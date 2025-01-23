// Arrow HTML-JS Runtime: Condition node module

class Condition {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;
        
        const FALSE_SLOT = 0;
        const TRUE_SLOT  = 1;
        
        const UNSET_CONDITION_MESSAGE = "Condition unset or invalid!";

        this.get_element = function () {
            return this.html;
        };
        
        this.remove_element = function() {
            this.html.remove();
        };
        
        this.play_forward_from = function(slot_idx){
            slot_idx = parseInt(slot_idx);
            if ( Number.isFinite(slot_idx) == false || slot_idx < 0 || slot_idx > 1 ){
                // We default to `false` anytime something is wrong but we can continue
                slot_idx = FALSE_SLOT; 
            }
            if ( this.slots_map.hasOwnProperty(slot_idx) ) {
                var next = this.slots_map[slot_idx];
                play_node(next.id, next.slot);
            } else {
                handle_status(_CONSOLE_STATUS_CODE.END_EDGE, _self);
            }
            this.set_view_played(slot_idx);
        };
        
        this.skip_play = function() {            
            // Skipped? The convention is to ...
            this.html.setAttribute('data-skipped', true);
            // ... react by playing the *False Slot First*
            if ( this.slots_map.hasOwnProperty(FALSE_SLOT) ){ // if false slot is connected
                this.play_forward_from(FALSE_SLOT);
            }
            else { // otherwise playing the *Only Remained [Possibly Connected] True Slot*
                this.play_forward_from(TRUE_SLOT); // which ...
            } // ... will naturally end the plot line if the true slot is not connected
        };
        
        this.set_view_played = function(){
            this.html.setAttribute('data-played', true);
        };
        
        this.set_view_unplayed = function(){
            this.html.setAttribute('data-played', false);
        };
        
        this.step_back = function(){
            this.html.setAttribute('data-skipped', false);
            this.set_view_unplayed();
        };

        this.evaluation_and_play = function(){
            var evaluation = null;
            if ( this.condition_statement ) {
                evaluation = this.condition_statement.evaluate();
                // ... It may result in `null` (e.g. if the statement is unset.)
            }
            if ( typeof evaluation != 'boolean' ) {
                evaluation = false; // reset to default `false` if there is no valid evaluation ...
                if (_VERBOSE) console.warn(`Evaluation of Condition (${this.node_resource.name}) Failed, therefore considered as 'False'.`);
            }
            this.play_forward_from(
                ( evaluation == true) ? TRUE_SLOT : FALSE_SLOT
            );
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
                // Sort stuff
                this.node_id = node_id;
                this.node_resource = node_resource;
                this.node_map = node_map;
                this.slots_map = remap_connections_for_slots( (node_map || {}), node_id );
                // Statement
                this.condition_statement = null;
                if ( this.node_resource.hasOwnProperty("data") ){
                    try {
                        this.condition_statement = new ConditionStatement(this.node_resource.data, VARS);
                    } catch(err){
                        if (_VERBOSE) console.warn('Unable to Parse Condition. Error:' + err);
                    }
                }
                // Create the node html element
                this.html = create_node_base_html(node_id, node_resource);
                    // ... and the children
                    // Parsed Condition Statement:
                    if ( this.condition_statement ){
                        var parsed_condition_statement = (this.condition_statement.parse() || UNSET_CONDITION_MESSAGE);
                        this.parsed_statement = create_element("code", parsed_condition_statement, {"class": "statement"});
                        this.html.appendChild(this.parsed_statement);
                    }
                    // False:
                    this.false_button = create_element("button", i18n("false"), { "value": "false" });
                    this.false_button.addEventListener( _CLICK, this.play_forward_from.bind(_self, FALSE_SLOT) );
                    this.html.appendChild(this.false_button);
                    // True:
                    this.true_button = create_element("button", i18n("true"), { "value": "true" });
                    this.true_button.addEventListener( _CLICK, this.play_forward_from.bind(_self, TRUE_SLOT) );
                    this.html.appendChild(this.true_button);
            }
            return this;
        }
        throw new Error("Unable to construct `Condition`");
    }

}

class ConditionStatement {

    /*  Note:
        (convention)
        length comparisons can get a str(int) as `with` value or a str(string)
        in the first case the stringified integer will be parsed as the length of the right-hand-side,
        and in the latter case, the `.length()` of the string will be used in the comparison.
    */

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
        
        const COMPARISON_OPERATORS = {
            "num": {
                "eq": { "text": "is Equal", "sign": "==" },
                "nq": { "text": "is Not Equal", "sign": "!=" },
                "gt": { "text": "is Greater", "sign": ">" },
                "gte": { "text": "is Greater or Equal", "sign": ">=" },
                "ls": { "text": "is Lesser", "sign": "<" },
                "lse": { "text": "is Lesser or Equal", "sign": "<=" },
            },
            "str": {
                "rgx":{ "text": "Matches RegEx Pattern", "sign": "~=" },
                "ct":{ "text": "Contains Substring", "sign": "%~" },
                "cts":{ "text": "Contains Substring (Case-Sensitive)", "sign": "%=" },
                "bgn":{ "text": "Begins with", "sign": "^=" },
                "end":{ "text": "Ends with", "sign": "=^" },
                "eql":{ "text": "Has Equal Length", "sign": "#=" },
                "lng":{ "text": "Is Longer", "sign": "#>" },
                "shr":{ "text": "Is Shorter", "sign": "#<" },
            },
            "bool": {
                "eq": { "text": "Conforms", "sign": "=="},
                "nq": { "text": "Doesn't Conform", "sign": "!="},
            },
        };

        const KEYS_NEEDED_TO_PARSE = ["variable", "operator", "with"];
        
        const STATEMENT_TEMPLATE = "{ident} {operator_sign} {parameter}";
        const COMPARED_TO_SELF_INITIAL_RIGHT_SIDE = "Self (Initial Value)";
        
        const STRING_VALUE_FORMATTING_TEMPLATE = "`%s`";
    
        this.parse = function(){
            var parsed = null;
            if ( this.variable && this.data ) {
                this.statement = { "ident": null, "operator_sign": null, "parameter": null };
                this.statement.ident = this.variable.name;
                if ( COMPARISON_OPERATORS[this.variable.type].hasOwnProperty(this.data.operator) ){
                    this.statement.operator_sign = COMPARISON_OPERATORS[this.variable.type][this.data.operator].sign;
                }
                switch ( this.data.with[0] ){
                    case PARAMETER_MODES_ENUM_CODE.value:
                        if (this.variable.type == "str"){
                            this.statement.parameter = STRING_VALUE_FORMATTING_TEMPLATE.replace("%s", this.data.with[1]);
                        } else {
                            this.statement.parameter = this.data.with[1];
                        }
                        break;
                    case PARAMETER_MODES_ENUM_CODE.variable:
                        if ( this.data.with[1] == this.data.variable) { // the variable is compared to self (initial value)
                            this.statement.parameter = COMPARED_TO_SELF_INITIAL_RIGHT_SIDE;
                        } else { // or another variable
                            if ( VARS.hasOwnProperty(this.data.with[1]) ) {
                                var parameter_var = VARS[ this.data.with[1] ];
                                this.statement.parameter = parameter_var.name;
                            }
                        }
                        break;
                }
                for (const key in this.statement) {
                    if ( this.statement.hasOwnProperty(key) ) {
                        if ( this.statement[key] === null ){
                            this.statement = null;
                            break;
                        }
                    }
                }
                parsed = (this.statement ? format(STATEMENT_TEMPLATE, this.statement) : null );
            }
            return parsed;
        };

        //  `evaluate_str_comparison` can give a number as input, but it comes from a textual input
        //  also it may compare two real strings (str variables) so we shall
        //  detect what user have had in mind:
        this.smart_length_parse = function(input){
            if ( typeof input == 'number' ){
                return safeInt(input, 0);
            } else if ( typeof input == 'string' ) {
                var parsed_input = parseInt(input);
                if ( parsed_input.toString() == input ){
                    // if input is only a number inputted as string, it will be returned as the length (parsed)
                    return parsed_input;
                } else { //  otherwise ...
                    //... the length of the string is the result
                    return input.length;
                }
            } else {
                return 0;
            }
        };
            
        this.evaluators = {
            "str": function(left, operation, right){ 
                var result = null;
                switch (operation) {
                    case "rgx": // Matches RegEx Pattern
                        try {
                            var regex = new RegExp(right);
                            result = ( left.search(regex) >= 0);
                        } catch(err) {
                            if (_VERBOSE){
                                console.warn(`Evaluation Failed! Bad RegEx Match Operation: ` + err);
                                console.warn(arguments);
                            }
                        }
                        break;                    
                    case "ct": // Contains Substring
                        var l = left.toLowerCase();
                        var r = right.toLowerCase();
                        result = (l.indexOf(r) >= 0);
                        break;
                    case "cts": // Contains Substring (Case-Sensitive)
                        result = (left.indexOf(right) >= 0);
                        break;
                    case "eql": // Has Equal Length
                        result = (left.length == _self.smart_length_parse(right));
                        break;
                    case "lng": // Is Longer
                        result = (left.length > _self.smart_length_parse(right));
                        break;
                    case "shr": // Is Shorter
                        result = (left.length < _self.smart_length_parse(right));
                        break;
                    case "bgn": // Begins with
                        result = string_begins_with(left, right);
                        break;
                    case "end": // Ends with
                        result = string_ends_with(left, right);
                        break;
                }
                return result;
            },
            "num": function(left, operation, right){
                var result = null;
                switch (operation) {
                    case "eq": // is Equal
                        result = ( left == right);
                        break;
                    case "nq": // is Not Equal
                        result = ( left != right);
                        break;
                    case "gt": // is Greater
                        result = ( left > right);
                        break;
                    case "gte": // is Greater or Equal
                        result = ( left >= right);
                        break;
                    case "ls": // is Lesser
                        result = ( left < right);
                        break;
                    case "lse": // is Lesser or Equal
                        result = ( left <= right);
                        break;
                }
                return result;
            },
            "bool": function(left, operation, right){
                var result = null;
                switch (operation){
                    case "eq":
                        result = (left == right);
                        break;
                    case "nq":
                        result = (left != right);
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
                                // compared to itself (self initial value)
                                with_value = VARS[the_second_variable_id].init;
                            } else {
                                with_value = VARS[the_second_variable_id].value;
                            }
                        }
                        break;
                }
                // now we have whatever we need, just make sure the compared value is right
                if ( with_value !== null ) {
                    if ( type == "str" && ( typeof with_value != 'string') ){
                        with_value = with_value.toString();
                    } else if ( type == "num" && (typeof with_value != 'number') ){
                        with_value= safeInt(with_value, 0);
                    } else if ( type == "bool" && (typeof with_value != 'boolean') ){
                        with_value= safeBool(with_value);
                    }
                    // lets evaluate for the type
                    if ( COMPARISON_OPERATORS[type].hasOwnProperty(this.data.operator) ){
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
            throw new Error( "Invalid Condition! Some of required data is missing: " + KEYS_NEEDED_TO_PARSE.join(", ") );
        }
        
    }
    
}
