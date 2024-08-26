#import "content.typ": unwrap-content, wrap-component, wrap-content
#import "number.typ": interpret-number, format-number
#import "unit.typ": interpret-unit, format-unit-power, format-unit-fraction

// Config for the output format of numbers and units
//
// The following options are available:
//  - uncertainty-format: "plus-minus" ("+-", "pm") or "parentheses" ("()") or "conserve"
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

#let num(body, ..args) = {
  let (number, tree) = interpret-number(body)

  context {
    let args = state-config.get() + args.named()
    format-number(number, tree, ..args)
  }
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