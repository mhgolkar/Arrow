# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Content Node Type Inspector
extends ScrollContainer

onready var Main = get_tree().get_root().get_child(0)

const DEFAULT_NODE_DATA = {
	"title": "",
	"content": "",
	"brief": "",
	"clear": false
}

var _OPEN_NODE_ID
var _OPEN_NODE

const EXPOSED_VARIABLES_REGEX_PATTERN = "{([.]*[^{|}]*)}"
var EXPOSED_VARIABLES_REGEX = null

var _PROJECT_VARIABLES_CACHE:Dictionary
var _PROJECT_VARIABLES_CACHE_NAME_TO_ID:Dictionary

var This = self

onready var Title = get_node("./ScrollContainer/Content/Title")
onready var Brief = get_node("./ScrollContainer/Content/Brief")
onready var Content = get_node("./ScrollContainer/Content/Content")
onready var ClearPage = get_node("./ScrollContainer/Content/ClearPage")

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	# ... then update parameters, and set defaults if node doesn't provide the right data
	if node.has("data") && node.data is Dictionary:
		# Title
		var title
		if node.data.has("title"):
			title = String(node.data.title)
		Title.set_deferred("text", (title if (title is String && title.length() > 0) else DEFAULT_NODE_DATA.title))
		# Content
		if node.data.has("content") && node.data.content is String && node.data.content.length() > 0 :
			Content.set_deferred("text", node.data.content)
		else:
			Content.set_deferred("text", DEFAULT_NODE_DATA.content)
		# Brief
		if node.data.has("brief") && node.data.brief is String && node.data.brief.length() > 0 :
			Brief.set_deferred("text", node.data.brief)
		else:
			Brief.set_deferred("text", DEFAULT_NODE_DATA.brief)
		# Clear (print on a clear console)
		if node.data.has("clear") && node.data.clear is bool :
			ClearPage.set_deferred("pressed", node.data.clear)
		else:
			ClearPage.set_deferred("pressed", DEFAULT_NODE_DATA.clear)
	pass

func refresh_variables_cache() -> void:
	_PROJECT_VARIABLES_CACHE = Main.Mind.clone_dataset_of("variables")
	_PROJECT_VARIABLES_CACHE_NAME_TO_ID = {}
	if _PROJECT_VARIABLES_CACHE.size() > 0 : 
		for variable_id in _PROJECT_VARIABLES_CACHE:
			var the_variable = _PROJECT_VARIABLES_CACHE[variable_id]
			_PROJECT_VARIABLES_CACHE_NAME_TO_ID[the_variable.name] = variable_id
	pass

func find_exposed_variables(parameters:Dictionary, fields:Array, return_ids:bool = true) -> Array:
	refresh_variables_cache()
	if EXPOSED_VARIABLES_REGEX == null:
		EXPOSED_VARIABLES_REGEX = RegEx.new()
		EXPOSED_VARIABLES_REGEX.compile(EXPOSED_VARIABLES_REGEX_PATTERN)
	var exposed_variables = []
	for field in fields:
		for regex_match in EXPOSED_VARIABLES_REGEX.search_all( parameters[field] ):
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
	# reference for any parsed variables ?
	var exposed_variable_ids = find_exposed_variables(parameters, ["title", "content", "brief"], true)
	# print_debug( "Exposed Variables in %s: " % _OPEN_NODE.name, exposed_variable_ids )
	# remove the reference if any variable is not exposed anymore
	if _OPEN_NODE.has("ref") && _OPEN_NODE.ref is Array:
		for currently_referred_resource in _OPEN_NODE.ref:
			if exposed_variable_ids.has( currently_referred_resource ) == false:
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
		"title"  : Title.get_text(),
		"content": Content.get_text(),
		"brief"  : Brief.get_text(),
		"clear"  : ClearPage.is_pressed(),
	}
	# does it rely on any other resource ?
	var _use = create_use_command(parameters)
	if _use.drop.size() > 0 || _use.refer.size() > 0:
		parameters._use = _use
		# print_debug( "Changes will be: drop ", use.drop, " refer ", use.refer )
	return parameters

func _create_new(new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data
