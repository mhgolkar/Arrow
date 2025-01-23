// Arrow HTML-JS Runtime: Variable-Update node module

class VariableUpdate {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;
        
        const ONLY_PLAY_SLOT = 0;
        
        const UNSET_EXPRESSION_MESSAGE = "Parameters unset or invalid!";

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

        this.evaluation_and_play = function(){
            var new_value = null;
            if ( this.update_expression ) {
                new_value = this.update_expression.evaluate();
                // ... It may result in `null` (e.g. if the expression is unset.)
            }
            if ( new_value !== null && this.the_variable ){
                update_global_variable_by_id(this.the_variable_id, new_value);
                this.play_forward();
            } else {
                console.error(`Unable to evaluate the variable_update (${this.node_resource.name}) expression. Skipped forward.`);
                this.skip_play();
            }
        };
        
        this.proceed = function(){
            if (_ALLOW_AUTO_PLAY) {
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play();
                } else {
                    this.evaluation_and_play();
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
                this.update_expression = null;
                if ( this.node_resource.hasOwnProperty("data") && this.node_resource.data.hasOwnProperty("variable") ){
                    this.the_variable_id = safeInt(this.node_resource.data.variable);
                    try {
                        this.update_expression = new VariableUpdateExpression(this.node_resource.data, VARS);
                        this.the_variable = this.update_expression.variable;
                        this.previous_variable_value = this.the_variable.value;
                    } catch(err){
                        if (_VERBOSE) console.warn('Invalid Variable_Update Expression. Error:' + err);
                    }
                }
                // Create the node html element
                this.html = create_node_base_html(node_id, node_resource);
                    // ... and the children
                    // Parsed VariableUpdate Expression:
                    if ( this.update_expression ){
                        var parsed_update_expression = (this.update_expression.parse() || UNSET_EXPRESSION_MESSAGE);
                        this.parsed_expression = create_element("code", parsed_update_expression, {"class": "expression"});
                        this.html.appendChild(this.parsed_expression);
                    }
                    // Manual Evaluation Button:
                    this.eval_button = create_element("button", i18n("evaluate"));
                    this.eval_button.addEventListener( _CLICK, this.evaluation_and_play.bind(_self) );
                    this.html.appendChild(this.eval_button);
                    // and skip button (used in manual play and step-backs)
                    this.skip_button = create_element("button", i18n("skip"));
                    this.skip_button.addEventListener( _CLICK, this.skip_play.bind(_self) );
                    this.html.appendChild(this.skip_button);
                    // ...
            }
            return this;
        }
        throw new Error("Unable to construct `VariableUpdate`");
    }
}


class VariableUpdateExpression {
    
    constructor(data, variables){

        const _self = this;

        this.data = null;
        this.variable = null;

        const PARAMETER_MODES_ENUM = {
            0: "value",
            1: "variable"
        };
        const PARAMETER_MODES_ENUM_CODE = {
            "value": 0,
            "variable": 1
        };

        const UPDATE_OPERATORS = {
            "num": {
                "set": { "text": "Set Equal", "sign": "=" },
                "add": { "text": "Addition", "sign": "+=" },
                "sub": { "text": "Subtraction", "sign": "-=" },
                "div": { "text": "Division", "sign": "/=" },
                "rem": { "text": "Remainder", "sign": "%=" },
                "mul": { "text": "Multiplication", "sign": "*=" },
                "exp": { "text": "Exponentiation", "sign": "^=" },
                "abs": { "text": "Absolute", "sign": "=||" },
            },
            "str": {
                "set": { "text": "Set", "sign": "=" },
                "stc": { "text": "Set Capitalized", "sign": "C=" },
                "stl": { "text": "Set Lowercased", "sign": "l=" },
                "stu": { "text": "Set Uppercased", "sign": "U=" },
                "ins": { "text": "Insert Right", "sign": "=+" },
                "inb": { "text": "Insert Left", "sign": "+=" },
                "rmc": { "text": "Remove Left", "sign": "-=" },
                "rml": { "text": "Remove Left (Case Insensitive)", "sign": "-~" },
                "rmr": { "text": "Remove Right", "sign": "=-" },
                "rmi": { "text": "Remove Right (Case Insensitive)", "sign": "~-" },
                "rpl": { "text": "Replace", "sign": "=*" },
                "rpi": { "text": "Replace (Case Insensitive)", "sign": "~*" },
            },
            "bool": {
                "set": { "text": "Set", "sign": "=" },
                "neg": { "text": "Set Negative", "sign": "=!" },
            },
        };

        const KEYS_NEEDED_TO_PARSE = ["variable", "operator", "with"];
        
        const EXPRESSION_TEMPLATE = "{ident} {operator_sign} {parameter}";
        const UPDATED_WITH_SELF_INITIAL_RIGHT_SIDE = "Self (Initial Value)";
        
        const STRING_VALUE_FORMATTING_TEMPLATE = "`%s`";
    
        this.parse = function(){
            var parsed = null;
            if ( this.variable && this.data ) {
                this.expression = { "ident": null, "operator_sign": null, "parameter": null };
                this.expression.ident = this.variable.name;
                if ( UPDATE_OPERATORS[this.variable.type].hasOwnProperty(this.data.operator) ){
                    this.expression.operator_sign = UPDATE_OPERATORS[this.variable.type][this.data.operator].sign;
                }
                switch ( this.data.with[0] ){
                    case PARAMETER_MODES_ENUM_CODE.value:
                        if (this.variable.type == "str"){
                            this.expression.parameter = STRING_VALUE_FORMATTING_TEMPLATE.replace("%s", this.data.with[1]);
                        } else {
                            this.expression.parameter = this.data.with[1];
                        }
                        break;
                    case PARAMETER_MODES_ENUM_CODE.variable:
                        if ( this.data.with[1] == this.data.variable) { // the variable is compared to self (initial value)
                            this.expression.parameter = UPDATED_WITH_SELF_INITIAL_RIGHT_SIDE;
                        } else { // or another variable
                            if ( VARS.hasOwnProperty(this.data.with[1]) ) {
                                var parameter_var = VARS[ this.data.with[1] ];
                                this.expression.parameter = parameter_var.name;
                            }
                        }
                        break;
                }
                for (const key in this.expression) {
                    if ( this.expression.hasOwnProperty(key) ) {
                        if ( this.expression[key] === null ){
                            this.expression = null;
                            break;
                        }
                    }
                }
                parsed = (this.expression ? format(EXPRESSION_TEMPLATE, this.expression) : null );
            }
            return parsed;
        };
            
        this.evaluators = {
            "str": function(left, operation, right){ 
                var result = null;
                switch (operation) {
                    case "set": // Set (=)
                        result = right;
                        break;
                    case "stc": // Set Capitalized (C=)
                        result = capitalize(right);
                        break;
                    case "stl": // Set Lowercased (l=)
                        result = right.toLowerCase();
                        break;
                    case "stu": // Set Uppercased (u=)
                        result = right.toUpperCase();
                        break;
                    case "ins": // Insert Right (=+)
                        result = ( left + right );
                        break;
                    case "inb": // Insert Left (+=)
                        result = ( right + left );
                        break;
                    case "rmc": // Remove Left (-=)
                        var rem_idx = left.indexOf(right);
                        if (rem_idx >= 0){
                            result = left.substring(0, rem_idx) + left.substring(rem_idx + right.length);
                        } else {
                            result = left;
                        }
                        break;
                    case "rml": // Remove Left _Case Insensitive_ (-~)
                        var rem_idx = left.toLowerCase().indexOf(right.toLowerCase());
                        if (rem_idx >= 0){
                            result = left.substring(0, rem_idx) + left.substring(rem_idx + right.length);
                        } else {
                            result = left;
                        }
                        break;
                    case "rmr": // Remove Right (=-)
                        var rem_idx = left.lastIndexOf(right);
                        if (rem_idx >= 0){
                            result = left.substring(0, rem_idx) + left.substring(rem_idx + right.length);
                        } else {
                            result = left;
                        }
                        break;
                    case "rmi": // Remove Right _Case Insensitive_ (~-)
                        var rem_idx = left.toLowerCase().lastIndexOf(right.toLowerCase());
                        if (rem_idx >= 0){
                            result = left.substring(0, rem_idx) + left.substring(rem_idx + right.length);
                        } else {
                            result = left;
                        }
                        break;
                    case "rpl": // Replace (=*)	
                        var replacement = right.split("|");
                        if (replacement.length == 1){ replacement.push(""); }
                        result = left.replaceAll(replacement[0], replacement[1]);
                        break;
                    case "rpi": // Replace _Case Insensitive_ (~*)
                        var replacement = right.split("|");
                        if (replacement.length == 1){ replacement.push(""); }
                        var escaped_replacement = replacement[0].replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
                        replacement[0] = new RegExp(escaped_replacement, 'ig');
                        result = left.replace(replacement[0], replacement[1]);
                        break;
                }
                return result;
            },
            "num": function(left, operation, right){
                var result = null;
                switch (operation) {
                    case "set": // Set Equal (=)
                        result = right;
                        break;
                    case "add": // Addition (+=)
                        result = (left + right);
                        break;
                    case "sub": // Subtraction (-=)
                        result = (left - right);
                        break;
                    case "div": // Division (/=)
                        result = Math.floor(left / right);
                        break;
                    case "rem": // Remainder (%=)
                        result = (left % right);
                        break;
                    case "mul": // Multiplication (*=)
                        result = (left * right);
                        break;
                    case "exp": // Exponentiation (^=)
                        result = Math.pow(left, right);
                        break;
                    case "abs": // Absolute (=||)
                        result = Math.abs(right);
                        break;
                }
                return ( Number.isFinite(result) ? Math.round(result) : null );
            },
            "bool": function(left, operation, right){
                var result = null;
                switch (operation){
                    case "set": // Set (=)
                        result = right;
                        break;
                    case "neg": // Set Negative (=!)
                        result = ( ! right );
                        break;
                }
                return result;
            }
        };

        this.evaluate = function(){
            var result = null;
            if ( this.variable ){
                var type  = this.variable.type;
                var value = this.variable.value;
                var with_value;
                switch ( this.data.with[0] ) {
                    case PARAMETER_MODES_ENUM_CODE.value:
                        with_value = this.data.with[1];
                        break;
                    case PARAMETER_MODES_ENUM_CODE.variable:
                        var the_second_variable_id = this.data.with[1];
                        if ( VARS.hasOwnProperty(the_second_variable_id) ){
                            if (the_second_variable_id == this.data.variable){
                                // with its own initial value
                                with_value = VARS[the_second_variable_id].init;
                            } else {
                                with_value = VARS[the_second_variable_id].value;
                            }
                        }
                        break;
                }
                if ( with_value !== null ) {
                    if ( type == "str" && ( typeof with_value != 'string') ){
                        with_value = with_value.toString();
                    } else if ( type == "num" && (typeof with_value != 'number') ){
                        with_value= safeInt(with_value, 0);
                    } else if ( type == "bool" && (typeof with_value != 'boolean') ){
                        with_value= safeBool(with_value);
                    }
                    if ( UPDATE_OPERATORS[type].hasOwnProperty(this.data.operator) ){
                        result = this.evaluators[type]( value, this.data.operator, with_value );
                    }
                }
            }
            return result;
        };

        if (
            object_has_keys_all(data, KEYS_NEEDED_TO_PARSE) && 
            Array.isArray(data.with) && data.with.length == 2  // with<array>[parameter_mode, parameter_value]
        ){
            this.data = data;
            var target_variable_id = safeInt(data.variable);
            if ( VARS.hasOwnProperty(target_variable_id) ){
                this.variable = VARS[data.variable];
            }
        } else {
            throw new Error( "Invalid VariableUpdate! Some of the required data is missing: " + KEYS_NEEDED_TO_PARSE.join(", ") );
        }
        
    }
    
}