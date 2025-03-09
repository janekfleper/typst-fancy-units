#set page(height: auto, width: auto, margin: 1em)
#import "/src/content.typ": *


#let wrap-content-tests = (
  ([], ()),
  ([kg], ()),
  ([kg], ((strong, (:)),)),
  ([kg], ((math.cancel, (:)),)),
  ([kg], ((strong, (:)), (emph, (:)))),
  ([kg], ((strong, (:)), (underline, (:)))),
  ([kg], ((strong, (:)), (underline, (:)), (strike, (:)))),
  unwrap-content([#text(red)[kg]]).values(),
)

#for (content, layers) in wrap-content-tests {
  box(
    wrap-content(content, layers),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let wrap-content-math-tests = (
  ([], (), none),
  ("0.9", (), none),
  ("0.9", (), ","),
  ([0.9], (), none),
  ([0.9], (), ","),
  ([kg], ((strong, (:)),), none),
  ([kg], ((emph, (:)),), none),
  ([kg], ((strong, (:)), (emph, (:))), none),
  (..unwrap-content([#text(red)[kg]]).values(), none),
)

// math.upright() won't have an effect on the numbers, only the units
#for (content, layers, separator) in wrap-content-math-tests {
  box(
    math.upright(
      wrap-content-math(
        content,
        layers,
        decimal-separator: separator,
      ),
    ),
    stroke: red + 0.5pt,
  )
  linebreak()
}

#pagebreak()


#let wrap-component-tests = (
  ((body: "0.9", path: ()), (body: "0.9", layers: ()), ".", false),
  ((body: "0.9", path: ()), (body: "0.9", layers: ()), ",", false),
  ((body: "137", path: ()), (body: "137", layers: ((strong, (:)),)), ".", false),
  ((body: "137", path: ()), (body: "137", layers: ((strong, (:)),)), ".", true),
  (
    (body: "137", path: (0,)),
    (
      children: (
        (body: "137", layers: ((strong, (:)),)),
        (body: "(1)", layers: ((strong, (:)),)),
        (body: "e-3", layers: ((emph, (:)),)),
      ),
      layers: (),
    ),
    ".",
    true,
  ),
)

#for (component, tree, decimal-separator, apply-parent-layers) in wrap-component-tests {
  box(
    wrap-component(
      component,
      tree,
      decimal-separator,
      apply-parent-layers: apply-parent-layers,
    ),
    stroke: red + 0.5pt,
  )
  linebreak()
}
