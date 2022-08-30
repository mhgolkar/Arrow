// Arrow HTML-JS Runtime: Generator node module

class Generator {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;
        
        const ONLY_PLAY_SLOT = 0;
        
        const UNSET_EXPRESSION_MESSAGE = "Parameters unset or invalid!";
        const MAX_ARGS_PREVIEW_LENGTH = 10;

        const STRING_SET_DELIMITER = "|";
        const DEFAULT_CHARACTER_POOL = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz123456789";

        const VALID_GENERATORS = {
            "num": {
                "randi": {
                    "title": "Random Integer",
                    "func": function(args){
                        var result = null;
                        if (
                            Array.isArray(args) &&
                            args.length == 5
                        ){
                            if (
                                Number.isInteger(args[0]) && args[0] >= 0 &&
                                Number.isInteger(args[1]) && args[1] >= 2
                            ){
                                result = inclusiveRandInt(
                                    args[0],        // from
                                    (args[1] - 1), // to (exclusive)
                                    undefined,    // undefined base = 2
                                    args[2],     // negative,
                                    args[3],     // even
                                    args[4]     // odd
                                );
                            } else{
                                if (_VERBOSE) console.warn("Unexpected Behavior! Bad range for `randi` generator: ", args );
                            }
                        } else {
                            if (_VERBOSE) console.warn("Unexpected Behavior! Wrong arguments for `randi` generator: ", args );
                        }
                        if (result === null) {
                            result = inclusiveRandInt(0, 100); // so returns even on corrupt arguments
                        }
                        return result;
                    },
                    "args": function(data) {
                        if (data.hasOwnProperty("arguments") && Array.isArray(data.arguments) && data.arguments.length == 5){
                            var args = data.arguments;
                            return `: [${args[0]}, ${args[1]}] ${args[2] ? "N" : ""}${args[3] ? "E" : ""}${args[4] ? "O": ""}`;
                        } else {
                            return "(Invalid)"
                        }
                    },
                },
            },
            "str": {
                "ascii": {
                    "title": "Random ASCII String",
                    "func": function(args){
                        var result = "";
                        if (args.length == 2){
                            var char_pool = (typeof args[0] == "string" && args[0].length > 0) ? args[0] : DEFAULT_CHARACTER_POOL;
                            var char_pool_length = char_pool.length;
                            var desired_length = (typeof args[1] == "number" && args[1] >= 1) ? Math.floor(args[1]) : char_pool_length;
                            while (result.length < desired_length){
                                let char_pos = inclusiveRandInt(0, char_pool_length - 1);
                                console.log(char_pos);
                                result = ( result + char_pool[ char_pos ] );
                            }
                        }
                        return result;
                    },
                    "args": function(data) {
                        if (data.hasOwnProperty("arguments") && Array.isArray(data.arguments) && data.arguments.length == 2){
                            return `: ${data.arguments[1]} of \`${ellipsis(data.arguments[0].length > 0 ? data.arguments[0] : DEFAULT_CHARACTER_POOL, MAX_ARGS_PREVIEW_LENGTH)}\``;
                        } else {
                            return "(Invalid)"
                        }
                    },
                },
                "strst": {
                    "title": "From Set of Strings",
                    "func": function(stringified_set){
                        var result = "";
                        if (typeof stringified_set == "string" && stringified_set.length > 0){
                            var string_set = stringified_set
                                            .split(STRING_SET_DELIMITER)
                                            .filter( (part) => { return part.length > 0; } );
                            if (string_set.length > 0){
                                result = string_set[ inclusiveRandInt(0, (string_set.length - 1)) ];
                            }
                        }
                        return result;
                    },
                    "args": function(data) {
                        if (data.hasOwnProperty("arguments") && typeof data.arguments == 'string' && data.arguments.length > 0){
					        return ": `" + ellipsis(data.arguments, MAX_ARGS_PREVIEW_LENGTH) + "`"
                        } else {
                            return "(Null/Invalid)"
                        }
                    },
                },
            },
            "bool": {
                "rnbln": {
                    "title": "Random Boolean",
                    "func": function(_null){
                        return (
                            Math.floor( Math.random() * 10 ) % 2 == 0
                        );
                    },
                    "args": function(data) {
                        return "" // No arguments to preview
                    },
                },
            },
        };

        this.the_variable = null;
        this.the_variable_id = null;
        this.previous_variable_value = null;

        this.get_element = function () {
            return this.html;
        };
        
        this.remove_element = function() {
            this.html.remove();
        };
        
        this.play_forward = function(){
            if ( this.slots_map.hasOwnProperty(ONLY_PLAY_SLOT) ) {
                var next = this.slots_map[ONLY_PLAY_SLOT];
                play_node(next.id, next.slot);
            } else {
                handle_status(_CONSOLE_STATUS_CODE.END_EDGE, _self);
            }
            this.set_view_played(ONLY_PLAY_SLOT);
        };
        
        this.skip_play = function() {
            this.html.setAttribute('data-skipped', true);
            // when skipped it *doesn't modify* the variable
            this.play_forward();
        };
        
        this.set_view_played = function(){
            this.html.setAttribute('data-played', true);
        };
        
        this.set_view_unplayed = function(){
            this.html.setAttribute('data-played', false);
        };
        
        this.step_back = function(){
            // reverse any variable update
            if ( this.the_variable && this.previous_variable_value !== null ){
                update_global_variable_by_id(this.the_variable_id, this.previous_variable_value);
            }
            this.html.setAttribute('data-skipped', false);
            this.set_view_unplayed();
        };

        this.generate_and_play = function(){
            var new_value = null;
            if ( this.valid_generator ) {
                new_value = this.valid_generator.func.call(
                    null,
                    this.node_resource.data.hasOwnProperty("arguments") ? this.node_resource.data.arguments : null
                );
                // ... It may result in `null` (e.g. if the expression is unset.)
            }
            if ( new_value !== null && this.the_variable ){
                update_global_variable_by_id(this.the_variable_id, new_value);
                this.play_forward();
            } else {
                console.error(`Unable to run the generator (${this.node_resource.name}.) Skipped forward.`);
                this.skip_play();
            }
        };
        
        this.proceed = function(){
            if (_ALLOW_AUTO_PLAY) {
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play();
                } else {
                    this.generate_and_play();
                }
            }
        };
        
        if ( node_id >= 0 ){
            if ( typeof node_resource == 'object' && typeof node_map == 'object' ){
                this.node_id = node_id;
                this.node_resource = node_resource;
                this.node_map = node_map;
                this.slots_map = remap_connections_for_slots( (node_map || {}), node_id );
                // Expression
                this.valid_generator = null;
                if ( this.node_resource.hasOwnProperty("data") && this.node_resource.data.hasOwnProperty("variable") ){
                    this.the_variable_id = safeInt(this.node_resource.data.variable);
                    if ( VARS.hasOwnProperty(this.the_variable_id) ) {
                        this.the_variable = VARS[ this.the_variable_id ];
                        this.previous_variable_value = this.the_variable.value;
                        if (
                            this.node_resource.data.hasOwnProperty("method") &&
                            this.the_variable.hasOwnProperty("type") &&
                            VALID_GENERATORS.hasOwnProperty(this.the_variable.type) &&
                            VALID_GENERATORS[this.the_variable.type].hasOwnProperty(this.node_resource.data.method)
                        ){
                            this.valid_generator = VALID_GENERATORS[this.the_variable.type][this.node_resource.data.method];
                        }
                    } else {
                        if (_VERBOSE) console.warn(
                            "Invalid Generator Node! The node has nonexistent UID as the target variable:",
                            this.the_variable_id,
                            this.node_resource
                        );
                    }
                } else {
                    if (_VERBOSE) console.warn(
                        "Invalid Generator Node! The node has no data set or target variable.",
                        this.node_resource
                    );
                }
                // Create the node html element
                this.html = create_node_base_html(node_id, node_resource);
                    // ... and the children
                    // Parsed VariableUpdate Expression:
                    var parsed_valid_generator = (
                        this.valid_generator ?
                        `${this.the_variable.name} = ${this.valid_generator.title} ${this.valid_generator.args(this.node_resource.data)}`
                        : UNSET_EXPRESSION_MESSAGE
                    );
                    this.parsed_expression = create_element("code", parsed_valid_generator, { "class": "expression" });
                    this.html.appendChild(this.parsed_expression);
                    // Manual Evaluation Button:
                    this.eval_button = create_element("button", i18n("generate"));
                    this.eval_button.addEventListener( _CLICK, this.generate_and_play.bind(_self) );
                    this.html.appendChild(this.eval_button);
                    // and skip button (used in manual play and step-backs)
                    this.skip_button = create_element("button", i18n("skip"));
                    this.skip_button.addEventListener( _CLICK, this.skip_play.bind(_self) );
                    this.html.appendChild(this.skip_button);
            }
            return this;
        }
        throw new Error("Unable to construct `VariableUpdate`");
    }

}
