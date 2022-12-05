# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Tag-Edit Node Type Inspector
extends ScrollContainer

onready var Main = get_tree().get_root().get_child(0)

var Utils = Helpers.Utils

var _OPEN_NODE_ID
var _OPEN_NODE

var _PROJECT_CHARACTERS_CACHE
	
# data for unset character (view)
const NO_CHARACTER_TEXT = "No Character Available"
const NO_CHARACTER_ID = -1

const DEFAULT_NODE_DATA = TagEditSharedClass.DEFAULT_NODE_DATA

const METHODS = TagEditSharedClass.METHODS
const METHODS_HINTS = TagEditSharedClass.METHODS_HINTS
const METHOD_NEEDS_NO_VALUE = TagEditSharedClass.METHOD_NEEDS_NO_VALUE

var This = self

onready var Characters = get_node("./TagEdit/Characters")
onready var Methods = get_node("./TagEdit/Methods")
onready var Key = get_node("./TagEdit/Key")
onready var Value = get_node("./TagEdit/Value")

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	Methods.connect("item_selected", self, "_on_method_item_selected", [], CONNECT_DEFERRED)
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
			var the_method_item_idx = Methods.get_item_index( _OPEN_NODE.data.edit[0] )
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

func refresh_tag_key_value(key: String = "", value: String = "") -> void:
	var invalid = (! is_open_node_valid())
	Key.set_text(key if (key.length() > 0 || invalid) else _OPEN_NODE.data.edit[1])
	Value.set_text(value if (value.length() > 0 || invalid) else _OPEN_NODE.data.edit[2])
	pass

func _on_method_item_selected(item_index:int = -1) -> void:
	if item_index < 0:
		item_index = Methods.get_selected()
	var selected_method = Methods.get_item_id(item_index)
	Value.set_editable( (! METHOD_NEEDS_NO_VALUE.has(selected_method)) )
	Methods.set_tooltip( METHODS_HINTS[selected_method] )
	pass

func is_open_node_valid() -> bool :
	return (
		(_OPEN_NODE_ID is int) && (_OPEN_NODE_ID >= 0) &&
		(_OPEN_NODE is Dictionary) && _OPEN_NODE.has("data") && (_OPEN_NODE.data is Dictionary) &&
		TagEditSharedClass.data_is_valid(_OPEN_NODE.data)
	)

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	# ... then refresh view
	refresh_tag_key_value()
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
		"edit": [
			Methods.get_selected_id(),
			Utils.exposure_safe_resource_name( Key.get_text() ),
			Value.get_text(),
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

func _translate_internal_ref(data: Dictionary, translation: Dictionary) -> void:
	if translation.ids.has(data.character):
		data.character = translation.ids[data.character]
	pass
