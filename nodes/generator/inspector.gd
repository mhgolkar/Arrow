# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Generator Node Type Inspector
extends ScrollContainer

onready var Main = get_tree().get_root().get_child(0)

var _OPEN_NODE_ID
var _OPEN_NODE

var _PROJECT_VARIABLES_CACHE

var _METHODS_LISTED_BY_ITEM_ID = {}
var _METHODS_ITEM_ID_LISTED_BY_KEY = {}
	
# data for unset variable (view)
const NO_VARIABLE_VAR_TYPE = "bool"
const NO_VARIABLE_TEXT = "No Variable Available"
const NO_VARIABLE_ID = -1

var DEFAULT_NODE_DATA = {
	"variable": NO_VARIABLE_ID, # uid of the target variable to be updated
	"method": GeneratorSharedClass.VALID_METHODS_FOR_TYPE[NO_VARIABLE_VAR_TYPE][0],
	# "arguments": null # depends on the generator method
}

var This = self

onready var Variables = get_node("./Generate/Variables")
onready var Methods = get_node("./Generate/Methods")

onready var ArgumentsBox = get_node("./Generate/Arguments")
onready var ArgumentsFormForMethod = {
	"randi": get_node("./Generate/Arguments/RandomInt"),
	"ascii": get_node("./Generate/Arguments/RandomAscii"),
	"strst": get_node("./Generate/Arguments/FromStrSet"),
	"rnbln": null,
}
const ArgumentsGetterForMethod = {
	"randi": "read_randi_arguments",
	"ascii": "read_ascii_arguments",
	"strst": "read_strst_arguments",
	"rnbln": null,
}
const ArgumentsSetterForMethod = {
	"randi": "load_randi_arguments",
	"ascii": "load_ascii_arguments",
	"strst": "load_strst_arguments",
	"rnbln": null,
}
onready var RandomIntRangeFromValue = get_node("./Generate/Arguments/RandomInt/Range/From/Value")
onready var RandomIntRangeToValue = get_node("./Generate/Arguments/RandomInt/Range/To/Value")
onready var RandomIntModifiersNegative = get_node("./Generate/Arguments/RandomInt/Modifiers/Negative")
onready var RandomIntModifiersEven = get_node("./Generate/Arguments/RandomInt/Modifiers/Even")
onready var RandomIntModifiersOdd = get_node("./Generate/Arguments/RandomInt/Modifiers/Odd")
onready var RandomAsciiLength = get_node("./Generate/Arguments/RandomAscii/Length/Value")
onready var RandomAsciiPoolString = get_node("./Generate/Arguments/RandomAscii/Pool/String")
onready var StrSetPool = get_node("./Generate/Arguments/FromStrSet/StrSetPool")

const STRSET_DELIMITER_HINT_MESSAGE = "* Separate with `%s`"
onready var StrSetDelimiterHint = get_node("./Generate/Arguments/FromStrSet/Hint")

func _ready() -> void:
	register_connections()
	update_strset_delimiter_hint()
	pass

func register_connections() -> void:
	Variables.connect("item_selected", self, "_on_variables_item_selected", [], CONNECT_DEFERRED)
	Methods.connect("item_selected", self, "_on_method_item_selected", [], CONNECT_DEFERRED)
	RandomIntRangeFromValue.connect("value_changed", self, "_balance_from_to_for_randi", [], CONNECT_DEFERRED)
	RandomIntRangeToValue.connect("value_changed", self, "_balance_from_to_for_randi", [], CONNECT_DEFERRED)
	pass

func update_strset_delimiter_hint() -> void:
	StrSetDelimiterHint.set_deferred(
		"text",
		STRSET_DELIMITER_HINT_MESSAGE % GeneratorSharedClass.STRING_SET_DELIMITER
	)
	pass

func refresh_methods_list() -> void:
	Methods.clear()
	_METHODS_LISTED_BY_ITEM_ID = {}
	_METHODS_ITEM_ID_LISTED_BY_KEY = {}
	var selected_variable_id = Variables.get_selected_id()
	var selected_variable_type = NO_VARIABLE_VAR_TYPE
	if _PROJECT_VARIABLES_CACHE.has(selected_variable_id):
		selected_variable_type = _PROJECT_VARIABLES_CACHE[ selected_variable_id ].type
	var valid_methods = GeneratorSharedClass.VALID_METHODS_FOR_TYPE[selected_variable_type]
	var method_id = 0
	for method in valid_methods:
		_METHODS_LISTED_BY_ITEM_ID[method_id] = method
		_METHODS_ITEM_ID_LISTED_BY_KEY[method] = method_id
		Methods.add_item( GeneratorSharedClass.METHODS[method], method_id )
		method_id += 1
	# select the method if the node has anyone set
	if a_node_is_open() && _OPEN_NODE.data.variable == selected_variable_id:
		var the_node_method_item_idx = Methods.get_item_index( _METHODS_ITEM_ID_LISTED_BY_KEY[_OPEN_NODE.data.method] )
		Methods.select(the_node_method_item_idx)
	_on_method_item_selected() # to force show arguments box
	pass

# it loads variables into the option-button's list, where ...
# every item-id is the variable's resource-uid
func refresh_variables_list(select_by_res_id:int = -1) -> void:
	Variables.clear()
	_PROJECT_VARIABLES_CACHE = Main.Mind.clone_dataset_of("variables")
	if _PROJECT_VARIABLES_CACHE.size() > 0 : 
		for variable_id in _PROJECT_VARIABLES_CACHE:
			var the_variable = _PROJECT_VARIABLES_CACHE[variable_id]
			Variables.add_item(the_variable.name, variable_id)
		if select_by_res_id >= 0 :
			var variable_item_index = Variables.get_item_index( select_by_res_id )
			Variables.select( variable_item_index )
		else:
			if a_node_is_open() && _OPEN_NODE.data.has("variable") && _OPEN_NODE.data.variable in _PROJECT_VARIABLES_CACHE :
				var variable_item_index = Variables.get_item_index( _OPEN_NODE.data.variable )
				Variables.select( variable_item_index )
	else:
		Variables.add_item(NO_VARIABLE_TEXT, NO_VARIABLE_ID)
	pass

func _on_variables_item_selected(item_index:int) -> void:
	refresh_methods_list()
	pass

func _on_method_item_selected(item_index:int = -1) -> void:
	if item_index < 0:
		item_index = Methods.get_selected()
	var selected_method = _METHODS_LISTED_BY_ITEM_ID[ Methods.get_item_id(item_index) ]
	ArgumentsBox.set_visible( ArgumentsFormForMethod[selected_method] != null )
	for method in ArgumentsFormForMethod:
		if ArgumentsFormForMethod[method] != null:
			ArgumentsFormForMethod[method].set_visible( method == selected_method )
	pass

func a_node_is_open() -> bool :
	if (
		(_OPEN_NODE_ID is int) && (_OPEN_NODE_ID >= 0) &&
		(_OPEN_NODE is Dictionary) &&
		_OPEN_NODE.has("data") && (_OPEN_NODE.data is Dictionary)
	):
		return true
	else:
		return false

func refresh_view_all() -> void:
	# CAUTION!
	# `refresh_methods_list` relies on the cache made by `refresh_variables_list`
	refresh_variables_list()
	refresh_methods_list()
	pass

func _balance_from_to_for_randi(_x = null) -> void:
	var from = RandomIntRangeFromValue.get_value()
	var to = RandomIntRangeToValue.get_value()
	if to - from < 2:
		RandomIntRangeToValue.set_value(to + (2 - (to - from)))
	pass

func load_randi_arguments(args = null) -> void:
	var from = 0 # min from
	var to = 100 # default value (also in `.tscn`
	var negative = false
	var even = false
	var odd = false
	if args is Array && args.size() == 5:
		if args[0] is int && args[0] >= 0:
			from = args[0]
		if args[1] is int && args[1] >= 2: # min `to`
			to = args[1];
		if args[2] is bool:
			negative = args[2]
		if args[3] is bool:
			even = args[3]
		if args[4] is bool:
			odd = args[4]
	RandomIntRangeFromValue.set_value(from)
	RandomIntRangeToValue.set_value(to)
	RandomIntModifiersNegative.set_pressed(negative)
	RandomIntModifiersEven.set_pressed(even)
	RandomIntModifiersOdd.set_pressed(odd)
	pass

func load_ascii_arguments(args = null) -> void:
	var char_pool = ""
	var length = 1
	if args is Array && args.size() == 2:
		if args[0] is String:
			char_pool = args[0]
		if args[1] is int && args[1] >= 1:
			length = args[1]
	RandomAsciiPoolString.set_text(char_pool)
	RandomAsciiLength.set_value(length)
	pass

func load_strst_arguments(args = null) -> void:
	StrSetPool.set_text( args if args is String else "" )
	pass

func load_generator_arguments() -> void:
	var selected_method = _METHODS_LISTED_BY_ITEM_ID[ Methods.get_selected_id() ]
	if ArgumentsSetterForMethod[selected_method] != null:
		var arguments = (
			_OPEN_NODE.data.arguments
			if (
				a_node_is_open() && _OPEN_NODE.data.has("arguments") &&
				_OPEN_NODE.data.variable == Variables.get_selected_id()
			)
			else null
		)
		call(ArgumentsSetterForMethod[selected_method], arguments)
	pass

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	# ... then refresh view
	refresh_view_all() # that will default to cache, when called without args
	load_generator_arguments()
	pass

func read_randi_arguments() -> Array:
	_balance_from_to_for_randi()
	return [
		int( RandomIntRangeFromValue.get_value() ),
		int( RandomIntRangeToValue.get_value() ),
		RandomIntModifiersNegative.is_pressed(),
		RandomIntModifiersEven.is_pressed(),
		RandomIntModifiersOdd.is_pressed(),
	]

func read_ascii_arguments() -> Array:
	return [
		RandomAsciiPoolString.get_text(),
		int( RandomAsciiLength.get_value() )
	]

func read_strst_arguments() -> String:
	return StrSetPool.get_text()

func _read_parameters() -> Dictionary:
	# if there is no variable out there
	if _PROJECT_VARIABLES_CACHE.size() == 0:
		# we can only accept unset parameters, so ...
		return _create_new()
	# otherwise ...
	var selected_method = _METHODS_LISTED_BY_ITEM_ID[ Methods.get_selected_id() ]
	var parameters = {
		"variable": Variables.get_selected_id(),
		"method": selected_method,
	}
	if ArgumentsGetterForMethod[selected_method] != null:
		parameters["arguments"] = call(ArgumentsGetterForMethod[selected_method])
	# `use` state can be for ...
	var _use = { "drop":[], "refer":[] }
	# ... target `variable`,
	if parameters.variable != _OPEN_NODE.data.variable: # if changed
		_use.drop.append(_OPEN_NODE.data.variable) # old one
		_use.refer.append(parameters.variable) # new one
	# clean up `_use`
	for cmd in _use:
		for res in _use[cmd]:
			if res < 0 :
				_use[cmd].erase(res)
	if _use.drop.size() > 0 || _use.refer.size() > 0 :
		parameters._use = _use
		parameters._use.field = "variables"
	return parameters

func _create_new(new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data

func _translate_internal_ref(data: Dictionary, translation: Dictionary) -> void:
	if translation.ids.has(data.variable):
		data.variable = translation.ids[data.variable]
	pass
