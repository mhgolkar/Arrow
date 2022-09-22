# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Tag-Pass Node Type Inspector
extends ScrollContainer

onready var Main = get_tree().get_root().get_child(0)

var Utils = Helpers.Utils

var _OPEN_NODE_ID
var _OPEN_NODE

var _PROJECT_CHARACTERS_CACHE
	
# data for unset character (view)
const NO_CHARACTER_TEXT = "No Character Available"
const NO_CHARACTER_ID = -1

const TAG_KEY_ONLY_FORMAT_STRING = "{key}: *"
const TAG_KEY_VALUE_FORMAT_STRING = "{key}: `{value}`"

const DEFAULT_NODE_DATA = TagPassSharedClass.DEFAULT_NODE_DATA

const METHODS = TagPassSharedClass.METHODS
const METHODS_HINTS = TagPassSharedClass.METHODS_HINTS
const METHOD_ACCEPTS_KEY_ONCE = TagPassSharedClass.METHOD_ACCEPTS_KEY_ONCE

var This = self

onready var Characters = get_node("./TagPass/Characters")
onready var Methods = get_node("./TagPass/Methods")
onready var TagBox = get_node("./TagPass/Checkables/Rows/TagBox/Scroll/Tags")
onready var TagNoneMessage = get_node("./TagPass/Checkables/Rows/TagBox/Scroll/NoTagsToCheck")
onready var TagEditKey = get_node("./TagPass/Checkables/Rows/Edit/Entity/Key")
onready var TagEditValue = get_node("./TagPass/Checkables/Rows/Edit/Entity/Value")
onready var TagEditKeyOnly = get_node("./TagPass/Checkables/Rows/Edit/Check/KeyOnly")
onready var TagEditAdd = get_node("./TagPass/Checkables/Rows/Edit/Check/Add")

var _CHECKABLES_CACHE: Array = []

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	Methods.connect("item_selected", self, "_on_method_item_selected", [], CONNECT_DEFERRED)
	TagEditKeyOnly.connect("toggled", self, "_on_key_only_toggled", [], CONNECT_DEFERRED)
	TagEditAdd.connect("pressed", self, "read_and_add_checkable", [], CONNECT_DEFERRED)
	pass

func refresh_methods_list(select_by_method_id: int = -1) -> void:
	Methods.clear()
	for method_id in METHODS:
		Methods.add_item( METHODS[method_id], method_id )
	# ...
	if select_by_method_id >= 0 :
		var the_method_item_idx = Characters.get_item_index( select_by_method_id )
		Characters.select( the_method_item_idx )
	else:
		if is_open_node_valid():
			var the_method_item_idx = Methods.get_item_index( _OPEN_NODE.data.pass[0] )
			Methods.select(the_method_item_idx)
	# ...
	_on_method_item_selected()
	pass

# it loads characters into the option-button's list, where ...
# every item-id is the character's resource-uid
func refresh_characters_list(select_by_res_id:int = -1) -> void:
	Characters.clear()
	_PROJECT_CHARACTERS_CACHE = Main.Mind.clone_dataset_of("characters")
	if _PROJECT_CHARACTERS_CACHE.size() > 0 : 
		for character_id in _PROJECT_CHARACTERS_CACHE:
			var the_character = _PROJECT_CHARACTERS_CACHE[character_id]
			Characters.add_item(the_character.name, character_id)
		if select_by_res_id >= 0 :
			var character_item_index = Characters.get_item_index( select_by_res_id )
			Characters.select( character_item_index )
		else:
			if is_open_node_valid() && _PROJECT_CHARACTERS_CACHE.has(_OPEN_NODE.data.character):
				var character_item_index = Characters.get_item_index( _OPEN_NODE.data.character )
				Characters.select( character_item_index )
	else:
		Characters.add_item(NO_CHARACTER_TEXT, NO_CHARACTER_ID)
	pass

func is_open_node_valid() -> bool :
	return (
		(_OPEN_NODE_ID is int) && (_OPEN_NODE_ID >= 0) &&
		(_OPEN_NODE is Dictionary) && _OPEN_NODE.has("data") && (_OPEN_NODE.data is Dictionary) &&
		TagPassSharedClass.data_is_valid(_OPEN_NODE.data)
	)

func _on_key_only_toggled(state: bool) -> void:
	if state == true:
		TagEditValue.set_text("")
	TagEditValue.set_editable(!state)
	pass

func drop_all_duplicated_keys(refresh_view: bool = true) -> void:
	var kept_keys = []
	var erasure = []
	for entity in _CHECKABLES_CACHE:
		if kept_keys.has(entity[0]):
			erasure.append(entity)
		else:
			kept_keys.append(entity[0])
	for duplicate in erasure:
		_CHECKABLES_CACHE.erase(duplicate)
	if refresh_view:
		refresh_checkable_tags(false) # ~ from cache not scratch 
	pass

func drop_matching_checkable(key: String, value, key_is_enough: bool, refresh_view: bool = true) -> void:
	var erasure = []
	for entity in _CHECKABLES_CACHE:
		if entity[0] == key && (key_is_enough || (entity.size() >= 2 && entity[1] == value)):
			erasure.append(entity)
	for duplicate in erasure:
		while _CHECKABLES_CACHE.has(duplicate):
			_CHECKABLES_CACHE.erase(duplicate)
	if refresh_view:
		refresh_checkable_tags(false) # ~ from cache not scratch
	pass

func read_and_add_checkable() -> void:
	var key = Utils.exposure_safe_resource_name( TagEditKey.get_text() )
	TagEditKey.set_text(key) # ... so the user can see the safe key if we have changed it
	var only_key = TagEditKeyOnly.is_pressed()
	var value = null if only_key else TagEditValue.get_text()
	var method = Methods.get_selected_id()
	if key.length() > 0:
		drop_matching_checkable(key, value, METHOD_ACCEPTS_KEY_ONCE.has(method), false) # + we refresh view later
		_CHECKABLES_CACHE.append([key, value])
	refresh_checkable_tags(false) # ~ from cache not scratch
	pass

func take_tag_menu_action(action_id: int, key: String, value) -> void:
	var value_text = value if value is String else ""
	match action_id:
		1: # Edit
			TagEditKey.set_text(key)
			TagEditValue.set_text(value_text)
			TagEditKeyOnly.set_pressed(value == null)
			TagEditKey.grab_focus()
		2: # Drop
			drop_matching_checkable(key, value, false, true)
			TagEditKey.set_text(key)
			TagEditValue.set_text(value_text)
			TagEditKeyOnly.set_pressed(value == null)
			TagEditKey.grab_focus()
	pass

func clean_all_tags() -> void:
	for node in TagBox.get_children():
		if node is Button:
			node.free()
	pass

func append_tag_to_box(key: String, value) -> void:
	var _FORMAT_STRING = TAG_KEY_VALUE_FORMAT_STRING if value is String else TAG_KEY_ONLY_FORMAT_STRING
	var key_value_display = _FORMAT_STRING.format({
		"key": key, "value": value if value is String else "N/A"
	})
	var the_tag = MenuButton.new()
	the_tag.set_text(key_value_display)
	# the_tag.set_tooltip(key_value_display)
	the_tag.set_flat(false)
	var the_popup = the_tag.get_popup()
	the_popup.add_item(key_value_display, 0)
	the_popup.set_item_disabled(0, true)
	the_popup.add_separator("", 0)
	the_popup.add_item("Edit", 1)
	the_popup.add_item("Drop", 2)
	the_popup.connect("id_pressed", self, "take_tag_menu_action", [key, value], CONNECT_DEFERRED)
	# ...
	TagBox.add_child(the_tag)
	pass

func refresh_checkable_tags(clear: bool = true) -> void:
	clean_all_tags()
	if clear:
		_CHECKABLES_CACHE = []
		if is_open_node_valid():
			for entity in _OPEN_NODE.data.pass[1]:
				if TagPassSharedClass.tag_is_checkable(entity):
					_CHECKABLES_CACHE.append(entity)
	for checkable in _CHECKABLES_CACHE:
		append_tag_to_box(checkable[0], checkable[1] if checkable.size() > 1 else null)
	TagNoneMessage.set_visible(_CHECKABLES_CACHE.size() == 0)
	pass

func _on_method_item_selected(item_index:int = -1) -> void:
	if item_index < 0:
		item_index = Methods.get_selected()
	var selected_method = Methods.get_item_id(item_index)
	Methods.set_tooltip( METHODS_HINTS[selected_method] )
	if METHOD_ACCEPTS_KEY_ONCE.has(selected_method):
		drop_all_duplicated_keys(true)
	pass

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	# ... then refresh view
	refresh_checkable_tags()
	refresh_characters_list()
	refresh_methods_list()
	pass

func _read_parameters() -> Dictionary:
	# if there is no character out there
	if _PROJECT_CHARACTERS_CACHE.size() == 0:
		# we can only accept unset parameters, so ...
		return _create_new()
	# otherwise ...
	var parameters = {
		"character": Characters.get_selected_id(),
		"pass": [
			Methods.get_selected_id(),
			_CHECKABLES_CACHE
		],
	}
	# `use` state can be for ...
	var _use = { "drop": [], "refer": [] }
	# ... target `character`,
	if parameters.character != _OPEN_NODE.data.character: # if changed
		_use.drop.append(_OPEN_NODE.data.character) # old one
		_use.refer.append(parameters.character) # new one
	# clean up `_use`
	for cmd in _use:
		for res in _use[cmd]:
			if res < 0 :
				_use[cmd].erase(res)
	if _use.drop.size() > 0 || _use.refer.size() > 0 :
		parameters._use = _use
		parameters._use.field = "characters"
	return parameters

func _create_new(new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data
