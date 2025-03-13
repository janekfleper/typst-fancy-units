#import "content.typ": unwrap-content
#import "number.typ": (
  interpret-number,
  format-number,
  absolute-uncertainties,
  relative-uncertainties,
)
#import "unit.typ": interpret-unit, insert-macros, format-unit-power, format-unit-fraction, format-unit-slash
#import "state.typ": (
  state-config,
  state-macros,
  get-decimal-separator,
  fancy-units-configure,
  add-macros,
)

#let num(
  transform: auto,
  format: auto,
  body,
) = context {
  let (number, tree) = interpret-number(body)
  let config = state-config.get()
  let _transform = if transform == auto { config.num-transform } else { transform }
  if type(_transform) == array {
    for func in _transform { number = func(number) }
  } else if type(_transform) == function {
    number = _transform(number)
  } else if _transform == false {
    // Do nothing
  } else {
    panic("Unknown transform type: " + str(type(_transform)))
  }

  let _format = if format == auto {
    if config.num-format == auto { format-number } else { config.num-format }
  } else { format }

  if type(_format) == function {
    return _format(number, tree)
  } else if type(_format) == array {
    for func in format { number = func(number, tree) }
    return number
  } else if _format == false or _format == none {
    // Do nothing
  } else {
    panic("Unknown format type: " + str(type(_format)))
  }
  return number
}

#let unit(
  decimal-separator: auto,
  unit-separator: auto,
  per-mode: auto,
  body,
) = {
  let tree = interpret-unit(body)

  context {
    let config = state-config.get()
    let tree = insert-macros(tree, state-macros.get())
    if decimal-separator != auto { config.decimal-separator = decimal-separator }
    if config.decimal-separator == auto { config.decimal-separator = get-decimal-separator() }
    if unit-separator != auto { config.unit-separator = unit-separator }
    let per-mode = if per-mode != auto { per-mode } else { config.per-mode }
    if per-mode == "power" { format-unit-power(tree, config) } else if per-mode == "fraction" {
      format-unit-fraction(tree, config)
    } else if per-mode == "slash" { format-unit-slash(tree, config) } else {
      panic("Unknown per-mode '" + per-mode + "'")
    }
  }
}

#let qty(
  decimal-separator: auto,
  uncertainty-mode: auto,
  unit-separator: auto,
  per-mode: auto,
  quantity-separator: auto,
  body-number,
  body-unit,
) = {
  num(
    decimal-separator: decimal-separator,
    uncertainty-mode: uncertainty-mode,
    body-number,
  )

  context {
    if quantity-separator != auto { quantity-separator } else { state-config.get().quantity-separator }
  }

  unit(
    decimal-separator: decimal-separator,
    unit-separator: unit-separator,
    per-mode: per-mode,
    body-unit,
  )
}
