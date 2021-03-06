# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Jump Node Type Console
extends MarginContainer

signal play_forward
signal status_code
# warning-ignore:unused_signal
signal clear_up
# warning-ignore:unused_signal
signal reset_variable

onready var Main = get_tree().get_root().get_child(0)

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY:bool = false

onready var TargetName:Button = get_node("./JumpPlay/TargetName")

const REASON_TEXT_UNSET_MESSAGE = "No Reason"

func _ready() -> void:
	register_connections()
	_NODE_IS_READY = true
	if _PLAY_IS_SET_UP:
		setup_view()
	if _DEFERRED_VIEW_PLAY:
		set_view_played()
	pass

func register_connections() -> void:
	TargetName.connect("pressed", self, "play_forward_the_jump", [], CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

func setup_view() -> void:
	# Jump's name
	if _NODE_RESOURCE.has("name"):
		TargetName.set_text(_NODE_RESOURCE.name)
	else:
		printerr("Node %s data seems corrupt! It lacks `name` key in the resource dictionary." % _NODE_ID)
	# Jump's reason
	if _NODE_RESOURCE.has("data") && _NODE_RESOURCE.data.has("reason") && (_NODE_RESOURCE.data.reason is String):
		TargetName.set("hint_tooltip", _NODE_RESOURCE.data.reason )
	else:
		TargetName.set("hint_tooltip", REASON_TEXT_UNSET_MESSAGE )
	pass
	
func setup_play(node_id:int, node_resource:Dictionary, node_map:Dictionary, _playing_in_slot:int = -1, _variables_current:Dictionary={}) -> void:
	_NODE_ID = node_id
	_NODE_RESOURCE = node_resource
	_NODE_MAP = node_map
	remap_connections_for_slots()
	# update fields and children
	if _NODE_IS_READY:
		setup_view()
	# always auto-play next node (i.e. the jump destination)
	# unless it's a skipped jump, which means ...
	if _NODE_MAP.has("skip") && _NODE_MAP.skip == true:
		skip_play() # ... ending with status_code
	else:
		play_forward_the_jump()
	_PLAY_IS_SET_UP = true
	pass

func play_forward_the_jump() -> void:
	if _NODE_RESOURCE.has("data") && _NODE_RESOURCE.data.has("target") && (_NODE_RESOURCE.data.target is int) && _NODE_RESOURCE.data.target >= 0 :
		emit_signal("play_forward", _NODE_RESOURCE.data.target, 0)
	else:
		emit_signal("status_code", CONSOLE_STATUS_CODE.END_EDGE)
	set_view_played_on_ready()
	pass

func set_view_played_on_ready() -> void:
	if _NODE_IS_READY:
		set_view_played()
	else:
		_DEFERRED_VIEW_PLAY = true
	pass

func set_view_unplayed() -> void:
	TargetName.set_deferred("flat", false)
	TargetName.set_deferred("disabled", false)
	pass

func set_view_played() -> void:
	TargetName.set_deferred("flat", true)
	TargetName.set_deferred("disabled", true)
	pass

func skip_play() -> void:
	emit_signal("status_code", CONSOLE_STATUS_CODE.NO_DEFAULT)
	pass

func step_back() -> void:
	set_view_unplayed()
	pass
	
