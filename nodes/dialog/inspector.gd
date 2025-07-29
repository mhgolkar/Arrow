# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Dialog Sub-Inspector
extends Control

@onready var Main = get_tree().get_root().get_child(0)

var ListHelpers = Helpers.ListHelpers

const ANONYMOUS_CHARACTER = DialogSharedClass.ANONYMOUS_CHARACTER
const DEFAULT_NODE_DATA = DialogSharedClass.DEFAULT_NODE_DATA

const SAVE_UNOPTIMIZED = DialogSharedClass.SAVE_UNOPTIMIZED

const ALLOW_ANONYMOUS_DIALOGS = true
const ANONYMOUS_UID_CONTROL_VALUE = -254

var _OPEN_NODE_ID
var _OPEN_NODE

var _PROJECT_CHARACTERS_CACHE = {}

const RESOURCE_NAME_EXPOSURE = Settings.RESOURCE_NAME_EXPOSURE

var This = self

@onready var CharactersInspector = Main.Mind.Inspector.Tab.Characters

@onready var Character = $Selector/List
@onready var GlobalFilters = $Selector/Filtered
@onready var Line = $Line/Edit
@onready var Tools = $Line/Tools
@onready var ToolsPopup = Tools.get_popup()
@onready var LinesList = $Lines
@onready var Playable = $Playable

const TOOLS_MENU_BUTTON_POPUP = { # <id>:int { label:string, action:string<function-ident-to-be-called> }
	0: { "label": "DIALOG_INSPECTOR_MENU_APPEND_NEW_LINE", "action": "append_new_line" },
	1: null, # separator
	2: { "label": "DIALOG_INSPECTOR_MENU_EXTRACT_SELECTED", "action": "extract_selected_line" },
	3: { "label": "DIALOG_INSPECTOR_MENU_REPLACE_SELECTED", "action": "replace_selected_line" },
	4: { "label": "DIALOG_INSPECTOR_MENU_REMOVE_SELECTED", "action": "remove_selected_lines" },
	5: null,
	6: { "label": "DIALOG_INSPECTOR_MENU_SORT_LINES_AZ", "action": "sort_items_alphabetical" },
	7: { "label": "DIALOG_INSPECTOR_MENU_MOVE_SELECTED_TOP", "action": "move_selected_top" },
	8: { "label": "DIALOG_INSPECTOR_MENU_MOVE_SELECTED_END", "action": "move_selected_end" },
	9: null,
	10: { "label": "DIALOG_INSPECTOR_MENU_MOVE_SELECTED_UP", "action": "move_selected_up" },
	11: { "label": "DIALOG_INSPECTOR_MENU_MOVE_SELECTED_DOWN", "action": "move_selected_down" },
}
var _TOOLS_ITEM_INDEX_BY_ACTION = {}

func _ready() -> void:
	load_tools_menu()
	register_connections()
	pass

func register_connections() -> void:
	GlobalFilters.pressed.connect(self.refresh_character_list, CONNECT_DEFERRED)
	ToolsPopup.id_pressed.connect(self._on_tools_popup_menu_id_pressed, CONNECT_DEFERRED)
	Line.text_changed.connect(self._toggle_available_tools_smartly, CONNECT_DEFERRED)
	Line.text_submitted.connect(self.append_new_line, CONNECT_DEFERRED)
	LinesList.multi_selected.connect(self._toggle_available_tools_smartly, CONNECT_DEFERRED)
	LinesList.item_activated.connect(self._on_double_click_item_activated, CONNECT_DEFERRED)
	LinesList.item_clicked.connect(self._on_item_clicked, CONNECT_DEFERRED)
	LinesList.gui_input.connect(self._on_list_gui_input, CONNECT_DEFERRED)
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
func _toggle_available_tools_smartly(_x=null, _y=null, _z=null) -> void:
	var new_string_is_blank = ( Line.get_text().length() == 0 )
	var selection_size = LinesList.get_selected_items().size()
	var all_items_count = LinesList.get_item_count()
	ToolsPopup.set_item_disabled( _TOOLS_ITEM_INDEX_BY_ACTION["append_new_line"], new_string_is_blank )
	ToolsPopup.set_item_disabled( _TOOLS_ITEM_INDEX_BY_ACTION["extract_selected_line"], (selection_size != 1 || all_items_count == 1 ) )
	ToolsPopup.set_item_disabled( _TOOLS_ITEM_INDEX_BY_ACTION["replace_selected_line"], (selection_size != 1 || new_string_is_blank) )
	ToolsPopup.set_item_disabled( _TOOLS_ITEM_INDEX_BY_ACTION["remove_selected_lines"], ( selection_size == 0 || selection_size >= all_items_count || all_items_count == 1 ) )
	pass

func move_item(to_final_idx:int = 0, from:int = -1) -> void:
	var current_list_size = LinesList.get_item_count()
	if current_list_size > 1 :
		if to_final_idx < current_list_size && from < current_list_size:
			if from < 0 : # if no item is selected to be moved
				from = (current_list_size - 1) # move the last one by default
			LinesList.move_item(from, to_final_idx)
	pass

func move_selected_top(selected_lines_indices:Array = []) -> void:
	if LinesList.get_item_count() > 1 :
		if selected_lines_indices.size() == 0:
			selected_lines_indices = LinesList.get_selected_items()
		if selected_lines_indices.size() >= 1:
			selected_lines_indices.sort()
			while selected_lines_indices.size() > 0 :
				var the_first_item = selected_lines_indices.pop_front()
				move_item(0, the_first_item)
	pass

func move_selected_end(selected_lines_indices:Array = []) -> void:
	if LinesList.get_item_count() > 1 :
		if selected_lines_indices.size() == 0:
			selected_lines_indices = LinesList.get_selected_items()
		if selected_lines_indices.size() >= 1:
			selected_lines_indices.sort()
			var end = LinesList.get_item_count() - 1;
			while selected_lines_indices.size() > 0 :
				var the_first_item = selected_lines_indices.pop_front()
				move_item(end, the_first_item)
	pass

func move_selected_up(selected_lines_indices:Array = []) -> void:
	if LinesList.get_item_count() > 1 :
		if selected_lines_indices.size() == 0:
			selected_lines_indices = LinesList.get_selected_items()
		if selected_lines_indices.size() >= 1:
			selected_lines_indices.sort()
			while selected_lines_indices.size() > 0 :
				var nth = selected_lines_indices.pop_front()
				LinesList.move_item(nth, max(0, nth - 1))
	pass

func move_selected_down(selected_lines_indices:Array = []) -> void:
	if LinesList.get_item_count() > 1 :
		if selected_lines_indices.size() == 0:
			selected_lines_indices = LinesList.get_selected_items()
		if selected_lines_indices.size() >= 1:
			selected_lines_indices.sort()
			var end = LinesList.get_item_count() - 1;
			while selected_lines_indices.size() > 0 :
				var nth = selected_lines_indices.pop_back()
				LinesList.move_item(nth, min(end, nth + 1))
	pass

func sort_items_alphabetical() -> void:
	LinesList.sort_items_by_text()
	pass

func append_new_line(text:String = "") -> void:
	var new_line = ( text if text.length() > 0 else Line.get("text") )
	if new_line.length() > 0: # (blank dialog lines are not allowed)
		LinesList.add_item( new_line )
		Line.clear()
		# select the last/newly created item
		LinesList.select(( LinesList.get_item_count() - 1) , true) 
		# and make sure it's visible
		LinesList.ensure_current_is_visible()
	pass

func extract_selected_line(selected_lines_indices:Array = []) -> void:
	if selected_lines_indices.size() == 0:
		selected_lines_indices = LinesList.get_selected_items()
	if selected_lines_indices.size() >= 1:
		var item_idx_to_extract = selected_lines_indices[0]
		var item_text = LinesList.get_item_text(item_idx_to_extract)
		Line.set_text(item_text)
		LinesList.remove_item(item_idx_to_extract)
	# refresh tools manually, because set_text won't fire input event
	_toggle_available_tools_smartly()
	pass
	
func replace_selected_line(selected_lines_indices:Array = []) -> void:
	if selected_lines_indices.size() == 0:
		selected_lines_indices = LinesList.get_selected_items()
	if selected_lines_indices.size() >= 1:
		var to_idx_for_replacement = selected_lines_indices[0]
		remove_selected_lines(selected_lines_indices)
		var new_line = Line.get("text")
		LinesList.add_item( new_line )
		Line.clear()
		move_item(to_idx_for_replacement) # by default moves the last item
	pass

func remove_selected_lines(selected_lines_indices:Array = []) -> void:
	if selected_lines_indices.size() == 0:
		selected_lines_indices = LinesList.get_selected_items()
	# we shall remove items from the last one because 
	# removal of a preceding item will change indices for others and you may remove innocent items!
	if selected_lines_indices.size() >= 1:
		selected_lines_indices.sort()
		while selected_lines_indices.size() > 0 :
			var the_last_item = selected_lines_indices.pop_back()
			LinesList.remove_item(the_last_item)
	pass

func _on_item_clicked(item_idx:int, _click_position:Vector2, mouse_button_index:int) -> void:
	match mouse_button_index:
		# Extract on right-click
		MOUSE_BUTTON_RIGHT:
			var all_items_count = LinesList.get_item_count()
			if all_items_count > 1 :
				extract_selected_line([item_idx])
	pass

func _on_double_click_item_activated(item_idx:int) -> void:
	var item_text = LinesList.get_item_text(item_idx)
	Line.set_text(item_text)
	_toggle_available_tools_smartly()
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

func find_listed_character_index(by_id: int) -> int:
	for idx in range(0, Character.get_item_count()):
		if Character.get_item_metadata(idx) == by_id:
			return idx
	return -1

func refresh_character_list(select_by_res_id:int = -1) -> void:
	Character.clear()
	var item_index := 0
	if ALLOW_ANONYMOUS_DIALOGS == true:
		# (Our conventional `-1` conflicts with the default behavior of `add_item` method, so we use a `..._CONTROL_VALUE`)
		Character.add_item(ANONYMOUS_CHARACTER.name, ANONYMOUS_UID_CONTROL_VALUE)
		Character.set_item_metadata(item_index, ANONYMOUS_UID_CONTROL_VALUE)
		item_index += 1
	_PROJECT_CHARACTERS_CACHE = Main.Mind.clone_dataset_of("characters")
	var already = null
	if a_node_is_open() && _OPEN_NODE.data.has("character") && _OPEN_NODE.data.character in _PROJECT_CHARACTERS_CACHE :
		already = _OPEN_NODE.data.character
	var global_filters = CharactersInspector.read_listing_instruction()
	var apply_globals = GlobalFilters.is_pressed()
	var listing = {}
	for character_id in _PROJECT_CHARACTERS_CACHE:
		var the_character = _PROJECT_CHARACTERS_CACHE[character_id]
		if character_id == already || apply_globals == false || CharactersInspector.passes_filters(global_filters, character_id, the_character):
			listing[the_character.name] = character_id
	var listing_keys = listing.keys()
	if apply_globals && global_filters.SORT_ALPHABETICAL:
		listing_keys.sort()
	for char_name in listing_keys:
		var id = listing[char_name]
		Character.add_item(char_name if already != id || apply_globals == false else "["+ char_name +"]", id)
		Character.set_item_metadata(item_index, id)
		item_index += 1
	if select_by_res_id >= 0 :
		var character_item_index = find_listed_character_index( select_by_res_id )
		Character.select( character_item_index )
	else:
		if already != null :
			var character_item_index = find_listed_character_index(already)
			Character.select( character_item_index )
	pass

func update_lines_list(lines:Array = [], clear:bool = false) -> void:
	if clear:
		LinesList.clear()
	for line in lines:
		if line is String && line.length() > 0 :
			LinesList.add_item(line)
	pass

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	refresh_character_list()
	Line.clear()
	if node.has("data") && node.data is Dictionary:
		if node.data.has("lines") && node.data.lines is Array:
			update_lines_list(node.data.lines, true)
		else:
			update_lines_list(DEFAULT_NODE_DATA.lines, true)
		if node.data.has("playable") && node.data.playable is bool:
			Playable.set_deferred("button_pressed", node.data.playable)
		else:
			Playable.set_deferred("button_pressed", DEFAULT_NODE_DATA.playable)
	pass

func find_exposed_resources(lines:Array, return_ids:bool = true) -> Array:
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
		for line in lines:
			if line is String:
				for regex_match in _EXPOSURE_PATTERN.search_all( line ):
					var possible_exposure = regex_match.get_string(_NAME_GROUP_ID)
					# print_debug("Possible Resource Exposure: ", possible_exposure)
					if _CACHE_NAME_TO_ID.has( possible_exposure ):
						var exposed = _CACHE_NAME_TO_ID[possible_exposure] if return_ids else possible_exposure
						if exposed_resources.has(exposed) == false:
							exposed_resources.append(exposed)
	return exposed_resources

func cut_off_dropped_connections() -> void:
	if a_node_is_open() && _OPEN_NODE.data.has("lines") && ( _OPEN_NODE.data.lines is Array ):
		if _OPEN_NODE.data.lines.size() > LinesList.get_item_count():
			Main.Grid.cut_off_connections(_OPEN_NODE_ID, "out", LinesList.get_item_count() - 1)
	pass

func create_use_command(parameters:Dictionary) -> Dictionary:
	var use = { "drop": [], "refer": [] }
	# reference for any character as the dialog's owner?
	if parameters.character != _OPEN_NODE.data.character: # if new != already used
		if parameters.character >= 0:
			use.refer.append(parameters.character)
		if _OPEN_NODE.data.character >= 0:
			use.drop.append(_OPEN_NODE.data.character)
	# or any resource parsed ?
	var exposed_resources_by_uid = find_exposed_resources(parameters.lines, true)
	# ... remove the reference if any resource is not exposed anymore
	if _OPEN_NODE.has("ref") && _OPEN_NODE.ref is Array:
		for currently_referred_resource in _OPEN_NODE.ref:
			if (
				exposed_resources_by_uid.has( currently_referred_resource ) == false &&
				currently_referred_resource != parameters.character &&
				currently_referred_resource != _OPEN_NODE.data.character
			):
				use.drop.append( currently_referred_resource )
	# ... and add new ones
	if exposed_resources_by_uid.size() > 0 :
		var may_exist = (_OPEN_NODE.has("ref") && _OPEN_NODE.ref is Array)
		for newly_exposed in exposed_resources_by_uid:
			if may_exist == false || _OPEN_NODE.ref.has( newly_exposed ) == false:
				use.refer.append( newly_exposed )
	return use

func _read_parameters() -> Dictionary:
	cut_off_dropped_connections()
	var parameters = {
		"character": Character.get_selected_metadata(),
		"lines": ListHelpers.get_item_list_as_text_array(LinesList),
	}
	# Optionals (to avoid bloat:)
	# > playable (otherwise randomly auto-played)
	var playable = Playable.is_pressed()
	parameters["playable"] = playable if SAVE_UNOPTIMIZED || playable != DEFAULT_NODE_DATA.playable else null
	# ...
	# NOTE:
	# To avoid conflict with `add_item` default `-1` behavior, we used ANONYMOUS_UID_CONTROL_VALUE instead.
	# Here we adjust it to our conventional `-1` for unset/anonymous:
	if parameters.character == ANONYMOUS_UID_CONTROL_VALUE:
		parameters.character = -1
	# We should also handle dependencies if it relies on any other resource:
	var _use = create_use_command(parameters)
	if _use.drop.size() > 0 || _use.refer.size() > 0 :
		parameters._use = _use
	return parameters

func _create_new(_new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data

func _translate_internal_ref(data: Dictionary, translation: Dictionary) -> void:
	if translation.ids.has(data.character):
		data.character = translation.ids[data.character]
	for resource_set in RESOURCE_NAME_EXPOSURE:
		var _NAME_GROUP_ID = RESOURCE_NAME_EXPOSURE[resource_set].NAME_GROUP_ID
		var _EXPOSURE_PATTERN = RegEx.new()
		_EXPOSURE_PATTERN.compile( RESOURCE_NAME_EXPOSURE[resource_set].PATTERN )
		for idx in range(0, data.lines.size()):
			var revised = {}
			for matched in _EXPOSURE_PATTERN.search_all( data.lines[idx] ):
				var exposure = [matched.get_string(), matched.get_start(), matched.get_end()] 
				var exposed = [matched.get_string(_NAME_GROUP_ID), matched.get_start(_NAME_GROUP_ID), matched.get_end(_NAME_GROUP_ID)]
				if translation.names.has( exposed[0] ):
					var cut = [exposed[1] - exposure[1], exposed[2] - exposure[1]]
					var new_name = translation.names[exposed[0]]
					revised[exposure[0]] = (exposure[0].substr(0, cut[0]) + new_name + exposure[0].substr(cut[1], -1))
			for exposure in revised:
				data.lines[idx] = data.lines[idx].replace(exposure, revised[exposure])
	pass

func _on_list_gui_input(event) -> void:
	if event is InputEventKey && event.is_pressed():
		match event.get_physical_keycode():
			KEY_DELETE:
				if LinesList.get_item_count() > LinesList.get_selected_items().size(): # (Empty list is not allowed)
					remove_selected_lines()
			KEY_HOME:
				move_selected_top()
			KEY_END:
				move_selected_end()
			KEY_PAGEUP:
				move_selected_up()
			KEY_UP:
				if event.is_ctrl_pressed():
					move_selected_up()
			KEY_PAGEDOWN:
				move_selected_down()
			KEY_DOWN:
				if event.is_ctrl_pressed():
					move_selected_down()
	pass

static func map_i18n_data(id: int, node: Dictionary) -> Dictionary:
	var base_key = String.num_int64(id) + "-dialog-line-"
	var i18n = {}
	for idx in range(0, node.data.lines.size()):
		i18n[base_key + String.num_int64(idx)] = node.data.lines[idx]
	return i18n
