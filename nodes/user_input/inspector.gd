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

var This = self

onready var Prompt = get_node("./UserInput/PromptFor")
onready var VariablesOption = get_node("./UserInput/DirectToVariable")

var _CACHED_VARIABLES_LIST:Dictionary = {}

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

func referesh_variables_list(select_by_res_id:int = NO_VARIABLE_ID) -> void:
	VariablesOption.clear()
	_CACHED_VARIABLES_LIST = Main.Mind.clone_dataset_of("variables")
	if _CACHED_VARIABLES_LIST.size() > 0 :
		for variable_id in _CACHED_VARIABLES_LIST:
			var the_variable = _CACHED_VARIABLES_LIST[variable_id]
			VariablesOption.add_item(the_variable.name, variable_id)
		if select_by_res_id >= 0 :
			var variable_item_index = VariablesOption.get_item_index( select_by_res_id )
			VariablesOption.select(variable_item_index)
		else:
			if a_node_is_open() && _OPEN_NODE.data.has("variable") && ( _OPEN_NODE.data.variable in _CACHED_VARIABLES_LIST ):
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

func _read_parameters() -> Dictionary:
	var parameters = {
		"prompt": Prompt.get_text(),
		"variable": (VariablesOption.get_selected_id() if (_CACHED_VARIABLES_LIST.size() > 0) else NO_VARIABLE_ID),
	}
	# if there is any change in the target resources ...
	if parameters.variable != _OPEN_NODE.data.variable:
		var _use = { "drop": [], "refer": [], "field": "variables"}
		if parameters.variable >= 0:
			_use.refer.append(parameters.variable)
		if _OPEN_NODE.data.variable >= 0:
			_use.drop.append(_OPEN_NODE.data.variable)
		# ... attach a `_use` command 
		if _use.drop.size() > 0 || _use.refer.size() > 0 :
			parameters._use = _use
	return parameters

func _create_new(new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data

