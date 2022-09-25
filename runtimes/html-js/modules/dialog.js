// Arrow HTML-JS Runtime: Dialog node module

class Dialog {
    
    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;
        
        const ANONYMOUS_CHARACTER = {
            "name": i18n("dialog_anonymous_character_name"),
            "color": "ffffff",
        };

        const DEFAULT_NODE_DATA = {
            "character": -1, // ~ anonymous or unset (hardcoded convention)
            "lines": ["Hey there!"],
            // -- optional(s) --
            "playable": false,
        };

        const AUTO_PLAY_SLOT = -1;
        
        const LINES_HOLDER_TAG = 'ol';
        const LINE_ELEMENT_TAG = 'li';
        const PLAYED_LINE_TAG = 'p';
        
        this.lines = null;
        this.line_elements = null;
        this.played_line = null;
        this.character_profile = null;
        this.character_profile_element = null;
        this.character_name_element = null;

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
        
        this.set_view_played = function(slot_idx){
            // set the famous attribute,
            this.html.setAttribute('data-played', true);
            // then emphasize the played line
            if ( Number.isInteger(slot_idx) && slot_idx >= 0 && slot_idx < this.lines.length ){
                this.played_line = create_element(
                    PLAYED_LINE_TAG,
                    exposure(this.lines[slot_idx]),
                    { class: 'dialog-played-line' }
                );
                this.html.appendChild(this.played_line);
            } else {
                throw new Error("Unable to set `Dialog` played: The played slot doesn't exist: ", slot_idx);
            }
        };
        
        this.set_view_unplayed = function(){
            this.html.setAttribute('data-played', false);
            // ... and remove the element for the emphasized played line
            if ( this.played_line ){
                this.played_line.remove();
                this.played_line = null;
            }
        };
        
        this.step_back = function(){
            this.html.setAttribute('data-skipped', false);
            this.set_view_unplayed();
        };
        
        this.proceed = function(){
            if (_ALLOW_AUTO_PLAY) {
                // handle skip in case,
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play();
                // otherwise auto-play if set (which is not normal)
                } else if ( AUTO_PLAY_SLOT >= 0 ) {
                    this.play_forward_from(AUTO_PLAY_SLOT);
                // or handle the none-playable dialog in case ...
                } else {
                    this.random_play_none_playable_dialogs();
                }
                // ... and finally for normal playable dialogs,
                // we'll wait for the user to take action and play a line.
            }
        };

        this.create_line_elements = function(lines_array, lines_holder, listen){
            if ( ("appendChild" in lines_holder) == false ) lines_holder = null;
            var line_elements = [];
            for ( var idx = 0; idx < lines_array.length; idx++ ) {
                var line_element = create_element(
                    LINE_ELEMENT_TAG,
                    exposure(lines_array[idx])
                );
                if ( listen ){
                    // Each line has its own slot in the same order, so...
                    line_element.addEventListener(_CLICK, this.play_forward_from.bind(_self, idx));
                }
                if ( lines_holder ) lines_holder.appendChild(line_element);
                line_elements.push(line_element);
            }
            return line_elements;
        };
        
        this.has_intended_bool_behavior = function(parameter) {
            var is_intended = DEFAULT_NODE_DATA[parameter];
            if (
                this.node_resource.data.hasOwnProperty(parameter) &&
                (typeof this.node_resource.data[parameter] == 'boolean')
            ){
                is_intended = this.node_resource.data[parameter]
            }
            return is_intended;
        };
        
        this.random_play_none_playable_dialogs = function(){
            if ( this.has_intended_bool_behavior("playable") == false ){
                var random_played_line_idx = inclusiveRandInt( this.lines.length - 1);
                this.play_forward_from(random_played_line_idx);
            }
        };

        this.update_character_profile = function(character_id, character){
            if ( typeof character == 'object' && character.hasOwnProperty("color") && character.hasOwnProperty("name") ){
                if ( this.character_profile_element == null ){
                    this.character_name_element = create_element( "div", character.name, { class: 'character-name' } );
                    var data_attributes = {
                        class: 'character-profile',
                        style: `--character-color: #${character.color};`,
                        "data-id": character_id,
                        "data-name": character.name,
                    };
                    for (const key in character.tags){
                        data_attributes[`data-tag-${key}`] = character.tags[key];
                    };
                    this.character_profile_element = create_element( "div",
                        this.character_name_element,
                        data_attributes
                    );
                    this.html.appendChild(this.character_profile_element);
                } else {
                    this.character_profile_element.setAttribute('style', `--character-color: #${character.color};`);
                    this.character_name_element.innerHTML = character.name;
                }
            } else {
                if (_VERBOSE) console.error(character);
                throw new Error("Unable to Update Character Profile: Lack of required object keys, `name` and/or `color`.");
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
                    var error = null;
                    if ( node_resource.hasOwnProperty('data') ){
                        // Character profile:
                        if ( node_resource.data.hasOwnProperty('character') ){
                            var character_id = safeInt(node_resource.data.character);
                            this.update_character_profile(
                                character_id,
                                CHARS.hasOwnProperty(character_id) ? CHARS[character_id] : ANONYMOUS_CHARACTER,
                            );
                        }
                        // Lines:
                        if ( node_resource.data.hasOwnProperty('lines') && Array.isArray(node_resource.data.lines) && node_resource.data.lines.length > 0 ){
                            // + holder
                            this.lines_holder = create_element(LINES_HOLDER_TAG, null, { class: "dialog-lines"});
                                // + lines
                                this.lines = node_resource.data.lines;
                                this.line_elements = this.create_line_elements(node_resource.data.lines, this.lines_holder, true);
                            this.html.appendChild(this.lines_holder);
                        } else {
                            error = "No `lines` exist!";
                        }
                        if ( this.has_intended_bool_behavior("playable") ){
                            this.html.setAttribute('data-playable', 'true');
                        }
                    } else {
                        error = "The resource doesn't own the required `data`.";
                    }
                    if (error)  throw new Error("Unable to create `Dialog` node! " + error );

            }
            return this;
        }
        throw new Error("Unable to construct `Dialog`");
    }
    
}
