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

#let num(
  transform: auto,
  format: auto,
  body,
) = context {
  let number = interpret-number(body)
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
    if config.num-format == auto { format-num } else { config.num-format }
  } else { format }

  if type(_format) == function {
    return _format(number)
  } else if type(_format) == array {
    for func in format { number = func(number) }
    return number
  } else if _format == false or _format == none {
    // Do nothing
  } else {
    panic("Unknown format type: " + str(type(_format)))
  }
  return number
}

#let unit(
  transform: auto,
  format: auto,
  body,
) = context {
  let tree = interpret-unit(body)
  let config = state-config.get()
  let tree = insert-macros(tree, state-macros.get())

  let _transform = if transform == auto { config.unit-transform } else { transform }
  if type(_transform) == array {
    for func in _transform { tree = func(tree) }
  } else if type(_transform) == function {
    tree = _transform(tree)
  } else if _transform == false {
    // Do nothing
  } else {
    panic("Unknown transform type: " + str(type(_transform)))
  }

  let _format = if format == auto {
    if config.unit-format == auto { format-unit-power } else { config.unit-format }
  } else { format }
  if type(_format) == array {
    for func in format { tree = func(tree) }
  } else if type(_format) == function {
    tree = _format(tree)
  } else if _format == false or _format == none {
    // Do nothing
  } else {
    panic("Unknown format type: " + str(type(_format)))
  }
  tree
}


#let format-qty(separator: auto, num-body, unit-body) = {
  if separator == auto { separator = h(0.2em) }
  (num-body, unit-body).join(separator)
}

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
