# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Jump Sub-Inspector
extends Control

@onready var Main = get_tree().get_root().get_child(0)

const DEFAULT_NODE_DATA = {
	"reason": ""
}

var _OPEN_NODE_ID
var _OPEN_NODE

var This = self

@onready var Reason = $Reason

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	pass

func _update_parameters(node_id:int, node:Dictionary, do_cache:bool = true) -> void:
	# first cache the node (if it's not a history point being restored)
	if do_cache:
		_OPEN_NODE_ID = node_id
		_OPEN_NODE = node
	# ... then update parameters
	Reason.clear()
	if node.has("data") && node.data is Dictionary:
		if node.data.has("reason") && (node.data.reason is String) && (node.data.reason.length() > 0):
			Reason.set_text(node.data.reason)
	pass

func _read_parameters() -> Dictionary:
	var parameters = {
		"reason": Reason.get_text()
	}

	# ...
	# TODO implement _use() command
	# ...
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
