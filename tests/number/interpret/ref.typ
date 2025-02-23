#set page(height: auto, width: auto, margin: 1em)

#(
  (leaves: (), value: (text: "137", layers: ())),
  (
    leaves: ((text: "(1)e5", layers: ()),),
    value: (text: "137", layers: ()),
  ),
  (
    leaves: (),
    value: (text: "−137", layers: ((strong: (:)),)),
  ),
  (
    leaves: ((text: "(1)e5", layers: ((strong: (:)),)),),
    value: (text: "−137", layers: ((strong: (:)),)),
  ),
)

#pagebreak()

#(
  (
    leaves: ((text: "137", layers: ()),),
    exponent: none,
  ),
  (
    leaves: ((text: "137(1)", layers: ()),),
    exponent: (text: "5", layers: ()),
  ),
  (
    leaves: ((text: "−137", layers: ((strong: (:)),)),),
    exponent: none,
  ),
  (
    leaves: ((text: "−137(1)", layers: ((strong: (:)),)),),
    exponent: (text: "5", layers: ((strong: (:)),)),
  ),
)

#pagebreak()

#(
  (
    leaves: (),
    value: (text: "137", layers: ()),
    exponent: none,
  ),
  (
    leaves: ((text: "(1)", layers: ()),),
    value: (text: "137", layers: ()),
    exponent: (text: "5", layers: ()),
  ),
  (
    leaves: (),
    value: (text: "−137", layers: ((strong: (:)),)),
    exponent: none,
  ),
  (
    leaves: ((text: "(1)", layers: ((strong: (:)),)),),
    value: (text: "−137", layers: ((strong: (:)),)),
    exponent: (text: "5", layers: ((strong: (:)),)),
  ),
)

#pagebreak()

#(
  (
    (
      absolute: true,
      symmetric: true,
      text: "0.9",
      path: (),
    ),
  ),
  (
    (
      absolute: false,
      symmetric: true,
      text: "137",
      path: (),
    ),
  ),
  (
    (
      absolute: false,
      symmetric: true,
      text: "137",
      path: (0, 1, 2),
    ),
  ),
  (
    (
      absolute: true,
      symmetric: false,
      positive: (text: "0.9", path: (4,)),
      negative: (text: "0.1", path: (8,)),
    ),
  ),
  (
    (
      absolute: false,
      symmetric: false,
      positive: (text: "1", path: ()),
      negative: (text: "2", path: ()),
    ),
  ),
  (
    (
      absolute: false,
      symmetric: true,
      text: "1",
      path: (),
    ),
    (
      absolute: true,
      symmetric: true,
      text: "0.2",
      path: (),
    ),
  ),
  (
    (
      absolute: false,
      symmetric: true,
      text: "1",
      path: (),
    ),
    (
      absolute: false,
      symmetric: true,
      text: "2",
      path: (),
    ),
  ),
)

#pagebreak()

#(
  (
    (
      value: (text: "0.9", path: ()),
      uncertainties: (),
      exponent: none,
    ),
    (text: "0.9", layers: ()),
  ),
  (
    (
      value: (text: "0.9", path: ()),
      uncertainties: (),
      exponent: none,
    ),
    (text: "0.9", layers: ((strong, (:)),)),
  ),
  (
    (
      value: (text: "0.9", path: ()),
      uncertainties: (
        (
          absolute: true,
          symmetric: true,
          text: "0.1",
          path: (),
        ),
      ),
      exponent: (text: "5", path: ()),
    ),
    (text: "0.9+−0.1e5", layers: ()),
  ),
  (
    (
      value: (text: "0.9", path: (0,)),
      uncertainties: (
        (
          absolute: false,
          symmetric: true,
          text: "1",
          path: (1,),
        ),
      ),
      exponent: (text: "5", path: (2,)),
    ),
    (
      children: (
        (text: "0.9", layers: ()),
        (text: "(1)", layers: ((strong, (:)),)),
        (text: "e5", layers: ()),
      ),
      layers: (),
    ),
  ),
)
