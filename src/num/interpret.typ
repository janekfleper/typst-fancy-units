#import "../content.typ": _unwrap-content, _find-leaves

// Regular expressions for matching number components
#let _pattern-value = regex("^\(?([+−]?[\d\.]+)")
#let _pattern-exponent = regex("\)?[eE]([+−\d\.]+)$")
#let _pattern-absolute-uncertainty = regex("\+ ?([\d\.]+)? ?− ?([\d\.]+)")
#let _pattern-relative-uncertainty = regex("\((?:(\d+)\:)?(\d+)\)")

// Convert string to decimal
//
// - s (str or decimal): Input value
// -> (decimal): Converted decimal
#let _to-decimal(s) = {
  if type(s) == decimal { return s }
  return decimal(s)
}

// Find the value in the number leaves
//
// - leaves (array)
// -> (dictionary):
//   - leaves (array): Leaves with the value removed
//   - value (dictionary): Value component
#let _find-value(leaves) = {
  let match = leaves.at(0).body.match(_pattern-value)
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
#let _find-exponent(leaves) = {
  if leaves == () { return (leaves: (), exponent: none) }
  let match = leaves.at(-1).body.match(_pattern-exponent)
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
#let _remove-value-from-leaves(match, leaves) = {
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
    value: (..leaf, body: _to-decimal(match.captures.at(0))),
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
// have a valid format for `_find-uncertainties()`.
#let _find-value-and-exponent(leaves) = {
  let number = leaves.map(leaf => leaf.body).join()
  let match-value = number.match(_pattern-value)
  assert.ne(match-value, none, message: "Invalid number format")
  let parentheses = match-value.text.starts-with("(")
  let match-exponent = number.match(_pattern-exponent)

  if parentheses {
    if match-exponent == none {
      assert(number.ends-with(")"), message: "Invalid number format")
      leaves.at(-1).body = leaves.at(-1).body.slice(0, -1)
    } else {
      assert(match-exponent.text.starts-with(")"), message: "Invalid number format")
    }
  }

  let (value, leaves) = _remove-value-from-leaves(match-value, leaves)
  if match-exponent == none { return (leaves: leaves, value: value, exponent: none) }

  let exponent = (..leaves.at(-1), body: _to-decimal(match-exponent.captures.at(0)))

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
#let _match-uncertainty(leaves, match) = {
  let (positive, negative) = match.captures
  let uncertainty = (absolute: match.absolute, symmetric: positive == none)

  let index = 0
  for leaf in leaves {
    index += leaf.body.len()
    if index < match.start { continue }

    let value = leaf.body
    if positive != none and positive in value and "positive" not in uncertainty.keys() {
      uncertainty.insert("positive", (..leaf, body: _to-decimal(positive)))
      // prevent that "negative" matches the same leaf as "positive"
      value = value.replace(positive, "", count: 1)
    }
    if negative in value {
      if positive == none {
        uncertainty += (..leaf, body: _to-decimal(negative))
      } else {
        uncertainty.insert("negative", (..leaf, body: _to-decimal(negative)))
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
#let _find-uncertainties(leaves) = {
  if leaves == () { return () }
  let number = leaves.map(leaf => leaf.body).join()
  let absolute-matches = number.matches(_pattern-absolute-uncertainty).map(match => (..match, absolute: true))
  let relative-matches = number.matches(_pattern-relative-uncertainty).map(match => (..match, absolute: false))
  let matches = (absolute-matches + relative-matches).sorted(key: match => match.start)
  if matches == () { panic("Invalid number format") }

  assert.eq(matches.at(0).start, 0, message: "Invalid number format")
  assert.eq(matches.at(-1).end, number.len(), message: "Invalid number format")
  let start-positions = matches.slice(1).map(match => match.start)
  let end-positions = matches.slice(0, -1).map(match => match.end)
  assert.eq(start-positions, end-positions, message: "Invalid number format")

  matches.map(match => _match-uncertainty(leaves, match))
}

// Get the styling layers from the content tree
//
// - component (dictionary): The component to style
// - tree (array): The content tree
// -> (dictionary): The component with the styling layers
#let _resolve-path(component, tree) = {
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
  let tree = _unwrap-content(c)
  let leaves = _find-leaves(tree).filter(leaf => leaf.body != " ")
  let leaves = leaves.map(leaf => (..leaf, body: leaf.body.replace(" ", "")))
  let (leaves, value, exponent) = _find-value-and-exponent(leaves)
  let uncertainties = _find-uncertainties(leaves)

  (
    value: _resolve-path(value, tree),
    uncertainties: uncertainties.map(uncertainty => {
      if uncertainty.symmetric {
        return _resolve-path(uncertainty, tree)
      } else {
        uncertainty.positive = _resolve-path(uncertainty.positive, tree)
        uncertainty.negative = _resolve-path(uncertainty.negative, tree)
        return uncertainty
      }
    }),
    exponent: if exponent != none { _resolve-path(exponent, tree) } else { none },
    layers: tree.layers,
  )
}
