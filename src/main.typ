#import "lib.typ": *
#import "number.typ": *
#import "content.typ": *
#import "unit.typ": *
#import "units.typ": units

#set page(paper: "a4")

#fancy-units-configure((
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

// this should not result in a per-mode = "power" unit?
#let u = [1 / (a:b^2)^2]

#unit[#u] \
#unit(per-mode: "power")[#u]

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

// #parse-number("1f2 +- 2 +- 1")

// #let value-pattern = regex("(-?\d+(?:[\,.]\d+)?(?:[eE][+-]?\d+)?)")
// #let pattern = regex("^ *(-?\d+)( ?\+- ?\d)*")
// #let uncertainty-pattern = regex("(\+- ?\d)")
// #let string = " -2+-5+-2"
// #let match = string.match(value-pattern)
// // #string.matches(pattern)
// #string.matches(uncertainty-pattern)