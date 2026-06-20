# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Jump Sub-Inspector
extends Control

@onready var Main = get_tree().get_root().get_child(0)

const DEFAULT_NODE_DATA = {
	"scene": -1, # node resource-id to get jumped into 
	"description": ""
}

var _OPEN_NODE_ID
var _OPEN_NODE

var _PROJECT_SCENES_CACHE = {}

var This = self

@onready var ScenesInspector = Main.Mind.Inspector.Tab.Scenes

@onready var GlobalFilters = $Selector/Filtered
@onready var Scene = $Selector/List
@onready var Description = $Description

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	GlobalFilters.pressed.connect(self.refresh_scene_list, CONNECT_DEFERRED)
	pass
	
func refresh_scene_list(select_by_res_id:int = -1) -> void:
	Scene.clear()
	_PROJECT_SCENES_CACHE = Main.Mind.clone_dataset_of("scenes", {}, { "macro": null })
	var already = null
	if a_node_is_open() && _OPEN_NODE.data.has("scene") && _OPEN_NODE.data.scene in _PROJECT_SCENES_CACHE :
		already = _OPEN_NODE.data.scene
	var global_filters = ScenesInspector.read_listing_instruction()
	var apply_globals = GlobalFilters.is_pressed()
	var listing = {}
	for scene_id in _PROJECT_SCENES_CACHE:
		var the_scene = _PROJECT_SCENES_CACHE[scene_id]
		if scene_id == already || apply_globals == false || ScenesInspector.passes_filters(global_filters, scene_id, the_scene):
			listing[the_scene.name] = scene_id
	var listing_keys = listing.keys()
	if apply_globals && global_filters.SORT_ALPHABETICAL:
		listing_keys.sort()
	for scene_name in listing_keys:
		var id = listing[scene_name]
		Scene.add_item(scene_name if already != id || apply_globals == false else "["+ scene_name +"]", id)
	if select_by_res_id >= 0 :
		var scene_item_index = Scene.get_item_index( select_by_res_id )
		Scene.select( scene_item_index )
	else:
		if already != null :
			var scene_item_index = Scene.get_item_index(already)
			Scene.select( scene_item_index )
	pass

func _update_parameters(node_id:int, node:Dictionary, do_cache:bool = true) -> void:
	# first cache the node (if it's not a history point being restored)
	if do_cache:
		_OPEN_NODE_ID = node_id
		_OPEN_NODE = node
	# ... then update parameters
	Scene.clear()
	Description.clear()
	refresh_scene_list()
	if node.has("data") && node.data is Dictionary:
		if node.data.has("scene") && (node.data.scene is int) && (node.data.scene >= 0):
			var scene = Main.Mind.lookup_resource(node.data.scene, "scenes")
			if (scene is Dictionary) && scene.has("name") && (scene.name is String):
				Scene.select( Scene.get_item_index( node.data.scene ) )
		if node.data.has("description") && (node.data.description is String) && (node.data.description.length() > 0):
			Description.set_text(node.data.description)
	pass

func warn_jump_loop(extra_message:String = "Parameter reset!") -> void:
	printerr("Warn! You shall not make loop jumps. They will crash your project. ", extra_message)
	pass

func _read_parameters() -> Dictionary:
	var parameters = {
		"scene": -1, # will be updated down there
		"description": Description.get_text()
	}
	var scene_id = Scene.get_selected_id()
	# Only set if id is valid
	if scene_id >= 0:
		parameters.scene = scene_id
	else:
		# ... otherwise leave it as it was
		if _OPEN_NODE.data.scene is int:
			parameters.scene = _OPEN_NODE.data.scene
		else:
			parameters.scene = -1
	
	# now attach `_use` command in case
	if parameters.scene != _OPEN_NODE.data.scene:
		var _use = { "drop": [], "refer": [], "field": "nodes"}
		if parameters.scene >= 0:
			_use.refer.append(parameters.scene)
		if _OPEN_NODE.data.scene >= 0:
			_use.drop.append(_OPEN_NODE.data.scene)
		if _use.drop.size() > 0 || _use.refer.size() > 0 :
			parameters._use = _use
	return parameters

func _create_new(_new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data

func _translate_internal_ref(data: Dictionary, translation: Dictionary) -> void:
	if translation.ids.has(data.scene):
		data.scene = translation.ids[data.scene]
	pass

func a_node_is_open() -> bool :
	if (
		(_OPEN_NODE_ID is int) && (_OPEN_NODE_ID >= 0) &&
		(_OPEN_NODE is Dictionary) &&
		_OPEN_NODE.has("data") && (_OPEN_NODE.data is Dictionary)
	):
		return true
	else:
		return false
