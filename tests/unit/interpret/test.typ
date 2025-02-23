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
      ((text: "a/(b c)d", layers: ()),),
      (type: 0, open: (child: 0, position: 2), close: (child: 0, position: 6)),
    ),
    output: ((text: "a/", layers: ()),),
  ),
  (
    input: (
      (
        (text: "a", layers: ((strong, (:)),)),
        (text: " ", layers: ()),
        (text: "/(b c)", layers: ((emph, (:)),)),
      ),
      (type: 0, open: (child: 2, position: 1), close: (child: 2, position: 5)),
    ),
    output: (
      (text: "a", layers: ((strong, (:)),)),
      (text: " ", layers: ()),
      (text: "/", layers: ((emph, (:)),)),
    ),
  ),
)

#for (input, output) in get-opening-children-tests {
  assert.eq(get-opening-children(..input), output)
}


#let get-inner-children-tests = (
  (
    input: (
      ((text: "a/(b c)d", layers: ()),),
      (type: 0, open: (child: 0, position: 2), close: (child: 0, position: 6)),
    ),
    output: ((text: "b c", layers: ()),),
  ),
  (
    input: (
      (
        (text: "a", layers: ((strong, (:)),)),
        (text: " ", layers: ()),
        (text: "/(b c)", layers: ((emph, (:)),)),
      ),
      (type: 0, open: (child: 2, position: 1), close: (child: 2, position: 5)),
    ),
    output: (
      (text: "b c", layers: ((emph, (:)),)),
    ),
  ),
)

#for (input, output) in get-inner-children-tests {
  assert.eq(get-inner-children(..input), output)
}


#let get-closing-children-tests = (
  (
    input: (
      ((text: "a/(b c)d", layers: ()),),
      (type: 0, open: (child: 0, position: 2), close: (child: 0, position: 6)),
    ),
    output: ((text: "d", layers: ()),),
  ),
  (
    input: (
      (
        (text: "a/(b c)", layers: ()),
        (text: " ", layers: ()),
        (text: "d", layers: ((emph, (:)),)),
      ),
      (type: 0, open: (child: 0, position: 2), close: (child: 0, position: 6)),
    ),
    output: (
      (text: " ", layers: ()),
      (text: "d", layers: ((emph, (:)),)),
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
      ((text: "b c", layers: ()),),
      (type: 0, open: (child: 0, position: 1), close: (child: 0, position: 5)),
    ),
    output: (
      (text: "b c", layers: (), brackets: (0,)),
    ),
  ),
  (
    input: (
      (
        (text: "b", layers: ()),
        (text: " ", layers: ()),
        (text: "c", layers: ((strong, (:)),)),
        (text: "", layers: ()),
      ),
      (type: 0, open: (child: 0, position: 2), close: (child: 3, position: 0)),
    ),
    output: (
      (
        children: (
          (text: "b", layers: ()),
          (text: " ", layers: ()),
          (text: "c", layers: ((strong, (:)),)),
          (text: "", layers: ()),
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
      ((text: "(a b)", layers: ()),),
      ((type: 0, open: (child: 0, position: 0), close: (child: 0, position: 4)),),
    ),
    output: (
      (text: "a b", layers: (), brackets: (0,)),
    ),
  ),
  (
    input: (
      ((text: "[ab]", layers: ()),),
      ((type: 1, open: (child: 0, position: 0), close: (child: 0, position: 3)),),
    ),
    output: (
      (text: "ab", layers: (), brackets: (1,)),
    ),
  ),
  (
    input: (
      ((text: "a/{b c}", layers: ()),),
      ((type: 2, open: (child: 0, position: 2), close: (child: 0, position: 6)),),
    ),
    output: (
      (text: "a/", layers: ()),
      (text: "b c", layers: (), brackets: (2,)),
    ),
  ),
)

#for (input, output) in group-brackets-tests {
  assert.eq(group-brackets(..input), output)
}


#let find-exponents-text-tests = (
  (
    input: (
      (text: "b^2", layers: ()),
      ((text: "a", layers: ()),),
    ),
    output: (
      (text: "a", layers: ()),
      (
        text: "b",
        layers: (),
        exponent: (text: "2", layers: ()),
      ),
    ),
  ),
  (
    input: (
      (text: "^2", layers: ()),
      (
        (
          children: ((text: "a", layers: ()), (text: "b", layers: ())),
          layers: (),
          brackets: (1,),
        ),
      ),
    ),
    output: (
      (
        children: ((text: "a", layers: ()), (text: "b", layers: ())),
        layers: (),
        brackets: (1,),
        exponent: (text: "2", layers: ()),
      ),
    ),
  ),
)

#for (input, output) in find-exponents-text-tests {
  assert.eq(find-exponents-text(..input), output)
}


#let find-groups-tests = (
  (
    input: (
      (
        (text: "a", layers: ()),
        (text: "b", layers: ()),
      ),
      (),
    ),
    output: ((0,), (1,)),
  ),
  (
    input: (
      (
        (text: "a", layers: ()),
        (text: ":", layers: ()),
        (text: "b", layers: ()),
      ),
      (),
    ),
    output: ((0, 2),),
  ),
  (
    input: (
      (
        (text: "a", layers: ()),
        (text: "b", layers: ()),
        (text: ":", layers: ()),
        (text: "c", layers: ()),
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
        (text: "a", layers: ()),
        (text: ":", layers: ()),
        (text: "b", layers: ()),
      ),
      (),
    ),
    output: (
      (text: "ab", layers: ()),
    ),
  ),
  (
    input: (
      (
        (text: "a", layers: ()),
        (text: "b", layers: ()),
        (text: ":", layers: ()),
        (
          text: "c",
          layers: (),
          exponent: (text: "2", layers: ()),
        ),
      ),
      (1,),
    ),
    output: (
      (text: "a", layers: ()),
      (text: "bc", layers: (), exponent: (text: "−2", layers: ())),
    ),
  ),
)

#for (input, output) in group-units-tests {
  assert.eq(group-units(..input), output)
}


#let interpret-exponents-and-groups-tests = (
  (
    input: (
      children: ((text: "1/ab^2", layers: ()),),
      layers: (),
      group: false,
    ),
    output: (
      text: "ab",
      layers: (),
      exponent: (text: "−2", layers: ()),
    ),
  ),
  (
    input: (
      children: (
        (text: "a", layers: ()),
        (text: ":", layers: ()),
        (text: "b^2", layers: ()),
      ),
      layers: (),
      group: false,
    ),
    output: (
      text: "ab",
      layers: (),
      exponent: (text: "2", layers: ()),
    ),
  ),
  (
    input: (
      children: (
        (text: "a/b", layers: ()),
        (text: ":", layers: ()),
        (text: "c^2", layers: ()),
      ),
      layers: (),
      group: false,
    ),
    output: (
      children: (
        (text: "a", layers: ()),
        (
          text: "bc",
          layers: (),
          exponent: (text: "−2", layers: ()),
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
      children: ((text: "ab^2", layers: ()),),
      layers: (),
    ),
    output: (
      text: "ab",
      layers: (),
      exponent: (text: "2", layers: ()),
    ),
  ),
  (
    input: (
      children: ((text: "(a b)^2", layers: ()),),
      layers: (),
    ),
    output: (
      children: ((text: "a", layers: ()), (text: "b", layers: ())),
      layers: (),
      brackets: (0,),
      exponent: (text: "2", layers: ()),
      group: false,
    ),
  ),
)

#for (input, output) in interpret-unit-tests {
  assert.eq(interpret-unit(input), output)
}
