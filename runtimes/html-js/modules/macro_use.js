// Arrow HTML-JS Runtime: Macro-Use node module

class MacroUse {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;
        
        this.holder = null;
        this.nodes_list = null;
        this.entry = null;

        const PLAY_FORWARD_SELF_SLOT =  0;
        
        this.get_element = function () {
            return this.html;
        };
        
        this.remove_element = function() {
            this.html.remove();
        };
        
        this.play_forward_from = function(slot_idx){
            slot_idx = safeInt(slot_idx);
            if ( Number.isFinite(slot_idx) == false || slot_idx < 0 ){
                slot_idx = PLAY_FORWARD_SELF_SLOT;
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
            this.play_self_forward();
        };

        this.play_self_forward = function() {
            this.play_forward_from(PLAY_FORWARD_SELF_SLOT);
        };

        this.owns_node = function(node_id) {
            if ( this.nodes_list ){
                node_id = safeInt(node_id);
                return ( 
                    this.nodes_list.includes(node_id)
                );
            } else{
                if (_VERBOSE) console.warn("Unexpected Behavior! The `macro_use` instance has no valid `nodes_list`.");
            }
            return false;
        };

        this.append_instance = function(node_instance) {
            if (this.holder && 'appendChild' in this.holder){
                if ( 'get_element' in node_instance ){
                    this.holder.appendChild( node_instance.get_element() );
                    this.reset_replay(false); // we do not allow replaying macro in the midst (out of order)
                } else {
                    throw new Error("Invalid Instance! Unable to get_element from the inputted instance.");
                }
            } else {
                throw new Error("Unexpected Behavior! The holder element of the macro is not ready.");
            }
        };
        
        this.reset_replay = function(force) {
            if (this.replay) {
                var is_at_initial_state = (
                    typeof force == 'boolean' ? force :
                    this.holder.childElementCount == 0 && Number.isInteger(this.entry) && this.entry >= 0
                );
                this.replay.disabled = (! is_at_initial_state);
            } else {
                console.warn("Macro-use has no replay button!")
            }
        };

        this.set_view_played = function(slot_idx){
            this.html.setAttribute('data-played', true);
        };
        
        // IMPORTANT!
        // Unlike `step_back` which is called only when the node itself is the last step back,
        // this method could be called by the main runtime module whenever a wrapped node
        // (i.e. one inside the macro) is the last node (subject of backing;)
        this.set_view_unplayed = function(){
            this.html.setAttribute('data-played', false);
        };
        
        // This method is called when we `step_back` on a node that is wrapped by this macro_use
        this.step_into = function() {
            this.html.setAttribute('data-skipped', false);
            this.set_view_unplayed()
        };

        this.step_back = function(){
            this.html.setAttribute('data-skipped', false);
            this.set_view_unplayed();
            this.reset_replay();
        };

        this.replay_macro = function(){
            if ( Number.isInteger(this.entry) && this.entry >= 0 ){
                play_node(this.entry);
            } else {
                console.error(`Node ${this.node_id} using macro ${this.macro_id} has no valid entry: ${this.entry}`);
                this.skip_play();
            }
        };
        
        this.proceed = function(){
            if (_ALLOW_AUTO_PLAY) {
                // handle skip in case,
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play();
                // otherwise run the macro (i.e. scoped nodes starting with entry):
                } else {
                    this.replay_macro();
                }
            } else {
                this.reset_replay();
            }
        };
        
        if ( node_id >= 0 ){
            if ( typeof node_resource == 'object' && typeof node_map == 'object' ){
                // Sort stuff
                this.node_id = node_id;
                this.node_resource = node_resource;
                this.node_map = node_map;
                this.slots_map = remap_connections_for_slots( (node_map || {}), node_id );
                // fetch the target macro and its map
                if ( node_resource.hasOwnProperty('data') && node_resource.data.hasOwnProperty('macro') ){
                    this.macro_id = safeInt( node_resource.data.macro );
                    if ( this.macro_id >= 0 ){
                        this.macro = get_resource_by_id(this.macro_id, 'scenes');
                        if ( this.macro ){
                            if ( this.macro.hasOwnProperty('map') && typeof this.macro.map == 'object' ){
                                this.nodes_list = Object.keys( this.macro.map ).map( safeInt );
                            }
                            if ( this.macro.hasOwnProperty("entry") ){
                                this.entry = safeInt(this.macro.entry);
                            }
                        } else {
                            throw new Error(`Corrupt Project Data! Node ${node_resource.name} (macro_use) links to no valid macro (scene) resource.`);
                        }
                    }
                }
                // Create the node html element
                this.html = create_node_base_html(node_id, node_resource);
                    this.html.setAttribute('data-macro',  node_resource.data.macro);
                    // holder element to capsulate sub-nodes
                    this.holder = create_element("div");
                    this.html.appendChild(this.holder);
                    // the identity label,
                    var macro_label = `${node_id}: ${node_resource.data.macro} - ${this.macro.name}`;
                    this.label = create_element("span", macro_label);
                    this.html.appendChild(this.label);
                    // a replay button
                    this.replay = create_element("button", macro_label);
                    this.replay.addEventListener( _CLICK, this.replay_macro.bind(_self) );
                    this.html.appendChild(this.replay);
                    // and skip button (used in manual play and step-backs)
                    this.skip_button = create_element("button", i18n("skip"));
                    this.skip_button.addEventListener( _CLICK, this.skip_play.bind(_self) );
                    this.html.appendChild(this.skip_button);
                // ...
                if ( Array.isArray(this.nodes_list) == false || this.nodes_list.length == 0 || this.nodes_list.includes(this.entry) == false ){
                    console.warn("Unset or invalid macro_use: ", node_id, node_resource, " -> Set to be skipped.");
                    this.node_map.skip = true;
                }
            }
            return this;
        }
        throw new Error("Unable to construct `MacroUse`");
    }
    
}
