# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Condition Sub-Inspector
extends Control

@onready var Main = get_tree().get_root().get_child(0)

var _OPEN_NODE_ID
var _OPEN_NODE

var _PROJECT_VARIABLES_CACHE

var _OPERATORS_LISTED_BY_ITEM_ID
var _OPERATORS_ITEM_ID_LISTED_BY_KEY

const OPERATOR_ITEM_TEXT_TEMPLATE = "CONDITION_INSPECTOR_OPERATOR_ITEM_TEXT_TEMPLATE" # Translated ~ "{text} ({sign})"
const COMPARE_TO_INITIAL_VALUE_OF_VAR_TEXT_TEMPLATE = "CONDITION_INSPECTOR_COMPARE_TO_SELF_INITIAL" # Translated ~ "Self (Initial Value)" (accepting `{self}` placeholder for the variable name)

const PARAMETER_MODES_ENUM = ConditionSharedClass.PARAMETER_MODES_ENUM
const PARAMETER_MODES_ENUM_CODE = ConditionSharedClass.PARAMETER_MODES_ENUM_CODE

const COMPARISON_OPERATORS = ConditionSharedClass.COMPARISON_OPERATORS

# data for unset variable (view)
const NO_VARIABLE_VAR_TYPE = "bool"
const NO_VARIABLE_TEXT = "CONDITION_INSPECTOR_NO_VARIABLE" # Translated ~ "No Variable Available"
const NO_VARIABLE_ID = -1

var DEFAULT_NODE_DATA = {
	"variable": NO_VARIABLE_ID, # uid of the target variable to be checked
	"operator": COMPARISON_OPERATORS[NO_VARIABLE_VAR_TYPE].keys()[0], # comparison operation
	"with": [PARAMETER_MODES_ENUM_CODE.value, null] # [PARAMETER_MODES_ENUM_CODE::value/variable, value/variable_id]
}

var This = self

@onready var VariablesInspector = Main.Mind.Inspector.Tab.Variables

@onready var Variables = $Variable/Selector
@onready var GlobalFilters = $Variable/Filtered
@onready var Operators = $Operator
@onready var ParameterType = $Rhs/Mode
@onready var ParameterVariable = $Rhs/Parameter/Variable
@onready var ParameterValue = $Rhs/Parameter/Value
@onready var ParameterValueTypes = {
	"str":  $Rhs/Parameter/Value/String,
	"num":  $Rhs/Parameter/Value/Number,
	"bool": $Rhs/Parameter/Value/Boolean,
}

func _ready() -> void:
	load_parameter_types()
	register_connections()
	pass

func load_parameter_types() -> void:
	ParameterType.clear()
	for type_id in PARAMETER_MODES_ENUM:
		var type_text = PARAMETER_MODES_ENUM[type_id].capitalize() 
		ParameterType.add_item(type_text, type_id)
	pass

func register_connections() -> void:
	Variables.item_selected.connect(self._on_variables_item_selected, CONNECT_DEFERRED)
	GlobalFilters.pressed.connect(self.refresh_variables_list, CONNECT_DEFERRED)
	# Operators.item_selected.connect(self._on_operators_item_selected, CONNECT_DEFERRED)
	ParameterType.item_selected.connect(self._on_parameter_type_item_selected, CONNECT_DEFERRED)
	pass

func refresh_operators_list() -> void:
	Operators.clear()
	_OPERATORS_LISTED_BY_ITEM_ID = {}
	_OPERATORS_ITEM_ID_LISTED_BY_KEY = {}
	var selected_variable_id = Variables.get_selected_metadata()
	var selected_variable_type = NO_VARIABLE_VAR_TYPE
	if _PROJECT_VARIABLES_CACHE.has(selected_variable_id):
		selected_variable_type = _PROJECT_VARIABLES_CACHE[ selected_variable_id ].type
	var the_operators = COMPARISON_OPERATORS[selected_variable_type]
	var operator_id = 0
	for operator in the_operators:
		_OPERATORS_LISTED_BY_ITEM_ID[operator_id] = operator
		_OPERATORS_ITEM_ID_LISTED_BY_KEY[operator] = operator_id
		Operators.add_item(
			tr(OPERATOR_ITEM_TEXT_TEMPLATE).format({
				"sign": the_operators[operator].sign,
				"text": tr(the_operators[operator].text),
			}),
			operator_id
		)
		operator_id += 1
	# select the operator if the node has one set
	if a_node_is_open() && _OPEN_NODE.data.variable == selected_variable_id:
		var the_node_operator_item_idx = Operators.get_item_index( _OPERATORS_ITEM_ID_LISTED_BY_KEY[_OPEN_NODE.data.operator] )
		Operators.select(the_node_operator_item_idx)
	pass

func find_listed_variable_index(by_id: int) -> int:
	for idx in range(0, Variables.get_item_count()):
		if Variables.get_item_metadata(idx) == by_id:
			return idx
	return -1

func refresh_variables_list(select_by_res_id:int = -1) -> void:
	Variables.clear()
	_PROJECT_VARIABLES_CACHE = Main.Mind.clone_dataset_of("variables")
	if _PROJECT_VARIABLES_CACHE.size() > 0 :
		var already = null
		if a_node_is_open() && _OPEN_NODE.data.has("variable") && _OPEN_NODE.data.variable in _PROJECT_VARIABLES_CACHE :
			already = _OPEN_NODE.data.variable
		var global_filters = VariablesInspector.read_listing_instruction()
		var apply_globals = GlobalFilters.is_pressed()
		var listing = {}
		for variable_id in _PROJECT_VARIABLES_CACHE:
			var the_variable = _PROJECT_VARIABLES_CACHE[variable_id]
			if variable_id == already || apply_globals == false || VariablesInspector.passes_filters(global_filters, variable_id, the_variable):
				listing[the_variable.name] = variable_id
		if listing.size() == 0:
			Variables.add_item(NO_VARIABLE_TEXT, NO_VARIABLE_ID)
			Variables.set_item_metadata(0, NO_VARIABLE_ID)
		else:
			var listing_keys = listing.keys()
			if apply_globals && global_filters.SORT_ALPHABETICAL:
				listing_keys.sort()
			var item_index := 0
			for var_name in listing_keys:
				var id = listing[var_name]
				Variables.add_item(var_name if already != id || apply_globals == false else "["+ var_name +"]", id)
				Variables.set_item_metadata(item_index, id)
				item_index += 1
			if select_by_res_id >= 0 :
				var variable_item_index = find_listed_variable_index( select_by_res_id )
				Variables.select( variable_item_index )
			else:
				if already != null :
					var variable_item_index = find_listed_variable_index(already)
					Variables.select( variable_item_index )
	else:
		Variables.add_item(NO_VARIABLE_TEXT, NO_VARIABLE_ID)
		Variables.set_item_metadata(0, NO_VARIABLE_ID)
	pass

func _on_variables_item_selected(_item_index:int) -> void:
	refresh_operators_list()
	refresh_comparison_parameter()
	pass

#func _on_operators_item_selected(item_index:int) -> void:
#	pass

func _on_parameter_type_item_selected(item_index:int) -> void:
	var type_id = ParameterType.get_item_id(item_index)
	match PARAMETER_MODES_ENUM[type_id]:
		"value":
			ParameterVariable.set_deferred("visible", false)
			ParameterValue.set_deferred("visible", true)
			refresh_comparison_parameter_value()
		"variable":
			ParameterValue.set_deferred("visible", false)
			ParameterVariable.set_deferred("visible", true)
			refresh_comparison_parameters_variable_list()
	pass

func refresh_comparison_parameter_value(value = null) -> void:
	# value can only be of the same type as the selected variable,
	# so the form inputs should correspond to the selected target variable
	var selected_check_var_id = Variables.get_selected_metadata()
	var selected_check_var_type = NO_VARIABLE_VAR_TYPE
	if _PROJECT_VARIABLES_CACHE.has(selected_check_var_id):
		selected_check_var_type = _PROJECT_VARIABLES_CACHE[ selected_check_var_id ].type
	for type in ParameterValueTypes:
		ParameterValueTypes[type].set_deferred("visible", (true if (type == selected_check_var_type) else false))
	if value == null:
		value = Settings.VARIABLE_TYPES[selected_check_var_type].default
		# but can we use the value from current state of the node ?
		if a_node_is_open() && (_OPEN_NODE.data.variable is int && _OPEN_NODE.data.variable >= 0) && _PROJECT_VARIABLES_CACHE.has(_OPEN_NODE.data.variable):
			var open_node_variable_type = _PROJECT_VARIABLES_CACHE[ _OPEN_NODE.data.variable ].type
			if (selected_check_var_type == open_node_variable_type) && ( selected_check_var_id == _OPEN_NODE.data.variable) :
				# we can, so...
				value = _OPEN_NODE.data.with[1]
	match selected_check_var_type:
		"str":
			ParameterValueTypes["str"].set_deferred("text", value)
		"num":
			ParameterValueTypes["num"].set_deferred("value", value)
		"bool":
			ParameterValueTypes["bool"].select( ParameterValueTypes["bool"].get_item_index( ( 1 if value else 0 ) ) )
	pass

func find_listed_parameter_variable_index(by_id: int) -> int:
	for idx in range(0, ParameterVariable.get_item_count()):
		if ParameterVariable.get_item_metadata(idx) == by_id:
			return idx
	return -1

func refresh_comparison_parameters_variable_list(select_by_variable_id:int = -1) -> void:
	ParameterVariable.clear()
	# Note: it currently happens after `refresh_variables_list`, so we can use cache
	var selected_check_var_id = Variables.get_selected_metadata()
	var type_of_selected_check_var_id = _PROJECT_VARIABLES_CACHE[ selected_check_var_id ].type
	var item_index := 0
	for variable_id in _PROJECT_VARIABLES_CACHE:
		var the_variable = _PROJECT_VARIABLES_CACHE[variable_id]
		# only variables of the same type can be compared, so ...
		if the_variable.type == type_of_selected_check_var_id:
			var the_param_var_item_text = ( the_variable.name if ( variable_id != selected_check_var_id ) else (tr(COMPARE_TO_INITIAL_VALUE_OF_VAR_TEXT_TEMPLATE).format({ "self": the_variable.name })) )
			ParameterVariable.add_item(the_param_var_item_text, variable_id)
			ParameterVariable.set_item_metadata(item_index, variable_id)
			item_index += 1
	if select_by_variable_id >= 0 :
		var variable_item_index = find_listed_parameter_variable_index( select_by_variable_id )
		ParameterVariable.select( variable_item_index )
	else:
		if a_node_is_open() && (_OPEN_NODE.data.with[0] == PARAMETER_MODES_ENUM_CODE.variable && _OPEN_NODE.data.with[1] is int && _OPEN_NODE.data.with[1] >= 0 ):
			var variable_item_index = find_listed_parameter_variable_index( _OPEN_NODE.data.with[1] )
			ParameterVariable.select( variable_item_index )
	pass

func refresh_comparison_parameter(parameter_type_enum_id:int = -1) -> void:
	if (parameter_type_enum_id in PARAMETER_MODES_ENUM) == false:
		if a_node_is_open():
			parameter_type_enum_id = _OPEN_NODE.data.with[0]
		else:
			parameter_type_enum_id = PARAMETER_MODES_ENUM_CODE.value # use the first one (~ value mode) anyway
	var param_type_item_idx = ParameterType.get_item_index( parameter_type_enum_id )
	ParameterType.select( param_type_item_idx )
	# because `.select` won't fire the `item_select` event, we will call ...
	_on_parameter_type_item_selected(param_type_item_idx)
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
	# `refresh_operators_list` relies on the cache made by `refresh_variables_list`
	refresh_variables_list()
	refresh_operators_list()
	refresh_comparison_parameter()
	pass

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	# ... then refresh view
	refresh_view_all() # that will default to cache, when called without args
	pass

func read_the_parameter_with() -> Array:
	var mode_enum = ParameterType.get_selected_id()
	var the_value = null
	match mode_enum:
		PARAMETER_MODES_ENUM_CODE.value:
			var selected_check_var_id = Variables.get_selected_metadata()
			if _PROJECT_VARIABLES_CACHE.has(selected_check_var_id):
				var selected_check_var_type = _PROJECT_VARIABLES_CACHE[ selected_check_var_id ].type
				match selected_check_var_type:
					"str":
						the_value = ParameterValueTypes["str"].get_text()
					"num":
						the_value = int( ParameterValueTypes["num"].get_value() )
					"bool":
						var int_boolean = int( ParameterValueTypes["bool"].get_selected_id() )
						the_value = ( int_boolean == 1 )
		PARAMETER_MODES_ENUM_CODE.variable:
			the_value = ParameterVariable.get_selected_metadata()
	return [mode_enum, the_value]

func _read_parameters() -> Dictionary:
	# if there is no variable out there
	if _PROJECT_VARIABLES_CACHE.size() == 0:
		# we can only accept unset parameters, so ...
		return _create_new()
	# otherwise ...
	var parameters = {
		"variable": Variables.get_selected_metadata(),
		"operator": _OPERATORS_LISTED_BY_ITEM_ID[ Operators.get_selected_id() ],
		"with": read_the_parameter_with()
	}
	# `use` state can be for ...
	var _use = { "drop":[], "refer":[] }
	# ... `variable` being checked,
	if parameters.variable != _OPEN_NODE.data.variable: # if changed
		_use.drop.append(_OPEN_NODE.data.variable) # old one
		_use.refer.append(parameters.variable) # new one
	# ... or the comparison variable in `with` parameter
	var old_mode_is_variable = (_OPEN_NODE.data.with[0] == PARAMETER_MODES_ENUM_CODE.variable)
	var old_comparison_param = _OPEN_NODE.data.with[1]
	var new_mode_is_variable = (parameters.with[0] == PARAMETER_MODES_ENUM_CODE.variable)
	var new_comparison_param = parameters.with[1]
		# where different possibilities are:
	if old_mode_is_variable && new_mode_is_variable && old_comparison_param != new_comparison_param:
		_use.refer.append(new_comparison_param)
		_use.drop.append(old_comparison_param)
	elif old_mode_is_variable && (! new_mode_is_variable):
		_use.drop.append(old_comparison_param)
	elif (! old_mode_is_variable) && new_mode_is_variable:
		_use.refer.append(new_comparison_param)
	# clean up `_use`
	for cmd in _use:
		for res in _use[cmd]:
			if res < 0 :
				_use[cmd].erase(res)
	if _use.drop.size() > 0 || _use.refer.size() > 0 :
		parameters._use = _use
		parameters._use.field = "variables"
	return parameters

func _create_new(_new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data

func _translate_internal_ref(data: Dictionary, translation: Dictionary) -> void:
	if translation.ids.has(data.variable):
		data.variable = translation.ids[data.variable]
	if data.with[0] == PARAMETER_MODES_ENUM_CODE.variable:
		if translation.ids.has(data.with[1]):
			data.with[1] = translation.ids[data.with[1]]
	pass
