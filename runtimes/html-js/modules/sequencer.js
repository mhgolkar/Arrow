// Arrow HTML-JS Runtime: Sequencer node module

class Sequencer {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;

        const AUTO_PLAY = true;
        
        this.get_element = function () {
            return this.html;
        };
        
        this.remove_element = function() {
            this.html.remove();
        };
        
        this.count_slots = function() {
            var slots_count = -1;
            if (this.node_resource.hasOwnProperty("data") && this.node_resource.data.hasOwnProperty("slots") ){
                slots_count = safeInt( this.node_resource.data.slots );
            }
            if ( slots_count < 0 && typeof this.slots_map == 'object'){
                var connected_slot_keys_int = Object.keys(this.slots_map).map((x) => { return parseInt(x); }).sort((a, b) => { return a <= b; });
                slots_count = (connected_slot_keys_int ? connected_slot_keys_int.length > 0 : [-1])[0] + 1;
            }
            if (slots_count < 0) slots_count = 0;
            return slots_count;
        };

        this.request_play_forward = function(slot_idx){
            slot_idx = safeInt(slot_idx);
            if ( this.slots_map.hasOwnProperty(slot_idx) ) {
                var next = this.slots_map[slot_idx];
                play_node(next.id, next.slot);
            }
        };

        this.play_sequence_forward = function(){
            var nothing = true
            for (var slot_idx = 0; slot_idx < this.slots_count; slot_idx++){
                if ( this.slots_map.hasOwnProperty(slot_idx) ) { // (is connected)
                    nothing = false;
                    this.request_play_forward(slot_idx);
                }
            }
            if (nothing) {
                handle_status(_CONSOLE_STATUS_CODE.END_EDGE, _self);
            }
            this.set_view_played();
        };

        this.play_last_connected_slot = function(){
            var nothing = true
            for (var last_idx = (this.slots_count - 1); last_idx >= 0; last_idx--){
                if ( this.slots_map.hasOwnProperty(last_idx) ) { // (is connected)
                    nothing = false;
                    this.request_play_forward(last_idx);
                    break;
                }
            }
            if (nothing) {
                handle_status(_CONSOLE_STATUS_CODE.END_EDGE, _self);
            }
            this.set_view_played();
        };
        
        this.skip_play = function() {
            this.html.setAttribute('data-skipped', true);
            this.play_last_connected_slot();
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
        
        this.proceed = function(){
            if (_ALLOW_AUTO_PLAY) {
                // Play last connected slot if skipped
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play();
                // or auto-playing all the sequence
                } else if ( AUTO_PLAY ) {
                    this.play_sequence_forward();
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
                this.slots_count = this.count_slots();
                // Create the node html element
                this.html = create_node_base_html(node_id, node_resource);
                    // ... and the children including
                    // a marker
                    this.seq_mark = create_element("span", "[Sequencer]");
                    this.html.appendChild(this.seq_mark);
                    // play button
                    this.sequencer_button = create_element("button", node_resource.name);
                    this.sequencer_button.addEventListener( _CLICK, this.play_sequence_forward.bind(_self) );
                    this.html.appendChild( this.sequencer_button );
                    // and skip button (used in manual play and step-backs)
                    this.skip_button = create_element("button", i18n("skip"));
                    this.skip_button.addEventListener( _CLICK, this.skip_play.bind(_self) );
                    this.html.appendChild(this.skip_button);
                    // ...
                    this.set_view_unplayed()
            }
            return this;
        }
        throw new Error("Unable to construct `Sequencer`");
    }
    
}
