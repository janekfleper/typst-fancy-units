#import "lib.typ": *
#import "src/number.typ": *
#import "src/content.typ": *
#import "src/lib.typ": *
#import "units.typ": units

#set page(paper: "a4")

#siunity-configure(
  units: units,
  uncertainty-format: "()",
)

// per-mode: "power", "fraction", [content]
#let state-config = state("fancy-units-config", (
  "uncertainty-format": "plus-minus",
  "decimal-character": ".",
  "unit-spacing": "0.1",
  "unit-separator": sym.dot,
  "per-mode": "power",
))
#let state-units = state("fancy-units", (:))

#let parse-input(content) = {
  if content.has("text") { return content.text }

  let children = ()
  for child in content.children {
    if child.has("text") {
      children.push(child.text)
    }
  }
  return children//.join(" ")
}

#let numbers = (
  [0.9],
  [-0.9],
  [+0.9],
  [0.9+-0.1],
  [0.9 +-0.1],
  [0.9+- 0.1],
  [0.9 +- 0.1],
  [0.9(1)],
  [0.9 (1)],
)

#let pattern-unit = regex("([^\(\)\s\d\^]+)(?:\^(\d+))?")

#let find-units(leaves) = {
  let units = ()
  for (text, path) in leaves {
    for match in text.matches(pattern-unit) {
      // the exponent will automatically default to none if it was not captured
      units.push((unit: match.captures.at(0), exponent: match.captures.at(1), path: path))
    }
  }
  units
}

#let parentheses(c, format: "math") = {
  if format == "math" [#math.lr([(#c)])] else [(#c)]
}

// #let pattern-open = regex("[\(\[\{<]")
// #let pattern-close = regex("[\)\]\}>]")
#let pattern-open = regex("(\()|(\[)|(\{)|(<)")
#let pattern-close = regex("(\))|(\])|(\})|(>)")
#let pattern-bracket = regex("(\()|(\[)|(\{)|(<)|(\))|(\])|(\})|(>)")

#let brackets = ("(", "[", "{", ")", "]", "}")
#let pattern-bracket = regex(brackets.map(bracket => "(\\" + bracket + ")").join("|"))

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

// Include the actual bracket in the error message
// 
// - leaves (array): Leaves from the content tree
// - type (int): Bracket type (0 - 5)
// -> (str): Error message
#let unmatched-bracket-message(leaves, type) = {
  "Unmatched bracket "
  brackets.at(type)
  " in '"
  leaves.map(leaf => leaf.text).join()
  "'"
}

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
  if s.starts-with("-") { s.trim("-", at: start) }
  else { "-" + s }
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
  else if exponent.text == "-1" {
    child.exponent.text = invert-exponent(child.exponent.text)
    child
  } else if child.exponent.text == "-1" {
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

#let pattern-exponent = regex(":\^(?:-?)")//"(-[+\.\/\d]*)")
// The base is directly included in the pattern. If there is no base captured,
// this will count as an exponent format error. If the base contains a "^", this
// is also a format error.
#let pattern-exponent = regex("([^^]+)\^(-?\d+(?:(?:\/[1-9]\d*)|(?:\.\d*[1-9]))?)")
#let pattern-fraction = regex("\/[\D]")
#let pattern-fraction = regex("\/ *(?:[\D]|$)")


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
    let exponent = match.captures.at(1)
    // is this even necessary? The "match" should just be none already...
    assert.ne(exponent, "", message: "Empty exponent in child '" + unit + "'")

    let base = match.captures.at(0)
    units.push((text: base, ..child))
    // let unit = unit.slice(0, match.start)
    // if unit != "" { units.push((text: unit, ..child)) }
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

    let last-unit = group.pop()
    let exponents = group.any(unit => "exponent" in unit.keys())
    assert(not exponents, message: "Only the last unit in a group can have an exponent.")

    let props = (layers: ())
    let exponent = last-unit.remove("exponent", default: none)
    if exponent != none { props.insert("exponent", exponent) }
    ((children: (..group, last-unit), ..props, group: true),)
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
    let layers = tree.layers
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
    units.at(i) = apply-exponent(units.at(i), (text: "-1", layers: ()))
  }
  // simplify-units(tree, group-units(units))
  simplify-units(tree, units)

  // let children = group-units(units)
  // // return (..tree, children: children)
  // if children.len() > 1 {
  //   (..tree, children: children)
  // } else {
  //   let child = children.at(0)
  //   let layers = tree.layers
  //   child.layers += layers
  //   if "subscript" in child.keys() { child.subscript.layers += layers }
  //   if "exponent" in tree.keys() { child = apply-exponent(child, tree.exponent) }
  //   child
  // }
}



// Do this with a parameter "mode" in the regular function `wrap-content()`?

// So far this function replaces the following layer functions:
//    strong -> math.bold
//    emph -> math.italic
#let wrap-content-math(c, layers) = {
  for (func, fields) in layers {
    if func == strong { func = math.bold }
    if func == emph { func = math.italic }
    if "styles" in fields.keys() { c = func(c, fields.styles) }
    else { c = func(c, ..fields) }
  }
  c
}

#let unit-attach-old(unit, exponent: none, subscript: none) = {
  if subscript != none and type(subscript) != str {
    subscript = wrap-content-math(subscript.text, subscript.layers)
  }
  if exponent != none { exponent = wrap-content-math(exponent.text, exponent.layers) }
  math.attach(unit, tr: exponent, br: subscript)
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

// Prepend a one if the content array is empty
//
// The per-mode "fraction" or a custom per-mode as content requires
// some content as the numerator. If the array of content children is
// empty so far, a simple [1] is pushed to the array as the numerator.
//
// - c (array): Content array in `format-unit()`
// -> (array)
#let pad-one(c) = {
  if c.len() == 0 { c.push([1]) }
  c
}


// $#math.italic[E]#sub[rec]$
$#math.attach([E], br: [rec], tr: [2])$


// #let u = [μg^ s m / s^2]
#let u = [_*(kg m^ / s)*_ {_E_}#sub[rec]]
// #let u = [(((a b c) *d   e)  f*)]
#let u = [abc ((*(a b c)* d  e){}  f)    defasdf]
#let u = [abc((*(a b c)* d a) () {f})]
// #let u = [*kg* (μm^2)]
// #let u = [(μm / *s*)^2 abc]
// #let u = [kg /m^3 s^2]
// #let u = [kg/ *micro*:m^2]///(s/kg)^3]
#let u = [(kg^-2 / (μm / Joule))^2]
#let u = [kg / (μm / Joule)]
#let u = [_E^2_#sub[rec]]

// bug with parentheses detection...
#let u = [[((a:_u_:g^2 m))]^-1 cm^3 / abc^-3]
#let u = [(({a:_u_:g^2 m}))^-1 cm^3 / (abc^-3)]
#let u = [(({a:b^2 m}))^-1 cm^3 / (abc^-3)]
#let u = [kg / ((((abc^-6) kg m s^2))^12)]
// #let u = [kg / (kg:s:m^2 m^3 s^2)]
#let u = [kg / (s^-2)]
// #let u = [kg / ((abc^-3) m s) ^2]
// #let u = [kg / abc^3]
// #let u = [kg abc^3]

// per-mode = "fraction", the exponent two should be applied to the children?
// #let u = [kg / a:b:c (((ab^-3) kg m))^2]

// per-mode = "fraction", there is no fraction 1/ab^6
// #let u = [kg / a:b:c (ab^-3 kg m)^2]

// per-mode = "fraction", the denominator turns into a really weird stack of fractions...
// #let u = [kg / (((ab^-3) kg m)^-2)]

// this should raise an error due to an invalid exponent...
#let u = [1 / a:m^-1/2]

#let u1 = [1 / (a b)]
#let uc = [c / (a b)]
// #let u = [c / (a b)]

// the exponent one shouldn't be there...
// #let u = [kg m / s^-1]

// #let u = [1 / (abc^-2)^2]
// #let u = [(abc^-2)^2]


// #let u = [kg / (d abc^3)]
// #let u = [(({cm a^2}))^-1 cm^3 / ((abc^-3))]
// #let u = [a:#text(red)[b]:c^2 def kg]
// #let u = [a:b:c f]
// #let u = [/kg]
// #let u = [(kg *m*)*^-1*]
// #let u = [_kg_ m#sub[abc]^2]
// #let u = [*a#sub[abc]*^2]
// #let u = [abc(((a b c)  d e)a f)]
// #let u = [abc(((*a b c*) d e)a f)]

// #let bare-tree = unwrap-content(u)
// // wrap the "text" child to use the functions find-brackets() and group-brackets-children()
// #if bare-tree.keys().contains("text") { bare-tree = (children: (bare-tree,), layers: ()) }
// #let pairs = find-brackets(bare-tree)
// #let brackets-children = group-brackets-children(bare-tree.children, pairs)
// #let tree = find-exponents((
//   children: brackets-children,
//   layers: bare-tree.layers,
//   group: false, // make sure that the topmost level also has the 'group' field
// ))
// #let leaves = find-leaves(tree)

// #tree \

// Calling `format-unit()` here is not possible since the function
// is only defined after this function. This function will therefore
// only take care of the preparation to use a fraction in the unit.
#let prepare-frac(child) = {
  child.exponent.text = child.exponent.text.trim("-")
  if child.exponent.text == "1" { _ = child.remove("exponent") }
  // if c.len() == 0 { c.push([1]) }
  child
}

#let format-unit(tree, ..args) = {
  if "text" in tree.keys() { return format-unit-text(tree) }
  let exponent = tree.at("exponent", default: none)
  let brackets = tree.at("brackets", default: none)

  let per-mode-power = args.named().per-mode == "power" and brackets == (0,)
  // apply the exponent to all children, and set it to none afterward...
  // if exponent != none and (brackets == none or per-mode-power) and not tree.group {

  let inherit-exponent = if args.named().per-mode == "fraction" {
    brackets == none and not tree.group
  } else {
    (brackets == none or brackets == (0,)) and not tree.group
  }

  // always apply an exponent if there is only one pair of parentheses...
  // if exponent != none and (brackets == none or brackets == (0,)) and not tree.group {
  if exponent != none and inherit-exponent {
    tree.children = tree.children.map(child => apply-exponent(child, exponent))
    exponent = none
  }

  let c = ()
  for child in tree.children {
    // the per-mode only needs to be considered for a negative exponent
    let negative-exponent = child.keys().contains("exponent") and child.exponent.text.starts-with("-")
    // a single child in brackets is protected from being turned into a fraction
    let protective-brackets = brackets != none and tree.children.len() == 1
    // invert the exponent of the child if it is used in a fraction or with a content per-mode
    if negative-exponent and args.named().per-mode != "power" and not protective-brackets { child = prepare-frac(child) }
    let unit = format-unit(child, ..args)

    if args.named().per-mode == "power" or not negative-exponent or protective-brackets {
      c.push(unit)
    } else {
      // use the content [1] if `c` is empty so far...
      let previous = if c.len() > 0 { c.pop() } else { [1] }
      // why is the flag `protective-brackets` checked here again?
      if args.named().per-mode == "fraction" and not protective-brackets {
        c.push(math.frac(previous, unit))
      } else if type(args.named().per-mode) == content {
        // wrap multiple units in brackets for the custom per-mode...
        if child.keys().contains("children") and child.children.len() > 1 { unit = unit-bracket(unit, 0) }
        c.push((previous, args.named().per-mode, unit).join())
      } else {
        panic("The per-mode must be 'fraction', 'power' or content")
      }
    }
  }

  // the content in `c` is joined by the unit-separator if it is not a group
  let join-symbol = if tree.group { [] } else { args.named().unit-separator }
  let unit = c.join(join-symbol)
  if brackets != none {
    // only discard the first layer of parentheses if there is no exponent to be added in the next step...
    if brackets.at(-1) == 0 and (exponent == none or brackets.len() > 1) { _ = brackets.pop() }
    for bracket in brackets { unit = unit-bracket(unit, bracket) }
  }

  if exponent != none {
    if args.named().per-mode == "fraction" {
      let previous = if unit == [] { [1] } else { unit }
      
      
    }
    
  }
  if exponent != none and (tree.group or brackets.len() > 0) { unit = unit-attach(unit, tr: exponent) }

  // don't forget to apply the layers to non-text children...
  wrap-content-math(unit, tree.layers)
}

#let unit(body, ..args) = {
  let bare-tree = unwrap-content(body)
  // wrap the "text" child to use the functions find-brackets() and group-brackets-children()
  if bare-tree.keys().contains("text") { bare-tree = (children: (bare-tree,), layers: ()) }
  let pairs = find-brackets(bare-tree)
  let brackets-children = group-brackets-children(bare-tree.children, pairs)
  let tree = find-exponents((
    children: brackets-children,
    layers: bare-tree.layers,
    group: false, // make sure that the topmost level also has the 'group' field...
  ))
  context { format-unit(tree, ..state-config.get(), ..args) }
}

$1^(-3)$  $1^(-6)$ #linebreak()
$1 / ([a + b])$
$1 / ((1 + 2))$
// #let m = $1 / x$
// #m.body.func()

#math.attach("abc", tr: [-4])
#"−".starts-with("-")
#unit-attach([abc], tr: (text: "-4", layers: ()))


#unit(per-mode: "fraction")[#u1] \
#unit(per-mode: "fraction")[#uc]

// $#math.bold([$1^2$])$

// #"km/μm^2/s".position(regex("\/[\D]")) \
// #"km/cm^1/2".split("/") \







// #group-brackets(tree)

// #let n = [ ( 0.9 +- 0.1 )  ]
// #let n = [ *0,9* ( 12 ) e5 ]
// #let tree = unwrap-content(n)
// // remove leaves with empty text...
// #let leaves = find-leaves(tree)//.filter(leaf => leaf.text != " ")
// #let number = leaves.map(leaf => leaf.text).join().trim(" ") // remove the outside-facing spaces
// // #interpret-number(number) \
// #let components = leaves.filter(leaf => leaf.text != " ")
// #let res = interpret-number-content(n)
// #let (number, tree) = res
// #number \
// #tree \

// $#output-number(number, tree)$

// Get the text and all (styling) functions from a content object
//
// - c (content)
// -> dictionary
//    - text (str): Actual text in the content object
//    - layers (array): Functions and fields that style the `text`
#let unwrap-text(c) = {
  let layers = ()
  while not c.has("text") {
    let func = c.func() // get the func() before stepping into the next layer...
    let fields = c.fields()
    if c.has("body") { c = fields.remove("body") }
    else if c.has("child") { c = fields.remove("child") }
    layers.push((func, fields))
  }
  (text: c.text, layers: layers.rev()) // should this really be reversed here?
}

// Wrap a string in layers of (styling) functions to get a content object
//
// - s (str): String to use in the content object
// - layers (array): Functions and fields to style `s`
// -> content
#let wrap-text(s, layers) = {
  let c = [#s]
  for (func, fields) in layers {
    if "styles" in fields.keys() { c = func(c, fields.styles) } // the "styles" are a positional argument...
    else { c = func(c, ..fields) } // this also works for "strong", "emph" etc. since "fields" will be empty
  }
  c
}

#let get-text(c) = {
  unwrap-text(c).at("text")
}

#let set-text(c, s) = {
  wrap-text(s, unwrap-text(c).at("layers"))
}

#let n = [#highlight(extent: 10pt)[abc]]
// #get-text(n)
#let n = [#text(fill: red)[*_abc_*]]
#let n = [abc]
#let layers = unwrap-text(n)
// #let (func, fields) = layers.at(0)
// #func()
// #func([abc], ..fields)
// #set-text(n, "1(2)")
// #n.fields()

#let n = [#text(red)[abc]]
// #n.fields()

#let n = [#text(baseline: -5pt, fill: blue, weight: 900)[_*1(2)*_]]
#let c = [1(2)]
#let nn = [#text(red)[12]]
#let layers = unwrap-text(n)
// #let (func, styles) = layers.at(0)
#let func = n.func()
#let styles = n.styles
// #func([abc], styles) abc


// #func([abc], styles.at("styles"))

// #text(green, 18pt)[abc]


// #n #funcs.at(0)
// #let (f, ..args) = funcs.at(0)
// #f([abc], ..args)
// #type(get-text(n))

// #for i in range(5) [
//   #linebreak()
// ]
// #let (f, styles) = funcs.at(0)
// #f([abc], styles)


// #let styled = nn.func()
// #styled([abc], nn.styles)
// #type(nn.styles)
// [#nn.styles [abc]]
// #nn.styles


// #let styles = n.styles
// #n.func()
// #styles
// #style(n.styles)
// #set-text(n, "a") \
// #{
//   n.body.func() == text
// }
// #set-text(n, "abc")

#let number(number) = {
  if number.has("text") {
    return interpret-number(number.text)
  }
}

// #let n = [_*1(2)*_]
// #n.
// #type([1(2)])
// #number[*1(2)*]
// // #[1 (2)e5].children


// // #$#([1(*2*)],).join()$ \
// // #$#([1(2)],).join()$ \
// // #$#([1(#math.bold([2]))],).join()$

// #unit[ab  abd^2  easdfasdf]

// #unit[abc / def^1] \
// abc

// #let cc = ([a], [b], [c])
// $#cc.join()$




// #num[0.9+-2]
// #let Erec = [E#sub[rec]]
// #let fm = "abc"

// // #parse_input[1    µ]
// // #num[1µ]

// #let Erec(n: none) = [
//   E#sub[rec]
//   #if n != none [
//     #h(-0.7em)^(#n)
//   ]
// ]

// $#Erec(n: 1)$

// $#math.italic[E]^22$

// $#math.upright[#math.italic[E]#sub[rec]]#h(-0.7em)^(2)$

// $#math.upright[#math.italic[E]]^22#sub[rec]$
// $#math.upright[mm]^2$
// $#math.upright[#sym.mu f]$
// $μ #sym.mu$
// μ#sym.mu
// $#math.upright[a]#sub[rec]$

// $a#sub(typographic: false)[2]#super(typographic: false)[2]$
// $E#super[2] E^2$
// $E#sub[2] E_2$
// $1^(-1)_(-1)$

// $ #math.scripts[1]_1^1 $
// $ 1_1^1 $
// 1#sub[1]#super[1] $1#sub[1]#super[1]$

// $5℃$

// // #unit[#Erec] \
// #unit[Erec] \
// $#unit[um]$ \
// #unit[um] \
// $#math.upright(sym.mu)$
// $#math.upright([#sym.mu m])$
// $#math.upright([#math.italic[E]#sub[rec]])$
// $#math.upright(sym.planck.reduce)$
// #math.upright(sym.rect)
// $#math.upright[abc]$

// $1fm$
// $upright(mu)$
// $µ$
 
// #num(display-uncertainty: "plus.minus")[1+-2]
// #parse_input[1+-2 mu].join(" ").split("+-")
// #num[1+-2  mu]
// $mu$
// #num(display-uncertainty: "plus.minus")[1d-10 +- 1e cm^2 bd^-10 per cd]
// #num(display_uncertainty: "abc")[1+-1]




// #for i in range(-3, 4) [ shift #i: #shift-decimal-position("10", i) \ ]
// #for i in range(-3, 4) [ shift #i: #shift-decimal-position("0.9", i) \ ]

// #n2.match(pattern-number-format)

// #unc
// #calc.div-euclid(0.001, 0.002)

// #"(1+-2)".match(pattern-number-mode)
// #let n1 = "(1+-2)e5"
// #let match = match-exponent(n1)
// #match
// #match.s.match(pattern-number-mode)
// #"(1+-2)e5".match(pattern-exponent)
// #"(1+-2)*10^5".match(pattern-exponent)
// #"10(2)*10^5".match(pattern-exponent)
// #"(1+-2)".match(pattern-number-mode)

// #parse-number("1f2 +- 2 +- 1")

// #let value-pattern = regex("(-?\d+(?:[\,.]\d+)?(?:[eE][+-]?\d+)?)")
// #let pattern = regex("^ *(-?\d+)( ?\+- ?\d)*")
// #let uncertainty-pattern = regex("(\+- ?\d)")
// #let string = " -2+-5+-2"
// #let match = string.match(value-pattern)
// // #string.matches(pattern)
// #string.matches(uncertainty-pattern)

// $1#super[def]#h(-0.3cm)#sub[abc]$