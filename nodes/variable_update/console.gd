# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Variable-Update Console Element
extends Control

signal play_forward
signal status_code
# signal clear_up
signal reset_variables
# signal reset_characters_tags

@onready var Main = get_tree().get_root().get_child(0)

# will be played forward after automatic evaluation (update)
# or by a user choice (Apply or Dismiss)
const ONLY_PLAY_SLOT = 0

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary
var _VARIABLES_CURRENT:Dictionary
var _THE_VARIABLE_ID:int = -1
var _THE_VARIABLE = null
var _THE_VARIABLE_ORIGINAL_VALUE = null

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

const UNSET_OR_INVALID_MESSAGE = "VARIABLE_UPDATE_CONSOLE_UNSET_OR_INVALID_MSG" # Translated ~ "Unset !"
@onready var VarUpExpression = VariableUpdateSharedClass.expression.new(Main.Mind)

@onready var TheExpression = $Play/Head/Expression
@onready var Apply = $Play/Actions/Apply
@onready var Dismiss = $Play/Actions/Dismiss

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
	Apply.pressed.connect(self.evaluate_and_play_forward.bind(true), CONNECT_DEFERRED)
	Dismiss.pressed.connect(self.evaluate_and_play_forward.bind(false), CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

# update view parts, normally called first after instancing via setup_play
# it also fetches target variable data
func setup_view() -> void:
	var unset = true
	if _NODE_RESOURCE.has("data"):
		# cache variable
		if _NODE_RESOURCE.data.has("variable") && (_NODE_RESOURCE.data.variable is int) :
			var the_variable
			if _NODE_RESOURCE.data.variable >= 0 && _VARIABLES_CURRENT.has(_NODE_RESOURCE.data.variable):
				the_variable = _VARIABLES_CURRENT[_NODE_RESOURCE.data.variable]
			else:
				the_variable = Main.Mind.lookup_resource(_NODE_RESOURCE.data.variable, "variables")
			if the_variable is Dictionary:
				_THE_VARIABLE_ID = _NODE_RESOURCE.data.variable
				_THE_VARIABLE = the_variable
				if _THE_VARIABLE_ORIGINAL_VALUE == null:
					_THE_VARIABLE_ORIGINAL_VALUE = (
						the_variable.value if the_variable.has("value") else the_variable.init
					)
		# expression
		var expression_text = VarUpExpression.parse(_NODE_RESOURCE.data, _VARIABLES_CURRENT)
		if expression_text is String:
			TheExpression.set_deferred("text", expression_text)
			unset = false
	if unset:
		TheExpression.set_deferred("text", UNSET_OR_INVALID_MESSAGE)
	set_view_unplayed()
	pass
	
func setup_play(
	node_id:int, node_resource:Dictionary, node_map:Dictionary, _playing_in_slot:int = -1,
	variables_current:Dictionary={}, _characters_current:Dictionary={}
) -> void:
	_NODE_ID = node_id
	_NODE_RESOURCE = node_resource
	_NODE_MAP = node_map
	_VARIABLES_CURRENT = variables_current
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
			evaluate_and_play_forward(true)
	else:
		set_view_unplayed()
	pass

func evaluate_and_play_forward(do_apply:bool = true) -> void:
	if _THE_VARIABLE_ID >= 0:
		var new_value = VarUpExpression.evaluate(_NODE_RESOURCE.data, _VARIABLES_CURRENT)
		if new_value == null:
			printerr("Evaluation of Update Failed! Data: ", _NODE_RESOURCE.data, " Variables Current: ", _VARIABLES_CURRENT)
		else:
			if do_apply:
				self.reset_variables.emit({
					_THE_VARIABLE_ID: new_value
				})
	play_forward_from(ONLY_PLAY_SLOT)
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
	# in case unplayed (i.e. step-back after automatic evaluation)
	# ... let user choose
	Apply.set_deferred("visible", true)
	Dismiss.set_deferred("visible", true)
	pass

func set_view_played(_slot_idx:int = ONLY_PLAY_SLOT) -> void:
	Apply.set_deferred("visible", false)
	Dismiss.set_deferred("visible", false)
	pass

func skip_play() -> void:
	play_forward_from(ONLY_PLAY_SLOT)
	pass

func step_back() -> void:
	# Stepping back, we should undo the changes we've made to the variable as well,
	# so the user can inspect the previous value, before manually playing or skipping the node.
	if _THE_VARIABLE_ID >= 0:
		self.reset_variables.emit({
			_THE_VARIABLE_ID: _THE_VARIABLE_ORIGINAL_VALUE
		})
	# ...
	set_view_unplayed()
	pass
