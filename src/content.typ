// Get the content tree from a content object
//
// - c (content): The content to unwrap
// -> dictionary
//    - body (str): Actual text in the content object
//    - children (array): Children of the content object
//    - layers (array): Functions that style the `body` or the `children`
//                      (in reverse order)
//
// This is the complementary function to `wrap-content()`.
//
// If the content is empty [ ] or has the field "body", there is nothing more
// to unwrap. The tree is returned with the key "body".
// If the content has the field "children", run this function recursively for
// each child. The tree is returned with the key "children".
// If the content has the field "body" or "child", just store the functions
// that wrap the content as new `layers`.
//
// If the content contains text, regular minus signs "-" are replaced by
// 'math' minus signs "−". The difference between the two characters is not
// directly visible. Only when the exponents are actually formatted there
// is a visible difference.
#let _unwrap-content(c) = {
  let layers = ()
  while true {
    // the exit conditions will return different keys
    if c == [ ] { return (body: " ", layers: layers.rev()) } else if c.has("text") {
      return (body: c.text.replace("-", "−"), layers: layers.rev())
    } else if c.has("children") {
      let children = ()
      // discard "empty" content (or rather content with a single space inside)?
      for child in c.children { children.push(_unwrap-content(child)) }
      return (children: children, layers: layers.rev())
    }

    // get the `func` and `fields` before stepping into the next layer...
    let func = c.func()
    let fields = c.fields()
    // ...and remove the "body" or "child" from the `fields` as the new child!
    if c.has("body") {
      c = fields.remove("body")
    } else if c.has("child") {
      c = fields.remove("child")
    }

    if fields == (:) {
      layers.push(func)
    } else if "styles" in fields.keys() {
      layers.push((body => func(body, fields.styles)))
    } else {
      layers.push(func.with(..fields))
    }
  }
}

// Walk the content tree to find (body) leaves and their paths
//
// - tree (array): The content tree from `_unwrap-content()`
// - path (array, optional): The parent path, defaults to ()
// -> leaves (array): Each leaf has the keys "body" and "path"
#let _find-leaves(tree, path: ()) = {
  // wrap the dictionary in a list to always have the same return type
  if "body" in tree.keys() { return ((body: tree.body, path: path),) }
  tree.children.enumerate().map(((i, child)) => _find-leaves(child, path: (..path, i))).join()
}

// Apply (function) layers to a content object
//
// - c (content): The content to wrap in the functions
// - layers (array): The layers from `_unwrap-content()`
// -> c (content)
//
// This is the complementary function to `_unwrap-content()`.
//
// Each layer consists of a function that takes a single positional argument.
// This will be the content `c` that is wrapped in the layers consecutively.
#let wrap-content(c, layers) = {
  for func in layers { c = func(c) }
  c
}

// Apply (function) layers to a content object in math mode
//
// - c (array, content, str or decimal): The content to wrap in the functions
// - layers (array): The layers from `_unwrap-content()`
// - decimal-separator (str, symbol or content): The separator to replace the decimal point "."
// -> c (content)
//
// Compared to `wrap-content()` this function will replace functions
// by their counterparts in math mode. See the following list:
//    strong -> math.bold
//    emph -> math.italic
//
// If the decimal-separator has to be changed, the string `c` is split
// at the "." and joined with the decimal-separator again.
#let wrap-content-math(c, layers, decimal-separator: none) = {
  if type(c) == decimal { c = str(c) }
  if (type(c) == str) and ("." in c) and (decimal-separator != none) {
    c = c.split(".").join(decimal-separator)
  } else if type(c) == array {
    c = c.join(decimal-separator)
  }

  for func in layers {
    if func == strong { func = math.bold }
    if func == emph { func = math.italic }
    c = func(c)
  }
  math.equation(c)
}

