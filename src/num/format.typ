#import "../content.typ": wrap-content-math
#import "../state.typ": get-decimal-separator

// Format a symmetric uncertainty
//
// - uncertainty (dictionary)
// - decimal-separator (str, symbol or content): The decimal separator to use
// -> (content)
//
// If the `uncertainty` is absolute, it will be preceded by sym.plus.minus.
// If the `uncertainty` is not absolute, it will be wrapped in parentheses ().
#let _format-symmetric-uncertainty(uncertainty, decimal-separator) = {
  let u = wrap-content-math(uncertainty.body, uncertainty.layers, decimal-separator: decimal-separator)
  if uncertainty.absolute { [#sym.plus.minus] + u } else { math.lr[(#u)] }
}

// Format an asymmetric uncertainty
//
// - positive (dictionary): The positive uncertainty
// - negative (dictionary): The negative uncertainty
// - decimal-separator (str, symbol or content): The decimal separator to use
// -> (content)
//
// The uncertainties are not directly attached to the existing content
// in `format-number()` to ensure that their positions do not depend on
// the content before them.
#let _format-asymmetric-uncertainty(positive, negative, decimal-separator) = {
  math.attach(
    [],
    tr: [#sym.plus] + wrap-content-math(positive.body, positive.layers, decimal-separator: decimal-separator),
    br: [#sym.minus] + wrap-content-math(negative.body, negative.layers, decimal-separator: decimal-separator),
  )
}

// Format the exponent
//
// - exponent (dictionary)
// - decimal-separator (str, symbol or content): The decimal separator to use
// -> (content)
//
// For now the layers are only applied to the actual exponent. The x10
// is not affected.
#let _format-exponent(exponent, decimal-separator) = [
  #sym.times
  #math.attach([10], tr: wrap-content-math(exponent.body, exponent.layers, decimal-separator: decimal-separator))
]

// Format a number
//
// - number (dictionary): The interpreted number
// - decimal-separator (auto, str, symbol or content): The decimal separator to use
// -> (content)
//
// If the `decimal-separator` is auto, context is used to get the separator
// from the state or from the text language.
#let format-num(number, decimal-separator: auto) = {
  // Use provided decimal separator or get from config
  if decimal-separator == auto { decimal-separator = context get-decimal-separator() }

  let c = wrap-content-math(number.value.body, number.value.layers, decimal-separator: decimal-separator)
  let wrap-in-parentheses = false
  for uncertainty in number.uncertainties {
    if uncertainty.symmetric {
      c += _format-symmetric-uncertainty(uncertainty, decimal-separator)
      if uncertainty.absolute { wrap-in-parentheses = true }
    } else {
      let (absolute, positive, negative) = uncertainty
      c += _format-asymmetric-uncertainty(positive, negative, decimal-separator)
      wrap-in-parentheses = true
    }
  }

  if number.exponent != none {
    if wrap-in-parentheses { c = math.lr[(#c)] }
    c += _format-exponent(number.exponent, decimal-separator)
  }
  wrap-content-math(c, number.layers, decimal-separator: decimal-separator)
}
