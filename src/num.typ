#import "content.typ": unwrap-content, find-leaves, wrap-content-math
#import "state.typ": state-config, get-decimal-separator

#let pattern-value = regex("^\(?([+−]?[\d\.]+)")
#let pattern-exponent = regex("\)?[eE]([+−\d\.]+)$")
#let pattern-absolute-uncertainty = regex("\+ ?([\d\.]+)? ?− ?([\d\.]+)")
#let pattern-relative-uncertainty = regex("\((?:(\d+)\:)?(\d+)\)")

// Convert string to decimal
//
// - s (str or decimal): Input value
// -> (decimal): Converted decimal
#let to-decimal(s) = {
  if type(s) == decimal { return s }
  return decimal(s)
}

// Find the value in the number leaves
//
// - leaves (array)
// -> (dictionary):
//   - leaves (array): Leaves with the value removed
//   - value (dictionary): Value component
#let find-value(leaves) = {
  let match = leaves.at(0).body.match(pattern-value)
  if match == none { panic("Unable to match value in number") }

  let value = match.captures.at(0)
  if match.end == leaves.at(0).body.len() {
    let value = (..leaves.remove(0), body: value)
    return (leaves: leaves, value: value)
  }

  let value = (..leaves.at(0), body: value)
  leaves.at(0).body = leaves.at(0).body.slice(match.end)
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
  let match = leaves.at(-1).body.match(pattern-exponent)
  if match == none { return (leaves: leaves, exponent: none) }

  let exponent = match.captures.at(0)
  if match.start == 0 {
    let exponent = (..leaves.remove(-1), body: exponent)
    return (leaves: leaves, exponent: exponent)
  }

  let exponent = (..leaves.at(-1), body: exponent)
  leaves.at(-1).body = leaves.at(-1).body.slice(0, match.start + 1)
  return (leaves: leaves, exponent: exponent)
}

// Remove the matched value from the leaves
//
// - match (dictionary): The matched value
// - leaves (array): All the leaves
// -> (dictionary):
//   - value (dictionary): The value with the text and the path
//   - leaves (array): The remaining leaves
//
// When the value starts with a hyphen, Typst will separate it from
// the (absolute) value even if there is no space between the two.
// This would not happen with an actual minus sign, but not allowing
// the hyphen as input is not an option.
// In most cases the value is not spread over multiple leaves and the
// path is unambiguous. The most recently checked leaf can therefore be
// used to set the path for the value.
// If the value is spread over multiple leaves, the most recent leaf is
// still a reasonable choice since this will be the leaf that holds the
// absolute value. The styling of the sign is then simply ignored.
#let remove-value-from-leaves(match, leaves) = {
  let leaf
  let i = 0
  let offset = match.start
  while true {
    leaf = leaves.at(i)
    let length = match.end - offset

    if leaf.body.len() == length {
      i += 1
      break
    } else if leaf.body.len() > length {
      // do not increment i since leaves.at(i) is not empty (yet)
      leaves.at(i).body = leaf.body.slice(match.end - offset)
      break
    }

    offset += leaf.body.len()
    i += 1
  }

  (
    value: (..leaf, body: to-decimal(match.captures.at(0))),
    leaves: leaves.slice(i),
  )
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
//
// The closing parenthesis ")" is part of the exponent-pattern to validate
// the number format. This parenthesis has to be removed if it belongs to
// the pair that encloses the number and the uncertainties. If it belongs
// to a relative uncertainty however, the parenthesis has to be kept to
// have a valid format for `find-uncertainties()`.
#let find-value-and-exponent(leaves) = {
  let number = leaves.map(leaf => leaf.body).join()
  let match-value = number.match(pattern-value)
  assert.ne(match-value, none, message: "Invalid number format")
  let parentheses = match-value.text.starts-with("(")
  let match-exponent = number.match(pattern-exponent)

  if parentheses {
    if match-exponent == none {
      assert(number.ends-with(")"), message: "Invalid number format")
      leaves.at(-1).body = leaves.at(-1).body.slice(0, -1)
    } else {
      assert(match-exponent.text.starts-with(")"), message: "Invalid number format")
    }
  }

  let (value, leaves) = remove-value-from-leaves(match-value, leaves)
  if match-exponent == none { return (leaves: leaves, value: value, exponent: none) }

  let exponent = (..leaves.at(-1), body: to-decimal(match-exponent.captures.at(0)))

  if match-exponent.text.len() >= leaves.at(-1).body.len() { _ = leaves.remove(-1) } else {
    let parenthesis-offset = int(match-exponent.text.starts-with(")"))
    let end = match-exponent.start - match-exponent.end + parenthesis-offset
    leaves.at(-1).body = leaves.at(-1).body.slice(0, end)
  }
  if parentheses and leaves.at(-1).body.ends-with(")") {
    leaves.at(-1).body = leaves.at(-1).body.slice(0, -1)
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
    index += leaf.body.len()
    if index < match.start { continue }

    let value = leaf.body
    if positive != none and positive in value and "positive" not in uncertainty.keys() {
      uncertainty.insert("positive", (..leaf, body: to-decimal(positive)))
      // prevent that "negative" matches the same leaf as "positive"
      value = value.replace(positive, "", count: 1)
    }
    if negative in value {
      if positive == none {
        uncertainty += (..leaf, body: to-decimal(negative))
      } else {
        uncertainty.insert("negative", (..leaf, body: to-decimal(negative)))
      }
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
  let number = leaves.map(leaf => leaf.body).join()
  let absolute-matches = number.matches(pattern-absolute-uncertainty).map(match => (..match, absolute: true))
  let relative-matches = number.matches(pattern-relative-uncertainty).map(match => (..match, absolute: false))
  let matches = (absolute-matches + relative-matches).sorted(key: match => match.start)
  if matches == () { panic("Invalid number format") }

  assert.eq(matches.at(0).start, 0, message: "Invalid number format")
  assert.eq(matches.at(-1).end, number.len(), message: "Invalid number format")
  let start-positions = matches.slice(1).map(match => match.start)
  let end-positions = matches.slice(0, -1).map(match => match.end)
  assert.eq(start-positions, end-positions, message: "Invalid number format")

  matches.map(match => match-uncertainty(leaves, match))
}

// Get the styling layers from the content tree
//
// - component (dictionary): The component to style
// - tree (array): The content tree
// -> (dictionary): The component with the styling layers
#let resolve-path(component, tree) = {
  let path = component.remove("path")
  component.layers = ()
  if path.len() == 0 { return component }

  let current-tree = tree
  for i in path {
    current-tree = current-tree.children.at(i)
    component.layers += current-tree.layers.rev()
  }

  component.layers = component.layers.rev()
  return component
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
#let interpret-number(c) = {
  let tree = unwrap-content(c)
  let leaves = find-leaves(tree).filter(leaf => leaf.body != " ")
  let leaves = leaves.map(leaf => (..leaf, body: leaf.body.replace(" ", "")))
  let (leaves, value, exponent) = find-value-and-exponent(leaves)
  let uncertainties = find-uncertainties(leaves)

  (
    value: resolve-path(value, tree),
    uncertainties: uncertainties.map(uncertainty => {
      if uncertainty.symmetric {
        return resolve-path(uncertainty, tree)
      } else {
        uncertainty.positive = resolve-path(uncertainty.positive, tree)
        uncertainty.negative = resolve-path(uncertainty.negative, tree)
        return uncertainty
      }
    }),
    exponent: if exponent != none { resolve-path(exponent, tree) } else { none },
    layers: tree.layers,
  )
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
// - n (decimal): The number
// - shift (int): Decimal shift
// -> (decimal)
//
// The sign of the parameter `shift` is defined such that a positive shift
// will move the decimal position to the right. As an equation this function
// would be $n * 10^shift$.
#let shift-decimal-position(n, shift) = {
  let s = str(n)
  let split = s.split(".")
  let integer-places = split.at(0).len()
  let decimal-places = split.at(1, default: "").len()
  s = s.replace(".", "")

  if shift >= decimal-places {
    return decimal(trim-leading-zeros(s + "0" * (shift - decimal-places)))
  } else if -shift >= integer-places {
    return decimal("0." + "0" * calc.abs(shift + integer-places) + s)
  } else {
    let decimal-position = integer-places + shift
    return decimal(trim-leading-zeros(s.slice(0, decimal-position) + "." + s.slice(decimal-position)))
  }
}

// This is already the decimal-only implementation of `shift-decimal-position()`...
//
// Shift the decimal position of a number
//
// - n (decimal): The number
// - shift (int): Decimal shift
// -> (decimal)
//
// The sign of the parameter `n` is defined such that a positive shift
// will move the decimal position to the right. As an equation this
// function would be $s * 10^n$.
// #let shift-decimal-position(n, shift) = {
//   let n-shifted = n * calc.pow(decimal(10), shift)
//   let s = str(n-shifted)
//   if s.contains(".") {
//     return decimal(s.trim("0", at: end))
//   } else {
//     return n-shifted
//   }
// }

// Count decimal places in a value
//
// - val (decimal): The value to check
// -> (int): Number of decimal places
#let count-decimal-places(val) = {
  let parts = str(val).split(".")
  if parts.len() > 1 { return parts.at(1).len() }
  return 0
}

// Convert a relative uncertainty to an absolute uncertainty
//
// - uncertainty (dictionary): The relative uncertainty
// - value (dictionary)
// -> (dictionary): The absolute uncertainty
#let convert-uncertainty-relative-to-absolute(uncertainty, value) = {
  let decimal-places = count-decimal-places(value.body)
  if decimal-places > 0 {
    if uncertainty.symmetric {
      uncertainty.body = shift-decimal-position(uncertainty.body, -decimal-places)
    } else {
      uncertainty.positive.body = shift-decimal-position(uncertainty.positive.body, -decimal-places)
      uncertainty.negative.body = shift-decimal-position(uncertainty.negative.body, -decimal-places)
    }
  }

  uncertainty.absolute = true
  uncertainty
}

// Convert an absolute uncertainty to a relative uncertainty
//
// - uncertainty (dictionary): The absolute uncertainty
// - value (dictionary)
// -> (dictionary): The relative uncertainty
#let convert-uncertainty-absolute-to-relative(uncertainty, value) = {
  let decimal-places = count-decimal-places(value.body)
  if decimal-places > 0 {
    if uncertainty.symmetric {
      uncertainty.body = shift-decimal-position(uncertainty.body, decimal-places)
    } else {
      uncertainty.positive.body = shift-decimal-position(uncertainty.positive.body, decimal-places)
      uncertainty.negative.body = shift-decimal-position(uncertainty.negative.body, decimal-places)
    }
  }

  uncertainty.absolute = false
  uncertainty
}

// Transform all uncertainties to absolute (plus-minus) format
//
// - number (dictionary): The number with uncertainties
// -> (dictionary): Updated number with transformed uncertainties
#let absolute-uncertainties(number) = {
  let uncertainties = number.uncertainties.map(u => {
    if u.absolute { return u }
    return convert-uncertainty-relative-to-absolute(u, number.value)
  })

  (..number, uncertainties: uncertainties)
}

// Convert all uncertainties to relative (parentheses) format
//
// - number (dictionary): The number with uncertainties
// -> (dictionary): Updated number with transformed uncertainties
#let relative-uncertainties(number) = {
  let uncertainties = number.uncertainties.map(u => {
    if not u.absolute { return u }
    return convert-uncertainty-absolute-to-relative(u, number.value)
  })

  (..number, uncertainties: uncertainties)
}


// Format a symmetric uncertainty
//
// - uncertainty (dictionary)
// - decimal-separator (str, symbol or content): The decimal separator to use
// -> (content)
//
// If the `uncertainty` is absolute, it will be preceded by sym.plus.minus.
// If the `uncertainty` is not absolute, it will be wrapped in parentheses ().
#let format-symmetric-uncertainty(uncertainty, decimal-separator) = {
  let u = wrap-content-math(uncertainty.body, uncertainty.layers, decimal-separator: decimal-separator)
  if uncertainty.absolute { [#sym.plus.minus] + u } else { math.lr[(#u)] }
}

// Format an asymmetric uncertainty
//
// - positive (dictionary): The positive uncertainty
// - negative (dictionary): The negative uncertainty
// - decimal-separator (str, symbol or content): The decimal separator to use
// -> (content)
//
// The uncertainties are not directly attached to the existing content
// in `format-number()` to ensure that their positions do not depend on
// the content before them.
#let format-asymmetric-uncertainty(positive, negative, decimal-separator) = {
  math.attach(
    [],
    tr: [#sym.plus] + wrap-content-math(positive.body, positive.layers, decimal-separator: decimal-separator),
    br: [#sym.minus] + wrap-content-math(negative.body, negative.layers, decimal-separator: decimal-separator),
  )
}

// Format the exponent
//
// - exponent (dictionary)
// - decimal-separator (str, symbol or content): The decimal separator to use
// -> (content)
//
// For now the layers are only applied to the actual exponent. The x10
// is not affected.
#let format-exponent(exponent, decimal-separator) = [
  #sym.times
  #math.attach([10], tr: wrap-content-math(exponent.body, exponent.layers, decimal-separator: decimal-separator))
]

// Format a number
//
// - number (dictionary): The interpreted number
// - decimal-separator (str, symbol or content): The decimal separator to use
// -> (content)
#let format-num(number, decimal-separator: auto) = {
  // Use provided decimal separator or get from config
  if decimal-separator == auto {
    let config-decimal-separator = state-config.get().decimal-separator
    if config-decimal-separator == auto { decimal-separator = get-decimal-separator() } else {
      decimal-separator = config-decimal-separator
    }
  }

  let c = wrap-content-math(number.value.body, number.value.layers, decimal-separator: decimal-separator)
  let wrap-in-parentheses = false
  for uncertainty in number.uncertainties {
    if uncertainty.symmetric {
      c += format-symmetric-uncertainty(uncertainty, decimal-separator)
      if uncertainty.absolute { wrap-in-parentheses = true }
    } else {
      let (absolute, positive, negative) = uncertainty
      c += format-asymmetric-uncertainty(positive, negative, decimal-separator)
      wrap-in-parentheses = true
    }
  }

  if number.exponent != none {
    if wrap-in-parentheses { c = math.lr[(#c)] }
    c += format-exponent(number.exponent, decimal-separator)
  }
  wrap-content-math(c, number.layers, decimal-separator: decimal-separator)
}
