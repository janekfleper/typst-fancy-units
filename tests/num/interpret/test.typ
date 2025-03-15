#set page(height: auto, width: auto, margin: 1em)
#import "/src/num.typ": *

#let find-value-tests = (
  (
    input: ((body: "137", layers: ()),),
    output: (leaves: (), value: (body: "137", layers: ())),
  ),
  (
    input: ((body: "137(1)e5", layers: ()),),
    output: (leaves: ((body: "(1)e5", layers: ()),), value: (body: "137", layers: ())),
  ),
  (
    input: ((body: "−137", layers: ((strong: (:)),)),),
    output: (leaves: (), value: (body: "−137", layers: ((strong: (:)),))),
  ),
  (
    input: ((body: "−137(1)e5", layers: ((strong: (:)),)),),
    output: (leaves: ((body: "(1)e5", layers: ((strong: (:)),)),), value: (body: "−137", layers: ((strong: (:)),))),
  ),
)

#for (input, output) in find-value-tests {
  assert.eq(find-value(input), output)
}

#pagebreak()

#let find-exponent-tests = (
  (
    input: ((body: "137", layers: ()),),
    output: (leaves: ((body: "137", layers: ()),), exponent: none),
  ),
  (
    input: ((body: "137(1)e5", layers: ()),),
    output: (leaves: ((body: "137(1)", layers: ()),), exponent: (body: "5", layers: ())),
  ),
  (
    input: ((body: "−137", layers: ((strong: (:)),)),),
    output: (leaves: ((body: "−137", layers: ((strong: (:)),)),), exponent: none),
  ),
  (
    input: ((body: "−137(1)e5", layers: ((strong: (:)),)),),
    output: (leaves: ((body: "−137(1)", layers: ((strong: (:)),)),), exponent: (body: "5", layers: ((strong: (:)),))),
  ),
)

#for (input, output) in find-exponent-tests {
  assert.eq(find-exponent(input), output)
}

#pagebreak()

#let find-value-and-exponent-tests = (
  (
    input: ((body: "137", layers: ()),),
    output: (leaves: (), value: (body: decimal("137"), layers: ()), exponent: none),
  ),
  (
    input: ((body: "137(1)e5", layers: ()),),
    output: (
      leaves: ((body: "(1)", layers: ()),),
      value: (body: decimal("137"), layers: ()),
      exponent: (body: decimal("5"), layers: ()),
    ),
  ),
  (
    input: ((body: "−137", layers: ((strong: (:)),)),),
    output: (leaves: (), value: (body: decimal("-137"), layers: ((strong: (:)),)), exponent: none),
  ),
  (
    input: ((body: "−137(1)e5", layers: ((strong: (:)),)),),
    output: (
      leaves: ((body: "(1)", layers: ((strong: (:)),)),),
      value: (body: decimal("-137"), layers: ((strong: (:)),)),
      exponent: (body: decimal("5"), layers: ((strong: (:)),)),
    ),
  ),
)

#for (input, output) in find-value-and-exponent-tests {
  assert.eq(find-value-and-exponent(input), output)
}

#pagebreak()

#let find-uncertainties-tests = (
  (
    input: ((body: "+−0.9", path: ()),),
    output: ((absolute: true, symmetric: true, body: decimal("0.9"), path: ()),),
  ),
  (
    input: ((body: "(137)", path: ()),),
    output: ((absolute: false, symmetric: true, body: decimal("137"), path: ()),),
  ),
  (
    input: ((body: "(137)", path: (0, 1, 2)),),
    output: ((absolute: false, symmetric: true, body: decimal("137"), path: (0, 1, 2)),),
  ),
  (
    input: (
      (body: "+", path: (2,)),
      (body: "0.9", path: (4,)),
      (body: "−", path: (6,)),
      (body: "0.1", path: (8,)),
    ),
    output: (
      (
        absolute: true,
        symmetric: false,
        positive: (body: decimal("0.9"), path: (4,)),
        negative: (body: decimal("0.1"), path: (8,)),
      ),
    ),
  ),
  (
    input: ((body: "(1:2)", path: ()),),
    output: (
      (
        absolute: false,
        symmetric: false,
        positive: (body: decimal("1"), path: ()),
        negative: (body: decimal("2"), path: ()),
      ),
    ),
  ),
  (
    input: ((body: "(1)+−0.2", path: ()),),
    output: (
      (
        absolute: false,
        symmetric: true,
        body: decimal("1"),
        path: (),
      ),
      (
        absolute: true,
        symmetric: true,
        body: decimal("0.2"),
        path: (),
      ),
    ),
  ),
  (
    input: ((body: "(1)(2)", path: ()),),
    output: (
      (
        absolute: false,
        symmetric: true,
        body: decimal("1"),
        path: (),
      ),
      (
        absolute: false,
        symmetric: true,
        body: decimal("2"),
        path: (),
      ),
    ),
  ),
)

#for (input, output) in find-uncertainties-tests {
  assert.eq(find-uncertainties(input), output)
}

#pagebreak()

#let interpret-number-tests = (
  (
    input: [0.9],
    output: (
      value: (body: decimal("0.9"), layers: ()),
      uncertainties: (),
      exponent: none,
      layers: (),
    ),
  ),
  (
    input: [*0.9*],
    output: (
      value: (body: decimal("0.9"), layers: ()),
      uncertainties: (),
      exponent: none,
      layers: ((strong, (:)),),
    ),
  ),
  (
    input: [0.9+-0.1e5],
    output: (
      value: (body: decimal("0.9"), layers: ()),
      uncertainties: (
        (
          absolute: true,
          symmetric: true,
          body: decimal("0.1"),
          layers: (),
        ),
      ),
      exponent: (body: decimal("5"), layers: ()),
      layers: (),
    ),
  ),
  (
    input: [0.9*(1)*e5],
    output: (
      value: (body: decimal("0.9"), layers: ()),
      uncertainties: (
        (
          absolute: false,
          symmetric: true,
          body: decimal("1"),
          layers: ((strong, (:)),),
        ),
      ),
      exponent: (body: decimal("5"), layers: ()),
      layers: (),
    ),
  ),
)

#for (input, output) in interpret-number-tests {
  assert.eq(interpret-number(input), output)
}
