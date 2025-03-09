#set page(height: auto, width: auto, margin: 1em)
#import "/src/content.typ": *


#let unwrap-content-tests = (
  (
    input: [],
    output: (children: (), layers: ()),
  ),
  (
    input: [ ],
    output: (body: " ", layers: ()),
  ),
  (
    input: [0.9],
    output: (body: "0.9", layers: ()),
  ),
  (
    input: [-0.9],
    output: (children: ((body: "−", layers: ()), (body: "0.9", layers: ())), layers: ()),
  ),
  (
    input: [+0.9],
    output: (body: "+0.9", layers: ()),
  ),
  (
    input: [*0.9*],
    output: (body: "0.9", layers: ((strong, (:)),)),
  ),
  (
    input: [_0.9_],
    output: (body: "0.9", layers: ((emph, (:)),)),
  ),
  (
    input: [m/s],
    output: (body: "m/s", layers: ()),
  ),
  (
    input: [m / s],
    output: (
      children: (
        (body: "m", layers: ()),
        (body: " ", layers: ()),
        (body: "/", layers: ()),
        (body: " ", layers: ()),
        (body: "s", layers: ()),
      ),
      layers: (),
    ),
  ),
  (
    input: [m^2],
    output: (body: "m^2", layers: ()),
  ),
  (
    input: [m ^2],
    output: (
      children: (
        (body: "m", layers: ()),
        (body: " ", layers: ()),
        (body: "^2", layers: ()),
      ),
      layers: (),
    ),
  ),
  (
    input: [#sub[kg]],
    output: (body: "kg", layers: ((sub, (:)),)),
  ),
  (
    input: [#super[kg]],
    output: (body: "kg", layers: ((super, (:)),)),
  ),
  (
    input: [#math.cancel[kg]],
    output: (body: "kg", layers: ((math.cancel, (:)),)),
  ),
  (
    input: [*_kg_ m* / s],
    output: (
      children: (
        (
          children: (
            (body: "kg", layers: ((emph, (:)),)),
            (body: " ", layers: ()),
            (body: "m", layers: ()),
          ),
          layers: ((strong, (:)),),
        ),
        (body: " ", layers: ()),
        (body: "/", layers: ()),
        (body: " ", layers: ()),
        (body: "s", layers: ()),
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
    input: (tree: (body: "137", layers: ())),
    output: ((body: "137", path: ()),),
  ),
  (
    input: (tree: (body: "137", layers: ()), path: ()),
    output: ((body: "137", path: ()),),
  ),
  (
    input: (tree: (body: "137", layers: ()), path: (0,)),
    output: ((body: "137", path: (0,)),),
  ),
  (
    input: (tree: (body: "137", layers: ()), path: (0, 1)),
    output: ((body: "137", path: (0, 1)),),
  ),
  (
    input: (
      tree: (
        children: (
          (body: "137", layers: ()),
          (body: "(1)", layers: ((strong, (:)),)),
          (body: "e-3", layers: ((emph, (:)),)),
        ),
        layers: (),
      ),
      path: (1,),
    ),
    output: (
      (body: "137", path: (1, 0)),
      (body: "(1)", path: (1, 1)),
      (body: "e-3", path: (1, 2)),
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
