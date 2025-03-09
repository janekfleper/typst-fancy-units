#set page(height: auto, width: auto, margin: 1em)

#(
  (leaves: (), value: (body: "137", layers: ())),
  (
    leaves: ((body: "(1)e5", layers: ()),),
    value: (body: "137", layers: ()),
  ),
  (
    leaves: (),
    value: (body: "−137", layers: ((strong: (:)),)),
  ),
  (
    leaves: ((body: "(1)e5", layers: ((strong: (:)),)),),
    value: (body: "−137", layers: ((strong: (:)),)),
  ),
)

#pagebreak()

#(
  (
    leaves: ((body: "137", layers: ()),),
    exponent: none,
  ),
  (
    leaves: ((body: "137(1)", layers: ()),),
    exponent: (body: "5", layers: ()),
  ),
  (
    leaves: ((body: "−137", layers: ((strong: (:)),)),),
    exponent: none,
  ),
  (
    leaves: ((body: "−137(1)", layers: ((strong: (:)),)),),
    exponent: (body: "5", layers: ((strong: (:)),)),
  ),
)

#pagebreak()

#(
  (
    leaves: (),
    value: (body: "137", layers: ()),
    exponent: none,
  ),
  (
    leaves: ((body: "(1)", layers: ()),),
    value: (body: "137", layers: ()),
    exponent: (body: "5", layers: ()),
  ),
  (
    leaves: (),
    value: (body: "−137", layers: ((strong: (:)),)),
    exponent: none,
  ),
  (
    leaves: ((body: "(1)", layers: ((strong: (:)),)),),
    value: (body: "−137", layers: ((strong: (:)),)),
    exponent: (body: "5", layers: ((strong: (:)),)),
  ),
)

#pagebreak()

#(
  (
    (
      absolute: true,
      symmetric: true,
      body: "0.9",
      path: (),
    ),
  ),
  (
    (
      absolute: false,
      symmetric: true,
      body: "137",
      path: (),
    ),
  ),
  (
    (
      absolute: false,
      symmetric: true,
      body: "137",
      path: (0, 1, 2),
    ),
  ),
  (
    (
      absolute: true,
      symmetric: false,
      positive: (body: "0.9", path: (4,)),
      negative: (body: "0.1", path: (8,)),
    ),
  ),
  (
    (
      absolute: false,
      symmetric: false,
      positive: (body: "1", path: ()),
      negative: (body: "2", path: ()),
    ),
  ),
  (
    (
      absolute: false,
      symmetric: true,
      body: "1",
      path: (),
    ),
    (
      absolute: true,
      symmetric: true,
      body: "0.2",
      path: (),
    ),
  ),
  (
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
)

#pagebreak()

#(
  (
    (
      value: (body: "0.9", path: ()),
      uncertainties: (),
      exponent: none,
    ),
    (body: "0.9", layers: ()),
  ),
  (
    (
      value: (body: "0.9", path: ()),
      uncertainties: (),
      exponent: none,
    ),
    (body: "0.9", layers: ((strong, (:)),)),
  ),
  (
    (
      value: (body: "0.9", path: ()),
      uncertainties: (
        (
          absolute: true,
          symmetric: true,
          body: "0.1",
          path: (),
        ),
      ),
      exponent: (body: "5", path: ()),
    ),
    (body: "0.9+−0.1e5", layers: ()),
  ),
  (
    (
      value: (body: "0.9", path: (0,)),
      uncertainties: (
        (
          absolute: false,
          symmetric: true,
          body: "1",
          path: (1,),
        ),
      ),
      exponent: (body: "5", path: (2,)),
    ),
    (
      children: (
        (body: "0.9", layers: ()),
        (body: "(1)", layers: ((strong, (:)),)),
        (body: "e5", layers: ()),
      ),
      layers: (),
    ),
  ),
)
