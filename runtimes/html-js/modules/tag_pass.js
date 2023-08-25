// Arrow HTML-JS Runtime: Tag-Pass node module

class TagPass {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;
        
        const FALSE_SLOT = 0;
        const TRUE_SLOT  = 1;
        
        const METHODS = {
            0: "Any (OR)", // If at least one of the tags matches, it short-circuits and passes.
            1: "All (AND)", // All tags shall match for the node to pass.
        }

        this.the_character = null;
        this.the_character_id = null;

        this.get_element = function () {
            return this.html;
        };
        
        this.remove_element = function() {
            this.html.remove();
        };
        
        this.play_forward_from = function(slot_idx){
            slot_idx = parseInt(slot_idx);
            if ( Number.isFinite(slot_idx) == false || slot_idx < 0 || slot_idx > 1 ){
                // We default to `false` anytime something is wrong but we can continue
                slot_idx = FALSE_SLOT; 
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
            // Skipped? The convention is to ...
            this.html.setAttribute('data-skipped', true);
            // ... react by playing the *False Slot First*
            if ( this.slots_map.hasOwnProperty(FALSE_SLOT) ){ // if false slot is connected
                this.play_forward_from(FALSE_SLOT);
            } else { // otherwise playing the *Only Remained [Possibly Connected] True Slot*
                this.play_forward_from(TRUE_SLOT); // which ...
            } // ... will naturally end the plot line if the true slot is not connected
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
        
        this.tag_is_checkable = function(entity){
            return (
                Array.isArray(entity) && entity.length >= 1 && // at least a key
                (typeof entity[0] == 'string') && entity[0].length > 0 && // valid key
                (entity.length == 1 || entity[1] === null || (typeof entity[1] == 'string')) // valid value (including unchecked)
            )
        };

        this.process_tag_pass_forward = function(){
            var shall_pass = false;
            if ( this.the_character != null ){ // (~ means validity checks are passed)
                var current_tags = (
                    (this.the_character.hasOwnProperty("tags") && (typeof this.the_character.tags == 'object'))
                    ? this.the_character.tags : {}
                );
                var method = this.node_resource.data.pass[0];
                var checks = this.node_resource.data.pass[1];
                for (var i = 0; i < checks.length; i++){
                    var entity = checks[i];
                    if ( this.tag_is_checkable(entity) ){
                        shall_pass = (
                            current_tags.hasOwnProperty( entity[0] ) &&
                            ( entity.length == 1 || entity[1] == null || entity[1] == current_tags[entity[0]] )
                        );
                        if (method == 0 && shall_pass == true) break; // Any (OR) : short-circuits when reaches the first true
                        if (method == 1 && shall_pass == false) break; // All (AND) : breaks false if any one false is reached
                    }
                }
            }
            this.play_forward_from(
                (shall_pass == true) ? TRUE_SLOT : FALSE_SLOT
            );
        };
        
        this.proceed = function(){
            if (_ALLOW_AUTO_PLAY) {
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play();
                } else {
                    this.process_tag_pass_forward();
                }
            }
        };
        
        this.data_is_valid = function(data){
            return (
                data != null && (typeof data == 'object') &&
                data.hasOwnProperty("character") && (Number.isInteger( safeInt(data.character) ) && safeInt(data.character) >= 0) &&
                data.hasOwnProperty("pass") && Array.isArray(data.pass) && data.pass.length >= 2 &&
                Number.isInteger(data.pass[0]) && METHODS.hasOwnProperty(data.pass[0]) && Array.isArray(data.pass[1])
		        // && Invalid tags are dropped/ignored, so we don't need to check deeper
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
                            "Invalid Tag-Pass Node! The node has non-existent UID as the target character:",
                            this.the_character_id,
                            this.node_resource
                        );
                    }
                } else {
                    if (_VERBOSE) console.warn(
                        "Invalid Tag-Pass Node! The node has no valid data set or target character.",
                        this.node_resource
                    );
                }
                // Create the node html element
                this.html = create_node_base_html(node_id, node_resource);
                    // ... and the children
                    // Tags:
                    if (is_valid) {
                        var method = this.node_resource.data.pass[0];
                        var checks = this.node_resource.data.pass[1];
                        var checkable = 0;
                        var checkable_tags = create_element("div", `${this.the_character.name}: ${METHODS[method]}`);
                        for (var i = 0; i < checks.length; i++){
                            var entity = checks[i];
                            if (this.tag_is_checkable(entity)){
                                checkable += 1;
                                var checked_value = (entity.length >= 1 && (typeof entity[1] == 'string')) ? `'${entity[1]}'` : null;
                                checkable_tags.appendChild(
                                    create_element("span", `${ entity[0] }: ${ checked_value || "*" }`)
                                )
                            }
                        }
                        this.tag_passage = create_element("code",
                            ( checkable > 0 ? checkable_tags : `No Tags To Check` ),
                            {
                                style: `--character-color: #${this.the_character.color};`,
                                "data-character-id": this.the_character_id,
                                "data-character-name": this.the_character.name,
                            }
                        );
                        this.html.appendChild(this.tag_passage);
                    } else {
                        this.invalid_tag_pass = create_element("span", `[Tag-Pass] ${this.node_resource.name} : ${ i18n("invalid") }`);
                        this.html.appendChild(this.invalid_tag_pass);
                    }
                    // False:
                    this.false_button = create_element("button", i18n("false"), { "value": "false" });
                    this.false_button.addEventListener( _CLICK, this.play_forward_from.bind(_self, FALSE_SLOT) );
                    this.html.appendChild(this.false_button);
                    // True:
                    this.true_button = create_element("button", i18n("true"), { "value": "true" });
                    this.true_button.addEventListener( _CLICK, this.play_forward_from.bind(_self, TRUE_SLOT) );
                    this.html.appendChild(this.true_button);
            }
            return this;
        }
        throw new Error("Unable to construct `TagPass`");
    }

}
