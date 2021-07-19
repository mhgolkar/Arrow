// Arrow
// HTML-JS Runtime
// Mor. H. Golkar

class Content {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {
        
        const _self = this;
        
        const AUTO_PLAY_SLOT = -1;
        const CONTINUE_PLAY_SLOT = 0;
        
        const TITLE_TAG = "h2";
        const CONTENT_TAG = "pre";
        const BRIEF_TAG = "pre";

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
            // a skipped content node is not displayed ...
            this.html.setAttribute('data-skipped', true);
            // ...  so there is no continue button and we shall play forward anyway
            this.play_forward_from((AUTO_PLAY_SLOT >= 0 ? AUTO_PLAY_SLOT : CONTINUE_PLAY_SLOT));
        };
        
        this.set_view_played = function(){
            this.html.setAttribute('data-played', true);
        };
        
        this.set_view_unplayed = function(){
            this.html.setAttribute('data-played', false);
        };
        
        this.step_back = function(){
            this.set_view_unplayed();
        };
        
        this.proceed = function(){
            // ... auto-plays anyway
            if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                this.skip_play();
            } else if ( AUTO_PLAY_SLOT >= 0 ) {
                this.play_forward_from(AUTO_PLAY_SLOT);
            }
            // View Clearance ?
            // `content` nodes can force the page to get cleaned before they step in
            if ( this.node_resource.data.hasOwnProperty('clear') &&  typeof this.node_resource.data.clear == 'boolean' ){
                if ( this.node_resource.data.clear === true ){
                    clear_up(this.node_id);
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
                    this.continue_button = create_element("button", i18n("continue"));
                    this.continue_button.addEventListener( _CLICK, this.play_forward_from.bind(_self, CONTINUE_PLAY_SLOT) );
                    if ( node_resource.hasOwnProperty("data") ){
                        if ( node_resource.data.hasOwnProperty("title") ){
                            this.title = create_element(TITLE_TAG, format(node_resource.data.title, VARS_NAME_VALUE_PAIR));
                            this.html.appendChild(this.title);
                        }
                        if ( node_resource.data.hasOwnProperty("brief") ){
                            this.brief = create_element(BRIEF_TAG, parse_bbcode( format(node_resource.data.brief, VARS_NAME_VALUE_PAIR) ) );
                            this.html.appendChild(this.brief);
                        }
                        if ( node_resource.data.hasOwnProperty("content") ){
                            this.content = create_element(CONTENT_TAG, parse_bbcode( format(node_resource.data.content, VARS_NAME_VALUE_PAIR) ) );
                            this.html.appendChild(this.content);
                        }
                    }
                    this.html.appendChild(this.continue_button);
            }
            return this;
        }
        throw new Error("Unable to construct `Content`");
    }
    
}
