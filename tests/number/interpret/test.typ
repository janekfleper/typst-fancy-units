#set page(height: auto, width: auto, margin: 1em)
#import "/src/number.typ": *

#let find-value-tests = (
  ((text: "137", layers: ()),),
  ((text: "137(1)e5", layers: ()),),
  ((text: "−137", layers: ((strong: (:)),)),),
  ((text: "−137(1)e5", layers: ((strong: (:)),)),),
)

#for leaves in find-value-tests {
  (find-value(leaves),)
}

#pagebreak()

#let find-exponent-tests = (
  ((text: "137", layers: ()),),
  ((text: "137(1)e5", layers: ()),),
  ((text: "−137", layers: ((strong: (:)),)),),
  ((text: "−137(1)e5", layers: ((strong: (:)),)),),
)

#for leaves in find-exponent-tests {
  (find-exponent(leaves),)
}

#pagebreak()

#let find-value-and-exponent-tests = (
  ((text: "137", layers: ()),),
  ((text: "137(1)e5", layers: ()),),
  ((text: "−137", layers: ((strong: (:)),)),),
  ((text: "−137(1)e5", layers: ((strong: (:)),)),),
)

#for leaves in find-value-and-exponent-tests {
  (find-value-and-exponent(leaves),)
}

#pagebreak()

#let find-uncertainties-tests = (
  ((text: "+−0.9", path: ()),),
  ((text: "(137)", path: ()),),
  ((text: "(137)", path: (0, 1, 2)),),
  (
    (text: "+", path: (2,)),
    (text: "0.9", path: (4,)),
    (text: "−", path: (6,)),
    (text: "0.1", path: (8,)),
  ),
  ((text: "(1:2)", path: ()),),
  ((text: "(1)+−0.2", path: ()),),
  ((text: "(1)(2)", path: ()),),
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
