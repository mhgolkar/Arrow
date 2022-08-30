// Arrow HTML-JS Runtime: Marker node module

class Marker {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;
        // super();

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
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play(); // ... also auto-plays forward
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
                    // Label
                    var label_text = (
                        node_resource.hasOwnProperty("data") && node_resource.data.hasOwnProperty("label") &&
                        typeof node_resource.data.label == 'string' && node_resource.data.label.length > 0
                    ) ? node_resource.data.label : "...";
                    var attributes = ( node_resource.data.hasOwnProperty("color") ? { style: `--marker-color: #${node_resource.data.color}; ` } :  undefined );
                    this.label = create_element("p", label_text, attributes);
                    this.html.appendChild(this.label);
                    // Manual play button
                    this.marker_button = create_element("button", node_resource.name);
                    this.marker_button.addEventListener( _CLICK, this.play_forward_from.bind(_self, AUTO_PLAY_SLOT) );
                    this.html.appendChild(this.marker_button);
            }
            return this;
        }
        throw new Error("Unable to construct `Marker`");
    }

}
