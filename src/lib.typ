#import "content.typ": unwrap-content, wrap-component, wrap-content
#import "number.typ": interpret-number-content
#import "unit.typ": interpret-unit, format-unit-power, format-unit-fraction

// taken from https://github.com/PgBiel/typst-tablex/tree/main
#let _array-type = type(())
#let _dict-type = type((a: 5))
#let _bool-type = type(true)
#let _str-type = type("")
#let _color-type = type(red)
#let _stroke-type = type(red + 5pt)
#let _length-type = type(5pt)
#let _rel-len-type = type(100% + 5pt)
#let _ratio-type = type(100%)
#let _int-type = type(5)
#let _float-type = type(5.0)
#let _fraction-type = type(5fr)
#let _function-type = type(x => x)
#let _content-type = type([])

// Config for the output format of numbers and units
//
// The following options are available:
//  - uncertainty-format: "plus-minus" ("+-", "pm") or "parentheses" ("()")
//  - decimal-character: content
//  - unit-separator: content
//  - per-mode: "power" or "fraction"
#let state-config = state("fancy-units-config", (
  "uncertainty-format": "plus-minus",
  "decimal-character": ".",
  "unit-separator": h(0.2em),
  "per-mode": "power",
))
#let state-units = state("fancy-units", (:))

// Change the configuration of the package
//
// - data (dictionary): Items to update the config
//
// The `data` is used to update the current config state. If keys are missing
// in `data`, their previous values are kept in the state. It is not possible to
// delete keys from the state.
#let fancy-units-configure(data) = {
  assert.eq(type(data), dictionary, message: "Data must be a dictionary")
  context { state-config.update(state-config.get() + data) }
}

// Format a number based on the individual components
//
// - value (content): Formatted value
// - uncertainty (content): Formatted uncertainty, will be ignored if it is `none`
// - exponent (content): Formatted exponent, will be ignored if it is `none`
// -> content
#let format-number(value, uncertainty, exponent) = {
  let c = value
  if uncertainty != none { c += [#sym.plus.minus] + uncertainty }
  if exponent != none {
    // Using math.lr() instead of bare parentheses won't make a difference in most cases.
    // But it's still better to rely on the math function here that would automatically
    // adjust the size of the parentheses.
    c = math.lr([(#c)]) + [#sym.times] + math.attach([10], tr: exponent)
  }
  c
}

// Interpret a number and return it as formatted content
//
// - body (content)
// -> equation(block: false)
#let num(body) = {
  let (number, tree) = interpret-number-content(body)
  let value = wrap-component(number.value, tree)
  let uncertainty = if number.uncertainty != none { wrap-component(number.uncertainty, tree) }
  let exponent = if number.exponent != none { wrap-component(number.exponent, tree) }
  wrap-content(format-number(value, uncertainty, exponent), tree.layers)
}

#let unit(body, ..args) = {
  let bare-tree = unwrap-content(body)
  // wrap the "text" child to use the functions find-brackets() and group-brackets-children()
  if "text" in bare-tree.keys() { bare-tree = (children: (bare-tree,), layers: ()) }
  let tree = interpret-unit(bare-tree)

  context {
    let args = state-config.get() + args.named()
    let per-mode = args.remove("per-mode")
    if per-mode == "power" { format-unit-power(tree, ..args) }
    else if per-mode == "fraction" { format-unit-fraction(tree, ..args) }
    else { panic("Unknown per-mode '" + per-mode + "'") }
  }
}