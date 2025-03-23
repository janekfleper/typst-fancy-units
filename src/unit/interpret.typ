#import "../content.typ": _unwrap-content
#import "transform.typ": _invert-exponent, _apply-exponent

#let _pattern-exponent = regex("^([^^]*)\^(−?[a-zA-Z0-9\.\/]+)$")
#let _pattern-fraction = regex("\/ *(?:[\D]|$)")
#let _pattern-non-numeric = regex("[^−\d\/]+")

#let _brackets = ("(", "[", "{", ")", "]", "}")
#let _pattern-bracket = regex(_brackets.map(bracket => "(\\" + bracket + ")").join("|"))

// Offset a bracket location
//
// - bracket (dictionary): Open or close bracket
//   - child (int): Child index in the content tree
//   - position (int): Bracket position in the child body
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
#let _offset-bracket(bracket, offset) = {
  // the offset.child always has to be subtracted!
  let child = bracket.child - offset.child
  // the position is only subtracted if bracket.child and offset.child are equal!
  let position = if child > 0 { bracket.position } else { bracket.position - offset.position - 1 }
  return (child: child, position: position)
}

// Offset the locations of bracket pairs
//
// - pairs (array): All (remaining) bracket pairs
// - offset (dictionary): Offset to apply to the brackets in `pairs`
//   - child (int)
//   - position (int)
// -> pairs (array): Shifted bracket pairs
//
// This function will apply `offset-bracket()` to every "open" and
// "close" bracket in the `pairs`.
#let _offset-bracket-pairs(pairs, offset) = {
  pairs.map(pair => (
    type: pair.type,
    open: _offset-bracket(pair.open, offset),
    close: _offset-bracket(pair.close, offset),
  ))
}

// Get the children before the opening bracket
//
// - children (array): All the children in the current tree level
// - pair (dictionary): Bracket pair
//   - type (int): Bracket type
//   - open (dictionary): Open bracket
//   - close (dictionary): Close bracket
// -> (array): The children up to the opening bracket
//
// Example:
//  unit[a/(b c)]
//  children = (
//    (body: "a/(b c)", layers: ()),
//  )
//  pair = (
//    type: 0,
//    open: (child: 0, position: 2),
//    close: (child: 0, position: 6),
//  )
//
//  get-opening-children(children, pair) -> (
//    (body: "a/", layers: ()),
//  )
#let _get-opening-children(children, pair) = {
  // get the "full" children up to the open child...
  children.slice(0, pair.open.child)

  // ... and add body in the "open-child" up to the open position
  let open-child = children.at(pair.open.child)
  if pair.open.position > 0 {
    let pre = open-child.body.slice(0, pair.open.position)
    ((body: pre, layers: open-child.layers),)
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
//
// Example:
//  unit[a/(b c)]
//  children = (
//    (body: "a/(b c)", layers: ()),
//  )
//  pair = (
//    type: 0,
//    open: (child: 0, position: 2),
//    close: (child: 0, position: 6),
//  )
//
//  get-inner-children(children, pair) -> (
//    (body: "b c", layers: ()),
//  )
#let _get-inner-children(children, pair) = {
  let open-child = children.at(pair.open.child)
  let close-child = children.at(pair.close.child)

  if pair.open.child == pair.close.child {
    let body = open-child.body.slice(pair.open.position + 1, pair.close.position)
    ((body: body, layers: open-child.layers),)
  } else {
    (
      (body: open-child.body.slice(pair.open.position + 1), layers: open-child.layers),
      ..children.slice(pair.open.child + 1, pair.close.child),
      (body: close-child.body.slice(0, pair.close.position), layers: close-child.layers),
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
//
// Example:
//  unit[(a b)^2/c]
//  children = (
//    (body: "(a b)^2/c", layers: ()),
//  )
//  pair = (
//    type: 0,
//    open: (child: 0, position: 0),
//    close: (child: 0, position: 4),
//  )
//
//  get-closing-children(children, pair) -> (
//    (body: "^2/c", layers: ()),
//  )
#let _get-closing-children(children, pair) = {
  let close-child = children.at(pair.close.child)

  if pair.close.position + 1 < close-child.body.len() {
    let post = close-child.body.slice(pair.close.position + 1)
    ((body: post, layers: close-child.layers),)
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
#let _get-inner-pairs(pairs, close) = {
  pairs.filter(pair => (
    pair.close.child < close.child or (pair.close.child == close.child and pair.close.position < close.position)
  ))
}

// Get the bracket pairs after the current bracket pair
//
// - pairs (array): All (remaining) bracket pairs
// - close (dictionary): Closing bracket of the current bracket pair
// -> pairs (array): Bracket pairs after the current bracket pair
//
// Since the current bracket pair is always the first one, the filter only
// has to check the "child" and "position" compared to the closing bracket.
#let _get-closing-pairs(pairs, close) = {
  pairs.filter(pair => (
    pair.close.child > close.child or (pair.close.child == close.child and pair.close.position > close.position)
  ))
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
//
// Example:
//  unit[(a b)^2]
//  children = ((body: "a b", layers: ()),)
//  pair = (
//    type: 0,
//    open: (child: 0, position: 0),
//    close: (child: 0, position: 4),
//  )
//
//  wrap-children(children, pair) -> (
//    (body: "a b", layers: (), brackets: (0,)),
//  )
#let _wrap-children(children, pair) = {
  if children.len() == 1 {
    let brackets = children.at(0).at("brackets", default: ())
    brackets.push(pair.type)
    children.at(0).insert("brackets", brackets)
    children
  } else {
    (
      (
        children: children,
        layers: (),
        brackets: (pair.type,),
      ),
    )
  }
}

// Split children by bracket pairs
//
// - children (array): Children in the content tree
// - pairs (array): Bracket pairs
// -> children (array)
//
// Example:
//  unit[(a b)^2/c]
//  children = (
//    (body: "(a b)^2/c", layers: ()),
//  )
//  pairs = (
//    (
//      type: 0,
//      open: (child: 0, position: 0),
//      close: (child: 0, position: 4),
//    ),
//  )
//
//  group-brackets(children, pair) -> (
//    (body: "a b", layers: (), brackets: (0,)),
//    (body: "^2/c", layers: ()),
//  )
#let _group-brackets(children, pairs) = {
  // return the children if there are no (more) bracket pairs
  if pairs.len() == 0 { return children }
  // return the children if the bracket pairs start behind the children
  if children.len() < pairs.at(0).open.child { return children }
  let pair = pairs.remove(0)

  // start with the opening children
  _get-opening-children(children, pair)

  // get the bracket pair and the inner children
  let inner-children = _get-inner-children(children, pair)
  let inner-pairs = _offset-bracket-pairs(
    _get-inner-pairs(pairs, pair.close),
    pair.open,
  )
  _wrap-children(_group-brackets(inner-children, inner-pairs), pair)

  // get the closing children
  let closing-children = _get-closing-children(children, pair)
  let closing-offset = (
    child: children.len() - closing-children.len(),
    position: pair.close.position,
  )
  let closing-pairs = _offset-bracket-pairs(
    _get-closing-pairs(pairs, pair.close),
    closing-offset,
  )

  // call the function again with the remaining bracket pairs
  _group-brackets(closing-children, closing-pairs)
}


// Find an exponent in a child with a string body
//
// - child (dictionary)
//   - body (str)
//   - layers (array)
//   - exponent (dictionary): (Optional) exponent
// - units (array): Units accumulated up to the `child`
// -> units (array): Updated array of units
//
// Any text directly after an exponent is simply ignored. There should
// always be a space after an exponent which allows the body to be split
// in this function.
// Passing all the `units` to the function is required because an exponent
// is always applied to the (current) last unit. It is possible that no
// element is added to the `units` in this function. Therefore, all of the
// `units` are passed to this function.
// The `child` will not have the field "brackets" since these cases are
// handled separately in the parent function `find-exponents()`.
#let _find-exponents-body(child, units) = {
  let (body, ..child) = child
  for unit in body.split(" ") {
    if unit.trim(" ") == "" { continue } // discard empty strings again...

    let match = unit.match(_pattern-exponent)
    if match == none {
      if unit.contains("^") { panic("Invalid exponent format") }
      units.push((body: unit, ..child))
      continue
    }
    let exponent = match.captures.at(1)
    // is this even necessary? The "match" should just be none already...
    assert.ne(exponent, "", message: "Empty exponent in child '" + unit + "'")

    let unit = match.captures.at(0)
    if unit != "" { units.push((body: unit, ..child)) }
    units.at(-1) = _apply-exponent(units.at(-1), (body: exponent, ..child))
  }

  units
}

// Find the indices of the units to group together
//
// - units (array): The units in the content tree
// - invert-units (array): The indices of the units to invert
// -> (array): The indices to group together
//
// Example:
//  unit[1/a:b^2]
//  units = (
//    (body: "1", layers: ()),
//    (body: "a", layers: ()),
//    (body: ":", layers: ()),
//    (
//      body: "b",
//      layers: (),
//      exponent: (body: "2", layers: ()),
//    ),
//  )
//  invert-units = (1,)
//
//  find-groups(units, invert-units) -> ((0,), (1, 3))
#let _find-groups(units, invert-units) = {
  let i = 0
  let groups = ()
  while i < units.len() {
    let child = units.at(i)
    // if the "child" has the key "children", it is treated just like a single unit here
    if "body" in child.keys() and child.body == ":" {
      assert.ne(i, 0, message: "Colons are not allowed at the start of a group.")
      i = i + 1
      assert.ne(i, units.len(), message: "Colons are not allowed at the end of a group.")
      assert(i not in invert-units, message: "Colons are not allowed at the end of a group.")
      if units.at(i).body == ":" { panic("Consecutive colons are not allowed.") }
      groups.at(-1).push(i)
    } else {
      groups.push((i,))
    }
    i = i + 1
  }
  return groups
}

// Find and apply groups in the units
//
// - units (array): The units in the content tree
// - invert-units (array): The indices of the units to invert
// -> (array): The grouped units
//
// To allow an insertion of macros, groups of unstyled units are no longer
// joined in this function. This does not require any other changes since the
// function `join-units()` already handles grouped units.
//
// Example:
//  unit[1/a:b^2]
//  units = (
//    (body: "1", layers: ()),
//    (body: "a", layers: ()),
//    (body: ":", layers: ()),
//    (
//      body: "b",
//      layers: (),
//      exponent: (body: "2", layers: ()),
//    ),
//  )
//  invert-units = (1,)
//
//  group-units(units, invert-units) -> (
//    (body: "1", layers: ()),
//    (
//      children: ((body: "a", layers: ()), (body: "b", layers: ())),
//      layers: (),
//      exponent: (body: "−2", layers: ()),
//      group: true,
//    ),
//  )
#let _group-units(units, invert-units) = {
  for indices in _find-groups(units, invert-units) {
    let group = indices.map(i => units.at(i))
    if group.len() == 1 {
      let child = group.at(0)
      if "children" in child.keys() { child.insert("group", false) }
      if indices.at(0) in invert-units { child = _invert-exponent(child) }
      (child,)
      continue
    }

    let single-units = group.all(unit => "body" in unit.keys())
    assert(single-units, message: "Only single units can be grouped.")

    let exponents = group.slice(0, -1).any(unit => "exponent" in unit.keys())
    assert(not exponents, message: "Only the last unit in a group can have an exponent.")

    let props = (layers: ())
    let exponent = group.at(-1).remove("exponent", default: none)
    if exponent != none { props.insert("exponent", exponent) }
    group = (children: group, ..props, group: true)
    if indices.at(0) in invert-units { group = _invert-exponent(group) }
    (group,)
  }
}

// Remove unnecessary levels and children
//
// - tree (dictionary): The content tree
// - children (array): The children with exponents and groups
// -> (dictionary)
//
// The `tree` is only used for global layers, exponents and brackets.
// The `children` are already the processed version of `tree.children`.
//
// Example:
//  unit[1/ab^2]
//  tree = (
//    children: ((body: "1/ab^2", layers: ()),),
//    layers: (),
//    group: false,
//  )
//  children = (
//    (body: "1", layers: ()),
//    (
//      body: "ab",
//      layers: (),
//      exponent: (body: "−2", layers: ()),
//    ),
//  )
//
//  simplify-units(tree, children) -> (
//    body: "ab",
//    layers: (),
//    exponent: (body: "−2", layers: ()),
//  )
#let _simplify-units(tree, children) = {
  // remove children with body "1" to avoid a leading "1" if it is not necessary
  // the "1" will be added again in `format-unit-...()` if it is required...
  children = children.filter(child => (not child.keys().contains("body")) or child.body != "1")

  if children.len() > 1 or "brackets" in tree.keys() {
    (..tree, children: children)
  } else {
    let child = children.at(0)
    child.layers += tree.layers
    if "subscript" in child.keys() { child.subscript.layers += tree.layers }
    if "exponent" in child.keys() { child.exponent.layers += tree.layers }
    if "exponent" in tree.keys() { child = _apply-exponent(child, tree.exponent) }
    child
  }
}

// Find exponents and groups in the content tree
//
// - tree (dictionary): The content tree
// -> (dictionary)
//
// The brackets are already handled prior to this function in
// `interpret-unit()`. The rest of the interpretation is then
// handled inside this function, and the tree is finally also
// simplified to remove unnecessary levels and children.
//
// Example:
//  unit[a:b^2]
//  tree = (
//    children: (
//      (body: "a", layers: ()),
//      (body: ":", layers: ()),
//      (body: "b^2", layers: ()),
//    ),
//    layers: (),
//    group: false,
//  )
//
//  interpret-exponents-and-groups(tree) -> (
//    body: "ab",
//    layers: (),
//    exponent: (body: "2", layers: ()),
//  )
#let _interpret-exponents-and-groups(tree) = {
  let units = ()
  let invert-units = ()

  for child in tree.children {
    if "children" in child.keys() {
      units.push(_interpret-exponents-and-groups(child))
      continue
    }
    if child.body.trim(" ") == "" { continue } // discard empty children...

    // handle subscripts...
    if child.layers.contains((sub, (:))) {
      let layers = child.layers.filter(layer => layer != (sub, (:)))
      units.at(-1).insert("subscript", (..child, layers: layers))
      continue
    }

    // remove the "body" field since it will be replaced in any new child anyway...
    let (body, ..child) = child
    // wrap everything in a sub-tree if the child is inside of a bracket...
    if "brackets" in child.keys() {
      units.push(_interpret-exponents-and-groups((children: ((body: body, layers: ()),), ..child)))
      continue
    }

    while body.trim(" ") != "" {
      let match = body.match(_pattern-fraction)
      if match == none {
        units = _find-exponents-body((body: body, ..child), units)
        break
      }

      units = _find-exponents-body((body: body.slice(0, match.start), ..child), units)
      // store the current length to invert the next child...
      invert-units.push(units.len())
      body = body.slice(match.start + 1)
    }
  }

  _simplify-units(tree, _group-units(units, invert-units))
}

// Recursively interpret the unit content tree
//
// - tree (dictionary): The content tree
// -> tree (dictionary)
//
// This function builds upon the previous function `find-brackets()`. In order
// to make the bracket finding recursive, the group and exponents also have to
// be handled in this function.
//
// If a child with the key "children" is found, the function is called recursively
// and the original child is then just replaced by the return value. Brackets can
// therefore not be tracked across different depths!
//
// The (open) brackets are tracked across the children and kept in a separate list.
// When a closing bracket is found, it is paired up with the last open bracket.
// If the bracket types do not match, an error will be raised.
// If there are any open brackets left after iterating over all children, an error
// will also be raised.
#let _interpret-unit(tree) = {
  let pairs = ()
  let open = ()

  for i in range(tree.children.len()) {
    let child = tree.children.at(i)
    if "children" in child.keys() {
      tree.children.at(i) = _interpret-unit(child)
      continue
    }
    for match in child.body.matches(_pattern-bracket) {
      // the bracket type is "encoded" in the group index
      let bracket-type = match.captures.position(x => x != none)
      // types 0, 1 and 2 are the open brackets
      if bracket-type < 3 { open.push((type: bracket-type, child: i, position: match.start)) } else {
        assert.ne(open, (), message: "error when matching brackets...")
        let (type: open-bracket-type, ..open-bracket) = open.pop()
        assert.eq(bracket-type - 3, open-bracket-type, message: "error when matching brackets...")
        pairs.push((type: open-bracket-type, open: open-bracket, close: (child: i, position: match.start)))
      }
    }
  }

  if open.len() > 0 { panic("error when matching brackets...") }

  // sort the pairs to be ordered by open.child and open.position
  pairs = pairs.sorted(key: pair => pair.open.position).sorted(key: pair => pair.open.child)
  _interpret-exponents-and-groups((
    children: _group-brackets(tree.children, pairs),
    layers: tree.layers,
    group: false, // make sure that the topmost level also has the 'group' field...
  ))
}

// Unwrap and interpret a unit
//
// - body (content): The unit to interpret
// -> tree (dictionary)
//
// The internal function is `_interpret-unit()` which recursively interprets
// the content tree. Since `unwrap-content()` only has to be called once, it
// cannot be in `_interpret-unit()`. This function is therefore required to
// wrap the internal function of the same name.
#let interpret-unit(body) = {
  let bare-tree = _unwrap-content(body)
  // wrap the "body" child to use the functions find-brackets() and group-brackets-children()...
  if "body" in bare-tree.keys() { bare-tree = (children: (bare-tree,), layers: ()) }
  // ...the tree is unwrapped again (if possible) in simplify-units()
  _interpret-unit(bare-tree)
}
