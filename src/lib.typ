#import "content.typ": wrap-content-math
#import "num/interpret.typ": interpret-number
#import "num/transform.typ": absolute-uncertainties, relative-uncertainties
#import "num/format.typ": format-exponent, format-num, group-digits

#import "unit/interpret.typ": interpret-unit
#import "unit/transform.typ": insert-macros
#import "unit/format.typ": format-unit-fraction, format-unit-power, format-unit-symbol
#import "state.typ": _state-config, _state-macros, add-macros, configure

#let format-qty(separator: auto, num-body, unit-body) = {
  if separator == auto { separator = h(0.2em) }
  (num-body, unit-body).join(separator)
}

#let _default-num-format() = {
  let config = _state-config.get()
  if config.num-format == auto { format-num } else { config.num-format }
}

#let _default-unit-format() = {
  let config = _state-config.get()
  if config.unit-format == auto { format-unit-power } else { config.unit-format }
}

#let _default-qty-format() = {
  let config = _state-config.get()
  if config.qty-format == auto { format-qty } else { config.qty-format }
}

#let _apply-functions(element, functions) = {
  let _functions = if type(functions) == array { functions } else { (functions,) }
  for func in _functions {
    if func == none { continue }
    assert(type(func) == function, message: "Unknown function type: " + repr(func))
    element = func(element)
  }
  element
}

// A fancy number
//
// - transform (auto, none or (array of) function): The transformation(s) to apply to the number
// - format (auto, none or (array of) function): The formatting to apply to the number
// - body (content or dictionary): The number to format
// -> (content or dictionary)
#let num(
  transform: auto,
  format: auto,
  body,
) = {
  let number = if type(body) == content { interpret-number(body) } else { body }
  if transform == auto or format == auto {
    context {
      let _transform = if transform == auto { _state-config.get().num-transform } else { transform }
      let _format = if format == auto { _default-num-format() } else { format }
      _apply-functions(_apply-functions(number, _transform), _format)
    }
  } else {
    _apply-functions(_apply-functions(number, transform), format)
  }
}

// A fancy unit
//
// - transform (auto, none or (array of) function): The transformation(s) to apply to the unit
// - format (auto, none or (array of) function): The formatting to apply to the unit
// - macros (auto, none or dictionary): Insert macros
// - body (content or dictionary): The unit to format
// -> (content or dictionary)
#let unit(
  transform: auto,
  format: auto,
  macros: auto,
  body,
) = {
  let unit = if type(body) == content { interpret-unit(body) } else { body }
  if transform == auto or format == auto or macros == auto {
    context {
      let _transform = if transform == auto { _state-config.get().unit-transform } else { transform }
      let _format = if format == auto { _default-unit-format() } else { format }
      let _macros = if macros == auto { _state-macros.get() } else { macros }
      _apply-functions(_apply-functions(insert-macros(unit, _macros), _transform), _format)
    }
  } else {
    _apply-functions(_apply-functions(insert-macros(unit, macros), transform), format)
  }
}

// A fancy quantity
//
// - num-transform (auto, (array of) function or none): The transformation(s) to apply to the number
// - num-format (auto, (array of) function or none): The formatting to apply to the number
// - unit-transform (auto, array of) function or none): The transformation(s) to apply to the unit
// - unit-format (auto, (array of) function or none): The formatting to apply to the unit
// - unit-macros (auto, dictionary or none): Insert unit macros
// - format (auto, function or none): The formatting to apply to the quantity
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
  } else if format == none {
    (num: num-body, unit: unit-body)
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
