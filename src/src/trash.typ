

// Find the value component of a number in parentheses format
// 
// - leaves (array): Leaves from the content tree
// -> component (dictionary)
//    - text (str): The value
//    - path (array): The path to the value leaf in the content tree
// 
// Due to the syntax rules the value must always be in a single leaf.
// But there can be other characters in the same leaf.
#let find-parentheses-value(leaves) = {
  for i in range(leaves.len()) {
    let match = leaves.at(i).text.match(pattern-parentheses-value)
    if match != none { return (text: match.text.replace(",", "."), path: leaves.at(i).path) }
  }
  panic("Could not match parentheses value in " + array-to-string(leaves.map(leaf => leaf.text)))
}

// Due to the syntax rules the value must always be in a single leaf,
// but there can be other characters in the same leaf.
#let find-plus-minus-value(leaves) = {
  for i in range(leaves.len()) {
    let match = leaves.at(i).text.match(pattern-plus-minus-value)
    if match != none { return (text: match.text.replace(",", "."), path: leaves.at(i).path) }
  }
  panic("Could not match plus-minus value in " + array-to-string(leaves.map(leaf => leaf.text)))
}

#let find-parentheses-uncertainty(leaves) = {
  for i in range(leaves.len()) {
    // skip the leaves until the opening parenthesis (
    if not "(" in leaves.at(i).text { continue }

    // make sure that the uncertainty can only come after the opening parenthesis...
    let split = leaves.at(i).text.split("(")
    let match = split.at(1, default: "").match(regex("\d+"))
    if match != none { return (text: match.text, path: leaves.at(i).path) }

    // if the leaf at index i did not contain the uncertainty, it must be in the next one...
    let match-next = leaves.at(i+1).text.match(regex("\d+"))
    if match-next != none { return (text: match-next.text, path: leaves.at(i+1).path) }
  }
  panic("Could not match parentheses uncertainty in " + array-to-string(leaves.map(leaf => leaf.text)))
}

#let find-plus-minus-uncertainty(leaves) = {
  for i in range(leaves.len()) {
    // skip the leaves until the opening parenthesis (
    if not "+-" in leaves.at(i).text { continue }

    // make sure that the uncertainty can only come after the +-...
    let split = leaves.at(i).text.split("+-")
    let match = split.at(1, default: "").match(pattern-plus-minus-value)
    if match != none { return (text: match.text, path: leaves.at(i).path) }

    // if the leaf at index i did not contain the uncertainty, it must be in the next one...
    let match-next = leaves.at(i+1).text.match(pattern-plus-minus-value)
    if match-next != none { return (text: match-next.text, path: leaves.at(i+1).path) }
  }
  panic("Could not match plus-minus uncertainty in " + array-to-string(leaves.map(leaf => leaf.text)))
}

#let find-value(leaves, number-format) = {
  if number-format == "parentheses" { find-parentheses-value(leaves) }
  else if number-format == "plus-minus" { find-plus-minus-value(leaves) }
}

#let find-uncertainty(leaves, number-format) = {
  if number-format == "parentheses" { find-parentheses-uncertainty(leaves) }
  else if number-format == "plus-minus" { find-plus-minus-uncertainty(leaves) }
}