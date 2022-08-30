// Arrow HTML-JS Runtime: Jump node module

class Jump {
    
    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;
        
        this.get_element = function () {
            return this.html;
        };
        
        this.remove_element = function() {
            this.html.remove();
        };
        
        this.play_forward_the_jump = function(){
            if (this.node_resource.hasOwnProperty("data") && this.node_resource.data.hasOwnProperty("target") && Number.isInteger(this.node_resource.data.target) && this.node_resource.data.target >= 0 ){
                play_node(this.node_resource.data.target, 0);
            } else {
                handle_status(_CONSOLE_STATUS_CODE.END_EDGE, _self);
            }
            this.set_view_played();
        };
        
        this.skip_play = function() {
            this.html.setAttribute('data-skipped', true);
            // `jump`s have no default action when they are skipped
            handle_status(_CONSOLE_STATUS_CODE.NO_DEFAULT, _self);
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
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play();
                } else {
                    this.play_forward_the_jump();
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
                this.html.setAttribute('data-target',  node_resource.data.target);
                    // ... and the children
                    // Reason or a mark:
                    if (
                        node_resource.hasOwnProperty("data") && node_resource.data.hasOwnProperty("reason") &&
                        typeof node_resource.data.reason == 'string' && node_resource.data.reason.length > 0
                    ) {
                        this.reason = create_element("em", node_resource.data.reason, {'class': 'reason'});
                        this.html.appendChild(this.reason);
                    } else {
                        this.jump_mark = create_element("span", "[Jump]");
                        this.html.appendChild(this.jump_mark);
                    }
                    // Manual play button:
                    this.jump_button = create_element("button", `${node_resource.name} > ${node_resource.data.target}`);
                    this.jump_button.addEventListener( _CLICK, this.play_forward_the_jump.bind(_self) );
                    this.html.appendChild(this.jump_button);
            }
            return this;
        }
        throw new Error("Unable to construct `Jump`");
    }

}
