# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Macro_Use Node Type Console
extends PanelContainer

signal play_forward
signal status_code
# warning-ignore:unused_signal
signal clear_up
# warning-ignore:unused_signal
signal reset_variable

onready var Main = get_tree().get_root().get_child(0)

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

# this reference will be used by the main console (~ as sub-terminal/sub-console)
const MACRO_TERMINAL_REL_PATH = "./MacroUsePlay/PanelContainer/MacroUseSubConsole"

onready var MacroUseName = get_node("./MacroUsePlay/MacroUseTitle/Name")
onready var SkipButton = get_node("./MacroUsePlay/SkipMacro")

func _ready() -> void:
	register_connections()
	_NODE_IS_READY = true
	if _PLAY_IS_SET_UP:
		setup_view()
	if _DEFERRED_VIEW_PLAY_SLOT >= 0:
		set_view_played(_DEFERRED_VIEW_PLAY_SLOT)
	pass

func register_connections() -> void:
	SkipButton.connect("pressed", self, "play_macro_use_forward", [], CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

func setup_view() -> void:
	if _NODE_RESOURCE.has("name"):
		MacroUseName.set_text(_NODE_RESOURCE.name)
	pass
	
func setup_play(node_id:int, node_resource:Dictionary, node_map:Dictionary, _playing_in_slot:int = -1, _variables_current:Dictionary={}) -> void:
	_NODE_ID = node_id
	_NODE_RESOURCE = node_resource
	_NODE_MAP = node_map
	remap_connections_for_slots()
	# update fields and children
	if _NODE_IS_READY:
		setup_view()
	# handle skip in case
	if _NODE_MAP.has("skip") && _NODE_MAP.skip == true:
		skip_play()
		# otherwise wait for further user interactions
	_PLAY_IS_SET_UP = true
	pass

# currently, there is only one slot out (one forward) possible for any instance of `macro_use`
# this function is called by the main console's `macro_use_treatment_unload`
# when the macro is left or run out (END_EDGE) or by `skip` button being pressed
func play_macro_use_forward() -> void:
	play_forward_from(PLAY_MACRO_END_SLOT)
	pass

func play_forward_from(slot_idx:int = PLAY_MACRO_END_SLOT) -> void:
	if slot_idx >= 0:
		if _NODE_SLOTS_MAP.has(slot_idx):
			var next = _NODE_SLOTS_MAP[slot_idx]
			self.emit_signal("play_forward", next.id, next.slot)
		else:
			emit_signal("status_code", CONSOLE_STATUS_CODE.END_EDGE)
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

func set_view_played(slot_idx:int = PLAY_MACRO_END_SLOT) -> void:
	SkipButton.set("visible", false)
	pass

func skip_play() -> void:
	# notify user of no action being taken
	emit_signal("status_code", CONSOLE_STATUS_CODE.NO_DEFAULT)
	pass

func step_back() -> void:
	set_view_unplayed()
	pass
	
