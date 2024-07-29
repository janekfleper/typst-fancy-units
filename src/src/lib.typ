#import "content.typ": wrap-component, wrap-content
#import "number.typ": interpret-number-content

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