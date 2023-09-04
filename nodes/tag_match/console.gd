# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Tag-Match Node Type Console
extends PanelContainer

signal play_forward
signal status_code
# signal clear_up
# signal reset_variables
# signal reset_characters_tags

onready var Main = get_tree().get_root().get_child(0)

var Utils = Helpers.Utils

const AUTO_PLAY_SLOT = -1

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary
var _CHARACTERS_CURRENT:Dictionary
var _CHARACTER_CACHED:Dictionary

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

onready var CharacterProfileName  = get_node("./TagMatchPlay/Header/CharacterProfile/Name")
onready var CharacterProfileColor = get_node("./TagMatchPlay/Header/CharacterProfile/Color")
onready var TagKey = get_node("./TagMatchPlay/TagKey")
onready var Matchables = get_node("./TagMatchPlay/Rows/Matchables")
onready var PatternsSelector = get_node("./TagMatchPlay/Rows/Matchables/Patterns")
onready var ManualEolButton = get_node("./TagMatchPlay/Rows/Matchables/Actions/Eol")
onready var ManualMatchButton = get_node("./TagMatchPlay/Rows/Matchables/Actions/Match")
onready var MatchedPattern = get_node("./TagMatchPlay/Rows/MatchedPattern")

const ANONYMOUS_CHARACTER = TagMatchSharedClass.INVALID_CHARACTER
const DEFAULT_NODE_DATA = TagMatchSharedClass.DEFAULT_NODE_DATA

const INVALID_TAG_KEY_ERROR = "Invalid Tag Key"
const MATCHING_FORMAT_STRING = "`{value}` matched `{pattern}`"
const NO_MATCH = "No Match (EOL)"

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
	ManualEolButton.connect("pressed", self, "play_eol", [], CONNECT_DEFERRED)
	ManualMatchButton.connect("pressed", self, "play_selected_pattern", [], CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

func update_character(profile:Dictionary) -> void:
	if profile.has("name") && (profile.name is String):
		CharacterProfileName.set("text", profile.name)
	if profile.has("color") && (profile.color is String):
		CharacterProfileColor.set("color", Utils.rgba_hex_to_color(profile.color))
	pass

func set_character_anonymous() -> void:
	update_character( ANONYMOUS_CHARACTER )
	pass

func update_character_profile() -> void:
	if _NODE_RESOURCE.has("data") && _NODE_RESOURCE.data.has("character") && (_NODE_RESOURCE.data.character is int) && (_NODE_RESOURCE.data.character >= 0):
		var the_character_profile = Main.Mind.lookup_resource(_NODE_RESOURCE.data.character, "characters")
		if the_character_profile != null :
			update_character( the_character_profile )
			_CHARACTER_CACHED = the_character_profile
	else:
		set_character_anonymous()
		_CHARACTER_CACHED = {}
	pass
	
func clean_all_patterns() -> void:
	PatternsSelector.clear()
	pass

func update_tag_key() -> void:
	TagKey.set_text(
		_NODE_RESOURCE.data.tag_key
		if (
			_NODE_RESOURCE.has("data") && _NODE_RESOURCE.data.has("tag_key") &&
			_NODE_RESOURCE.data.tag_key is String && _NODE_RESOURCE.data.tag_key.length() > 0
		)
		else INVALID_TAG_KEY_ERROR
	)
	pass

func update_patterns() -> void:
	if _NODE_RESOURCE.has("data") && _NODE_RESOURCE.data.has("patterns") && (_NODE_RESOURCE.data.patterns is Array):
		for pattern_idx in range(0, _NODE_RESOURCE.data.patterns.size()):
			var pattern_text = _NODE_RESOURCE.data.patterns[pattern_idx]
			PatternsSelector.add_item(pattern_text)
	pass

func setup_view() -> void:
	clean_all_patterns()
	update_character_profile()
	update_tag_key()
	update_patterns()
	pass

func play_selected_pattern() -> void:
	play_forward_from(PatternsSelector.get_selected())
	pass

func play_eol() -> void:
	play_forward_from(-1)
	pass

func play_matching_or_eol() -> void:
	var matched = -1
	if (
		_NODE_RESOURCE.has("data") &&
		_NODE_RESOURCE.data.has("character") && (_NODE_RESOURCE.data.character is int) && (_NODE_RESOURCE.data.character >= 0) &&
		_NODE_RESOURCE.data.has("tag_key") && (_NODE_RESOURCE.data.tag_key is String) &&
		_NODE_RESOURCE.data.has("patterns") && (_NODE_RESOURCE.data.patterns is Array)
	):
		if _CHARACTERS_CURRENT.has(_NODE_RESOURCE.data.character):
			if _CHARACTERS_CURRENT[_NODE_RESOURCE.data.character].has("tags"):
				var use_regex = (
					DEFAULT_NODE_DATA.regex
					if _NODE_RESOURCE.data.has("regex") == false || false == (_NODE_RESOURCE.data.regex is bool)
					else _NODE_RESOURCE.data.regex
				)
				matched = TagMatchSharedClass.find_matching(
					_CHARACTERS_CURRENT[_NODE_RESOURCE.data.character].tags,
					_NODE_RESOURCE.data.tag_key,
					_NODE_RESOURCE.data.patterns,
					use_regex
				)
	# ...
	PatternsSelector.select(matched)
	play_forward_from(matched)
	pass
		
func setup_play(
	node_id:int, node_resource:Dictionary, node_map:Dictionary, _playing_in_slot:int = -1,
	variables_current:Dictionary={}, characters_current:Dictionary={}
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
		if _NODE_MAP.has("skip") && _NODE_MAP.skip == true:
			skip_play()
		elif AUTO_PLAY_SLOT >= 0:
			play_forward_from(AUTO_PLAY_SLOT)
		else:
			play_matching_or_eol()
	else:
		set_view_unplayed()
	pass

func play_forward_from(slot_idx:int = AUTO_PLAY_SLOT) -> void:
	if slot_idx >= 0 && _NODE_SLOTS_MAP.has(slot_idx):
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
	MatchedPattern.set_text("")
	MatchedPattern.set_visible(false)
	Matchables.set_visible(true)
	pass

func set_view_played(slot_idx:int = AUTO_PLAY_SLOT) -> void:
	MatchedPattern.set_text(NO_MATCH)
	if slot_idx >= 0:
		if (
			_NODE_RESOURCE.has("data") &&
			_NODE_RESOURCE.data.has("tag_key") &&
			_NODE_RESOURCE.data.has("patterns") && (_NODE_RESOURCE.data.patterns is Array)
		):
			if _NODE_RESOURCE.data.patterns.size() > slot_idx:
				MatchedPattern.set_text(
					MATCHING_FORMAT_STRING.format({
						"pattern": _NODE_RESOURCE.data.patterns[slot_idx],
						"value": (
							_CHARACTERS_CURRENT[_NODE_RESOURCE.data.character].tags[_NODE_RESOURCE.data.tag_key]
							if (
								_CHARACTERS_CURRENT.has(_NODE_RESOURCE.data.character) &&
								_CHARACTERS_CURRENT[_NODE_RESOURCE.data.character].has("tags") &&
								_CHARACTERS_CURRENT[_NODE_RESOURCE.data.character].tags.has(_NODE_RESOURCE.data.tag_key)
							)
							else "N/A"
						)
					})
				)
	MatchedPattern.set_visible(true)
	Matchables.set_visible(false)
	pass

func skip_play() -> void:
	# plays the first *connected* slot
	# or just the first[0] one if there is no connection which means end edge
	var first_connected_slot:int = 0
	if _NODE_SLOTS_MAP.size() >= 1:
		var all_connected_slots = _NODE_SLOTS_MAP.keys()
		all_connected_slots.sort() 
		first_connected_slot = all_connected_slots[0]
	play_forward_from(first_connected_slot)
	pass

func step_back() -> void:
	set_view_unplayed()
	pass
