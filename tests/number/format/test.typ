#set page(height: auto, width: auto, margin: 1em)
#import "/src/number.typ": *


#let format-symmetric-uncertainty-tests = (
  (
    uncertainty: (absolute: false, symmetric: true, body: "1", path: ()),
    tree: (body: "0.9(1)", layers: ()),
    config: (decimal-separator: "."),
  ),
  (
    uncertainty: (absolute: true, symmetric: true, body: "0.1", path: ()),
    tree: (body: "0.9(1)", layers: ()),
    config: (decimal-separator: "."),
  ),
  (
    uncertainty: (absolute: true, symmetric: true, body: "0.1", path: ()),
    tree: (body: "0.9(1)", layers: ()),
    config: (decimal-separator: ","),
  ),
  (
    uncertainty: (absolute: false, symmetric: true, body: "1", path: (1,)),
    tree: (
      children: (
        (body: "0.9", layers: ()),
        (body: "(1)", layers: ((strong, (:)),)),
      ),
      layers: (),
    ),
    config: (decimal-separator: "."),
  ),
  (
    uncertainty: (absolute: true, symmetric: true, body: "0.1", path: (1,)),
    tree: (
      children: (
        (body: "0.9", layers: ()),
        (body: "(1)", layers: ((strong, (:)),)),
      ),
      layers: (),
    ),
    config: (decimal-separator: "."),
  ),
)

#for test in format-symmetric-uncertainty-tests {
  box(
    math.equation(
      format-symmetric-uncertainty(
        test.uncertainty,
        test.tree,
        test.config,
      ),
    ),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let format-asymmetric-uncertainty-tests = (
  (
    positive: (absolute: true, body: "9", path: ()),
    negative: (absolute: true, body: "27", path: ()),
    tree: (body: "137+9-27", layers: ()),
    config: (decimal-separator: "."),
  ),
  (
    positive: (absolute: true, body: "0.1", path: ()),
    negative: (absolute: true, body: "0.2", path: ()),
    tree: (body: "0.9+0.1-0.2", layers: ()),
    config: (decimal-separator: "."),
  ),
  (
    positive: (absolute: true, body: "0.01", path: ()),
    negative: (absolute: true, body: "0.2", path: ()),
    tree: (body: "0.9+0.01-0.2", layers: ()),
    config: (decimal-separator: ","),
  ),
  (
    positive: (absolute: true, body: "0.1", path: (1,)),
    negative: (absolute: true, body: "0.2", path: (1,)),
    tree: (
      children: (
        (body: "0.9", layers: ()),
        (body: "+0.1-0.2", layers: ((strong, (:)),)),
      ),
      layers: (),
    ),
    config: (decimal-separator: "."),
  ),
)

#for test in format-asymmetric-uncertainty-tests {
  box(
    math.equation(
      format-asymmetric-uncertainty(
        test.positive,
        test.negative,
        test.tree,
        test.config,
      ),
    ),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let format-exponent-tests = (
  (
    exponent: (body: "1", path: ()),
    tree: (body: "0.9e-1", layers: ()),
    config: (decimal-separator: "."),
  ),
  (
    exponent: (body: "0.5", path: ()),
    tree: (body: "0.9e-0.5", layers: ()),
    config: (decimal-separator: "."),
  ),
  (
    exponent: (body: "0.5", path: ()),
    tree: (body: "0.9e-0.5", layers: ()),
    config: (decimal-separator: ","),
  ),
  (
    exponent: (body: "−1", path: (2,)),
    tree: (
      children: (
        (body: "0.9", layers: ()),
        (body: " ", layers: ()),
        (body: "e-1", layers: ((strong, (:)),)),
      ),
      layers: (),
    ),
    config: (decimal-separator: "."),
  ),
)

#for test in format-exponent-tests {
  box(
    math.equation(
      format-exponent(
        test.exponent,
        test.tree,
        test.config,
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
      value: (body: "0.9", path: ()),
      uncertainties: (),
      exponent: none,
    ),
    tree: (body: "0.9", layers: ()),
    config: (decimal-separator: "."),
  ),
  (
    number: (
      value: (body: "0.9", path: ()),
      uncertainties: (),
      exponent: none,
    ),
    tree: (body: "0.9", layers: ((strong, (:)),)),
    config: (decimal-separator: ","),
  ),
  (
    number: (
      value: (body: "0.9", path: ()),
      uncertainties: (
        (
          absolute: false,
          symmetric: true,
          body: "1",
          path: (),
        ),
        (
          absolute: false,
          symmetric: true,
          body: "2",
          path: (),
        ),
      ),
      exponent: none,
    ),
    tree: (body: "0.9", layers: ()),
    config: (decimal-separator: ".", uncertainty-mode: "conserve"),
  ),
  (
    number: (
      value: (body: "0.9", path: ()),
      uncertainties: (
        (
          absolute: true,
          symmetric: true,
          body: "0.1",
          path: (),
        ),
        (
          absolute: true,
          symmetric: true,
          body: "0.2",
          path: (),
        ),
      ),
      exponent: none,
    ),
    tree: (body: "0.9", layers: ()),
    config: (decimal-separator: ".", uncertainty-mode: "conserve"),
  ),
  (
    number: (
      value: (body: "0.9", path: ()),
      uncertainties: (
        (
          absolute: false,
          symmetric: true,
          body: "1",
          path: (),
        ),
      ),
      exponent: (body: "−1", path: ()),
    ),
    tree: (body: "0.9e-1", layers: ()),
    config: (decimal-separator: ".", uncertainty-mode: "conserve"),
  ),
  (
    number: (
      value: (body: "0.9", path: ()),
      uncertainties: (
        (
          absolute: true,
          symmetric: true,
          body: "0.1",
          path: (),
        ),
      ),
      exponent: (body: "−1", path: ()),
    ),
    tree: (body: "0.9e-1", layers: ()),
    config: (decimal-separator: ".", uncertainty-mode: "conserve"),
  ),
)

#for test in format-number-tests {
  box(
    math.equation(
      format-number(
        test.number,
        test.tree,
        test.config,
      ),
    ),
    stroke: red + 0.5pt,
  )
  linebreak()
}
