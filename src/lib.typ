#import "content.typ": wrap-component, wrap-content
#import "number.typ": interpret-number-content

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

#let state-config = state("siunity-config", (
  "uncertainty-format": "plus-minus",
  "decimal-character": ".",
  "unit-spacing": "0.1",
))
#let state-units = state("siunity-units", (:))

#let _uncertainty-format-alias-plus-minus = ("plus-minus", "+-", "pm")
#let _uncertainty-format-alias-parentheses = ("parentheses", "()")
#let _uncertainty-format-options = _uncertainty-format-alias-plus-minus + _uncertainty-format-alias-parentheses
#let _check-uncertainty-format(format) = {
  if type(format) == _function-type {
    return
  } else if type(format) == _str-type {
    let message = "Illegal uncertainty-format '" + format + "'"
    assert(_uncertainty-format-options.contains(format), message: message)
  } else {
    let message = "Illegal type '" + type(format) + "' for uncertainty-format"
    panic(message)
  }
}

#let update-config(key, value) = {
  let update(s) = {
    s.insert(key, value)
    return s
  }
  return update
}

#let update-units(units) = {
  let update(s) = {
    if units == none { return s }
    for (key, value) in units.pairs() { s.insert(key, value) }
    return s
  }
  return update
}

#let siunity-configure(uncertainty-format: none, units: none) = {
  if uncertainty-format != none {
    _check-uncertainty-format(uncertainty-format)
    state-config.update(update-config("uncertainty-format", uncertainty-format))
  }

  state-units.update(update-units(units))
}

#let parse-input(content) = {
  if content.has("text") { return content.text }

  let children = ()
  for child in content.children {
    if child.has("text") {
      children.push(child.text)
    }
  }
  return children//.join("")
}

#let num(decimal: "auto", uncertainty-format: none, content) = {
  let input = parse-input(content)
  // return input.split("+-")
  // let _text = if content.has("text") { content.text } else { content.children.join(" ") }
  let (value, uncertainty) = input.split("+-")

  context {
    let uncertainty-format = if uncertainty-format == none { state-config.get().uncertainty-format } else { uncertainty-format }

    if type(uncertainty-format) == _function-type [
      abc
      $#display_uncertainty(value, uncertainty)$
    ] else {
      if _uncertainty-format-alias-plus-minus.contains(uncertainty-format) [
        $value plus.minus uncertainty$
      ] else if _uncertainty-format-alias-parentheses.contains(uncertainty-format) [
        $value (uncertainty)$
      ]
    }
  }
}

#let unit(content) = context {
  if content.has("text") {
    let name = content.text
    let units = state-units.get()
    if units.keys().contains(name) {
      return $units.at(name)$
    } else {
      return $content.text$
    }
  }

  return content.children
  // let unit = content.text
  return $content$
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