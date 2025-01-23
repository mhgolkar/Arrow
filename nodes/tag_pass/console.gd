# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Tag-Pass Console Element
extends Control

signal play_forward
signal status_code
# signal clear_up
# signal reset_variables
# signal reset_characters_tags

@onready var Main = get_tree().get_root().get_child(0)

const FALSE_SLOT = 0
const TRUE_SLOT  = 1
# Note:
# `False` is the 2rd and `True` is 4th slot (seemingly index `2` and `4`) but ...
# its real index is  `0` and `1` previous slots right-disabled and not counted

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary
var _CHARACTERS_CURRENT:Dictionary
var _THE_TARGET_CHARACTER_ID:int = -1

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

const TAG_KEY_ONLY_FORMAT_STRING = "{key}: *"
const TAG_KEY_VALUE_FORMAT_STRING = "{key}: `{value}`"

const ANONYMOUS_CHARACTER = TagPassSharedClass.ANONYMOUS_CHARACTER
const METHODS = TagPassSharedClass.METHODS
const METHODS_HINTS = TagPassSharedClass.METHODS_HINTS
const METHODS_ENUM = TagPassSharedClass.METHODS_ENUM

const METHOD_INVALID = ""
const METHOD_INVALID_HINT = ""

@onready var Method = $Play/Body/Checkables/Method
@onready var CharacterProfileColor = $Play/Body/Color
@onready var CharacterProfileName = $Play/Head/Name
@onready var Invalid = $Play/Body/Checkables/Invalid
@onready var TagTemplate = $Play/Body/Checkables/Margin/TagTemplate
@onready var Tags = $Play/Body/Checkables/Margin/Tags
@onready var TagNoneMessage = $Play/Body/Checkables/Margin/NoTagsToCheck
@onready var TheFalse = $Play/Body/Checkables/Actions/False
@onready var TheTrue = $Play/Body/Checkables/Actions/True

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
	TheTrue.pressed.connect(self.play_forward_from.bind(TRUE_SLOT), CONNECT_DEFERRED)
	TheFalse.pressed.connect(self.play_forward_from.bind(FALSE_SLOT), CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

func update_character(profile:Dictionary) -> void:
	CharacterProfileName.set(
		"text",
		profile.name if profile.has("name") && (profile.name is String) else ANONYMOUS_CHARACTER.name
	)
	CharacterProfileColor.set(
		"color",
		Helpers.Utils.rgba_hex_to_color(
			profile.color if profile.has("color") && (profile.color is String) else ANONYMOUS_CHARACTER.color
		)
	)
	pass

func refresh_tag_box(entities: Array) -> void:
	var checkables = 0
	for node in Tags.get_children():
		if node is Label:
			node.free()
	for entity in entities:
		if TagPassSharedClass.tag_is_checkable(entity):
			checkables += 1
			var value_is_checked = (entity.size() >= 1 && entity[1] is String)
			var checkable_tag = TagTemplate.duplicate()
			var _FORMAT_STRING = TAG_KEY_VALUE_FORMAT_STRING if value_is_checked else TAG_KEY_ONLY_FORMAT_STRING
			checkable_tag.set_text(
				_FORMAT_STRING.format({
					"key": entity[0], "value": entity[1] if value_is_checked else "N/A"
				})
			)
			checkable_tag.set_visible(true)
			Tags.add_child(checkable_tag)
	TagNoneMessage.set_visible(checkables == 0)
	pass

# update view parts, normally called first after instancing via setup_play
# also caches some character data
func setup_view() -> void:
	var is_valid = _NODE_RESOURCE.has("data") && TagPassSharedClass.data_is_valid(_NODE_RESOURCE.data)
	var method_text = METHOD_INVALID
	var method_hint = METHOD_INVALID_HINT
	if is_valid:
		var method_id = _NODE_RESOURCE.data.pass[0]
		method_text = METHODS[method_id]
		method_hint = METHODS_HINTS[method_id]
		if _CHARACTERS_CURRENT.has(_NODE_RESOURCE.data.character):
			_THE_TARGET_CHARACTER_ID = _NODE_RESOURCE.data.character
			update_character( _CHARACTERS_CURRENT[_THE_TARGET_CHARACTER_ID] )
		else:
			is_valid = false
	Invalid.set_deferred("visible", (! is_valid))
	Tags.set_deferred("visible", is_valid)
	TheTrue.set_deferred("tooltip_text", method_hint)
	Method.set_deferred("text", method_text)
	Method.set_deferred("visible", is_valid)
	CharacterProfileColor.set_deferred("visible", is_valid)
	CharacterProfileName.set_deferred("visible", is_valid)
	refresh_tag_box(_NODE_RESOURCE.data.pass[1] if is_valid else [])
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
			process_tag_pass_forward()
	else:
		set_view_unplayed()
	pass

func process_tag_pass_forward() -> void:
	var shall_pass = false
	if _THE_TARGET_CHARACTER_ID >= 0: # means has valid data (tag pairs are not checked)
		var the_character = _CHARACTERS_CURRENT[_THE_TARGET_CHARACTER_ID]
		var current_tags = the_character.tags if the_character.has("tags") && the_character.tags is Dictionary else {}
		var method = _NODE_RESOURCE.data.pass[0]
		for entity in _NODE_RESOURCE.data.pass[1]:
			if TagPassSharedClass.tag_is_checkable(entity):
				shall_pass = (
					current_tags.has( entity[0] ) &&
					( entity.size() == 1 || entity[1] == null || entity[1] == current_tags[entity[0]] )
				)
				if method == METHODS_ENUM.ANY && shall_pass == true:
					break
				if method == METHODS_ENUM.ALL && shall_pass == false:
					break
	play_forward_from(TRUE_SLOT if shall_pass else FALSE_SLOT)
	pass

func play_forward_from(slot_idx:int) -> void:
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
	TheFalse.set_deferred("visible", true)
	TheFalse.set_deferred("disabled", false)
	TheTrue.set_deferred("visible", true)
	TheTrue.set_deferred("disabled", false)
	pass

func set_view_played(slot_idx:int) -> void:
	TheFalse.set_deferred("visible", (slot_idx == FALSE_SLOT))
	TheFalse.set_deferred("disabled", true)
	TheTrue.set_deferred("visible", (slot_idx == TRUE_SLOT))
	TheTrue.set_deferred("disabled", true)
	pass

func skip_play() -> void:
	# skipped? the convention is to ...
	# react by playing the *False Slot First*
	if _NODE_SLOTS_MAP.has(FALSE_SLOT): # if false slot is connected
		play_forward_from(FALSE_SLOT)
	else: # otherwise playing the *Only Remained [Possibly Connected] True Slot*
		play_forward_from(TRUE_SLOT) # which ...
		# ... will naturally end the plot line if the true slot is not connected
	pass

func step_back() -> void:
	set_view_unplayed()
	pass
