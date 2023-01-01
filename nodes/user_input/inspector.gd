# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# User_Input Node Type Inspector
extends ScrollContainer

onready var Main = get_tree().get_root().get_child(0)

const NO_VARIABLE_TEXT = "No Variable Available"
const NO_VARIABLE_ID = -1

const DEFAULT_NODE_DATA = {
	"prompt": "",
	"variable": NO_VARIABLE_ID,
	#
	# IMPORTANT:
	# Console & runtimes depend on the order of elements in `custom` property to run the node properly:
	# They are per variable type:
	# + str: [pattern, default, extra] (all strings)
	# + num: [min, max, step, value] (all integers)
	# + bool: [negative, positive, default-state] (two strings and a boolean)
	# Also note that behavior regarding partially stored values (arrays with size other than expected,)
	# or invalid custom data (e.g. data not complying with the target `variable` type)
	# may depend on runtime implementation.
	"custom": [],
}

var _OPEN_NODE_ID
var _OPEN_NODE

var _PROJECT_VARIABLES_CACHE:Dictionary = {}

const FIELDS_WITH_EXPOSURE = ["prompt"]
const RESOURCE_NAME_EXPOSURE = Settings.RESOURCE_NAME_EXPOSURE

var This = self

onready var Prompt = get_node("./UserInput/PromptFor")
onready var VariablesOption = get_node("./UserInput/DirectToVariable")
onready var InputProperties = get_node("./UserInput/Customization")
onready var InputPropertiesByType = {
	#
	# CAUTION!
	# Order of elements in each `fields` property is crutial for each variable type to be stored and run properly.
	# They should represent the same order in which parameters are stored in the project file (i.e. node data,)
	# in other words the order console and runtimes depend on, to run the node properly.
	# Check out `DEFAULT_NODE_DATA` for more information.
	#
	"str": {
		"group": get_node("./UserInput/Customization/PanelContainer/String"),
		"fields": [
			# [node, parameter, default-value]
			[get_node("./UserInput/Customization/PanelContainer/String/Pattern/LineEdit"), "text", ""],
			[get_node("./UserInput/Customization/PanelContainer/String/Default/LineEdit"), "text", ""],
			[get_node("./UserInput/Customization/PanelContainer/String/Extra/LineEdit"), "text", ""],
		]
	},
	"num": {
		"group": get_node("./UserInput/Customization/PanelContainer/Number"),
		"fields": [
			[get_node("./UserInput/Customization/PanelContainer/Number/Min/SpinBox"), "value", -100],
			[get_node("./UserInput/Customization/PanelContainer/Number/Max/SpinBox"), "value", 100],
			[get_node("./UserInput/Customization/PanelContainer/Number/Step/SpinBox"), "value", 1],
			[get_node("./UserInput/Customization/PanelContainer/Number/Value/SpinBox"), "value", 0],
		]
	},
	"bool": {
		"group": get_node("./UserInput/Customization/PanelContainer/Boolean"),
		"fields": [
			[get_node("./UserInput/Customization/PanelContainer/Boolean/False/LineEdit"), "text", ""],
			[get_node("./UserInput/Customization/PanelContainer/Boolean/True/LineEdit"), "text", ""],
			[get_node("./UserInput/Customization/PanelContainer/Boolean/Default/CheckButton"), "pressed", true],
		]
	},
}

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	VariablesOption.connect("item_selected", self, "refresh_custom_properties_panel", [], CONNECT_DEFERRED)
	for num_prop in InputPropertiesByType["num"].fields:
		num_prop[0].connect("value_changed", self, "_cap_num_custom_prop_values", [], CONNECT_DEFERRED)
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

func referesh_variables_list(select_by_res_id:int = NO_VARIABLE_ID) -> void:
	VariablesOption.clear()
	_PROJECT_VARIABLES_CACHE = Main.Mind.clone_dataset_of("variables")
	if _PROJECT_VARIABLES_CACHE.size() > 0 :
		for variable_id in _PROJECT_VARIABLES_CACHE:
			var the_variable = _PROJECT_VARIABLES_CACHE[variable_id]
			VariablesOption.add_item(the_variable.name, variable_id)
		if select_by_res_id >= 0 :
			var variable_item_index = VariablesOption.get_item_index( select_by_res_id )
			VariablesOption.select(variable_item_index)
		else:
			if a_node_is_open() && _OPEN_NODE.data.has("variable") && ( _OPEN_NODE.data.variable in _PROJECT_VARIABLES_CACHE ):
				var variable_item_index_from_id = VariablesOption.get_item_index( _OPEN_NODE.data.variable )
				VariablesOption.select( variable_item_index_from_id )
	else:
		VariablesOption.add_item(NO_VARIABLE_TEXT, NO_VARIABLE_ID)
	pass

func refresh_custom_properties_panel(_x = null) -> void:
	var show_panel = false
	var variable_type = null
	var selected_var_id = VariablesOption.get_selected_id()
	if _PROJECT_VARIABLES_CACHE.has(selected_var_id):
		variable_type = _PROJECT_VARIABLES_CACHE[selected_var_id].type
	# ...
	for by_type in InputPropertiesByType:
		var shown = (by_type == variable_type)
		InputPropertiesByType[by_type].group.set_visible(shown)
		if shown: # any
			show_panel = true
		# Let's also reset value of the custom properties to defaults
		for field in InputPropertiesByType[by_type].fields:
			field[0].set(field[1], field[2])
	InputProperties.set_visible(show_panel)
	# ...
	if _OPEN_NODE.has("data") && _OPEN_NODE.data is Dictionary:
		if _OPEN_NODE.data.has("variable") && _OPEN_NODE.data.variable ==  selected_var_id:
			if _OPEN_NODE.data.has("custom") && _OPEN_NODE.data.custom is Array:
				var custom_properties_size = _OPEN_NODE.data.custom.size()
				for field_index in range(0, InputPropertiesByType[variable_type].fields.size()):
					var field = InputPropertiesByType[variable_type].fields[field_index]
					var custom_property = (
						_OPEN_NODE.data.custom[field_index]
						if field_index < custom_properties_size
						else field[2] # Default value
					)
					field[0].set(field[1], custom_property)
	pass

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	# ... then update parameters
	Prompt.set_deferred("text", "")
	var variable_id_to_select = -1
	if node.has("data") && node.data is Dictionary:
		if node.data.has("prompt") && (node.data.prompt is String) && node.data.prompt.length() > 0:
			Prompt.set_deferred("text", node.data.prompt)
		if node.data.has("variable") && (node.data.variable is int) && (node.data.variable >= 0) :
			variable_id_to_select = node.data.variable
	referesh_variables_list(variable_id_to_select)
	refresh_custom_properties_panel()
	pass

func _cap_num_custom_prop_values(_x = null) -> void:
	var min_value = InputPropertiesByType["num"].fields[0][0].get_value()
	var max_value = InputPropertiesByType["num"].fields[1][0].get_value()
	var step_value = InputPropertiesByType["num"].fields[2][0].get_value()
	# cap range (sorted)
	if max_value <= min_value:
		max_value = min_value + 1
		InputPropertiesByType["num"].fields[1][0].set_value(max_value)
	# and make sure step is positive non-zero and meaningful
	if step_value < 1 || step_value > abs(max_value - min_value):
		InputPropertiesByType["num"].fields[2][0].set_value(1)
	pass

func read_custom_properties():
	var selected_var_id = VariablesOption.get_selected_id()
	if _PROJECT_VARIABLES_CACHE.has(selected_var_id):
		var custom_properties = []
		var variable_type = _PROJECT_VARIABLES_CACHE[selected_var_id].type
		for field in InputPropertiesByType[variable_type].fields:
			var value = field[0].get(field[1])
			if variable_type == "num":
				value = int(value)
			custom_properties.push_back( value )
		return custom_properties
	return null

func find_exposed_resources(parameters:Dictionary, fields:Array, return_ids:bool = true) -> Array:
	var exposed_resources = []
	for resource_set in RESOURCE_NAME_EXPOSURE:
		var _CACHE = Main.Mind.clone_dataset_of(resource_set)
		var _CACHE_NAME_TO_ID = {}
		if _CACHE.size() > 0 : 
			for resource_id in _CACHE:
				_CACHE_NAME_TO_ID[ _CACHE[resource_id].name ] = resource_id
		# ...
		var _NAME_GROUP_ID = RESOURCE_NAME_EXPOSURE[resource_set].NAME_GROUP_ID
		var _EXPOSURE_PATTERN = RegEx.new()
		_EXPOSURE_PATTERN.compile( RESOURCE_NAME_EXPOSURE[resource_set].PATTERN )
		# ...
		for field in fields:
			if parameters[field] is String:
				for regex_match in _EXPOSURE_PATTERN.search_all( parameters[field] ):
					var possible_exposure = regex_match.get_string(_NAME_GROUP_ID)
					# print_debug("Possible Resource Exposure: ", possible_exposure)
					if _CACHE_NAME_TO_ID.has( possible_exposure ):
						var exposed = _CACHE_NAME_TO_ID[possible_exposure] if return_ids else possible_exposure
						if exposed_resources.has(exposed) == false:
							exposed_resources.append(exposed)
	return exposed_resources

func create_use_command(parameters:Dictionary) -> Dictionary:
	var use = { "drop": [], "refer": [] }
	var exposed_resources_by_uid = find_exposed_resources(parameters, FIELDS_WITH_EXPOSURE, true)
	# reference for the target variable ?
	# if there is any change in the target resources ...
	if parameters.variable != _OPEN_NODE.data.variable:
		if parameters.variable >= 0:
			use.refer.append(parameters.variable)
		if _OPEN_NODE.data.variable >= 0: # drop the old target reference ...
			# ... if it's not exposed in the prompt message too
			if exposed_resources_by_uid.has(_OPEN_NODE.data.variable) == false:
				use.drop.append(_OPEN_NODE.data.variable)
	# or for any exposed variable or character in the context ?
	# print_debug( "Exposed Resources in %s: " % _OPEN_NODE.name, exposed_resources_by_uid )
	# remove the reference if any resource is not exposed anymore
	if _OPEN_NODE.has("ref") && _OPEN_NODE.ref is Array:
		for currently_referred_resource in _OPEN_NODE.ref:
			if (
				exposed_resources_by_uid.has( currently_referred_resource ) == false &&
				currently_referred_resource != parameters.variable &&
				currently_referred_resource != _OPEN_NODE.data.variable
			):
				use.drop.append( currently_referred_resource )
	# and add new ones
	if exposed_resources_by_uid.size() > 0 :
		var may_exist = (_OPEN_NODE.has("ref") && _OPEN_NODE.ref is Array)
		for newly_exposed in exposed_resources_by_uid:
			if may_exist == false || _OPEN_NODE.ref.has( newly_exposed ) == false:
				use.refer.append( newly_exposed )
	return use

func _read_parameters() -> Dictionary:
	var parameters = {
		"prompt": Prompt.get_text(),
		"variable": (VariablesOption.get_selected_id() if (_PROJECT_VARIABLES_CACHE.size() > 0) else NO_VARIABLE_ID),
	}
	var custom_properties = read_custom_properties()
	if custom_properties != null:
		parameters.custom = custom_properties
	# does it rely on any other resource ?
	var _use = create_use_command(parameters)
	if _use.drop.size() > 0 || _use.refer.size() > 0 :
		parameters._use = _use
	return parameters

func _create_new(new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data

func _translate_internal_ref(data: Dictionary, translation: Dictionary) -> void:
	if translation.ids.has(data.variable):
		data.variable = translation.ids[data.variable]
	for resource_set in RESOURCE_NAME_EXPOSURE:
		var _NAME_GROUP_ID = RESOURCE_NAME_EXPOSURE[resource_set].NAME_GROUP_ID
		var _EXPOSURE_PATTERN = RegEx.new()
		_EXPOSURE_PATTERN.compile( RESOURCE_NAME_EXPOSURE[resource_set].PATTERN )
		for field in FIELDS_WITH_EXPOSURE:
			if data.has(field) && data[field] is String:
				var revised = {}
				for matched in _EXPOSURE_PATTERN.search_all( data[field] ):
					var exposure = [matched.get_string(), matched.get_start(), matched.get_end()] 
					var exposed = [matched.get_string(_NAME_GROUP_ID), matched.get_start(_NAME_GROUP_ID), matched.get_end(_NAME_GROUP_ID)]
					if translation.names.has( exposed[0] ):
						var cut = [exposed[1] - exposure[1], exposed[2] - exposure[1]]
						var new_name = translation.names[exposed[0]]
						revised[exposure[0]] = (exposure[0].substr(0, cut[0]) + new_name + exposure[0].substr(cut[1], -1))
				for exposure in revised:
					data[field] = data[field].replace(exposure, revised[exposure])
	pass
