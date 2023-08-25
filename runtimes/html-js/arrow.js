// Arrow HTML-JS Runtime: Main interpreter script

// Preferences
//
// NOTE: Respecting following preferences depends on each node module.
//

const _VERBOSE = true;    // console logging verbosity
const _CLICK   = 'click'; // default event to be listened for user interactions
const _LOCALE  = 'en';    // runtime's UI locale (used by `i18n`)

// This runtime allows nodes (such as hubs, generators, etc.)
// to auto-play (or skip) in case no user interaction is normally needed.
// You can force a fully manual play by disabling following constant.
// This constant controls auto-skipping as well.
const _ALLOW_AUTO_PLAY = true;

// Nodes (e.g. `Content`s) can clear up the view from all other nodes before them if allowed:
const _ALLOW_CLEARANCE = true;

const DO_NOT_PRINT_EOL_MESSAGE = true;

// Referencing to frequently used DOM Elements
var DOME = {};

// Global Variables
var VARS = {};

// Characters List
var CHARS = {};

var OPEN_NODES_BY_ORDER = [];
var OPEN_NODES_REFORMATTED_NAMES = []; // names-lowercased-with-whitespaces-replaced-by-dashes

if (typeof PROJECT != "object" || PROJECT.hasOwnProperty("entry") == false) {
    throw new Error("Invalid document data (i.e. `PROJECT` constant.)")
}

// Adjusting document to the project settings
const ROOT = document.getElementsByTagName('html')[0];

// Greeting
console.log(
    "Hello and welcome to \n\t" +
    PROJECT.title + "\n" +
    "Made with Arrow {{arrow_version}} \n" +
    "{{arrow_website}}"
);

const NODE_CLASSES_BY_TYPE = {
    // jshint ignore:start
    "condition": Condition,
    "content": Content,
    "dialog": Dialog,
    "entry": Entry,
    "frame": Frame,
    "generator": Generator,
    "hub": Hub,
    "interaction": Interaction,
    "jump": Jump,
    "macro_use": MacroUse,
    "marker": Marker,
    "monolog": Monolog,
    "randomizer": Randomizer,
    "sequencer": Sequencer,
    "tag_edit": TagEdit,
    "tag_match": TagMatch,
    "tag_pass": TagPass,
    "user_input": UserInput,
    "variable_update": VariableUpdate,
    // jshint ignore:end
};

const _CHARS_REQUIRED_KEYS = ["name", "color"];
function sort_characters(){
    var characters = PROJECT.resources.characters;
    for (const char_id in characters) {
        if ( characters.hasOwnProperty(char_id) ) {
            if ( object_has_keys_all( characters[char_id], _CHARS_REQUIRED_KEYS ) ){
                CHARS[char_id] = characters[char_id];
                if ( CHARS[char_id].hasOwnProperty("tags") == false ) {
                    CHARS[char_id].tags = {}
                }
            } else {
                throw new Error(`Unable to sort characters! The character '${char_id}' resource doesn't include required data! ${ _CHARS_REQUIRED_KEYS.join(", ") }`);
            }
        }
    }
}

function update_global_characters_tags(update_list) {
    for (char_id in update_list) {
        if ( CHARS.hasOwnProperty(char_id) ) {
            for (tag_key in update_list[char_id]) {
                if (tag_key.length > 0) {
                    var new_value = update_list[char_id][tag_key];
                    if (typeof new_value == 'string'){
                        console.log(`updating character tag '${tag_key} : ${CHARS[char_id].tags[tag_key]}' with '${new_value}' for '${CHARS[char_id].name}'`);
                        CHARS[char_id].tags[tag_key] = new_value;
                    } else if (new_value === null) {
                        if (CHARS[char_id].tags.hasOwnProperty(tag_key)) {
                            console.log(`removing character tag '${tag_key} : ${CHARS[char_id].tags[tag_key]}' for '${CHARS[char_id].name}'`);
                            delete CHARS[char_id].tags[tag_key];
                        }
                    } else {
                        console.warn(`Trying to update character tag '${tag_key}' with unexpected value: ${new_value}`, arguments);
                    }
                } else {
                    console.warn(`Trying to update character tag with blank key: ${tag_key}`, arguments);
                }
            }
        } else {
            console.warn(`Trying to update non-existent character ID: ${char_id}`, arguments);
        }
    }
}

const _GLOBAL_VARS_REQUIRED_KEYS = ["name", "type", "init"];
const _SUPPORTED_VARIABLE_TYPES  = ["num", "str", "bool"]; 
function sort_global_variables(){
    var variables = PROJECT.resources.variables;
    for (const var_id in variables) {
        if ( variables.hasOwnProperty(var_id) ) {
            if (
                object_has_keys_all( variables[var_id], _GLOBAL_VARS_REQUIRED_KEYS ) &&
                _SUPPORTED_VARIABLE_TYPES.includes( variables[var_id].type )
            ){
                VARS[var_id] = variables[var_id];
                VARS[var_id].value = variables[var_id].init; // Make it ready to change
                refresh_console_attribute_of(variables[var_id].name, VARS[var_id].value);
            } else {
                throw new Error(`Unable to sort global variables! The variable '${var_id}' resource doesn't include required data! ${ _GLOBAL_VARS_REQUIRED_KEYS.join(", ") }`);
            }
        }
    }
}

function update_global_variable_by_id(var_id, new_value){
    if ( VARS.hasOwnProperty(var_id) ){
        // Type checking...
        var var_type = VARS[var_id].type;
        if (
            ( var_type == 'str'  && typeof new_value == 'string'  ) ||
            ( var_type == 'num'  && Number.isInteger(new_value)   ) ||
            ( var_type == 'bool' && typeof new_value == 'boolean' )
        ) {
            // ... then updating
            var var_name = VARS[var_id].name;
            VARS[var_id].value = new_value;
            refresh_console_attribute_of(var_name, new_value);
            if (_VERBOSE) console.log("Variable Updated: ", var_name, "=", new_value);
        } else {
            throw new Error(`Unable to Update Global Variable! Type Inconsistency: new value ${new_value}<${typeof new_value}> for ${var_id}<${var_type}>`);
        }
    } else {
        throw new Error(`Unable to Update Global Variable by ID: No variable with ID '${var_id}'`);
    }
}

function update_global_variable_by_name(var_name, new_value){
    var var_uid = null
    for (const uid in VARS) {
        if ( VARS[uid].name === var_name ) {
            var_uid = uid;
            break;
        }
    }
    if ( var_uid !== null ){
        update_global_variable_by_id(var_uid, new_value);
    } else {
        throw new Error(`Unable to Update Global Variable by Name: No variable with name '${var_name}'`);
    }
}

function exposure(text){
    if ( typeof text == 'string' ){
        for (const var_id in VARS) {
            text = text.replaceAll(`{${VARS[var_id].name}}`, VARS[var_id].value);
        }
        for (const char_id in CHARS) {
            var char_name = CHARS[char_id].name;
            for (const tag_key in CHARS[char_id].tags){
                text = text.replaceAll(`{${char_name}.${tag_key}}`, CHARS[char_id].tags[tag_key]);
            }
        }
        return text;
    } else {
        throw new Error("Unable to process exposure: the text shall be of type string.");
    }
}

function refresh_console_attribute_of(var_name, new_value){
    DOME.CONSOLE.setAttribute( `data-${ escape_name(var_name) }`, ( typeof new_value == 'string' ? new_value : new_value.toString() ) );
}

// Project Validation
const PROJECT_DATA_MANDATORY_FIELDS = [ "title", "entry", "meta", "resources" ];
const PROJECT_DATA_RESOURCES_MANDATORY_SETS = [ "scenes", "nodes", "variables", "characters" ];
const DATASET_ITEM_MANDATORY_FIELDS_FOR_SET = {
    "scenes": [ "name", "entry", "map" ],
    "nodes": [ "type", "name", "data" ],
    "variables": [ "name", "type", "init" ],
    "characters": [ "name", "color" ]
};
function validate_project_data(project){
    if ( !project ) project = PROJECT;
    // Note: only essential validation (node type related checks shall be done by the respective module)
    if ( typeof project == 'object' ){
        if ( object_has_keys_all(project, PROJECT_DATA_MANDATORY_FIELDS ) ) {
            if ( object_has_keys_all(project.resources, PROJECT_DATA_RESOURCES_MANDATORY_SETS ) ){
                if (
                    Number.isInteger(project.entry) && project.resources.nodes.hasOwnProperty(project.entry)
                ){
                    for ( const set in project.resources ){
                        if ( project.resources.hasOwnProperty(set) ) {
                            for ( const uid in project.resources[set] ){
                                if ( project.resources[set].hasOwnProperty(uid) ){
                                    if (
                                        ( safeInt(uid, -1) < 0 ) ||
                                        ( typeof project.resources[set][uid] != 'object' ) ||
                                        ( object_has_keys_all( project.resources[set][uid], DATASET_ITEM_MANDATORY_FIELDS_FOR_SET[set] ) != true )
                                    ){
                                        // Doesn't pass general dataset checks
                                        return false;
                                    } else {
                                        // Passes? What about dataset special checks?
                                        switch (set){
                                            case "scenes":
                                                for ( const map_uid in project.resources[set][uid].map ){
                                                    if (
                                                        ( safeInt(map_uid, -1) < 0 ) ||
                                                        ( typeof project.resources[set][uid].map[map_uid] != 'object' ) /* ||
                                                        (
                                                            // A valid project requires valid offsets but,
                                                            // offsets are not required for this runtime to work. We can safely ignore them ...
                                                            project.resources[set][uid].map[map_uid].hasOwnProperty("offset") != true ||
                                                            Array.isArray(project.resources[set][uid].map[map_uid].offset) != true ||
                                                            project.resources[set][uid].map[map_uid].offset.length != 2 // [x, y]
                                                            )
                                                        */
                                                    ){
                                                        return false;
                                                    }
                                                }
                                                break;
                                            case "nodes":
                                                if ( typeof project.resources[set][uid].data != 'object'){
                                                    return false;
                                                }
                                                break;
                                            case "variables":
                                                // Nothing special at the time
                                                break;
                                            case "characters":
                                                // Ditto
                                                break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    // Passes all
                    return true;
                }
            }
        }
    }
    // Passes none!
    return false;
}

function get_resource_by_id(res_id, priority_field) {
    var resource = null;
    // Optimization: Search in the priority_field first, where the resource most likely is
    // (defaults to `nodes`.)
    if ( typeof priority_field != "string" || priority_field.length == 0 || PROJECT.resources.hasOwnProperty(priority_field) == false ) priority_field = "nodes";
    if ( PROJECT.resources[priority_field].hasOwnProperty(res_id) ) {
        resource = PROJECT.resources[priority_field][res_id];
    } else {
        for (const field in PROJECT.resources) {
            if (PROJECT.resources.hasOwnProperty(field)) {
                if ( PROJECT.resources[field].hasOwnProperty(res_id) ){
                    resource = PROJECT.resources[field][res_id];
                }
            }
        }
    }
    return resource;
}

function get_owner_scene_of(node_id, only_return_scene_id){
    var scenes = PROJECT.resources.scenes;
    for (const scene_id in scenes) {
        if (scenes.hasOwnProperty(scene_id)) {
            if ( scenes[scene_id].map.hasOwnProperty(node_id) ){
                if ( only_return_scene_id === true ){
                    return scene_id;
                }
                return scenes[scene_id];
            }
        }
    }
    return null;
}

function get_node_map_by_id(node_id){
    var owner_scene = get_owner_scene_of(node_id);
    if (owner_scene){
        if ( owner_scene.hasOwnProperty("map") && owner_scene.map.hasOwnProperty(node_id) ){
         return owner_scene.map[node_id];   
        } else {
            return null;
        }
    } else {
        throw new Error(`Unable to get node (${node_id}) map: It belongs to no scene!`);
    }
}

function escape_name(name){
    if ( typeof name == 'string' && name.length > 0 ){
        return name.toLowerCase().replace(/\W/gi, "-");
    } else {
        throw new Error("Unable to scape the name. It must be a string longer than 0 chars.");
    }
}

function update_ui_open_nodes_list(new_child_name, clean_previous_ones){
    if (clean_previous_ones === true){
        OPEN_NODES_REFORMATTED_NAMES = [];
    }
    if (new_child_name && typeof new_child_name == 'string'){
        OPEN_NODES_REFORMATTED_NAMES.push( escape_name(new_child_name) );
    }
    DOME.CONTENT.setAttribute("data-open-nodes", OPEN_NODES_REFORMATTED_NAMES.join(' '));
}

// Clears view by removing all the appended nodes before the one with resource-uid passed as `the_last_one_id`.
function clear_up(the_last_one_id){
    var last_idx = 0;
    for(var l = OPEN_NODES_BY_ORDER.length - 1; l >= 0; l--){
        if ( OPEN_NODES_BY_ORDER[l].id == the_last_one_id ){
            last_idx = l;
            break;
        }
    }
    if ( last_idx > 0 ){
        OPEN_NODES_REFORMATTED_NAMES.splice(0, last_idx);
        var removed_ones = OPEN_NODES_BY_ORDER.splice(0, last_idx);
        for (var node of removed_ones) {
            node.instance.remove_element();
        }
        update_ui_open_nodes_list();
        if ( OPEN_NODES_BY_ORDER.length == 1){ // there is only one remained node!
            // make sure it's playable (Note: currently only content nodes clear up)
            OPEN_NODES_BY_ORDER[0].instance.step_back();
        }
    } else {
        throw new Error(`The annotated node (${the_last_one_id}) is not open or is the first one. We can only clean view from a node backward.`);
    }
}

function scroll_into_view(element){
    ( element || document.activeElement ).scrollIntoView({
        behavior: 'smooth',
        block: 'center',
        inline: 'center'
    });
}

var OPEN_MACRO = null;

function play_node(node_id, _playing_in_slot){
    var error, node_resource, node_map, instance;
    node_id = safeInt(node_id);
    _playing_in_slot = safeInt(_playing_in_slot);
    node_resource = get_resource_by_id(node_id);
    node_map = get_node_map_by_id(node_id);
    if ( node_id >= 0 ){
        if ( NODE_CLASSES_BY_TYPE.hasOwnProperty(node_resource.type) ){
            instance = new NODE_CLASSES_BY_TYPE[node_resource.type](
                node_id, node_resource, node_map, _playing_in_slot
            );
            // Macros need special treatments
            var handled_by_macro = false;
            if ( OPEN_MACRO ){
                if ( OPEN_MACRO.owns_node(node_id) ){
                    OPEN_MACRO.append_instance(instance);
                    handled_by_macro = true;
                } else { // We must have left the macro by jumping to a node outside, so ...
                    OPEN_MACRO.set_view_played();
                    OPEN_MACRO = null;
                }
            }
            OPEN_NODES_BY_ORDER.push({
                id: node_id,
                resource: node_resource,
                instance: instance,
                wrapper: OPEN_MACRO,
            });
            update_ui_open_nodes_list(node_resource.name);
            var new_node_element = instance.get_element();
            if (handled_by_macro == false) {
                DOME.CONTENT.appendChild( new_node_element );
            }
            // Is the new node itself a macro ?
            if ( node_resource.type == 'macro_use' ) OPEN_MACRO = instance;
            // Finally, proceed the node to auto-play, skip, etc.
            instance.proceed();
            scroll_into_view(new_node_element);
        } else {
            error = "Node Instancing Failed! The node type might be invalid.";
        }
    } else {
        error = "Invalid Node Resource!";
    }
    if (error){
        if (_VERBOSE) console.error(node_id, node_resource);
        throw new Error(error + ` Unable to play the node (${node_id}.)`);
    }
}

// More global constants
const _CONSOLE_STATUS_CODE = {
    "END_EDGE" : 0, // disconnected outgoing slot
	"NO_DEFAULT" : 1 // no default action is taken (e.g. due to being skipped)
};
function handle_status(status_code, the_player_node_instance){
    switch (status_code) {
        case _CONSOLE_STATUS_CODE.END_EDGE:
            if ( OPEN_MACRO && OPEN_MACRO != the_player_node_instance ){
                // This is most likely the end of a `macro_use` in a scene,
                // so there might be still more to play on the parent scene:
                OPEN_MACRO.play_self_forward();
            } else {
                var node_name = the_player_node_instance.node_resource.name;
                console.log(`EOL: ${node_name}`);
                if ( DO_NOT_PRINT_EOL_MESSAGE !== true ){
                    DOME.CONTENT.appendChild(
                        create_element(
                            'div',
                            format( i18n('eol_node'), { "node_name": node_name } ),
                            { class: 'eol' }
                        )
                    );
                }
            }
            break;
        case _CONSOLE_STATUS_CODE.NO_DEFAULT:
            if (_VERBOSE) {
                console.log(
                    `Node '${the_player_node_instance.node_resource.name}' has no action and no default!\n`+
                    'The node may be skipped or has unset/invalid parameters.'
                );
            }
            break;
    }
}

function play_back(steps, default_throw_error){
    var error = null;
    var open_nodes_count = OPEN_NODES_BY_ORDER.length;
    if ( open_nodes_count > 1 ){
        if ( Number.isInteger(steps) == false || steps < 1 || steps >= open_nodes_count ){
            steps = 1;
            if (_VERBOSE) console.warn("Unset or too many steps back. Reset to 1.");
        }
        // Now we step back
        var remove_threshold = ( open_nodes_count - steps );
        OPEN_NODES_REFORMATTED_NAMES.splice(remove_threshold);
        var removed_ones = OPEN_NODES_BY_ORDER.splice(remove_threshold);
        for (var node of removed_ones) {
            node.instance.remove_element();
        }
        update_ui_open_nodes_list();
        // we also need to make the last open node manually playable,
        var last = OPEN_NODES_BY_ORDER[ remove_threshold - 1 ];
        if ( last.wrapper != null ) {
            OPEN_MACRO = last.wrapper; // (with special cares)
            OPEN_MACRO.step_into();
        } else if (OPEN_MACRO != null && OPEN_MACRO.node_id != last.id){
            OPEN_MACRO.set_view_played();
            OPEN_MACRO = null;
        } else if ( last.resource.type == 'macro_use' ) {
            OPEN_MACRO = last.instance;
        }
        last.instance.step_back();
    } else {
        error = "There is only one remained open node! We can't step back anymore.";
    }
    if (error && default_throw_error != false) throw new Error(error);
}

var DARKMODE = false;
function switch_dark_mode(force){
    DARKMODE = ( typeof force === 'boolean' ? force : ( ! DARKMODE ) );
    ROOT.setAttribute( 'data-theme', ( DARKMODE ? 'dark' : 'light' ) );
    window.localStorage['_arrow_runtime_darkmode'] = DARKMODE; // jshint ignore: line
}

// Runtime
const runtime = function(){

    // Preparation
        // Making references for dry access
    DOME.CONSOLE = document.getElementById("console");
    DOME.CONTENT = document.getElementById("content");
        // Make sure _LOCALE is supported, otherwise stop running the project with an error
    if ( _SUPPORTED_LOCALES.includes(_LOCALE) == false ){
        throw new Error (`The set _LOCALE (${_LOCALE}) is not supported! To add a new one, edit i18n module.`);
    }
    // Then trying to run the project from its entry node
    var error_running = null;
    if ( typeof PROJECT == "object" && validate_project_data() === true ){
        sort_global_variables();
        sort_characters();
        play_node( PROJECT.entry );
        if (_VERBOSE) console.log(`Project Validation [OK]. Running from the project's entry node (${PROJECT.entry}) ...`);
    } else {
        error_running = "Project Data seems Corrupt !!";
    }
    if (error_running) throw new Error("Unable to Run the Project: " + error_running);

    // Control Buttons
    // Dark-mode
    try {
        const DARK_MODE_SWITCH = document.getElementById('switch-dark-mode');
        if ( DARK_MODE_SWITCH ) {
            DARK_MODE_SWITCH.addEventListener(_CLICK, switch_dark_mode);
            if ( window.localStorage && '_arrow_runtime_darkmode' in window.localStorage ){
                switch_dark_mode(
                    ( window.localStorage._arrow_runtime_darkmode === 'true' ||
                      window.localStorage._arrow_runtime_darkmode === true // really ?!
                    ) ? true : false
                );
            }
        }
    } catch (error){
        if (_VERBOSE) console.warn("Dark-mode is Not Available! The `#switch-dark-mode` button is missing.");
    }
    // Back
    try {
        const PLAY_BACK_BUTTON = document.getElementById('play-back');
        if ( PLAY_BACK_BUTTON ) {
            PLAY_BACK_BUTTON.addEventListener( _CLICK, play_back.bind(null, 1, false) );
        }
    } catch (error){
        if (_VERBOSE) console.warn("Play-Back is Not Available! The `#play-back` button is missing.");
    }

};

// Run the `runtime` function when the page is loaded
window.addEventListener("load", runtime);
