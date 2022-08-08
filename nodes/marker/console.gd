# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Marker Node Type Console
extends PanelContainer

signal play_forward
signal status_code
# warning-ignore:unused_signal
signal clear_up
# warning-ignore:unused_signal
signal reset_variable

onready var Main = get_tree().get_root().get_child(0)

var Utils = Helpers.Utils

const AUTO_PLAY_SLOT = 0

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

onready var MarkerName:Label = get_node("./MarkerPlay/Head/MarkerName")
onready var MarkerLabel:Button = get_node("./MarkerPlay/MarkerLabel")

const LABEL_UNSET_MESSAGE = "Unlabeled"
const LABEL_UNSET_SELF_MODULATION_COLOR  = Color(1, 1, 1, 0.30)

const NO_NOTES_MESSAGE = "Marker Has No Extra Information."

func _ready() -> void:
	register_connections()
	_NODE_IS_READY = true
	if _PLAY_IS_SET_UP:
		setup_view()
	if _DEFERRED_VIEW_PLAY_SLOT >= 0:
		set_view_played(_DEFERRED_VIEW_PLAY_SLOT)
	pass

func register_connections() -> void:
	MarkerLabel.connect("pressed", self, "play_forward_from", [AUTO_PLAY_SLOT], CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

func setup_view() -> void:
	MarkerName.set_text(_NODE_RESOURCE.name)
	if _NODE_RESOURCE.data.label.length() > 0:
		MarkerLabel.set_text(_NODE_RESOURCE.data.label)
	else:
		MarkerLabel.set_text(LABEL_UNSET_MESSAGE)
		MarkerLabel.set_deferred("self_modulate", LABEL_UNSET_SELF_MODULATION_COLOR)
	MarkerLabel.set("hint_tooltip", (_NODE_RESOURCE.notes if _NODE_RESOURCE.has("notes") else NO_NOTES_MESSAGE))
	self.set("self_modulate", Utils.rgba_hex_to_color(_NODE_RESOURCE.data.color))
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
	# otherwise auto-play if set
	elif AUTO_PLAY_SLOT >= 0:
		play_forward_from(AUTO_PLAY_SLOT)
	_PLAY_IS_SET_UP = true
	pass

func play_forward_from(slot_idx:int = AUTO_PLAY_SLOT) -> void:
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
	MarkerLabel.set("flat", false)
	MarkerLabel.set("disabled", false)
	pass

func set_view_played(slot_idx:int = AUTO_PLAY_SLOT) -> void:
	MarkerLabel.set("flat", true)
	MarkerLabel.set("disabled", true)
	pass

func skip_play() -> void:
	# play the AUTO (and only) play slot anyway
	# as if this node is just part of a direct connection with no side effects
	play_forward_from(AUTO_PLAY_SLOT)
	pass

func step_back() -> void:
	set_view_unplayed()
	pass
	
