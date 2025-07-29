# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Inspector :: Character Tab
extends Control

signal relay_request_mind()

@onready var Main = get_tree().get_root().get_child(0)
@onready var Grid = $/root/Main/Editor/Center/Grid

var _LISTED_CHARACTERS_BY_ID = {}
var _LISTED_CHARACTERS_BY_NAME = {}

var _SELECTED_CHARACTER_BEING_EDITED_ID = -1

var _SELECTED_CHARACTER_USERS = {} # id: {id, resource, map}
var _SELECTED_CHARACTER_USER_IDS = []

var _CURRENT_LOCATED_REF_ID = -1

var _KEY_BEING_REVISED = null

@onready var Filter = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Filters/Input
@onready var FilterReverse = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Filters/Reverse
@onready var FilterForScene = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Filters/Scoped
@onready var SortAlphabetical = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Filters/Alphabetical

@onready var CharactersList = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/List

@onready var CharacterEditorPanel = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Editor
# > Identity
@onready var CharacterRawUid = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Editor/Tools/Configs/Uid
@onready var CharacterEditorName = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Editor/Tools/Configs/Name
@onready var CharacterColorPickerButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Editor/Tools/Configs/Color
@onready var CharacterEditorSaveButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Editor/Tools/Configs/Set
# > Tags
@onready var TagBox = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Editor/Tools/Tags/Initials/Scroll/Pairs
@onready var TagNoneMessage = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Editor/Tools/Tags/Initials/Scroll/None
@onready var TagEditKey = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Editor/Tools/Tags/Initials/Edit/Key
@onready var TagEditValue = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Editor/Tools/Tags/Initials/Edit/Value
@onready var TagEditOverset = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Editor/Tools/Tags/Initials/Edit/Overset
# > Appearances (References)
@onready var CharacterAppearancePanel = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Editor/Tools/Appearances
@onready var CharacterAppearanceGoToButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Editor/Tools/Appearances/Referrers
@onready var CharacterAppearanceGoToButtonPopup = CharacterAppearanceGoToButton.get_popup()
@onready var CharacterAppearanceGoToPrevious = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Editor/Tools/Appearances/Previous
@onready var CharacterAppearanceGoToNext = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Editor/Tools/Appearances/Next
@onready var CharacterAppearanceFilterForScene = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Editor/Tools/Appearances/Scoped

@onready var CharactersNewButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Actions/New
@onready var CharacterRemoveButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Characters/Manager/Actions/Remove

const TAG_KEY_VALUE_DISPLAY_TEMPLATE = "`{value}`" # also available: {key}
const CHARACTER_APPEARANCE_COUNT_TEMPLATE = "{0} [{1}]"
const RAW_UID_TIP_TEMPLATE = "UID: %s"

func _ready() -> void:
	register_connections()
	CharacterAppearanceGoToButtonPopup.set_allow_search(true)
	pass

func register_connections() -> void:
	CharactersNewButton.pressed.connect(self.request_new_character_creation, CONNECT_DEFERRED)
	CharactersList.item_selected.connect(self._on_characters_list_item_selected, CONNECT_DEFERRED)
	CharactersList.empty_clicked.connect(self._on_characters_list_empty_clicked, CONNECT_DEFERRED)
	CharactersList.gui_input.connect(self._on_list_gui_input, CONNECT_DEFERRED)
	CharacterRawUid.pressed.connect(self.os_clipboard_push_raw_uid, CONNECT_DEFERRED)
	CharacterEditorSaveButton.pressed.connect(self.submit_character_modification, CONNECT_DEFERRED)
	CharacterRemoveButton.pressed.connect(self.request_remove_character, CONNECT_DEFERRED)
	TagEditOverset.pressed.connect(self.read_and_overset_tag, CONNECT_DEFERRED)
	CharacterAppearanceGoToButtonPopup.index_pressed.connect(self._on_go_to_menu_button_popup_index_pressed, CONNECT_DEFERRED)
	CharacterAppearanceGoToPrevious.pressed.connect(self._rotate_go_to.bind(-1), CONNECT_DEFERRED)
	CharacterAppearanceGoToNext.pressed.connect(self._rotate_go_to.bind(1), CONNECT_DEFERRED)
	CharacterAppearanceFilterForScene.pressed.connect(self.refresh_referrers_list, CONNECT_DEFERRED)
	Filter.text_changed.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	FilterReverse.toggled.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	FilterForScene.toggled.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	SortAlphabetical.toggled.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
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
	CharactersList.deselect_all()
	smartly_toggle_editor()
	pass

func _on_listing_instruction_change(_x = null) -> void:
	refresh_characters_list()
	pass

func read_listing_instruction() -> Dictionary:
	var filter_text = Filter.get_text()
	var filter_array = []
	for pattern in ["(.*)\\.(.*):(.*)", "(.*)\\.(.*)", "(.*)"]:
		var extended_pattern = RegEx.new()
		extended_pattern.compile(pattern)
		var regex_match = extended_pattern.search(filter_text)
		if regex_match != null:
			filter_array = Array(regex_match.get_strings())
			filter_array.pop_front() # to remove the first (whole text) element
			break
	while filter_array.size() < 3:
		filter_array.append("")
	# ...
	return {
		"FILTER": filter_array,
		"FILTER_REVERSE": FilterReverse.is_pressed(),
		"FILTER_FOR_SCENE": FilterForScene.is_pressed(),
		"SORT_ALPHABETICAL": SortAlphabetical.is_pressed(),
	}

func passes_char_filters(character: Dictionary, _LISTING: Dictionary) -> bool:
	var passes = true # when there is no filter
	if _LISTING.FILTER.size() > 0:
		var pass_name = Helpers.Utils.filter_pass(character.name, _LISTING.FILTER[0])
		# first make sure that characters with no tag also passe if there is no real filter:
		var pass_tag_key = _LISTING.FILTER[1].length() == 0
		var pass_tag_value = _LISTING.FILTER[2].length() == 0
		if character.has("tags"):
			for key in character.tags:
				if pass_tag_key != true:
					pass_tag_key = Helpers.Utils.filter_pass(key, _LISTING.FILTER[1])
				if pass_tag_key == true && pass_tag_value != true:
					pass_tag_value = Helpers.Utils.filter_pass(character.tags[key], _LISTING.FILTER[2])
				if pass_tag_key && pass_tag_value:
					break
		passes = (pass_name && pass_tag_key && pass_tag_value)
	return (passes if _LISTING.FILTER_REVERSE == false else (!passes))

func passes_filters(instruction: Dictionary, character_id: int, character: Dictionary) -> bool:
	if passes_char_filters(character, instruction):
		if instruction.FILTER_FOR_SCENE == false || Main.Mind.resource_is_used_in_scene(character_id, "characters"):
			return true
	return false

# appends a list of characters to the existing ones
# Note: this won't refresh the current list,
# if a character exists (by id) it'll be updated, otherwise added
func list_characters(list_to_append:Dictionary) -> void :
	var _LISTING = read_listing_instruction()
	for character_id in list_to_append:
		var the_character = list_to_append[character_id]
		if passes_filters(_LISTING, character_id, the_character):
			if _LISTED_CHARACTERS_BY_ID.has(character_id):
				update_character_list_item(character_id, the_character)
			else:
				insert_character_list_item(character_id, the_character)
	CharactersList.ensure_current_is_visible()
	if _LISTING.SORT_ALPHABETICAL:
		CharactersList.call_deferred("sort_items_by_text")
	pass

func unlist_characters(id_list:Array) -> void :
	CharactersList.deselect_all()
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
	CharactersList.set_item_custom_fg_color(item_index, Helpers.Utils.rgba_hex_to_color(the_character.color))
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
			CharactersList.set_item_custom_fg_color(idx, Helpers.Utils.rgba_hex_to_color(the_character.color))
			return
	printerr("Unexpected Behavior! Trying to update character=%s which is not found in the list!")
	pass

func request_new_character_creation() -> void:
	self.relay_request_mind.emit("create_character")
	pass

func request_remove_character(resource_id:int = -1) -> void:
	if resource_id < 0 : # default to the selected one
		resource_id = _SELECTED_CHARACTER_BEING_EDITED_ID
	# make sure this is an existing character resource before removing it
	if _LISTED_CHARACTERS_BY_ID.has(resource_id):
		self.relay_request_mind.emit("remove_resource", { "id": resource_id, "field": "characters" })
	CharactersList.deselect_all()
	smartly_toggle_editor()
	pass

func load_character_in_editor(character_id:int) -> void:
	_SELECTED_CHARACTER_BEING_EDITED_ID = character_id
	var the_character = _LISTED_CHARACTERS_BY_ID[character_id]
	CharacterRawUid.set_deferred("tooltip_text", (RAW_UID_TIP_TEMPLATE % character_id) + tr("TYPE_INSPECTOR_RAW_UID_HINT"))
	CharacterEditorName.set_text(the_character.name)
	CharacterColorPickerButton.set("color", Helpers.Utils.rgba_hex_to_color(the_character.color))
	# can't it be removed ? not if it's used by other resources
	CharacterRemoveButton.set_disabled( (the_character.has("use") && the_character.use.size() > 0) )
	# ...
	update_tag_box(character_id)
	update_appearance_pagination(character_id)
	refresh_revision_mode(null)
	smartly_toggle_editor()
	pass

func refresh_character_cache_by_id(character_id:int) -> void:
	if character_id >= 0 :
		var the_character = Main.Mind.lookup_resource(character_id, "characters", true)
		if the_character is Dictionary:
			_LISTED_CHARACTERS_BY_ID[character_id] = the_character
			_LISTED_CHARACTERS_BY_NAME[the_character.name] = _LISTED_CHARACTERS_BY_ID[character_id]
	pass

func os_clipboard_push_raw_uid():
	DisplayServer.clipboard_set( String.num_int64(_SELECTED_CHARACTER_BEING_EDITED_ID) )
	pass

func refresh_revision_mode(key = null) -> void:
	if key is String:
		_KEY_BEING_REVISED = key
	else:
		_KEY_BEING_REVISED = null
	# ...
	for node in TagBox.get_children():
		if node is Button:
			node.set_disabled(
				_KEY_BEING_REVISED is String &&
				node.get_meta("key") != _KEY_BEING_REVISED
			)
	pass

func take_tag_action(action_id: int, key: String, value: String) -> void:
	match action_id:
		1: # Edit
			TagEditKey.set_text(key)
			TagEditValue.set_text(value)
			TagEditValue.grab_focus()
			refresh_revision_mode(key)
		2: # Unset
			TagEditKey.set_text(key)
			TagEditKey.grab_focus()
			TagEditValue.set_text(value)
			var tag_unset = {
				"id": _SELECTED_CHARACTER_BEING_EDITED_ID, 
				"modification": { "tags": { key: null } },
				"field": "characters"
			}
			self.relay_request_mind.emit("update_resource", tag_unset)
		3: # Overset
			var tag_overset = {
				"id": _SELECTED_CHARACTER_BEING_EDITED_ID, 
				"modification": { "tags": { key: value } },
				"field": "characters"
			}
			if _KEY_BEING_REVISED is String && _KEY_BEING_REVISED != key:
				var character_name = _LISTED_CHARACTERS_BY_ID[_SELECTED_CHARACTER_BEING_EDITED_ID].name
				tag_overset.modification["tags"][_KEY_BEING_REVISED] = null
				tag_overset.modification["data"] = {
					"_exposure_revision": [
						[_KEY_BEING_REVISED, key, character_name, character_name]
					]
				}
			self.relay_request_mind.emit("update_resource", tag_overset)
	pass

func read_and_overset_tag() -> void:
	var key = Helpers.Utils.exposure_safe_resource_name( TagEditKey.get_text() )
	TagEditKey.set_text(key) # ... so the user can see the safe key if we have changed it
	var value = TagEditValue.get_text()
	if key.length() > 0:
		take_tag_action(3, key, value)
	pass

func clean_all_tags() -> void:
	for node in TagBox.get_children():
		if node is Button:
			node.free()
	pass

func append_tag_to_box(key: String, value: String) -> void:
	var key_value_display = TAG_KEY_VALUE_DISPLAY_TEMPLATE.format({ "key": key, "value": value })
	var the_tag = MenuButton.new()
	the_tag.set_meta("key", key) # CAUTION! `refresh_revision_mode` depends on this
	the_tag.set_text(key)
	the_tag.set_tooltip_text(key_value_display)
	the_tag.set_flat(false)
	var the_popup = the_tag.get_popup()
	the_popup.add_item(key_value_display, 0)
	the_popup.set_item_disabled(0, true)
	the_popup.add_separator("", 0)
	the_popup.add_item("Edit", 1)
	the_popup.add_item("Unset", 2)
	the_popup.id_pressed.connect(self.take_tag_action.bind(key, value), CONNECT_DEFERRED)
	# ...
	TagBox.add_child(the_tag)
	pass

func update_tag_box(character_id:int) -> void:
	clean_all_tags()
	refresh_character_cache_by_id(character_id)
	var the_character = _LISTED_CHARACTERS_BY_ID[character_id]
	var tags_available = (
		the_character is Dictionary && the_character.has("tags") &&
		the_character.tags is Dictionary && the_character.tags.size() > 0
	)
	if tags_available:
		# print_debug("Character tags available: ", the_character.tags)
		for key in the_character.tags:
			append_tag_to_box(key, the_character.tags[key])
	TagBox.set_visible(tags_available)
	TagNoneMessage.set_visible( ! tags_available )
	pass

func refresh_referrers_list() -> void:
	if _SELECTED_CHARACTER_BEING_EDITED_ID >= 0:
		update_appearance_pagination(_SELECTED_CHARACTER_BEING_EDITED_ID)
	pass

func update_appearance_pagination(character_id:int) -> void:
	CharacterAppearanceGoToButtonPopup.clear()
	_SELECTED_CHARACTER_USER_IDS = []
	_SELECTED_CHARACTER_USERS = Main.Mind.list_referrers(character_id)
	var referrers_size = _SELECTED_CHARACTER_USERS.size()
	if referrers_size > 0 :
		CharacterAppearancePanel.set_visible(true)
		var item_index := 0
		for user_node_id in _SELECTED_CHARACTER_USERS:
			if CharacterAppearanceFilterForScene.is_pressed() == false || Main.Mind.scene_owns_node(user_node_id) != null:
				var user_node = _SELECTED_CHARACTER_USERS[user_node_id]
				_SELECTED_CHARACTER_USER_IDS.append(user_node_id)
				var user_node_name = user_node.name if user_node.has("name") else ("Unnamed - %s" % user_node_id)
				CharacterAppearanceGoToButtonPopup.add_item(user_node_name, user_node_id)
				CharacterAppearanceGoToButtonPopup.set_item_metadata(item_index, user_node_id)
				item_index += 1
		CharacterAppearanceGoToButton.set_text( CHARACTER_APPEARANCE_COUNT_TEMPLATE.format([item_index, referrers_size]) )
		var no_option = (item_index == 0)
		CharacterAppearanceGoToPrevious.set_disabled(no_option)
		CharacterAppearanceGoToButton.set_disabled(no_option)
		CharacterAppearanceGoToNext.set_disabled(no_option)
	else:
		CharacterAppearancePanel.set_visible(false)
	pass
	
func _on_go_to_menu_button_popup_index_pressed(referrer_idx:int) -> void:
	# (We can not use `id_pressed` because currently Godot support is limited to i32 item IDs.)
	var referrer_id = _SELECTED_CHARACTER_USER_IDS[referrer_idx]
	if referrer_id >= 0:
		_CURRENT_LOCATED_REF_ID = referrer_id
		self.relay_request_mind.emit("locate_node_on_grid", {
			"id": referrer_id,
			"highlight": true,
			"force": true, # ... to change open scene
		})
	pass

func _rotate_go_to(direction: int) -> void:
	var count = _SELECTED_CHARACTER_USER_IDS.size()
	if count > 0:
		var current_located_index = _SELECTED_CHARACTER_USER_IDS.find(_CURRENT_LOCATED_REF_ID)
		var goto = max(-1, current_located_index + direction)
		if goto >= count:
			goto = 0
		elif goto < 0:
			goto = count - 1
		# ...
		if goto < count && goto >= 0:
			_on_go_to_menu_button_popup_index_pressed(goto) # also updates _CURRENT_LOCATED_REF_ID
	else:
		_CURRENT_LOCATED_REF_ID = -1
	pass

func submit_character_modification() -> void:
	var the_character_original = _LISTED_CHARACTERS_BY_ID[ _SELECTED_CHARACTER_BEING_EDITED_ID ]
	var resource_updater = {
		"id": _SELECTED_CHARACTER_BEING_EDITED_ID, 
		"modification": {},
		"field": "characters"
	}
	var mod_name  = CharacterEditorName.get_text()
	var mod_color = Helpers.Utils.color_to_rgba_hex(CharacterColorPickerButton.get("color"), false)
	if mod_name.length() > 0 && mod_name != the_character_original.name: # name is changed
		mod_name = Helpers.Utils.exposure_safe_resource_name(mod_name)
		# force using unique name for characters ?
		if Settings.FORCE_UNIQUE_NAMES_FOR_CHARACTERS == false || _LISTED_CHARACTERS_BY_NAME.has(mod_name) == false:
			resource_updater.modification["name"] = mod_name
		else:
			resource_updater.modification["name"] = ( mod_name + Settings.REUSED_CHARACTER_NAMES_AUTO_POSTFIX )
	if mod_color != the_character_original.color: # emphasis-color value is changed
		resource_updater.modification["color"] = mod_color
	if resource_updater.modification.size() > 0 :
		self.relay_request_mind.emit("update_resource", resource_updater)
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
	TagEditKey.set_text("")
	TagEditValue.set_text("")
	pass
	
func _on_characters_list_empty_clicked(_x = null, _y = null) -> void:
	CharactersList.deselect_all()
	_SELECTED_CHARACTER_BEING_EDITED_ID = -1
	refresh_revision_mode(null)
	smartly_toggle_editor()
	pass

func _on_list_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_echo() == false && event.is_pressed() == true:
			if event.is_ctrl_pressed():
				match event.get_keycode():
					KEY_C:
						if event.is_shift_pressed():
							var selected = _SELECTED_CHARACTER_BEING_EDITED_ID
							if selected >= 0:
								self.relay_request_mind.emit("clean_clipboard", null)
								self.relay_request_mind.emit("os_clipboard_push", [[selected], "characters", false])
					KEY_V:
						if event.is_shift_pressed():
							self.relay_request_mind.emit("os_clipboard_pull", [null, null]) # (no moving)
		pass
