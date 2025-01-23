# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Entry Sub-Inspector
extends Control

@onready var Main = get_tree().get_root().get_child(0)

const DEFAULT_NODE_DATA = {
	"plaque": "",
	# to make this entry active for a scene, macro or a project, we can add:
	# _as_entry: { { node_id:node_resource_uid, for_scene:bool, for_project:bool }
}

var _OPEN_NODE_ID
var _OPEN_NODE

var _ALREADY_SCENE_ENTRY = false
var _ALREADY_PROJECT_ENTRY = false

var This = self

@onready var Plaque = $Plaque
@onready var SetAsProjectEntry = $ForProject
@onready var SetAsSceneOrMacroEntry = $ForScene

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	# ... then update parameters
	if node.has("data") && node.data is Dictionary:
		if node.data.has("plaque") && node.data.plaque is String:
			Plaque.set_text(node.data.plaque)
		else:
			Plaque.clear()
	# hide respective inputs
	# when the node is already an active entry of some kind
	_ALREADY_SCENE_ENTRY = ( Main.Mind.get_scene_entry() == _OPEN_NODE_ID)
	_ALREADY_PROJECT_ENTRY = ( Main.Mind.get_project_entry() == _OPEN_NODE_ID )
	SetAsSceneOrMacroEntry.set_disabled(_ALREADY_SCENE_ENTRY)
	SetAsSceneOrMacroEntry.set_pressed(_ALREADY_SCENE_ENTRY)
	SetAsProjectEntry.set_disabled(_ALREADY_PROJECT_ENTRY)
	SetAsProjectEntry.set_pressed(_ALREADY_PROJECT_ENTRY)
	pass

func _read_parameters() -> Dictionary:
	var parameters = {
		"plaque": Plaque.get_text(),
	}
	# is it going to be an active entry ?
	var for_project_entry = SetAsProjectEntry.is_pressed()
	var for_scene_or_macro_entry = SetAsSceneOrMacroEntry.is_pressed()
	if for_project_entry || for_scene_or_macro_entry :
		var update_entry = false
		var _as_entry = { "node_id": _OPEN_NODE_ID }
		if for_project_entry == true && _ALREADY_PROJECT_ENTRY == false:
			_as_entry["for_project"] = true
			update_entry = true
		if for_scene_or_macro_entry == true && _ALREADY_SCENE_ENTRY == false:
			_as_entry["for_scene"] = true
			update_entry = true
		if update_entry == true:
			parameters["_as_entry"] = _as_entry
	return parameters

func _create_new(_new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data

static func map_i18n_data(id: int, node: Dictionary) -> Dictionary:
	var base_key = String.num_int64(id) + "-entry-"
	return {
		base_key + "plaque": node.data.plaque,
	}
