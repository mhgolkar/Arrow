# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Interaction Node Type Inspector
extends ScrollContainer

onready var Main = get_tree().get_root().get_child(0)

var ListHelpers = Helpers.ListHelpers

const DEFAULT_NODE_DATA = {
	"actions": ["Go ahead!"]
}

var _OPEN_NODE_ID
var _OPEN_NODE

const RESOURCE_NAME_EXPOSURE = Settings.RESOURCE_NAME_EXPOSURE

var This = self

onready var Action = get_node("./Interaction/Action/Edit")
onready var Tools = get_node("./Interaction/Action/Tools")
onready var ToolsPopup = Tools.get_popup()
onready var ActionsList = get_node("./Interaction/Actions/List")

const TOOLS_MENU_BUTTON_POPUP = { # <id>:int { label:string, action:string<function-ident-to-be-called> }
	0: { "label": "Append New Action", "action": "append_new_action" },
	1: null, # separator
	2: { "label": "Extract Selected Action", "action": "extract_selected_action" },
	3: { "label": "Replace Selected Action", "action": "replace_selected_action" },
	4: { "label": "Remove Selected Action(s)", "action": "remove_selected_actions" },
	5: null,
	6: { "label": "Sort Actions (Alphabetical)", "action": "sort_items_alphabetical" },
	7: { "label": "Move Selected Top", "action": "move_selected_top" },
}
var _TOOLS_ITEM_INDEX_BY_ACTION = {}

func _ready() -> void:
	load_tools_menu()
	register_connections()
	pass

func register_connections() -> void:
	ToolsPopup.connect("id_pressed", self, "_on_tools_popup_menu_id_pressed", [], CONNECT_DEFERRED)
	Action.connect("text_changed", self, "_toggle_available_tools_smartly", [], CONNECT_DEFERRED)
	Action.connect("text_entered", self, "append_new_action", [], CONNECT_DEFERRED)
	ActionsList.connect("multi_selected", self, "_toggle_available_tools_smartly", [], CONNECT_DEFERRED)
	ActionsList.connect("item_rmb_selected", self, "_on_right_click_item_selection", [], CONNECT_DEFERRED)
	pass
	
func load_tools_menu() -> void:
	ToolsPopup.clear()
	for item_id in TOOLS_MENU_BUTTON_POPUP:
		var item = TOOLS_MENU_BUTTON_POPUP[item_id]
		if item == null: # separator
			ToolsPopup.add_separator()
		else:
			ToolsPopup.add_item(item.label, item_id)
			_TOOLS_ITEM_INDEX_BY_ACTION[item.action] = ToolsPopup.get_item_index(item_id)
	self.call_deferred("_toggle_available_tools_smartly")
	pass

func _on_tools_popup_menu_id_pressed(pressed_item_id:int) -> void:
	var the_action = TOOLS_MENU_BUTTON_POPUP[pressed_item_id].action
	if the_action is String && the_action.length() > 0 :
		self.call_deferred(the_action)
	pass

# Note: it needs `x,y,z` nulls, because it's connected to different signals with different number of passed arguments
func _toggle_available_tools_smartly(x=null, y=null, z=null) -> void:
	var new_string_is_blank = ( Action.get_text().length() == 0 )
	var selection_size = ActionsList.get_selected_items().size()
	var all_items_count = ActionsList.get_item_count()
	ToolsPopup.set_item_disabled( _TOOLS_ITEM_INDEX_BY_ACTION["append_new_action"], new_string_is_blank )
	ToolsPopup.set_item_disabled( _TOOLS_ITEM_INDEX_BY_ACTION["extract_selected_action"], (selection_size != 1 || all_items_count == 1 ) )
	ToolsPopup.set_item_disabled( _TOOLS_ITEM_INDEX_BY_ACTION["replace_selected_action"], (selection_size != 1 || new_string_is_blank) )
	ToolsPopup.set_item_disabled( _TOOLS_ITEM_INDEX_BY_ACTION["remove_selected_actions"], ( selection_size == 0 || selection_size >= all_items_count || all_items_count == 1 ) )
	pass

func move_item(to_final_idx:int = 0, from:int = -1) -> void:
	var current_list_size = ActionsList.get_item_count()
	if current_list_size > 1 :
		if to_final_idx < current_list_size && from < current_list_size:
			if from < 0 : # if no item is selected to be moved
				from = (current_list_size - 1) # move the last one by default
			ActionsList.move_item(from, to_final_idx)
	pass

func move_selected_top(selected_actions_idxs:Array = []) -> void:
	if ActionsList.get_item_count() > 1 :
		if selected_actions_idxs.size() == 0:
			selected_actions_idxs = ActionsList.get_selected_items()
		if selected_actions_idxs.size() >= 1:
			# we shall move from the first element in order, so they keep staying in order
			selected_actions_idxs.sort()
			while selected_actions_idxs.size() > 0 :
				var the_first_item = selected_actions_idxs.pop_front()
				move_item(0, the_first_item)
	pass

func sort_items_alphabetical() -> void:
	ActionsList.sort_items_by_text()
	pass

func append_new_action(text:String = "") -> void:
	var new_action = ( text if text.length() > 0 else Action.get("text") )
	ActionsList.add_item( new_action )
	Action.clear()
	# select the last/newly created item
	ActionsList.select(( ActionsList.get_item_count() - 1) , true) 
	# and make sure it's visible
	ActionsList.ensure_current_is_visible()
	pass

func extract_selected_action(selected_actions_idxs:Array = []) -> void:
	if selected_actions_idxs.size() == 0:
		selected_actions_idxs = ActionsList.get_selected_items()
	if selected_actions_idxs.size() >= 1:
		var item_idx_to_extract = selected_actions_idxs[0]
		var item_text = ActionsList.get_item_text(item_idx_to_extract)
		Action.set_text(item_text)
		ActionsList.remove_item(item_idx_to_extract)
	# refresh tools manually, because set_text won't fire input event
	_toggle_available_tools_smartly()
	pass
	
func replace_selected_action(selected_actions_idxs:Array = []) -> void:
	if selected_actions_idxs.size() == 0:
		selected_actions_idxs = ActionsList.get_selected_items()
	if selected_actions_idxs.size() >= 1:
		var to_idx_for_replacement = selected_actions_idxs[0]
		remove_selected_actions(selected_actions_idxs)
		var new_action = Action.get("text")
		ActionsList.add_item( new_action )
		Action.clear()
		move_item(to_idx_for_replacement) # by default moves the last item
	pass

func remove_selected_actions(selected_actions_idxs:Array = []) -> void:
	if selected_actions_idxs.size() == 0:
		selected_actions_idxs = ActionsList.get_selected_items()
	# we shall remove items from the last one because 
	# removal of a preceding item will change indices for others and you may remove innocent items!
	if selected_actions_idxs.size() >= 1:
		selected_actions_idxs.sort()
		while selected_actions_idxs.size() > 0 :
			var the_last_item = selected_actions_idxs.pop_back()
			ActionsList.remove_item(the_last_item)
	pass

func _on_right_click_item_selection(item_idx:int, _click_position:Vector2) -> void:
	var all_items_count = ActionsList.get_item_count()
	if all_items_count > 1 :
		extract_selected_action([item_idx])
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

func update_actions_list(actions:Array = [], clear:bool = false) -> void:
	if clear:
		ActionsList.clear()
	for action in actions:
		if action is String && action.length() > 0 :
			ActionsList.add_item(action)
	pass

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	Action.clear()
	if node.has("data") && node.data is Dictionary:
		if node.data.has("actions") && node.data.actions is Array:
			update_actions_list(node.data.actions, true)
		else:
			update_actions_list(DEFAULT_NODE_DATA.actions, true)
	pass

func find_exposed_resources(actions:Array, return_ids:bool = true) -> Array:
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
		for action in actions:
			if action is String:
				for regex_match in _EXPOSURE_PATTERN.search_all( action ):
					var possible_exposure = regex_match.get_string(_NAME_GROUP_ID)
					# print_debug("Possible Resource Exposure: ", possible_exposure)
					if _CACHE_NAME_TO_ID.has( possible_exposure ):
						var exposed = _CACHE_NAME_TO_ID[possible_exposure] if return_ids else possible_exposure
						if exposed_resources.has(exposed) == false:
							exposed_resources.append(exposed)
	return exposed_resources

func create_use_command(parameters:Dictionary) -> Dictionary:
	var use = { "drop": [], "refer": [] }
	# reference for any exposed variable or character ?
	var exposed_resources_by_uid = find_exposed_resources(parameters.actions, true)
	# print_debug( "Exposed Variables in %s: " % _OPEN_NODE.name, exposed_resources_by_uid )
	# remove the reference if any resource is not exposed anymore
	if _OPEN_NODE.has("ref") && _OPEN_NODE.ref is Array:
		for currently_referred_resource in _OPEN_NODE.ref:
			if exposed_resources_by_uid.has( currently_referred_resource ) == false:
				use.drop.append( currently_referred_resource )
	# and add new ones
	if exposed_resources_by_uid.size() > 0 :
		var may_exist = (_OPEN_NODE.has("ref") && _OPEN_NODE.ref is Array)
		for newly_exposed in exposed_resources_by_uid:
			if may_exist == false || _OPEN_NODE.ref.has( newly_exposed ) == false:
				use.refer.append( newly_exposed )
	return use

func cut_off_dropped_connections() -> void:
	if a_node_is_open() && _OPEN_NODE.data.has("actions") && ( _OPEN_NODE.data.actions is Array ):
		if _OPEN_NODE.data.actions.size() > ActionsList.get_item_count():
			Main.Grid.cut_off_connections(_OPEN_NODE_ID, "out", ActionsList.get_item_count() - 1)
	pass
	

func _read_parameters() -> Dictionary:
	cut_off_dropped_connections()
	var parameters = {
		"actions": ListHelpers.get_item_list_as_text_array(ActionsList),
	}
	# does it rely on any other resource ?
	var _use = create_use_command(parameters)
	if _use.drop.size() > 0 || _use.refer.size() > 0 :
		parameters._use = _use
	return parameters

func _create_new(new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data

func _translate_internal_ref(data: Dictionary, translation: Dictionary) -> void:
	for resource_set in RESOURCE_NAME_EXPOSURE:
		var _NAME_GROUP_ID = RESOURCE_NAME_EXPOSURE[resource_set].NAME_GROUP_ID
		var _EXPOSURE_PATTERN = RegEx.new()
		_EXPOSURE_PATTERN.compile( RESOURCE_NAME_EXPOSURE[resource_set].PATTERN )
		for idx in range(0, data.actions.size()):
			var revised = {}
			for matched in _EXPOSURE_PATTERN.search_all( data.actions[idx] ):
				var exposure = [matched.get_string(), matched.get_start(), matched.get_end()] 
				var exposed = [matched.get_string(_NAME_GROUP_ID), matched.get_start(_NAME_GROUP_ID), matched.get_end(_NAME_GROUP_ID)]
				if translation.names.has( exposed[0] ):
					var cut = [exposed[1] - exposure[1], exposed[2] - exposure[1]]
					var new_name = translation.names[exposed[0]]
					revised[exposure[0]] = (exposure[0].substr(0, cut[0]) + new_name + exposure[0].substr(cut[1], -1))
			for exposure in revised:
				data.actions[idx] = data.actions[idx].replace(exposure, revised[exposure])
	pass
