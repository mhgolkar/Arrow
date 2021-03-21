// Arrow
// HTML-JS Runtime
// Mor. H. Golkar

class UserInput {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;
        
        this.the_variable_id = null;
        this.the_variable = null;
        this.previous_variable_value = null;

        const ONLY_PLAY_SLOT = 0;
        const REQUIRE_VALID_INPUT_TO_CONTINUE = true;
        const INVALIDATE_EMPTY_STRING = true;

        const INPUT_VALIDATION_EVENT  = 'change';
        const INPUT_PER_VARIABLE_TYPE = {
            'str': 'text',
            'num': 'number',
            'bool': 'checkbox'
        };
        const DEFAULT_CHECKBOX_CLICKABLE_LABEL_TEXT = i18n('defaultCheckboxClickableLabelText');

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

        this.str_validator = function(_event, default_reset_value){
            var is_valid = true;
            var parsed_value = this.read_and_parse_value();
            if ( INVALIDATE_EMPTY_STRING === true && parsed_value.length == 0 ){
                is_valid = false;
            }
            return is_valid;
        };

        this.num_validator = function(_event, default_reset_value){
            var is_valid = true;
            var parsed_value = this.read_and_parse_value();
            if ( parsed_value == Number.NEGATIVE_INFINITY ){
                parsed_value = '';
                is_valid = false;
            }
            if (default_reset_value != false){
                this.input_element.value = parsed_value;
            }
            return is_valid;
        };

        this.bool_validator = function(_event){
            // Note: This one doesn't have `default_reset_value` because
            // ... it can't have intermediate invalid value. It's either checked (true) or not.
            return ( typeof this.read_and_parse_value() == 'boolean' );
        };
        
        this.get_element = function () {
            return this.html;
        };
        
        this.remove_element = function() {
            this.html.remove();
        };
        
        this.play_forward_from = function(){
            if (
                REQUIRE_VALID_INPUT_TO_CONTINUE === false ||
                this.is_input_valid() == true
            ){
                if ( this.slots_map.hasOwnProperty( ONLY_PLAY_SLOT ) ) {
                    // update variable
                    if ( this.the_variable ){
                        update_global_variable_by_id( this.the_variable_id, this.read_and_parse_value() );
                    }
                    // then go for the next node
                    var next = this.slots_map[ONLY_PLAY_SLOT];
                    play_node(next.id, next.slot);
                } else {
                    handle_status(_CONSOLE_STATUS_CODE.END_EDGE, _self);
                }
                this.set_view_played(ONLY_PLAY_SLOT);
            }
        };
        
        this.skip_play = function() {
            this.html.setAttribute('data-skipped', true);
            this.play_forward_from(ONLY_PLAY_SLOT);
        };
        
        this.set_view_played = function(slot_idx){
            this.html.setAttribute('data-played', true);
        };
        
        this.set_view_unplayed = function(){
            this.html.setAttribute('data-played', false);
        };
        
        this.step_back = function(){
            // reverse any variable update
            if ( this.the_variable && this.previous_variable_value !== null ){
                update_global_variable_by_id( this.the_variable_id, this.previous_variable_value );
            }
            this.set_view_unplayed();
        };
        
        this.proceed = function(){
            // `user_input` node type is pure interactive (there is no auto-play or default behavior,)
            if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                // if skipped, it means we just go to the next node as if this node didn't exist
                this.skip_play();
            } // otherwise we shall wait for user interaction
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
                            this.prompt_element = create_element(
                                "p",
                                format(node_resource.data.prompt, VARS_NAME_VALUE_PAIR),
                            );
                            this.html.appendChild(this.prompt_element);
                        }
                        // Input
                        if ( node_resource.data.hasOwnProperty('variable') ){
                            this.the_variable_id = safeInt( node_resource.data.variable );
                            if ( VARS.hasOwnProperty( this.the_variable_id ) ){
                                this.the_variable = VARS[ this.the_variable_id ];
                                this.previous_variable_value = this.the_variable.value;
                                var input_html_type = INPUT_PER_VARIABLE_TYPE[ this.the_variable.type ];
                                var input_element_id = `${node_resource.name}_input`;
                                this.input_element = create_element("input", null, {
                                    id: input_element_id,
                                    type: input_html_type
                                });
                                this.is_input_valid = _self[`${this.the_variable.type}_validator`].bind(_self);
                                this.input_element.addEventListener( INPUT_VALIDATION_EVENT, this.is_input_valid );
                                this.html.appendChild(this.input_element);
                                if ( input_html_type == 'checkbox'){
                                    var check_box_clickable_label = create_element('label', DEFAULT_CHECKBOX_CLICKABLE_LABEL_TEXT, {
                                        for: input_element_id
                                    });
                                    this.html.appendChild(check_box_clickable_label);
                                }
                            } else {
                                error = "Invalid target variable id.";
                            }
                        }
                        // Continue Button
                        this.continue_button = create_element("button", i18n('continue'));
                        this.continue_button.addEventListener( _CLICK, this.play_forward_from.bind(_self) );
                        this.html.appendChild(this.continue_button);
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
