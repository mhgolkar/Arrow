# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Jump Console Element
extends Control

signal play_forward
signal status_code
# signal clear_up
# signal reset_variables
# signal reset_characters_tags

@onready var Main = get_tree().get_root().get_child(0)

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY:bool = false

@onready var Reason:Label = $Play/Head/Reason
@onready var Action:Button = $Play/Action

const UNSET_REASON_MESSAGE = "JUMP_CONSOLE_UNSET_REASON_MSG" # Translated ~ "No Reason"
const JUMP_TARGET_LABEL_FORMAT_STRING = (
	"{target_name}" if Settings.FORCE_UNIQUE_NAMES_FOR_NODES else "{target_name} ({target_uid})"
)

func _ready() -> void:
	register_connections()
	_NODE_IS_READY = true
	if _PLAY_IS_SET_UP:
		setup_view()
		proceed_auto_play()
	if _DEFERRED_VIEW_PLAY:
		set_view_played()
	pass

func register_connections() -> void:
	Action.pressed.connect(self.play_forward_the_jump, CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

func setup_view() -> void:
	# Jump action label (identity of the jump and its target)
	var label = { "jump": tr("JUMP_CONSOLE_INVALID_MSG"), "target_name": tr("JUMP_CONSOLE_UNSET_TARGET_MSG"), "target_uid": "-1" }
	if _NODE_RESOURCE.has("name"):
		label.jump = _NODE_RESOURCE.name
	if _NODE_RESOURCE.has("data"):
		if _NODE_RESOURCE.data.has("target") && (_NODE_RESOURCE.data.target is int) && _NODE_RESOURCE.data.target >= 0:
			label.target_uid = _NODE_RESOURCE.data.target
			var the_target = Main.Mind.lookup_resource(_NODE_RESOURCE.data.target, "nodes")
			label.target_name = the_target.name
	Action.set_text( JUMP_TARGET_LABEL_FORMAT_STRING.format(label) )
	# Jump's reason
	if _NODE_RESOURCE.has("data") && _NODE_RESOURCE.data.has("reason") && (_NODE_RESOURCE.data.reason is String) && _NODE_RESOURCE.data.reason.length() > 0:
		Reason.set_text( _NODE_RESOURCE.data.reason )
	else:
		Reason.set_text( UNSET_REASON_MESSAGE )
	# ...
	This.set("tooltip_text", (_NODE_RESOURCE.notes if _NODE_RESOURCE.has("notes") else ""))
	pass
	
func setup_play(
	node_id:int, node_resource:Dictionary, node_map:Dictionary, _playing_in_slot:int = -1,
	_variables_current:Dictionary={}, _characters_current:Dictionary={}
) -> void:
	_NODE_ID = node_id
	_NODE_RESOURCE = node_resource
	_NODE_MAP = node_map
	remap_connections_for_slots()
	# update fields and children
	if _NODE_IS_READY:
		setup_view()
		proceed_auto_play()
	_PLAY_IS_SET_UP = true
	pass

func proceed_auto_play() -> void:
	if Main.Mind.Console._ALLOW_AUTO_PLAY:
		# always auto-play next node (i.e. the jump destination)
		# unless it's a skipped jump, which means ...
		if _NODE_MAP.has("skip") && _NODE_MAP.skip == true:
			skip_play() # ... ending with status_code
			# because jumps have no outgoing slot
		else:
			play_forward_the_jump()
	else:
		set_view_unplayed()
	pass

func play_forward_the_jump() -> void:
	if _NODE_RESOURCE.has("data") && _NODE_RESOURCE.data.has("target") && (_NODE_RESOURCE.data.target is int) && _NODE_RESOURCE.data.target >= 0 :
		self.play_forward.emit(_NODE_RESOURCE.data.target, 0)
	else:
		self.status_code.emit(CONSOLE_STATUS_CODE.END_EDGE)
	set_view_played_on_ready()
	pass

func set_view_played_on_ready() -> void:
	if _NODE_IS_READY:
		set_view_played()
	else:
		_DEFERRED_VIEW_PLAY = true
	pass

func set_view_unplayed() -> void:
	Action.set_deferred("flat", false)
	Action.set_deferred("disabled", false)
	pass

func set_view_played() -> void:
	Action.set_deferred("flat", true)
	Action.set_deferred("disabled", true)
	pass

func skip_play() -> void:
	self.status_code.emit(CONSOLE_STATUS_CODE.NO_DEFAULT)
	pass

func step_back() -> void:
	set_view_unplayed()
	pass
