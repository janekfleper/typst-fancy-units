#import "../content.typ": wrap-content-math
#import "../state.typ": _get-decimal-separator

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
#let _format-exponent(exponent, separator, base, decimal-separator) = [
  #separator
  #math.attach(base, tr: wrap-content-math(exponent.body, exponent.layers, decimal-separator: decimal-separator).body)
]

// Format the exponent of a number
//
// - number (dictionary): The number to format
// - base (int or float): The base of the exponent
// - separator (symbol): The separator to use
// - decimal-separator (auto, str, symbol or content): The decimal separator to use
// -> (dictionary)
#let format-exponent(number, base: 10, separator: sym.times, decimal-separator: auto) = {
  if number.exponent == none { return number }
  if decimal-separator == auto { decimal-separator = context { _get-decimal-separator() } }
  if type(base) == int or type(base) == float { base = [#base] }
  number.exponent = _format-exponent(number.exponent, separator, base, decimal-separator)
  number
}


// Group a string
//
// - s (str): The string to group
// - size (int): The size of the groups
// - reverse (bool): Assign the groups from right to left
// -> (array of str)
#let _apply-group(s, size, reverse: false) = {
  let digits = s.split("").filter(c => c != "")
  if reverse { digits = digits.rev() }
  let chunks = digits
    .chunks(size)
    .map(c => {
      if reverse { c.rev().join("") } else { c.join("") }
    })
  if reverse { chunks.rev() } else { chunks }
}

// Group the digits of a decimal number
//
// - n (decimal): The value to group
// - mode (auto or str): The parts of the number to group
// - size (int): The size of the groups
// - threshold (int): The minimum number of digits to enable grouping
// - separator (str, symbol or content): The separator to use
// -> ((array of) str or content)
#let _group-digits(n, mode, size, threshold, separator) = {
  let split = str(n).split(".")
  let integer-digits = split.at(0)
  if integer-digits.len() >= threshold and mode == auto or mode == "integer" {
    integer-digits = _apply-group(integer-digits, size, reverse: true).join(separator)
  }

  if split.len() == 1 { return integer-digits }
  let decimal-digits = split.at(1)
  if decimal-digits.len() >= threshold and mode == auto or mode == "decimal" {
    decimal-digits = _apply-group(decimal-digits, size, reverse: false).join(separator)
  }
  (integer-digits, decimal-digits)
}

// Group the digits of an uncertainty
//
// - uc (uncertainty): The uncertainty to group
// - mode (auto or str): The parts of the uncertainty to group
// - size (int): The size of the groups
// - threshold (int): The minimum number of digits to enable grouping
// - separator (str, symbol or content): The separator to use
// -> (uncertainty)
#let _group-digits-uncertainty(uc, mode, size, threshold, separator) = {
  if uc.symmetric {
    uc.body = _group-digits(uc.body, mode, size, threshold, separator)
  } else {
    uc.positive.body = _group-digits(uc.positive.body, mode, size, threshold, separator)
    uc.negative.body = _group-digits(uc.negative.body, mode, size, threshold, separator)
  }
  uc
}

// Group the digits of a number
//
// - number (dictionary): The number to group
// - target (auto or str): The components of the number to target
// - mode (auto or str): The parts of the value and uncertainties to group
// - size (int): The size of the groups
// - threshold (int): The minimum number of digits to enable grouping
// - separator (str, symbol or content): The separator to use
// -> (dictionary)
//
// With the `mode` you can choose between grouping both the integer and
// decimal parts of the number or only either one of them.
#let group-digits(
  number,
  target: auto,
  mode: auto,
  size: 3,
  threshold: 5,
  separator: sym.space.thin,
) = {
  if target == auto or target == "value" {
    number.value.body = _group-digits(number.value.body, mode, size, threshold, separator)
  }
  if target == auto or target == "uncertainties" {
    number.uncertainties = number.uncertainties.map(uc => _group-digits-uncertainty(
      uc,
      mode,
      size,
      threshold,
      separator,
    ))
  }

  number
}


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
  if decimal-separator == auto { decimal-separator = context { _get-decimal-separator() } }

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
    if type(number.exponent) == dictionary {
      c += _format-exponent(number.exponent, sym.times, [10], decimal-separator)
    } else {
      c += number.exponent
    }
  }
  wrap-content-math(c, number.layers, decimal-separator: decimal-separator)
}
