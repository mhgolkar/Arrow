# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Monolog Console Element
extends Control

signal play_forward
signal status_code
signal clear_up
# signal reset_variables
# signal reset_characters_tags

@onready var Main = get_tree().get_root().get_child(0)

const DEFAULT_NODE_DATA = MonologSharedClass.DEFAULT_NODE_DATA
const ANONYMOUS_CHARACTER = MonologSharedClass.ANONYMOUS_CHARACTER

# forces auto-play regardless of the `auto` property
const AUTO_PLAY_SLOT = -1

# played on `Continue` button being pressed or skipping
const ONLY_SLOT_OUT = 0

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary
var _CHARACTERS_CURRENT: Dictionary
var _CURRENT_VARS_EXPO:Dictionary
var _CURRENT_CHAR_TAGS_EXPO:Dictionary

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

@onready var CharacterName = $Play/Head/Name
@onready var CharacterColor = $Play/Body/Color
@onready var Monolog = $Play/Body/Monolog
@onready var Continue = $Play/Continue

const MONOLOG_UNSET_MESSAGE = "MONOLOG_CONSOLE_UNSET_MSG" # Translated ~ "No Monolog."
const MONOLOG_UNSET_SELF_MODULATION_COLOR = Color(1, 1, 1, 0.30)

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
	# clicking `Continue` button will play forward from the first and only slot (0)
	Continue.pressed.connect(self.play_forward_from.bind(ONLY_SLOT_OUT), CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

func string_data_or_default(parameter:String) -> String:
	var text = DEFAULT_NODE_DATA[parameter]
	if _NODE_RESOURCE.has("data") && _NODE_RESOURCE.data.has(parameter) && _NODE_RESOURCE.data[parameter] is String:
		text = _NODE_RESOURCE.data[parameter]
	return text

func bool_data_or_default(parameter: String) -> bool:
	var intended = DEFAULT_NODE_DATA[parameter]
	if _NODE_RESOURCE.has("data") && _NODE_RESOURCE.data.has(parameter) && _NODE_RESOURCE.data[parameter] is bool:
		intended = _NODE_RESOURCE.data[parameter]
	return intended

func setup_view() -> void:
	# Character Profile
	var character_id = _NODE_RESOURCE.data.character if _NODE_RESOURCE.data.has("character") && _NODE_RESOURCE.data.character is int else -1
	var profile = _CHARACTERS_CURRENT[character_id] if _CHARACTERS_CURRENT.has(character_id) else ANONYMOUS_CHARACTER
	CharacterName.set(
		"text",
		profile.name if profile.has("name") && (profile.name is String) else ANONYMOUS_CHARACTER.name
	)
	CharacterColor.set(
		"color",
		Helpers.Utils.rgba_hex_to_color(
			profile.color if profile.has("color") && (profile.color is String) else ANONYMOUS_CHARACTER.color
		)
	)
	# Monolog
	var monolog = string_data_or_default("monolog")
	if monolog.length() > 0:
		var reformatted_monolog = monolog.format(_CURRENT_CHAR_TAGS_EXPO).format(_CURRENT_VARS_EXPO)
		Monolog.set_deferred("text", reformatted_monolog)
	else:
		Monolog.set_deferred("text", MONOLOG_UNSET_MESSAGE)
		Monolog.set_deferred("self_modulate", MONOLOG_UNSET_SELF_MODULATION_COLOR)
	# Ask for console clearance if the behavior is intended (unless the node is skipped):
	if bool_data_or_default("clear") && (_NODE_MAP.has("skip") == false || _NODE_MAP.skip == false):
		self.clear_up.emit()
	pass

func create_current_variables_exposure(variables:Dictionary) -> void:
	_CURRENT_VARS_EXPO = {}
	for var_id in variables:
		var the_variable = variables[var_id]
		_CURRENT_VARS_EXPO[the_variable.name] = the_variable.value
	pass

func create_current_characters_exposure(characters:Dictionary) -> void:
	_CURRENT_CHAR_TAGS_EXPO = {}
	for char_id in characters:
		var the_character = characters[char_id]
		if the_character.has("tags") && the_character.tags is Dictionary:
			for key in the_character.tags:
				_CURRENT_CHAR_TAGS_EXPO[the_character.name + "." + key] = the_character.tags[key]
	pass

func setup_play(
	node_id:int, node_resource:Dictionary, node_map:Dictionary, _playing_in_slot:int = -1,
	variables_current:Dictionary={}, characters_current:Dictionary={}
) -> void:
	_NODE_ID = node_id
	_NODE_RESOURCE = node_resource
	_NODE_MAP = node_map
	_CHARACTERS_CURRENT = characters_current
	create_current_variables_exposure(variables_current)
	create_current_characters_exposure(characters_current)
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
		elif bool_data_or_default("auto"):
			play_forward_from(ONLY_SLOT_OUT)
	else:
		set_view_unplayed()
	pass

func play_forward_from(slot_idx:int = AUTO_PLAY_SLOT) -> void:
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
	Continue.set("visible", true)
	pass

func set_view_played(_slot_idx:int = AUTO_PLAY_SLOT) -> void:
	Continue.set("visible", false)
	pass

func skip_play() -> void:
	play_forward_from( ONLY_SLOT_OUT )
	pass

func step_back() -> void:
	set_view_unplayed()
	pass
