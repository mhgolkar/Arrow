# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# User_Input Node Type Console
extends PanelContainer

signal play_forward
signal status_code
# warning-ignore:unused_signal
signal clear_up
signal reset_variable

onready var Main = get_tree().get_root().get_child(0)

const ONLY_PLAY_SLOT = 0

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary
var _VARIABLES_CURRENT:Dictionary
var _THE_VARIABLE_ID:int = -1
var _THE_VARIABLE = null
var _CURRENT_VARIABLES_VALUE_BY_NAME:Dictionary

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

const PROMPT_UNSET_MESSAGE = "No Question!"
const NO_VARIABLE_MESSAGE = "Variable Unset!"
const DONE_RESULT_TEMPLATE = "{variable_name} = {new_value}"

onready var Prompt:Label = get_node("./UserInputPlay/Prompt")
onready var Enter:Button = get_node("./UserInputPlay/Enter")
onready var InputsHolder = get_node("./UserInputPlay/Input")
onready var Inputs = {
	"str":  get_node("./UserInputPlay/Input/String"),
	"num":  get_node("./UserInputPlay/Input/Number"),
	"bool": get_node("./UserInputPlay/Input/Boolean"),
}
onready var Result = get_node("./UserInputPlay/Result")

func _ready() -> void:
	register_connections()
	_NODE_IS_READY = true
	if _PLAY_IS_SET_UP:
		setup_view()
	if _DEFERRED_VIEW_PLAY_SLOT >= 0:
		set_view_played(_DEFERRED_VIEW_PLAY_SLOT)
	pass

func register_connections() -> void:
	Enter.connect("pressed", self, "play_forward", [], CONNECT_DEFERRED)
	pass
	
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

func setup_view() -> void:
	if _NODE_RESOURCE.has("data"):
		# prompt
		if _NODE_RESOURCE.data.has("prompt") && (_NODE_RESOURCE.data.prompt is String) :
			var prompt_text
			if _NODE_RESOURCE.data.prompt.length() > 0:
				prompt_text = _NODE_RESOURCE.data.prompt.format(_CURRENT_VARIABLES_VALUE_BY_NAME)
			else:
				prompt_text = PROMPT_UNSET_MESSAGE
			Prompt.set_text( prompt_text )
		# variable & input
		if _NODE_RESOURCE.data.has("variable") && (_NODE_RESOURCE.data.variable is int) :
			if _NODE_RESOURCE.data.variable >= 0:
				var the_variable
				if _VARIABLES_CURRENT.has(_NODE_RESOURCE.data.variable):
					the_variable = _VARIABLES_CURRENT[_NODE_RESOURCE.data.variable]
				else:
					the_variable = Main.Mind.lookup_resource(_NODE_RESOURCE.data.variable, "variables")
				if the_variable is Dictionary:
					_THE_VARIABLE_ID = _NODE_RESOURCE.data.variable
					_THE_VARIABLE = the_variable
	set_view_unplayed()
	pass

func setup_play(node_id:int, node_resource:Dictionary, node_map:Dictionary, _playing_in_slot:int = -1, variables_current:Dictionary={}) -> void:
	_NODE_ID = node_id
	_NODE_RESOURCE = node_resource
	_NODE_MAP = node_map
	_VARIABLES_CURRENT = variables_current
	remap_current_variables_value_by_name(variables_current)
	remap_connections_for_slots()
	# update fields and children
	if _NODE_IS_READY:
		setup_view()
	# handle skip in case
	if _NODE_MAP.has("skip") && _NODE_MAP.skip == true:
		skip_play()
	# ... otherwise wait for user manual input
	_PLAY_IS_SET_UP = true
	pass

func read_input():
	var the_value = null
	if _THE_VARIABLE is Dictionary && _THE_VARIABLE.has("type"):
		match _THE_VARIABLE.type:
			"str":
				the_value = Inputs["str"].get_text()
			"num":
				the_value = int( Inputs["num"].get_value() )
			"bool":
				var int_boolean = int( Inputs["bool"].get_selected_id() )
				the_value = ( int_boolean == 1 )
	return the_value 

# Note: there is only one playable slot
func play_forward(with_input_read_and_set:bool = true) -> void:
	if _NODE_SLOTS_MAP.has(ONLY_PLAY_SLOT):
		var next = _NODE_SLOTS_MAP[ONLY_PLAY_SLOT]
		if with_input_read_and_set != false:
			var new_var_value = read_input()
			if new_var_value != null:
				self.emit_signal("reset_variable", {
					_THE_VARIABLE_ID: new_var_value
				})
				set_result(DONE_RESULT_TEMPLATE.format({
					"variable_name": _THE_VARIABLE.name,
					"new_value": new_var_value,
				}), true)
		self.emit_signal("play_forward", next.id, next.slot)
	else:
		emit_signal("status_code", CONSOLE_STATUS_CODE.END_EDGE)
	set_view_played_on_ready(ONLY_PLAY_SLOT)
	pass

func set_view_played_on_ready(slot_idx:int) -> void:
	if _NODE_IS_READY:
		set_view_played(slot_idx)
	else:
		_DEFERRED_VIEW_PLAY_SLOT = slot_idx
	pass

func set_result(value:String, show:bool = true):
	Result.set_text(value)
	Result.set("visible", show)
	pass

func switch_input_to_type(visible_type:String) -> void:
	for type in Inputs:
		Inputs[type].set("visible", (type == visible_type))
	pass

func set_view_unplayed() -> void:
	if _THE_VARIABLE_ID >= 0:
		InputsHolder.set("visible", true)
		switch_input_to_type( _THE_VARIABLE.type )
		set_result("", false)
	else:
		InputsHolder.set("visible", false)
		set_result( NO_VARIABLE_MESSAGE, true )
	Enter.set("visible", true)
	pass

func set_view_played(slot_idx:int = ONLY_PLAY_SLOT) -> void:
	InputsHolder.set("visible", false)
	Enter.set("visible", false)
	pass

func skip_play() -> void:
	play_forward(false) # ... without reading and seting input
	pass

func step_back() -> void:
	set_view_unplayed()
	pass
	
