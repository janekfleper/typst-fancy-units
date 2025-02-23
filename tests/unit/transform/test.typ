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
      (text: "a", layers: ()),
      (text: "2", layers: ((strong, (:)),)),
    ),
    output: (text: "a", layers: (), exponent: (text: "2", layers: ((strong, (:)),))),
  ),
  (
    input: (
      (text: "a", layers: (), exponent: (text: "2", layers: ())),
      (text: "−1", layers: ()),
    ),
    output: (text: "a", layers: (), exponent: (text: "−2", layers: ())),
  ),
  (
    input: (
      (text: "a", layers: (), exponent: (text: "−1", layers: ())),
      (text: "3", layers: ()),
    ),
    output: (text: "a", layers: (), exponent: (text: "−3", layers: ())),
  ),
  (
    input: (
      (text: "a", layers: (), exponent: (text: "1/2", layers: ())),
      (text: "3", layers: ()),
    ),
    output: (text: "a", layers: (), exponent: (text: "3/2", layers: ())),
  ),
)

#for (input, output) in apply-exponent-tests {
  assert.eq(apply-exponent(..input), output)
}


#let invert-exponent-tests = (
  (
    input: (text: "a", layers: (), exponent: (text: "2", layers: ())),
    output: (text: "a", layers: (), exponent: (text: "−2", layers: ())),
  ),
  (
    input: (text: "a", layers: (), exponent: (text: "−2", layers: ())),
    output: (text: "a", layers: (), exponent: (text: "2", layers: ())),
  ),
)

#for (input, output) in invert-exponent-tests {
  assert.eq(invert-exponent(input), output)
}


#let simplify-units-tests = (
  (
    input: (
      (
        children: ((text: "1/a^2", layers: ()),),
        layers: (),
        group: false,
      ),
      (
        (text: "1", layers: ()),
        (
          text: "a",
          layers: (),
          exponent: (text: "−2", layers: ()),
        ),
      ),
    ),
    output: (
      text: "a",
      layers: (),
      exponent: (text: "−2", layers: ()),
    ),
  ),
  (
    input: (
      (
        children: ((text: "a b", layers: ()),),
        layers: (),
        brackets: (0,),
      ),
      (
        (text: "a", layers: ()),
        (text: "b", layers: ()),
      ),
    ),
    output: (
      children: ((text: "a", layers: ()), (text: "b", layers: ())),
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
      children: ((text: "a", layers: ()), (text: "b", layers: ())),
      layers: (),
      brackets: (0,),
      exponent: (text: "2", layers: ()),
      group: false,
    ),
    output: (
      children: (
        (
          text: "a",
          layers: (),
          exponent: (text: "2", layers: ()),
        ),
        (
          text: "b",
          layers: (),
          exponent: (text: "2", layers: ()),
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
