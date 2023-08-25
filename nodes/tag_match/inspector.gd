# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Tag-Match Node Type Inspector
extends ScrollContainer

onready var Main = get_tree().get_root().get_child(0)

var ListHelpers = Helpers.ListHelpers

const DEFAULT_NODE_DATA = TagMatchSharedClass.DEFAULT_NODE_DATA

const SAVE_UNOPTIMIZED = TagMatchSharedClass.SAVE_UNOPTIMIZED

const DONT_ALLOW_BLANK_PATTERNS = false # ~ tag values can be blank by convention
const NO_CHARACTER_TEXT = "No Character Available"
const NO_CHARACTER_ID = -254
const RESERVED_BLANK_KEYWORD = "--BLANK--"

var _OPEN_NODE_ID
var _OPEN_NODE

var _PROJECT_CHARACTERS_CACHE = {}

var This = self

onready var Character = get_node("./TagMatch/Character/Selection")
onready var TagKey = get_node("./TagMatch/TagKey/LineEdit")
onready var Pattern = get_node("./TagMatch/Pattern/Edit")
onready var Tools = get_node("./TagMatch/Pattern/Tools")
onready var ToolsPopup = Tools.get_popup()
onready var PatternsList = get_node("./TagMatch/Patterns/List")
onready var RegEx = get_node("./TagMatch/RegEx")

const TOOLS_MENU_BUTTON_POPUP = { # <id>:int { label:string, action:string<function-ident-to-be-called> }
	0: { "label": "Append New Pattern", "action": "append_new_pattern" },
	1: null, # separator
	2: { "label": "Extract Selected Pattern", "action": "extract_selected_pattern" },
	3: { "label": "Replace Selected Pattern", "action": "replace_selected_pattern" },
	4: { "label": "Remove Selected Pattern(s)", "action": "remove_selected_patterns" },
	5: null,
	6: { "label": "Sort Patterns (Alphabetical)", "action": "sort_items_alphabetical" },
	7: { "label": "Move Selected Top", "action": "move_selected_top" },
}
var _TOOLS_ITEM_INDEX_BY_ACTION = {}

func _ready() -> void:
	load_tools_menu()
	register_connections()
	pass

func register_connections() -> void:
	ToolsPopup.connect("id_pressed", self, "_on_tools_popup_menu_id_pressed", [], CONNECT_DEFERRED)
	Pattern.connect("text_changed", self, "_toggle_available_tools_smartly", [], CONNECT_DEFERRED)
	Pattern.connect("text_entered", self, "append_new_pattern", [], CONNECT_DEFERRED)
	PatternsList.connect("multi_selected", self, "_toggle_available_tools_smartly", [], CONNECT_DEFERRED)
	PatternsList.connect("item_rmb_selected", self, "_on_right_click_item_selection", [], CONNECT_DEFERRED)
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
	var new_string_is_blank = DONT_ALLOW_BLANK_PATTERNS && ( Pattern.get_text().length() == 0 )
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

func move_selected_top(selected_patterns_idxs:Array = []) -> void:
	if PatternsList.get_item_count() > 1 :
		if selected_patterns_idxs.size() == 0:
			selected_patterns_idxs = PatternsList.get_selected_items()
		if selected_patterns_idxs.size() >= 1:
			# we shall move from the first element in order, so they keep staying in order
			selected_patterns_idxs.sort()
			while selected_patterns_idxs.size() > 0 :
				var the_first_item = selected_patterns_idxs.pop_front()
				move_item(0, the_first_item)
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

func extract_selected_pattern(selected_patterns_idxs:Array = []) -> void:
	if selected_patterns_idxs.size() == 0:
		selected_patterns_idxs = PatternsList.get_selected_items()
	if selected_patterns_idxs.size() >= 1:
		var item_idx_to_extract = selected_patterns_idxs[0]
		var item_text = PatternsList.get_item_text(item_idx_to_extract)
		Pattern.set_text(item_text)
		PatternsList.remove_item(item_idx_to_extract)
	# refresh tools manually, because set_text won't fire input event
	_toggle_available_tools_smartly()
	pass
	
func replace_selected_pattern(selected_patterns_idxs:Array = []) -> void:
	if selected_patterns_idxs.size() == 0:
		selected_patterns_idxs = PatternsList.get_selected_items()
	if selected_patterns_idxs.size() >= 1:
		var to_idx_for_replacement = selected_patterns_idxs[0]
		remove_selected_patterns(selected_patterns_idxs)
		var new_pattern = Pattern.get("text")
		PatternsList.add_item( new_pattern if new_pattern.length() > 0 else RESERVED_BLANK_KEYWORD )
		Pattern.clear()
		move_item(to_idx_for_replacement) # by default moves the last item
	pass

func remove_selected_patterns(selected_patterns_idxs:Array = []) -> void:
	if selected_patterns_idxs.size() == 0:
		selected_patterns_idxs = PatternsList.get_selected_items()
	# we shall remove items from the last one because 
	# removal of a preceding item will change indices for others and you may remove innocent items!
	if selected_patterns_idxs.size() >= 1:
		selected_patterns_idxs.sort()
		while selected_patterns_idxs.size() > 0 :
			var the_last_item = selected_patterns_idxs.pop_back()
			PatternsList.remove_item(the_last_item)
	pass

func _on_right_click_item_selection(item_idx:int, _click_position:Vector2) -> void:
	var all_items_count = PatternsList.get_item_count()
	if all_items_count > 1 :
		extract_selected_pattern([item_idx])
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
		var item_index := 0
		for character_id in _PROJECT_CHARACTERS_CACHE:
			var the_character = _PROJECT_CHARACTERS_CACHE[character_id]
			Character.add_item(the_character.name, character_id)
			Character.set_item_metadata(item_index, character_id)
			item_index += 1
		if select_by_res_id >= 0 :
			var character_item_index = find_listed_character_index( select_by_res_id )
			Character.select(character_item_index )
		else:
			if a_node_is_open() && _OPEN_NODE.data.has("character") && ( _OPEN_NODE.data.character in _PROJECT_CHARACTERS_CACHE ):
				var character_item_index_from_id = find_listed_character_index( _OPEN_NODE.data.character )
				Character.select( character_item_index_from_id )
	else:
		Character.add_item(NO_CHARACTER_TEXT, NO_CHARACTER_ID)
		Character.set_item_metadata(0, NO_CHARACTER_ID)
	pass

func update_patterns_list(patterns:Array = [], clear:bool = false) -> void:
	if clear:
		PatternsList.clear()
	for pattern in patterns:
		if pattern is String && (pattern.length() > 0 || false == DONT_ALLOW_BLANK_PATTERNS):
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
			RegEx.set_deferred("pressed", node.data.regex)
		else:
			RegEx.set_deferred("pressed", DEFAULT_NODE_DATA.regex)
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
	var user_defined_tag_key = TagKey.get_text();
	var pattern_candidates = ListHelpers.get_item_list_as_text_array(PatternsList)
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
	var regex = RegEx.is_pressed()
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

func _create_new(new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data

func _translate_internal_ref(data: Dictionary, translation: Dictionary) -> void:
	if translation.ids.has(data.character):
		data.character = translation.ids[data.character]
	pass
