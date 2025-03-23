#set page(height: auto, width: auto, margin: 1em)
#import "/src/unit/transform.typ": *


#let _invert-number-tests = (
  (input: "2", output: "−2"),
  (input: "−2", output: "2"),
)

#for (input, output) in _invert-number-tests {
  assert.eq(_invert-number(input), output)
}


#let _apply-exponent-tests = (
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

#for (input, output) in _apply-exponent-tests {
  assert.eq(_apply-exponent(..input), output)
}


#let _invert-exponent-tests = (
  (
    input: (body: "a", layers: (), exponent: (body: "2", layers: ())),
    output: (body: "a", layers: (), exponent: (body: "−2", layers: ())),
  ),
  (
    input: (body: "a", layers: (), exponent: (body: "−2", layers: ())),
    output: (body: "a", layers: (), exponent: (body: "2", layers: ())),
  ),
)

#for (input, output) in _invert-exponent-tests {
  assert.eq(_invert-exponent(input), output)
}


#let _inherit-exponents-tests = (
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

#for (input, output) in _inherit-exponents-tests {
  assert.eq(_inherit-exponents(input), output)
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
