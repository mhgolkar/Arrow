// Arrow HTML-JS Runtime: Interaction node module

class Interaction {
    
    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;
        
        const AUTO_PLAY_SLOT = -1;
        
        const ACTIONS_HOLDER_TAG = 'ol';
        const ACTION_ELEMENT_TAG = 'li';
        const PLAYED_ACTION_TAG = 'p';
        
        this.actions = null;
        this.action_elements = null;
        this.played_action = null;

        this.get_element = function () {
            return this.html;
        };
        
        this.remove_element = function() {
            this.html.remove();
        };
        
        this.play_forward_from = function(slot_idx){
            slot_idx = safeInt(slot_idx);
            if ( Number.isFinite(slot_idx) == false || slot_idx < 0 ){
                slot_idx = AUTO_PLAY_SLOT;
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
            this.html.setAttribute('data-skipped', true);
            // Plays the first *connected* slot (interaction)
            // or just the first[0] slot if there is no connected one which means end edge
            var first_connected_slot = 0;
            if (this.slots_map.length >= 1) {
                var all_connected_slots = Object.keys(this.slots_map);
                all_connected_slots.sort();
                first_connected_slot = all_connected_slots[0];
            }
            this.play_forward_from(first_connected_slot);
        };
        
        this.set_view_played = function(slot_idx){
            // set the famous attribute,
            this.html.setAttribute('data-played', true);
            // then emphasize the played action
            if ( Number.isInteger(slot_idx) && slot_idx >= 0 && slot_idx < this.actions.length ){
                this.played_action = create_element(
                    PLAYED_ACTION_TAG,
                    exposure(this.actions[slot_idx]),
                    { class: 'interaction-played-action' }
                );
                this.html.appendChild(this.played_action);
            } else {
                throw new Error("Unable to set `Interaction` played: The played slot doesn't exist: ", slot_idx);
            }
        };
        
        this.set_view_unplayed = function(){
            this.html.setAttribute('data-played', false);
            // ... and remove the element for the emphasized played action
            if ( this.played_action ){
                this.played_action.remove();
                this.played_action = null;
            }
        };
        
        this.step_back = function(){
            this.html.setAttribute('data-skipped', false);
            this.set_view_unplayed();
        };
        
        this.proceed = function(){
            if (_ALLOW_AUTO_PLAY) {
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play();
                } else if ( AUTO_PLAY_SLOT >= 0 ) {
                    this.play_forward_from(AUTO_PLAY_SLOT);
                }
            }
        };

        this.create_action_elements = function(actions_array, actions_holder, listen){
            if ( ("appendChild" in actions_holder) == false ) actions_holder = null;
            var action_elements = [];
            for ( var idx = 0; idx < actions_array.length; idx++ ) {
                var action_element = create_element(
                    ACTION_ELEMENT_TAG,
                    exposure(actions_array[idx])
                );
                if ( listen ){
                    // Each action has its own slot in the same order, so...
                    action_element.addEventListener(_CLICK, this.play_forward_from.bind(_self, idx));
                }
                if ( actions_holder ) actions_holder.appendChild(action_element);
                action_elements.push(action_element);
            }
            return action_elements;
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
                        // Actions:
                        if ( node_resource.data.hasOwnProperty('actions') && Array.isArray(node_resource.data.actions) && node_resource.data.actions.length > 0 ){
                            // + holder
                            this.actions_holder = create_element(ACTIONS_HOLDER_TAG, null, { class: 'interaction-actions' });
                                // + actions
                                this.actions = node_resource.data.actions;
                                this.action_elements = this.create_action_elements(node_resource.data.actions, this.actions_holder, true);
                            this.html.appendChild(this.actions_holder);
                        } else {
                            error = "No `actions` exist!";
                        }
                    } else {
                        error = "The resource doesn't own the required `data`.";
                    }
                    if (error)  throw new Error("Unable to create `Interaction` node! " + error );

            }
            return this;
        }
        throw new Error("Unable to construct `Interaction`");
    }
    
}
