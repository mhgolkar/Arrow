# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Inspector :: Scenes Tab
extends Control

signal relay_request_mind()

@onready var Main = get_tree().get_root().get_child(0)

var _LISTED_SCENES_BY_ID = {}
var _LISTED_SCENES_BY_NAME = {}

var _SELECTED_SCENE_BEING_EDITED_ID = -1

@onready var Filter = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Scenes/Manager/Filters/Input
@onready var FilterReverse = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Scenes/Manager/Filters/Reverse
@onready var SortAlphabetical = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Scenes/Manager/Filters/Alphabetical

@onready var ScenesList = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Scenes/Manager/Listing/Items
@onready var SceneEntryNote = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Scenes/Manager/Listing/Description

@onready var SceneEditorBox = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Scenes/Manager/Configs
@onready var SceneRawUid = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Scenes/Manager/Configs/Uid
@onready var SceneEditorName = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Scenes/Manager/Configs/Name
@onready var SceneEditorUpdateButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Scenes/Manager/Configs/Set

@onready var ScenesNewButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Scenes/Manager/Actions/New
@onready var ScenesRemoveButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Scenes/Manager/Actions/Remove
@onready var ScenesEditButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Scenes/Manager/Actions/Open

const RAW_UID_TIP_TEMPLATE = "UID: %s"

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	ScenesList.item_selected.connect(self._on_scenes_list_item_selected, CONNECT_DEFERRED)
	ScenesList.item_activated.connect(self.request_scene_editorial_open, CONNECT_DEFERRED)
	ScenesList.empty_clicked.connect(self._on_scenes_list_empty_clicked, CONNECT_DEFERRED)
	ScenesList.gui_input.connect(self._on_list_gui_input, CONNECT_DEFERRED)
	ScenesNewButton.pressed.connect(self.request_new_scene_creation, CONNECT_DEFERRED)
	ScenesRemoveButton.pressed.connect(self.request_remove_scene, CONNECT_DEFERRED)
	ScenesEditButton.pressed.connect(self.request_scene_editorial_open, CONNECT_DEFERRED)
	SceneRawUid.pressed.connect(self.os_clipboard_push_raw_uid, CONNECT_DEFERRED)
	SceneEditorUpdateButton.pressed.connect(self.submit_scene_modification, CONNECT_DEFERRED)
	Filter.text_changed.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	FilterReverse.toggled.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	SortAlphabetical.toggled.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	pass

func initialize_tab() -> void:
	refresh_tab()
	pass

func refresh_tab() -> void:
	refresh_scenes_list()
	update_scene_editorial_state(-1) # -1 = reset to no-edit mode
	pass

func refresh_scenes_list(list:Dictionary = {}) -> void:
	ScenesList.clear()
	_LISTED_SCENES_BY_ID.clear()
	_LISTED_SCENES_BY_NAME.clear()
	if list.size() == 0 :
		# fetch the scenes dataset if it's not provided as parameter
		list = Main.Mind.clone_dataset_of("scenes", {}, { "macro": null })
	list_scenes(list)
	ScenesList.deselect_all()
	smartly_update_tools()
	update_scene_notes()
	pass

func _on_listing_instruction_change(_x = null) -> void:
	refresh_scenes_list()
	pass

func read_listing_instruction() -> Dictionary:
	return {
		"FILTER": Filter.get_text(),
		"FILTER_REVERSE": FilterReverse.is_pressed(),
		"SORT_ALPHABETICAL": SortAlphabetical.is_pressed(),
	}

# appends a list of scenes to the existing ones
# Note: this won't refresh the current list,
# if a scene exists (by id) it'll be updated, otherwise added
func list_scenes(list_to_append:Dictionary) -> void :
	var _LISTING = read_listing_instruction()
	for scene_id in list_to_append:
		var the_scene = list_to_append[scene_id]
		if Helpers.Utils.filter_pass(the_scene.name, _LISTING.FILTER, _LISTING.FILTER_REVERSE):
			if _LISTED_SCENES_BY_ID.has(scene_id):
				update_scene_list_item(scene_id, the_scene)
			else:
				insert_scene_list_item(scene_id, the_scene)
	ScenesList.ensure_current_is_visible()
	if _LISTING.SORT_ALPHABETICAL:
		ScenesList.call_deferred("sort_items_by_text")
	pass

func unlist_scenes(id_list:Array) -> void :
	ScenesList.deselect_all()
	# remove items from the list
	# Note: to avoid conflicts, we remove from end, because the indices may change otherwise and disturb the job.
	var idx = ( ScenesList.get_item_count() - 1 )
	while idx >= 0:
		if id_list.has( ScenesList.get_item_metadata(idx) ):
			ScenesList.remove_item(idx)
		idx = (idx - 1)
	# also clean from the references
	for scene_id in id_list:
		dereference_listed_scenes(scene_id)
	pass
	
func reference_listed_scenes(scene_id:int, the_scene:Dictionary) -> void:
	# is it previously referenced ?
	if _LISTED_SCENES_BY_ID.has(scene_id): # if so, attempt some cleanup
		var previously_referenced = _LISTED_SCENES_BY_ID[scene_id]
		# the id never changes but names change, so we need to remove previously kept reference by name
		if previously_referenced.name != the_scene.name: # if the name is changed
			# ... to avoid the false notion that the old name is still in use
			_LISTED_SCENES_BY_NAME.erase(previously_referenced.name)
	# now we can update or create the references
	_LISTED_SCENES_BY_ID[scene_id] = the_scene
	_LISTED_SCENES_BY_NAME[the_scene.name] = _LISTED_SCENES_BY_ID[scene_id]
	pass

func dereference_listed_scenes(scene_id:int) -> void:
	if _LISTED_SCENES_BY_ID.has(scene_id):
		_LISTED_SCENES_BY_NAME.erase( _LISTED_SCENES_BY_ID[scene_id].name )
		_LISTED_SCENES_BY_ID.erase(scene_id)
	if _SELECTED_SCENE_BEING_EDITED_ID == scene_id:
		update_scene_editorial_state(-1)
	pass
	
func insert_scene_list_item(scene_id:int, the_scene:Dictionary) -> void:
	reference_listed_scenes(scene_id, the_scene)
	# insert the scene as list item
	ScenesList.add_item( the_scene.name )
	# we need to keep track of ids in metadata
	# the item is added last, so...
	var item_index = (ScenesList.get_item_count() - 1)
	ScenesList.set_item_metadata(item_index, scene_id)
	pass

func update_scene_list_item(scene_id:int, the_scene:Dictionary) -> void:
	reference_listed_scenes(scene_id, the_scene)
	for idx in range(0, ScenesList.get_item_count()):
		if ScenesList.get_item_metadata(idx) == scene_id:
			# found it, update...
			ScenesList.set_item_text(idx, the_scene.name)
			if _SELECTED_SCENE_BEING_EDITED_ID == scene_id:
				SceneEditorName.set_text(the_scene.name)
			return
	printerr("Unexpected Behavior! Trying to update scene=%s which is not found in the list!")
	pass

func _on_scenes_list_item_selected(idx:int) -> void:
	var scene_id = ScenesList.get_item_metadata(idx)
	smartly_update_tools(scene_id)
	update_scene_notes(scene_id)
	pass

func _on_scenes_list_empty_clicked(_x = null, _y = null) -> void:
	ScenesList.deselect_all()
	smartly_update_tools()
	update_scene_notes()
	pass
	
func get_selected_scene_id() -> int:
	var selection = ScenesList.get_selected_items()
	if selection.size() > 0:
		var selected_idx = selection[0]
		var selected_scene_id = ScenesList.get_item_metadata(selected_idx)
		return selected_scene_id 
	return -1

func smartly_update_tools(selected_scene_id:int = -1) -> void:
	var a_scene_is_selected = ScenesList.is_anything_selected()
	var selected_scene_is_removable = false
	if a_scene_is_selected:
		if selected_scene_id < 0:
			selected_scene_id = get_selected_scene_id()
		if _LISTED_SCENES_BY_ID.has(selected_scene_id):
			var the_scene = _LISTED_SCENES_BY_ID[selected_scene_id]
			# you can't remove the last existing scene or the one including the project's entry point
			var the_project_entry = Main.Mind.get_project_entry()
			if (
				_LISTED_SCENES_BY_ID.size() <= 1 || the_scene.map.has(the_project_entry) ||
				selected_scene_id == _SELECTED_SCENE_BEING_EDITED_ID
			):
				selected_scene_is_removable = false
			else:
				selected_scene_is_removable = true
	ScenesEditButton.set_disabled( (! a_scene_is_selected) || (selected_scene_id == _SELECTED_SCENE_BEING_EDITED_ID) )
	ScenesRemoveButton.set_disabled( (!a_scene_is_selected) || (!selected_scene_is_removable) )
	SceneEditorBox.set_visible( a_scene_is_selected && selected_scene_id == _SELECTED_SCENE_BEING_EDITED_ID )
	pass

func update_scene_notes(scene_id: int = -1) -> void:
	SceneEntryNote.set_visible(false)
	if scene_id < 0:
		if ScenesList.is_anything_selected():
			scene_id = get_selected_scene_id()
	if scene_id >= 0:
		var the_scene = Main.Mind.lookup_resource(scene_id, "scenes", false)
		if the_scene is Dictionary && the_scene.has("entry"):
			var the_entry = Main.Mind.lookup_resource(the_scene.entry, "nodes", false)
			if the_entry is Dictionary && the_entry.has("notes"):
				if the_entry.notes is String && the_entry.notes.length() > 0:
					SceneEntryNote.set_deferred("text", the_entry.notes)
					SceneEntryNote.set_deferred("visible", true)
	pass

func request_new_scene_creation() -> void:
	self.relay_request_mind.emit("create_scene", false)
	# passed args: `true = is_macro` otherwise normal scene
	pass

func request_remove_scene(resource_id:int = -1) -> void:
	if resource_id < 0 : # default to the selected one
		resource_id = get_selected_scene_id()
	# make sure this is an existing scene resource before removing it
	if _LISTED_SCENES_BY_ID.size() >= 2 : # Note: Every project must have at least one scene.
		if _LISTED_SCENES_BY_ID.has(resource_id):
			if resource_id == _SELECTED_SCENE_BEING_EDITED_ID:
				printerr("Unable to remove open scene!")
			else:
				prompt_to_request_scene_removal(resource_id)
	ScenesList.deselect_all()
	pass

func prompt_to_request_scene_removal(scene_id:int = -1) -> void:
	if scene_id >= 0:
		var scene_name = _LISTED_SCENES_BY_ID[scene_id].name
		Main.Mind.Notifier.call_deferred(
			"show_notification",
			"Are you sure ?",
			(
				tr("RESOURCE_PERMANENT_REMOVAL_WARNING")
				.format({
					"field_name": tr("SCENES_FIELD_NAME"),
					"res_name": scene_name,
				})
			),
			[
				{ 
					"label": "Yes, Remove",
					"callee": self,
					"method": "emit_signal",
					"arguments": [
						"relay_request_mind", "remove_resource",
						{ "id": scene_id, "field": "scenes" }
					]
				},
			],
			Settings.WARNING_COLOR
		)
	pass

func request_scene_editorial_open(_x = null) -> void:
	var scene_id = get_selected_scene_id()
	if scene_id >= 0 :
		self.relay_request_mind.emit("switch_scene", scene_id)
	pass
	
func select_list_item_by_scene_id(scene_id:int = -1, unselect_all:bool = false) -> void:
	if unselect_all:
		ScenesList.deselect_all()
	if scene_id >= 0:
		for idx in range(0, ScenesList.get_item_count()):
			if ScenesList.get_item_metadata(idx) == scene_id:
				ScenesList.select(idx, true)
				break
	pass

func update_scene_editorial_state(scene_id:int = -1) -> void:
	SceneEditorName.clear()
	if scene_id < 0:
		var scene_or_macro_id = Main.Mind.get_current_open_scene_id()
		if _LISTED_SCENES_BY_ID.has(scene_or_macro_id):
			scene_id = scene_or_macro_id
	if scene_id >= 0 && _LISTED_SCENES_BY_ID.has(scene_id):
		_SELECTED_SCENE_BEING_EDITED_ID = scene_id
		var the_scene = _LISTED_SCENES_BY_ID[scene_id]
		SceneRawUid.set_deferred("tooltip_text", (RAW_UID_TIP_TEMPLATE % scene_id) + tr("TYPE_INSPECTOR_RAW_UID_HINT"))
		SceneEditorName.set_text(the_scene.name)
		# SceneEditorBox.set("visible", true) # moved to `smartly_update_tools`
		# this may be called by other scripts, so let's reselect the open scene
		select_list_item_by_scene_id(scene_id)
	else:
		_SELECTED_SCENE_BEING_EDITED_ID = -1
		# SceneEditorBox.set("visible", false)
	smartly_update_tools()
	update_scene_notes()
	pass

func os_clipboard_push_raw_uid():
	DisplayServer.clipboard_set( String.num_int64(_SELECTED_SCENE_BEING_EDITED_ID) )
	pass
	
func request_scene_editorial_close() -> void:
	if _SELECTED_SCENE_BEING_EDITED_ID >= 0:
		self.relay_request_mind.emit("switch_scene", -1)
	pass

func submit_scene_modification() -> void:
	var the_scene_original = _LISTED_SCENES_BY_ID[ _SELECTED_SCENE_BEING_EDITED_ID ]
	var resource_updater = {
		"id": _SELECTED_SCENE_BEING_EDITED_ID, 
		"modification": {},
		"field": "scenes"
	}
	var mod_name = SceneEditorName.get_text()
	if mod_name.length() > 0 && mod_name != the_scene_original.name: # name is changed
		# force using unique names for variables ?
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
							var selected = get_selected_scene_id()
							if selected >= 0:
								self.relay_request_mind.emit("clean_clipboard", null)
								self.relay_request_mind.emit("os_clipboard_push", [[selected], "scenes", false])
					KEY_V:
						if event.is_shift_pressed():
							self.relay_request_mind.emit("os_clipboard_pull", [null, null]) # (no moving)
		pass
