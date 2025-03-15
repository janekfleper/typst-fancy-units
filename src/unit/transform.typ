// Invert the sign of a number
//
// - s (str)
// -> (str)
//
// This function just checks if `s` starts with "-" and removes
// (or adds) it if it does (not) start with one.
#let invert-number(s) = {
  if s.starts-with("−") { s.trim("−", at: start) } else { "−" + s }
}

// Apply an exponent to a child
//
// - child (dictionary): The child to update
// - exponent (dictionary): The exponent to be applied
//   - body (str)
//   - layers (array)
// -> child (dictionary)
//
// If an exponent already exists in the `child`, the layers of that
// exponent are conserved and the `layers` of the new `exponent` are
// ignored.
// If the child does not have an exponent yet, the new exponent is
// always applied and kept, no matter the value of the exponent. This
// also allows exponents such as 0 or 1 to be used if they are specified
// in the initial unit.
// If the exponent is 1 after some kind of calculation, it will be removed
// before the child is returned. This mostly happens when the exponent -1
// is inverted, but this can also happen if the exponents 2 and 1/2 are
// combined.
#let apply-exponent(child, exponent) = {
  if not "exponent" in child.keys() {
    return (..child, exponent: exponent)
  } else if exponent.body == "−1" {
    child.exponent.body = invert-number(child.exponent.body)
  } else if child.exponent.body == "−1" {
    child.exponent.body = invert-number(exponent.body)
  } else {
    if pattern-non-numeric in child.exponent.body or pattern-non-numeric in exponent.body {
      panic("Exponent " + exponent.body + " cannot be applied to exponent " + child.exponent.body)
    }
    let fraction = exponent.body.split("/")
    let child-fraction = child.exponent.body.split("/")
    let numerator = int(fraction.at(0)) * int(child-fraction.at(0))
    let denominator = int(fraction.at(1, default: "1")) * int(child-fraction.at(1, default: "1"))
    let gcd = calc.gcd(numerator, denominator)
    if gcd == denominator { child.exponent.body = str(numerator / denominator) } else if gcd == 1 {
      child.exponent.body = str(numerator) + "/" + str(denominator)
    } else { child.exponent.body = str(numerator / gcd) + "/" + str(denominator / gcd) }
  }

  if child.exponent.body == "1" { _ = child.remove("exponent") }
  child
}

// Helper function to invert the exponent of a child
//
// - child (dictionary): The child to update
// -> child (dictionary)
#let invert-exponent(child) = {
  apply-exponent(child, (body: "−1", layers: ()))
}

// Pass down the exponent from the tree to the children
//
// - tree (dictionary)
//   - children (array)
//   - exponent (dictionary)
// -> tree (dictionary)
//
// The field "exponent" is always removed from the returned tree.
// If the tree is a grouped unit, the exponent is only applied to the last
// child. Otherwise the exponent is applied to all children.
#let inherit-exponents(tree) = {
  let exponent = tree.remove("exponent")
  if tree.group { tree.children.at(-1) = apply-exponent(tree.children.at(-1), exponent) } else {
    tree.children = tree.children.map(child => apply-exponent(child, exponent))
  }
  tree
}

// Insert macros into the content tree
//
// - tree (dictionary): The content tree
// - macros (dictionary): The available macros to insert
// -> tree (dictionary)
//
// This function will walk the content tree and replace the leaf body with
// its macro if it is defined in the macros states.
// If the leaf has an exponent, it is applied to the macro. And existing
// layers in the leaf are appended to the layers of the macro. The styling
// of the macro therefore takes precedence over the styling of the leaf.
// If the leaf has a subscript, it is applied to the macro if it does not
// already have a subscript. This matches the general behavior of units
// where multiple subscripts are not supported either.
#let insert-macros(tree, macros) = {
  if "body" in tree.keys() {
    if tree.body not in macros.keys() { return tree }
    let macro = macros.at(tree.body)
    if "exponent" in tree.keys() {
      macro = apply-exponent(macro, tree.exponent)
      macro.exponent.layers += tree.layers
    }
    if "subscript" in tree.keys() and "subscript" not in macro.keys() {
      macro.subscript = tree.subscript
      macro.subscript.layers += tree.layers
    }
    macro.layers += tree.layers
    return macro
  }

  tree.children = tree.children.map(child => insert-macros(child, macros))
  tree
}
