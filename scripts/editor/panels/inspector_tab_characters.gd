# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Inspector :: Character Tab
extends Tabs

signal relay_request_mind

onready var Main = get_tree().get_root().get_child(0)
onready var Grid = get_node(Addressbook.GRID)

var _LISTED_CHARACTERS_BY_ID = {}
var _LISTED_CHARACTERS_BY_NAME = {}
var _SELECTED_CHARACTER_BEING_EDITED_ID = -1
var _SELECTED_CHARACTER_USE_CASES_IN_THE_SCENE_BY_ID = []

onready var CharactersList = get_node(Addressbook.INSPECTOR.CHARACTERS.CHARACTERS_LIST)
onready var CharactersNewButton = get_node(Addressbook.INSPECTOR.CHARACTERS.NEW_BUTTON)
onready var CharacterRemoveButton = get_node(Addressbook.INSPECTOR.CHARACTERS.REMOVE_BUTTON)

onready var CharacterEditorPanel = get_node(Addressbook.INSPECTOR.CHARACTERS.CHARACTER_EDITOR.itself)
onready var CharacterEditorName = get_node(Addressbook.INSPECTOR.CHARACTERS.CHARACTER_EDITOR.NAME_EDIT)
onready var CharacterColorPickerButton = get_node(Addressbook.INSPECTOR.CHARACTERS.CHARACTER_EDITOR.COLOR_PICKER_BUTTON)
onready var CharacterEditorSaveButton = get_node(Addressbook.INSPECTOR.CHARACTERS.CHARACTER_EDITOR.SAVE_BUTTON)

onready var CharacterAppearanceIndication = get_node(Addressbook.INSPECTOR.CHARACTERS.CHARACTER_APPEARANCE.INDICATION)
onready var CharacterAppearanceGoToButton = get_node(Addressbook.INSPECTOR.CHARACTERS.CHARACTER_APPEARANCE.GO_TO_MENU_BUTTON)
onready var CharacterAppearanceGoToButtonPopup = CharacterAppearanceGoToButton.get_popup()
const CHARACTER_APPEARANCE_INDICATION_TEMPLATE = "{here}:{total}"

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	CharactersNewButton.connect("pressed", self, "request_new_character_creation", [], CONNECT_DEFERRED)
	CharactersList.connect("item_selected", self, "_on_characters_list_item_selected", [], CONNECT_DEFERRED)
	CharactersList.connect("nothing_selected", self, "_on_characters_list_nothing_selected", [], CONNECT_DEFERRED)
	CharacterEditorSaveButton.connect("pressed", self, "submit_character_modification", [], CONNECT_DEFERRED)
	CharacterRemoveButton.connect("pressed", self, "request_remove_character", [], CONNECT_DEFERRED)
	CharacterAppearanceGoToButtonPopup.connect("id_pressed", self, "_on_go_to_menu_button_popup_id_pressed", [], CONNECT_DEFERRED)
	pass

func initialize_tab() -> void:
	refresh_tab()
	pass

func refresh_tab() -> void:
	refresh_characters_list()
	pass
	
func refresh_characters_list(list:Dictionary = {}) -> void:
	CharactersList.clear()
	_LISTED_CHARACTERS_BY_ID.clear()
	_LISTED_CHARACTERS_BY_NAME.clear()
	if list.size() == 0 :
		# fetch the characters dataset if it's not provided as parameter
		list = Main.Mind.clone_dataset_of("characters")
	list_characters(list)
	CharactersList.unselect_all()
	smartly_toggle_editor()
	pass

# appends a list of characters to the existing ones
# Note: this won't refresh the current list,
# if a character exists (by id) it'll be updated, otherwise added
func list_characters(list_to_append:Dictionary) -> void :
	for character_id in list_to_append:
		var the_character = list_to_append[character_id]
		if _LISTED_CHARACTERS_BY_ID.has(character_id):
			update_character_list_item(character_id, the_character)
		else:
			insert_character_list_item(character_id, the_character)
	CharactersList.ensure_current_is_visible()
	pass

func unlist_characters(id_list:Array) -> void :
	CharactersList.unselect_all()
	smartly_toggle_editor()
	# remove items from the list
	# Note: to avoid conflicts, we remove from end, because the indices may change otherwise and disturb the job.
	var idx = ( CharactersList.get_item_count() - 1 )
	while idx >= 0:
		if id_list.has( CharactersList.get_item_metadata(idx) ):
			CharactersList.remove_item(idx)
		idx = (idx - 1)
	# also clean from the references
	for character_id in id_list:
		dereference_listed_characters(character_id)
	pass
	
func reference_listed_characters(character_id:int, the_character:Dictionary) -> void:
	# is it previously referenced ?
	if _LISTED_CHARACTERS_BY_ID.has(character_id): # if so, attempt some cleanup
		var previously_referenced = _LISTED_CHARACTERS_BY_ID[character_id]
		# the id never changes but names change, so we need to remove previously kept reference by name
		if previously_referenced.name != the_character.name: # if the name is changed
			# to avoid the false notion that the old name is still in use
			_LISTED_CHARACTERS_BY_NAME.erase(previously_referenced.name)
	# now we can update or create the references
	_LISTED_CHARACTERS_BY_ID[character_id] = the_character
	_LISTED_CHARACTERS_BY_NAME[the_character.name] = _LISTED_CHARACTERS_BY_ID[character_id]
	# we can refresh character editor because change in reference means an update
	if _SELECTED_CHARACTER_BEING_EDITED_ID == character_id:
		load_character_in_editor(_SELECTED_CHARACTER_BEING_EDITED_ID)
	pass

func dereference_listed_characters(character_id:int) -> void:
	if _LISTED_CHARACTERS_BY_ID.has(character_id):
		_LISTED_CHARACTERS_BY_NAME.erase( _LISTED_CHARACTERS_BY_ID[character_id].name )
		_LISTED_CHARACTERS_BY_ID.erase(character_id)
	pass
	
func insert_character_list_item(character_id:int, the_character:Dictionary) -> void:
	reference_listed_characters(character_id, the_character)
	# insert the character as list item
	CharactersList.add_item( the_character.name )
	# we need to keep track of ids in metadata
	# the item is added last, so...
	var item_index = (CharactersList.get_item_count() - 1)
	CharactersList.set_item_metadata(item_index, character_id)
	CharactersList.set_item_custom_fg_color(item_index, Color(the_character.color))
	# then select and load it in the character editor
	CharactersList.select(item_index)
	load_character_in_editor(character_id)
	pass

func update_character_list_item(character_id:int, the_character:Dictionary) -> void:
	reference_listed_characters(character_id, the_character)
	for idx in range(0, CharactersList.get_item_count()):
		if CharactersList.get_item_metadata(idx) == character_id:
			# found it, update...
			CharactersList.set_item_text(idx, the_character.name)
			CharactersList.set_item_custom_fg_color(idx, Color(the_character.color))
			return
	printerr("Unexpected Behavior! Trying to update character=%s which is not found in the list!")
	pass

func request_new_character_creation() -> void:
	self.emit_signal("relay_request_mind", "create_character")
	pass

func request_remove_character(resource_id:int = -1) -> void:
	if resource_id < 0 : # default to the selected one
		resource_id = _SELECTED_CHARACTER_BEING_EDITED_ID
	# make sure this is an exising character resource before removing it
	if _LISTED_CHARACTERS_BY_ID.has(resource_id):
		self.emit_signal("relay_request_mind", "remove_resource", { "id": resource_id, "field": "characters" })
	CharactersList.unselect_all()
	smartly_toggle_editor()
	pass

func load_character_in_editor(character_id:int) -> void:
	_SELECTED_CHARACTER_BEING_EDITED_ID = character_id
	var the_character = _LISTED_CHARACTERS_BY_ID[character_id]
	CharacterEditorName.set_text(the_character.name)
	CharacterColorPickerButton.set("color", Color(the_character.color))
	# can't it be removed ? not if it's used by other resources
	CharacterRemoveButton.set_disabled( (the_character.has("use") && the_character.use.size() > 0) )
	update_appearance_pagination(character_id)
	smartly_toggle_editor()
	pass
	
func update_appearance_pagination(character_id:int) -> void:
	_SELECTED_CHARACTER_USE_CASES_IN_THE_SCENE_BY_ID.clear()
	CharacterAppearanceGoToButtonPopup.clear()
	var count = {
		"total": 0,
		"here": 0
	}
	var the_character = _LISTED_CHARACTERS_BY_ID[character_id]
	if the_character.has("use"):
		for usecase_id in the_character.use:
			if Grid._DRAWN_NODES_BY_ID.has(usecase_id):
				_SELECTED_CHARACTER_USE_CASES_IN_THE_SCENE_BY_ID.append(usecase_id)
		count.total = the_character.use.size()
		count.here = _SELECTED_CHARACTER_USE_CASES_IN_THE_SCENE_BY_ID.size()
	# update stuff
	CharacterAppearanceIndication.set_text( CHARACTER_APPEARANCE_INDICATION_TEMPLATE.format(count) )
	if count.here > 0 :
		for usecase_id in _SELECTED_CHARACTER_USE_CASES_IN_THE_SCENE_BY_ID:
			CharacterAppearanceGoToButtonPopup.add_item(
				Grid._DRAWN_NODES_BY_ID[usecase_id]._node_resource.name,
				usecase_id
			)
	CharacterAppearanceGoToButton.set_disabled( ! (count.here > 0) )
	pass
	
func _on_go_to_menu_button_popup_id_pressed(usecase_id:int) -> void:
	Grid.call_deferred("go_to_offset_by_node_id", usecase_id, true)
	pass
	
func submit_character_modification() -> void:
	var the_character_original = _LISTED_CHARACTERS_BY_ID[ _SELECTED_CHARACTER_BEING_EDITED_ID ]
	var resource_updater = {
		"id": _SELECTED_CHARACTER_BEING_EDITED_ID, 
		"modification": {},
		"field": "characters"
	}
	var mod_name  = CharacterEditorName.get_text()
	var mod_color = CharacterColorPickerButton.get("color").to_html(false)
	if mod_name.length() > 0 && mod_name != the_character_original.name: # name is changed
		# force using unique name for characters ?
		if Settings.FORCE_UNIQUE_NAMES_FOR_CHARACTERS == false || _LISTED_CHARACTERS_BY_NAME.has(mod_name) == false:
			resource_updater.modification["name"] = mod_name
		else:
			resource_updater.modification["name"] = ( mod_name + Settings.REUSED_CHARACTER_NAMES_AUTO_POSTFIX )
	if mod_color != the_character_original.color: # emphasis-color value is changed
		resource_updater.modification["color"] = mod_color
	if resource_updater.modification.size() > 0 :
		self.emit_signal("relay_request_mind", "update_resource", resource_updater)
	pass

func _on_characters_list_item_selected(idx:int)-> void:
	var character_id = CharactersList.get_item_metadata(idx)
	load_character_in_editor(character_id)
	pass

func smartly_toggle_editor() -> void:
	var selected_characters_in_list = CharactersList.get_selected_items()
	if selected_characters_in_list.size() == 0 || CharactersList.get_item_metadata( selected_characters_in_list[0] ) != _SELECTED_CHARACTER_BEING_EDITED_ID:
		CharacterEditorPanel.set("visible", false)
	else:
		CharacterEditorPanel.set("visible", true)
	pass
	
func _on_characters_list_nothing_selected() -> void:
	CharactersList.unselect_all()
	_SELECTED_CHARACTER_BEING_EDITED_ID = -1
	smartly_toggle_editor()
	pass
