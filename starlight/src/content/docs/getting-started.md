---
title: Getting Started
description: A guide to getting started with fancy-units in Typst.
---

On this page you will learn the basics about writing fancy units (and numbers) in your Typst projects.
I am assuming that you have a basic understanding of Typst and its syntax, especially the usage of functions with positional and named arguments.
If that is not the case, please refer to the [Typst tutorial](https://typst.app/docs/tutorial/).

As a long time user of [siunitx](https://ctan.org/pkg/siunitx), I have formatted my fair share of numbers in units during my studies.
When I started to learn Typst, I created this package to try to find a new approach to writing numbers and units that follows the Typst philosophy.
While it would be great to have a package that is as powerful as siunitx, setting this as the baseline would involuntarily lead to a port of siunitx.
If you are looking for a package that does just that, check out [unify](https://typst.app/universe/package/unify).

## A few examples

Formatting your first numbers and units with sensible default settings is very easy.
Just import the functions `num` and `unit` and write down some numbers and units.

```typst frame="none"
#import "@preview/fancy-units:0.1.0": num, unit
#num[0.9 +- 0.1]
#unit[kg m/s^2]
```

As you can see in the example above, the functions `num()` and `unit()` expect a body of type `content` as the only required argument.
This allows you to use styling functions, just like you would do it with regular Typst content.
While the output of the functions will always be wrapped in `math.equation()`, the input is not in math mode to avoid any restrictions on unit names.
Where necessary, the styling functions are converted to their equivalents in math mode.

```typst frame="none"
#import "@preview/fancy-units:0.1.0": num, unit
#num[137 +- #text(red)[14]]
#unit[W / *kg*]
```

Passing a content body is the only required argument for all functions in this package.

## Typst version
