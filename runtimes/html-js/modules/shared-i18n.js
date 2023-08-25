// Arrow HTML-JS Runtime: i18n (internationalization) module

const _SUPPORTED_LOCALES = ["en"];

const _TRANSLATION_TABLE = {
    skip: {
        en: "Skip",
    },
    continue: {
        en: "Continue",
    },
    false: {
        en: "False",
    },
    true: {
        en: "True",
    },
    generate: {
        en: "Generate",
    },
    dialog_anonymous_character_name: {
        en: "Anonymous",
    },
    apply: {
        en: "Apply",
    },
    invalid: {
        en: "Invalid",
    },
    user_input_default_bool_negative: {
        en: "Negative (False)",
    },
    user_input_default_bool_positive: {
        en: "Positive (True)",
    },
    evaluate: {
        en: "Evaluate",
    },
    match: {
        en: "Match",
    },
    eol: {
        en: "EOL",
    },
    eol_node: {
        en: "EOL: {node_name}",
    },
};

function i18n(string_id, lang){
    // default to `_LOCALE` if the target `lang` is not annotated or supported 
    if ( _SUPPORTED_LOCALES.includes(lang) == false ) lang = _LOCALE;
    if ( _TRANSLATION_TABLE.hasOwnProperty(string_id) ) {
        if ( _TRANSLATION_TABLE[string_id].hasOwnProperty(lang) ) {
            return _TRANSLATION_TABLE[string_id][lang];
        } else {
            throw new Error(`Incomplete Translation Table: value for the selected locale doesn't exist! _TRANSLATION_TABLE[${string_id}][${lang}]`);
        }
    } else {
        throw new Error(`I18n translation table doesn't include the string id: ${string_id} `);
    }
}
