#set page(height: auto, width: auto, margin: 1em)
#import "/src/num.typ": *


#let trim-leading-zeros-tests = (
  (input: "0.9", output: "0.9"),
  (input: "00.9", output: "0.9"),
  (input: "137", output: "137"),
  (input: "0137", output: "137"),
  (input: ".9", output: ".9"),
)

#for (input, output) in trim-leading-zeros-tests {
  assert.eq(trim-leading-zeros(input), output)
}


#let shift-decimal-position-tests = (
  (input: ("0.9", 0), output: "0.9"),
  (input: ("0.9", 1), output: "9"),
  (input: ("0.9", 2), output: "90"),
  (input: ("0.9", -1), output: "0.09"),
  (input: ("0.9", -2), output: "0.009"),
  (input: ("137", 0), output: "137"),
  (input: ("137", 1), output: "1370"),
  (input: ("137", -1), output: "13.7"),
  (input: ("137", -2), output: "1.37"),
  (input: ("137", -3), output: "0.137"),
  (input: ("137", -4), output: "0.0137"),
)

#for (input, output) in shift-decimal-position-tests {
  assert.eq(shift-decimal-position(..input), output)
}


#let convert-uncertainty-relative-to-absolute-tests = (
  (
    input: (
      (body: "27", path: (0,), absolute: false, symmetric: true),
      (body: "0.9", path: (0,)),
    ),
    output: (body: "2.7", path: (0,), absolute: true, symmetric: true),
  ),
  (
    input: (
      (body: "27", path: (2,), absolute: false, symmetric: true),
      (body: "0.137", path: ()),
    ),
    output: (body: "0.027", path: (2,), absolute: true, symmetric: true),
  ),
  (
    input: (
      (body: "27", path: (), absolute: false, symmetric: true),
      (body: "0.137", path: (0,)),
    ),
    output: (body: "0.027", path: (), absolute: true, symmetric: true),
  ),
  (
    input: (
      (body: "7", path: ()),
      (body: "0.137", path: (0,)),
    ),
    output: (body: "0.007", path: (), absolute: true),
  ),
)

#for (input, output) in convert-uncertainty-relative-to-absolute-tests {
  assert.eq(convert-uncertainty-relative-to-absolute(..input), output)
}


#let convert-uncertainty-absolute-to-relative-tests = (
  (
    input: (
      (body: "2.7", path: (0,), absolute: true, symmetric: true),
      (body: "0.9", path: (0,)),
    ),
    output: (body: "27", path: (0,), absolute: false, symmetric: true),
  ),
  (
    input: (
      (body: "0.027", path: (2,), absolute: true, symmetric: true),
      (body: "0.137", path: ()),
    ),
    output: (body: "27", path: (2,), absolute: false, symmetric: true),
  ),
  (
    input: (
      (body: "0.027", path: (), absolute: true, symmetric: true),
      (body: "0.137", path: (0,)),
    ),
    output: (body: "27", path: (), absolute: false, symmetric: true),
  ),
  (
    input: (
      (body: "0.007", path: ()),
      (body: "0.137", path: (0,)),
    ),
    output: (body: "7", path: (), absolute: false),
  ),
)

#for (input, output) in convert-uncertainty-absolute-to-relative-tests {
  assert.eq(convert-uncertainty-absolute-to-relative(..input), output)
}


#let convert-uncertainty-tests = (
  (
    input: (
      (body: "0.027", path: (), absolute: true, symmetric: true),
      (body: "0.137", path: ()),
      "plus-minus",
    ),
    output: (body: "0.027", path: (), absolute: true, symmetric: true),
  ),
  (
    input: (
      (body: "0.027", path: (), absolute: true, symmetric: true),
      (body: "0.137", path: ()),
      "parentheses",
    ),
    output: (body: "27", path: (), absolute: false, symmetric: true),
  ),
  (
    input: (
      (body: "0.027", path: (), absolute: true, symmetric: true),
      (body: "0.137", path: ()),
      "conserve",
    ),
    output: (body: "0.027", path: (), absolute: true, symmetric: true),
  ),
  (
    input: (
      (body: "27", path: (), absolute: false, symmetric: true),
      (body: "0.137", path: ()),
      "plus-minus",
    ),
    output: (body: "0.027", path: (), absolute: true, symmetric: true),
  ),
  (
    input: (
      (body: "27", path: (), absolute: false, symmetric: true),
      (body: "0.137", path: ()),
      "parentheses",
    ),
    output: (body: "27", path: (), absolute: false, symmetric: true),
  ),
  (
    input: (
      (body: "27", path: (), absolute: false, symmetric: true),
      (body: "0.137", path: ()),
      "conserve",
    ),
    output: (body: "27", path: (), absolute: false, symmetric: true),
  ),
)


#for (input, output) in convert-uncertainty-tests {
  assert.eq(convert-uncertainty(..input), output)
}
