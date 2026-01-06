#import "unit/interpret.typ": interpret-unit

// Config for the output format of numbers and units
//
// The following options are available:
//  - decimal-separator (auto, string or content): Defaults to `auto`
//  - num-transform ((array) of function): Number transformation(s)
//  - num-format ((array) of function): Number formatting function(s)
//  - unit-transform ((array) of function): Unit transformation(s)
//  - unit-format ((array) of function): Unit formatting function(s)
//  - qty-format (function): Quantity formatting function(s)
#let _state-config = state(
  "fancy-units-config",
  (
    decimal-separator: auto,
    num-transform: none,
    num-format: auto,
    unit-transform: none,
    unit-format: auto,
    qty-format: auto,
  ),
)

// State for the unit macros
//
// The keys must only contain alphabetic characters.
// The values must be of type content or of type string.
#let _state-macros = state(
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
  _state-config.update(config => { config + args.named() })
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

  _state-macros.update(macros => {
    for (name, unit) in new-macros {
      macros.insert(name, unit)
    }
    return macros
  })
}


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

// Get the decimal separator from the config or based on the text language
//
// This function can only be called in a known context!
//
// All languages from https://typst.app/tools/hyphenate/ except for Kurmanji and Latin
// are currently supported. In addition Japanese, Korean and Chinese are available.
// If a language is not supported, the separator will default to ".".
#let _get-decimal-separator() = {
  let config-decimal-separator = _state-config.get().decimal-separator
  if config-decimal-separator == auto {
    language-decimal-separator.at(text.lang, default: ".")
  } else {
    config-decimal-separator
  }
}
