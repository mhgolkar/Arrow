// Arrow HTML-JS Runtime: Randomizer node module

class Randomizer {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;

        const AUTO_PLAY = true;
        const ONLY_USE_CONNECTED_SLOTS = false;
        
        this.get_element = function () {
            return this.html;
        };
        
        this.remove_element = function() {
            this.html.remove();
        };
        
        this.play_forward_from = function(slot_idx){
            slot_idx = safeInt(slot_idx);
            if ( this.slots_map.hasOwnProperty(slot_idx) ) {
                var next = this.slots_map[slot_idx];
                play_node(next.id, next.slot);
            } else {
                handle_status(_CONSOLE_STATUS_CODE.END_EDGE, _self);
            }
            this.set_view_played(slot_idx);
        };

        this.play_forward_randomly = function(){
            var slots_count = -1;
            if ( ONLY_USE_CONNECTED_SLOTS !== true && this.node_resource.hasOwnProperty("data") && this.node_resource.data.hasOwnProperty("slots") ){
                slots_count = safeInt( this.node_resource.data.slots );
            }
            if ( slots_count < 0 ){
                slots_count = Object.keys(this.slots_map).length;
            }
            var random_out_slot_idx = inclusiveRandInt(0, (slots_count - 1) );
            this.play_forward_from(random_out_slot_idx);
        };
        
        this.skip_play = function() {
            this.html.setAttribute('data-skipped', true);
            // Randomizes anyway
            this.play_forward_randomly();
        };
        
        this.set_view_played = function(slot_idx){
            this.html.setAttribute('data-played', true);
        };
        
        this.set_view_unplayed = function(){
            this.html.setAttribute('data-played', false);
        };
        
        this.step_back = function(){
            this.html.setAttribute('data-skipped', false);
            this.set_view_unplayed();
        };
        
        this.proceed = function(){
            if (_ALLOW_AUTO_PLAY) {
                // Randomly play one of the outgoing slots
                // whether we are handling skip,
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play();
                // or auto-playing
                } else if ( AUTO_PLAY ) {
                    this.play_forward_randomly();
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
                // Create the node html element
                this.html = create_node_base_html(node_id, node_resource);
                    // ... and the children
                    this.rnd_mark = create_element("span", "[Randomizer]");
                    this.html.appendChild(this.rnd_mark);
                    this.randomizer_button = create_element("button", node_resource.name);
                    this.randomizer_button.addEventListener( _CLICK, this.play_forward_randomly.bind(_self) );
                    this.html.appendChild( this.randomizer_button );
            }
            return this;
        }
        throw new Error("Unable to construct `Randomizer`");
    }
    
}
