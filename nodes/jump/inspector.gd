# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Jump Sub-Inspector
extends Control

@onready var Main = get_tree().get_root().get_child(0)

const DEFAULT_NODE_DATA = {
	"target": -1, # node resource-id to get jumped into 
	"reason": ""
}

var _OPEN_NODE_ID
var _OPEN_NODE

var This = self

@onready var Destination = $Destination
@onready var Reason = $Reason
@onready var SuggestionBox = $Suggestion
@onready var SuggestionList = $Suggestion/List

# the function `query_nodes_by_name` uses `matchn`,
# so we add asterisks (*) to make auto-suggestion query more user-friendly
const NODE_NAME_QUERY_REFACTORING = "*%s*"
const MINIMUM_QUERY_STRING_LENGTH_TO_REFRESH_SUGGESTIONS = 3 # 2 asterisks (automatically added) + 1 min characters
const DO_NOT_SHOW_EXACT_MATCH_AS_SUGGESTION = true

const SUGGESTION_ITEM_TEMPLATE = (
	"{name} - {capitalized_type}" if Settings.FORCE_UNIQUE_NAMES_FOR_NODES else "{name} - {capitalized_type} ({id})"
)

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	Destination.text_changed.connect(self._on_destination_text_input, CONNECT_DEFERRED)
	SuggestionList.item_activated.connect(self._on_suggestion_item_activated, CONNECT_DEFERRED)
	pass

var _suggestion_is_visible:bool = true

func set_suggestion_view(visibility:bool = false) -> void:
	if _suggestion_is_visible != visibility:
		SuggestionBox.set("visible", visibility)
		_suggestion_is_visible = visibility
	pass

var _SUGGESTION_NODES = {}
var _SUGGESTION_NODE_ID_LIST_BY_NAME = {}
# because item texts may differ from item names and the list may be sorted so,
# ... to get the node-uid of the selected node we can't use item-index, therefore we remap:
var _SUGGESTION_NODE_ID_LIST_BY_ITEM_TEXT = {}
var _ACTIVATED_SUGGESTION_NODE_ID = null

func clear_suggestions() -> void:
	SuggestionList.clear()
	_SUGGESTION_NODES.clear()
	_SUGGESTION_NODE_ID_LIST_BY_NAME.clear()
	_SUGGESTION_NODE_ID_LIST_BY_ITEM_TEXT.clear()
	_ACTIVATED_SUGGESTION_NODE_ID = null
	pass

func is_valid_query_string(query:String) -> bool:
	var quey_length = query.length()
	if quey_length < MINIMUM_QUERY_STRING_LENGTH_TO_REFRESH_SUGGESTIONS:
		return false
	elif query == ( "*".repeat(quey_length) ):
		return false
	return true

func refresh_suggestions(query:String = "") -> void:
	clear_suggestions()
	if is_valid_query_string(query):
		_SUGGESTION_NODES = Main.Mind.query_nodes_by_name(query, -2, true) # -2 means all the nodes in all the scenes
		var suggestion_item_idx = 0
		for node_id in _SUGGESTION_NODES:
			var the_node = _SUGGESTION_NODES[node_id]
			var item_text = SUGGESTION_ITEM_TEMPLATE.format({
					"id": node_id,
					"name": the_node.name,
					"capitalized_type": the_node.type.capitalize()
				})
			_SUGGESTION_NODE_ID_LIST_BY_NAME[the_node.name] = node_id
			_SUGGESTION_NODE_ID_LIST_BY_ITEM_TEXT[item_text] = node_id
			SuggestionList.add_item(item_text)
			SuggestionList.set_item_metadata(suggestion_item_idx, node_id)
			suggestion_item_idx += 1
		var similar_nodes_count = _SUGGESTION_NODES.size()
		# show suggestions by default
		var show_suggestions = true
		if similar_nodes_count > 0:
			if similar_nodes_count == 1:
				var only_one_id = _SUGGESTION_NODES.keys()[0]
				var the_one_found =  _SUGGESTION_NODES[ only_one_id ]
				if DO_NOT_SHOW_EXACT_MATCH_AS_SUGGESTION && the_one_found.name == Destination.text:
					show_suggestions = false
					_ACTIVATED_SUGGESTION_NODE_ID = only_one_id
		else: # ... or there is no suggestion
			show_suggestions = false
		SuggestionList.sort_items_by_text()
		set_suggestion_view( show_suggestions )
	else:
		set_suggestion_view(false)
	pass

func _on_destination_text_input(_new_text:String) -> void:
	var full_destination_text = (NODE_NAME_QUERY_REFACTORING % Destination.text)
	refresh_suggestions(full_destination_text)
	pass

func _on_suggestion_item_activated(item_idx:int) -> void:
	var selected_item_metadata_id = SuggestionList.get_item_metadata(item_idx)
	var selected_item_text = SuggestionList.get_item_text(item_idx)
	var selected_node_id_from_text = _SUGGESTION_NODE_ID_LIST_BY_ITEM_TEXT[selected_item_text]
	var selected_node = _SUGGESTION_NODES[ selected_node_id_from_text ]
	_ACTIVATED_SUGGESTION_NODE_ID = selected_item_metadata_id
	Destination.set_text( selected_node.name )
	set_suggestion_view(false)
	# ...
	if selected_item_metadata_id != selected_node_id_from_text:
		printerr(
			"jump selected node-id expected to be identical; ",
			selected_item_text, " : ", selected_item_metadata_id, " != ", selected_node_id_from_text
		)
	pass

func _update_parameters(node_id:int, node:Dictionary, do_cache:bool = true) -> void:
	# first cache the node (if it's not a history point being restored)
	if do_cache:
		_OPEN_NODE_ID = node_id
		_OPEN_NODE = node
	# ... then update parameters
	Destination.clear()
	Reason.clear()
	if node.has("data") && node.data is Dictionary:
		if node.data.has("target") && (node.data.target is int) && (node.data.target >= 0):
			var target_node = Main.Mind.lookup_resource(node.data.target, "nodes")
			if (target_node is Dictionary) && target_node.has("name") && (target_node.name is String):
				Destination.set_text(target_node.name)
		if node.data.has("reason") && (node.data.reason is String) && (node.data.reason.length() > 0):
			Reason.set_text(node.data.reason)
	set_suggestion_view(false)
	pass

func warn_jump_loop(extra_message:String = "Parameter reset!") -> void:
	printerr("Warn! You shall not make loop jumps. They will crash your project. ", extra_message)
	pass

func _read_parameters() -> Dictionary:
	var parameters = {
		"target": -1, # will be updated down there
		"reason": Reason.get_text()
	}
	# last queries are in _SUGGESTION_NODE_ID_LIST_BY_NAME
	# if the node name is not in the list, it means there has been no such node or no query, so...
	var target_name = Destination.get_text()
	if target_name.length() > 0 && _SUGGESTION_NODE_ID_LIST_BY_NAME.has(target_name):
		# there is a valid node name
		# get node_id for it
		var new_target_id = _ACTIVATED_SUGGESTION_NODE_ID # it's either cached from suggestion list
		if new_target_id == null: # or
			# typed by the user directly (no selection from suggestion list)
			new_target_id = _SUGGESTION_NODE_ID_LIST_BY_NAME[target_name]
		# (if cached, node-id is expected to related to the same name)
		if _SUGGESTION_NODES[new_target_id].name != target_name:
			printerr(
				"unexpected behavior! jump target node id from name differs from cache: ",
				target_name, " - ", _SUGGESTION_NODE_ID_LIST_BY_NAME[target_name], " -x-> ", new_target_id
			)
		# and to avoid loopers check it for ...
		if new_target_id != _OPEN_NODE_ID: # no jump to the jump itself
			# and no jump to the jump that jumps back!
			var the_target_node = _SUGGESTION_NODES[new_target_id]
			if (the_target_node.type != _OPEN_NODE.type) || (the_target_node.data.target != _OPEN_NODE_ID):
				parameters.target = new_target_id # then set it
		# or reset the jump's target on any possible loop
			else: 
				parameters.target = -1
				warn_jump_loop()
		else: 
			parameters.target = -1
			warn_jump_loop()
	else:
		# ... otherwise leave it as it was
		if _OPEN_NODE.data.target is int:
			parameters.target = _OPEN_NODE.data.target
		else:
			parameters.target = -1
	# now attach `_use` command in case
	if parameters.target != _OPEN_NODE.data.target:
		var _use = { "drop": [], "refer": [], "field": "nodes"}
		if parameters.target >= 0:
			_use.refer.append(parameters.target)
		if _OPEN_NODE.data.target >= 0:
			_use.drop.append(_OPEN_NODE.data.target)
		if _use.drop.size() > 0 || _use.refer.size() > 0 :
			parameters._use = _use
	return parameters

func _create_new(_new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data

func _translate_internal_ref(data: Dictionary, translation: Dictionary) -> void:
	if translation.ids.has(data.target):
		data.target = translation.ids[data.target]
	pass
