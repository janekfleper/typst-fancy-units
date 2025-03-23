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

#let format-qty(separator: auto, num-body, unit-body) = {
  if separator == auto { separator = h(0.2em) }
  (num-body, unit-body).join(separator)
}

#let _default-num-format() = {
  let config = state-config.get()
  if config.num-format == auto { format-num } else { config.num-format }
}

#let _default-unit-format() = {
  let config = state-config.get()
  if config.unit-format == auto { format-unit-power } else { config.unit-format }
}

#let _default-qty-format() = {
  let config = state-config.get()
  if config.qty-format == auto { format-qty } else { config.qty-format }
}

#let _apply-functions(element, functions) = {
  let _functions = if type(functions) == array { functions } else { (functions,) }
  for func in _functions {
    if func == false { continue }
    assert(type(func) == function, message: "Unknown function type: " + repr(func))
    element = func(element)
  }
  element
}

// A fancy number
//
// - transform (auto, false, function or array): The transformation(s) to apply to the number
// - format (auto, function or array): The formatting to apply to the number
// - body (content or dictionary): The number to format
// -> (content or dictionary)
#let num(
  transform: auto,
  format: auto,
  body,
) = {
  assert(format != false, message: "The 'format' argument must not be false")

  let number = if type(body) == content { interpret-number(body) } else { body }
  if transform == auto or format == auto {
    context {
      let _transform = if transform == auto { state-config.get().num-transform } else { transform }
      let _format = if format == auto { _default-num-format() } else { format }
      _apply-functions(_apply-functions(number, _transform), _format)
    }
  } else {
    _apply-functions(_apply-functions(number, transform), format)
  }
}

// A fancy unit
//
// - transform (auto, false, function or array): The transformation(s) to apply to the unit
// - format (auto, function or array): The formatting to apply to the unit
// - macros (auto, false or dictionary): Insert macros
// - body (content or dictionary): The unit to format
// -> (content or dictionary)
#let unit(
  transform: auto,
  format: auto,
  macros: auto,
  body,
) = {
  assert(format != false, message: "The 'format' argument must not be false")

  let unit = if type(body) == content { interpret-unit(body) } else { body }
  if transform == auto or format == auto or macros == auto {
    context {
      let _transform = if transform == auto { state-config.get().unit-transform } else { transform }
      let _format = if format == auto { _default-unit-format() } else { format }
      let _macros = if macros == auto { state-macros.get() } else { macros }
      _apply-functions(_apply-functions(insert-macros(unit, _macros), _transform), _format)
    }
  } else {
    _apply-functions(_apply-functions(insert-macros(unit, macros), transform), format)
  }
}

// A fancy quantity
//
// - num-transform (auto, false, function or array): The transformation(s) to apply to the number
// - num-format (auto, function or array): The formatting to apply to the number
// - unit-transform (auto, false, function or array): The transformation(s) to apply to the unit
// - unit-format (auto, function or array): The formatting to apply to the unit
// - unit-macros (auto, false or dictionary): Insert unit macros
// - format (auto, function or array): The formatting to apply to the quantity
// - num-body (content or dictionary): The number to format
// - unit-body (content or dictionary): The unit to format
// -> (content or dictionary)
#let qty(
  num-transform: auto,
  num-format: auto,
  unit-transform: auto,
  unit-format: auto,
  unit-macros: auto,
  format: auto,
  num-body,
  unit-body,
) = {
  assert(format != false, message: "The 'format' argument must not be false")

  num-body = num(
    transform: num-transform,
    format: num-format,
    num-body,
  )

  unit-body = unit(
    transform: unit-transform,
    format: unit-format,
    macros: unit-macros,
    unit-body,
  )

  if format == auto {
    context {
      let _format = _default-qty-format()
      _format(num-body, unit-body)
    }
  } else if type(format) == function {
    format(num-body, unit-body)
  } else {
    panic("Unknown format type: " + str(type(format)))
  }
}


// Create a valid number to pass to the function `num()`
//
// - value (string or decimal): The value of the number
// - uncertainties (array of string or decimal): The uncertainties of the number
// - exponent (string or decimal): The exponent of the number
// -> (dictionary)
//
// All numerical values are passed to the function `decimal()`. This imposes a
// limit of 28 to 29 digits. If a value has more digits than this limit, please
// use the `exponent`.
// The uncertainties and the exponent are optional. Uncertainties are always
// interpreted as absolute and symmetric uncertainties. If you want to use
// relative or asymmetric uncertainties, you have to create the required
// dictionary yourself.
#let create-num(value, uncertainties: none, exponent: none) = {
  (value: (body: decimal(value), layers: ()))
  if uncertainties == none { uncertainties = () }
  (uncertainties: uncertainties.map(uc => (body: decimal(uc), absolute: true, symmetric: true, layers: ())))
  if exponent != none { exponent = (body: decimal(exponent), layers: ()) }
  (exponent: exponent)
  (layers: ())
}

// Create a valid unit to pass to the function `unit()`
//
// - unit (string): The unit
// -> (dictionary)
#let create-unit(unit) = {
  (body: unit, layers: ())
}
