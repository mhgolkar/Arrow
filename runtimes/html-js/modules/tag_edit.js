// Arrow HTML-JS Runtime: Tag-Edit node module

class TagEdit {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;
        
        const ONLY_PLAY_SLOT = 0;
        
        const METHODS = {
            0: "Inset",
            1: "Reset",
            2: "Overset",
            3: "Outset",
            4: "Unset",
        }

        this.the_character = null;
        this.the_character_id = null;
        this.the_character_tags_revert = null;

        this.get_element = function () {
            return this.html;
        };
        
        this.remove_element = function() {
            this.html.remove();
        };
        
        this.play_forward = function(){
            if ( this.slots_map.hasOwnProperty(ONLY_PLAY_SLOT) ) {
                var next = this.slots_map[ONLY_PLAY_SLOT];
                play_node(next.id, next.slot);
            } else {
                handle_status(_CONSOLE_STATUS_CODE.END_EDGE, _self);
            }
            this.set_view_played(ONLY_PLAY_SLOT);
        };
        
        this.skip_play = function() {
            this.html.setAttribute('data-skipped', true);
            // when skipped it *doesn't modify* the character
            this.play_forward();
        };
        
        this.set_view_played = function(){
            this.html.setAttribute('data-played', true);
        };
        
        this.set_view_unplayed = function(){
            this.html.setAttribute('data-played', false);
        };
        
        this.step_back = function(){
            // reverse any character tag update
            if ( this.the_character && this.the_character_tags_revert !== null ){
                update_global_characters_tags(this.the_character_tags_revert);
                this.the_character_tags_revert = null;
            }
            this.html.setAttribute('data-skipped', false);
            this.set_view_unplayed();
        };

        this.process_tag_edit_forward = function(){
            if ( this.the_character != null ){ // (~ means validity checks are passed)
		        var update_instruction = {};
                var revert_instruction = {};
                var current_tags = (
                    (this.the_character.hasOwnProperty("tags") && (typeof this.the_character.tags == 'object'))
                    ? this.the_character.tags : {}
                );
                var edit_key = this.node_resource.data.edit[1];
                var edit_value = this.node_resource.data.edit[2];
                switch (this.node_resource.data.edit[0]) {
                    case 0: // Inset: Adds a key:value tag, only if the key does not exist
                        if ( current_tags.hasOwnProperty(edit_key) == false ){
                            update_instruction[edit_key] = edit_value;
                            revert_instruction[edit_key] = null;
                        }
                        break;
                    case 1: // Reset: Updates value of a tag, only if the key exists
                        if (current_tags.hasOwnProperty(edit_key) == true){
                            update_instruction[edit_key] = edit_value;
                            revert_instruction[edit_key] = current_tags[edit_key];
                        }
                        break;
                    case 2: // Overset: Overwrites or adds a key:value tag, whether the key exists or not
                        update_instruction[edit_key] = edit_value;
                        revert_instruction[edit_key] = (
                            current_tags.hasOwnProperty(edit_key) ? current_tags[edit_key] : null
                        );
                        break;
                    case 3: // Outset: Removes a tag if both key & value match
                        if ( current_tags.hasOwnProperty(edit_key) == true ){
                            if (current_tags[edit_key] == edit_value) {
                                update_instruction[edit_key] = null;
                                revert_instruction[edit_key] = current_tags[edit_key];
                            }
                        }
                        break;
                    case 4: // Unset: Removes a tag if just the key matches
                        if (current_tags.hasOwnProperty(edit_key) == true){
                            update_instruction[edit_key] = null;
                            revert_instruction[edit_key] = current_tags[edit_key];
                        }
                        break;
                }
                // ...
                this.the_character_tags_revert = {}
                this.the_character_tags_revert[this.the_character_id] = revert_instruction;
                // ...
                var application = {};
                application[this.the_character_id] = update_instruction;
                update_global_characters_tags(application);
                // ...
                this.play_forward();
            } else {
                console.error(`Unable to process the tag-edit (${this.node_resource.name}.) Skipped forward.`);
                this.skip_play();
            }
        };

        this.proceed = function(){
            if (_ALLOW_AUTO_PLAY) {
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play();
                } else {
                    this.process_tag_edit_forward();
                }
            }
        };
        
        this.data_is_valid = function(data){
            return (
                data != null && (typeof data == 'object') &&
                data.hasOwnProperty("character") && (Number.isInteger( safeInt(data.character) ) && safeInt(data.character) >= 0) &&
                data.hasOwnProperty("edit") && Array.isArray(data.edit) && data.edit.length >= 3 &&
                Number.isInteger(data.edit[0]) && METHODS.hasOwnProperty(data.edit[0]) &&
                (typeof data.edit[1] == 'string') && data.edit[1].length > 0 && (typeof data.edit[2] == 'string')
            )
        }
        
        if ( node_id >= 0 ){
            if ( typeof node_resource == 'object' && typeof node_map == 'object' ){
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
                            "Invalid Tag-Edit Node! The node has non-existent UID as the target character:",
                            this.the_character_id,
                            this.node_resource
                        );
                    }
                } else {
                    if (_VERBOSE) console.warn(
                        "Invalid Tag-Edit Node! The node has no valid data set or target character.",
                        this.node_resource
                    );
                }
                // Create the node html element
                this.html = create_node_base_html(node_id, node_resource);
                    // ... and the children
                    if (is_valid) {
                        var edition = this.node_resource.data.edit
                        this.tag_edition = create_element("code",
                            `${this.the_character.name}.${edition[1]} << [${METHODS[edition[0]]}] '${edition[2]}'`,
                            {
                                style: `--character-color: #${this.the_character.color};`,
                                "data-character-id": this.the_character_id,
                                "data-character-name": this.the_character.name,
                            }
                        );
                        this.html.appendChild(this.tag_edition);
                    } else {
                        this.invalid_tag_edit = create_element("span", `[Tag-Edit] ${this.node_resource.name} : ${ i18n("invalid") }`);
                        this.html.appendChild(this.invalid_tag_edit);
                    }
                    // manual application button,
                    if (is_valid){
                        this.apply_button = create_element("button", i18n("apply"));
                        this.apply_button.addEventListener( _CLICK, this.process_tag_edit_forward.bind(_self) );
                        this.html.appendChild(this.apply_button);
                    }
                    // and skip button (used in manual play and step-backs)
                    this.skip_button = create_element("button", i18n("skip"));
                    this.skip_button.addEventListener( _CLICK, this.skip_play.bind(_self) );
                    this.html.appendChild(this.skip_button);
            }
            return this;
        }
        throw new Error("Unable to construct `VariableUpdate`");
    }

}
