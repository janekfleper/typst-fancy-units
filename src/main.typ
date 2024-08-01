#import "lib.typ": *
#import "number.typ": *
#import "content.typ": *
#import "unit.typ": *
#import "units.typ": units

#set page(paper: "a4")

#siunity-configure(
  units: units,
  uncertainty-format: "()",
)

// per-mode: "power", "fraction", [content]
#let state-config = state("fancy-units-config", (
  "uncertainty-format": "plus-minus",
  "decimal-character": ".",
  "unit-spacing": "0.1",
  "unit-separator": sym.dot,
  "per-mode": "power",
))
#let state-units = state("fancy-units", (:))

#let math-minus = "−"
#let text-minus = "-"

#let parse-input(content) = {
  if content.has("text") { return content.text }

  let children = ()
  for child in content.children {
    if child.has("text") {
      children.push(child.text)
    }
  }
  return children//.join(" ")
}

#let numbers = (
  [0.9],
  [-0.9],
  [+0.9],
  [0.9+-0.1],
  [0.9 +-0.1],
  [0.9+- 0.1],
  [0.9 +- 0.1],
  [0.9(1)],
  [0.9 (1)],
)

#let pattern-unit = regex("([^\(\)\s\d\^]+)(?:\^(\d+))?")

#let find-units(leaves) = {
  let units = ()
  for (text, path) in leaves {
    for match in text.matches(pattern-unit) {
      // the exponent will automatically default to none if it was not captured
      units.push((unit: match.captures.at(0), exponent: match.captures.at(1), path: path))
    }
  }
  units
}

#let parentheses(c, format: "math") = {
  if format == "math" [#math.lr([(#c)])] else [(#c)]
}

// #let pattern-open = regex("[\(\[\{<]")
// #let pattern-close = regex("[\)\]\}>]")
#let pattern-open = regex("(\()|(\[)|(\{)|(<)")
#let pattern-close = regex("(\))|(\])|(\})|(>)")
#let pattern-bracket = regex("(\()|(\[)|(\{)|(<)|(\))|(\])|(\})|(>)")

// Include the actual bracket in the error message
// 
// - leaves (array): Leaves from the content tree
// - type (int): Bracket type (0 - 5)
// -> (str): Error message
#let unmatched-bracket-message(leaves, type) = {
  "Unmatched bracket "
  brackets.at(type)
  " in '"
  leaves.map(leaf => leaf.text).join()
  "'"
}



// $#math.italic[E]#sub[rec]$
$#math.attach([E], br: [rec], tr: [2])$


// #let u = [μg^ s m / s^2]
#let u = [_*(kg m^ / s)*_ {_E_}#sub[rec]]
// #let u = [(((a b c) *d   e)  f*)]
#let u = [abc ((*(a b c)* d  e){}  f)    defasdf]
#let u = [abc((*(a b c)* d a) () {f})]
// #let u = [*kg* (μm^2)]
// #let u = [(μm / *s*)^2 abc]
// #let u = [kg /m^3 s^2]
// #let u = [kg/ *micro*:m^2]///(s/kg)^3]
#let u = [(kg^-2 / (μm / Joule))^2]
#let u = [kg / (μm / Joule)]
#let u = [_E^2_#sub[rec]]

// bug with parentheses detection...
#let u = [[((a:_u_:g^2 m))]^-1 cm^3 / abc^-3]
#let u = [(({a:_u_:g^2 m}))^-1 cm^3 / (abc^-3)]
#let u = [(({a:b^2 m}))^-1 cm^3 / (abc^-3)]
#let u = [kg / ((((abc^-6) kg m s^2))^12)]
// #let u = [kg / (kg:s:m^2 m^3 s^2)]
#let u = [kg / (s^-2)]
// #let u = [kg / ((abc^-3) m s) ^2]
// #let u = [kg / abc^3]
// #let u = [kg abc^3]

// per-mode = "fraction", the exponent two should be applied to the children?
// #let u = [kg / a:b:c (((ab^-3) kg m))^2]

// per-mode = "fraction", there is no fraction 1/ab^6
// #let u = [kg / a:b:c (ab^-3 kg m)^2]

// per-mode = "fraction", the denominator turns into a really weird stack of fractions...
// #let u = [kg / (((ab^-3) kg m)^-2)]

// this should raise an error due to an invalid exponent...
// #let u = [abcd^-1/0]

// this should raise an error due to an invalid exponent...
// #let u = [abcd^-0,9]

// how should the exponent zero be handled?
// #let u = [a^0]

// should this raise an error or be accepted as an exponent?
// #let u = [a^n]

// this should raise an error due to an invalid exponent...
#let u = [1 / a:m^-1/2]

$1 / ((1 / x))$

#let u1 = [(a b^-3 c^2)^-2 (a^-1) (((b))^-2)]
#let u1 = [(a b^-2)^-2]
// #let u1 = [1 / 2 / 3 / 4 / 5^-1]
// #let u1 = [c / ( x^-1)]
// #let u1 = [c / 1 / x]
// #let u1 = [kg / (((ab^-3) kg m)^-2)]
// #let u1 = [((a b c))^1]
// #let u1 = [(b a) / (ab)^2 / c]
// #let u1 = [a / b / c / d /e f g/(h/i)]
// #let u1 = [a c / b]
// #let u1 = [a / (a b)^2]
// #let u1 = [1 / ((a b))^2]
#let u2 = [1 / (a b)^2]
#let u3 = [1 / ((a b))]
#let u4 = [1 / ((a b))^2]
#let u5 = [1 / ((a b)^2)]
#let uc = [c / (a b)]
// #let u = [c / (a b)]

// the exponent one shouldn't be there...
// #let u = [kg m / s^-1]

// #let u = [1 / (abc^-2)^2]
// #let u = [(abc^-2)^2]


// #let u = [kg / (d abc^3)]
// #let u1 = [(cm a^2)^-3 cm^3 / ((abc^-3))]
// #let u = [a:#text(red)[b]:c^2 def kg]
// #let u = [a:b:c f]
// #let u = [/kg]
// #let u = [(kg *m*)*^-1*]
// #let u = [_kg_ m#sub[abc]^2]
// #let u = [*a#sub[abc]*^2]
// #let u = [abc(((a b c)  d e)a f)]
// #let u = [abc(((*a b c*) d e)a f)]

// #let bare-tree = unwrap-content(u)
// // wrap the "text" child to use the functions find-brackets() and group-brackets-children()
// #if bare-tree.keys().contains("text") { bare-tree = (children: (bare-tree,), layers: ()) }
// #let pairs = find-brackets(bare-tree)
// #let brackets-children = group-brackets-children(bare-tree.children, pairs)
// #let tree = find-exponents((
//   children: brackets-children,
//   layers: bare-tree.layers,
//   group: false, // make sure that the topmost level also has the 'group' field
// ))
// #let leaves = find-leaves(tree)

// #tree \

// Calling `format-unit()` here is not possible since the function
// is only defined after this function. This function will therefore
// only take care of the preparation to use a fraction in the unit.
#let prepare-frac(child) = {
  child.exponent.text = child.exponent.text.trim("−")
  if child.exponent.text == "1" { _ = child.remove("exponent") }
  // if c.len() == 0 { c.push([1]) }
  child
}

#let format-unit(tree, ..args) = {
  if "text" in tree.keys() { return format-unit-text(tree) }
  let exponent = tree.at("exponent", default: none)
  let brackets = tree.at("brackets", default: none)

  let per-mode-power = args.named().per-mode == "power" and brackets == (0,)
  // apply the exponent to all children, and set it to none afterward...
  // if exponent != none and (brackets == none or per-mode-power) and not tree.group {

  let inherit-exponent = if args.named().per-mode == "fraction" {
    brackets == none and not tree.group
  } else {
    (brackets == none or brackets == (0,)) and not tree.group
  }

  // always apply an exponent if there is only one pair of parentheses...
  // if exponent != none and (brackets == none or brackets == (0,)) and not tree.group {
  if exponent != none and inherit-exponent {
    tree.children = tree.children.map(child => apply-exponent(child, exponent))
    exponent = none
  }

  let c = ()
  for child in tree.children {
    // the per-mode only needs to be considered for a negative exponent
    let negative-exponent = child.keys().contains("exponent") and child.exponent.text.starts-with("−")
    // a single child in brackets is protected from being turned into a fraction
    let protective-brackets = brackets != none and tree.children.len() == 1
    // invert the exponent of the child if it is used in a fraction or with a content per-mode
    if negative-exponent and args.named().per-mode != "power" and not protective-brackets { child = prepare-frac(child) }
    let unit = format-unit(child, ..args)

    if args.named().per-mode == "power" or not negative-exponent or protective-brackets {
      c.push(unit)
    } else {
      // use the content [1] if `c` is empty so far...
      let previous = if c.len() > 0 { c.pop() } else { [1] }
      // why is the flag `protective-brackets` checked here again?
      if args.named().per-mode == "fraction" and not protective-brackets {
        c.push(math.frac(previous, unit))
      } else if type(args.named().per-mode) == content {
        // wrap multiple units in brackets for the custom per-mode...
        if child.keys().contains("children") and child.children.len() > 1 { unit = unit-bracket(unit, 0) }
        c.push((previous, args.named().per-mode, unit).join())
      } else {
        panic("The per-mode must be 'fraction', 'power' or content")
      }
    }
  }

  // the content in `c` is joined by the unit-separator if it is not a group
  let join-symbol = if tree.group { [] } else { args.named().unit-separator }
  let unit = c.join(join-symbol)
  if brackets != none {
    // only discard the first layer of parentheses if there is no exponent to be added in the next step...
    if brackets.at(-1) == 0 and (exponent == none or brackets.len() > 1) { _ = brackets.pop() }
    for bracket in brackets { unit = unit-bracket(unit, bracket) }
  }

  if exponent != none {
    if args.named().per-mode == "fraction" {
      let previous = if unit == [] { [1] } else { unit }
      
      
    }
    
  }
  if exponent != none and (tree.group or brackets.len() > 0) { unit = unit-attach(unit, tr: exponent) }

  // don't forget to apply the layers to non-text children...
  wrap-content-math(unit, tree.layers)
}

// simplify this???
#let format-unit-fraction-text(tree) = {
  let negative-exponent = tree.keys().contains("exponent") and tree.exponent.text.starts-with("−")
  if negative-exponent {
    math.frac([1], format-unit-text(prepare-frac(tree)))
  } else {
    format-unit-text(tree)
  }
}


$1^(-3)$  $1^(-6)$ #linebreak()
$1 / ([a + b])$
$1 / ((1 + 2))$
// #let m = $1 / x$
// #m.body.func()

#math.attach("abc", tr: [-4])
#"−".starts-with("-")
#unit-attach([abc], tr: (text: math-minus + "4", layers: ()))

$a^(-1)$

#let c = unit(per-mode: "power")[#u1]
$#c$

Why is the 1 formatted differently in the two cases? \
$1 / (a b)^1$ $1 / (a b)^10$ \

#let f = math.frac([1], [2])
#{f.func() == math.frac} \

#let x1 = [ab]
#let x2 = ([a], [b]).join([])

$1 / (#math.italic([a]) #math.italic([b]))$
$1 / (#math.italic([ab]))$
$1 / (#math.bold([a]) #math.bold([b]))$
$1 / (#math.bold($#math.bold($a b$)$))$
$1 / a$ \

#let c1 = $#math.upright([$1 / (x b c)^A$])$
#let c2 = $1 / (#math.upright([x]) #math.upright([b]) #math.upright([c]))^A$
#let c3 = $1 / (#math.upright([xbc]))^A$
#c1
#c2
#c3

// $#math.bold([$1^2$])$

// #"km/μm^2/s".position(regex("\/[\D]")) \
// #"km/cm^1/2".split("/") \







// #group-brackets(tree)

// #let n = [ ( 0.9 +- 0.1 )  ]
// #let n = [ *0,9* ( 12 ) e5 ]
// #let tree = unwrap-content(n)
// // remove leaves with empty text...
// #let leaves = find-leaves(tree)//.filter(leaf => leaf.text != " ")
// #let number = leaves.map(leaf => leaf.text).join().trim(" ") // remove the outside-facing spaces
// // #interpret-number(number) \
// #let components = leaves.filter(leaf => leaf.text != " ")
// #let res = interpret-number-content(n)
// #let (number, tree) = res
// #number \
// #tree \

// $#output-number(number, tree)$

// Get the text and all (styling) functions from a content object
//
// - c (content)
// -> dictionary
//    - text (str): Actual text in the content object
//    - layers (array): Functions and fields that style the `text`
#let unwrap-text(c) = {
  let layers = ()
  while not c.has("text") {
    let func = c.func() // get the func() before stepping into the next layer...
    let fields = c.fields()
    if c.has("body") { c = fields.remove("body") }
    else if c.has("child") { c = fields.remove("child") }
    layers.push((func, fields))
  }
  (text: c.text, layers: layers.rev()) // should this really be reversed here?
}

// Wrap a string in layers of (styling) functions to get a content object
//
// - s (str): String to use in the content object
// - layers (array): Functions and fields to style `s`
// -> content
#let wrap-text(s, layers) = {
  let c = [#s]
  for (func, fields) in layers {
    if "styles" in fields.keys() { c = func(c, fields.styles) } // the "styles" are a positional argument...
    else { c = func(c, ..fields) } // this also works for "strong", "emph" etc. since "fields" will be empty
  }
  c
}

#let get-text(c) = {
  unwrap-text(c).at("text")
}

#let set-text(c, s) = {
  wrap-text(s, unwrap-text(c).at("layers"))
}

#let n = [#highlight(extent: 10pt)[abc]]
// #get-text(n)
#let n = [#text(fill: red)[*_abc_*]]
#let n = [abc]
#let layers = unwrap-text(n)
// #let (func, fields) = layers.at(0)
// #func()
// #func([abc], ..fields)
// #set-text(n, "1(2)")
// #n.fields()

#let n = [#text(red)[abc]]
// #n.fields()

#let n = [#text(baseline: -5pt, fill: blue, weight: 900)[_*1(2)*_]]
#let c = [1(2)]
#let nn = [#text(red)[12]]
#let layers = unwrap-text(n)
// #let (func, styles) = layers.at(0)
#let func = n.func()
#let styles = n.styles
// #func([abc], styles) abc


// #func([abc], styles.at("styles"))

// #text(green, 18pt)[abc]


// #n #funcs.at(0)
// #let (f, ..args) = funcs.at(0)
// #f([abc], ..args)
// #type(get-text(n))

// #for i in range(5) [
//   #linebreak()
// ]
// #let (f, styles) = funcs.at(0)
// #f([abc], styles)


// #let styled = nn.func()
// #styled([abc], nn.styles)
// #type(nn.styles)
// [#nn.styles [abc]]
// #nn.styles


// #let styles = n.styles
// #n.func()
// #styles
// #style(n.styles)
// #set-text(n, "a") \
// #{
//   n.body.func() == text
// }
// #set-text(n, "abc")

#let number(number) = {
  if number.has("text") {
    return interpret-number(number.text)
  }
}

// #let n = [_*1(2)*_]
// #n.
// #type([1(2)])
// #number[*1(2)*]
// // #[1 (2)e5].children


// // #$#([1(*2*)],).join()$ \
// // #$#([1(2)],).join()$ \
// // #$#([1(#math.bold([2]))],).join()$

// #unit[ab  abd^2  easdfasdf]

// #unit[abc / def^1] \
// abc

// #let cc = ([a], [b], [c])
// $#cc.join()$




// #num[0.9+-2]
// #let Erec = [E#sub[rec]]
// #let fm = "abc"

// // #parse_input[1    µ]
// // #num[1µ]

// #let Erec(n: none) = [
//   E#sub[rec]
//   #if n != none [
//     #h(-0.7em)^(#n)
//   ]
// ]

// $#Erec(n: 1)$

// $#math.italic[E]^22$

// $#math.upright[#math.italic[E]#sub[rec]]#h(-0.7em)^(2)$

// $#math.upright[#math.italic[E]]^22#sub[rec]$
// $#math.upright[mm]^2$
// $#math.upright[#sym.mu f]$
// $μ #sym.mu$
// μ#sym.mu
// $#math.upright[a]#sub[rec]$

// $a#sub(typographic: false)[2]#super(typographic: false)[2]$
// $E#super[2] E^2$
// $E#sub[2] E_2$
// $1^(-1)_(-1)$

// $ #math.scripts[1]_1^1 $
// $ 1_1^1 $
// 1#sub[1]#super[1] $1#sub[1]#super[1]$

// $5℃$

// // #unit[#Erec] \
// #unit[Erec] \
// $#unit[um]$ \
// #unit[um] \
// $#math.upright(sym.mu)$
// $#math.upright([#sym.mu m])$
// $#math.upright([#math.italic[E]#sub[rec]])$
// $#math.upright(sym.planck.reduce)$
// #math.upright(sym.rect)
// $#math.upright[abc]$

// $1fm$
// $upright(mu)$
// $µ$
 
// #num(display-uncertainty: "plus.minus")[1+-2]
// #parse_input[1+-2 mu].join(" ").split("+-")
// #num[1+-2  mu]
// $mu$
// #num(display-uncertainty: "plus.minus")[1d-10 +- 1e cm^2 bd^-10 per cd]
// #num(display_uncertainty: "abc")[1+-1]




// #for i in range(-3, 4) [ shift #i: #shift-decimal-position("10", i) \ ]
// #for i in range(-3, 4) [ shift #i: #shift-decimal-position("0.9", i) \ ]

// #n2.match(pattern-number-format)

// #unc
// #calc.div-euclid(0.001, 0.002)

// #"(1+-2)".match(pattern-number-mode)
// #let n1 = "(1+-2)e5"
// #let match = match-exponent(n1)
// #match
// #match.s.match(pattern-number-mode)
// #"(1+-2)e5".match(pattern-exponent)
// #"(1+-2)*10^5".match(pattern-exponent)
// #"10(2)*10^5".match(pattern-exponent)
// #"(1+-2)".match(pattern-number-mode)

// #parse-number("1f2 +- 2 +- 1")

// #let value-pattern = regex("(-?\d+(?:[\,.]\d+)?(?:[eE][+-]?\d+)?)")
// #let pattern = regex("^ *(-?\d+)( ?\+- ?\d)*")
// #let uncertainty-pattern = regex("(\+- ?\d)")
// #let string = " -2+-5+-2"
// #let match = string.match(value-pattern)
// // #string.matches(pattern)
// #string.matches(uncertainty-pattern)

// $1#super[def]#h(-0.3cm)#sub[abc]$