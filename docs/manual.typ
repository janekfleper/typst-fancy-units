#import "/src/lib.typ": *
#import "./my-tidy.typ"

#set page(numbering: "1")
#set par(justify: true)
#set heading(numbering: "1.1")

#set raw(lang: "typc")
#set table(stroke: none)
#show link: set text(blue)

#align(center)[
  #text(18pt)[`fancy-units`]

  https://github.com/janekfleper/typst-fancy-units \
  Version 0.2.0 \
  Requires Typst 0.14+
]



= Introduction <introduction>

Since a comparison to the LaTeX package #link("https://ctan.org/pkg/siunitx?lang=de")[siunitx] is inevitable for a units package, I will get this out of the way immediately.
I used the same names for the functions ```typc num()```, ```typc unit()```, ```typc qty()``` etc. and tried to use same (or at least similar) names for the options.
However, this package is not supposed to be a port of siunitx.
There is already a Typst package available that aims to replace siunitx, namely #link("https://typst.app/universe/package/unify/")[unify].
Additionally, the package #link("https://typst.app/universe/package/zero")[zero] offers formatting of numbers with fine-grained control and alignment in tables, and formatting of units and quantities using a declarative approach.

My goal was to create a package to format numbers and units that makes use of the Typst language and the built-in styling as much as possible.
This package therefore does not have to be nearly as complex as siunitx to get started.
However, I am definitely planning to implement more features over time.

For the impatient reader I will already show a few examples.
Please refer to the later sections for the parameters of the functions and more examples to showcase all the available options.

#my-tidy.show-example-table(
  scope: (num: num, unit: unit, qty: qty),
  "num[0.9]",
  "num[-0.9 (*1*)]",
  "num[0.9 +-#text(red)[0.1] e1]",
  "unit[kg m^2 / s]",
  "unit[#math.cancel[μg]]",
  "unit[_E_#sub[rec]]",
  "qty[0.9][g]",
  "qty[27][_E_#sub[rec]]",
)

The input for numbers and units is just regular Typst content in markup mode that can be styled with the functions that are already available in Typst.
Writing the units does not require any variables or macros#footnote[
  Macros are available (see #text(red)[ref section]) and should be used for composite units or to apply styling to a specific unit.
] for the prefixes and base units.
The parser strips off the styling and stores the functions together with the number and unit content.
During the processing the numbers and units are converted to your desired output format, and the styling is applied again when the content is actually formatted.

In @styling I will go into the details of the styling and explain some of the known limitations.
I will give a summary of the available configuration options in @configuration.
The functions ```typc num()```, ```typc unit()``` and ```typc qty()``` are then shown in @numbers, @units and @quantities respectively with many examples to highlight the capabilities of the package.

If you have found a bug or if you have any suggestions how I could improve the package, please feel free to open an issue or a pull request on #link("https://github.com/janekfleper/typst-fancy-units").
I am also active on the Typst forum if you want to reach out to me #link("https://forum.typst.app/u/janekfleper").



#pagebreak()

= Styling <styling>

This package allows you to wrap parts of the numbers and units into styling functions.
During the parsing#footnote[
  The parsing follows strict rules and does not allow any configuration.
  However, you can pass a dictionary instead of a content body to skip the built-in parsing.
  The details are explained in #text(red)[add references...]
] the content is unwrapped until there is only the actual text left.
The styling functions are saved in a stack alongside the text in a so-called content tree.
If necessary, the text is then modified according to the format options.
During the formatting the styling functions are applied to the text again to get the desired output.
You can customize any part of the formatting pipeline.

Since the body has to follow the syntax rules of markup content, there are cases where spaces are either prohibited or required.
There is no way to ignore a syntax error, the content must always be valid before it can be parsed.
For negative values, there must not be a space between the hyphen `"-"` and the value to prevent an interpretation as a bullet list.
If you are calling a function in the content of a number or a unit, make sure to put a space in front of succeeding parentheses (or brackets) that are not part of the function.
For numbers this is only relevant when you are using relative uncertainties.
With units this can be an issue whenever you are grouping units with parentheses (or brackets).

== Supported functions <styling-supported-functions>

This table gives you an overview of the styling functions that are currently supported for numbers and units.
The support for quantities is equivalent to `num[]` and `unit[]` for the respective parts.
Which styling functions are actually useful is for you to decide.

#let cell-no-effect = table.cell(colspan: 1, fill: yellow.lighten(60%))[]
#let cell-not-supported = table.cell(colspan: 1, fill: red.lighten(60%))[]
#let cell-supported = it => table.cell(align: center, fill: green.lighten(83%))[#it]
#let styling-note = it => text(size: 11pt)[#it]

#table(
  columns: (2fr, 1fr, 1fr, 5fr),
  inset: 4pt,
  gutter: 2pt,
  align: left,

  table.header([function], table.cell(align: center)[`num[]`], table.cell(align: center)[`unit[]`], [Notes]),
  table.hline(y: 0, stroke: 1pt + gray, position: bottom),
  table.vline(x: 0, stroke: 1pt + gray, position: end),

  ```typ *bold*```,
  cell-supported(num[*0.9*]),
  cell-supported(unit[*kg*]),
  [],

  ```typ _emph_```,
  cell-supported(num[_0.9_]),
  cell-supported(unit[_kg_]),
  styling-note[Support for `num[]` depends on the font],

  `text(..)[]`,
  cell-supported(num[#text(red)[0.9]]),
  cell-supported(unit[#text(red)[kg]]),
  [],

  `overline[]`,
  cell-not-supported,
  cell-supported(unit[#overline[kg]]),
  [],

  `underline[]`,
  cell-not-supported,
  cell-supported(unit[#underline[kg]]),
  [],

  `strike[]`,
  cell-not-supported,
  cell-supported(unit[#strike[kg]]),
  [],

  `sub[]`,
  cell-not-supported,
  cell-supported(unit[kg#sub[abc]]),
  styling-note[The subscript is passed to `attach(br: )`],

  `super[]`,
  cell-not-supported,
  cell-supported(unit[#super[kg]]),
  styling-note[The superscript is treated like a separate unit],

  `math.cancel[]`,
  cell-supported(num[#math.cancel[0.9]]),
  cell-supported(unit[#math.cancel[kg]]),
  [],

  `math.display[]`,
  cell-no-effect,
  cell-supported(unit[#math.display[kg^2]]),
  styling-note[The parameter `cramped` has no effect],

  `math.inline[]`,
  cell-no-effect,
  cell-supported(unit[#math.inline[kg^2]]),
  styling-note[Equivalent to the function `math.display[]`],

  `math.script[]`,
  cell-supported(num[#math.script[0.9]]),
  cell-supported(unit[#math.script[kg^2]]),
  [],

  `math.sscript[]`,
  cell-supported(num[#math.sscript[0.9]]),
  cell-supported(unit[#math.sscript[kg^2]]),
  [],

  `math.bold[]`,
  cell-supported(num[#math.bold[0.9]]),
  cell-supported(unit[#math.bold[kg]]),
  styling-note[Equivalent to the function ```typ *bold*```],

  `math.italic[]`,
  cell-supported(num[#math.italic[0.9]]),
  cell-supported(unit[#math.italic[kg]]),
  styling-note[Equivalent to the function ```typ _emph_```],

  `math.sans[]`,
  cell-supported(num[#math.sans[0.9]]),
  cell-supported(unit[#math.sans[kg]]),
  styling-note[Support for `num[]` depends on the font],

  `math.frak[]`,
  cell-supported(num[#math.frak[0.9]]),
  cell-supported(unit[#math.frak[kg]]),
  styling-note[Support for `num[]` depends on the font],

  `math.mono[]`,
  cell-supported(num[#math.mono[0.9]]),
  cell-supported(unit[#math.mono[kg]]),
  styling-note[Support for `num[]` depends on the font],

  `math.bb[]`,
  cell-supported(num[#math.bb[0.9]]),
  cell-supported(unit[#math.bb[kg]]),
  styling-note[Support for `num[]` depends on the font],

  `math.cal[]`,
  cell-supported(num[#math.cal[0.9]]),
  cell-supported(unit[#math.cal[kg]]),
  styling-note[Support for `num[]` depends on the font],

  `math.overline[]`,
  cell-supported(num[#math.overline[0.9]]),
  cell-supported(unit[#math.overline[kg]]),
  styling-note[Different spacing than the regular `overline[]`],

  `math.underline[]`,
  cell-supported(num[#math.underline[0.9]]),
  cell-supported(unit[#math.underline[kg]]),
  styling-note[Different spacing than the regular `underline[]`],
)


= Configuration <configuration>

The settings to configure the transformations and formatting of the numbers and units are kept in a state and to be used as the default.
The (global) configuration should be done at the beginning of the document to set up the state for the entire document.
The transformation and formatting can always be changed for individual numbers and units by using the respective function arguments that will take precedence over the state.
Reading the configuration always requires context to access the state.

#let func-configure = (
  name: "configure",
  description: "Configure the transforming and formatting of numbers and units\n\n",
  args: (
    decimal-separator: (
      description: [
        The symbol to separate the integer part from the decimal part.

        This only affects the output. The input must always use the decimal point `"."` as separator.

        If the separator is set to `auto`, the appropriate symbol based on the text language is used#footnote[
          According to #link("https://en.wikipedia.org/wiki/Decimal_separator#Conventions_worldwide")
        ].
      ],
      types: ("auto", "string", "content"),
      default: "auto",
    ),
    num-transform: (
      description: [
        Transformation function(s) to apply to the numbers between parsing and formatting.

        See the corresponding parameter of `num()` in @num-parameters for the details.
      ],
      types: ("function", "array", "none"),
      default: "none",
    ),
    num-format: (
      description: [
        Formatting function(s) to turn the numbers into content.

        See the corresponding parameter of `num()` in @num-parameters for the details.
      ],
      types: ("function", "array", "none"),
      default: "format-num()",
    ),
    unit-transform: (
      description: [
        Transformation function(s) to apply to the units between parsing and formatting.

        For now, no unit transformation functions are implemented.
        You can add your own transformation functions to change anything but the format of the units.
        The order of the functions is preserved.

        // TODO: Add reference to the section with the details
      ],
      types: ("function", "array", "none"),
      default: "none",
    ),
    unit-format: (
      description: [
        Formatting function(s) to turn the units into content.

        The built-in formatting functions for units address the handling of negative powers with exponents or fractions.
        You can also add styling functions or format (some) units with custom functions.

        // TODO: Add reference to the section with the details (make `format-unit-power()` a link?)
      ],
      types: ("function", "array", "none"),
      default: "format-unit-power()",
    ),
    qty-format: (
      description: [
        Formatting function to combine the number and unit into a quantity.

        The formatting is applied after the transforming and formatting of the number and unit are done.

        // TODO: Add reference to the section with the details (make `format-qty()` a link?)
      ],
      types: ("function",),
      default: "format-qty()",
    ),
  ),
  return-types: none,
)
#my-tidy.show-function(func-configure, my-tidy.style-args)


= Numbers <numbers>

A number consisting of a value, uncertainties and an exponent.

All components in the number are optional and they can be used in any possible combination, as long as they are in the correct order.
Relative uncertainties always require a value to be specified#footnote[
  A standalone, relative uncertainty is interpreted as a value. Attempting to convert a standalone, absolute uncertainty to a relative uncertainty raises an error.
].
There can be multiple uncertainties between the value and the exponent, even a mixture of absolute and relative uncertainties (although I would not recommend doing this).

#my-tidy.show-example-table(
  scope: (num: num, unit: unit),
  "num[0.9]",
  "num[0.9e1]",
  "num[-0.9 +-0.1 e1]",
  "num[e5]",
  "num[+-0.1]",
  "num[+-0.9e-3]",
)


== Parameters <num-parameters>

#let func-num = (
  name: "num",
  description: "Parse and format a number",
  args: (
    transform: (
      description: [
        Transformation function(s) to apply to the numbers between parsing and formatting.

        This can be used to transform numbers between absolute and relative uncertainties.
        In general, you can use your own transformation functions to change anything but the structure of the numbers.
        The order of the functions is preserved.
        See @num-transform for more information about transformations.
      ],
      types: ("function", "array", "none"),
      default: "none",
    ),
    format: (
      description: [
        Formatting function(s) to turn the numbers into content.

        The formatting can be applied separately to individual components of the numbers (the value, the uncertainties, and the exponent), before joining everything with the function `format-num()`.
        Alternatively, you can completely customize the number formatting with your own functions.
        See @num-format for more information about the formatting.

        // TODO: Add reference to the section with the details (make `format-num()` a link?)
      ],
      types: ("function", "array", "none"),
      default: "format-num()",
    ),
    body: (
      description: [
        The actual number to be parsed and formatted.

        The number can contain a value, uncertainties, and an exponent, all of which are optional. The uncertainties can be either symmetric or asymmetric and absolute or relative to the value.

        #block[
          #h(1em)
          #my-tidy.show-component("value", padding: 1pt)
          ```typ +-```
          #my-tidy.show-component("uncertainty", padding: 1pt)
          ```typ e```
          #my-tidy.show-component("exponent", padding: 1pt)
          #h(1em) or #h(1em)
          #my-tidy.show-component("value", padding: 1pt)
          ```typ (```
          #my-tidy.show-component("uncertainty", padding: 1pt)
          ```typ )e```
          #my-tidy.show-component("exponent", padding: 1pt)
        ]

        The value can either be an integer or a floating point number.

        The exponent is prefixed by an `e` or `E` and must always be at the end of the number.
        It can either be an integer or a floating point number.

        There is no limit to the number of uncertainties, the parser tries to interpret everything after the value (and before the exponent) as uncertainties.
        If an uncertainty is prefixed by ```raw +-```, it is interpreted as an _absolute_ uncertainty.
        Absolute uncertainties can either be integers or floats. \

        An uncertainty wrapped in parentheses `()` is interpreted _relative_ to the significant digits of the value.
        Relative uncertainties must always be integers, a float results in an error.

        Instead of a content body, you can also pass a dictionary to skip the interpretation. See @num-interpretation for the required dictionary format and #text(red)[ref third-party section] for the function `create-num()` to simplify the creation of the dictionary with the correct format.
      ],
      types: ("content", "dictionary"),
      tags: ("Required", "Positional"),
    ),
  ),
  return-types: ("content",),
)
#my-tidy.show-function(func-num, my-tidy.style-args)


== Interpretation <num-interpretation>
// TODO: Find a better section name?

After the interpretation, the number is stored in a dictionary with the keys `value`, `uncertainties`, `exponent`, and `layers`.
As an example, the input `num[0.9(1)*e2*]` results in the following dictionary:

#interpret-number[0.9(1)*e2*]

If you want to skip the interpretation, you can also pass the number as a dictionary in this format to the function `num()`.
Alternatively, you can use the helper function `create-num()` (see #text(red)[add ref to section...]) to simplify the creation of the dictionary if you do not require any styling.


== Transformations <num-transform>

The transformation functions must accept exactly one positional argument, which is the number as a dictionary#footnote[
  See @num-interpretation for the specifications of the dictionary format.
].
Additional arguments must be named arguments to allow their configuration as introduced in @configuration.


=== Absolute uncertainties

This function transforms all uncertainties to the absolute format.
Use the configuration

```typ
#import "@preview/fancy-units:0.2.0: configure, absolute-uncertainties
#configure(num-transform: absolute-uncertainties)
```

to make absolute uncertainties the default for the entire document.
For a single number or a direct customization of the `num()` function, use one of the lines in the following snippet

```typ
#num(transform: absolute-uncertainties)[0.9(1)]
#let my-num = num.with(transform: absolute-uncertainties)
```

==== Parameters

#let func-absolute-uncertainties = (
  name: "absolute-uncertainties",
  description: "Convert all uncertainties to absolute ones",
  args: (
    number: (
      description: [
        The number to convert to absolute uncertainties.
      ],
      types: ("dictionary",),
      tags: ("Required", "Positional"),
    ),
  ),
  return-types: ("dictionary",),
)
#my-tidy.show-function(func-absolute-uncertainties, my-tidy.style-args)

==== Examples

#my-tidy.show-example-table(
  scope: (num: num.with(transform: absolute-uncertainties)),
  "num[0.9+-0.1]",
  "num[0.9(1)]",
  "num[0.9(1:2)]",
)


=== Relative uncertainties

This function transforms all uncertainties to the relative format.
Asymmetric uncertainties are not affected by this function, and if the value of the number is `none`, the transformation results in an error.
To make absolute uncertainties the default for the entire document, use the configuration

```typ
#import "@preview/fancy-units:0.2.0: configure, relative-uncertainties
#configure(num-transform: relative-uncertainties)
```

For a single number with relative uncertainties or a direct customization of the `num()` function, use one of the lines in the following snippet

```typ
#num(transform: relative-uncertainties)[0.9+-0.1]
#let my-num = num.with(transform: relative-uncertainties)
```

==== Parameters

#let func-relative-uncertainties = (
  name: "relative-uncertainties",
  description: "Convert all uncertainties to relative ones",
  args: (
    number: (
      description: [
        The number to convert to relative uncertainties.
      ],
      types: ("dictionary",),
      tags: ("Required", "Positional"),
    ),
  ),
  return-types: ("dictionary",),
)
#my-tidy.show-function(func-relative-uncertainties, my-tidy.style-args)

==== Examples

#my-tidy.show-example-table(
  scope: (num: num.with(transform: relative-uncertainties)),
  "num[0.9 +-0.1]",
  "num[0.9(1)]",
  "num[0.9(1:2)]",
)


== Formatting <num-format>

By default, the function `format-num()` converts the number dictionary (as shown in @num-interpretation) to content, thereby concluding the life cycle of the number.
Additional formatting functions must always be applied prior to this function (and prior to the digit grouping in @num-format-digit-grouping).


=== Format exponent <num-format-exponent>

The exponent of a number can be formatted separately before the rest of the number is formatted.
This enables fine-grained control over the exponent format compared to the default scientific notation.
To change the exponent format, add the function `format-exponent()` to the configuration:

```typ
#import "@preview/fancy-units:0.2.0: configure, format-num, format-exponent
#configure(num-format: (format-exponent.with(separator: sym.dot), format-num))
```

==== Parameters

#let func-format-exponent = (
  name: "format-exponent",
  description: "Format the exponent of a number",
  args: (
    number: (
      description: [
        The number to format.

        The returned number dictionary has the same keys, but the exponent value is now content.
      ],
      types: ("dictionary",),
      tags: ("Required", "Positional"),
    ),
    separator: (
      description: [
        The symbol to separate the exponent from the rest of the number.
      ],
      types: ("string", "symbol", "content"),
      default: "sym.times",
    ),
    base: (
      description: [
        The base of the exponent.
      ],
      types: ("integer", "float", "string", "content"),
      default: "10",
    ),
    decimal-separator: (
      description: [
        The symbol to separate the integer part from the decimal part in the exponent.

        By default, the decimal separator set with `configure()` is used (see @configuration).
      ],
      types: ("auto", "string", "symbol", "content"),
      default: "auto",
    ),
    attach: (
      description: [
        Wrap the exponent in `math.attach()` (thereby making it an actual exponent).
      ],
      types: ("boolean",),
      default: "true",
    ),
  ),
  return-types: ("dictionary",),
)
#my-tidy.show-function(func-format-exponent, my-tidy.style-args)

==== Examples

To format the exponent using the E notation, use the configuration

```typ
#configure(
  num-format: (
    format-exponent.with(separator: none, base: "E", attach: false),
    format-num,
  )
)
```

resulting in the output format

#my-tidy.show-example-table(
  scope: (num: num.with(format: (format-exponent.with(separator: none, base: "e", attach: false), format-num))),
  "num[0.1e3]",
)

=== Digit grouping <num-format-digit-grouping>

For long numbers, grouping the digits can increase the readability.
Usually, this is done in groups of three digits starting from the decimal separator#footnote[
  The actual grouping properties can vary, see https://en.wikipedia.org/wiki/Decimal_separator#Digit_grouping.
].
While this could also be considered a transformation of the number, I chose to make it part of the formatting since it only changes the output format.
To enable digit grouping, add the function `group-digits()` to the `num-format` in the configuration:

```typ
#import "@preview/fancy-units:0.2.0: configure, format-num, group-digits
#configure(num-format: (group-digits, format-num))
```

The digit grouping should always be applied just before the formatting of the number since it affects the body of the value and the uncertainties.
See the description of the `number` parameter for the details.

==== Parameters

#let func-group-digits = (
  name: "group-digits",
  description: "Convert the uncertainties to absolute ones",
  args: (
    number: (
      description: [
        The number to apply digit grouping to.

        While the returned number dictionary has the same keys, the values and uncertainties are no longer decimal numbers but rather strings, content, or arrays thereof.
        This is required to insert the group separator, and the different bodies are handled accordingly in `format-num()`.
        However, this can affect other formatting functions that expect a decimal body.
      ],
      types: ("dictionary",),
      tags: ("Required", "Positional"),
    ),
    target: (
      description: [
        The components of the number to target.

        By default, the digit grouping is applied to both the value and the uncertainties.
        Setting the target to `"value"` or `"uncertainties"` allows you to restrict the grouping to either component.
      ],
      types: ("auto", "string"),
      default: "auto",
    ),
    mode: (
      description: [
        The parts of the number to group.

        By default, the digit grouping is applied to the integer digits as well as the decimal digits.
        Setting the mode to `"integer"` or `"decimal"` allows you to restrict the grouping.
      ],
      types: ("auto", "string"),
      default: "auto",
    ),
    size: (
      description: [
        The size of the groups.
      ],
      types: ("integer",),
      default: "3",
    ),
    threshold: (
      description: [
        The threshold ($>=$) for applying the digit grouping.

        This is counted separately for the integer digits and decimal digits.
      ],
      types: ("integer",),
      default: "5",
    ),
    separator: (
      description: [
        The separator to insert between the groups.
      ],
      types: ("string", "symbol", "content"),
      default: "sym.space.thin",
    ),
  ),
  return-types: ("dictionary",),
)
#my-tidy.show-function(func-group-digits, my-tidy.style-args)

==== Examples

With the default configuration, the digit grouping results in the following output format
#{
  configure(num-format: (group-digits, format-num))
  my-tidy.show-example-table(
    scope: (num: num, unit: unit),
    "num[1234.5678]",
    "num[12345.67890]",
    "num[1234567]",
    "num[12345+-12345]",
  )
}


=== Format number <num-format-num>

This function handles the final formatting of the number and it is required to return content from the function `num()`.
Without this function, the number remains a dictionary as shown in @num-interpretation.

==== Parameters

#let func-format-num = (
  name: "format-num",
  description: "Format a number",
  args: (
    number: (
      description: [
        The number to format.

      ],
      types: ("dictionary",),
      tags: ("Required", "Positional"),
    ),
    decimal-separator: (
      description: [
        The symbol to separate the integer part from the decimal part.

        By default, the decimal separator set with `configure()` is used (see @configuration).
      ],
      types: ("auto", "string", "symbol", "content"),
      default: "auto",
    ),
  ),
  return-types: ("content",),
)
#my-tidy.show-function(func-format-num, my-tidy.style-args)


== Styling <num-styling>

When styling the components in a number, there are a few (syntax) rules to follow.
The styling functions are attached to the components before the number is actually parsed.
The styling does, therefore, not affect the interpretation of the number.
For the supported styling functions see @styling-supported-functions.

It is sufficient to apply the styling to the actual components.
The accompanying characters ```none +-```, `()` or `eE` do not have to be included in the styling functions.
In either case only the actual component will be styled in the output.
Styling the accompanying characters is (currently) not possible.

#my-tidy.show-example-table(
  scope: (num: num, unit: unit),
  "num[#text(red)[-0.9] (1)]",
  "num[0.9 #text(red)[(1)] e1]",
  "num[0.9 *+-0.1* e1]",
  "num[-0.9 (1) #text(red)[e1]]",
  "num[0.9 +0.0 #text(red)[-0.1]]",
)


= Units <units>

#let link-format-unit-power = link(<unit-format-power>, `format-unit-power()`)
#let link-format-unit-fraction = link(<unit-format-fraction>, `format-unit-fraction()`)
#let link-format-unit-symbol = link(<unit-format-symbol>, `format-unit-symbol()`)

#let format-example-units(units) = table(
  columns: units.len() + 1,
  "", ..units.map(u => raw("unit[" + u + "]")),
  link-format-unit-power,
  ..units.map(u => unit(format: format-unit-power, eval(u, mode: "markup"))),
  link-format-unit-fraction,
  ..units.map(u => unit(format: format-unit-fraction, eval(u, mode: "markup"))),
  link-format-unit-symbol,
  ..units.map(u => unit(format: format-unit-symbol, eval(u, mode: "markup"))),
)

A unit can be anything from a single character to a complex structure with fractions, brackets, and groups.
It is not necessary to use variables for the prefixes and units, you can just write them down directly.
The parser will figure out the exponents, brackets, etc. and the unit is formatted accordingly.

#my-tidy.show-example-table(
  scope: (num: num, unit: unit),
  "unit[μg]",
  "unit[(m s)^2]",
  "unit[kg m/s^2]",
)

== Parameters <unit-parameters>

#let func-unit = (
  name: "unit",
  description: "Parse and format a unit",
  args: (
    transform: (
      description: [
        Transformation function(s) to apply to the units between parsing and formatting.

        As of now, there are no transformation functions implemented.
        However, you can write your own custom transformation functions to apply to the units.
        See @unit-transform for an example to format the exponents `1/2` or `0.5` as `math.sqrt()`.
      ],
      types: ("function", "array", "none"),
      default: "none",
    ),
    format: (
      description: [
        Formatting function(s) to turn the units into content.

        The formatting is applied recursively to the units in the content tree.
        There are three built-in formatting functions, #link-format-unit-power, #link-format-unit-fraction, and #link-format-unit-symbol.
        Only one of them can be used at a time since they each return the final unit as content.
        If you want to apply a different formatting to the units, you can write a custom function.
        See @unit-interpretation for the structure of the content tree and look at the source code of the built-in formatting functions.

        // TODO: Add reference to the section with the details (use links for `format-unit-...()`?)
      ],
      types: ("function", "array"),
      default: "format-unit-power()",
    ),
    macros: (
      description: [
        Macros to replace units or prefixes.

        By default, the macros set with `add-macros()` are used (see @unit-macros).
      ],
      types: ("dictionary",),
      default: "auto",
    ),
    body: (
      description: [
        The actual unit(s) to be parsed and formatted.

        The unit can contain prefixes, units, fractions, exponents, and brackets (round, square, curly).

        // TODO: Anything to add here?

        Instead of a content body, you can also pass a dictionary to skip the interpretation. See @unit-interpretation for the required dictionary format and #text(red)[ref third-party section] for the function `create-unit()` to simplify the creation of the dictionary with the correct format.
      ],
      types: ("content", "dictionary"),
      tags: ("Required", "Positional"),
    ),
  ),
  return-types: ("content",),
)
#my-tidy.show-function(func-unit, my-tidy.style-args)


== Interpretation <unit-interpretation>

After the interpretation, the unit is stored in a dictionary with the keys `children` (or `body`), `layers`, and `group`.
As an example, the input `unit[*kg* m/s^2]` results in the following dictionary:

#interpret-unit[*kg* m/s^2]

If you want to skip the interpretation, you can also pass the unit as a dictionary in this format to the function `unit()`.
Alternatively, you can use the helper function `create-unit()` (see #text(red)[add ref to section...]) to simplify the creation of the dictionary if you do not require any styling.


== Transformations <unit-transform>

Add the unit-transform-sqrt function...


== Formatting <unit-format>

The formatting of units mainly revolves around the handling of negative exponents.
They can be formatted directly with a negative exponent, by using a fraction, or by using a symbol to indicate the division.
These three options are available with the formatting functions #link-format-unit-power, #link-format-unit-fraction, and #link-format-unit-symbol.
See the formats in the examples below.

#format-example-units(("m/s", "kg^-2", "kg m/s^2", "kg/(m s)"))

The format with the function #link-format-unit-symbol can be ambiguous when a slash is followed by multiple units.
If you want to prevent this ambiguity, group the units by wrapping them in a second pair of parentheses as shown in @unit-grouping.


=== Format units with powers <unit-format-power>

Formatting units with the function `format-unit-power()` directly uses the exponent.
This format is suitable for inline units and quantities since it works well with the regular line height, especially for short and simple units.
For complicated units, the format can become difficult to read as the output tends to become very long.

#let func-unit-format-power = (
  name: "unit-format-power",
  description: "Format units with powers",
  args: (
    tree: (
      description: [
        The unit to format.
      ],
      types: ("dictionary",),
      tags: ("Required", "Positional"),
    ),
    separator: (
      description: [
        The separator between individual units.

        The individual units are formatted they are joined by the separator.
        The recommended separator is a small amount of horizontal space to visually separate the units.
        Other typical options are the symbols `sym.dot` [#sym.dot] or `sym.times` [#sym.times].
      ],
      types: ("str", "symbol", "content"),
      default: "h(0.2em)",
    ),
    decimal-separator: (
      description: [
        The symbol to separate the integer part from the decimal part in exponents.

        By default, the separator set with `configure()` is used (see @configuration).
      ],
      types: ("auto", "str", "symbol", "content"),
      default: "auto",
    ),
  ),
  return-types: ("content",),
)
#my-tidy.show-function(func-unit-format-power, my-tidy.style-args)

// TODO: Add any further examples here?


=== Format units with fractions <unit-format-fraction>

Formatting units with the function `format-unit-fraction()` uses `math.frac()` to represent negative exponents.
This format is recommended for block-level equations where the fractions are displayed in their regular size.
For inline units and quantities the fractions can be difficult to read, especially if the units in the fraction have exponents.

#let func-unit-format-fraction = (
  name: "unit-format-fraction",
  description: "Format units with fractions",
  args: (
    tree: (
      description: [
        The unit to format.
      ],
      types: ("dictionary",),
      tags: ("Required", "Positional"),
    ),
    separator: (
      description: [
        The separator between individual units.

        The separator is applied between units and fractions, and between units in the same numerator or denominator.
        The recommended separator is a small amount of horizontal space to visually separate the units.
        Other typical options are the symbols `sym.dot` [#sym.dot] or `sym.times` [#sym.times].
      ],
      types: ("str", "symbol", "content"),
      default: "h(0.2em)",
    ),
    decimal-separator: (
      description: [
        The symbol to separate the integer part from the decimal part in exponents.

        By default, the separator set with `configure()` is used (see @configuration).
      ],
      types: ("auto", "str", "symbol", "content"),
      default: "auto",
    ),
  ),
  return-types: ("content",),
)
#my-tidy.show-function(func-unit-format-fraction, my-tidy.style-args)

// TODO: Add any further examples here?


=== Format units with symbols <unit-format-symbol>

Formatting units with the function `format-unit-symbol()` uses a symbol in place of a fraction to represent negative exponents.
This format is suitable for inline units and quantities since it works well with the regular line height, especially for short and simple units.
For complicated units, the format can become difficult to read as the output tends to become very long.
Furthermore, the format can be ambiguous when there are multiple units in the denominator of the fraction.

#let func-unit-format-symbol = (
  name: "unit-format-symbol",
  description: "Format units with symbols",
  args: (
    tree: (
      description: [
        The unit to format.
      ],
      types: ("dictionary",),
      tags: ("Required", "Positional"),
    ),
    symbol: (
      description: [
        The symbol to indicate a fraction.
      ],
      types: ("str", "symbol", "content"),
      default: "sym.slash",
    ),
    padding: (
      description: [
        The padding around the symbol.

        This can be used to fine-tune the spacing around the fractional symbol.
        Using a dictionary with the keys `left` and `right`, the padding can be set individually for both sides of the symbol.
      ],
      types: ("content", "dictionary"),
      default: "h(0.05em)",
    ),
    separator: (
      description: [
        The separator between individual units.

        The separator is applied between individual units that are not adjacent to the fractional symbol.
        The recommended separator is a small amount of horizontal space to visually separate the units.
        Other typical options are the symbols `sym.dot` [#sym.dot] or `sym.times` [#sym.times].
      ],
      types: ("str", "symbol", "content"),
      default: "h(0.2em)",
    ),
    decimal-separator: (
      description: [
        The symbol to separate the integer part from the decimal part in exponents.

        By default, the separator set with `configure()` is used (see @configuration).
      ],
      types: ("auto", "str", "symbol", "content"),
      default: "auto",
    ),
  ),
  return-types: ("content",),
)
#my-tidy.show-function(func-unit-format-symbol, my-tidy.style-args)

// TODO: Add any further examples here?


== Grouping <unit-grouping>

You can group multiple units with parentheses or (curly) brackets.
A single pair of parentheses _silently_ group the units, and only the second pair of parentheses is actually included in the formatted output.
Brackets (square#footnote[
  Since brackets `[]` are also the macro for `content`, which can sometimes lead to unexpected behavior.
  This is just something to keep in mind if you absolutely have to use square brackets in a unit.
] and curly) are always included in the formatted output.
This replicates the behavior of parentheses and brackets in a fraction in math mode.

#format-example-units(("kg/(m s)", "kg/((m s))", "(kg m)/s", "[kg m]/s"))

If you wrap a single unit in parentheses the exponent is _protected_ from the formatting function.
This can be useful if you are using the function #link-format-unit-fraction and you want to prevent nested fractions that can be difficult to read.
When using the function #link-format-unit-power, the behavior of protected exponents can be a bit weird when it results in stacked exponents.
For the formatting function #link-format-unit-symbol wrapping a single unit in parentheses has no effect since nested fractions are not possible anyway.

#format-example-units(("kg/(m^-1 s)", "kg/((m^-1) s)"))


== Styling and Joining <unit-examples-styling-and-joining>

You can apply styling to (multiple) units or just to a part of a unit.
The styling functions are attached to the (group of) units and components inside.
E.g. if there is a fraction or an exponent in the styling function, they are also be formatted accordingly.
It is also possible to apply the styling only to the base unit or to the exponent.

If a unit is split up into multiple parts due to the styling, you can use a colon to join the components again.
This is useful when you want to apply styling only to the prefix or the base unit.
In addition, this is also necessary to include a Typst symbol or variable in a unit.

Since the underscore character `_` is reserved for _italic_ styling you have to use the function `sub()` to add a subscript to a unit.
If a unit has both an exponent and a subscript, everything is formatted correctly with a single call of the function `math.attach()`.

#my-tidy.show-example-table(
  scope: (unit: unit),
  "unit[*kg* m / s]",
  "unit[_E_#sub[rec]^2]",
  "unit[#text(red)[μ]:m^2]",
  "unit[m#math.cancel[^2] / (#math.cancel[m] s)]",
)


== Macros <unit-macros>

Macros enable you to define units or unit prefixes to be inserted automatically if you use the macro in a unit or quantity anywhere in your document.
This feature is designed for composite units, complicated units with styling, or units where you want to change the output format later.
In all three cases, using macros can improve the workflow and help in reducing mistakes.
You should not use this feature for trivial units like `meter: [m]` or `second: [s]`.
There is no reason for a debate on how to format these standard units and using macros here would just decrease the readability.
Marcos are compatible with all unit features such as exponents, subscripts, styling and grouping.

#let func-add-macros = (
  name: "add-macros",
  description: "Add macros for units and prefixes",
  args: (
    macros: (
      name: [..macros],
      description: [
        The names of the macros must only contain alphanumeric characters.
        Underscores are not allowed since they are used for italic styling in the units parser.

        The values of the macros should be content.
        If a string or a symbol are passed, they are turned into content automatically to allow their interpretation by the same function as the regular units.
      ],
      types: ("content", "string", "symbol"),
      tags: (),
    ),
  ),
  return-types: ("content",),
)
#my-tidy.show-function(func-add-macros, my-tidy.style-args)

The easiest example for a macro is the prefix μ.
If you do not want to type that letter directly (or use `sym.mu`), you can define a macro that replaces the character `"u"` with the symbol μ.
For the macro to work correctly, you then have to join the prefix and the unit with a colon, e.g. `unit[u:m]`.
Additionally, macros are useful for composite units that might initially require some styling.
With the macros

// TODO: How to use the example-macros for the code snipped with `add-macros()`?
#let example-macros = (
  u: sym.mu,
  m2: [m^2],
  aB: [_a_#sub[B]],
  au: [arb. unit],
  verdet: [rad / (T m)],
)

// TODO: Use this as the default for all code snippets...
#pad(
  x: 5pt,
  ```typ
  #add-macros(
    u: sym.mu,
    m2: [m^2],
    aB: [_a_#sub[B]],
    au: [arb. unit],
    verdet: [rad / (T m)],
  )
  ```,
)

see the following examples for units and quantities using those macros

#{
  add-macros(..example-macros)
  set table(inset: 5pt)
  my-tidy.show-example-table(
    scope: (unit: unit, qty: qty),
    "unit[u#sub[2]]",
    "unit[#text(red)[u]:m2^2]",
    "unit[((m2))^2]",
    "unit[aB^2]",
    "unit[au]",
    "qty[137][verdet]",
  )
}
