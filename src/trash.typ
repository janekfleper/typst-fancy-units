#let pattern-outer-open-bracket = regex("^[^\(\[\{]*(?:(\()|(\[)|(\{))")
#let pattern-outer-close-bracket = regex("(?:(\))|(\])|(\}))[^\)\]\}]*$")
#let pattern-outer-bracket = regex("^[^\(\[\{]*(?:(\()|(\[)|(\{))|(?:(\))|(\])|(\}))[^\)\]\}]*$")


// Find pairs of brackets in the content tree
// 
// - leaves (array): Leaves from the content tree
// -> pairs (array): Pairs of brackets
//   - (dictionary)
//     - type (int): Bracket type
//     - open (dictionary): Leaf index and position in the leaf text
// 
// The (open) brackets are tracked across leaves and kept in a separate list.
// When a closing bracket is found, it is paired up with the last open bracket.
// If the bracket types do not match, an error will be raised.
// If there are any open brackets left after iterating over all leaves, an error
// will also be raised.
#let find-brackets(leaves) = {
  let pairs = ()
  let open = ()

  for i in range(leaves.len()) {
    // the matches will automatically be in the right order
    for match in leaves.at(i).text.matches(pattern-bracket) {
      // the bracket type is "encoded" in the group index
      let bracket-type = match.captures.position(x => x != none)
      // types 0, 1 and 2 are the open brackets
      if bracket-type < 3 { open.push((type: bracket-type, leaf: i, position: match.start)) }
      else {
        assert.ne(open, (), message: unmatched-bracket-message(leaves, bracket-type))
        let (type: open-bracket-type, ..open-bracket) = open.pop()
        assert.eq(bracket-type - 3, open-bracket-type, message: unmatched-bracket-message(leaves, open-bracket-type))
        pairs.push((type: open-bracket-type, open: open-bracket, close: (leaf: i, position: match.start)))
      }
    }
  }

  if open.len() > 0 { panic(unmatched-bracket-message(leaves, open.at(0).type)) }
  pairs
}


#let find-outer-open-bracket-in-tree(tree) = {
  for i in range(tree.children.len()) {
    let child = tree.children.at(i)
    if not child.keys().contains("text") { continue }
    let match = child.text.match(pattern-outer-open-bracket)
    if match == none { continue }

    let bracket-type = match.captures.position(x => x != none)
    return (type: bracket-type, child: i, position: match.end - 1)
  }

  return none
}

#let find-outer-close-bracket-in-tree(tree) = {
  let children = tree.children.rev()
  for i in range(children.len()) {
    let child = children.at(i)
    if not child.keys().contains("text") { continue }
    let match = child.text.match(pattern-outer-close-bracket)
    if match == none { continue }

    let bracket-type = match.captures.position(x => x != none)
    return (type: bracket-type, child: children.len() - 1 - i, position: match.start)
  }

  return none
}

// none is returned if there are no brackets in any of the children...
#let find-outer-brackets-in-children(tree) = {
  let open = find-outer-open-bracket-in-tree(tree)
  let close = find-outer-close-bracket-in-tree(tree)
  if open == none and close == none { return none }
  if open == none or close == none { panic("error matching brackets...") }

  let open-bracket-type = open.remove("type")
  let close-bracket-type = close.remove("type")
  assert.eq(open-bracket-type, close-bracket-type, message: "error matching brackets...")
  (type: open-bracket-type, open: open, close: close)
}

// none is returned if there are no brackets in the text...
#let find-outer-brackets-in-text(tree) = {
  let matches = tree.text.matches(pattern-outer-bracket)
  if matches.len() == 0 { return none }
  if matches.len() == 1 { panic("error matching brackets in '" + tree.text + "'") }

  let open-bracket-type = matches.at(0).captures.position(x => x != none)
  let close-bracket-type = matches.at(1).captures.position(x => x != none)
  assert.eq(
    open-bracket-type,
    close-bracket-type - 3,
    message: "error matching brackets in '" + tree.text + "'"
  )

  (type: open-bracket-type, open: matches.at(0).start, close: matches.at(1).start)
}

#let group-brackets(tree) = {
  let children = ()
  let pair = find-outer-brackets-in-children(tree)
  if pair == none { return tree }
  // add children up to the "open-child"
  children += tree.children.slice(0, pair.open.child)

  // get the children that hold the bracket pair...
  let open-child = tree.children.at(pair.open.child)
  let close-child = tree.children.at(pair.close.child)

  // add text in the "open-child" prior to the open bracket
  if pair.open.position > 0 {
    let pre = open-child.text.slice(0, pair.open.position)
    children.push((text: pre, layers: open-child.layers))
  }

  // handle everything inside the brackets...
  children.push(group-brackets((children: group-inner-children(tree, pair), bracket: pair.type)))

  // handle everything after the "close" bracket...
  children += group-close-children(tree.remove("children"), pair)
  ( children: children, ..tree )
}