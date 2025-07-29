# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Macro-Use Console Element
extends Control

signal play_forward
signal status_code
# signal clear_up
# signal reset_variables
# signal reset_characters_tags

@onready var Main = get_tree().get_root().get_child(0)

# there is only one slot that may be connected
# (to another node in the parent scene)
const PLAY_MACRO_END_SLOT = 0

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

@onready var MacroUseLabel = $Play/Head/Title
@onready var SkipButton = $Play/Actions/Skip
@onready var ReplayButton = $Play/Actions/Replay

@onready var TERMINAL = $Play/SubConsole/Terminal

const MACRO_USE_LABEL_FORMAT_STRING = (
	"{user}: {target_name}" if Settings.FORCE_UNIQUE_NAMES_FOR_SCENES_AND_MACROS else "{user}: {target_name} ({target_uid})"
)

func _ready() -> void:
	register_connections()
	_NODE_IS_READY = true
	if _PLAY_IS_SET_UP:
		setup_view()
		proceed_auto_play()
	if _DEFERRED_VIEW_PLAY_SLOT >= 0:
		set_view_played(_DEFERRED_VIEW_PLAY_SLOT)
	pass

func register_connections() -> void:
	SkipButton.pressed.connect(self.play_forward_from, CONNECT_DEFERRED)
	ReplayButton.pressed.connect(self.replay_macro, CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

func setup_view() -> void:
	var label = { "user": tr("MACRO_USE_CONSOLE_INVALID_MSG"), "target_name": tr("MACRO_USE_CONSOLE_UNSET_TARGET_MSG"), "target_uid": "-1" }
	if _NODE_RESOURCE.has("name"):
		label.user = _NODE_RESOURCE.name
	if _NODE_RESOURCE.has("data"):
		if _NODE_RESOURCE.data.has("macro") && (_NODE_RESOURCE.data.macro is int) && _NODE_RESOURCE.data.macro >= 0:
			label.target_uid = _NODE_RESOURCE.data.macro
			var the_macro = Main.Mind.lookup_resource(_NODE_RESOURCE.data.macro, "scenes")
			label.target_name = the_macro.name
	MacroUseLabel.set_text( MACRO_USE_LABEL_FORMAT_STRING.format(label) )
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

func append_subnode(node_instance) -> void:
	TERMINAL.call_deferred("add_child", node_instance)
	reset_replay(false)
	pass

func reset_replay(force: bool = false) -> void:
	ReplayButton.set_disabled(! force)
	ReplayButton.set_visible(force)
	pass

func replay_macro() -> void:
	if (
		_NODE_RESOURCE.has("data") && _NODE_RESOURCE.data is Dictionary &&
		_NODE_RESOURCE.data.has("macro") && (_NODE_RESOURCE.data.macro is int) &&
		_NODE_RESOURCE.data.macro >= 0
	):
		var the_macro = Main.Mind.lookup_resource(_NODE_RESOURCE.data.macro, "scenes")
		if (
			the_macro is Dictionary &&
			the_macro.has("entry") && the_macro.entry is int && the_macro.entry >= 0
		):
			self.play_forward.emit(the_macro.entry, 0)
		else:
			print(
				"Macro-use %s skipped, trying to run macro %s with no valid entry (%s)"
				% [_NODE_ID, _NODE_RESOURCE.data.macro, the_macro]
			)
			skip_play()
	else:
		skip_play()
	pass

func proceed_auto_play() -> void:
	if Main.Mind.Console._ALLOW_AUTO_PLAY:
		if _NODE_MAP.has("skip") && _NODE_MAP.skip == true:
			skip_play()
		else:
			replay_macro()
	else:
		reset_replay(true)
	pass

func play_forward_from(slot_idx:int = PLAY_MACRO_END_SLOT) -> void:
	if slot_idx >= 0:
		if _NODE_SLOTS_MAP.has(slot_idx):
			var next = _NODE_SLOTS_MAP[slot_idx]
			self.play_forward.emit(next.id, next.slot)
		else:
			self.status_code.emit(CONSOLE_STATUS_CODE.END_EDGE)
		set_view_played_on_ready(slot_idx)
	pass

func set_view_played_on_ready(slot_idx:int) -> void:
	if _NODE_IS_READY:
		set_view_played(slot_idx)
	else:
		_DEFERRED_VIEW_PLAY_SLOT = slot_idx
	pass

func set_view_unplayed() -> void:
	SkipButton.set("visible", true)
	pass

func set_view_played(_slot_idx:int = PLAY_MACRO_END_SLOT) -> void:
	SkipButton.set("visible", false)
	reset_replay(false)
	pass

func skip_play() -> void:
	play_forward_from(PLAY_MACRO_END_SLOT)
	pass

func step_back() -> void:
	reset_replay(true)
	set_view_unplayed()
	pass
	