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
#import "const.typ": constants

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


// Format a physical constant as a fancy quantity (or fancy number)
//
// The constants are taken from https://physics.nist.gov/cuu/Constants/Table/allascii.txt
//
// - num-transform (auto, false, function or array): The transformation(s) to apply to the number
// - num-format (auto, false, function or array): The formatting to apply to the number
// - unit-transform (auto, false, function or array): The transformation(s) to apply to the unit
// - unit-format (auto, false, function or array): The formatting to apply to the unit
// - format (auto, false, function or array): The formatting to apply to the quantity
// - name (string): The name of the constant
// -> (content)
//
// When using `format-unit-fraction()` the exact formatting is opinionated. If there is a fraction
// with multiple units in the numerator or the denominator, the unit from CODATA is ambiguous.
// As an example, the unit of the Stefan-Boltzmann constant is given as "W m^-2 K^-4" which would be
// formatted as two separate fractions. In this package the recommended input format would be
// "W / (m^2 K^4)" or "W (m^-2 K^-4)" which would result in a single fraction. Since the first pair
// of parentheses is only used for grouping, the unit does not change with `format-unit-power()` or
// `format-unit-symbol()`. The output from `format-unit-fraction()` does however look a lot nicer.
#let const(
  num-transform: auto,
  num-format: auto,
  unit-transform: auto,
  unit-format: auto,
  format: auto,
  name,
) = {
  let constant = constants.at(name)
  let uncertainties = if constant.uncertainty != none { (constant.uncertainty,) } else { none }
  let number = create-num(constant.value, uncertainties: uncertainties, exponent: constant.exponent)
  if constant.unit == none {
    return num(transform: num-transform, format: num-format, number)
  } else {
    return qty(
      num-transform: num-transform,
      num-format: num-format,
      unit-transform: unit-transform,
      unit-format: unit-format,
      format: format,
      number,
      constant.unit,
    )
  }
}

// Retrieve the value of a physical constant
//
// - name (string): The name of the constant
// - output (float or decimal): The type of the output
// -> (float or decimal)
//
// The exponent will only be included if `output` is `float`.
// For the `decimal` type the exponent cannot always be included
// since the type only allows 28 or 29 significant digits.
#let const-value(name, output: float) = {
  if output == float {
    let exponent = constants.at(name).exponent
    let value = float(constants.at(name).value)
    if exponent != none { value = value * calc.pow(10, int(exponent)) }
    value
  } else if output == decimal {
    constants.at(name).value
  } else {
    panic("Unknown output type: " + str(output))
  }
}

// Retrieve the uncertainty of a physical constant
//
// - name (string): The name of the constant
// - output (float or decimal): The type of the output
// -> (float, decimal or none)
//
// If the constant has no uncertainty, `none` is returned.
//
// The exponent will only be included if `output` is `float`.
// For the `decimal` type the exponent cannot always be included
// since the type only allows 28 or 29 significant digits.
#let const-uncertainty(name, output: float) = {
  if constants.at(name).uncertainty == none {
    none
  } else if output == float {
    let exponent = constants.at(name).exponent
    let value = float(constants.at(name).uncertainty)
    if exponent != none { value = value * calc.pow(10, int(exponent)) }
    value
  } else if output == decimal {
    constants.at(name).uncertainty
  } else {
    panic("Unknown output type: " + str(output))
  }
}

// Retrieve the exponent of a physical constant
//
// - name (string): The name of the constant
// -> (decimal or none)
//
// If the constant has no exponent, `none` is returned.
#let const-exponent(name) = {
  constants.at(name).exponent
}

// Retrieve the unit of a physical constant
//
// - name (string): The name of the constant
// -> (dictionary or none)
//
// If the constant has no unit, `none` is returned.
#let const-unit(name) = {
  constants.at(name).unit
}
