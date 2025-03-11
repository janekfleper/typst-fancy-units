#set page(height: auto, width: auto, margin: 1em)
#import "/src/unit.typ": *


#let invert-number-tests = (
  (input: "2", output: "−2"),
  (input: "−2", output: "2"),
)

#for (input, output) in invert-number-tests {
  assert.eq(invert-number(input), output)
}


#let apply-exponent-tests = (
  (
    input: (
      (body: "a", layers: ()),
      (body: "2", layers: ((strong, (:)),)),
    ),
    output: (body: "a", layers: (), exponent: (body: "2", layers: ((strong, (:)),))),
  ),
  (
    input: (
      (body: "a", layers: (), exponent: (body: "2", layers: ())),
      (body: "−1", layers: ()),
    ),
    output: (body: "a", layers: (), exponent: (body: "−2", layers: ())),
  ),
  (
    input: (
      (body: "a", layers: (), exponent: (body: "−1", layers: ())),
      (body: "3", layers: ()),
    ),
    output: (body: "a", layers: (), exponent: (body: "−3", layers: ())),
  ),
  (
    input: (
      (body: "a", layers: (), exponent: (body: "1/2", layers: ())),
      (body: "3", layers: ()),
    ),
    output: (body: "a", layers: (), exponent: (body: "3/2", layers: ())),
  ),
)

#for (input, output) in apply-exponent-tests {
  assert.eq(apply-exponent(..input), output)
}


#let invert-exponent-tests = (
  (
    input: (body: "a", layers: (), exponent: (body: "2", layers: ())),
    output: (body: "a", layers: (), exponent: (body: "−2", layers: ())),
  ),
  (
    input: (body: "a", layers: (), exponent: (body: "−2", layers: ())),
    output: (body: "a", layers: (), exponent: (body: "2", layers: ())),
  ),
)

#for (input, output) in invert-exponent-tests {
  assert.eq(invert-exponent(input), output)
}


#let simplify-units-tests = (
  (
    input: (
      (
        children: ((body: "1/a^2", layers: ()),),
        layers: (),
        group: false,
      ),
      (
        (body: "1", layers: ()),
        (
          body: "a",
          layers: (),
          exponent: (body: "−2", layers: ()),
        ),
      ),
    ),
    output: (
      body: "a",
      layers: (),
      exponent: (body: "−2", layers: ()),
    ),
  ),
  (
    input: (
      (
        children: ((body: "a b", layers: ()),),
        layers: (),
        brackets: (0,),
      ),
      (
        (body: "a", layers: ()),
        (body: "b", layers: ()),
      ),
    ),
    output: (
      children: ((body: "a", layers: ()), (body: "b", layers: ())),
      layers: (),
      brackets: (0,),
    ),
  ),
)

#for (input, output) in simplify-units-tests {
  assert.eq(simplify-units(..input), output)
}


#let inherit-exponents-tests = (
  (
    input: (
      children: ((body: "a", layers: ()), (body: "b", layers: ())),
      layers: (),
      brackets: (0,),
      exponent: (body: "2", layers: ()),
      group: false,
    ),
    output: (
      children: (
        (
          body: "a",
          layers: (),
          exponent: (body: "2", layers: ()),
        ),
        (
          body: "b",
          layers: (),
          exponent: (body: "2", layers: ()),
        ),
      ),
      layers: (),
      brackets: (0,),
      group: false,
    ),
  ),
)

#for (input, output) in inherit-exponents-tests {
  assert.eq(inherit-exponents(input), output)
}


#let insert-macros-tests = (
  (
    input: (
      (
        body: "a",
        layers: (),
        exponent: (body: "2", layers: ()),
      ),
      (
        a: (body: "α", layers: ()),
      ),
    ),
    output: (
      body: "α",
      layers: (),
      exponent: (body: "2", layers: ()),
    ),
  ),
  (
    input: (
      (
        body: "a",
        layers: (),
        exponent: (body: "2", layers: ()),
      ),
      (:),
    ),
    output: (
      body: "a",
      layers: (),
      exponent: (body: "2", layers: ()),
    ),
  ),
  (
    input: (
      (
        body: "ab",
        layers: (),
        exponent: (body: "2", layers: ()),
      ),
      (
        ab: (
          body: "a",
          layers: ((emph, (:)),),
          subscript: (body: "b", layers: ()),
        ),
      ),
    ),
    output: (
      body: "a",
      layers: ((emph, (:)),),
      subscript: (body: "b", layers: ()),
      exponent: (body: "2", layers: ()),
    ),
  ),
)

#for (input, output) in insert-macros-tests {
  assert.eq(insert-macros(..input), output)
}
