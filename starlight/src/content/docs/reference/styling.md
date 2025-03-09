---
title: Styling
description: Learn how to style numbers and units in the fancy-units package
---

This package allows you to wrap parts of the numbers and units into styling functions. During the parsing, the content is unwrapped until there is only the actual text left. The styling functions are saved in a stack alongside the text in a content tree. If necessary, the text is then modified according to the format options. During the formatting, the styling functions are applied to the text again to get the desired output.

Since the body has to follow the syntax rules of markup content, there are situations where spaces are required when you are using styling functions. There is no way to ignore a syntax error in the body; the content must always be valid before it can be parsed. If you are calling a function in the content of a number or a unit, make sure to put a space in front of succeeding parentheses (or brackets) that are not supposed to be part of the function. For numbers, this is only relevant when you are using relative uncertainties. With units, this can be an issue whenever you are grouping units with parentheses (or brackets).

## Supported Functions

This table gives you an overview of the styling functions that are currently supported for numbers and units. The support for quantities is equivalent to `num[]` and `unit[]` for the respective parts. Which styling functions are actually useful is for you to decide.

| Function           | `num[]` | `unit[]` | Notes                                            |
| ------------------ | ------- | -------- | ------------------------------------------------ |
| `*bold*`           | ✅      | ✅       |                                                  |
| `_emph_`           | ✅      | ✅       | Support for `num[]` depends on the font          |
| `text(..)[]`       | ✅      | ✅       |                                                  |
| `overline[]`       | ❌      | ✅       |                                                  |
| `underline[]`      | ❌      | ✅       |                                                  |
| `strike[]`         | ❌      | ✅       |                                                  |
| `sub[]`            | ❌      | ✅       | The subscript will be passed to `attach(br: )`   |
| `super[]`          | ❌      | ✅       | The superscript is treated like a separate unit  |
| `math.cancel[]`    | ✅      | ✅       |                                                  |
| `math.display[]`   | ⚠️      | ✅       | The parameter `cramped` has no effect            |
| `math.inline[]`    | ⚠️      | ✅       | Equivalent to the function `math.display[]`      |
| `math.script[]`    | ✅      | ✅       |                                                  |
| `math.sscript[]`   | ✅      | ✅       |                                                  |
| `math.bold[]`      | ✅      | ✅       | Equivalent to the function `*bold*`              |
| `math.italic[]`    | ✅      | ✅       | Equivalent to the function `_emph_`              |
| `math.sans[]`      | ✅      | ✅       | Support for `num[]` depends on the font          |
| `math.frak[]`      | ✅      | ✅       | Support for `num[]` depends on the font          |
| `math.mono[]`      | ✅      | ✅       | Support for `num[]` depends on the font          |
| `math.bb[]`        | ✅      | ✅       | Support for `num[]` depends on the font          |
| `math.cal[]`       | ✅      | ✅       | Support for `num[]` depends on the font          |
| `math.overline[]`  | ✅      | ✅       | Different spacing than the regular `overline[]`  |
| `math.underline[]` | ✅      | ✅       | Different spacing than the regular `underline[]` |

## Examples

### Styling in Numbers

When styling the components in a number, there are a few syntax rules to follow. The styling functions are attached to the components before the number is actually parsed. If done correctly, the styling will therefore not affect the interpretation of the number.

It is sufficient to apply the styling to the actual components. The accompanying characters `+-`, `()` or `eE` do not have to be included in the styling functions. In either case, only the actual component will be styled in the output. Styling the accompanying characters is currently not possible.

```typst
// Examples of styling in numbers
num[#text(red)[-0.9] (1)]
num[0.9 #text(red)[(1)] e1]
num[0.9 *+-0.1* e1]
num[-0.9 (1) #text(red)[e1]]
num[0.9 +0.0 #text(red)[-0.1]]
```

### Styling in Units

You can apply styling to (multiple) units or just to a part of a unit. The styling functions are attached to the (group of) units and components inside. For example, if there is a fraction or an exponent in the styling function, they will also be formatted accordingly.

It is also possible to apply the styling only to the base unit or only to the exponent. The parser will attach an exponent to the previous unit, so the separation by the styling functions is not an issue.

If a unit is split up into multiple parts due to the styling, you can use a colon to join the components again. This is useful when you want to apply styling only to the prefix or the base unit. In addition, this is also necessary to include a Typst variable in a unit.

Since the underscore character `_` is reserved for _italic_ styling, you have to use the function `sub()` to add a subscript to a unit. As for an exponent, the parser will attach the subscript to the previous unit and the formatter will use the function `math.attach()`. If a unit has both an exponent and a subscript, everything will be formatted correctly.

```typst
// Examples of styling in units
unit[*kg* m / s]
unit[_E_#sub[rec]^2]
unit[#text(red)[μ]:m^2]
unit[m#math.cancel[^2] / (#math.cancel[m] s)]
```
