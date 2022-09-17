# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Interaction Node Type Console
extends PanelContainer

signal play_forward
signal status_code
# signal clear_up
# signal reset_variable
# signal overset_characters_tags

onready var Main = get_tree().get_root().get_child(0)

const AUTO_PLAY_SLOT = -1

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary
var _CURRENT_VARIABLES_VALUE_BY_NAME:Dictionary

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

onready var ActionsHolder = get_node("./InteractionPlay/Actions")
onready var PlayedAction = get_node("./InteractionPlay/ActionPlayed")
onready var PlayedActionLabel = get_node("./InteractionPlay/ActionPlayed/Label")

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

func clean_all_actions() -> void:
	for node in ActionsHolder.get_children():
		if node is Button:
			node.free()
	pass

func listen_to_action(action:Button, action_idx:int) -> void:
	action.connect("pressed", self, "play_forward_from", [action_idx], CONNECT_DEFERRED)
	pass

func setup_view() -> void:
	clean_all_actions()
	if _NODE_RESOURCE.has("data") && _NODE_RESOURCE.data.has("actions") && (_NODE_RESOURCE.data.actions is Array):
		for action_idx in range(0, _NODE_RESOURCE.data.actions.size()):
			var the_action_button = Button.new()
			var action_text = _NODE_RESOURCE.data.actions[action_idx]
			var reformatted_action_text = action_text.format(_CURRENT_VARIABLES_VALUE_BY_NAME)
			the_action_button.set_text(reformatted_action_text)
			listen_to_action(the_action_button, action_idx)
			ActionsHolder.add_child(the_action_button)
	pass

func setup_play(
	node_id:int, node_resource:Dictionary, node_map:Dictionary, _playing_in_slot:int = -1,
	variables_current:Dictionary={}, _characters_current:Dictionary={}
) -> void:
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
	PlayedActionLabel.set_text("")
	PlayedAction.set_visible(false)
	ActionsHolder.set_visible(true)
	pass

func set_view_played(slot_idx:int = AUTO_PLAY_SLOT) -> void:
	if _NODE_RESOURCE.has("data") && _NODE_RESOURCE.data.has("actions") && (_NODE_RESOURCE.data.actions is Array):
		if _NODE_RESOURCE.data.actions.size() > slot_idx:
			var action_text = _NODE_RESOURCE.data.actions[slot_idx]
			var reformatted_action_text = action_text.format(_CURRENT_VARIABLES_VALUE_BY_NAME)
			PlayedActionLabel.set_text(reformatted_action_text)
			PlayedAction.set_visible(true)
			ActionsHolder.set_visible(false)
	pass

func skip_play() -> void:
	# plays the first *connected* slot (interaction)
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
