#import "content.typ": unwrap-content, wrap-content-math


#let pattern-exponent = regex("\^(−?\d+(?:(?:\/[1-9]\d*)|(?:\.\d*[1-9]))?)")
#let pattern-fraction = regex("\/ *(?:[\D]|$)")

#let brackets = ("(", "[", "{", ")", "]", "}")
#let pattern-bracket = regex(brackets.map(bracket => "(\\" + bracket + ")").join("|"))

// Find pairs of brackets in the content tree
// 
// - tree (dictionary): The content tree
// -> pairs (array): Pairs of brackets
//   - (dictionary)
//     - type (int): Bracket type
//     - open (dictionary): Child index of the open bracket and position in the child text
//     - close (dictionary): Child index of the close bracket and position in the child text
// 
// The (open) brackets are tracked across the children and kept in a separate list.
// When a closing bracket is found, it is paired up with the last open bracket.
// If the bracket types do not match, an error will be raised.
// If there are any open brackets left after iterating over all children, an error
// will also be raised.
#let find-brackets(tree) = {
  let pairs = ()
  let open = ()

  for i in range(tree.children.len()) {
    let child = tree.children.at(i)
    if not child.keys().contains("text") { continue }
    for match in child.text.matches(pattern-bracket) {
      // the bracket type is "encoded" in the group index
      let bracket-type = match.captures.position(x => x != none)
      // types 0, 1 and 2 are the open brackets
      if bracket-type < 3 { open.push((type: bracket-type, child: i, position: match.start)) }
      else {
        assert.ne(open, (), message: "error when matching brackets...")
        let (type: open-bracket-type, ..open-bracket) = open.pop()
        assert.eq(bracket-type - 3, open-bracket-type, message: "error when matching brackets...")
        pairs.push((type: open-bracket-type, open: open-bracket, close: (child: i, position: match.start)))
      }
    }
  }

  if open.len() > 0 { panic("error when matching brackets...") }

  // sort the pairs to be ordered by open.child and open.position
  pairs.sorted(key: pair => pair.open.position).sorted(key: pair => pair.open.child)
}


// Offset a bracket location
//
// - bracket (dictionary): Open or close bracket
//   - child (int): Child index in the content tree
//   - position (int): Bracket position in the child text
// - offset (dictionary): Offset to apply to the `bracket`
//   - child (int)
//   - position (int)
// -> bracket (dictionary): Bracket with shifted child or position
//
// If the bracket and the offset have a different child index, the offset
// points to a different child. In that case the child index has to be
// changed but the position is conserved.
// If the bracket and the offset have the same child index, only the
// position has to be shifted.
#let offset-bracket(bracket, offset) = {
  // the offset.child always has to be subtracted!
  let child = bracket.child - offset.child
  // the position is only subtracted if bracket.child and offset.child are equal!
  let position = if child > 0 { bracket.position } else { bracket.position - offset.position - 1 }
  return (child: child, position: position)

  // this is the old version of the function...
  if bracket.child != offset.child {
    (child: bracket.child - offset.child, position: bracket.position)
  } else {
    (child: bracket.child, position: bracket.position - offset.position - 1)
  }
}

// Offset the locations of bracket pairs
//
// - pairs (array): All (remaining) bracket pairs
// - offset (dictionary): Offset to apply to the brackets in `pairs`
//   - child (int)
//   - position (int)
// -> pairs (array): Shifted bracket pairs
//
// This function will apply `shift-bracket-offset()` to every "open" and
// "close" bracket in the `pairs`.
#let offset-bracket-pairs(pairs, offset) = {
  pairs.map(
    pair => (
      type: pair.type,
      open: offset-bracket(pair.open, offset),
      close: offset-bracket(pair.close, offset)
    )
  )
}

// Get the children before the opening bracket
//
// - children (array): All the children in the current tree level
// - pair (dictionary): Bracket pair
//   - type (int): Bracket type
//   - open (dictionary): Open bracket
//   - close (dictionary): Close bracket
// -> (array): The children up to the opening bracket
#let get-opening-children(children, pair) = {
  // get the "full" children up to the open child...
  children.slice(0, pair.open.child)

  // ... and add text in the "open-child" up to the open position
  let open-child = children.at(pair.open.child)
  if pair.open.position > 0 {
    let pre = open-child.text.slice(0, pair.open.position)
    ((text: pre, layers: open-child.layers),)
  }
}

// Get the children inside the bracket pair
//
// - children (array): All the children in the current tree level
// - pair (dictionary): Bracket pair
//   - type (int): Bracket type
//   - open (dictionary): Open bracket
//   - close (dictionary): Close bracket
// -> (array): The children inside the bracket `pair`
#let get-inner-children(children, pair) = {
  let open-child = children.at(pair.open.child)
  let close-child = children.at(pair.close.child)

  if pair.open.child == pair.close.child {
    let text = open-child.text.slice(pair.open.position + 1, pair.close.position)
    ((text: text, layers: open-child.layers),)
  } else {
    (
      (text: open-child.text.slice(pair.open.position + 1), layers: open-child.layers),
      ..children.slice(pair.open.child + 1, pair.close.child),
      (text: close-child.text.slice(0, pair.close.position), layers: close-child.layers)
    )
  }
}

// Get the children after the closing bracket
//
// - children (array): All the children in the current tree level
// - pair (dictionary): Bracket pair
//   - type (int): Bracket type
//   - open (dictionary): Open bracket
//   - close (dictionary): Close bracket
// -> (array): The children after the opening bracket
#let get-closing-children(children, pair) = {
  let close-child = children.at(pair.close.child)

  if pair.close.position + 1 < close-child.text.len() {
    let post = close-child.text.slice(pair.close.position + 1)
    ((text: post, layers: close-child.layers),)
  }

  // add children after the "close-child"
  children.slice(pair.close.child + 1)
}

// Get the bracket pairs inside the current bracket pair
//
// - pairs (array): All (remaining) bracket pairs
// - close (dictionary): Closing bracket of the current bracket pair
// -> pairs (array): Bracket pairs inside the current bracket pair
//
// Since the current bracket pair is always the first one, the filter only
// has to check the "child" and "position" compared to the closing bracket.
#let get-inner-pairs(pairs, close) = {
  pairs.filter(pair =>
    pair.close.child < close.child or
    (pair.close.child == close.child and pair.close.position < close.position)
  )
}

// Get the bracket pairs after the current bracket pair
//
// - pairs (array): All (remaining) bracket pairs
// - close (dictionary): Closing bracket of the current bracket pair
// -> pairs (array): Bracket pairs after the current bracket pair
//
// Since the current bracket pair is always the first one, the filter only
// has to check the "child" and "position" compared to the closing bracket.
#let get-closing-pairs(pairs, close) = {
  pairs.filter(pair =>
    pair.close.child > close.child or
    (pair.close.child == close.child and pair.close.position > close.position)
  )
}

// Wrap children in a bracket layer
//
// - children (array): Children in the bracket `pair`
// - pair (dictionary): Bracket pair
// -> (array): The branch/leaf for the content tree
//
// If there is only one child in the `children`, the bracket
// can just be added to the field "brackets".
// If there are multiple children in the `children`, everything
// has to be wrapped again in a new branch/leaf to include the
// "brackets".
#let wrap-children(children, pair) = {
  if children.len() == 1 {
    let brackets = children.at(0).at("brackets", default: ())
    brackets.push(pair.type)
    children.at(0).insert("brackets", brackets)
    children
  } else {
    ((
      children: children,
      layers: (),
      brackets: (pair.type,)
    ),)
  }
}

#let group-brackets-children(children, pairs) = {
  // return the entire children if there are no more bracket pairs...
  if pairs.len() == 0 { return children }
  // return the entire children if none of the bracket pairs are in current children
  if children.len() < pairs.at(0).open.child { return children }
  let pair = pairs.remove(0)

  // start with the opening children...
  get-opening-children(children, pair)

  // get the bracket pair and the inner children...
  let inner-children = get-inner-children(children, pair)
  let inner-pairs = offset-bracket-pairs(get-inner-pairs(pairs, pair.close), pair.open)
  wrap-children(group-brackets-children(inner-children, inner-pairs), pair)

  // get the closing children...
  let closing-children = get-closing-children(children, pair)
  // why do I have to increment the child index here...?
  // children missing in the "closing-children" have to be compensated with the offset here...
  let closing-offset = (
    // child: pair.close.child + children.len() - closing-children.len(),
    child: children.len() - closing-children.len(),
    position: pair.close.position
  )
  let closing-pairs = offset-bracket-pairs(get-closing-pairs(pairs, pair.close), closing-offset)
  group-brackets-children(closing-children, closing-pairs)
}


// Invert the sign of an exponent
//
// - s (str)
// -> (str)
//
// This function just checks if `s` starts with "-" and removes
// (or adds) it if it does (not) start with one.
#let invert-exponent(s) = {
  if s.starts-with("−") { s.trim("−", at: start) }
  else { "−" + s }
}

// Apply an exponent to a child
//
// - child (dictionary): The child to update
// - exponent (dictionary): The exponent to be applied
//   - text (str)
//   - layers (array)
// -> child (dictionary)
//
// If an exponent already exists in the `child`, the layers of that
// exponent are conserved and the `layers` of the new `exponent` are
// ignored.
#let apply-exponent(child, exponent) = {
  if not "exponent" in child.keys() { (..child, exponent: exponent) }
  else if exponent.text == "−1" {
    child.exponent.text = invert-exponent(child.exponent.text)
    child
  } else if child.exponent.text == "−1" {
    child.exponent.text = invert-exponent(exponent.text)
    child
  } else {
    let fraction = exponent.text.split("/")
    let child-fraction = child.exponent.text.split("/")
    let numerator = int(fraction.at(0)) * int(child-fraction.at(0))
    let denominator = int(fraction.at(1, default: "1")) * int(child-fraction.at(1, default: "1"))
    let gcd = calc.gcd(numerator, denominator)
    if gcd == denominator { child.exponent.text = str(numerator) }
    else if gcd == 1 { child.exponent.text = str(numerator) + "/" + str(denominator) }
    else { child.exponent.text = str(numerator / gcd) + "/" + str(denominator / gcd) }
    child
  }
}

// Find an exponent in a child with text
//
// - child (dictionary)
//   - text (str)
//   - layers (array)
//   - exponent (dictionary): (Optional) exponent
// - units (array): Units accumulated up to the `child`
// -> units (array): Updated array of units
//
// Any text directly after an exponent is simply ignored. There should
// always be a space after an exponent which allows the text to be split
// in this function.
// Passing all the `units` to the function is required because an exponent
// is always applied to the (current) last unit. It is possible that no
// element is added to the `units` in this function. Therefore, all of the
// `units` are passed to this function.
// The `child` will not have the field "brackets" since these cases are
// handled separately in the parent function `find-exponents()`.
#let find-exponents-text(child, units) = {
  let (text, ..child) = child
  for unit in text.split(" ") {
    if unit.trim(" ") == "" { continue } // discard empty strings again...

    let match = unit.match(pattern-exponent)
    if match == none {
      if unit.contains("^") { panic("Invalid exponent format") }
      units.push((text: unit, ..child))
      continue
    }
    let exponent = match.captures.at(0)
    // is this even necessary? The "match" should just be none already...
    assert.ne(exponent, "", message: "Empty exponent in child '" + unit + "'")

    // let base = match.captures.at(0)
    // units.push((text: base, ..child))
    let unit = unit.slice(0, match.start)
    if unit != "" { units.push((text: unit, ..child)) }
    units.at(-1) = apply-exponent(units.at(-1), (text: exponent, ..child))
  }

  units
}

#let group-units(units) = {
  let i = 0
  let groups = ()
  while i < units.len() {
    let child = units.at(i)
    // if the "child" has the key "children", it is treated just like a single unit here
    if "text" in child.keys() and child.text == ":" {
      assert.ne(i, 0, message: "Colons are not allowed at the start of a group.")
      i = i + 1
      assert.ne(i, units.len(), message: "Colons are not allowed at the end of a group.")
      if units.at(i).text == ":" { panic("Consecutive colons are not allowed.") }
      groups.at(-1).push(i)
    } else {
      groups.push((i,))
    }
    i = i + 1
  }

  for group in groups {
    group = group.map(i => units.at(i))
    if group.len() == 1 {
      let child = group.at(0)
      if "children" in child.keys() { child.insert("group", false) }
      (child,)
      continue
    }

    let single-units = group.all(unit => "text" in unit.keys())
    assert(single-units, message: "Only single units can be grouped.")

    let exponents = group.slice(0, -1).any(unit => "exponent" in unit.keys())
    assert(not exponents, message: "Only the last unit in a group can have an exponent.")

    let props = (layers: ())
    let exponent = group.at(-1).remove("exponent", default: none)
    if exponent != none { props.insert("exponent", exponent) }
    if group.all(unit => unit.layers == ()) {
      ((text: group.map(unit => unit.text).join(), ..props),)
    } else {
      ((children: group, ..props, group: true),)
    }
  }
}

// is it possible to merge brackets here?
#let simplify-units(tree, children) = {
  // remove children with text "1" to avoid a leading "1" if it is not necessary
  // the "1" will be added again in `format-unit()` if it is required...
  children = children.filter(child => (not child.keys().contains("text")) or child.text != "1")
  
  if children.len() > 1 or "brackets" in tree.keys() {
    (..tree, children: children)
  } else {
    let child = children.at(0)
    child.layers += tree.layers
    if "subscript" in child.keys() { child.subscript.layers += tree.layers }
    if "exponent" in child.keys() { child.exponent.layers += tree.layers }
    if "exponent" in tree.keys() { child = apply-exponent(child, tree.exponent) }
    child
  }
}

#let find-exponents(tree) = {
  let units = ()
  let invert-units = ()

  for child in tree.children {
    if "children" in child.keys() { units.push(find-exponents(child)); continue }
    if child.text.trim(" ") == "" { continue } // discard empty children...

    // handle subscripts...
    if child.layers.contains((sub, (:))) { 
      let layers = child.layers.filter(layer => layer != (sub, (:)))
      units.at(-1).insert("subscript", (..child, layers: layers))
      continue
    }

    // remove the "text" field since it will be replaced in any new child anyway...
    let (text, ..child) = child
    // wrap everything in a sub-tree if the child is inside of a bracket...
    if "brackets" in child.keys() {
      units.push(find-exponents((children: ((text: text, layers: ()),), ..child)))
      continue
    }

    while text.trim(" ") != "" {
      let match = text.match(pattern-fraction)
      if match == none {
        units = find-exponents-text((text: text, ..child), units)
        break
      }

      units = find-exponents-text((text: text.slice(0, match.start), ..child), units)
      // store the current length to invert the next child...
      invert-units.push(units.len())
      text = text.slice(match.start + 1)
    }
  }

  // the units have to be grouped before applying the inversions...
  units = group-units(units)
  for i in invert-units {
    units.at(i) = apply-exponent(units.at(i), (text: "−1", layers: ()))
  }
  simplify-units(tree, units)
}


// Pass down the exponent from the tree to the children
//
// - tree (dictionary)
//   - children (array)
//   - exponent (dictionary)
// -> tree (dictionary)
//
// The field "exponent" is always removed from the returned tree.
// If the tree is a grouped unit, the exponent is only applied to the last
// child. Otherwise the exponent is applied to all children.
#let inherit-exponents(tree) = {
  let exponent = tree.remove("exponent")
  if tree.group { tree.children.at(-1) = apply-exponent(tree.children.at(-1), exponent) }
  else { tree.children = tree.children.map(child => apply-exponent(child, exponent)) }
  tree
}

// Bracket wrapper function
//
// - c (content): Content to be wrapped inside the bracket
// - type (int): Bracket type 0, 1 or 2.
// -> (content)
#let unit-bracket(c, type) = {
  if type == 0 [
    (#c)
  ] else if type == 1 [
    [#c]
  ] else if type == 2 [
    {#c}
  ] else [
    #panic("Invalid bracket type " + str(type))
  ]
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
// - unit-separator (content): Separator if group is false
// -> (content)
#let join-units(c, group, unit-separator) = {
  let join-symbol = if group { [] } else { unit-separator }
  c.join(join-symbol)
}


// Format and attach content to a unit
// 
// - unit (content): Base unit
// - args (dictionary): Named arguments for the function `math.attach()`
// -> (content)
// 
// This is supposed to be used for exponents and subscripts, but in principle
// any valid attachement key can be passed to this function. 
#let unit-attach(unit, ..args) = {
  let attachements = args.named()
  for key in attachements.keys() {
    let attachement = attachements.at(key)
    if type(attachement) == str { continue }
    attachements.insert(key, wrap-content-math(attachement.text, attachement.layers))
  }
  math.attach(unit, ..attachements)
}

// Calling `format-unit()` here is not possible since the function
// is only defined after this function. This function will therefore
// only take care of the preparation to use a fraction in the unit.
#let prepare-frac(child) = {
  child.exponent.text = child.exponent.text.trim("−")
  if child.exponent.text == "1" { _ = child.remove("exponent") }
  child
}

// Format a child with text
// 
// - child (dictionary)
//   - text (str)
//   - layers (array)
//   - exponent (dictionary): (Optional) exponent
// -> (content)
// 
// math.upright() is called after the text is wrapped in the layers to
// allow `emph()` or `math.italic()` to be applied to the text.
#let format-unit-text(child) = {
  let unit = math.upright(wrap-content-math(child.text, child.layers))
  if "exponent" in child.keys() { unit = unit-attach(unit, tr: child.exponent) }
  unit
}

// simplify this???
#let format-unit-fraction-text(tree) = {
  let negative-exponent = tree.keys().contains("exponent") and tree.exponent.text.starts-with("−")
  if negative-exponent {
    math.frac([1], format-unit-text(prepare-frac(tree)))
  } else {
    format-unit-text(tree)
  }
}


#let format-unit-power(tree, ..args) = {
  let brackets = tree.at("brackets", default: none)
  if "text" in tree.keys() { return format-unit-text(tree) }

  // handle "global" exponents
  if "exponent" in tree.keys() and (brackets == none or brackets == (0,)) {
    tree = inherit-exponents(tree)
  }

  let c = tree.children.map(child => format-unit-power(child, ..args))
  let unit = join-units(c, tree.group, args.named().unit-separator)
  if brackets != none { unit = apply-brackets(unit, brackets) }
  if "exponent" in tree.keys() { unit = unit-attach(unit, tr: tree.exponent) }
  wrap-content-math(unit, tree.layers)
}

#let format-unit-fraction(tree, ..args) = {
  let brackets = tree.at("brackets", default: none)
  // handle protective brackets with the function format-unit-power()
  if brackets != none and tree.children.len() == 1 { return format-unit-power(tree, ..args) }
  if "text" in tree.keys() { return format-unit-fraction-text(tree) }

  // handle "global" exponents
  if "exponent" in tree.keys() {
    let negative-exponent = tree.exponent.text.starts-with("−")
    if negative-exponent { tree = prepare-frac(tree) }
    else if brackets == none or brackets == (0,) { tree = inherit-exponents(tree) }

    // only return here if the global exponent is actually negative...
    if negative-exponent { return math.frac([1], format-unit-fraction(tree, ..args)) }
    // ...otherwise the rest of the function can handle the formatting
  }

  let c = ()
  for child in tree.children {
    let negative-exponent = "exponent" in child.keys() and child.exponent.text.starts-with("−")
    if negative-exponent { child = prepare-frac(child) }

    let unit = format-unit-fraction(child, ..args)
    if negative-exponent {
      // a new fraction is started if the previous child is a fraction...
      let previous = if c.len() > 0 and c.at(-1).func() != math.frac { c.pop() } else { [1] }
      unit = math.frac(previous, unit)
    }
    c.push(unit)
  }

  let unit = join-units(c, tree.group, args.named().unit-separator)
  if brackets != none { unit = apply-brackets(unit, brackets) }
  if "exponent" in tree.keys() { unit = unit-attach(unit, tr: tree.exponent) }
  wrap-content-math(unit, tree.layers)
}