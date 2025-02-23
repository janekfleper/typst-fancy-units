#set page(height: auto, width: auto, margin: 1em)
#import "/src/lib.typ": *


#let num-tests = (
  (lang: "en", decimal-separator: auto, uncertainty-mode: auto, body: [0.9]),
  (lang: "en", decimal-separator: ",", uncertainty-mode: auto, body: [0.9]),
  (lang: "de", decimal-separator: ".", uncertainty-mode: "plus-minus", body: [0.9(1)]),
  (lang: "de", decimal-separator: auto, uncertainty-mode: "parentheses", body: [0.9(1)]),
  (lang: "fr", decimal-separator: auto, uncertainty-mode: "conserve", body: [0.9+-*0.1*]),
  (lang: "xy", decimal-separator: auto, uncertainty-mode: "conserve", body: [0.9(1)]),
)

#for test in num-tests {
  set text(lang: test.lang)
  box(
    num(decimal-separator: test.decimal-separator, uncertainty-mode: test.uncertainty-mode, test.body),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let unit-tests = (
  (unit-separator: auto, per-mode: auto, body: [a^2]),
  (unit-separator: auto, per-mode: auto, body: [a^-2]),
  (unit-separator: sym.dot.op, per-mode: "fraction", body: [(a b)^-2]),
  (unit-separator: auto, per-mode: "slash", body: [a^-1]),
  (unit-separator: sym.dot.op, per-mode: auto, body: [*μ*:b c]),
)

#for test in unit-tests {
  box(
    unit(
      unit-separator: test.unit-separator,
      per-mode: test.per-mode,
      test.body,
    ),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let qty-tests = (
  (quantity-separator: auto, body-number: [0.9], body-unit: [g]),
  (quantity-separator: auto, body-number: [137], body-unit: [m^-2]),
  (quantity-separator: sym.times, body-number: [27], body-unit: [_E_#sub[rec]]),
)

#for test in qty-tests {
  box(
    qty(quantity-separator: test.quantity-separator, test.body-number, test.body-unit),
    stroke: red + 0.5pt,
  )
  linebreak()
}
