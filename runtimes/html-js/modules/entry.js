// Arrow HTML-JS Runtime: Entry node module

class Entry {
    
    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;
        
        const AUTO_PLAY_SLOT = 0;
        
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
            // continue the only and natural path even if the node is skipped
            this.play_forward_from(AUTO_PLAY_SLOT);
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
                // ... auto-plays anyway
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play();
                } else if ( AUTO_PLAY_SLOT >= 0 ) {
                    this.play_forward_from(AUTO_PLAY_SLOT);
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
                    // + plaque:
                    if ( 
                        node_resource.hasOwnProperty("data") && node_resource.data.hasOwnProperty("plaque") &&
                        typeof node_resource.data.plaque == 'string' && node_resource.data.plaque.length > 0
                    ) {
                        this.plaque = create_element("em", node_resource.data.plaque, {'class': 'plaque'});
                        this.html.appendChild(this.plaque);
                    } else {
                        this.entry_mark = create_element("span", "[Entry]");
                        this.html.appendChild(this.entry_mark);
                    }
                    // + possible user interaction (manual play)
                    this.entry_button = create_element("button", node_resource.name);
                    this.entry_button.addEventListener( _CLICK, this.play_forward_from.bind(_self, AUTO_PLAY_SLOT) );
                    this.html.appendChild(this.entry_button);
            }
            return this;
        }
        throw new Error("Unable to construct `Entry`");
    }

}
