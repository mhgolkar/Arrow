# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Inspector :: Macros Tab
extends Control

# Note:
# 'macros' are `scenes` which are marked with `macro: true`,
# and receive special treatments from the editor and runtime(s)

signal relay_request_mind()

@onready var Main = get_tree().get_root().get_child(0)
@onready var Grid = $/root/Main/Editor/Center/Grid

var _LISTED_MACROS_BY_ID = {}
var _LISTED_MACROS_BY_NAME = {}

# The macro that is open in the editor (not selected one in the list)
# > You can use `get_selected_macro_id()` for the selected one
var _SELECTED_MACRO_BEING_EDITED_ID = -1

var _SELECTED_MACRO_USERS = {} # id: {id, resource, map}
var _SELECTED_MACRO_USER_IDS = []

var _CURRENT_LOCATED_REF_ID = -1

@onready var Filter = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Filters/Input
@onready var FilterReverse = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Filters/Reverse
@onready var FilterForScene = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Filters/Scoped
@onready var SortAlphabetical = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Filters/Alphabetical

@onready var MacrosList = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Listing/Items
@onready var MacroEntryNote = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Listing/Description

@onready var MacroEditorBox = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Configs
@onready var MacroRawUid = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Configs/Uid
@onready var MacroEditorName = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Configs/Name
@onready var MacroEditorUpdateButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Configs/Set

@onready var MacroInstancePanel = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Instances
@onready var MacroInstanceGoToButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Instances/Referrers
@onready var MacroInstanceGoToButtonPopup = MacroInstanceGoToButton.get_popup()
@onready var MacroInstanceGoToPrevious = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Instances/Previous
@onready var MacroInstanceGoToNext = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Instances/Next
@onready var MacroInstanceFilterForScene = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Instances/Scoped

@onready var MacrosNewButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Actions/New
@onready var MacrosRemoveButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Actions/Remove
@onready var MacrosEditButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Macros/Manager/Actions/Open

const MACRO_USERS_COUNT_TEMPLATE = "{0} [{1}]"
const RAW_UID_TIP_TEMPLATE = "UID: %s"

func _ready() -> void:
	register_connections()
	MacroInstanceGoToButtonPopup.set_allow_search(true)
	pass

func register_connections() -> void:
	MacrosList.item_selected.connect(self._on_macros_list_item_selected, CONNECT_DEFERRED)
	MacrosList.item_activated.connect(self.request_macro_editorial_open, CONNECT_DEFERRED)
	MacrosList.empty_clicked.connect(self._on_macros_list_empty_clicked, CONNECT_DEFERRED)
	MacrosList.gui_input.connect(self._on_list_gui_input, CONNECT_DEFERRED)
	MacrosNewButton.pressed.connect(self.request_new_macro_creation, CONNECT_DEFERRED)
	MacrosRemoveButton.pressed.connect(self.request_remove_macro, CONNECT_DEFERRED)
	MacrosEditButton.pressed.connect(self.request_macro_editorial_open, CONNECT_DEFERRED)
	MacroRawUid.pressed.connect(self.os_clipboard_push_raw_uid, CONNECT_DEFERRED)
	MacroEditorUpdateButton.pressed.connect(self.submit_macro_modification, CONNECT_DEFERRED)
	MacroInstanceGoToButtonPopup.index_pressed.connect(self._on_go_to_menu_button_popup_index_pressed, CONNECT_DEFERRED)
	MacroInstanceGoToPrevious.pressed.connect(self._rotate_go_to.bind(-1), CONNECT_DEFERRED)
	MacroInstanceGoToNext.pressed.connect(self._rotate_go_to.bind(1), CONNECT_DEFERRED)
	MacroInstanceFilterForScene.pressed.connect(self.refresh_referrers_list, CONNECT_DEFERRED)
	Filter.text_changed.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	FilterReverse.toggled.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	FilterForScene.toggled.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	SortAlphabetical.toggled.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	pass

func initialize_tab() -> void:
	refresh_tab()
	pass

func refresh_tab() -> void:
	refresh_macros_list()
	update_macro_editorial_state(-1) # -1 = reset to no-edit mode
	pass

func refresh_macros_list(list:Dictionary = {}) -> void:
	MacrosList.clear()
	_LISTED_MACROS_BY_ID.clear()
	_LISTED_MACROS_BY_NAME.clear()
	if list.size() == 0 :
		# fetch the macros dataset if it's not provided as parameter
		list = Main.Mind.clone_dataset_of("scenes", { "macro": true })
	list_macros(list)
	MacrosList.deselect_all()
	smartly_update_tools()
	update_macro_notes()
	pass

func _on_listing_instruction_change(_x = null) -> void:
	refresh_macros_list()
	pass

func read_listing_instruction() -> Dictionary:
	return {
		"FILTER": Filter.get_text(),
		"FILTER_REVERSE": FilterReverse.is_pressed(),
		"FILTER_FOR_SCENE": FilterForScene.is_pressed(),
		"SORT_ALPHABETICAL": SortAlphabetical.is_pressed(),
	}

func passes_filters(instruction: Dictionary, macro_id: int, macro: Dictionary) -> bool:
	if Helpers.Utils.filter_pass(macro.name, instruction.FILTER, instruction.FILTER_REVERSE):
		if instruction.FILTER_FOR_SCENE == false || Main.Mind.resource_is_used_in_scene(macro_id, "scenes"):
			return true
	return false

# appends a list of macros to the existing ones
# Note: this won't refresh the current list,
# if a macro exists (by id) it'll be updated, otherwise added
func list_macros(list_to_append:Dictionary) -> void :
	var _LISTING = read_listing_instruction()
	for macro_id in list_to_append:
		var the_macro = list_to_append[macro_id]
		if passes_filters(_LISTING, macro_id, the_macro):
			if _LISTED_MACROS_BY_ID.has(macro_id):
				update_macro_list_item(macro_id, the_macro)
			else:
				insert_macro_list_item(macro_id, the_macro)
	MacrosList.ensure_current_is_visible()
	if _LISTING.SORT_ALPHABETICAL:
		MacrosList.call_deferred("sort_items_by_text")
	pass

func unlist_macros(id_list:Array) -> void :
	MacrosList.deselect_all()
	# remove items from the list
	# Note: to avoid conflicts, we remove from end, because the indices may change otherwise and disturb the job.
	var idx = ( MacrosList.get_item_count() - 1 )
	while idx >= 0:
		if id_list.has( MacrosList.get_item_metadata(idx) ):
			MacrosList.remove_item(idx)
		idx = (idx - 1)
	# also clean from the references
	for macro_id in id_list:
		dereference_listed_macros(macro_id)
	pass
	
func reference_listed_macros(macro_id:int, the_macro:Dictionary) -> void:
	# is it previously referenced ?
	if _LISTED_MACROS_BY_ID.has(macro_id): # if so, attempt some cleanup
		var previously_referenced = _LISTED_MACROS_BY_ID[macro_id]
		# the id never changes but names change, so we need to remove previously kept reference by name
		if previously_referenced.name != the_macro.name: # if the name is changed
			# to avoid the false notion that the old name is still in use
			_LISTED_MACROS_BY_NAME.erase(previously_referenced.name)
	# now we can update or create the references
	_LISTED_MACROS_BY_ID[macro_id] = the_macro
	_LISTED_MACROS_BY_NAME[the_macro.name] = _LISTED_MACROS_BY_ID[macro_id]
	pass

func dereference_listed_macros(macro_id:int) -> void:
	if _LISTED_MACROS_BY_ID.has(macro_id):
		_LISTED_MACROS_BY_NAME.erase( _LISTED_MACROS_BY_ID[macro_id].name )
		_LISTED_MACROS_BY_ID.erase(macro_id)
	if _SELECTED_MACRO_BEING_EDITED_ID == macro_id:
		update_macro_editorial_state(-1)
	pass
	
func insert_macro_list_item(macro_id:int, the_macro:Dictionary) -> void:
	reference_listed_macros(macro_id, the_macro)
	# insert the macro as list item
	MacrosList.add_item( the_macro.name )
	# we need to keep track of ids in metadata
	# the item is added last, so...
	var item_index = (MacrosList.get_item_count() - 1)
	MacrosList.set_item_metadata(item_index, macro_id)
	pass

func update_macro_list_item(macro_id:int, the_macro:Dictionary) -> void:
	reference_listed_macros(macro_id, the_macro)
	for idx in range(0, MacrosList.get_item_count()):
		if MacrosList.get_item_metadata(idx) == macro_id:
			# found it, update...
			MacrosList.set_item_text(idx, the_macro.name)
			if _SELECTED_MACRO_BEING_EDITED_ID == macro_id:
				MacroEditorName.set_text(the_macro.name)
			return
	printerr("Unexpected Behavior! Trying to update macro=%s which is not found in the list!")
	pass

func _on_macros_list_item_selected(idx:int) -> void:
	var macro_id = MacrosList.get_item_metadata(idx)
	smartly_update_tools(macro_id)
	update_macro_notes(macro_id)
	pass

func _on_macros_list_empty_clicked(_x = null, _y = null) -> void:
	MacrosList.deselect_all()
	smartly_update_tools()
	update_macro_notes()
	pass
	
func get_selected_macro_id() -> int:
	var selection = MacrosList.get_selected_items()
	if selection.size() > 0:
		var selected_idx = selection[0]
		var selected_macro_id = MacrosList.get_item_metadata(selected_idx)
		return selected_macro_id 
	return -1

func smartly_update_tools(selected_macro_id:int = -1) -> void:
	var a_macro_is_selected = MacrosList.is_anything_selected()
	var selected_macro_is_removable = false
	if a_macro_is_selected:
		if selected_macro_id < 0:
			selected_macro_id = get_selected_macro_id()
		if _LISTED_MACROS_BY_ID.has(selected_macro_id):
			var the_macro = _LISTED_MACROS_BY_ID[selected_macro_id]
			if (
				the_macro.has("use") && the_macro.use is Array && the_macro.use.size() > 0 ||
				selected_macro_id == _SELECTED_MACRO_BEING_EDITED_ID
			):
				selected_macro_is_removable = false
			else:
				selected_macro_is_removable = true
	MacrosEditButton.set_disabled( (! a_macro_is_selected) || (selected_macro_id == _SELECTED_MACRO_BEING_EDITED_ID) )
	MacrosRemoveButton.set_disabled( (!a_macro_is_selected) || (!selected_macro_is_removable) )
	MacroEditorBox.set_visible( a_macro_is_selected && selected_macro_id == _SELECTED_MACRO_BEING_EDITED_ID )
	update_instance_pagination(selected_macro_id)
	pass

func update_macro_notes(macro_id: int = -1) -> void:
	MacroEntryNote.set_visible(false)
	if macro_id < 0:
		if MacrosList.is_anything_selected():
			macro_id = get_selected_macro_id()
	if macro_id >= 0:
		var the_scene = Main.Mind.lookup_resource(macro_id, "scenes", false)
		if the_scene is Dictionary && the_scene.has("entry"):
			var the_entry = Main.Mind.lookup_resource(the_scene.entry, "nodes", false)
			if the_entry is Dictionary && the_entry.has("notes"):
				if the_entry.notes is String && the_entry.notes.length() > 0:
					MacroEntryNote.set_deferred("text", the_entry.notes)
					MacroEntryNote.set_deferred("visible", true)
	pass

func request_new_macro_creation() -> void:
	self.relay_request_mind.emit("create_scene", true)
	# args: `true = is_macro` otherwise normal scene
	pass

func request_remove_macro(resource_id:int = -1) -> void:
	if resource_id < 0 : # default to the selected one
		resource_id = get_selected_macro_id()
	# make sure this is an existing macro resource before removing it
	if _LISTED_MACROS_BY_ID.has(resource_id):
		if resource_id == _SELECTED_MACRO_BEING_EDITED_ID:
			request_macro_editorial_close()
		prompt_to_request_macro_removal(resource_id)
	MacrosList.deselect_all()
	pass

func prompt_to_request_macro_removal(macro_id:int = -1) -> void:
	if macro_id >= 0:
		var macro_name = _LISTED_MACROS_BY_ID[macro_id].name
		Main.Mind.Notifier.call_deferred(
			"show_notification",
			"Are you sure ?",
			(
				tr("RESOURCE_PERMANENT_REMOVAL_WARNING")
				.format({
					"field_name": tr("MACROS_FIELD_NAME"),
					"res_name": macro_name,
				})
			),
			[
				{ 
					"label": "Yes, Remove",
					"callee": self,
					"method": "emit_signal",
					"arguments": [
						"relay_request_mind", "remove_resource",
						{ "id": macro_id, "field": "scenes" }
					]
				},
			],
			Settings.WARNING_COLOR
		)
	pass

func request_macro_editorial_open(_x = null) -> void:
	var macro_id = get_selected_macro_id()
	if macro_id >= 0 :
		self.relay_request_mind.emit("switch_scene", macro_id)
	pass

func select_list_item_by_macro_id(macro_id:int = -1, unselect_all:bool = false) -> void:
	if unselect_all:
		MacrosList.deselect_all()
	if macro_id >= 0:
		for idx in range(0, MacrosList.get_item_count()):
			if MacrosList.get_item_metadata(idx) == macro_id:
				MacrosList.select(idx, true)
				break
	pass

func update_macro_editorial_state(macro_id:int = -1) -> void:
	MacroEditorName.clear()
	if macro_id < 0:
		var macro_or_scene_id = Main.Mind.get_current_open_scene_id()
		if _LISTED_MACROS_BY_ID.has(macro_or_scene_id):
			macro_id = macro_or_scene_id
	if macro_id >= 0 && _LISTED_MACROS_BY_ID.has(macro_id):
		_SELECTED_MACRO_BEING_EDITED_ID = macro_id
		var the_macro = _LISTED_MACROS_BY_ID[macro_id]
		MacroRawUid.set_deferred("tooltip_text", (RAW_UID_TIP_TEMPLATE % macro_id) + tr("TYPE_INSPECTOR_RAW_UID_HINT"))
		MacroEditorName.set_text(the_macro.name)
		# MacroEditorBox.set("visible", true) # moved to `smartly_update_tools`
		# this may be called by other scripts, so let's reselect the open macro
		select_list_item_by_macro_id(macro_id)
	else:
		_SELECTED_MACRO_BEING_EDITED_ID = -1
		# MacroEditorBox.set("visible", false)
	smartly_update_tools()
	update_macro_notes()
	pass

func request_macro_editorial_close() -> void:
	if _SELECTED_MACRO_BEING_EDITED_ID >= 0:
		self.relay_request_mind.emit("switch_scene", -1)
	pass

func refresh_macro_cache_by_id(macro_id:int = -1) -> void:
	if macro_id >= 0 :
		var the_macro = Main.Mind.lookup_resource(macro_id, "scenes", true)
		if the_macro is Dictionary:
			_LISTED_MACROS_BY_ID[macro_id] = the_macro
			_LISTED_MACROS_BY_NAME[the_macro.name] = _LISTED_MACROS_BY_ID[macro_id]
	pass

func os_clipboard_push_raw_uid():
	DisplayServer.clipboard_set( String.num_int64(_SELECTED_MACRO_BEING_EDITED_ID) )
	pass

func refresh_referrers_list() -> void:
	var macro_id = get_selected_macro_id()
	if macro_id >= 0:
		update_instance_pagination(macro_id)
	pass

func update_instance_pagination(macro_id:int = -1) -> void:
	MacroInstanceGoToButtonPopup.clear()
	_SELECTED_MACRO_USER_IDS = []
	_SELECTED_MACRO_USERS = Main.Mind.list_referrers(macro_id)
	var referrers_size = _SELECTED_MACRO_USERS.size()
	if referrers_size > 0 :
		MacroInstancePanel.set_visible(true)
		var item_index := 0
		for user_node_id in _SELECTED_MACRO_USERS:
			if MacroInstanceFilterForScene.is_pressed() == false || Main.Mind.scene_owns_node(user_node_id) != null:
				var user_node = _SELECTED_MACRO_USERS[user_node_id]
				_SELECTED_MACRO_USER_IDS.append(user_node_id)
				var user_node_name = user_node.name if user_node.has("name") else ("Unnamed - %s" % user_node_id)
				MacroInstanceGoToButtonPopup.add_item(user_node_name, user_node_id)
				MacroInstanceGoToButtonPopup.set_item_metadata(item_index, user_node_id)
				item_index += 1
		MacroInstanceGoToButton.set_text( MACRO_USERS_COUNT_TEMPLATE.format([item_index, referrers_size]) )
		var no_option = (item_index == 0)
		MacroInstanceGoToPrevious.set_disabled(no_option)
		MacroInstanceGoToButton.set_disabled(no_option)
		MacroInstanceGoToNext.set_disabled(no_option)
	else:
		MacroInstancePanel.set_visible(false)
	pass

func _on_go_to_menu_button_popup_index_pressed(referrer_idx:int) -> void:
	# (We can not use `id_pressed` because currently Godot support is limited to i32 item IDs.)
	var referrer_id = _SELECTED_MACRO_USER_IDS[referrer_idx]
	if referrer_id >= 0:
		_CURRENT_LOCATED_REF_ID = referrer_id
		self.relay_request_mind.emit("locate_node_on_grid", {
			"id": referrer_id,
			"highlight": true,
			"force": true, # ... to change open scene
		})
	pass

func _rotate_go_to(direction: int) -> void:
	var count = _SELECTED_MACRO_USER_IDS.size()
	if count > 0:
		var current_located_index = _SELECTED_MACRO_USER_IDS.find(_CURRENT_LOCATED_REF_ID)
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

func submit_macro_modification() -> void:
	var the_macro_original = _LISTED_MACROS_BY_ID[ _SELECTED_MACRO_BEING_EDITED_ID ]
	var resource_updater = {
		"id": _SELECTED_MACRO_BEING_EDITED_ID, 
		"modification": {},
		"field": "scenes"
	}
	var mod_name = MacroEditorName.get_text()
	if mod_name.length() > 0 && mod_name != the_macro_original.name: # name is changed
		# force using unique name for macros ?
		while Settings.FORCE_UNIQUE_NAMES_FOR_SCENES_AND_MACROS && Main.Mind.is_resource_name_duplicate(mod_name, "scenes"):
			mod_name = ( mod_name + Settings.REUSED_SCENE_OR_MACRO_NAMES_AUTO_POSTFIX )
		resource_updater.modification["name"] = mod_name
	if resource_updater.modification.size() > 0 :
		self.relay_request_mind.emit("update_resource", resource_updater)
	pass

func _on_list_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_echo() == false && event.is_pressed() == true:
			if event.is_ctrl_pressed():
				match event.get_keycode():
					KEY_C:
						if event.is_shift_pressed():
							var selected = get_selected_macro_id()
							if selected >= 0:
								self.relay_request_mind.emit("clean_clipboard", null)
								self.relay_request_mind.emit("os_clipboard_push", [[selected], "scenes", false])
					KEY_V:
						if event.is_shift_pressed():
							self.relay_request_mind.emit("os_clipboard_pull", [null, null]) # (no moving)
		pass
