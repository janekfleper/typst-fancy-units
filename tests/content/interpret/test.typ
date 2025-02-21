#set page(height: auto, width: auto, margin: 1em)
#import "/src/content.typ": *


#let unwrap-content-tests = (
  (
    input: [],
    output: (children: (), layers: ()),
  ),
  (
    input: [ ],
    output: (text: " ", layers: ()),
  ),
  (
    input: [0.9],
    output: (text: "0.9", layers: ()),
  ),
  (
    input: [-0.9],
    output: (children: ((text: "−", layers: ()), (text: "0.9", layers: ())), layers: ()),
  ),
  (
    input: [+0.9],
    output: (text: "+0.9", layers: ()),
  ),
  (
    input: [*0.9*],
    output: (text: "0.9", layers: ((strong, (:)),)),
  ),
  (
    input: [_0.9_],
    output: (text: "0.9", layers: ((emph, (:)),)),
  ),
  (
    input: [m/s],
    output: (text: "m/s", layers: ()),
  ),
  (
    input: [m / s],
    output: (
      children: (
        (text: "m", layers: ()),
        (text: " ", layers: ()),
        (text: "/", layers: ()),
        (text: " ", layers: ()),
        (text: "s", layers: ()),
      ),
      layers: (),
    ),
  ),
  (
    input: [m^2],
    output: (text: "m^2", layers: ()),
  ),
  (
    input: [m ^2],
    output: (
      children: (
        (text: "m", layers: ()),
        (text: " ", layers: ()),
        (text: "^2", layers: ()),
      ),
      layers: (),
    ),
  ),
  (
    input: [#sub[kg]],
    output: (text: "kg", layers: ((sub, (:)),)),
  ),
  (
    input: [#super[kg]],
    output: (text: "kg", layers: ((super, (:)),)),
  ),
  (
    input: [#math.cancel[kg]],
    output: (text: "kg", layers: ((math.cancel, (:)),)),
  ),
  (
    input: [*_kg_ m* / s],
    output: (
      children: (
        (
          children: (
            (text: "kg", layers: ((emph, (:)),)),
            (text: " ", layers: ()),
            (text: "m", layers: ()),
          ),
          layers: ((strong, (:)),),
        ),
        (text: " ", layers: ()),
        (text: "/", layers: ()),
        (text: " ", layers: ()),
        (text: "s", layers: ()),
      ),
      layers: (),
    ),
  ),
)

#for (input, output) in unwrap-content-tests {
  assert.eq(unwrap-content(input), output)
}


#let find-leaves-tests = (
  (
    input: (tree: (text: "137", layers: ())),
    output: ((text: "137", path: ()),),
  ),
  (
    input: (tree: (text: "137", layers: ()), path: ()),
    output: ((text: "137", path: ()),),
  ),
  (
    input: (tree: (text: "137", layers: ()), path: (0,)),
    output: ((text: "137", path: (0,)),),
  ),
  (
    input: (tree: (text: "137", layers: ()), path: (0, 1,)),
    output: ((text: "137", path: (0, 1,)),),
  ),
  (
    input: (
      tree: (
        children: (
          (text: "137", layers: ()),
          (text: "(1)", layers: ((strong, (:)),)),
          (text: "e-3", layers: ((emph, (:)),)),
        ),
        layers: (),
      ),
      path: (1,),
    ),
    output: (
      (text: "137", path: (1, 0)),
      (text: "(1)", path: (1, 1)),
      (text: "e-3", path: (1, 2)),
    ),
  ),
)

#for (input, output) in find-leaves-tests {
  if "path" in input.keys() {
    assert.eq(find-leaves(input.tree, path: input.path), output)
  } else {
    assert.eq(find-leaves(input.tree), output)
  }
}
