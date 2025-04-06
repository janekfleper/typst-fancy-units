#set page(height: auto, width: auto, margin: 1em)
#import "/src/num/format.typ": *


#let _format-symmetric-uncertainty-tests = (
  (
    uncertainty: (absolute: false, symmetric: true, body: "1", layers: ()),
    decimal-separator: ".",
  ),
  (
    uncertainty: (absolute: true, symmetric: true, body: "0.1", layers: ()),
    decimal-separator: ".",
  ),
  (
    uncertainty: (absolute: true, symmetric: true, body: "0.1", layers: ()),
    decimal-separator: ",",
  ),
  (
    uncertainty: (absolute: false, symmetric: true, body: "1", layers: ((strong, (:)),)),
    decimal-separator: ".",
  ),
  (
    uncertainty: (absolute: true, symmetric: true, body: "0.1", layers: ((strong, (:)),)),
    decimal-separator: ".",
  ),
)

#for test in _format-symmetric-uncertainty-tests {
  box(
    math.equation(
      _format-symmetric-uncertainty(
        test.uncertainty,
        test.decimal-separator,
      ),
    ),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let _format-asymmetric-uncertainty-tests = (
  (
    positive: (absolute: true, body: "9", layers: ()),
    negative: (absolute: true, body: "27", layers: ()),
    decimal-separator: ".",
  ),
  (
    positive: (absolute: true, body: "0.1", layers: ()),
    negative: (absolute: true, body: "0.2", layers: ()),
    decimal-separator: ".",
  ),
  (
    positive: (absolute: true, body: "0.01", layers: ()),
    negative: (absolute: true, body: "0.2", layers: ()),
    decimal-separator: ",",
  ),
  (
    positive: (absolute: true, body: "0.1", layers: ((strong, (:)),)),
    negative: (absolute: true, body: "0.2", layers: ((strong, (:)),)),
    decimal-separator: ".",
  ),
)

#for test in _format-asymmetric-uncertainty-tests {
  box(
    math.equation(
      _format-asymmetric-uncertainty(
        test.positive,
        test.negative,
        test.decimal-separator,
      ),
    ),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let _format-exponent-tests = (
  (
    exponent: (body: "1", layers: ()),
    separator: sym.times,
    base: [10],
    decimal-separator: ".",
  ),
  (
    exponent: (body: "0.5", layers: ()),
    separator: sym.dot,
    base: [10],
    decimal-separator: ".",
  ),
  (
    exponent: (body: "0.5", layers: ()),
    separator: sym.times,
    base: [10],
    decimal-separator: ",",
  ),
  (
    exponent: (body: "−1", layers: ((strong, (:)),)),
    separator: sym.times,
    base: [2],
    decimal-separator: ".",
  ),
)

#for test in _format-exponent-tests {
  box(
    math.equation(
      _format-exponent(
        test.exponent,
        test.separator,
        test.base,
        test.decimal-separator,
      ),
    ),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let format-number-tests = (
  (
    number: (
      value: (body: "0.9", layers: ()),
      uncertainties: (),
      exponent: none,
      layers: (),
    ),
    decimal-separator: ".",
  ),
  (
    number: (
      value: (body: "0.9", layers: ((strong, (:)),)),
      uncertainties: (),
      exponent: none,
      layers: (),
    ),
    decimal-separator: ",",
  ),
  (
    number: (
      value: (body: "0.9", layers: ()),
      uncertainties: (
        (
          absolute: false,
          symmetric: true,
          body: "1",
          layers: (),
        ),
        (
          absolute: false,
          symmetric: true,
          body: "2",
          layers: (),
        ),
      ),
      exponent: none,
      layers: (),
    ),
    decimal-separator: ".",
  ),
  (
    number: (
      value: (body: "0.9", layers: ()),
      uncertainties: (
        (
          absolute: true,
          symmetric: true,
          body: "0.1",
          layers: (),
        ),
        (
          absolute: true,
          symmetric: true,
          body: "0.2",
          layers: (),
        ),
      ),
      exponent: none,
      layers: (),
    ),
    decimal-separator: ".",
  ),
  (
    number: (
      value: (body: "0.9", layers: ()),
      uncertainties: (
        (
          absolute: false,
          symmetric: true,
          body: "1",
          layers: (),
        ),
      ),
      exponent: (body: "−1", layers: ()),
      layers: (),
    ),
    decimal-separator: ".",
  ),
  (
    number: (
      value: (body: "0.9", layers: ()),
      uncertainties: (
        (
          absolute: true,
          symmetric: true,
          body: "0.1",
          layers: (),
        ),
      ),
      exponent: (body: "−1", layers: ()),
      layers: (),
    ),
    decimal-separator: ".",
  ),
)

#for test in format-number-tests {
  box(
    math.equation(
      format-num(
        test.number,
        decimal-separator: test.decimal-separator,
      ),
    ),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let group-digits-tests-number = (
  value: (body: "12345.567890", layers: ()),
  uncertainties: (
    (
      absolute: true,
      symmetric: true,
      body: "0.00001",
      layers: (),
    ),
  ),
  exponent: none,
  layers: (),
)

#let group-digits-tests-decimal-separator = "."

#let group-digits-tests = (
  (target: auto, mode: auto, size: 3, threshold: 5, separator: " "),
  (target: "value", mode: auto, size: 3, threshold: 5, separator: " "),
  (target: "uncertainties", mode: auto, size: 3, threshold: 5, separator: " "),
  (target: auto, mode: "integer", size: 3, threshold: 5, separator: " "),
  (target: auto, mode: "decimal", size: 3, threshold: 5, separator: " "),
  (target: auto, mode: auto, size: 2, threshold: 5, separator: " "),
  (target: auto, mode: auto, size: 3, threshold: 6, separator: " "),
)

#for test in group-digits-tests {
  let number = group-digits(
    group-digits-tests-number,
    target: test.target,
    mode: test.mode,
    size: test.size,
    threshold: test.threshold,
    separator: test.separator,
  )

  box(
    format-num(
      number,
      decimal-separator: group-digits-tests-decimal-separator,
    ),
    stroke: red + 0.5pt,
  )
  linebreak()
}
