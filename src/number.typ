#import "content.typ": unwrap-content, find-leaves

#let pattern-value = regex("^\(?([+−]?[\d\.]+)")
#let pattern-exponent = regex("\)?[eE]([+−\d\.]+)$")
#let pattern-absolute-uncertainty = regex("\+ ?([\d\.]+)? ?− ?([\d\.]+)")
#let pattern-relative-uncertainty = regex("\((?:(\d+)\:)?(\d+)\)")
#let pattern-decimal-places = regex("^−?\d+(?:\.(\d+))")


// Find the value in the number leaves
//
// - leaves (array)
// -> (dictionary):
//   - leaves (array): Leaves with the value removed
//   - value (dictionary): Value component
#let find-value(leaves) = {
  let match = leaves.at(0).text.match(pattern-value)
  if match == none { panic("Unable to match value in number") }

  let value = match.captures.at(0)
  if match.end == leaves.at(0).text.len() {
    let value = (..leaves.remove(0), text: value)
    return (leaves: leaves, value: value)
  }

  let value = (..leaves.at(0), text: value)
  leaves.at(0).text = leaves.at(0).text.slice(match.end)
  return (leaves: leaves, value: value)
}

// Find the (global) exponent in the number leaves
//
// - leaves (array)
// -> (dictionary):
//   - leaves (array): Leaves with the (global) exponent removed
//   - exponent (dictionary): Exponent component
#let find-exponent(leaves) = {
  if leaves == () { return (leaves: (), exponent: none) }
  let match = leaves.at(-1).text.match(pattern-exponent)
  if match == none { return (leaves: leaves, exponent: none) }

  let exponent = match.captures.at(0)
  if match.start == 0 {
    let exponent = (..leaves.remove(-1), text: exponent)
    return (leaves: leaves, exponent: exponent)
  }

  let exponent = (..leaves.at(-1), text: exponent)
  leaves.at(-1).text = leaves.at(-1).text.slice(0, match.start + 1)
  return (leaves: leaves, exponent: exponent)
}

// Find the value and the exponent in the number leaves
// 
// - leaves (array)
// -> (dictionary):
//   - leaves (array): Leaves with the value and the exponent removed
//   - value (dictionary)
//   - exponent (dictionary): `none` if there is no exponent in the number
// 
// The value and the exponent are handled in the same function since the
// different input formats of uncertainties require a different handling
// of the parenthesis in the match of the exponent pattern.
#let find-value-and-exponent(leaves) = {
  let number = leaves.map(leaf => leaf.text).join()
  let match-value = number.match(pattern-value)
  assert.ne(match-value, none, message: "Invalid number format")
  let parentheses = match-value.text.starts-with("(")
  let match-exponent = number.match(pattern-exponent)

  if parentheses {
    if match-exponent == none {
      assert(number.ends-with(")"), message: "Invalid number format")
      leaves.at(-1).text = leaves.at(-1).text.slice(0, -1)
    }
    else {
      assert(match-exponent.text.starts-with(")"), message: "Invalid number format")
    }
  }

  let value = (..leaves.at(0), text: match-value.captures.at(0))
  if match-value.end == leaves.at(0).text.len() { _ = leaves.remove(0) }
  else { leaves.at(0).text = leaves.at(0).text.slice(match-value.end) }
  if match-exponent == none { ( return (leaves: leaves, value: value, exponent: none) ) }

  let exponent = (..leaves.at(-1), text: match-exponent.captures.at(0))
  if match-exponent.text.len() >= leaves.at(-1).text.len() { _ = leaves.remove(-1) }
  else { leaves.at(-1).text = leaves.at(-1).text.slice(0, match-exponent.start - match-exponent.end + 1) }
  if parentheses and leaves.at(-1).text.ends-with(")") {
    leaves.at(-1).text = leaves.at(-1).text.slice(0, -1)
  }
  (leaves: leaves, value: value, exponent: exponent)
}

// Find the leaves corresponding to the matched uncertainty (pair)
//
// - leaves (array): Remaining leaves that contain only the uncertainties
// - match (dictionary): Regex match of an absolute/relative uncertainty (pair)
// -> uncertainty (dictionary): Uncertainty (pair)
//   - absolute (boolean): Flag for absolute/relative uncertainty
//   - symmetric (boolean): Flag for symmetric/asymmetric uncertainty
//   - value (dictionary): Value of the symmetric uncertainty (if symmetric is true)
//   - positive (dictionary): Value of the positive uncertainty (if symmetric is false)
//   - negative (dictionary): Value of the negative uncertainty (if symmetric is false)
//
// If there is no "positive" uncertainty in the `match`, the uncertainty is symmetric
// and the "negative" uncertainty is treated as the general uncertainty "value".
#let match-uncertainty(leaves, match) = {
  let (positive, negative) = match.captures
  let uncertainty = (absolute: match.absolute, symmetric: positive == none)

  let index = 0
  for leaf in leaves {
    index += leaf.text.len()
    if index < match.start { continue }

    let value = leaf.text
    if positive != none and positive in value and "positive" not in uncertainty.keys() {
      uncertainty.insert("positive", (..leaf, text: positive))
      // prevent that "negative" matches the same leaf as "positive"
      value = value.replace(positive, "", count: 1)
    }
    if negative in value {
      if positive == none { uncertainty.insert("value", (..leaf, text: negative)) }
      else { uncertainty.insert("negative", (..leaf, text: negative)) }
      return uncertainty
    }
  }
}

// Find uncertainties in the number leaves
//
// - leaves (array): Remaining leaves that contain only the uncertainties
// -> uncertainties (array)
//
// If the `leaves` are not empty, they must be matched completely by the
// uncertainties patterns. Otherwise there is a format error in the number.
#let find-uncertainties(leaves) = {
  if leaves == () { return () }
  let number = leaves.map(leaf => leaf.text).join()
  let absolute-matches = number.matches(pattern-absolute-uncertainty).map(match => (..match, absolute: true))
  let relative-matches = number.matches(pattern-relative-uncertainty).map(match => (..match, absolute: false))
  let matches = (absolute-matches + relative-matches).sorted(key: match => match.start)
  if matches == () { panic("Invalid number format") }

  assert.eq(matches.at(0).start, 0, message: "Invalid number format")
  // assert((matches.at(-1).end == number.len()) or number.at(-1) == (")"), message: "panic...")
  assert.eq(matches.at(-1).end, number.len(), message: "Invalid number format")
  let start-positions = matches.slice(1).map(match => match.start)
  let end-positions = matches.slice(0, -1).map(match => match.end)
  assert.eq(start-positions, end-positions, message: "Invalid number format")

  matches.map(match => match-uncertainty(leaves, match))
}

// Interpret content as a number
//
// - c (content)
// -> (array)
//   - (dictionary)
//     - value (dictionary): The value component
//     - uncertainties (array): The uncertainty components, can be empty
//     - exponent (dictionary): The (global) exponent component, can be `none`
//   - tree (dictionary): The content tree from `unwrap-content()`
#let interpret-number-content(c) = {
  let tree = unwrap-content(c)
  let leaves = find-leaves(tree).filter(leaf => leaf.text != " ")
  let leaves = leaves.map(leaf => (..leaf, text: leaf.text.replace(" ", "")))
  let (leaves, value, exponent) = find-value-and-exponent(leaves)
  let uncertainties = find-uncertainties(leaves)
  ((value: value, uncertainties: uncertainties, exponent: exponent), tree)
}


// Trim the leading zeros from a number
// 
// - s (str): The number
// -> (str)
//
// If the string starts with a "." after the trimming, a zero will be added
// to the start again. This could also be solved with regex, but unfortunately
// the required lookahead is not implemented/allowed.
// If the string already started with a "." before the trimming, no zero will
// be added to the start.
#let trim-leading-zeros(s) = {
  if not s.starts-with("0") { return s }
  let trimmed = s.trim("0", at: start)
  if trimmed.starts-with(".") { "0" }
  trimmed
}

// Shift the decimal position of a number
//
// - s (str): The number
// - n (int): Decimal shift
// -> (str)
//
// The sign of the parameter `n` is defined such that a positive shift
// will move the decimal position to the right. As an equation this
// function would be $s * 10^n$.
#let shift-decimal-position(s, n) = {
  let split = s.split(".")
  let integer-places = split.at(0).len()
  let decimal-places = split.at(1, default: "").len()
  s = s.replace(".", "")

  if n >= decimal-places {
    return trim-leading-zeros(s + "0" * (n - decimal-places))
  } else if -n >= integer-places {
    return "0." + "0" * calc.abs(n + integer-places) + s
  } else {
    let decimal-position = integer-places + n
    return s.slice(0, decimal-position) + "." + s.slice(decimal-position)
  }
}

// Get the absolute uncertainty from a relative uncertainty
//
// - value (str): The value
// - uncertainty (str): The relative uncertainty
// -> (str)
#let convert-relative-uncertainty(value, uncertainty) = {
  let match = value.match(pattern-decimal-places)
  if match != none {
    let decimal-places = match.captures.at(0).len()
    uncertainty = shift-decimal-position(uncertainty, - decimal-places)
  }
  uncertainty
}