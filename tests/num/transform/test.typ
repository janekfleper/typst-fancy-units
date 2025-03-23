#set page(height: auto, width: auto, margin: 1em)
#import "/src/num/transform.typ": *


#let _shift-decimal-position-tests = (
  (input: (decimal("0.9"), 0), output: decimal("0.9")),
  (input: (decimal("0.9"), 1), output: decimal("9")),
  (input: (decimal("0.9"), 2), output: decimal("90")),
  (input: (decimal("0.9"), -1), output: decimal("0.09")),
  (input: (decimal("0.9"), -2), output: decimal("0.009")),
  (input: (decimal("137"), 0), output: decimal("137")),
  (input: (decimal("137"), 1), output: decimal("1370")),
  (input: (decimal("137"), -1), output: decimal("13.7")),
  (input: (decimal("137"), -2), output: decimal("1.37")),
  (input: (decimal("137"), -3), output: decimal("0.137")),
  (input: (decimal("137"), -4), output: decimal("0.0137")),
)

#for (input, output) in _shift-decimal-position-tests {
  assert.eq(_shift-decimal-position(..input), output)
}


#let _convert-uncertainty-relative-to-absolute-tests = (
  (
    input: (
      (body: decimal("27"), path: (0,), absolute: false, symmetric: true),
      (body: decimal("0.9"), path: (0,)),
    ),
    output: (body: decimal("2.7"), path: (0,), absolute: true, symmetric: true),
  ),
  (
    input: (
      (body: decimal("27"), path: (2,), absolute: false, symmetric: true),
      (body: decimal("0.137"), path: ()),
    ),
    output: (body: decimal("0.027"), path: (2,), absolute: true, symmetric: true),
  ),
  (
    input: (
      (body: decimal("27"), path: (), absolute: false, symmetric: true),
      (body: decimal("0.137"), path: (0,)),
    ),
    output: (body: decimal("0.027"), path: (), absolute: true, symmetric: true),
  ),
  (
    input: (
      (body: decimal("7"), path: (), absolute: false, symmetric: true),
      (body: decimal("0.137"), path: (0,)),
    ),
    output: (body: decimal("0.007"), path: (), absolute: true, symmetric: true),
  ),
)

#for (input, output) in _convert-uncertainty-relative-to-absolute-tests {
  assert.eq(_convert-uncertainty-relative-to-absolute(..input), output)
}


#let _convert-uncertainty-absolute-to-relative-tests = (
  (
    input: (
      (body: decimal("2.7"), path: (0,), absolute: true, symmetric: true),
      (body: decimal("0.9"), path: (0,)),
    ),
    output: (body: decimal("27"), path: (0,), absolute: false, symmetric: true),
  ),
  (
    input: (
      (body: decimal("0.027"), path: (2,), absolute: true, symmetric: true),
      (body: decimal("0.137"), path: ()),
    ),
    output: (body: decimal("27"), path: (2,), absolute: false, symmetric: true),
  ),
  (
    input: (
      (body: decimal("0.027"), path: (), absolute: true, symmetric: true),
      (body: decimal("0.137"), path: (0,)),
    ),
    output: (body: decimal("27"), path: (), absolute: false, symmetric: true),
  ),
  (
    input: (
      (body: decimal("0.007"), path: (), absolute: true, symmetric: true),
      (body: decimal("0.137"), path: (0,)),
    ),
    output: (body: decimal("7"), path: (), absolute: false, symmetric: true),
  ),
)

#for (input, output) in _convert-uncertainty-absolute-to-relative-tests {
  assert.eq(_convert-uncertainty-absolute-to-relative(..input), output)
}


#let absolute-uncertainties-tests = (
  (
    input: (
      value: (body: decimal("0.137"), layers: ()),
      uncertainties: (
        (body: decimal("0.027"), layers: (), absolute: true, symmetric: true),
      ),
      exponent: none,
      layers: (),
    ),
    output: (
      value: (body: decimal("0.137"), layers: ()),
      uncertainties: (
        (body: decimal("0.027"), layers: (), absolute: true, symmetric: true),
      ),
      exponent: none,
      layers: (),
    ),
  ),
  (
    input: (
      value: (body: decimal("0.137"), layers: ()),
      uncertainties: (
        (body: decimal("27"), layers: (), absolute: false, symmetric: true),
      ),
      exponent: none,
      layers: (),
    ),
    output: (
      value: (body: decimal("0.137"), layers: ()),
      uncertainties: (
        (body: decimal("0.027"), layers: (), absolute: true, symmetric: true),
      ),
      exponent: none,
      layers: (),
    ),
  ),
)

#for (input, output) in absolute-uncertainties-tests {
  assert.eq(absolute-uncertainties(input), output)
}


#let relative-uncertainties-tests = (
  (
    input: (
      value: (body: decimal("0.137"), layers: ()),
      uncertainties: (
        (body: decimal("0.027"), layers: (), absolute: true, symmetric: true),
      ),
      exponent: none,
      layers: (),
    ),
    output: (
      value: (body: decimal("0.137"), layers: ()),
      uncertainties: (
        (body: decimal("27"), layers: (), absolute: false, symmetric: true),
      ),
      exponent: none,
      layers: (),
    ),
  ),
  (
    input: (
      value: (body: decimal("0.137"), layers: ()),
      uncertainties: (
        (body: decimal("0.027"), layers: (), absolute: true, symmetric: true),
      ),
      exponent: none,
      layers: (),
    ),
    output: (
      value: (body: decimal("0.137"), layers: ()),
      uncertainties: (
        (body: decimal("27"), layers: (), absolute: false, symmetric: true),
      ),
      exponent: none,
      layers: (),
    ),
  ),
)

#for (input, output) in relative-uncertainties-tests {
  assert.eq(relative-uncertainties(input), output)
}
