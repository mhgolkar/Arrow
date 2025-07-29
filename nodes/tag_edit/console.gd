# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Tag-Edit Console Element
extends Control

signal play_forward
signal status_code
# signal clear_up
# signal reset_variables
signal reset_characters_tags

@onready var Main = get_tree().get_root().get_child(0)

# will be played forward after automatic process (update) or by a user choice
const ONLY_PLAY_SLOT = 0

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary
var _CHARACTERS_CURRENT:Dictionary
var _THE_TARGET_CHARACTER_ID:int = -1
var _THE_TARGET_CHARACTER_REVERT_INSTRUCTION = {}

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

const METHOD_INVALID = "TAG_EDIT_CONSOLE_METHOD_INVALID" # Translated ~ "N/A"
const METHOD_INVALID_HINT = "TAG_EDIT_CONSOLE_METHOD_INVALID_HINT" # Translated ~ "Not Applicable: The node's resource data is corrupt"
const TAG_EDIT_INVALID = "TAG_EDIT_CONSOLE_INVALID_DATA" # Translated ~ "Invalid!"
const TAG_KEY_VALUE_FORMAT_STRING = "TAG_EDIT_CONSOLE_TAG_KEY_VALUE_FORMAT_STR" # Translated ~ "{key}: `{value}`"

const ANONYMOUS_CHARACTER = TagEditSharedClass.ANONYMOUS_CHARACTER
const METHODS = TagEditSharedClass.METHODS
const METHODS_HINTS = TagEditSharedClass.METHODS_HINTS
const METHODS_ENUM = TagEditSharedClass.METHODS_ENUM

@onready var Tag = $Play/Body/Tag
@onready var CharacterColor = $Play/Body/Color
@onready var CharacterName = $Play/Head/Name
@onready var Skip = $Play/Actions/Skip
@onready var Apply = $Play/Actions/Apply

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
	Apply.pressed.connect(self.process_tag_edit_forward, CONNECT_DEFERRED)
	Skip.pressed.connect(self.skip_play, CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

func update_character(profile:Dictionary) -> void:
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
	pass
	
# update view parts, normally called first after instancing via setup_play
# also caches some character data
func setup_view() -> void:
	var is_valid = _NODE_RESOURCE.has("data") && TagEditSharedClass.data_is_valid(_NODE_RESOURCE.data)
	var tag_text = TAG_EDIT_INVALID
	var method_text = METHOD_INVALID
	var method_hint = METHOD_INVALID_HINT
	if is_valid:
		var method_id = _NODE_RESOURCE.data.edit[0]
		method_text = METHODS[method_id]
		method_hint = METHODS_HINTS[method_id]
		if _CHARACTERS_CURRENT.has(_NODE_RESOURCE.data.character):
			# (shall be set only if the data is valid; other methods are depended on this fact)
			_THE_TARGET_CHARACTER_ID = _NODE_RESOURCE.data.character
			update_character( _CHARACTERS_CURRENT[_THE_TARGET_CHARACTER_ID] )
			tag_text = tr(TAG_KEY_VALUE_FORMAT_STRING).format({
				"key": _NODE_RESOURCE.data.edit[1], "value": _NODE_RESOURCE.data.edit[2]
			})
		else:
			is_valid = false
	Apply.set_deferred("text", method_text)
	Apply.set_deferred("tooltip_text", method_hint)
	Tag.set_deferred("text", tag_text)
	CharacterColor.set_deferred("visible", is_valid)
	CharacterName.set_deferred("visible", is_valid)
	set_view_unplayed()
	pass

func setup_play(
	node_id:int, node_resource:Dictionary, node_map:Dictionary, _playing_in_slot:int = -1,
	_variables_current:Dictionary={}, characters_current:Dictionary={}
) -> void:
	_NODE_ID = node_id
	_NODE_RESOURCE = node_resource
	_NODE_MAP = node_map
	_CHARACTERS_CURRENT = characters_current
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
		# otherwise...
		else:
			# evaluate the condition and auto-play the case:
			process_tag_edit_forward()
	else:
		set_view_unplayed()
	pass

func process_tag_edit_forward() -> void:
	if _THE_TARGET_CHARACTER_ID >= 0: # means has full valid data
		_THE_TARGET_CHARACTER_REVERT_INSTRUCTION = {}
		var update_instruction = {}
		# ...
		var the_character = _CHARACTERS_CURRENT[_THE_TARGET_CHARACTER_ID]
		var current_tags = the_character.tags if the_character.has("tags") && the_character.tags is Dictionary else {}
		var edit_key = _NODE_RESOURCE.data.edit[1]
		var edit_value = _NODE_RESOURCE.data.edit[2]
		print_debug("Tag-edit console processing: ", the_character, current_tags)
		match _NODE_RESOURCE.data.edit[0]:
			METHODS_ENUM.INSET: # Adds a key:value tag, only if the key does not exist
				if current_tags.has(edit_key) == false:
					update_instruction[edit_key] = edit_value
					_THE_TARGET_CHARACTER_REVERT_INSTRUCTION[edit_key] = null
			METHODS_ENUM.RESET: # Resets value of a tag, only if the key exists
				if current_tags.has(edit_key) == true:
					update_instruction[edit_key] = edit_value
					_THE_TARGET_CHARACTER_REVERT_INSTRUCTION[edit_key] = current_tags[edit_key]
			METHODS_ENUM.OVERSET: # Overwrites or adds a key:value tag, whether the key exists or not
				update_instruction[edit_key] = edit_value
				_THE_TARGET_CHARACTER_REVERT_INSTRUCTION[edit_key] = (
					current_tags[edit_key] if current_tags.has(edit_key) else null
				)
			METHODS_ENUM.OUTSET: # Removes a tag if both key & value match
				if current_tags.has(edit_key) == true:
					if current_tags[edit_key] == edit_value:
						update_instruction[edit_key] = null
						_THE_TARGET_CHARACTER_REVERT_INSTRUCTION[edit_key] = current_tags[edit_key]
			METHODS_ENUM.UNSET: # Removes a tag if just the key matches
				if current_tags.has(edit_key) == true:
					update_instruction[edit_key] = null
					_THE_TARGET_CHARACTER_REVERT_INSTRUCTION[edit_key] = current_tags[edit_key]
		# ...
		self.reset_characters_tags.emit({
			_THE_TARGET_CHARACTER_ID: update_instruction
		})
		play_forward_from(ONLY_PLAY_SLOT)
	else:
		skip_play()
	pass

func play_forward_from(slot_idx:int = ONLY_PLAY_SLOT) -> void:
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
	# in case unplayed (i.e. step-back after automatic process)
	# ... let user choose
	var is_valid = _NODE_RESOURCE.has("data") && TagEditSharedClass.data_is_valid(_NODE_RESOURCE.data)
	Apply.set_deferred("disabled", (! is_valid))
	Skip.set_deferred("visible", true)
	pass

func set_view_played(_slot_idx:int = ONLY_PLAY_SLOT) -> void:
	Apply.set_deferred("disabled", true)
	Skip.set_deferred("visible", false)
	pass

func skip_play() -> void:
	play_forward_from(ONLY_PLAY_SLOT)
	pass

func step_back() -> void:
	# Stepping back, we should undo the changes we've made to the variable as well,
	# so the user can inspect the previous value, before manually playing or skipping the node.
	if _THE_TARGET_CHARACTER_REVERT_INSTRUCTION.size() > 0:
		self.reset_characters_tags.emit({
			_THE_TARGET_CHARACTER_ID: _THE_TARGET_CHARACTER_REVERT_INSTRUCTION
		})
	# ...
	set_view_unplayed()
	pass
