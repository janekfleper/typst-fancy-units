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
    decimal-separator: ".",
  ),
  (
    exponent: (body: "0.5", layers: ()),
    decimal-separator: ".",
  ),
  (
    exponent: (body: "0.5", layers: ()),
    decimal-separator: ",",
  ),
  (
    exponent: (body: "−1", layers: ((strong, (:)),)),
    decimal-separator: ".",
  ),
)

#for test in _format-exponent-tests {
  box(
    math.equation(
      _format-exponent(
        test.exponent,
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
