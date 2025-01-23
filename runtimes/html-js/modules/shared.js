// Arrow HTML-JS Runtime: Shared utility (static) functions

function safeInt(maybe_number, replacement, allow_none_integer_replacement) {
    if ( Number.isInteger(replacement) == false && allow_none_integer_replacement !== true ) replacement = (-1);
    var result = parseInt(maybe_number);
        result = ( Number.isInteger(result) ? result : replacement );
    return result;
}

function safeBool(maybe_bool){
    var result = null;
    if ( typeof maybe_bool != 'boolean' ){
        if ( typeof maybe_bool == 'string' ){
            maybe_bool = maybe_bool.toLowerCase();
            if ( maybe_bool === "true" ){
                result = true;
            } else if ( maybe_bool === "false" ){
                result = false;
            }
        }
    } else {
        result = maybe_bool;
    }
    if ( result === null ){
        result = ( !!(maybe_bool) );
    }
    return result;
}

function object_has_keys_all(object, expected_keys_array) {
    for (const object_key of expected_keys_array) {
        if ( object.hasOwnProperty(object_key) == false ){
            return false;
        }
    }
    return true;
}

function remap_connections_for_slots(map, owner_node_id){
    if ( typeof map == 'object' && typeof owner_node_id == 'number' && owner_node_id >=0 ){
        var remap_for_slots = [];
        if ( map.hasOwnProperty("io") && Array.isArray(map.io) ){
            for (const connection of map.io) {
                // <connection>[ from_id, from_slot, to_id, to_slot ]
               if ( connection.length >= 4 && connection[0] == owner_node_id ){
                    remap_for_slots[ connection[1] ] = { "id": connection[2], "slot": connection[3] };
               }
            }
        }
        return remap_for_slots;
    } else {
        throw new Error("Unable to remap connections for slots: Called with wrong arguments.");
    }
}

function create_node_base_html(node_id, node_resource, tag){
    var html = document.createElement(tag || 'div');
        html.className = 'node';
        html.setAttribute('data-type',  node_resource.type);
        html.setAttribute('data-name',  node_resource.name);
        html.setAttribute('data-uid',   node_id.toString());
    return html;
}

function create_element(tag, inner, attributes){
    var element = document.createElement(tag);
    if ( inner ){
        if ( typeof inner == 'string' ){
            element.innerHTML = inner;
        } else if ( inner instanceof Element ){
            element.appendChild(inner);
        }
    }
    if (typeof attributes == 'object') {
        for (const attr in attributes) {
            if (attributes.hasOwnProperty(attr)) {
                element.setAttribute(attr, attributes[attr]);
            }
        }
    }
    return element;
}

function ellipsis(text, length) {
    return text.substr(0, length) + (text.length > length ? "..." : "")
}

function format(text, pairs, case_insensitive){
    // replacing every `{tag}` in `text` with value of `pairs[tag]`
    if ( typeof text == 'string' && typeof pairs == 'object' ){
        for (const key in pairs) {
            if (pairs.hasOwnProperty(key)) {
                const tag = '{' + key + '}';
                const pattern = new RegExp(tag, (case_insensitive === true ? 'gi' : 'g')); // i.e. `g`locally search for every key
                const replacement = pairs[key];
                text = text.replace( pattern , replacement );
            }
        }
        return text;
    } else {
        throw new Error("Unable to format text: Called with wrong arguments.");
    }
}

function parse_bbcode(text, return_text_anyway){
    // returns `text/html`
    if (typeof text == 'string'){
        return DEFAULT_BBCODE_PARSER.parse(text);
    } else {
        // ... or if the input is not what expected
        if (return_text_anyway === false){ // error
            throw new Error("Unable to parse BBCode: Called with wrong arguments.");
        } else { // or by default an empty string ''
            return "";
        }
    }
}

function string_begins_with(string, rhs){
    if ( typeof string == 'string' && typeof rhs == 'string'){
        return ( string.indexOf(rhs) == 0 );
    } else {
        throw new Error("Called with Wrong Arguments: Expected two strings.");
    }
}

function string_ends_with(string, rhs){
    if ( typeof string == 'string' && typeof rhs == 'string'){
        var last_index_of_rhs = string.lastIndexOf(rhs);
        return ( last_index_of_rhs >= 0 && last_index_of_rhs === ( string.length - rhs.length ) );
    } else {
        throw new Error("Called with Wrong Arguments: Expected two strings.");
    }
}

// Replicates `Godot[v3.2.x]::String::capitalize`:
// For `capitalize camelCase mixed_with_underscores`, it will return `Capitalize Camel Case Mixed With Underscores`.
function capitalize(string){
    if ( typeof string == 'string' ){
        // Replaces underscores with spaces
        var replaced = string.replace(/_/gi, " ");
        // adds spaces before in-word uppercase characters
        var result = "";
        for ( var cidx = 0; cidx < replaced.length; cidx++ ){
            var chr = replaced.charAt(cidx);
            var chr_upper = chr.toUpperCase();
            result += ( chr != " " && chr == chr_upper ? ` ${chr}` : chr );
        }
        // converts all letters to lowercase
        // then capitalizes the first letter and every letter following a space character.
        result = result.split(" ");
        for( var widx = 0; widx < result.length; widx++ ){
            var low_word = result[widx].toLowerCase();
            result[widx] = ( low_word.charAt(0).toUpperCase() + low_word.substring(1) );
        }
        result = result.join(" ");
        return result;
    } else {
        throw new Error("Called with Wrong Arguments: Expected string.");
    }
}

const inclusiveRandInt = function(_min, _max, base, negative, even, odd) {
    if( arguments.length < 2 ){
        _max = _min;
		_min = 0;
	}
    _min = ( Number.isFinite( _min ) ? Math.ceil(_min) : 0 );
    _max = ( Number.isFinite( _max ) ? Math.floor(_max) : 0 );
    var max = Math.max(_min, _max);
    var min = Math.min(_min, _max);
	let result = null;
    do {
        result = Math.floor(Math.random() * (max - min + 1)) + min;
        if ( even != odd ){
            let is_even = ((result % 2) == 0);
            if ( is_even && even == false ) result = null;
            if ( is_even == false && odd == false ) result = null;
        }
    } while (result == null);
    if ( negative === true ) result = (result * (-1));
	if ( Number.isInteger(base) && base >= 2 && base <= 36  ){
        return result.toString(base);
    } else {
        return result;
    }
};
