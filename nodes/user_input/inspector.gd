# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# User_Input Node Type Inspector
extends ScrollContainer

onready var Main = get_tree().get_root().get_child(0)

const NO_VARIABLE_TEXT = "No Variable Available"
const NO_VARIABLE_ID = -1

const DEFAULT_NODE_DATA = {
	"variable": NO_VARIABLE_ID,
	"prompt": ""
}

var _OPEN_NODE_ID
var _OPEN_NODE

const EXPOSED_VARIABLES_REGEX_PATTERN = "{([.]*[^{|}]*)}"
var EXPOSED_VARIABLES_REGEX = null

var _PROJECT_VARIABLES_CACHE:Dictionary = {}
var _PROJECT_VARIABLES_CACHE_NAME_TO_ID:Dictionary

var This = self

onready var Prompt = get_node("./UserInput/PromptFor")
onready var VariablesOption = get_node("./UserInput/DirectToVariable")

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func a_node_is_open() -> bool :
	if (
		(_OPEN_NODE_ID is int) && (_OPEN_NODE_ID >= 0) &&
		(_OPEN_NODE is Dictionary) &&
		_OPEN_NODE.has("data") && (_OPEN_NODE.data is Dictionary)
	):
		return true
	else:
		return false

func refresh_variables_cache() -> void:
	_PROJECT_VARIABLES_CACHE = Main.Mind.clone_dataset_of("variables")
	_PROJECT_VARIABLES_CACHE_NAME_TO_ID = {}
	if _PROJECT_VARIABLES_CACHE.size() > 0 : 
		for variable_id in _PROJECT_VARIABLES_CACHE:
			var the_variable = _PROJECT_VARIABLES_CACHE[variable_id]
			_PROJECT_VARIABLES_CACHE_NAME_TO_ID[the_variable.name] = variable_id
	pass

func referesh_variables_list(select_by_res_id:int = NO_VARIABLE_ID) -> void:
	VariablesOption.clear()
	refresh_variables_cache()
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
	pass

func find_exposed_variables(prompt:String, return_ids:bool = true) -> Array:
	refresh_variables_cache()
	if EXPOSED_VARIABLES_REGEX == null:
		EXPOSED_VARIABLES_REGEX = RegEx.new()
		EXPOSED_VARIABLES_REGEX.compile(EXPOSED_VARIABLES_REGEX_PATTERN)
	var exposed_variables = []
	for regex_match in EXPOSED_VARIABLES_REGEX.search_all( prompt ):
		var possibly_exposed_variable = regex_match.get_string(1)
		# print_debug("Possible Variable Exposure: ", possibly_exposed_variable)
		if _PROJECT_VARIABLES_CACHE_NAME_TO_ID.has( possibly_exposed_variable ):
			exposed_variables.append(
				_PROJECT_VARIABLES_CACHE_NAME_TO_ID[possibly_exposed_variable]
				if return_ids
				else possibly_exposed_variable
			)
	return exposed_variables

func create_use_command(parameters:Dictionary) -> Dictionary:
	var use = { "drop": [], "refer": [], "field": "variables" }
	var exposed_variable_ids = find_exposed_variables(parameters.prompt, true)
	# reference for the target variable ?
	# if there is any change in the target resources ...
	if parameters.variable != _OPEN_NODE.data.variable:
		if parameters.variable >= 0:
			use.refer.append(parameters.variable)
		if _OPEN_NODE.data.variable >= 0: # drop the old target reference ...
			# ... if it's not exposed in the prompt message too
			if exposed_variable_ids.has(_OPEN_NODE.data.variable) == false:
				use.drop.append(_OPEN_NODE.data.variable)
	# or for any parsed variables ?
	# print_debug( "Exposed Variables in %s: " % _OPEN_NODE.name, exposed_variable_ids )
	# remove the reference if any variable is not exposed anymore
	if _OPEN_NODE.has("ref") && _OPEN_NODE.ref is Array:
		for currently_referred_resource in _OPEN_NODE.ref:
			if (
				exposed_variable_ids.has( currently_referred_resource ) == false &&
				currently_referred_resource != parameters.variable &&
				currently_referred_resource != _OPEN_NODE.data.variable
			):
				use.drop.append( currently_referred_resource )
	# and add new ones
	if exposed_variable_ids.size() > 0 :
		var may_exist = (_OPEN_NODE.has("ref") && _OPEN_NODE.ref is Array)
		for newly_exposed in exposed_variable_ids:
			if may_exist == false || _OPEN_NODE.ref.has( newly_exposed ) == false:
				use.refer.append( newly_exposed )
	return use

func _read_parameters() -> Dictionary:
	var parameters = {
		"prompt": Prompt.get_text(),
		"variable": (VariablesOption.get_selected_id() if (_PROJECT_VARIABLES_CACHE.size() > 0) else NO_VARIABLE_ID),
	}
	# does it rely on any other resource ?
	var _use = create_use_command(parameters)
	if _use.drop.size() > 0 || _use.refer.size() > 0 :
		parameters._use = _use
	return parameters

func _create_new(new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data
