#import "lib.typ": *
#import "number.typ": *
#import "content.typ": *
#import "unit.typ": *
#import "units.typ": units

#set page(paper: "a4")

#fancy-units-configure((
  uncertainty-format: "plus-minus",
  per-mode: "fraction",
  unit-separator: sym.dot
))

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

#let u = [μg^1 s m / s^2]

#unit[#u] \
#unit(per-mode: "power")[#u]

#let n1 = [0.5(*1*)e5]
#let n1 = [*0.5*(1)(3)*e5*]
#let n1 = [#text(red)[0.5] (10)(30:20) +- 0.02 *e5*]
#let n1 = [#text(red)[*12.0*] (1:20) +0.00 -0.01 e1]
#let n1 = [#text(green)[0.12] +-0.01(2)e2]
// #let n1 = [12.12 +- 0.99e1]
// #let n1 = [0.5(1)e51]
// #let n1 = [*0.5*(1) e51]
// #let n1 = [0.9#text(red)[e5]]
// #let n1 = [(0.9 +- 0.1   ) *e-1*]
// #let n1 = [(0.9 +- 0.1)e-1]
// #let n1 = [0.9(1:2)e1]
// #let n1 = [0.9(12)]
// #let n1 = [0.91]
// #let n1 = [(0.9 +- 0.1)]
// #let n1 = [0.9e1]
// #let n1 = [(-1 +- 0.1)e-5]
// #let n1 = [1.11 (1:9) +0.12 -0.12 +0.42 -0.91 +-0.1 (2)]
#let (number, tree) = interpret-number(n1)
#number \
#tree \

#let args = (
  uncertainty-format: "plus-minus",
  // uncertainty-format: "parentheses",
  // uncertainty-format: "conserve",
)
$#format-number(number, tree, ..args)$ \
#num(uncertainty-format: "conserve")[#n1]

Why is the 1 formatted differently in the two cases? \
$1 / (a b)^1$ $1 / (a b)^10$ \

// #for i in range(-3, 4) [ shift #i: #shift-decimal-position("10", i) \ ]
// #for i in range(-3, 4) [ shift #i: #shift-decimal-position("0.9", i) \ ]

// #"(1+-2)".match(pattern-number-mode)
// #let n1 = "(1+-2)e5"
// #let match = match-exponent(n1)
// #match
// #match.s.match(pattern-number-mode)
// #"(1+-2)e5".match(pattern-exponent)
// #"(1+-2)*10^5".match(pattern-exponent)
// #"10(2)*10^5".match(pattern-exponent)
// #"(1+-2)".match(pattern-number-mode)

// #let value-pattern = regex("(-?\d+(?:[\,.]\d+)?(?:[eE][+-]?\d+)?)")
// #let pattern = regex("^ *(-?\d+)( ?\+- ?\d)*")
// #let uncertainty-pattern = regex("(\+- ?\d)")
// #let string = " -2+-5+-2"
// #let match = string.match(value-pattern)
// // #string.matches(pattern)
// #string.matches(uncertainty-pattern)