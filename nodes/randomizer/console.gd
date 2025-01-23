# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Randomizer Console Element
extends Control

signal play_forward
signal status_code
# signal clear_up
# signal reset_variables
# signal reset_characters_tags

@onready var Main = get_tree().get_root().get_child(0)

# if `true` tries to automatically play a randomly chosen slot
const AUTO_PLAY = true

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary
var _SLOTS_COUNT:int = RandomizerSharedClass.RANDOMIZER_MINIMUM_ACCEPTABLE_OUT_SLOTS

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

@onready var RandomizerName:Button = $Play/Name
@onready var SlotsCount:Label = $Play/SlotsCount

const ERROR_SLOT_NUMBER_MESSAGE = "ERR"
const SLOTS_COUNT_TEMPLATE = "[%s]"

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
	RandomizerName.pressed.connect(self.play_forward_randomly, CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

func setup_view() -> void:
	# the randomizer's name
	if _NODE_RESOURCE.has("name"):
		RandomizerName.set_text(_NODE_RESOURCE.name)
	else:
		printerr("Node %s data seems corrupt! It lacks `name` key in the resource dictionary." % _NODE_ID)
	# the randomizer's slot count
	if _NODE_RESOURCE.has("data") && _NODE_RESOURCE.data.has("slots") && (_NODE_RESOURCE.data.slots is int):
		_SLOTS_COUNT = _NODE_RESOURCE.data.slots
		SlotsCount.set_text( SLOTS_COUNT_TEMPLATE % _NODE_RESOURCE.data.slots )
	else:
		SlotsCount.set_text( ERROR_SLOT_NUMBER_MESSAGE )
		printerr("Unexpected Behavior! Hub doesn't have `slots` data/property.")
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
		elif AUTO_PLAY :
			play_forward_randomly()
	else:
		set_view_unplayed()
	pass

func play_forward_randomly() -> void:
	var random_slot_idx = ( randi() % _SLOTS_COUNT )
	play_forward_from(random_slot_idx)
	pass

func play_forward_from(slot_idx:int = -1) -> void:
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
	RandomizerName.set_deferred("flat", false)
	RandomizerName.set_deferred("disabled", false)
	pass

func set_view_played(_slot_idx:int = -1) -> void:
	RandomizerName.set_deferred("flat", true)
	RandomizerName.set_deferred("disabled", true)
	pass

func skip_play() -> void:
	# randomizes anyway
	play_forward_randomly()
	pass

func step_back() -> void:
	set_view_unplayed()
	pass
	
