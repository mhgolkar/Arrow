# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Generator Node Type Console
extends PanelContainer

signal play_forward
signal status_code
# warning-ignore:unused_signal
signal clear_up
signal reset_variable

onready var Main = get_tree().get_root().get_child(0)

# will be played forward after automatic process (update) or by a user choice
const ONLY_PLAY_SLOT = 0

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary
var _VARIABLES_CURRENT:Dictionary
var _THE_TARGET_VARIABLE_ID:int = -1
var _THE_TARGET_VARIABLE = null
var _THE_TARGET_VARIABLE_ORIGINAL_VALUE = null

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

const UNSET_OR_INVALID_TARGET_VAR_MESSAGE = "Undefined"
const UNSET_OR_INVALID_METHOD_MESSAGE = "Unset"
const UNSET_OR_INVALID_ARGUMENTS_MESSAGE = "Null/Invalid"
const HIDE_ARGUMENTS_IF_UNSET = true

const OPERATION_STATE_FORMAT_STRING = "{name} `{original}` : {updated}"

onready var TheGenerator = GeneratorSharedClass.generator.new(Main.Mind)

onready var Method = get_node("./GeneratorPlay/PanelContainer/VBoxContainer/Method")
onready var Arguments = get_node("./GeneratorPlay/PanelContainer/VBoxContainer/Arguments")
onready var Target = get_node("./GeneratorPlay/PanelContainer/VBoxContainer/Target")
onready var Redo = get_node("./GeneratorPlay/Application/Redo")
onready var Skip = get_node("./GeneratorPlay/Application/Skip")

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
	Redo.connect("pressed", self, "generate_set_and_play_forward", [true], CONNECT_DEFERRED)
	Skip.connect("pressed", self, "skip_play", [], CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

func reset_operation_view(generated_value = "?") -> void:
	Target.set_deferred(
		"text", OPERATION_STATE_FORMAT_STRING.format({
			"name": _THE_TARGET_VARIABLE.name,
			"original": _THE_TARGET_VARIABLE_ORIGINAL_VALUE,
			"updated": generated_value,
		})
	)
	pass

# update view parts, normally called first after instancing via setup_play
# it also fetches target variable data
func setup_view() -> void:
	var unset = true
	if _NODE_RESOURCE.has("data"):
		# method
		if (
			_NODE_RESOURCE.data.has("method") &&
			GeneratorSharedClass.METHODS.has(_NODE_RESOURCE.data.method)
		):
			Method.set_deferred( "text", GeneratorSharedClass.METHODS[_NODE_RESOURCE.data.method] )
			var args_preview = GeneratorSharedClass.render_arguments_message(_NODE_RESOURCE.data)
			Arguments.set_deferred("text", args_preview if args_preview is String else UNSET_OR_INVALID_ARGUMENTS_MESSAGE)
			Arguments.set_deferred("visible", args_preview != null)
			unset = false
		# cache target variable
		if _NODE_RESOURCE.data.has("variable") && (_NODE_RESOURCE.data.variable is int) :
			var the_variable
			if _NODE_RESOURCE.data.variable >= 0 && _VARIABLES_CURRENT.has(_NODE_RESOURCE.data.variable):
				the_variable = _VARIABLES_CURRENT[_NODE_RESOURCE.data.variable]
			else:
				the_variable = Main.Mind.lookup_resource(_NODE_RESOURCE.data.variable, "variables")
			if the_variable is Dictionary && the_variable.has_all(["name", "type"]):
				_THE_TARGET_VARIABLE_ID = _NODE_RESOURCE.data.variable
				_THE_TARGET_VARIABLE = the_variable
				if _THE_TARGET_VARIABLE_ORIGINAL_VALUE == null:
					_THE_TARGET_VARIABLE_ORIGINAL_VALUE = (
						the_variable.value if the_variable.has("value") else the_variable.init
					)
				reset_operation_view()
			else:
				unset = true
	if unset:
		Target.set_deferred("text", UNSET_OR_INVALID_METHOD_MESSAGE)
		Method.set_deferred("text", UNSET_OR_INVALID_TARGET_VAR_MESSAGE)
		Arguments.set_deferred("text", UNSET_OR_INVALID_ARGUMENTS_MESSAGE)
		Arguments.set_deferred("visible", (! HIDE_ARGUMENTS_IF_UNSET))
	set_view_unplayed()
	pass

func setup_play(node_id:int, node_resource:Dictionary, node_map:Dictionary, _playing_in_slot:int = -1, variables_current:Dictionary={}) -> void:
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
			generate_set_and_play_forward(true)
	else:
		set_view_unplayed()
	pass

func generate_set_and_play_forward(proceed_update:bool = true) -> void:
	if _THE_TARGET_VARIABLE_ID >= 0:
		var new_value = TheGenerator.generate(_NODE_RESOURCE.data, _VARIABLES_CURRENT)
		if new_value == null:
			printerr("Data Generation Failed! Node: ", _NODE_RESOURCE.data)
		else:
			print_debug("Data Generation Result: ", new_value)
			if proceed_update:
				reset_operation_view(new_value)
				emit_signal("reset_variable", {
					_THE_TARGET_VARIABLE_ID: new_value
				})
	play_forward_from(ONLY_PLAY_SLOT)
	pass

func play_forward_from(slot_idx:int = ONLY_PLAY_SLOT) -> void:
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
	# in case unplayed (i.e. step-back after automatic process)
	# ... let user choose
	Redo.set_deferred("visible", true)
	Skip.set_deferred("visible", true)
	pass

func set_view_played(slot_idx:int = ONLY_PLAY_SLOT) -> void:
	Redo.set_deferred("visible", false)
	Skip.set_deferred("visible", false)
	pass

func skip_play() -> void:
	reset_operation_view("[Skipped]")
	play_forward_from(ONLY_PLAY_SLOT)
	pass

func step_back() -> void:
	# Stepping back, we should undo the changes we've made to the variable as well,
	# so the user can inspect the previous value, before manually playing or skipping the node.
	if _THE_TARGET_VARIABLE_ID >= 0:
		reset_operation_view()
		emit_signal("reset_variable", {
			_THE_TARGET_VARIABLE_ID: _THE_TARGET_VARIABLE_ORIGINAL_VALUE
		})
	# ...
	set_view_unplayed()
	pass
