# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Tag-Match Sub-Inspector
extends Control

@onready var Main = get_tree().get_root().get_child(0)

const DEFAULT_NODE_DATA = TagMatchSharedClass.DEFAULT_NODE_DATA

const SAVE_UNOPTIMIZED = TagMatchSharedClass.SAVE_UNOPTIMIZED

const DO_NOT_ALLOW_BLANK_PATTERNS = false # ~ tag values can be blank by convention
const NO_CHARACTER_TEXT = "TAG_MATCH_INSPECTOR_NO_CHARACTER_TXT" # Translated ~ "No Character Available"
const NO_CHARACTER_ID = -254
const RESERVED_BLANK_KEYWORD = "--BLANK--"

var _OPEN_NODE_ID
var _OPEN_NODE

var _PROJECT_CHARACTERS_CACHE = {}

var This = self

@onready var CharactersInspector = Main.Mind.Inspector.Tab.Characters

@onready var Character = $Selector/List
@onready var GlobalFilters = $Selector/Filtered
@onready var TagKey = $TagKey
@onready var Pattern = $Pattern/Edit
@onready var Tools = $Pattern/Tools
@onready var ToolsPopup = Tools.get_popup()
@onready var PatternsList = $Patterns
@onready var RegExp = $RegExp

const TOOLS_MENU_BUTTON_POPUP = { # <id>:int { label:string, action:string<function-ident-to-be-called> }
	0: { "label": "TAG_MATCH_INSPECTOR_MENU_APPEND_NEW_PATTERN", "action": "append_new_pattern" },
	1: null, # separator
	2: { "label": "TAG_MATCH_INSPECTOR_MENU_EXTRACT_SELECTED", "action": "extract_selected_pattern" },
	3: { "label": "TAG_MATCH_INSPECTOR_MENU_REPLACE_SELECTED", "action": "replace_selected_pattern" },
	4: { "label": "TAG_MATCH_INSPECTOR_MENU_REMOVE_SELECTED", "action": "remove_selected_patterns" },
	5: null,
	6: { "label": "TAG_MATCH_INSPECTOR_MENU_SORT_PATTERNS_AZ", "action": "sort_items_alphabetical" },
	7: { "label": "TAG_MATCH_INSPECTOR_MENU_MOVE_SELECTED_TOP", "action": "move_selected_top" },
	8: { "label": "TAG_MATCH_INSPECTOR_MENU_MOVE_SELECTED_END", "action": "move_selected_end" },
	9: null,
	10: { "label": "TAG_MATCH_INSPECTOR_MENU_MOVE_SELECTED_UP", "action": "move_selected_up" },
	11: { "label": "TAG_MATCH_INSPECTOR_MENU_MOVE_SELECTED_DOWN", "action": "move_selected_down" },
}
var _TOOLS_ITEM_INDEX_BY_ACTION = {}

func _ready() -> void:
	load_tools_menu()
	register_connections()
	pass

func register_connections() -> void:
	GlobalFilters.pressed.connect(self.refresh_character_list, CONNECT_DEFERRED)
	ToolsPopup.id_pressed.connect(self._on_tools_popup_menu_id_pressed, CONNECT_DEFERRED)
	Pattern.text_changed.connect(self._toggle_available_tools_smartly, CONNECT_DEFERRED)
	Pattern.text_submitted.connect(self.append_new_pattern, CONNECT_DEFERRED)
	PatternsList.multi_selected.connect(self._toggle_available_tools_smartly, CONNECT_DEFERRED)
	PatternsList.item_activated.connect(self._on_double_click_item_activated, CONNECT_DEFERRED)
	PatternsList.item_clicked.connect(self._on_item_clicked, CONNECT_DEFERRED)
	PatternsList.gui_input.connect(self._on_list_gui_input, CONNECT_DEFERRED)
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
	var new_string_is_blank = DO_NOT_ALLOW_BLANK_PATTERNS && ( Pattern.get_text().length() == 0 )
	var selection_size = PatternsList.get_selected_items().size()
	var all_items_count = PatternsList.get_item_count()
	ToolsPopup.set_item_disabled( _TOOLS_ITEM_INDEX_BY_ACTION["append_new_pattern"], new_string_is_blank )
	ToolsPopup.set_item_disabled( _TOOLS_ITEM_INDEX_BY_ACTION["extract_selected_pattern"], (selection_size != 1 || all_items_count == 1 ) )
	ToolsPopup.set_item_disabled( _TOOLS_ITEM_INDEX_BY_ACTION["replace_selected_pattern"], (selection_size != 1 || new_string_is_blank) )
	ToolsPopup.set_item_disabled( _TOOLS_ITEM_INDEX_BY_ACTION["remove_selected_patterns"], ( selection_size == 0 || selection_size >= all_items_count || all_items_count == 1 ) )
	pass

func move_item(to_final_idx:int = 0, from:int = -1) -> void:
	var current_list_size = PatternsList.get_item_count()
	if current_list_size > 1 :
		if to_final_idx < current_list_size && from < current_list_size:
			if from < 0 : # if no item is selected to be moved
				from = (current_list_size - 1) # move the last one by default
			PatternsList.move_item(from, to_final_idx)
	pass

func move_selected_top(selected_patterns_indices:Array = []) -> void:
	if PatternsList.get_item_count() > 1 :
		if selected_patterns_indices.size() == 0:
			selected_patterns_indices = PatternsList.get_selected_items()
		if selected_patterns_indices.size() >= 1:
			selected_patterns_indices.sort()
			while selected_patterns_indices.size() > 0 :
				var the_first_item = selected_patterns_indices.pop_front()
				move_item(0, the_first_item)
	pass

func move_selected_end(selected_patterns_indices:Array = []) -> void:
	if PatternsList.get_item_count() > 1 :
		if selected_patterns_indices.size() == 0:
			selected_patterns_indices = PatternsList.get_selected_items()
		if selected_patterns_indices.size() >= 1:
			selected_patterns_indices.sort()
			var end = PatternsList.get_item_count() - 1;
			while selected_patterns_indices.size() > 0 :
				var the_first_item = selected_patterns_indices.pop_front()
				move_item(end, the_first_item)
	pass

func move_selected_up(selected_patterns_indices:Array = []) -> void:
	if PatternsList.get_item_count() > 1 :
		if selected_patterns_indices.size() == 0:
			selected_patterns_indices = PatternsList.get_selected_items()
		if selected_patterns_indices.size() >= 1:
			selected_patterns_indices.sort()
			while selected_patterns_indices.size() > 0 :
				var nth = selected_patterns_indices.pop_front()
				PatternsList.move_item(nth, max(0, nth - 1))
	pass

func move_selected_down(selected_patterns_indices:Array = []) -> void:
	if PatternsList.get_item_count() > 1 :
		if selected_patterns_indices.size() == 0:
			selected_patterns_indices = PatternsList.get_selected_items()
		if selected_patterns_indices.size() >= 1:
			selected_patterns_indices.sort()
			var end = PatternsList.get_item_count() - 1;
			while selected_patterns_indices.size() > 0 :
				var nth = selected_patterns_indices.pop_back()
				PatternsList.move_item(nth, min(end, nth + 1))
	pass

func sort_items_alphabetical() -> void:
	PatternsList.sort_items_by_text()
	pass

func append_new_pattern(text:String = "") -> void:
	var new_pattern = ( text if text.length() > 0 else Pattern.get("text") )
	PatternsList.add_item( new_pattern if new_pattern.length() > 0 else RESERVED_BLANK_KEYWORD )
	Pattern.clear()
	# select the last/newly created item
	PatternsList.select(( PatternsList.get_item_count() - 1) , true) 
	# and make sure it's visible
	PatternsList.ensure_current_is_visible()
	pass

func extract_selected_pattern(selected_patterns_indices:Array = []) -> void:
	if selected_patterns_indices.size() == 0:
		selected_patterns_indices = PatternsList.get_selected_items()
	if selected_patterns_indices.size() >= 1:
		var item_idx_to_extract = selected_patterns_indices[0]
		var item_text = PatternsList.get_item_text(item_idx_to_extract)
		Pattern.set_text(item_text)
		PatternsList.remove_item(item_idx_to_extract)
	# refresh tools manually, because set_text won't fire input event
	_toggle_available_tools_smartly()
	pass
	
func replace_selected_pattern(selected_patterns_indices:Array = []) -> void:
	if selected_patterns_indices.size() == 0:
		selected_patterns_indices = PatternsList.get_selected_items()
	if selected_patterns_indices.size() >= 1:
		var to_idx_for_replacement = selected_patterns_indices[0]
		remove_selected_patterns(selected_patterns_indices)
		var new_pattern = Pattern.get("text")
		PatternsList.add_item( new_pattern if new_pattern.length() > 0 else RESERVED_BLANK_KEYWORD )
		Pattern.clear()
		move_item(to_idx_for_replacement) # by default moves the last item
	pass

func remove_selected_patterns(selected_patterns_indices:Array = []) -> void:
	if selected_patterns_indices.size() == 0:
		selected_patterns_indices = PatternsList.get_selected_items()
	# we shall remove items from the last one because 
	# removal of a preceding item will change indices for others and you may remove innocent items!
	if selected_patterns_indices.size() >= 1:
		selected_patterns_indices.sort()
		while selected_patterns_indices.size() > 0 :
			var the_last_item = selected_patterns_indices.pop_back()
			PatternsList.remove_item(the_last_item)
	pass

func _on_item_clicked(item_idx:int, _click_position:Vector2, mouse_button_index:int) -> void:
	match mouse_button_index:
		# Extract on right-click
		MOUSE_BUTTON_RIGHT:
			var all_items_count = PatternsList.get_item_count()
			if all_items_count > 1 :
				extract_selected_pattern([item_idx])
	pass

func _on_double_click_item_activated(item_idx:int) -> void:
	var item_text = PatternsList.get_item_text(item_idx)
	Pattern.set_text(item_text)
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
	_PROJECT_CHARACTERS_CACHE = Main.Mind.clone_dataset_of("characters")
	if _PROJECT_CHARACTERS_CACHE.size() > 0 :
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
		if listing.size() == 0:
			Character.add_item(NO_CHARACTER_TEXT, NO_CHARACTER_ID)
			Character.set_item_metadata(0, NO_CHARACTER_ID)
		else:
			var listing_keys = listing.keys()
			if apply_globals && global_filters.SORT_ALPHABETICAL:
				listing_keys.sort()
			var item_index := 0
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
	else:
		Character.add_item(NO_CHARACTER_TEXT, NO_CHARACTER_ID)
		Character.set_item_metadata(0, NO_CHARACTER_ID)
	pass

func update_patterns_list(patterns:Array = [], clear:bool = false) -> void:
	if clear:
		PatternsList.clear()
	for pattern in patterns:
		if pattern is String && (pattern.length() > 0 || false == DO_NOT_ALLOW_BLANK_PATTERNS):
			PatternsList.add_item(pattern if pattern.length() > 0 else RESERVED_BLANK_KEYWORD)
	pass

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	refresh_character_list()
	Pattern.clear()
	if node.has("data") && node.data is Dictionary:
		TagKey.set_text(
			node.data.tag_key
			if node.data.has("tag_key") && node.data.tag_key is String && node.data.tag_key.length() > 0
			else DEFAULT_NODE_DATA.tag_key
		)
		if node.data.has("patterns") && node.data.patterns is Array:
			update_patterns_list(node.data.patterns, true)
		else:
			update_patterns_list(DEFAULT_NODE_DATA.patterns, true)
		if node.data.has("regex") && node.data.regex is bool:
			RegExp.set_deferred("button_pressed", node.data.regex)
		else:
			RegExp.set_deferred("button_pressed", DEFAULT_NODE_DATA.regex)
	pass

func cut_off_dropped_connections() -> void:
	if a_node_is_open() && _OPEN_NODE.data.has("patterns") && ( _OPEN_NODE.data.patterns is Array ):
		if _OPEN_NODE.data.patterns.size() > PatternsList.get_item_count():
			Main.Grid.cut_off_connections(_OPEN_NODE_ID, "out", PatternsList.get_item_count() - 1)
	pass

func create_use_command(parameters:Dictionary) -> Dictionary:
	var use = { "drop": [], "refer": [] }
	# reference for any character as the dialog's owner?
	if parameters.character != _OPEN_NODE.data.character: # if new != already used
		if parameters.character >= 0:
			use.refer.append(parameters.character)
		if _OPEN_NODE.data.character >= 0:
			use.drop.append(_OPEN_NODE.data.character)
	return use

func _read_parameters() -> Dictionary:
	cut_off_dropped_connections()
	var user_defined_tag_key = TagKey.get_text();
	var pattern_candidates = Helpers.ListHelpers.get_item_list_as_text_array(PatternsList)
	var revised_patterns = []
	for candidate in pattern_candidates:
		revised_patterns.append("" if candidate == RESERVED_BLANK_KEYWORD else candidate)
	# ...
	var parameters = {
		"character": Character.get_selected_metadata(),
		"tag_key": user_defined_tag_key if user_defined_tag_key.length() > 0 else DEFAULT_NODE_DATA.tag_key,
		"patterns": revised_patterns,
	}
	# Optionals (to avoid bloat:)
	# > regex (otherwise randomly auto-played)
	var regex = RegExp.is_pressed()
	parameters["regex"] = regex if SAVE_UNOPTIMIZED || regex != DEFAULT_NODE_DATA.regex else null
	# ...
	# NOTE:
	# To avoid conflict with `add_item` default `-1` behavior, we used NO_CHARACTER_ID instead.
	# Here we adjust it to our conventional `-1` for unset/anonymous:
	if parameters.character == NO_CHARACTER_ID:
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
	pass

func _on_list_gui_input(event) -> void:
	if event is InputEventKey && event.is_pressed():
		match event.get_physical_keycode():
			KEY_DELETE:
				if PatternsList.get_item_count() > PatternsList.get_selected_items().size(): # (Empty list is not allowed)
					remove_selected_patterns()
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
