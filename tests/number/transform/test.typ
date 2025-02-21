#set page(height: auto, width: auto, margin: 1em)
#import "/src/number.typ": *


#let trim-leading-zeros-tests = (
  ("0.9", "0.9"),
  ("00.9", "0.9"),
  ("137", "137"),
  ("0137", "137"),
  (".9", ".9"),
)

#for (input, output) in trim-leading-zeros-tests {
  assert.eq(trim-leading-zeros(input), output)
}


#let shift-decimal-position-tests = (
  (("0.9", 0), "0.9"),
  (("0.9", 1), "9"),
  (("0.9", 2), "90"),
  (("0.9", -1), "0.09"),
  (("0.9", -2), "0.009"),
  (("137", 0), "137"),
  (("137", 1), "1370"),
  (("137", -1), "13.7"),
  (("137", -2), "1.37"),
  (("137", -3), "0.137"),
  (("137", -4), "0.0137"),
)

#for (input, output) in shift-decimal-position-tests {
  assert.eq(shift-decimal-position(..input), output)
}


#let convert-uncertainty-relative-to-absolute-tests = (
  (
    ((text: "27", path: (0,), absolute: false, symmetric: true), (text: "0.9", path: (0,))),
    (text: "2.7", path: (0,), absolute: true, symmetric: true),
  ),
  (
    ((text: "27", path: (2,), absolute: false, symmetric: true), (text: "0.137", path: ())),
    (text: "0.027", path: (2,), absolute: true, symmetric: true),
  ),
  (
    ((text: "27", path: (), absolute: false, symmetric: true), (text: "0.137", path: (0,))),
    (text: "0.027", path: (), absolute: true, symmetric: true),
  ),
  (
    ((text: "7", path: ()), (text: "0.137", path: (0,))),
    (text: "0.007", path: (), absolute: true),
  ),
)

#for (input, output) in convert-uncertainty-relative-to-absolute-tests {
  assert.eq(convert-uncertainty-relative-to-absolute(..input), output)
}


#let convert-uncertainty-absolute-to-relative-tests = (
  (
    ((text: "2.7", path: (0,), absolute: true, symmetric: true), (text: "0.9", path: (0,))),
    (text: "27", path: (0,), absolute: false, symmetric: true),
  ),
  (
    ((text: "0.027", path: (2,), absolute: true, symmetric: true), (text: "0.137", path: ())),
    (text: "27", path: (2,), absolute: false, symmetric: true),
  ),
  (
    ((text: "0.027", path: (), absolute: true, symmetric: true), (text: "0.137", path: (0,))),
    (text: "27", path: (), absolute: false, symmetric: true),
  ),
  (
    ((text: "0.007", path: ()), (text: "0.137", path: (0,))),
    (text: "7", path: (), absolute: false),
  ),
)

#for (input, output) in convert-uncertainty-absolute-to-relative-tests {
  assert.eq(convert-uncertainty-absolute-to-relative(..input), output)
}


#let convert-uncertainty-tests = (
  (
    ((text: "0.027", path: (), absolute: true, symmetric: true), (text: "0.137", path: ()), "plus-minus"),
    (text: "0.027", path: (), absolute: true, symmetric: true),
  ),
  (
    ((text: "0.027", path: (), absolute: true, symmetric: true), (text: "0.137", path: ()), "parentheses"),
    (text: "27", path: (), absolute: false, symmetric: true),
  ),
  (
    ((text: "0.027", path: (), absolute: true, symmetric: true), (text: "0.137", path: ()), "conserve"),
    (text: "0.027", path: (), absolute: true, symmetric: true),
  ),
  (
    ((text: "27", path: (), absolute: false, symmetric: true), (text: "0.137", path: ()), "plus-minus"),
    (text: "0.027", path: (), absolute: true, symmetric: true),
  ),
  (
    ((text: "27", path: (), absolute: false, symmetric: true), (text: "0.137", path: ()), "parentheses"),
    (text: "27", path: (), absolute: false, symmetric: true),
  ),
  (
    ((text: "27", path: (), absolute: false, symmetric: true), (text: "0.137", path: ()), "conserve"),
    (text: "27", path: (), absolute: false, symmetric: true),
  ),
)


#for (input, output) in convert-uncertainty-tests {
  assert.eq(convert-uncertainty(..input), output)
}
