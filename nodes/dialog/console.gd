# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Dialog Node Type Console
extends PanelContainer

signal play_forward
signal status_code
# warning-ignore:unused_signal
signal clear_up
# warning-ignore:unused_signal
signal reset_variable

onready var Main = get_tree().get_root().get_child(0)

var Utils = Helpers.Utils

const AUTO_PLAY_SLOT = -1

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary
var _CURRENT_VARIABLES_VALUE_BY_NAME:Dictionary
var _CHARACTER_CACHED:Dictionary

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

onready var CharacterProfileName  = get_node("./DialogPlay/CharacterProfile/Name")
onready var CharacterProfileColor = get_node("./DialogPlay/CharacterProfile/Color")
onready var PlayBox = get_node("./DialogPlay/Box")
onready var PlayableLines = get_node("./DialogPlay/Box/Rows/PlayableLines")
onready var PlayedLine = get_node("./DialogPlay/Box/Rows/Played")

const ANONYMOUS_CHARACTER = DialogSharedClass.ANONYMOUS_CHARACTER
const DEFAULT_NODE_DATA = DialogSharedClass.DEFAULT_NODE_DATA

const LINES_SHARED_PROPERTIES = {
	"clip_text": true,
	"align": Button.ALIGN_LEFT
}

func _ready() -> void:
	# register_connections()
	_NODE_IS_READY = true
	if _PLAY_IS_SET_UP:
		setup_view()
		proceed_auto_play()
	if _DEFERRED_VIEW_PLAY_SLOT >= 0:
		set_view_played(_DEFERRED_VIEW_PLAY_SLOT)
	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

func remap_current_variables_value_by_name(variables:Dictionary) -> void:
	for var_id in variables:
		var the_variable = variables[var_id]
		_CURRENT_VARIABLES_VALUE_BY_NAME[the_variable.name] = the_variable.value
	pass

func update_character(profile:Dictionary) -> void:
	if profile.has("name") && (profile.name is String):
		CharacterProfileName.set("text", profile.name)
	if profile.has("color") && (profile.color is String):
		CharacterProfileColor.set("color", Utils.rgba_hex_to_color(profile.color))
		# And colorize the box's boarder
		var colorized = PlayBox.get_stylebox("panel").duplicate()
		colorized.border_color = Utils.rgba_hex_to_color(profile.color)
		PlayBox.add_stylebox_override("panel", colorized)
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
	
func clean_all_lines() -> void:
	for node in PlayableLines.get_children():
		if node is Button:
			node.free()
	pass

func listen_to_line(line:Button, line_idx:int) -> void:
	line.connect("pressed", self, "play_forward_from", [line_idx], CONNECT_DEFERRED)
	pass

func setup_view() -> void:
	clean_all_lines()
	update_character_profile()
	if _NODE_RESOURCE.has("data") && _NODE_RESOURCE.data.has("lines") && (_NODE_RESOURCE.data.lines is Array):
		for line_idx in range(0, _NODE_RESOURCE.data.lines.size()):
			var the_line_button = Button.new()
			var line_text = _NODE_RESOURCE.data.lines[line_idx]
			var reformatted_line_text = line_text.format(_CURRENT_VARIABLES_VALUE_BY_NAME)
			the_line_button.set_text(reformatted_line_text)
			for property in LINES_SHARED_PROPERTIES:
				the_line_button.set(property, LINES_SHARED_PROPERTIES[property])
			listen_to_line(the_line_button, line_idx)
			PlayableLines.add_child(the_line_button)
	pass

# automatically chooses a random reply (as a none-playable [character's] dialog)
func random_play_none_playable_dialogs() -> void:
	var non_playable = (! DEFAULT_NODE_DATA.playable)
	if _NODE_RESOURCE.has("data") && _NODE_RESOURCE.data.has("playable") && (_NODE_RESOURCE.data.playable is bool):
		non_playable = (! _NODE_RESOURCE.data.playable)
	# ...
	if non_playable:
		if _NODE_RESOURCE.data.has("lines") && (_NODE_RESOURCE.data.lines is Array) && (_NODE_RESOURCE.data.lines.size() > 0):
			var random_slot_idx = randi()  % _NODE_RESOURCE.data.lines.size()
			play_forward_from(random_slot_idx)
	pass
		
func setup_play(node_id:int, node_resource:Dictionary, node_map:Dictionary, _playing_in_slot:int = -1, variables_current:Dictionary={}) -> void:
	_NODE_ID = node_id
	_NODE_RESOURCE = node_resource
	_NODE_MAP = node_map
	remap_current_variables_value_by_name(variables_current)
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
		else: # or automatically play dialogs which are not playable (randomized reply)
			random_play_none_playable_dialogs()
			# Note: it does nothing if this is a playable dialog and ...
	# ... the node waits for user action/play (checkout `listen_to_line` func)
	else:
		set_view_unplayed()
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
	PlayedLine.set_text("")
	PlayedLine.set_visible(false)
	PlayableLines.set_visible(true)
	pass

func set_view_played(slot_idx:int = AUTO_PLAY_SLOT) -> void:
	if _NODE_RESOURCE.has("data") && _NODE_RESOURCE.data.has("lines") && (_NODE_RESOURCE.data.lines is Array):
		if _NODE_RESOURCE.data.lines.size() > slot_idx:
			var line_text = _NODE_RESOURCE.data.lines[slot_idx]
			var reformatted_line_text = line_text.format(_CURRENT_VARIABLES_VALUE_BY_NAME)
			PlayedLine.set_text(reformatted_line_text)
			PlayedLine.set_visible(true)
			PlayableLines.set_visible(false)
	pass

func skip_play() -> void:
	# plays the first *connected* slot (dialog)
	# or just the first[0] slot if there is no connected one which means end edge
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
	
