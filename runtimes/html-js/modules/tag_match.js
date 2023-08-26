// Arrow HTML-JS Runtime: Tag-Match node module

class TagMatch {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;

        const AUTO_PLAY_SLOT = -1;

        this.the_character = null;
        this.the_character_id = null;
        this.tag_key = null;
        this.patterns = null;
        this.patterns_element = null;
        this.use_regex = false; // (current default)

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
            // Plays the first *connected* slot (dialog) 
            // or just the first[0] slot if there is no connected one which means end edge
            var first_connected_slot = 0;
            if (this.slots_map.length >= 1) {
                var all_connected_slots = Object.keys(this.slots_map);
                all_connected_slots.sort();
                first_connected_slot = all_connected_slots[0];
            }
            this.play_forward_from(first_connected_slot);
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

        this.play_manual = function() {
            if (this.patterns_element != null) {
                this.play_forward_from(this.patterns_element.selectedIndex)
            } else {
                this.play_forward_from(-1)
            }
        }

        this.process_tag_match_forward = function(){
            var matched = -1;
            if ( this.the_character != null && this.tag_key != null && this.patterns != null ){ // (~ means validity checks are passed)
                if (
                    this.the_character.hasOwnProperty("tags") && (typeof this.the_character.tags == 'object') &&
                    this.the_character.tags.hasOwnProperty(this.tag_key)
                ) {
                    var tag_value = this.the_character.tags[this.tag_key]
                    for (var i = 0; i <= this.patterns.length; i++) {
                        var pattern = this.patterns[i];
                        if (this.use_regex) {
                            try {
                                var regex = new RegExp(pattern);
                                if (tag_value.search(regex) >= 0) {
                                    matched = i;
                                    break;
                                }
                            } catch(err) {
                                if (_VERBOSE){
                                    console.warn(`Tag-Match RegExp pattern '${i}.${pattern}' failed: ` + err);
                                    console.warn(arguments);
                                }
                            }
                        } else {
                            if (pattern === tag_value){
                                matched = i;
                                break;
                            }
                        }
                    }
                }
            }
            if (matched >= 0) {
                this.patterns_element.selectedIndex = matched;
                console.log(`'${this.the_character.name}.${this.tag_key}' tag matched '${this.patterns[matched]}' pattern, branching to slot ${matched}`);
            }
            this.play_forward_from(matched);
        };
        
        this.proceed = function(){
            if (_ALLOW_AUTO_PLAY) {
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play();
                } else {
                    this.process_tag_match_forward();
                }
            }
        };
        
        this.data_is_valid = function(data){
            return (
                data != null && (typeof data == 'object') &&
                data.hasOwnProperty("character") && (Number.isInteger( safeInt(data.character) ) && safeInt(data.character) >= 0) &&
                data.hasOwnProperty("patterns") && Array.isArray(data.patterns) && data.patterns.length > 0 &&
                data.hasOwnProperty("tag_key") && (typeof data.tag_key == 'string')
            )
        }
        
        if ( node_id >= 0 ){
            if ( typeof node_resource == 'object' && typeof node_map == 'object' ){
                // Sort stuff
                this.node_id = node_id;
                this.node_resource = node_resource;
                this.node_map = node_map;
                this.slots_map = remap_connections_for_slots( (node_map || {}), node_id );
                // ...
                var is_valid = this.node_resource.hasOwnProperty("data") && this.data_is_valid(this.node_resource.data);
                if ( is_valid ){
                    this.the_character_id = safeInt(this.node_resource.data.character);
                    if ( CHARS.hasOwnProperty(this.the_character_id) ) {
                        this.the_character = CHARS[ this.the_character_id ];
                    } else {
                        is_valid = false
                        if (_VERBOSE) console.warn(
                            "Invalid Tag-Match Node! The node has non-existent UID as the target character:",
                            this.the_character_id,
                            this.node_resource
                        );
                    }
                    // ...
                    if (this.node_resource.data.hasOwnProperty("regex") && (typeof this.node_resource.data.regex == 'boolean')) {
                        this.use_regex = this.node_resource.data.regex;
                    }
                    // ...
                    this.tag_key = this.node_resource.data.tag_key;
                    this.patterns = this.node_resource.data.patterns;
                } else {
                    if (_VERBOSE) console.warn(
                        "Invalid Tag-Match Node! The node has no valid data set or target character.",
                        this.node_resource
                    );
                }
                // Create the node html element
                this.html = create_node_base_html(node_id, node_resource);
                    // ... and the children
                    // Matching:
                    if (is_valid) {
                        this.patterns_element = create_element("select");
                        for (var i = 0; i < this.patterns.length; i++) {
                            var option = create_element("option", this.patterns[i]/*, { "value": this.patterns[i] }*/)
                            this.patterns_element.add(option)
                        }
                        this.character_tag = create_element(
                            "div",
                            `${this.the_character.name}.${this.tag_key}`,
                            {
                                style: `--character-color: #${this.the_character.color};`,
                                "data-character-id": this.the_character_id,
                                "data-character-name": this.the_character.name,
                            }
                        );
                        this.character_tag.appendChild(this.patterns_element);
                        this.html.appendChild(this.character_tag);
                    } else {
                        this.invalid_tag_pass = create_element("span", `[Tag-Match] ${this.node_resource.name} : ${ i18n("invalid") }`);
                        this.html.appendChild(this.invalid_tag_pass);
                    }
                    // EOL:
                    this.eol_button = create_element("button", i18n("eol"), { "value": "eol" });
                    this.eol_button.addEventListener( _CLICK, this.play_forward_from.bind(_self, -1) );
                    this.html.appendChild(this.eol_button);
                    // MATCH:
                    this.match_button = create_element("button", i18n("match"), { "value": "match" });
                    this.match_button.addEventListener( _CLICK, this.play_manual.bind(_self) );
                    this.html.appendChild(this.match_button);
            }
            return this;
        }
        throw new Error("Unable to construct `TagMatch`");
    }

}
