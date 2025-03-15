#set page(height: auto, width: auto, margin: 1em)
#import "/src/unit/format.typ": *


#let unit-bracket-tests = (
  (c: $a$, type: 0),
  (c: $a$, type: 1),
  (c: $a$, type: 2),
  (c: $a^2$, type: 0),
  (c: $a^2$, type: 1),
  (c: $a^2$, type: 2),
)

#for test in unit-bracket-tests {
  box(
    unit-bracket(test.c, test.type),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let apply-brackets-tests = (
  (unit: $a^2$, brackets: (0,)),
  (unit: $a^2$, brackets: (1,)),
  (unit: $a^2$, brackets: (2,)),
  (unit: $a^2$, brackets: (0, 0)),
)

#for test in apply-brackets-tests {
  box(
    apply-brackets(test.unit, test.brackets),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let join-units-tests = (
  (c: ($a$, $b$), group: true, separator: h(0.2em)),
  (c: ($a$, $b$), group: false, separator: h(0.2em)),
  (c: ($a$, $b$), group: false, separator: sym.dot.op),
)

#for test in join-units-tests {
  box(
    join-units(test.c, test.group, test.separator),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let unit-attach-tests = (
  (args: (tr: (body: "2", layers: ()), br: none)),
  (args: (tr: (body: "n", layers: ()), br: none)),
  (args: (tr: (body: "0.5", layers: ()), br: none)),
  (args: (tr: (body: "0.5", layers: ()), br: none)),
  (args: (tr: (body: "−2", layers: ()), br: (body: "q", layers: ()))),
  (args: (tr: (body: "−2", layers: ()), br: (body: "q", layers: ((emph, (:)),)))),
).map(case => (unit: $a$, decimal-separator: ".", args: case.args))

#for test in unit-attach-tests {
  box(
    unit-attach(test.unit, test.decimal-separator, ..test.args),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let format-unit-body-tests = (
  (
    child: (body: "a", layers: (), exponent: (body: "2", layers: ())),
    decimal-separator: ".",
  ),
  (
    child: (body: "a", layers: ((emph, (:)),), exponent: (body: "−2", layers: ())),
    decimal-separator: ".",
  ),
  (
    child: (body: "a", layers: ((strong, (:)),), exponent: (body: "−0.5", layers: ())),
    decimal-separator: ",",
  ),
)

#for test in format-unit-body-tests {
  box(
    format-unit-body(test.child, test.decimal-separator),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let format-unit-tests = (
  (
    children: (math.upright[$a$], math.upright[$b$]),
    tree: (
      children: ((body: "a", layers: ()), (body: "b", layers: ())),
      layers: (),
      brackets: (0, 0),
      exponent: (body: "2", layers: ()),
      group: false,
    ),
    separator: h(0.2em),
    decimal-separator: ".",
  ),
  (
    children: (math.upright[$a$], math.upright[$b$]),
    tree: (
      children: ((body: "a", layers: ()), (body: "b", layers: ())),
      layers: (),
      brackets: (2, 0),
      exponent: (body: "2", layers: ()),
      group: false,
    ),
    separator: sym.dot.op,
    decimal-separator: ".",
  ),
  (
    children: (math.upright[$a$], math.upright[$b$]),
    tree: (
      children: ((body: "a", layers: ()), (body: "b", layers: ())),
      layers: (),
      exponent: (body: "0.5", layers: ()),
      group: true,
    ),
    separator: sym.dot.op,
    decimal-separator: ".",
  ),
)

#for test in format-unit-tests {
  box(
    format-unit(test.children, test.tree, test.separator, test.decimal-separator),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let format-unit-per-mode-tests = (
  (
    tree: (
      body: "a",
      layers: (),
      exponent: (body: "−2", layers: ()),
    ),
    separator: sym.space.thin,
    decimal-separator: ".",
  ),
  (
    tree: (
      children: (
        (body: "a", layers: ()),
        (body: "b", layers: (), exponent: (body: "−1", layers: ())),
      ),
      layers: (),
      group: false,
    ),
    separator: sym.space.thin,
    decimal-separator: ".",
  ),
  (
    tree: (
      children: (
        (
          body: "b",
          layers: (),
          exponent: (body: "−2", layers: ()),
        ),
      ),
      layers: (),
      brackets: (0,),
      group: false,
      exponent: (body: "−1", layers: ()),
    ),
    separator: sym.space.thin,
    decimal-separator: ".",
  ),
)

#for test in format-unit-per-mode-tests {
  box(
    format-unit-power(test.tree, separator: test.separator, decimal-separator: test.decimal-separator),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#for test in format-unit-per-mode-tests {
  box(
    format-unit-fraction(test.tree, separator: test.separator, decimal-separator: test.decimal-separator),
    stroke: red + 0.5pt,
  )
  h(0.5em)
  box(
    math.equation(
      block: true,
      format-unit-fraction(test.tree, separator: test.separator, decimal-separator: test.decimal-separator),
    ),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#for test in format-unit-per-mode-tests {
  box(
    format-unit-symbol(test.tree, separator: test.separator, decimal-separator: test.decimal-separator),
    stroke: red + 0.5pt,
  )
  linebreak()
}
