#import "unit/interpret.typ": interpret-unit

// Source for the separators https://en.wikipedia.org/wiki/Decimal_separator#Conventions_worldwide
#let language-decimal-separator = (
  af: ",", // Afrikaans
  sq: ",", // Albanian
  be: ",", // Belarusian
  bg: ",", // Bulgarian
  hr: ",", // Croatian
  cs: ",", // Czech
  da: ",", // Danish
  nl: ",", // Dutch
  en: ".", // English
  et: ",", // Estonian
  fi: ",", // Finnish
  fr: ",", // French
  ka: ",", // Georgian
  de: ",", // German
  el: ",", // Greek
  hu: ",", // Hungarian
  is: ",", // Icelandic
  it: ",", // Italian
  lt: ",", // Lithuanian
  mn: ",", // Mongolian
  no: ",", // Norwegian
  pl: ",", // Polish
  pt: ",", // Portugese
  ru: ",", // Russian
  sr: ",", // Serbian
  sk: ",", // Slovak
  sl: ",", // Slovenian
  es: ",", // Spanish
  sv: ",", // Swedish
  tr: ",", // Turkish
  tk: ",", // Turkmen
  uk: ",", // Ukrainian
  // Kurmanji and Latin are missing
  //
  // A few other languages
  jp: ".", // Japanese
  ko: ".", // Korean
  zh: ".", // Chinese
)

// Get the decimal separator based on the text language
//
// This function can only be called in a known context!
//
// All languages from https://typst.app/tools/hyphenate/ except for Kurmanji and Latin
// are currently supported. In addition Japanese, Korean and Chinese are available.
// If a language is not supported, the separator will default to ".".
#let get-decimal-separator() = {
  language-decimal-separator.at(text.lang, default: ".")
}

// Config for the output format of numbers and units
//
// The following options are available:
//  - decimal-separator (auto | str | content): Defaults to `auto`
//  - uncertainty-mode (str): Defaults to "plus-minus". Can also be "parentheses" or "conserve"
//  - unit-separator (content): Default to `h(0.2em)`
//  - per-mode (str): Defaults to "power". Can also be "fraction" or "slash"
//  - quantity-separator (content): Defaults to `h(0.2em)`
#let state-config = state(
  "fancy-units-config",
  (
    decimal-separator: auto,
    num-transform: false,
    num-format: auto,
    unit-transform: false,
    unit-format: auto,
    qty-format: auto,
  ),
)

// State for the unit macros
//
// The keys must only contain alphabetic characters.
// The values must be of type content or of type string.
#let state-macros = state(
  "fancy-units-macros",
  (:),
)

// Change the configuration of the package
//
// - args (any): Named arguments to update the config
//
// The `args` are used to update the current config state. Only the keys
// that appear in the `args` are actually changed in the state. It is not
// possible to delete keys from the state.
#let configure(..args) = {
  state-config.update(config => { config + args.named() })
}

// Add unit macros
//
// - args (any): Named arguments to add as macros
#let add-macros(..args) = {
  let new-macros = args
    .named()
    .pairs()
    .map(macro => {
      let (name, unit) = macro
      if type(unit) != content { unit = [#unit] }
      return (name, interpret-unit(unit))
    })

  state-macros.update(macros => {
    for (name, unit) in new-macros {
      macros.insert(name, unit)
    }
    return macros
  })
}
