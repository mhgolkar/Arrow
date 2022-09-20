# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Entry Node Type Console
extends MarginContainer

signal play_forward
signal status_code
# signal clear_up
# signal reset_variables
# signal reset_characters_tags

onready var Main = get_tree().get_root().get_child(0)

# auto-plays the one outgoing slot
const AUTO_PLAY_SLOT = 0

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

onready var EntryLabel:Button = get_node("./EntryPlay/EntryLabel")
onready var IsSceneEntryIndicator = get_node("./EntryPlay/IsSceneEntryIndicator")
onready var IsProjectEntryIndicator = get_node("./EntryPlay/IsProjectEntryIndicator")

const ENTRY_LABEL_FORMAT_STRING = "{name}: {plaque}"

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
	EntryLabel.connect("pressed", self, "play_forward_from", [AUTO_PLAY_SLOT], CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

func setup_view() -> void:
	var label = { "name": "Invalid", "plaque": "Unset" }
	if _NODE_RESOURCE.has("name"):
		label.name = _NODE_RESOURCE.name
	if _NODE_RESOURCE.has("data"):
		if _NODE_RESOURCE.data.has("plaque") && (_NODE_RESOURCE.data.plaque is String) && _NODE_RESOURCE.data.plaque.length() > 0:
			label.plaque = _NODE_RESOURCE.data.plaque
	EntryLabel.set_text(ENTRY_LABEL_FORMAT_STRING.format(label))
	IsSceneEntryIndicator.set_deferred("visible", _NODE_ID == Main.Mind.get_scene_entry())
	IsProjectEntryIndicator.set_deferred("visible", _NODE_ID == Main.Mind.get_project_entry())
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
		# handle skip in case
		if _NODE_MAP.has("skip") && _NODE_MAP.skip == true:
			skip_play()
		# otherwise auto-play if set
		elif AUTO_PLAY_SLOT >= 0:
			play_forward_from(AUTO_PLAY_SLOT)
	else:
		set_view_unplayed()
	pass

func play_forward_from(slot_idx:int = AUTO_PLAY_SLOT) -> void:
	if slot_idx >= 0:
		if _NODE_SLOTS_MAP.has(slot_idx):
			var next = _NODE_SLOTS_MAP[slot_idx]
			emit_signal("play_forward", next.id, next.slot)
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
	EntryLabel.set_deferred("flat", false)
	EntryLabel.set_deferred("disabled", false)
	pass

func set_view_played(slot_idx:int = AUTO_PLAY_SLOT) -> void:
	EntryLabel.set_deferred("flat", true)
	EntryLabel.set_deferred("disabled", true)
	pass

func skip_play() -> void:
	# naturally auto-plays anyway even on skip
	play_forward_from(AUTO_PLAY_SLOT)
	pass

func step_back() -> void:
	set_view_unplayed()
	pass
	
