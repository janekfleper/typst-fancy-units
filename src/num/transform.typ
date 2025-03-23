// Trim the leading zeros from a number
//
// - s (str): The number
// -> (str)
//
// If the string starts with a "." after the trimming, a zero will be added
// to the start again. This could also be solved with regex, but unfortunately
// the required lookahead is not implemented/allowed.
// If the string already started with a "." before the trimming, no zero will
// be added to the start.
#let _trim-leading-zeros(s) = {
  if not s.starts-with("0") { return s }
  let trimmed = s.trim("0", at: start)
  if trimmed.starts-with(".") { "0" }
  trimmed
}

// Shift the decimal position of a number
//
// - n (decimal): The number
// - shift (int): Decimal shift
// -> (decimal)
//
// The sign of the parameter `shift` is defined such that a positive shift
// will move the decimal position to the right. As an equation this function
// would be $n * 10^shift$.
#let _shift-decimal-position(n, shift) = {
  let s = str(n)
  let split = s.split(".")
  let integer-places = split.at(0).len()
  let decimal-places = split.at(1, default: "").len()
  s = s.replace(".", "")

  if shift >= decimal-places {
    return decimal(_trim-leading-zeros(s + "0" * (shift - decimal-places)))
  } else if -shift >= integer-places {
    return decimal("0." + "0" * calc.abs(shift + integer-places) + s)
  } else {
    let decimal-position = integer-places + shift
    return decimal(_trim-leading-zeros(s.slice(0, decimal-position) + "." + s.slice(decimal-position)))
  }
}

// Count decimal places in a value
//
// - val (decimal): The value to check
// -> (int): Number of decimal places
#let _count-decimal-places(val) = {
  let parts = str(val).split(".")
  if parts.len() > 1 { return parts.at(1).len() }
  return 0
}

// Convert a relative uncertainty to an absolute uncertainty
//
// - uncertainty (dictionary): The relative uncertainty
// - value (dictionary)
// -> (dictionary): The absolute uncertainty
#let _convert-uncertainty-relative-to-absolute(uncertainty, value) = {
  let decimal-places = _count-decimal-places(value.body)
  if decimal-places > 0 {
    if uncertainty.symmetric {
      uncertainty.body = _shift-decimal-position(uncertainty.body, -decimal-places)
    } else {
      uncertainty.positive.body = _shift-decimal-position(uncertainty.positive.body, -decimal-places)
      uncertainty.negative.body = _shift-decimal-position(uncertainty.negative.body, -decimal-places)
    }
  }

  uncertainty.absolute = true
  uncertainty
}

// Convert an absolute uncertainty to a relative uncertainty
//
// - uncertainty (dictionary): The absolute uncertainty
// - value (dictionary)
// -> (dictionary): The relative uncertainty
#let _convert-uncertainty-absolute-to-relative(uncertainty, value) = {
  let decimal-places = _count-decimal-places(value.body)
  if decimal-places > 0 {
    if uncertainty.symmetric {
      uncertainty.body = _shift-decimal-position(uncertainty.body, decimal-places)
    } else {
      uncertainty.positive.body = _shift-decimal-position(uncertainty.positive.body, decimal-places)
      uncertainty.negative.body = _shift-decimal-position(uncertainty.negative.body, decimal-places)
    }
  }

  uncertainty.absolute = false
  uncertainty
}

// Transform all uncertainties to absolute (plus-minus) format
//
// - number (dictionary): The number with uncertainties
// -> (dictionary): Updated number with transformed uncertainties
#let absolute-uncertainties(number) = {
  let uncertainties = number.uncertainties.map(u => {
    if u.absolute { return u }
    return _convert-uncertainty-relative-to-absolute(u, number.value)
  })

  (..number, uncertainties: uncertainties)
}

// Convert all uncertainties to relative (parentheses) format
//
// - number (dictionary): The number with uncertainties
// -> (dictionary): Updated number with transformed uncertainties
#let relative-uncertainties(number) = {
  let uncertainties = number.uncertainties.map(u => {
    if not u.absolute { return u }
    return _convert-uncertainty-absolute-to-relative(u, number.value)
  })

  (..number, uncertainties: uncertainties)
}
