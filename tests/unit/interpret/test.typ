#set page(height: auto, width: auto, margin: 1em)
#import "/src/unit.typ": *


#let offset-bracket-tests = (
  (
    input: ((child: 0, position: 2), (child: 0, position: 0)),
    output: (child: 0, position: 1),
  ),
  (
    input: ((child: 0, position: 8), (child: 0, position: 1)),
    output: (child: 0, position: 6),
  ),
  (
    input: ((child: 3, position: 8), (child: 1, position: 27)),
    output: (child: 2, position: 8),
  ),
)

#for (input, output) in offset-bracket-tests {
  assert.eq(offset-bracket(..input), output)
}


#let offset-bracket-pairs-tests = (
  (
    input: (
      (
        (
          type: 0,
          open: (child: 0, position: 2),
          close: (child: 0, position: 6),
        ),
      ),
      (child: 0, position: 0),
    ),
    output: (
      (
        type: 0,
        open: (child: 0, position: 1),
        close: (child: 0, position: 5),
      ),
    ),
  ),
  (
    input: (
      (
        (
          type: 1,
          open: (child: 2, position: 2),
          close: (child: 4, position: 6),
        ),
      ),
      (child: 2, position: 0),
    ),
    output: (
      (
        type: 1,
        open: (child: 0, position: 1),
        close: (child: 2, position: 6),
      ),
    ),
  ),
)

#for (input, output) in offset-bracket-pairs-tests {
  assert.eq(offset-bracket-pairs(..input), output)
}


#let get-opening-children-tests = (
  (
    input: (
      ((body: "a/(b c)d", layers: ()),),
      (type: 0, open: (child: 0, position: 2), close: (child: 0, position: 6)),
    ),
    output: ((body: "a/", layers: ()),),
  ),
  (
    input: (
      (
        (body: "a", layers: ((strong, (:)),)),
        (body: " ", layers: ()),
        (body: "/(b c)", layers: ((emph, (:)),)),
      ),
      (type: 0, open: (child: 2, position: 1), close: (child: 2, position: 5)),
    ),
    output: (
      (body: "a", layers: ((strong, (:)),)),
      (body: " ", layers: ()),
      (body: "/", layers: ((emph, (:)),)),
    ),
  ),
)

#for (input, output) in get-opening-children-tests {
  assert.eq(get-opening-children(..input), output)
}


#let get-inner-children-tests = (
  (
    input: (
      ((body: "a/(b c)d", layers: ()),),
      (type: 0, open: (child: 0, position: 2), close: (child: 0, position: 6)),
    ),
    output: ((body: "b c", layers: ()),),
  ),
  (
    input: (
      (
        (body: "a", layers: ((strong, (:)),)),
        (body: " ", layers: ()),
        (body: "/(b c)", layers: ((emph, (:)),)),
      ),
      (type: 0, open: (child: 2, position: 1), close: (child: 2, position: 5)),
    ),
    output: (
      (body: "b c", layers: ((emph, (:)),)),
    ),
  ),
)

#for (input, output) in get-inner-children-tests {
  assert.eq(get-inner-children(..input), output)
}


#let get-closing-children-tests = (
  (
    input: (
      ((body: "a/(b c)d", layers: ()),),
      (type: 0, open: (child: 0, position: 2), close: (child: 0, position: 6)),
    ),
    output: ((body: "d", layers: ()),),
  ),
  (
    input: (
      (
        (body: "a/(b c)", layers: ()),
        (body: " ", layers: ()),
        (body: "d", layers: ((emph, (:)),)),
      ),
      (type: 0, open: (child: 0, position: 2), close: (child: 0, position: 6)),
    ),
    output: (
      (body: " ", layers: ()),
      (body: "d", layers: ((emph, (:)),)),
    ),
  ),
)

#for (input, output) in get-closing-children-tests {
  assert.eq(get-closing-children(..input), output)
}


#let get-inner-pairs-tests = (
  (
    input: (
      (
        (type: 0, open: (child: 2, position: 0), close: (child: 2, position: 4)),
        (type: 1, open: (child: 4, position: 0), close: (child: 4, position: 4)),
      ),
      (child: 2, position: 8),
    ),
    output: (
      (type: 0, open: (child: 2, position: 0), close: (child: 2, position: 4)),
    ),
  ),
)

#for (input, output) in get-inner-pairs-tests {
  assert.eq(get-inner-pairs(..input), output)
}


#let get-closing-pairs-tests = (
  (
    input: (
      (
        (type: 0, open: (child: 2, position: 0), close: (child: 2, position: 4)),
        (type: 1, open: (child: 4, position: 0), close: (child: 4, position: 4)),
      ),
      (child: 2, position: 8),
    ),
    output: (
      (type: 1, open: (child: 4, position: 0), close: (child: 4, position: 4)),
    ),
  ),
)

#for (input, output) in get-closing-pairs-tests {
  assert.eq(get-closing-pairs(..input), output)
}


#let wrap-children-tests = (
  (
    input: (
      ((body: "b c", layers: ()),),
      (type: 0, open: (child: 0, position: 1), close: (child: 0, position: 5)),
    ),
    output: (
      (body: "b c", layers: (), brackets: (0,)),
    ),
  ),
  (
    input: (
      (
        (body: "b", layers: ()),
        (body: " ", layers: ()),
        (body: "c", layers: ((strong, (:)),)),
        (body: "", layers: ()),
      ),
      (type: 0, open: (child: 0, position: 2), close: (child: 3, position: 0)),
    ),
    output: (
      (
        children: (
          (body: "b", layers: ()),
          (body: " ", layers: ()),
          (body: "c", layers: ((strong, (:)),)),
          (body: "", layers: ()),
        ),
        layers: (),
        brackets: (0,),
      ),
    ),
  ),
)

#for (input, output) in wrap-children-tests {
  assert.eq(wrap-children(..input), output)
}


#let group-brackets-tests = (
  (
    input: (
      ((body: "(a b)", layers: ()),),
      ((type: 0, open: (child: 0, position: 0), close: (child: 0, position: 4)),),
    ),
    output: (
      (body: "a b", layers: (), brackets: (0,)),
    ),
  ),
  (
    input: (
      ((body: "[ab]", layers: ()),),
      ((type: 1, open: (child: 0, position: 0), close: (child: 0, position: 3)),),
    ),
    output: (
      (body: "ab", layers: (), brackets: (1,)),
    ),
  ),
  (
    input: (
      ((body: "a/{b c}", layers: ()),),
      ((type: 2, open: (child: 0, position: 2), close: (child: 0, position: 6)),),
    ),
    output: (
      (body: "a/", layers: ()),
      (body: "b c", layers: (), brackets: (2,)),
    ),
  ),
)

#for (input, output) in group-brackets-tests {
  assert.eq(group-brackets(..input), output)
}


#let find-exponents-body-tests = (
  (
    input: (
      (body: "b^2", layers: ()),
      ((body: "a", layers: ()),),
    ),
    output: (
      (body: "a", layers: ()),
      (
        body: "b",
        layers: (),
        exponent: (body: "2", layers: ()),
      ),
    ),
  ),
  (
    input: (
      (body: "^2", layers: ()),
      (
        (
          children: ((body: "a", layers: ()), (body: "b", layers: ())),
          layers: (),
          brackets: (1,),
        ),
      ),
    ),
    output: (
      (
        children: ((body: "a", layers: ()), (body: "b", layers: ())),
        layers: (),
        brackets: (1,),
        exponent: (body: "2", layers: ()),
      ),
    ),
  ),
)

#for (input, output) in find-exponents-body-tests {
  assert.eq(find-exponents-body(..input), output)
}


#let find-groups-tests = (
  (
    input: (
      (
        (body: "a", layers: ()),
        (body: "b", layers: ()),
      ),
      (),
    ),
    output: ((0,), (1,)),
  ),
  (
    input: (
      (
        (body: "a", layers: ()),
        (body: ":", layers: ()),
        (body: "b", layers: ()),
      ),
      (),
    ),
    output: ((0, 2),),
  ),
  (
    input: (
      (
        (body: "a", layers: ()),
        (body: "b", layers: ()),
        (body: ":", layers: ()),
        (body: "c", layers: ()),
      ),
      (1,),
    ),
    output: ((0,), (1, 3)),
  ),
)

#for (input, output) in find-groups-tests {
  assert.eq(find-groups(..input), output)
}


#let group-units-tests = (
  (
    input: (
      (
        (body: "a", layers: ()),
        (body: ":", layers: ()),
        (body: "b", layers: ()),
      ),
      (),
    ),
    output: (
      (
        children: ((body: "a", layers: ()), (body: "b", layers: ())),
        layers: (),
        group: true,
      ),
    ),
  ),
  (
    input: (
      (
        (body: "a", layers: ()),
        (body: "b", layers: ()),
        (body: ":", layers: ()),
        (
          body: "c",
          layers: (),
          exponent: (body: "2", layers: ()),
        ),
      ),
      (1,),
    ),
    output: (
      (body: "a", layers: ()),
      (
        children: ((body: "b", layers: ()), (body: "c", layers: ())),
        layers: (),
        exponent: (body: "−2", layers: ()),
        group: true,
      ),
    ),
  ),
)

#for (input, output) in group-units-tests {
  assert.eq(group-units(..input), output)
}


#let interpret-exponents-and-groups-tests = (
  (
    input: (
      children: ((body: "1/ab^2", layers: ()),),
      layers: (),
      group: false,
    ),
    output: (
      body: "ab",
      layers: (),
      exponent: (body: "−2", layers: ()),
    ),
  ),
  (
    input: (
      children: (
        (body: "a", layers: ()),
        (body: ":", layers: ()),
        (body: "b^2", layers: ()),
      ),
      layers: (),
      group: false,
    ),
    output: (
      children: ((body: "a", layers: ()), (body: "b", layers: ())),
      layers: (),
      exponent: (body: "2", layers: ()),
      group: true,
    ),
  ),
  (
    input: (
      children: (
        (body: "a/b", layers: ()),
        (body: ":", layers: ()),
        (body: "c^2", layers: ()),
      ),
      layers: (),
      group: false,
    ),
    output: (
      children: (
        (body: "a", layers: ()),
        (
          children: ((body: "b", layers: ()), (body: "c", layers: ())),
          layers: (),
          exponent: (body: "−2", layers: ()),
          group: true,
        ),
      ),
      layers: (),
      group: false,
    ),
  ),
)

#for (input, output) in interpret-exponents-and-groups-tests {
  assert.eq(interpret-exponents-and-groups(input), output)
}


#let interpret-unit-tests = (
  (
    input: (
      children: ((body: "ab^2", layers: ()),),
      layers: (),
    ),
    output: (
      body: "ab",
      layers: (),
      exponent: (body: "2", layers: ()),
    ),
  ),
  (
    input: (
      children: ((body: "(a b)^2", layers: ()),),
      layers: (),
    ),
    output: (
      children: ((body: "a", layers: ()), (body: "b", layers: ())),
      layers: (),
      brackets: (0,),
      exponent: (body: "2", layers: ()),
      group: false,
    ),
  ),
)

#for (input, output) in interpret-unit-tests {
  assert.eq(interpret-unit(input), output)
}
