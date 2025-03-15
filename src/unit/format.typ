#import "../content.typ": unwrap-content, wrap-content-math
#import "../state.typ": state-config, get-decimal-separator
#import "transform.typ": invert-exponent, inherit-exponents

// Bracket wrapper function
//
// - c (content): Content to be wrapped inside the bracket
// - bracket-type (int): Bracket type 0, 1 or 2.
// -> (content)
#let unit-bracket(c, bracket-type) = {
  let body = if type(c) == math.equation and not c.block { c.body } else { c }
  if bracket-type == 0 { math.lr($(#body)$) } else if bracket-type == 1 { math.lr($[#body]$) } else if (
    bracket-type == 2
  ) { math.lr(${#body}$) } else {
    panic("Invalid bracket type " + str(bracket-type))
  }
}

// Apply brackets to a unit
//
// - unit (content): The content to wrap in the brackets
// - brackets (array): The array of brackets to apply
// -> unit (content)
//
// If the outermost brackets are parentheses (type 0), they are removed
// from the array of brackets. This follows the convention that the first
// pair of parentheses is only used for grouping.
#let apply-brackets(unit, brackets) = {
  if brackets.at(-1) == 0 { _ = brackets.pop() }
  for bracket in brackets { unit = unit-bracket(unit, bracket) }
  unit
}

// Join units with a separator
//
// - c (array): Individual (formatted) units
// - group (boolean): Flag to group the units
// - separator (content): Separator if group is false
// -> (content)
#let join-units(c, group, separator) = {
  let join-symbol = if group { [] } else { separator }
  c.join(join-symbol)
}


// Format and attach content to a unit
//
// - unit (content): Base unit
// - decimal-separator (str, symbol or content): The decimal separator to use
// - args (dictionary): Named arguments for the function `math.attach()`
// -> (content)
//
// This is supposed to be used for exponents and subscripts, but in principle
// any valid attachement key can be passed to this function.
//
// Exponents are wrapped in `math.italic()` by default since an exponent will
// most likely be a variable such as "n".
// Subscripts are wrapped in `math.upright()` by default since a subscript will
// most likely be a text to describe a unit or variable such as "rec".
#let unit-attach(unit, decimal-separator, ..args) = {
  let attachements = args.named()
  for key in attachements.keys() {
    let attachement = attachements.at(key)
    if attachement == none or type(attachement) == str { continue }
    attachement = wrap-content-math(
      attachement.body,
      attachement.layers,
      decimal-separator: decimal-separator,
    )
    if key == "tr" { attachements.insert(key, math.italic(attachement)) } else if key == "br" {
      attachements.insert(key, math.upright(attachement))
    } else { attachements.insert(key, attachement) }
  }
  math.attach(unit, ..attachements)
}

// Format a child with string body
//
// - child (dictionary)
//   - body (str)
//   - layers (array)
//   - exponent (dictionary): (Optional) exponent
//   - subscript (dictionary): (Optional) subscript
// - decimal-separator (str, symbol or content): The decimal separator to use
// -> (content)
//
// math.upright() is called after the body is wrapped in the layers to
// allow `emph()` or `math.italic()` to be applied to the body.
#let format-unit-body(child, decimal-separator) = {
  let unit = math.upright(
    wrap-content-math(
      child.body,
      child.layers,
      decimal-separator: decimal-separator,
    ),
  )

  if not ("exponent" in child.keys() or "subscript" in child.keys()) {
    return unit
  }

  unit-attach(
    unit,
    decimal-separator,
    tr: child.at("exponent", default: none),
    br: child.at("subscript", default: none),
  )
}

// Format children into a single unit
//
// - children (array): Individually formatted children
// - tree (dictionary): The (remaining) tree of the unit
// - unit-separator (str, symbol or content): The separator to use between units
// - decimal-separator (str, symbol or content): The decimal separator to use
// -> (content)
#let format-unit(children, tree, separator, decimal-separator) = {
  let unit = join-units(children, tree.group, separator)
  if "brackets" in tree.keys() { unit = apply-brackets(unit, tree.brackets) }
  if "exponent" in tree.keys() { unit = unit-attach(unit, decimal-separator, tr: tree.exponent) }
  wrap-content-math(unit, tree.layers)
}

// Format units with the power mode
//
// - tree (dictionary): The fully interpreted content tree
// - separator (str, symbol or content): The separator to use between units
// - decimal-separator (str, symbol or content): The decimal separator to use
// -> (content)
//
// Around brackets the separator `h(0.2em)` is always used and the
// "separator" is ignored. If the configured separator is e.g. a dot ".",
// it just looks wrong to join units and brackets with that separator.
#let format-unit-power(tree, separator: auto, decimal-separator: auto) = {
  if separator == auto { separator = h(0.2em) }
  if decimal-separator == auto {
    let config-decimal-separator = state-config.get().decimal-separator
    if config-decimal-separator == auto { decimal-separator = get-decimal-separator() } else {
      decimal-separator = config-decimal-separator
    }
  }

  if "body" in tree.keys() { return format-unit-body(tree, decimal-separator) }

  // the definition of protective brackets is broader here compared to `format-unit-fraction()`
  let single-child = tree.children.len() == 1 and ("body" in tree.children.at(0) or tree.children.at(0).group)
  let protective-brackets = "brackets" in tree.keys() and (single-child or tree.brackets != (0,))

  // handle global exponents
  if "exponent" in tree.keys() and not protective-brackets {
    tree = inherit-exponents(tree)
  }

  let c = ()
  let previous-brackets = false
  for child in tree.children {
    let unit = format-unit-power(child, separator: separator, decimal-separator: decimal-separator)
    let brackets = "brackets" in child.keys() and child.brackets != (0,)
    if (brackets or previous-brackets) and c.len() > 0 {
      unit = c.pop() + h(0.2em) + unit
    }
    previous-brackets = brackets
    c.push(unit)
  }

  format-unit(c, tree, separator, decimal-separator)
}

// Format units with the fraction mode
//
// - tree (dictionary): The fully interpreted content tree
// - separator (str, symbol or content): The separator to use between units
// - decimal-separator (str, symbol or content): The decimal separator to use
// -> (content)
//
// Unless a unit or multiple units are protected by brackets,
// the fractions in different levels can be nested. If there
// are multiple ungrouped units with negative indices, they
// will be put in individual fractions that are then joined
// by the `separator`.
#let format-unit-fraction(tree, separator: auto, decimal-separator: auto) = {
  if separator == auto { separator = h(0.2em) }
  if decimal-separator == auto {
    let config-decimal-separator = state-config.get().decimal-separator
    if config-decimal-separator == auto { decimal-separator = get-decimal-separator() } else {
      decimal-separator = config-decimal-separator
    }
  }

  // handle negative global exponents...
  // ...and handle "body-only" trees without exponents or with positive exponents
  if "exponent" in tree.keys() and tree.exponent.body.starts-with("−") {
    return math.frac(
      [1],
      format-unit-fraction(invert-exponent(tree), separator: separator, decimal-separator: decimal-separator),
    )
  } else if "body" in tree.keys() {
    return format-unit-body(tree, decimal-separator)
  }

  // use the per-mode power for children in protective brackets
  let single-child = tree.children.len() == 1 and ("body" in tree.children.at(0) or tree.children.at(0).group)
  if "brackets" in tree.keys() and single-child {
    return format-unit-power(tree, separator: separator, decimal-separator: decimal-separator)
  }

  // handle global exponents
  if "exponent" in tree.keys() and ("brackets" not in tree.keys() or tree.brackets == (0,)) {
    tree = inherit-exponents(tree)
  }

  let c = ()
  for child in tree.children {
    let negative-exponent = "exponent" in child.keys() and child.exponent.body.starts-with("−")
    if negative-exponent { child = invert-exponent(child) }

    let unit = format-unit-fraction(child, separator: separator, decimal-separator: decimal-separator)
    if negative-exponent {
      // a new fraction is started if the previous child is a fraction...
      let previous = if c.len() > 0 and c.at(-1).func() != math.frac { c.pop() } else { [1] }
      unit = math.frac(previous, unit)
    }
    c.push(unit)
  }

  format-unit(c, tree, separator, decimal-separator)
}

// Build the per-separator
//
// - symbol (str, symbol or content): The symbol to indicate a fraction
// - padding (content or dictionary): The padding to use around the symbol
// -> (content)
#let _get-per-separator(symbol, padding) = {
  symbol = if symbol == auto { sym.slash } else if type(symbol) == str { [#symbol] } else { symbol }
  padding = if padding == auto { (left: h(0.05em), right: h(0.05em)) } else if type(padding) != dict {
    (left: padding, right: padding)
  } else { padding }
  padding.left + symbol + padding.right
}

// Format units with a custom symbol as fraction
//
// - tree (dictionary): The fully interpreted content tree
// - symbol (str, symbol or content): The symbol to indicate a fraction
// - padding (content or dictionary): The padding to use around the symbol
// - separator (str, symbol or content): The separator to use between units
// - decimal-separator (str, symbol or content): The decimal separator to use
// -> (content)
//
// The symbol is only used for fractions in the topmost level of
// the hierarchy. Any nested fractions will be formatted with the
// function `format-unit-power()`.
#let format-unit-symbol(tree, symbol: auto, padding: auto, separator: auto, decimal-separator: auto) = {
  let per-separator = _get-per-separator(symbol, padding)
  if separator == auto { separator = h(0.2em) }
  if decimal-separator == auto {
    let config-decimal-separator = state-config.get().decimal-separator
    if config-decimal-separator == auto { decimal-separator = get-decimal-separator() } else {
      decimal-separator = config-decimal-separator
    }
  }

  // handle negative global exponents...
  // ...and handle body-only trees without exponents or with positive exponents
  if "exponent" in tree.keys() and tree.exponent.body.starts-with("−") {
    let unit = (
      [1]
        + per-separator
        + format-unit-power(invert-exponent(tree), separator: separator, decimal-separator: decimal-separator)
    )
    return wrap-content-math(unit, tree.layers)
  } else if "body" in tree.keys() {
    return format-unit-body(tree, decimal-separator)
  }

  // handle positive global exponents
  if "exponent" in tree.keys() and ("brackets" not in tree.keys() or tree.brackets == (0,)) {
    tree = inherit-exponents(tree)
  }

  let c = ()
  for child in tree.children {
    let negative-exponent = "exponent" in child.keys() and child.exponent.body.starts-with("−")
    if negative-exponent { child = invert-exponent(child) }

    let unit = format-unit-power(child, separator: separator, decimal-separator: decimal-separator)
    if negative-exponent {
      let previous = if c.len() > 0 { c.pop() } else { [1] }
      unit = previous + per-separator + unit
    }
    c.push(unit)
  }

  format-unit(c, tree, separator, decimal-separator)
}
