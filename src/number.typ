#import "content.typ": unwrap-content, find-leaves

// Match an exponential expression after a closing parenthesis. https://regex101.com/r/7DRoMp
// Group 0: The "remaining" number with the value and uncertainty
// Group 1: The entire exponential (e.g. e5 or *10^5)
// Group 2: The base (e.g. the 2 in *2^8)
// Group 3: The exponent (e.g. 5 in e5 or 7 in *10^7)
#let pattern-global-exponent = regex("(.*\(.+\) *)((?:[eE]|(?:\*(\d+)\^))([+-]?\d+))$")

// Match the number format "plus-minus" or "parentheses". https://regex101.com/r/pxynpo
// Group 0: The number if the format is "parentheses"
// Group 1: The number if the format is "plus-minus"
// Group 2: The number without (optional) parentheses if the format is "plus-minus"
#let pattern-number-format = regex("^([ \-+\d\.,eE]+\([ \d]+\))|(\(?([ \-+\d\.,eE]+(?:\+-[ \-+\d\.,eE]+)?)\)?)")

// Match the value and the uncertainty in the "parentheses" format. https://regex101.com/r/SglENc
// Group 0: The entire number again (if the format is valid)
// Group 1: The value
// Group 2: The uncertainty
#let pattern-parentheses-format = regex("(^ *(-?\d+(?:[\,.]\d+)?) *(?:\( *(\d+) *\)) *)")

// Match the value and the uncertainty in the "parentheses" format. https://regex101.com/r/zgE0l5
// Group 0: The entire number again (if the format is valid)
// Group 1: The value
// Group 2: The (optional) uncertainty
#let pattern-plus-minus-format = regex("(^ *(-?\d+(?:[\,.]\d+)?(?:[eE][+-]?\d+)?) *(?:\+-)? *(\d+(?:[\,.]\d+)?(?:[eE][+-]?\d+)?)? *)")

// Match the digits after the decimal character
// Group 0: The decimal digits
#let pattern-decimal-places = regex("^-?\d+(?:[\,.](\d+))")

#let pattern-find-global-exponent = regex("[eE]([+-]?\d*)$")
#let pattern-find-parentheses-value = regex("([+-]?\d+(?:[\,.]\d+)?)")
#let pattern-find-plus-minus-value = regex("([+-]?\d+(?:[\,.]\d+)?(?:[eE][+-]?\d+)?)")
#let pattern-find-parentheses-uncertainty = regex("\d+")
#let pattern-find-plus-minus-uncertainty = regex("([+-]?\d+(?:[\,.]\d+)?(?:[eE][+-]?\d+)?)")


// Trim the leading zeros from a number
// 
// - s (str): The number
// -> str
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
// -> str
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


// Get the (global) base and exponent of a number
//
// - s (str): The number
// -> dictionary with the (reduced) 'number', the 'base' and the 'exponent'
//
// If there was no match with the `interpret-global-exponent`, the number `s`
// is returned unchanged and the `base` and the `exponent` are set to none.
// If the exponential notation with 'e' or 'E' is used, the `base` defaults to 10.
#let interpret-global-exponent(s) = {
  let match = s.match(pattern-global-exponent)
  if match == none { return (number: s, base: none, exponent: none) }
  
  let base = match.captures.at(2)
  return (
    number: match.captures.at(0),
    base: if base == none { 10 } else { base },
    exponent: match.captures.at(3)
  )
}

// Get the absolute uncertainty from a number in "parentheses" format
//
// - value (str): The value
// - uncertainty (str): The uncertainty
// -> dictionary with the keys 'value' and 'uncertainty'
#let interpret-parentheses-uncertainty(value, uncertainty) = {
  let match = value.match(pattern-decimal-places)
  if match != none {
    let decimal-places = match.captures.at(0).len()
    uncertainty = shift-decimal-position(uncertainty, - decimal-places)
  }
  (value: value, uncertainty: uncertainty)
}

// Get the value and uncertainty from a number in "parentheses" format
//
// - s (str): The number
// -> dictionary with the keys 'value' and 'uncertainty'
//
// Commas used as decimal characters in the 'value' and the 'uncertainty' are replaced by
// decimal points.
#let interpret-parentheses-format(s) = {
  let match = s.match(pattern-parentheses-format)
  assert.ne(match, none, message: "Could not match parentheses format for '" + s + "'")
  // group 0 is the "check group" that should match all of "s"
  assert.eq(s, match.captures.at(0), message: "Could not match parentheses format for '" + s + "'")

  let value = match.captures.at(1).replace(",", ".")
  let uncertainty = match.captures.at(2).replace(",", ".")
  interpret-parentheses-uncertainty(value, uncertainty)
}

// Get the value and uncertainty from a number in "plus-minus" format
//
// - s (str): The number
// -> dictionary with the keys 'value' and 'uncertainty'
//
// Commas used as decimal characters in the 'value' and the 'uncertainty' are replaced by
// decimal points.
// If there was no uncertainty in the number `s`, the returned value of the
// key 'uncertainty' will be none.
#let interpret-plus-minus-format(s) = {
  let match = s.match(pattern-plus-minus-format)
  assert.ne(match, none, message: "Could not match plus-minus format for '" + s + "'")
  // group 0 is the "check group" that should match all of "s"
  assert.eq(s, match.captures.at(0), message: "Could not match plus-minus format for '" + s + "'")

  let uncertainty = match.captures.at(2)
  if uncertainty != none { uncertainty = uncertainty.replace(",", ".") }
  (value: match.captures.at(1).replace(",", "."), uncertainty: uncertainty)
}

// Get the value, uncertainty and exponent from a number
//
// - s (str): The number
// -> dictionary with the keys 'value', 'uncertainty', 'base' and 'exponent'
//
// A "number" refers to a value, an (optional) uncertainty and an (optional)
// exponent. There are two possible input formats, using +- between the value
// and the uncertainty or wrapping the uncertainty in parentheses (). The latter
// format always requires an uncertainty. If the number `s` only consists of a
// value, the format will always be interpreted as 'plus-minus' with the
// uncertainty being none.
// In either case, the "exponent" refers to the "global" exponent that concerns
// the value and the uncertainty. If there is an exponent in either the value or
// the uncertainty, this will remain in the respective elements.
#let interpret-number(s) = {
  let exponent-match = interpret-global-exponent(s)
  let number = exponent-match.remove("number")
  let match = number.match(pattern-number-format)
  assert.ne(match, none, message: "Could not match number format for '" + s + "'")
  let captures = match.captures
  if captures.at(0) != none {
    assert.eq(number.trim(" "), captures.at(0), message: "Could not match number format for '" + s + "'")
    return interpret-parentheses-format(captures.at(0)) + exponent-match
  } else {
    // group 1 is the "check group" for the plus-minus format...
    // ... and group 2 does not include the (optional) parentheses
    assert.eq(number.trim(" "), captures.at(1), message: "Could not match number format for '" + s + "'")
    return interpret-plus-minus-format(captures.at(2)) + exponent-match 
  }
}


#let array-to-string(a) = {
  "(" + a.map(it => "'" + it + "'").join(", ") + ")"
}

// Find the global exponent component
//
// - leaves (array): Leaves from the content tree
// -> component (dictionary)
//    - text (str): The global exponent
//    - path (array): The path to the global exponent leaf in the content tree
// 
// Due to the syntax rules the global exponent must always be in a single leaf.
// But there can be other characters in the same leaf.
#let find-global-exponent-component(leaves) = {
  let match = leaves.at(-1).text.match(pattern-find-global-exponent)
  if match != none { (text: match.captures.at(0), path: leaves.at(-1).path) }
}

// Find the value component of a number
// 
// - leaves (array): Leaves from the content tree
// -> component (dictionary)
//    - text (str): The value
//    - path (array): The path to the value leaf in the content tree
// 
// Due to the syntax rules the value must always be in a single leaf.
// But there can be other characters in the same leaf.
#let find-value-component(leaves, format) = {
  let pattern = if format == "parentheses" { pattern-find-parentheses-value } else { pattern-find-plus-minus-value }

  for i in range(leaves.len()) {
    let match = leaves.at(i).text.match(pattern)
    if match != none { return (text: match.text.replace(",", "."), path: leaves.at(i).path) }
  }
  panic("Could not match " + format + " value in " + array-to-string(leaves.map(leaf => leaf.text)))
}

// Find the uncertainty component of a number
// 
// - leaves (array): Leaves from the content tree
// -> component (dictionary)
//    - text (str): The uncertainty
//    - path (array): The path to the uncertainty leaf in the content tree
// 
// Due to the syntax rules the uncertainty must always be in a single leaf.
// But there can be other characters in the same leaf.
#let find-uncertainty-component(leaves, format) = {
  let separator = if format == "parentheses" { "(" } else { "+-" }
  let pattern = if format == "parentheses" { pattern-find-parentheses-uncertainty } else { pattern-find-plus-minus-uncertainty }

  for i in range(leaves.len()) {
    // skip the leaves until the separator is found...
    if not separator in leaves.at(i).text { continue }

    // make sure that the uncertainty can only come after the separator...
    let split = leaves.at(i).text.split(separator)
    let match = split.at(1, default: "").match(pattern)
    if match != none { return (text: match.text, path: leaves.at(i).path) }

    // if the leaf at index i did not contain the uncertainty, it must be in the next one...
    let match-next = leaves.at(i+1).text.match(pattern)
    if match-next != none { return (text: match-next.text, path: leaves.at(i+1).path) }
  }
  panic("Could not match " + format + " uncertainty in " + array-to-string(leaves.map(leaf => leaf.text)))
}


// Get the number format
//
// - s (str): The full number
// -> number-format (str): "parentheses" or "plus-minus"
#let interpret-number-format(s) = {
  let exponent-match = interpret-global-exponent(s)
  let number = exponent-match.remove("number")
  let match = number.match(pattern-number-format)
  assert.ne(match, none, message: "Could not match number format for '" + s + "'")
  let captures = match.captures
  if captures.at(0) != none {
    assert.eq(number.trim(" "), captures.at(0), message: "Could not match number format for '" + s + "'")
    return "parentheses"
  } else {
    assert.eq(number.trim(" "), captures.at(1), message: "Could not match number format for '" + s + "'")
    return "plus-minus"
  }
}

// Interpret content as a number
//
// - c (content)
// -> (array)
//   - (dictionary)
//     - value (dictionary): The value component
//     - uncertainty (dictionary): The uncertainty component, can be `none`
//     - exponent (dictionary): The (global) exponent component, can be `none`
//   - tree(dictionary): The content tree from `unwrap-content()`
#let interpret-number-content(c) = {
  let tree = unwrap-content(c)
  let leaves = find-leaves(tree)
  let number = leaves.map(leaf => leaf.text).join().trim(" ")
  let number-format = interpret-number-format(number)

  // empty leaves can be removed now...
  leaves = leaves.filter(leaf => leaf.text != " ")
  let exponent = find-global-exponent-component(leaves)
  let value = find-value-component(leaves, number-format)
  let uncertainty = find-uncertainty-component(leaves, number-format)
  if number-format == "parentheses" {
    uncertainty.text = interpret-parentheses-uncertainty(value.text, uncertainty.text).uncertainty
  }
  ((value: value, uncertainty: uncertainty, exponent: exponent), tree)
}