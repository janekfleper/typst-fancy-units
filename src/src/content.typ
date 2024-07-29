// Get the content tree from a content object
//
// - c (content): The content to unwrap
// -> dictionary
//    - text (str): Actual text in the content object
//    - children (array): Children of the content object
//    - layers (array): Functions and fields that style the `text`
//      or the `children` (in reverse order)
//
// This is the complementary function to `wrap-content()`.
// 
// If the content is empty [ ] or has the field "text", there is
// nothing more to unwrap. The tree is returned with the key "text".
// If the content has the field "children", run this function recursively
// for each child. The tree is returned with the key "children".
// If the content has the field "body" or "child", just store the functions
// that wrap the content as new `layers`.
#let unwrap-content(c) = {
  let layers = ()
  while true {
    // the exit conditions will return different keys
    if c == [ ] { return (text: " ", layers: layers.rev()) }
    else if c.has("text") { return (text: c.text, layers: layers.rev()) }
    else if c.has("children") {
      let children = ()
      // discard "empty" content (or rather content with a single space inside)?
      for child in c.children { children.push(unwrap-content(child)) }
      return (children: children, layers: layers.rev())
    }

    // get the `func` and `fields` before stepping into the next layer...
    let func = c.func()
    let fields = c.fields()
    // ...and remove the "body" or "child" from the `fields`!
    if c.has("body") { c = fields.remove("body") }
    else if c.has("child") { c = fields.remove("child") }
    layers.push((func, fields))
  }
}

// Walk the content tree to find (text) leaves and their paths
//
// - t (array): The content tree from `unwrap-content()`
// - path (array, optional): The parent path, defaults to ()
// -> leaves (array): Each leaf has the keys "text" and "path"
#let find-leaves(t, path: ()) = {
  // wrap the dictionary in a list to always have the same return type
  if "text" in t.keys() { return ((text: t.text, path: path),) }

  let leaves = ()
  for i in range(t.children.len()) {
    leaves += find-leaves(t.children.at(i), path: (..path, i))
  }
  leaves
}

// Apply (function) layers to a content object
//
// - c (content): The content to wrap in the functions
// - layers (array): The layers from `unwrap-content()`
// -> c (content)
// 
// This is the complementary function to `unwrap-content()`.
// 
// Each layer consists of a function and an (optional) fields dictionary.
// If the fields have the key "styles", they have to be passed as unnamed
// arguments to the function. This is the case when the `text()` function
// is used. The content will then be wrapped in the function `styled()`
// and there will be a field called "styles".
// In all other cases the fields can simply be destructured "into" the
// function call. This will also work if the dictionary is empty.
#let wrap-content(c, layers) = {
  for (func, fields) in layers {
    if "styles" in fields.keys() { c = func(c, fields.styles) }
    else { c = func(c, ..fields) }
  }
  c
}

// Wrap a component in the layers of the (content) tree
//
// - component (dictionary)
//    - text (str): The text of the component
//    - path (array): The path to the component in the `tree`
// - tree (array): The content tree from `unwrap-content()`
// - apply-parent-layers (boolean): Apply the outermost layers, defaults to
//   `false`. This is useful to apply the outermost layer somewhere else if it
//   affects more than just the extracted components of a number/unit.
// -> content
#let wrap-component(component, tree, apply-parent-layers: false) = {
  let (text: s, path: path) = component
  if path.len() == 0 {
    // Convert the string `s` to content in the lowest layer with `text()`.
    // This is also the function that wraps the string in any content object.
    let c = text(s)
    if apply-parent-layers { c = wrap-content(c, tree.layers) }
    return c
  }

  // descend into the next level of the hierarchy...
  let child-tree = tree.children.at(path.remove(0))
  let c = wrap-component((text: s, path: path), child-tree, apply-parent-layers: true)
  if apply-parent-layers { wrap-content(c, tree.layers) } else { c }
}