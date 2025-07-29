# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# User-Input Console Element
extends Control

signal play_forward
signal status_code
# signal clear_up
signal reset_variables
# signal reset_characters_tags

@onready var Main = get_tree().get_root().get_child(0)

const ONLY_PLAY_SLOT = 0

var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary
var _VARIABLES_CURRENT:Dictionary
var _CURRENT_VARS_EXPO:Dictionary
var _CURRENT_CHAR_TAGS_EXPO:Dictionary
var _THE_VARIABLE_ID:int = -1
var _THE_VARIABLE = null
var _THE_VARIABLE_ORIGINAL_VALUE = null

var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

const PROMPT_UNSET_MESSAGE = "USER_INPUT_CONSOLE_PROMPT_UNSET_MSG" # Translated ~ "No Question!"
const NO_VARIABLE_MESSAGE = "USER_INPUT_CONSOLE_NO_VARIABLE_MSG" # Translated ~ "Unset/Invalid Variable!"
const DONE_RESULT_TEMPLATE = "{variable_name} `{original_value}` = `{new_value}`"

const DEFAULT_CUSTOM = {
	"str": ["", "", ""],
	"num": [-100, 100, 1, 0], # if unset `set_input_view` allows greater and lesser too
	"bool": ["Negative (False)", "Positive (True)", true],
}

@onready var Prompt:Label = $Play/Head/Prompt
@onready var Enter:Button = $Play/Actions/Submit
@onready var Skip:Button = $Play/Actions/Skip
@onready var InputsHolder = $Play/Input
@onready var Inputs = {
	"str":  $Play/Input/String,
	"num":  $Play/Input/Number,
	"bool": $Play/Input/Boolean,
}
@onready var Invalid = $Play/Invalid
@onready var Result = $Play/Result

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
	Enter.pressed.connect(self.read_and_try_playing_forward.bind(true), CONNECT_DEFERRED)
	Skip.pressed.connect(self.skip_play, CONNECT_DEFERRED)
	for type in Inputs:
		Inputs[type].gui_input.connect(self._reset_input_validity_state, CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID) -> void:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
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

func setup_view() -> void:
	if _NODE_RESOURCE.has("data"):
		# prompt
		if _NODE_RESOURCE.data.has("prompt") && (_NODE_RESOURCE.data.prompt is String) :
			var prompt_text
			if _NODE_RESOURCE.data.prompt.length() > 0:
				prompt_text = _NODE_RESOURCE.data.prompt.format(_CURRENT_CHAR_TAGS_EXPO).format(_CURRENT_VARS_EXPO)
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
					if _THE_VARIABLE_ORIGINAL_VALUE == null:
						_THE_VARIABLE_ORIGINAL_VALUE = (
							the_variable.value if the_variable.has("value") else the_variable.init
						)
	set_view_unplayed()
	pass

func setup_play(
	node_id:int, node_resource:Dictionary, node_map:Dictionary, _playing_in_slot:int = -1,
	variables_current:Dictionary={}, characters_current:Dictionary={}
) -> void:
	_NODE_ID = node_id
	_NODE_RESOURCE = node_resource
	_NODE_MAP = node_map
	_VARIABLES_CURRENT = variables_current
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
		# ... otherwise wait for user manual input
		else:
			set_view_unplayed()
	else:
		set_view_unplayed()
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
	else:
		printerr("Invalid user-input node with no variable of valid type: ", _NODE_RESOURCE, _THE_VARIABLE)
	return the_value 

func _get_custom_input_properties() -> Array:
	return (
		_NODE_RESOURCE.data.custom
		if (
			_NODE_RESOURCE.has("data") &&  _NODE_RESOURCE.data is Dictionary &&
			_NODE_RESOURCE.data.has("custom") && _NODE_RESOURCE.data.custom is Array
		)
		else []
	)

func validate_input(input):
	if input != null:
		# Following checks nullify the input if it's not valid.
		# Only nodes with custom field need to be validated; others can pass anyway.
		var custom = _get_custom_input_properties()
		# empty array is just like no `custom` so we skip them too
		if custom.size() != 0:
			var error = null
			match _THE_VARIABLE.type:
				"str":
					# For `str`s only pattern (first, most significant element)
					# is what we need to check, and require it to be a string:
					if custom[0] is String: # (We checked above for the array to at least have 1 element)
						if custom[0].length() > 0: # (Conventionally we don't check for blank patterns and pass)
							var regex = RegEx.new()
							var compiled = regex.compile(custom[0])
							if compiled == OK:
								# RegEx.search() returns RegExMatch if found, otherwise `null`
								var matched = regex.search(input)
								if matched == null || matched.get_string(0) != input: # (i.e. no match or not exact)
									input = null # just invalid input (no structural error)
							else:
								error = "custom pattern (first element) is not a compilable RegEx!"
								input = null
					else:
						input = null
						error = "the pattern (first custom parameter) needs to be string (even blank.)"
				"num":
					if custom.size() >= 3:
						for required in range(0, 3):
							if (custom[required] is int) != true:
								input = null
								error = "all required values in custom for `num` [min, max, step, ...] shall be integers."
								break
						if input != null: # (all integers, we can still proceed)
							var min_ = custom[0]
							var max_ = custom[1]
							var step_ = custom[2]
							if min_ <= max_:
								if min_ == max_:
									# although this is not allowed by the inspector anymore,
									# we still let singular values to pass for backward compatibility
									if input != min_:
										input = null
								else: # ( min_ < max_)
									if input < min_ || input > max_:
										input = null
									else: # is in range but is it stepped properly?
										if (
											# (conventionally invalid step parameters are ignored and any value in range can pass)
											step_ >= 1 && step_ <= abs(max_ - min_) &&
											abs(input - min_) % step_ != 0
										):
											input = null
							else:
								input = null
								error = "`min` custom property shall be less or equal to `max`!"
					else:
						input = null
						error = "we expect at least 3 numeral values [min, max, step, ...] to validate input."
				"bool":
					# NOTE: custom properties for boolean does not enforce any validation.
					pass
			if error is String: # where invalidated
				printerr("User-input (#%s) node's `custom` parameter(s) are invalid; " % _NODE_ID + error + " > ", _NODE_RESOURCE, _THE_VARIABLE)
		else:
			print_debug("empty or undefined `custom` properties for user-input node (%s): " % _NODE_ID, _NODE_RESOURCE)
	# return the input anyway, it's null or nullified if invalid:
	return input

# Note: there is only one playable slot
func read_and_try_playing_forward(apply_change:bool = true) -> void:
	var play = false
	if apply_change != false:
		var new_var_value = validate_input( read_input() )
		if new_var_value != null:
			self.reset_variables.emit({
				_THE_VARIABLE_ID: new_var_value
			})
			set_result(new_var_value, true)
			play = true # Validated, applied and playable
		else:
			play = false # Invalid input
	else:
		play = true # Skipped node (play without applying variable)
	# ...
	_reset_input_validity_state(play)
	if play:
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

func set_result(value, make_visible:bool = true, unset = ""):
	var text = (
		unset if value == null else
		DONE_RESULT_TEMPLATE.format({
			"variable_name": _THE_VARIABLE.name,
			"original_value": _THE_VARIABLE_ORIGINAL_VALUE,
			"new_value": "%s" % value,
		})
	)
	Result.set_text(text)
	Result.set("visible", make_visible)
	pass

func _reset_input_validity_state(_force = null) -> void:
	var validity = _force if _force is bool else ( validate_input( read_input() ) != null )
	Invalid.set_visible( ! validity )
	Enter.set_disabled( ! validity )
	pass

func set_input_view() -> void:
	var custom = _get_custom_input_properties()
	var array_size = custom.size()
	match _THE_VARIABLE.type:
		"str": # [pattern, default, extra]
			Inputs["str"].set_text( custom[1] if array_size >= 2 && custom[1] is String else DEFAULT_CUSTOM.str[1] )
			Inputs["str"].set_placeholder( custom[2] if array_size >= 3 && custom[2] is String else DEFAULT_CUSTOM.str[2] )
		"num": # [min, max, step, value]
			var has_min = (array_size >= 1 && custom[0] is int)
			Inputs["num"].set_min( custom[0] if has_min else DEFAULT_CUSTOM.num[0] )
			Inputs["num"].set_allow_lesser( has_min == false )
			# ...
			var has_max = (array_size >= 2 && custom[1] is int)
			Inputs["num"].set_max( custom[1] if has_max else DEFAULT_CUSTOM.num[1] )
			Inputs["num"].set_allow_greater( has_max == false )
			# ...
			Inputs["num"].set_step( max( abs(custom[2]), 1 ) if array_size >= 3 && custom[2] is int else DEFAULT_CUSTOM.num[2] )
			# ...
			Inputs["num"].set_value( custom[3] if array_size >= 4 && custom[3] is int else DEFAULT_CUSTOM.num[3] )
		"bool": # [negative, positive, default-state]
			Inputs["bool"].set_item_text(
				0, (custom[0] if array_size >= 1 && custom[0] is String && custom[0].length() > 0 else DEFAULT_CUSTOM.bool[0])
			)
			Inputs["bool"].set_item_text(
				1, (custom[1] if array_size >= 2 && custom[1] is String && custom[1].length() > 0 else DEFAULT_CUSTOM.bool[1])
			)
			Inputs["bool"].set("selected", (
				custom[2] if array_size >= 3 && custom[2] is bool else (1 if DEFAULT_CUSTOM.bool[2] == true else 0)
			))
	for type in Inputs:
		Inputs[type].set("visible", (type == _THE_VARIABLE.type))
	_reset_input_validity_state()
	pass

func set_view_unplayed() -> void:
	if _THE_VARIABLE_ID >= 0:
		InputsHolder.set("visible", true)
		set_input_view()
		set_result("?", false)
		Enter.set_disabled(false)
	else:
		InputsHolder.set("visible", false)
		Invalid.set_visible(false)
		Enter.set_disabled(true)
		set_result(null, true, NO_VARIABLE_MESSAGE)
	Enter.set("visible", true)
	Skip.set("visible", true)
	pass

func set_view_played(_slot_idx:int = ONLY_PLAY_SLOT) -> void:
	InputsHolder.set("visible", false)
	Enter.set("visible", false)
	Skip.set("visible", false)
	pass

func skip_play() -> void:
	set_result(_THE_VARIABLE_ORIGINAL_VALUE, true)
	read_and_try_playing_forward(false) # ... without applying input
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
	
