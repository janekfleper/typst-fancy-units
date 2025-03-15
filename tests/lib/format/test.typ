#set page(height: auto, width: auto, margin: 1em)
#import "/src/lib.typ": *
#import "/src/num.typ": *
#import "/src/unit/format.typ": *


#let num-tests = (
  (lang: "en", transform: auto, format: auto, body: [0.9]),
  (lang: "en", transform: auto, format: format-num.with(decimal-separator: ","), body: [0.9]),
  (lang: "de", transform: absolute-uncertainties, format: format-num.with(decimal-separator: "."), body: [0.9(1)]),
  (lang: "de", transform: relative-uncertainties, format: auto, body: [0.9(1)]),
  (lang: "fr", transform: auto, format: auto, body: [0.9+-*0.1*]),
  (lang: "xy", transform: auto, format: auto, body: [0.9(1)]),
)

#for test in num-tests {
  set text(lang: test.lang)
  box(
    num(transform: test.transform, format: test.format, test.body),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let unit-tests = (
  (transform: auto, format: auto, body: [a^2]),
  (transform: auto, format: auto, body: [a^-2]),
  (transform: auto, format: format-unit-fraction.with(separator: sym.dot.op), body: [(a b)^-2]),
  (transform: auto, format: format-unit-symbol, body: [a^-1]),
  (transform: auto, format: format-unit-power.with(separator: sym.dot.op), body: [*μ*:b c]),
)

#for test in unit-tests {
  box(
    unit(transform: test.transform, format: test.format, test.body),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let qty-tests = (
  (format: auto, body-number: [0.9], body-unit: [g]),
  (format: auto, body-number: [137], body-unit: [m^-2]),
  (format: format-qty.with(separator: sym.times), body-number: [27], body-unit: [_E_#sub[rec]]),
)

#for test in qty-tests {
  box(
    qty(format: test.format, test.body-number, test.body-unit),
    stroke: red + 0.5pt,
  )
  linebreak()
}
