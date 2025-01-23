// Arrow HTML-JS Runtime: Node-Type (module) boilerplate

class NodeType {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;
        // super();

        const AUTO_PLAY_SLOT = -1;
        
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
            // Skipped nodes can have default behavior such as continuing to the only outgoing slot
            // without any side effects (e.g. no variable modification, etc.)
            if (AUTO_PLAY_SLOT >= 0){
                this.play_forward_from(AUTO_PLAY_SLOT);
            }
        };
        
        this.set_view_played = function(slot_idx){
            // ... generally by setting a custom data-attribute, so we can handle it cleaner with css
            this.html.setAttribute('data-played', true);
        };
        
        this.set_view_unplayed = function(){
            // ditto
            this.html.setAttribute('data-played', false);
        };
        
        this.step_back = function(){
            this.html.setAttribute('data-skipped', false);
            this.set_view_unplayed();
        };
        
        this.proceed = function(){
            if (_ALLOW_AUTO_PLAY) {
                // When auto-play is enabled (default)
                // we first handle node skipping which is set in the project data (via editor,)
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play();
                // otherwise auto-play if set by the constant:
                } else if ( AUTO_PLAY_SLOT >= 0 ) {
                    this.play_forward_from(AUTO_PLAY_SLOT);
                // or prepare for manual user interaction ...
                } else {
                    // ... if any extra set up is needed
                    // this.set_view_unplayed()
                }
            } else {
                // Here in fully manual play mode, we can wait for user interaction:
                // this.set_view_unplayed()
            }
        };
        
        if ( node_id >= 0 ){
            if ( typeof node_resource == 'object' && typeof node_map == 'object' ){
                // Sort stuff
                this.node_id = node_id;
                this.node_resource = node_resource;
                this.node_map = node_map;
                this.slots_map = remap_connections_for_slots( (node_map || {}), node_id );
                // TODO
                // Create the node's html elements, extra logic and bindings needed:
                this.html = create_node_base_html(node_id, node_resource);
                    // ... and the children
                    // this.x_button = create_element("button", node_resource.name);
                    // this.x_button.addEventListener( _CLICK, this.play_forward_from.bind(_self, AUTO_PLAY_SLOT) );
                    // this.html.appendChild(this.x_button);
            }
            // this.playing_in_slot = safeInt(_playing_in_slot);
            return this;
        }
        // We won't get here if construction is done right
        // TODO: replace `NodeType` with the right name
        throw new Error("Unable to construct `NodeType`");
    }
    
}
