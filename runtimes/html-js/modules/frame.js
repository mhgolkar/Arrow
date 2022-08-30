// Arrow HTML-JS Runtime: Frame node module

// NOTE:
//
// Frames nodes have no incoming or outgoing slots.
// They are designed to be used as visual organizers in the Arrow editor.
// Although frames can not act as active links in a plot and are not expected to be played by convention,
// they are structurally nodes (i.e. stored as node resources and allowed to be jumped into,)
// so shall have defined runtime behavior.
// This runtime treats them as end-of-line marker-like nodes (with labels) the same way the Arrow editor does.

class Frame {

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
                // NOTE:
                // You always end up here, because currently, **frames have no outgoing slot.**
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
                    var attributes = ( node_resource.data.hasOwnProperty("color") ? { style: `--frame-color: #${node_resource.data.color}; ` } :  undefined );
                    this.label = create_element("p", label_text, attributes);
                    this.html.appendChild(this.label);
                    // Manual play button
                    this.frame_button = create_element("button", node_resource.name);
                    this.frame_button.addEventListener( _CLICK, this.play_forward_from.bind(_self, AUTO_PLAY_SLOT) );
                    this.html.appendChild(this.frame_button);
                // We also need to inform user in case there was a mistake in creating jumps and we ended up here,
                // because frames are not expected to be played!
                if (_VERBOSE) console.warn(
                    `We just hit a Frame node (${node_id} - ${node_resource.name})!\n` +
                    "Although this node type is not expected to be part of (or a link in) a plot, " +
                    "it is allowed to be played (by being jumped into,) so needs to have defined runtime behavior.\n" +
                    "Because there is no general outgoing scenario, this runtime treats frames as marker-like end-of-line nodes.\n" +
                    "Make sure this node is intentionally played and is not a misdirected jump.\n" +
                    "Better practice may be to use a `Marker` if you intend to get this kind of result.\n"
                )
            }
            return this;
        }
        throw new Error("Unable to construct `Frame`");
    }

}
