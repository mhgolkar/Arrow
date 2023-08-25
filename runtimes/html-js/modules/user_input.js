// Arrow HTML-JS Runtime: User-Input node module

class UserInput {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;
        
        this.the_variable_id = null;
        this.the_variable = null;
        this.previous_variable_value = null;

        const ONLY_PLAY_SLOT = 0;
        const INVALIDATE_EMPTY_STRING = false;

        const INPUT_LISTENER_EVENT  = 'input';

        const INPUT_PER_VARIABLE_TYPE = {
            'str': 'text',
            'num': 'number',
            'bool': 'checkbox'
        };

        const DEFAULT_INPUT_PROPERTIES = {
            "str": [undefined, "", ""],
            "num": [undefined, undefined, 1, 0],
            "bool": [ i18n('user_input_default_bool_negative'), i18n('user_input_default_bool_positive'), true],
        };

        this.get_element = function () {
            return this.html;
        };
        
        this.remove_element = function() {
            this.html.remove();
        };

        this.get_input_custom_properties = function() {
            return (
                (
                    this.node_resource.hasOwnProperty("data") &&
                    this.node_resource.data.hasOwnProperty("custom") &&
                    Array.isArray(this.node_resource.data.custom)
                ) ? this.node_resource.data.custom : []
            );
        };

        this.read_and_parse_value = function(){
            if (this.the_variable && this.input_element){
                switch ( this.the_variable.type ){
                    case 'str':
                        return this.input_element.value;
                    case 'num':
                        return safeInt(this.input_element.value, Number.NEGATIVE_INFINITY, true);
                    case 'bool':
                        return this.input_element.checked;
                }
            } else {
                throw new Error("Invalid Call! There is no variable or input element!");
            }
        };

        this.str_validator = function(){
            var is_valid = true;
            var value = this.read_and_parse_value();
            if ( INVALIDATE_EMPTY_STRING === true && value.length == 0 ){
                is_valid = false;
            } else {
                var custom = this.get_input_custom_properties();
                if (custom.length >= 1){
                    var pattern = custom[0];
                    if ( typeof pattern == 'string' ) {
                        if (pattern.length > 0){ // Blank patterns are ignored (pass everything)
                            var matches = value.match( new RegExp( pattern, "g" ) )
                            if (
                                Array.isArray(matches) == false || matches.length == 0 ||
                                matches[0] != value
                            ){
                                is_valid = false;
                            }
                        }
                    } else {
                        console.error(
                            this.node_id, "We can only accept RegExp strings as pattern.", this.node_resource
                        );
                        is_valid = false;
                    }
                }
            }
            return is_valid;
        };

        this.num_validator = function(){
            var is_valid = true;
            var value = this.read_and_parse_value();
            var error = undefined;
            if ( value == Number.NEGATIVE_INFINITY ){
                is_valid = false;
            } else {
                var custom = this.get_input_custom_properties();
                if (custom.length >= 3) {
                    for (var req = 0; req < 3; req++){
                        if (Number.isInteger(custom[req]) != true){
                            error = "All required values in custom for `num` [min, max, step, ...] shall be integers.";
                            is_valid = false;
                            break;
                        }
                    }
                    if (is_valid) { // (all integers, we can still proceed)
                        var min = custom[0], max = custom[1], step = custom[2];
                        if (min <= max) {
                            if (min == max) {
                                if (value != min) {
                                    is_valid = false;
                                }
                            } else { // ( min < max)
                                if (value < min || value > max) {
                                    is_valid = false;
                                } else { // is in range but is it stepped properly?
                                    if (step != 0 && ((value - min) % step) != 0) { // (zero step is ignored)
                                        is_valid = false;
                                    }
                                }
                            }
                        } else {
                            is_valid = false;
                            error = "`min` custom property shall be less or equal to `max`!";
                        }
                    }
                } else {
                    error = "We expect at least 3 numeral values [min, max, step, ...] to validate input.";
                    is_valid = false;
                }
            }
            if (error) { console.error(this.node_id, error, this.node_resource); };
            return is_valid;
        };

        this.bool_validator = function(){
            return ( typeof this.read_and_parse_value() == 'boolean' );
        };

        this.is_input_valid = function(){
            if (this.the_variable) {
                switch (this.the_variable.type) {
                    case 'str':
                        return this.str_validator();
                    case 'num':
                        return this.num_validator();
                    case 'bool':
                        return this.bool_validator();
                    default:
                        console.error(this.the_variable_id, this.the_variable)
                        throw new Error('Unsupported variable type!');
                }
            } else {
                // No variable (-1) can not be validated (strictly) and passes only on skip
                return false
            }
        };

        this.set_input_view = function() {
            if (this.the_variable) {
                var custom = this.get_input_custom_properties()
                var length = custom.length
                switch (this.the_variable.type) {
                    case 'str': // [pattern, default, extra]
                        const _STR_FIELDS = ["pattern", "value", "placeholder"]
                        for (var i = 0; i < _STR_FIELDS.length; i++) {
                            if (_STR_FIELDS[i] == "pattern" && custom[i].length == 0) {
                                // unlike html text input we consider blank string no enforced pattern,
                                // so we do not set the property; otherwise it would only accept blank strings.
                                continue;
                            };
                            if (_STR_FIELDS[i] != undefined) {
                                this.input_element[_STR_FIELDS[i]] = (
                                    length >= (i+1) && (typeof custom[i] == 'string')
                                    ? custom[i] : DEFAULT_INPUT_PROPERTIES["str"][i]
                                );
                            }
                        }
                        break;
                    case 'num': // [min, max, step, value]
                        const _NUM_FIELDS = ["min", "max", "step", "value"]
                        for (var i = 0; i < _NUM_FIELDS.length; i++) {
                            if (_NUM_FIELDS[i] != undefined) {
                                this.input_element[_NUM_FIELDS[i]] = (
                                    length >= (i+1) && Number.isInteger(custom[i]) ? custom[i] : DEFAULT_INPUT_PROPERTIES["num"][i]
                                );
                            }
                        }
                        break;
                    case 'bool': // [negative, positive, default-state]
                        this.input_element.checked = (length >= 3 ? custom[2] : DEFAULT_INPUT_PROPERTIES["bool"][2])
                        break;
                    default:
                        console.error(this.the_variable_id, this.the_variable)
                        throw new Error('Unsupported variable type!');
                }
                // and to apply:
                this.on_input_modification()
            } else {
                console.warn(`No variable is set for node ${this.node_id}`)
            }
        };

        this.reset_validity_state = function(force) {
            var validity = ((typeof force == 'boolean') ? force : this.is_input_valid());
            this.html.setAttribute('data-valid', validity);
            this.continue_button.disabled = (!validity)
        };

        this.on_input_modification = function() {
            this.reset_validity_state()
            // Switch boolean check-box label to current state as well:
            if (this.input_checkbox_label){
                var custom = this.get_input_custom_properties()
                var state_idx = (this.input_element.checked ? 1 : 0);
                this.input_checkbox_label.innerText = (
                    custom.length >= (state_idx + 1) && typeof custom[state_idx] == 'string'
                    ? custom[state_idx] : DEFAULT_INPUT_PROPERTIES["bool"][state_idx]
                )
            }
        };
        
        this.play_forward_from = function(_, skip){
            var valid = this.is_input_valid()
            if ( skip === true || valid == true ){
                if ( this.slots_map.hasOwnProperty( ONLY_PLAY_SLOT ) ) {
                    // update variable
                    if ( this.the_variable && valid && skip != true ){
                        update_global_variable_by_id( this.the_variable_id, this.read_and_parse_value() );
                    }
                    // then go for the next node
                    var next = this.slots_map[ONLY_PLAY_SLOT];
                    play_node(next.id, next.slot);
                } else {
                    handle_status(_CONSOLE_STATUS_CODE.END_EDGE, _self);
                }
                this.set_view_played(ONLY_PLAY_SLOT);
            } else {
                this.reset_validity_state(false)
            }
        };
        
        this.skip_play = function() {
            this.html.setAttribute('data-skipped', true);
            this.play_forward_from(ONLY_PLAY_SLOT, true);
        };
        
        this.set_view_played = function(slot_idx){
            this.html.setAttribute('data-played', true);
        };
        
        this.set_view_unplayed = function(){
            this.set_input_view()
            this.html.setAttribute('data-played', false);
        };
        
        this.step_back = function(){
            // reverse any variable update
            if ( this.the_variable && this.previous_variable_value !== null ){
                update_global_variable_by_id( this.the_variable_id, this.previous_variable_value );
            }
            this.html.setAttribute('data-skipped', false);
            this.set_view_unplayed();
        };
        
        this.proceed = function(){
            if (_ALLOW_AUTO_PLAY) {
                // `user_input` node type is pure interactive (there is no auto-play or default behavior,)
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    // if skipped, it means we just go to the next node as if this node didn't exist
                    this.skip_play();
                } // otherwise we shall wait for user interaction
            }
        };
        
        if ( node_id >= 0 ){
            if ( typeof node_resource == 'object' && typeof node_map == 'object' ){
                // Sort stuff
                this.node_id = node_id;
                this.node_resource = node_resource;
                this.node_map = node_map;
                this.slots_map = remap_connections_for_slots( (node_map || {}), node_id );
                // Create the node html element
                this.html = create_node_base_html(node_id, node_resource);
                    // ... and the children
                    var error = null;
                    if ( node_resource.hasOwnProperty('data') ){
                        // Prompt Message:
                        if ( node_resource.data.hasOwnProperty('prompt') ){
                            this.prompt_element = create_element("p", exposure(node_resource.data.prompt));
                            this.html.appendChild(this.prompt_element);
                        }
                        // Input
                        if ( node_resource.data.hasOwnProperty('variable') ){
                            this.the_variable_id = safeInt( node_resource.data.variable );
                            if ( VARS.hasOwnProperty( this.the_variable_id ) ){
                                this.the_variable = VARS[ this.the_variable_id ];
                                this.previous_variable_value = this.the_variable.value;
                                var input_html_type = INPUT_PER_VARIABLE_TYPE[ this.the_variable.type ];
                                var input_element_id = `${node_id}_input`;
                                this.input_element = create_element("input", null, {
                                    id: input_element_id,
                                    type: input_html_type
                                });
                                this.input_element.addEventListener( INPUT_LISTENER_EVENT, this.on_input_modification.bind(_self) );
                                this.html.appendChild(this.input_element);
                                if ( input_html_type == 'checkbox'){
                                    this.input_checkbox_label = create_element('label', null, {
                                        for: input_element_id
                                    });
                                    this.html.appendChild(this.input_checkbox_label);
                                }
                            } else {
                                error = "Invalid target variable id.";
                            }
                        }
                        // Continue Button
                        this.continue_button = create_element("button", i18n('continue'));
                        this.continue_button.addEventListener( _CLICK, this.play_forward_from.bind(_self) );
                        this.html.appendChild(this.continue_button);
                        // and skip button (used in manual play and step-backs)
                        this.skip_button = create_element("button", i18n("skip"));
                        this.skip_button.addEventListener( _CLICK, this.skip_play.bind(_self) );
                        this.html.appendChild(this.skip_button);
                        // ...
                        this.set_view_unplayed()
                    }
                    if ( error ) {
                        console.error(`Corrupt user_input node (${node_resource.name}) resource data: `, error, '\nNode set to be skipped.');
                        this.node_map.skip = true;
                    }
            }
            return this;
        }
        throw new Error("Unable to construct `UserInput`");
    }

}
