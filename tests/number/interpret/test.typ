#set page(height: auto, width: auto, margin: 1em)
#import "/src/number.typ": *

#let find-value-tests = (
  ((body: "137", layers: ()),),
  ((body: "137(1)e5", layers: ()),),
  ((body: "−137", layers: ((strong: (:)),)),),
  ((body: "−137(1)e5", layers: ((strong: (:)),)),),
)

#for leaves in find-value-tests {
  (find-value(leaves),)
}

#pagebreak()

#let find-exponent-tests = (
  ((body: "137", layers: ()),),
  ((body: "137(1)e5", layers: ()),),
  ((body: "−137", layers: ((strong: (:)),)),),
  ((body: "−137(1)e5", layers: ((strong: (:)),)),),
)

#for leaves in find-exponent-tests {
  (find-exponent(leaves),)
}

#pagebreak()

#let find-value-and-exponent-tests = (
  ((body: "137", layers: ()),),
  ((body: "137(1)e5", layers: ()),),
  ((body: "−137", layers: ((strong: (:)),)),),
  ((body: "−137(1)e5", layers: ((strong: (:)),)),),
)

#for leaves in find-value-and-exponent-tests {
  (find-value-and-exponent(leaves),)
}

#pagebreak()

#let find-uncertainties-tests = (
  ((body: "+−0.9", path: ()),),
  ((body: "(137)", path: ()),),
  ((body: "(137)", path: (0, 1, 2)),),
  (
    (body: "+", path: (2,)),
    (body: "0.9", path: (4,)),
    (body: "−", path: (6,)),
    (body: "0.1", path: (8,)),
  ),
  ((body: "(1:2)", path: ()),),
  ((body: "(1)+−0.2", path: ()),),
  ((body: "(1)(2)", path: ()),),
)

#for leaves in find-uncertainties-tests {
  (find-uncertainties(leaves),)
}

#pagebreak()

#let interpret-number-tests = (
  [0.9],
  [*0.9*],
  [0.9+-0.1e5],
  [0.9*(1)*e5],
)

#for c in interpret-number-tests {
  (interpret-number(c),)
}
