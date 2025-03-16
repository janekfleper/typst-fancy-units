#import "content.typ": unwrap-content
#import "num.typ": (
  interpret-number,
  format-num,
  absolute-uncertainties,
  relative-uncertainties,
)
#import "unit/interpret.typ": interpret-unit
#import "unit/transform.typ": insert-macros
#import "unit/format.typ": format-unit-power, format-unit-fraction, format-unit-symbol
#import "state.typ": (
  state-config,
  state-macros,
  get-decimal-separator,
  configure,
  add-macros,
)

#let _default-num-format() = {
  let config = state-config.get()
  if config.num-format == auto { format-num } else { config.num-format }
}

#let _default-unit-format() = {
  let config = state-config.get()
  if config.unit-format == auto { format-unit-power } else { config.unit-format }
}

#let _apply-functions(element, functions, default) = {
  let _functions = if type(functions) == array { functions } else { (functions,) }
  for func in _functions {
    if func == auto { func = default }
    if func == false { continue }
    assert(type(func) == function, message: "Unknown function type: " + repr(func))
    element = func(element)
  }
  element
}

// A fancy number
//
// - transform (auto, false, function or array): The transformation(s) to apply to the number
// - format (auto, false, function or array): The formatting to apply to the number
// - body (content or dictionary): The number to format
// -> (content or dictionary)
#let num(
  transform: auto,
  format: auto,
  body,
) = context {
  let number = if type(body) == content { interpret-number(body) } else { body }
  number = _apply-functions(number, transform, state-config.get().num-transform)
  return _apply-functions(number, format, _default-num-format())
}

// A fancy unit
//
// - transform (auto, false, function or array): The transformation(s) to apply to the unit
// - format (auto, false, function or array): The formatting to apply to the unit
// - macros (bool): Insert macros
// - body (content or dictionary): The unit to format
// -> (content or dictionary)
#let unit(
  transform: auto,
  format: auto,
  macros: true,
  body,
) = context {
  let unit = if type(body) == content { interpret-unit(body) } else { body }
  if macros == true { unit = insert-macros(unit, state-macros.get()) }
  unit = _apply-functions(unit, transform, state-config.get().unit-transform)
  return _apply-functions(unit, format, _default-unit-format())
}


#let format-qty(separator: auto, num-body, unit-body) = {
  if separator == auto { separator = h(0.2em) }
  (num-body, unit-body).join(separator)
}

// A fancy quantity
//
// - num-transform (auto, false, function or array): The transformation(s) to apply to the number
// - num-format (auto, false, function or array): The formatting to apply to the number
// - unit-transform (auto, false, function or array): The transformation(s) to apply to the unit
// - unit-format (auto, false, function or array): The formatting to apply to the unit
// - format (auto, false, function or array): The formatting to apply to the quantity
// - num-body (content or dictionary): The number to format
// - unit-body (content or dictionary): The unit to format
// -> (content or dictionary)
#let qty(
  num-transform: auto,
  num-format: auto,
  unit-transform: auto,
  unit-format: auto,
  format: auto,
  num-body,
  unit-body,
) = context {
  let config = state-config.get()
  let _format = if format == auto {
    if config.qty-format == auto { format-qty } else { config.qty-format }
  } else { format }


  let _num-body = num(
    transform: num-transform,
    format: num-format,
    num-body,
  )

  let _unit-body = unit(
    transform: unit-transform,
    format: unit-format,
    unit-body,
  )

  if type(_format) == function {
    return _format(_num-body, _unit-body)
  } else {
    panic("Unknown format type: " + str(type(_format)))
  }
}
