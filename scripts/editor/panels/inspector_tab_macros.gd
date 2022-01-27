# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Inspector :: Macros Tab
extends Tabs

# Note:
# 'macros' are `scenes` which are marked with `macro: true`,
# and receive special treatments from the editor and runtime(s)

signal relay_request_mind

onready var Main = get_tree().get_root().get_child(0)
onready var Grid = get_node(Addressbook.GRID)

var _LISTED_MACROS_BY_ID = {}
var _LISTED_MACROS_BY_NAME = {}

var _SELECTED_MACRO_BEING_EDITED_ID = -1
var _SELECTED_MACRO_INSTANCES_IN_THE_SCENE_BY_ID = []

onready var MacrosList = get_node(Addressbook.INSPECTOR.MACROS.MACROS_LIST)
onready var MacroEntryNote = get_node(Addressbook.INSPECTOR.MACROS.MACRO_ENTRY_NOTE)

onready var MacrosNewButton = get_node(Addressbook.INSPECTOR.MACROS.TOOLS.NEW_BUTTON)
onready var MacrosRemoveButton = get_node(Addressbook.INSPECTOR.MACROS.TOOLS.REMOVE_BUTTON)
onready var MacrosEditButton = get_node(Addressbook.INSPECTOR.MACROS.TOOLS.EDIT_BUTTON)

onready var MacroEditorPanel = get_node(Addressbook.INSPECTOR.MACROS.EDIT.itself)
onready var MacroEditorName = get_node(Addressbook.INSPECTOR.MACROS.EDIT.NAME_EDIT)
onready var MacroEditorUpdateButton = get_node(Addressbook.INSPECTOR.MACROS.EDIT.UPDATE_BUTTON)
onready var MacroEditorCloseButton = get_node(Addressbook.INSPECTOR.MACROS.EDIT.CLOSE_BUTTON)

onready var MacroInstancePanel = get_node(Addressbook.INSPECTOR.MACROS.MACRO_INSTANCES.itself)
onready var MacroInstanceIndication = get_node(Addressbook.INSPECTOR.MACROS.MACRO_INSTANCES.INDICATION)
onready var MacroInstanceGoToButton = get_node(Addressbook.INSPECTOR.MACROS.MACRO_INSTANCES.GO_TO_MENU_BUTTON)
onready var MacroInstanceGoToButtonPopup = MacroInstanceGoToButton.get_popup()
const MACRO_INSTANCE_INDICATION_TEMPLATE = "{here}:{total}"

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	MacrosList.connect("item_selected", self, "_on_macros_list_item_selected", [], CONNECT_DEFERRED)
	MacrosList.connect("item_activated", self, "request_macro_editorial_open", [], CONNECT_DEFERRED)
	MacrosList.connect("nothing_selected", self, "_on_macros_list_nothing_selected", [], CONNECT_DEFERRED)
	MacrosNewButton.connect("pressed", self, "request_new_macro_creation", [], CONNECT_DEFERRED)
	MacrosRemoveButton.connect("pressed", self, "request_remove_macro", [], CONNECT_DEFERRED)
	MacrosEditButton.connect("pressed", self, "request_macro_editorial_open", [], CONNECT_DEFERRED)
	MacroEditorUpdateButton.connect("pressed", self, "submit_macro_modification", [], CONNECT_DEFERRED)
	MacroEditorCloseButton.connect("pressed", self, "request_macro_editorial_close", [], CONNECT_DEFERRED)
	MacroInstanceGoToButtonPopup.connect("id_pressed", self, "_on_go_to_menu_button_popup_id_pressed", [], CONNECT_DEFERRED)
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
	MacrosList.unselect_all()
	smartly_update_tools()
	update_macro_notes()
	pass

# appends a list of macros to the existing ones
# Note: this won't refresh the current list,
# if a macro exists (by id) it'll be updated, otherwise added
func list_macros(list_to_append:Dictionary) -> void :
	for macro_id in list_to_append:
		var the_macro = list_to_append[macro_id]
		if _LISTED_MACROS_BY_ID.has(macro_id):
			update_macro_list_item(macro_id, the_macro)
		else:
			insert_macro_list_item(macro_id, the_macro)
	MacrosList.ensure_current_is_visible()
	pass

func unlist_macros(id_list:Array) -> void :
	MacrosList.unselect_all()
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
			return
	printerr("Unexpected Behavior! Trying to update macro=%s which is not found in the list!")
	pass

func _on_macros_list_item_selected(idx:int) -> void:
	var macro_id = MacrosList.get_item_metadata(idx)
	smartly_update_tools(macro_id)
	update_macro_notes(macro_id)
	pass

func _on_macros_list_nothing_selected() -> void:
	MacrosList.unselect_all()
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
					MacroEntryNote.clear()
					if MacroEntryNote.append_bbcode(the_entry.notes) != OK:
						MacroEntryNote.set_text(the_entry.notes)
					MacroEntryNote.set_deferred("visible", true)
	pass

func request_new_macro_creation() -> void:
	self.emit_signal("relay_request_mind", "create_scene", true)
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
	MacrosList.unselect_all()
	pass

func prompt_to_request_macro_removal(macro_id:int = -1) -> void:
	if macro_id >= 0:
		var macro_name = _LISTED_MACROS_BY_ID[macro_id].name
		Main.Mind.Notifier.call_deferred(
			"show_notification",
			"Are you sure ?",
			(
				"You're removing the macro `%s`, permanently.\n" % macro_name +
				"Would you like to proceed?"
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
		emit_signal("relay_request_mind", "switch_scene", macro_id)
	pass

func select_list_item_by_macro_id(macro_id:int = -1, unselect_all:bool = false) -> void:
	if unselect_all:
		MacrosList.unselect_all()
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
		MacroEditorName.set_text(the_macro.name)
		MacroEditorPanel.set("visible", true)
		# this may be called by other scripts, so let's reselect the open macro
		select_list_item_by_macro_id(macro_id)
	else:
		_SELECTED_MACRO_BEING_EDITED_ID = -1
		MacroEditorPanel.set("visible", false)
	smartly_update_tools()
	update_macro_notes()
	pass

func request_macro_editorial_close() -> void:
	if _SELECTED_MACRO_BEING_EDITED_ID >= 0:
		emit_signal("relay_request_mind", "switch_scene", -1)
	pass

func refresh_macro_cache_by_id(macro_id:int = -1) -> void:
	if macro_id >= 0 :
		var the_macro = Main.Mind.lookup_resource(macro_id, "scenes", true)
		if the_macro is Dictionary:
			_LISTED_MACROS_BY_ID[macro_id] = the_macro
			_LISTED_MACROS_BY_NAME[the_macro.name] = _LISTED_MACROS_BY_ID[macro_id]
	pass

func update_instance_pagination(macro_id:int = -1) -> void:
	if macro_id >= 0 && _LISTED_MACROS_BY_ID.has(macro_id):
		refresh_macro_cache_by_id(macro_id)
		_SELECTED_MACRO_INSTANCES_IN_THE_SCENE_BY_ID.clear()
		MacroInstanceGoToButtonPopup.clear()
		var count = {
			"total": 0,
			"here": 0
		}
		var the_macro = _LISTED_MACROS_BY_ID[macro_id]
		if the_macro.has("use"):
			for referrer_id in the_macro.use:
				if Grid._DRAWN_NODES_BY_ID.has(referrer_id):
					_SELECTED_MACRO_INSTANCES_IN_THE_SCENE_BY_ID.append(referrer_id)
			count.total = the_macro.use.size()
			count.here = _SELECTED_MACRO_INSTANCES_IN_THE_SCENE_BY_ID.size()
		# update stuff
		MacroInstanceIndication.set_text( MACRO_INSTANCE_INDICATION_TEMPLATE.format(count) )
		if count.here > 0 :
			for referrer_id in _SELECTED_MACRO_INSTANCES_IN_THE_SCENE_BY_ID:
				MacroInstanceGoToButtonPopup.add_item(
					Grid._DRAWN_NODES_BY_ID[referrer_id]._node_resource.name,
					referrer_id
				)
		MacroInstanceGoToButton.set_disabled( ! (count.here > 0) )
		MacroInstancePanel.set("visible", true)
	else:
		MacroInstancePanel.set("visible", false)
	pass

func _on_go_to_menu_button_popup_id_pressed(referrer_id:int) -> void:
	Grid.call_deferred("go_to_offset_by_node_id", referrer_id, true)
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
		if Settings.FORCE_UNIQUE_NAMES_FOR_MACROS == false || _LISTED_MACROS_BY_NAME.has(mod_name) == false:
			resource_updater.modification["name"] = mod_name
		else:
			resource_updater.modification["name"] = ( mod_name + Settings.REUSED_MACRO_NAMES_AUTO_POSTFIX )
	if resource_updater.modification.size() > 0 :
		self.emit_signal("relay_request_mind", "update_resource", resource_updater)
	pass
