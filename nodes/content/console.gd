# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Content Node Type Console
extends PanelContainer

signal play_forward
signal status_code
signal clear_up
# warning-ignore:unused_signal
signal reset_variable

onready var Main = get_tree().get_root().get_child(0)

const AUTO_PLAY_SLOT = -1

# played on `Continue` button being pressed or skipping
const ONLY_SLOT_OUT = 0

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary
var _CURRENT_VARIABLES_VALUE_BY_NAME:Dictionary

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

onready var Title = get_node("./ContentPlay/Title")
onready var Content = get_node("./ContentPlay/Content")
onready var Brief = get_node("./ContentPlay/Brief")
onready var Continue = get_node("./ContentPlay/Continue")

const TITLE_UNSET_MESSAGE = "Untitled"
const TITLE_UNSET_SELF_MODULATION_COLOR  = Color(1, 1, 1, 0.30)
const CONTENT_UNSET_MESSAGE = "No Content."
const BRIEF_UNSET_MESSAGE = "No Brief."

func _ready() -> void:
	register_connections()
	_NODE_IS_READY = true
	if _PLAY_IS_SET_UP:
		setup_view()
	if _DEFERRED_VIEW_PLAY_SLOT >= 0:
		set_view_played(_DEFERRED_VIEW_PLAY_SLOT)
	pass

func register_connections() -> void:
	# clicking `Continue` button will play forward from the first and only slot (0)
	Continue.connect("pressed", self, "play_forward_from", [ONLY_SLOT_OUT], CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

func resource_has_valid_string_data(field:String) -> bool:
	return (
		_NODE_RESOURCE.has("data") &&
		_NODE_RESOURCE.data.has(field) &&
		_NODE_RESOURCE.data[field] is String &&
		_NODE_RESOURCE.data[field].length() > 0 
	)

func content_wants_clearance() -> bool:
	return (
		_NODE_RESOURCE.has("data") &&
		_NODE_RESOURCE.data.has("clear") &&
		_NODE_RESOURCE.data.clear is bool &&
		_NODE_RESOURCE.data.clear == true
	)

func setup_view() -> void:
	# Title
	if resource_has_valid_string_data("title"):
		var reformatted_title = _NODE_RESOURCE.data.title.format(_CURRENT_VARIABLES_VALUE_BY_NAME)
		Title.set_deferred("text", reformatted_title)
	else:
		Title.set_deferred("text", TITLE_UNSET_MESSAGE)
		Title.set_deferred("self_modulate", TITLE_UNSET_SELF_MODULATION_COLOR)
	# Content
	if resource_has_valid_string_data("content"):
		# print formated content:
		# firstly, by replacing `{variable_name}` tags with respective [current] value
		var reformatted_content = _NODE_RESOURCE.data.content.format(_CURRENT_VARIABLES_VALUE_BY_NAME)
		# then because this node type supports BBCode ...
		Content.clear() # clean up and try to set bbcode
		if Content.append_bbcode(reformatted_content) != OK:
			# or normal text if there was problem parsing it
			Content.set_text(reformatted_content)
	else:
		Content.set_deferred("text", CONTENT_UNSET_MESSAGE)
	# Brief
	if resource_has_valid_string_data("brief"):
		# ditto ...
		var reformatted_brief = _NODE_RESOURCE.data.brief.format(_CURRENT_VARIABLES_VALUE_BY_NAME)
		Brief.clear()
		if Brief.append_bbcode(reformatted_brief) != OK:
			Brief.set_text(reformatted_brief)
	else:
		Brief.set_deferred("text", BRIEF_UNSET_MESSAGE)
	# ask for console clearance ...
	if content_wants_clearance():
		emit_signal("clear_up")
	pass

func remap_current_variables_value_by_name(variables:Dictionary) -> void:
	for var_id in variables:
		var the_variable = variables[var_id]
		_CURRENT_VARIABLES_VALUE_BY_NAME[the_variable.name] = the_variable.value
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
	Continue.set("visible", true)
	pass

func set_view_played(slot_idx:int = AUTO_PLAY_SLOT) -> void:
	Continue.set("visible", false)
	pass

func skip_play() -> void:
	play_forward_from( ONLY_SLOT_OUT )
	pass

func step_back() -> void:
	set_view_unplayed()
	pass
