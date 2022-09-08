// Arrow HTML-JS Runtime: Content node module

class Content {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {
        
        const _self = this;
        
        const DEFAULT_NODE_DATA = {
            "title": "",
            "content": "",
            "brief": 0,
            "auto": false,
            "clear": false,
        }

        // Forces auto-play regardless of the `auto` property
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
            this.html.setAttribute('data-skipped', false);
            this.set_view_unplayed();
        };
        
        this.string_data_or_default = function(parameter) {
            var text = DEFAULT_NODE_DATA[parameter];
            if (
                this.node_resource.data.hasOwnProperty(parameter) &&
                (typeof this.node_resource.data[parameter] == 'string')
            ){
                text = this.node_resource.data[parameter]
            }
            return text;
        }
        
        this.bool_data_or_default = function(parameter) {
            var intended = DEFAULT_NODE_DATA[parameter];
            if (
                this.node_resource.data.hasOwnProperty(parameter) &&
                (typeof this.node_resource.data[parameter] == 'boolean')
            ){
                intended = this.node_resource.data[parameter]
            }
            return intended;
        }
                
        this.proceed = function(){
            if (_ALLOW_AUTO_PLAY) {   
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play();
                } else if (AUTO_PLAY_SLOT >= 0) {
                    this.play_forward_from(AUTO_PLAY_SLOT);
                } else {
                    if ( this.bool_data_or_default("auto") ) {
                        this.play_forward_from(CONTINUE_PLAY_SLOT);
                    }
                }
            }
            // View Clearance ?
            if (_ALLOW_CLEARANCE) {
                // `content` nodes can force the page to get cleaned before they step in
                if ( this.bool_data_or_default("clear") ) {
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
                    // ...
                    if ( node_resource.hasOwnProperty("data") ){
                        var title_string = this.string_data_or_default("title")
                        if ( title_string.length > 0 ){
                            this.title = create_element(TITLE_TAG, parse_bbcode( format(title_string, VARS_NAME_VALUE_PAIR) ) );
                            this.html.appendChild(this.title);
                        }
                        // Textual (legacy) brief support:
                        // (It's not a string anymore so we can check for its default)
                        if ( node_resource.data.hasOwnProperty("brief") && typeof node_resource.data.brief == 'string' ){
                            this.brief = create_element(BRIEF_TAG, parse_bbcode( format(node_resource.data.brief, VARS_NAME_VALUE_PAIR) ) );
                            this.html.appendChild(this.brief);
                        }
                        // ...
                        var content_string = this.string_data_or_default("content")
                        if (content_string.length > 0 ){
                            this.content = create_element(CONTENT_TAG, parse_bbcode( format(content_string, VARS_NAME_VALUE_PAIR) ) );
                            this.html.appendChild(this.content);
                        }
                        if ( this.bool_data_or_default("auto") ) { this.html.setAttribute('data-auto', 'true'); }
                        if ( this.bool_data_or_default("clear") ) { this.html.setAttribute('data-clear', 'true'); }
                    }
                    // ...
                    this.continue_button = create_element("button", i18n("continue"));
                    this.continue_button.addEventListener( _CLICK, this.play_forward_from.bind(_self, CONTINUE_PLAY_SLOT) );
                    this.html.appendChild(this.continue_button);
                    // ...
                    if (node_map.hasOwnProperty("skip") && node_map.skip === true) {
                        this.skip_button = create_element("button", i18n("skip"));
                        this.skip_button.addEventListener( _CLICK, this.skip_play.bind(_self) );
                        this.html.appendChild(this.skip_button);
                    }
            }
            return this;
        }
        throw new Error("Unable to construct `Content`");
    }
    
}
