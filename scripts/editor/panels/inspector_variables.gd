# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Inspector :: Variables Tab
extends Control

signal relay_request_mind()

@onready var Main = get_tree().get_root().get_child(0)
@onready var Grid = $/root/Main/Editor/Center/Grid

var _LISTED_VARIABLES_BY_ID = {}
var _LISTED_VARIABLES_BY_NAME = {}

var _SELECTED_VARIABLE_BEING_EDITED_ID = -1

var _SELECTED_VARIABLE_USERS = {} # id: {id, resource, map}
var _SELECTED_VARIABLE_USER_IDS = []

var _CURRENT_LOCATED_REF_ID = -1

@onready var Filter = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Filters/Input
@onready var FilterReverse = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Filters/Reverse
@onready var FilterInType = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Filters/Type
@onready var FilterForScene = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Filters/Scoped
@onready var SortAlphabetical = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Filters/Alphabetical

@onready var VariablesList = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/List

@onready var VariableEditorPanel = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Editor
@onready var VariableRawUid = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Editor/Tools/Identifier/Uid
@onready var VariableEditorName = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Editor/Tools/Identifier/Name
@onready var VariableEditorInitialValue = {
	"str": $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Editor/Tools/Initial/Value/String,
	"num": $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Editor/Tools/Initial/Value/Number,
	"bool": $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Editor/Tools/Initial/Value/Boolean
}
@onready var VariableEditorSaveButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Editor/Tools/Actions/Update
@onready var VariableEditorRemoveButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Editor/Tools/Actions/Remove
# + References
@onready var VariableReferencesBox = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Editor/Tools/References
@onready var VariableReferencesGoToButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Editor/Tools/References/Referrers
@onready var VariableReferencesGoToButtonPopup = VariableReferencesGoToButton.get_popup()
@onready var VariableReferencesGoToPrevious = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Editor/Tools/References/Previous
@onready var VariableReferencesGoToNext = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Editor/Tools/References/Next
@onready var VariableReferencesFilterForScene = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Editor/Tools/References/Scoped


@onready var VariablesTypeSelect = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Creation/Type
@onready var VariablesNewButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Variables/Manager/Creation/New

const VARIABLE_TYPE_IN_SELECTION_TEXT_TEMPLATE = "{name} ({type})"
const VARIABLE_IN_LIST_TEXT_TEMPLATE = "{name} ({type}, {init})"

const VARIABLE_APPEARANCE_COUNT_TEMPLATE = "{0} [{1}]"
const RAW_UID_TIP_TEMPLATE = "UID: %s"

func _ready() -> void:
	register_connections()
	VariableReferencesGoToButtonPopup.set_allow_search(true)
	pass

func register_connections() -> void:
	VariablesNewButton.pressed.connect(self.request_new_variable_creation, CONNECT_DEFERRED)
	VariablesList.item_selected.connect(self._on_variables_list_item_selected, CONNECT_DEFERRED)
	VariablesList.empty_clicked.connect(self._on_variables_list_empty_clicked, CONNECT_DEFERRED)
	VariablesList.gui_input.connect(self._on_list_gui_input, CONNECT_DEFERRED)
	VariableRawUid.pressed.connect(self.os_clipboard_push_raw_uid, CONNECT_DEFERRED)
	VariableEditorSaveButton.pressed.connect(self.submit_variable_modification, CONNECT_DEFERRED)
	VariableEditorRemoveButton.pressed.connect(self.request_remove_variable, CONNECT_DEFERRED)
	VariableReferencesGoToButtonPopup.index_pressed.connect(self._on_go_to_menu_button_popup_index_pressed, CONNECT_DEFERRED)
	VariableReferencesGoToPrevious.pressed.connect(self._rotate_go_to.bind(-1), CONNECT_DEFERRED)
	VariableReferencesGoToNext.pressed.connect(self._rotate_go_to.bind(1), CONNECT_DEFERRED)
	VariableReferencesFilterForScene.pressed.connect(self.refresh_referrers_list, CONNECT_DEFERRED)
	Filter.text_changed.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	FilterReverse.toggled.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	FilterInType.toggled.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	FilterForScene.toggled.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	SortAlphabetical.toggled.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	pass

func initialize_tab() -> void:
	refresh_variable_type_selection()
	refresh_variables_list()
	pass

func refresh_tab() -> void:
	refresh_variables_list()
	pass

func refresh_variable_type_selection() -> void:
	VariablesTypeSelect.clear()
	for type_id in Settings.VARIABLE_TYPES_ENUM:
		var type = Settings.VARIABLE_TYPES_ENUM[type_id]
		var the_type = Settings.VARIABLE_TYPES[type]
		VariablesTypeSelect.add_item(
			VARIABLE_TYPE_IN_SELECTION_TEXT_TEMPLATE.format({
				"name": the_type.name,
				"type": type
			}),
			type_id
		)
	pass
	
func refresh_variables_list(list:Dictionary = {}) -> void:
	VariablesList.clear()
	_LISTED_VARIABLES_BY_ID.clear()
	_LISTED_VARIABLES_BY_NAME.clear()
	if list.size() == 0 :
		# fetch the variables dataset if it's not provided as parameter
		list = Main.Mind.clone_dataset_of("variables")
	list_variables(list)
	VariablesList.deselect_all()
	smartly_toggle_editor()
	pass

func _on_listing_instruction_change(_x = null) -> void:
	refresh_variables_list()
	pass

func read_listing_instruction() -> Dictionary:
	return {
		"FILTER": Filter.get_text(),
		"FILTER_REVERSE": FilterReverse.is_pressed(),
		"FILTER_IN_TYPE": [null, "num", "str", "bool"][ FilterInType.get_selected_id() ],
		"FILTER_FOR_SCENE": FilterForScene.is_pressed(),
		"SORT_ALPHABETICAL": SortAlphabetical.is_pressed(),
	}

func passes_filters(instruction: Dictionary, variable_id: int, variable: Dictionary) -> bool:
	if Helpers.Utils.filter_pass(variable.name, instruction.FILTER, instruction.FILTER_REVERSE):
		if instruction.FILTER_IN_TYPE == null || variable.type == instruction.FILTER_IN_TYPE:
			if instruction.FILTER_FOR_SCENE == false || Main.Mind.resource_is_used_in_scene(variable_id, "variables"):
				return true
	return false

# appends a list of variables to the existing ones
# CAUTION! this won't refresh the current list,
# if a variable exists (by id) it'll be updated, otherwise added
func list_variables(list_to_append:Dictionary) -> void :
	var _LISTING = read_listing_instruction()
	for variable_id in list_to_append:
		var the_variable = list_to_append[variable_id]
		if passes_filters(_LISTING, variable_id, the_variable):
			if _LISTED_VARIABLES_BY_ID.has(variable_id):
				update_variable_list_item(variable_id, the_variable)
			else:
				insert_variable_list_item(variable_id, the_variable)
	VariablesList.ensure_current_is_visible()
	if _LISTING.SORT_ALPHABETICAL:
		VariablesList.call_deferred("sort_items_by_text")
	pass

func unlist_variables(id_list:Array) -> void :
	VariablesList.deselect_all()
	smartly_toggle_editor()
	# remove items from the list
	# Note: to avoid conflicts, we remove from end, because the indices may change otherwise and disturb the job.
	var idx = ( VariablesList.get_item_count() - 1 )
	while idx >= 0:
		if id_list.has( VariablesList.get_item_metadata(idx) ):
			VariablesList.remove_item(idx)
		idx = (idx - 1)
	# also clean from the references
	for variable_id in id_list:
		dereference_listed_variables(variable_id)
	pass
	
func reference_listed_variables(variable_id:int, the_variable:Dictionary) -> void:
	# is it previously referenced ?
	if _LISTED_VARIABLES_BY_ID.has(variable_id): # if so, attempt some cleanup
		var previously_referenced = _LISTED_VARIABLES_BY_ID[variable_id]
		# the id never changes but names change, so we need to remove previously kept reference by name
		if previously_referenced.name != the_variable.name: # if the name is changed
			# ... to avoid the false notion that the old name is still in use
			_LISTED_VARIABLES_BY_NAME.erase(previously_referenced.name)
	# now we can update or create the references
	_LISTED_VARIABLES_BY_ID[variable_id] = the_variable
	_LISTED_VARIABLES_BY_NAME[the_variable.name] = _LISTED_VARIABLES_BY_ID[variable_id]
	# we can refresh variable editor because change in reference means an update
	if _SELECTED_VARIABLE_BEING_EDITED_ID == variable_id:
		load_variable_in_editor(_SELECTED_VARIABLE_BEING_EDITED_ID)
	pass

func dereference_listed_variables(variable_id:int) -> void:
	if _LISTED_VARIABLES_BY_ID.has(variable_id):
		_LISTED_VARIABLES_BY_NAME.erase( _LISTED_VARIABLES_BY_ID[variable_id].name )
		_LISTED_VARIABLES_BY_ID.erase(variable_id)
	pass
	
func insert_variable_list_item(variable_id:int, the_variable:Dictionary) -> void:
	reference_listed_variables(variable_id, the_variable)
	var item_text = VARIABLE_IN_LIST_TEXT_TEMPLATE.format(the_variable)
	# insert the variable as list item
	VariablesList.add_item( item_text )
	# we need to keep track of ids in metadata
	# the item is added last, so:
	var item_index = (VariablesList.get_item_count() - 1)
	VariablesList.set_item_metadata(item_index, variable_id)
	# then select and load it in the variable editor
	VariablesList.select(item_index)
	load_variable_in_editor(variable_id)
	pass

func update_variable_list_item(variable_id:int, the_variable:Dictionary) -> void:
	reference_listed_variables(variable_id, the_variable)
	for idx in range(0, VariablesList.get_item_count()):
		if VariablesList.get_item_metadata(idx) == variable_id:
			# found it, update...
			VariablesList.set_item_text(idx, VARIABLE_IN_LIST_TEXT_TEMPLATE.format(the_variable))
			return
	printerr("Unexpected Behavior! Trying to update variable=%s which is not found in the list!")
	pass

func request_new_variable_creation() -> void:
	var selected_type = Settings.VARIABLE_TYPES_ENUM[ VariablesTypeSelect.get_selected_id() ]
	self.relay_request_mind.emit("create_variable", selected_type)
	pass

func request_remove_variable(resource_id:int = -1) -> void:
	if resource_id < 0 : # default to the selected one
		resource_id = _SELECTED_VARIABLE_BEING_EDITED_ID
	# make sure this is an existing variable resource before trying to remove it
	if _LISTED_VARIABLES_BY_ID.has(resource_id):
		self.relay_request_mind.emit("remove_resource", { "id": resource_id, "field": "variables" })
	VariablesList.deselect_all()
	smartly_toggle_editor()
	pass

func load_variable_in_editor(variable_id) -> void:
	_SELECTED_VARIABLE_BEING_EDITED_ID = variable_id
	var the_variable = _LISTED_VARIABLES_BY_ID[variable_id]
	switch_variable_initial_value_sub_editor(the_variable.type)
	VariableRawUid.set_deferred("tooltip_text", (RAW_UID_TIP_TEMPLATE % variable_id) + tr("TYPE_INSPECTOR_RAW_UID_HINT"))
	VariableEditorName.set_text(the_variable.name)
	set_variable_initial_value_sub_editor(the_variable.type, the_variable.init)
	# can't it be removed ? not if it's used by other resources
	VariableEditorRemoveButton.set_disabled( (the_variable.has("use") && the_variable.use.size() > 0) )
	update_usage_pagination(variable_id)
	smartly_toggle_editor()
	pass

func refresh_variable_cache_by_id(variable_id:int) -> void:
	if variable_id >= 0 :
		var the_variable = Main.Mind.lookup_resource(variable_id, "variables", true)
		if the_variable is Dictionary:
			_LISTED_VARIABLES_BY_ID[variable_id] = the_variable
			_LISTED_VARIABLES_BY_NAME[the_variable.name] = _LISTED_VARIABLES_BY_ID[variable_id]
	pass

func os_clipboard_push_raw_uid():
	DisplayServer.clipboard_set( String.num_int64(_SELECTED_VARIABLE_BEING_EDITED_ID) )
	pass

func refresh_referrers_list() -> void:
	if _SELECTED_VARIABLE_BEING_EDITED_ID >= 0:
		update_usage_pagination(_SELECTED_VARIABLE_BEING_EDITED_ID)
	pass

func update_usage_pagination(variable_id:int) -> void:
	VariableReferencesGoToButtonPopup.clear()
	_SELECTED_VARIABLE_USER_IDS = []
	_SELECTED_VARIABLE_USERS = Main.Mind.list_referrers(variable_id)
	var referrers_size = _SELECTED_VARIABLE_USERS.size()
	if referrers_size > 0 :
		VariableReferencesBox.set_visible(true)
		var item_index := 0
		for user_node_id in _SELECTED_VARIABLE_USERS:
			if VariableReferencesFilterForScene.is_pressed() == false || Main.Mind.scene_owns_node(user_node_id) != null:
				var user_node = _SELECTED_VARIABLE_USERS[user_node_id]
				_SELECTED_VARIABLE_USER_IDS.append(user_node_id)
				var user_node_name = user_node.name if user_node.has("name") else ("Unnamed - %s" % user_node_id)
				VariableReferencesGoToButtonPopup.add_item(user_node_name, user_node_id)
				VariableReferencesGoToButtonPopup.set_item_metadata(item_index, user_node_id)
				item_index += 1
		VariableReferencesGoToButton.set_text( VARIABLE_APPEARANCE_COUNT_TEMPLATE.format([item_index, referrers_size]) )
		var no_option = (item_index == 0)
		VariableReferencesGoToPrevious.set_disabled(no_option)
		VariableReferencesGoToButton.set_disabled(no_option)
		VariableReferencesGoToNext.set_disabled(no_option)
	else:
		VariableReferencesBox.set_visible(false)
	pass

func _on_go_to_menu_button_popup_index_pressed(referrer_idx:int) -> void:
	# (We can not use `id_pressed` because currently Godot support is limited to i32 item IDs.)
	var referrer_id = _SELECTED_VARIABLE_USER_IDS[referrer_idx]
	if referrer_id >= 0:
		_CURRENT_LOCATED_REF_ID = referrer_id
		self.relay_request_mind.emit("locate_node_on_grid", {
			"id": referrer_id,
			"highlight": true,
			"force": true, # ... to change open scene
		})
	pass

func _rotate_go_to(direction: int) -> void:
	var count = _SELECTED_VARIABLE_USER_IDS.size()
	if count > 0:
		var current_located_index = _SELECTED_VARIABLE_USER_IDS.find(_CURRENT_LOCATED_REF_ID)
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
	
func submit_variable_modification() -> void:
	var the_variable_original = _LISTED_VARIABLES_BY_ID[ _SELECTED_VARIABLE_BEING_EDITED_ID ]
	var resource_updater = {
		"id": _SELECTED_VARIABLE_BEING_EDITED_ID, 
		"modification": {},
		"field": "variables"
	}
	var mod_name = VariableEditorName.get_text()
	var mod_initial_value = get_variable_initial_value_sub_editor(the_variable_original.type)
	if mod_name.length() > 0 && mod_name != the_variable_original.name: # name is changed
		mod_name = Helpers.Utils.exposure_safe_resource_name(mod_name)
		# force using unique names ?
		if Settings.FORCE_UNIQUE_NAMES_FOR_VARIABLES == false || _LISTED_VARIABLES_BY_NAME.has(mod_name) == false:
			resource_updater.modification["name"] = mod_name
		else:
			resource_updater.modification["name"] = ( mod_name + Settings.REUSED_VARIABLE_NAMES_AUTO_POSTFIX )
	if mod_initial_value != the_variable_original.init: # initial value is changed
		resource_updater.modification["init"] = mod_initial_value
	if resource_updater.modification.size() > 0 :
		self.relay_request_mind.emit("update_resource", resource_updater)
	pass

func switch_variable_initial_value_sub_editor(open_type:String) -> void:
	for editor_type in VariableEditorInitialValue:
		if editor_type == open_type:
			VariableEditorInitialValue[editor_type].set("visible", true)
		else:
			VariableEditorInitialValue[editor_type].set("visible", false)
	pass

func set_variable_initial_value_sub_editor(type:String, value) -> void:
	match type:
		"str":
			VariableEditorInitialValue["str"].set_text(value)
		"num":
			VariableEditorInitialValue["num"].set_value(value)
		"bool":
			VariableEditorInitialValue["bool"].select( VariableEditorInitialValue["bool"].get_item_index( ( 1 if value else 0 ) ) )
	pass
	
func get_variable_initial_value_sub_editor(type:String):
	var the_value
	match type:
		"str":
			the_value = VariableEditorInitialValue["str"].get_text()
		"num":
			the_value = int( VariableEditorInitialValue["num"].get_value() )
		"bool":
			var int_boolean = int( VariableEditorInitialValue["bool"].get_selected_id() )
			the_value = ( int_boolean == 1 )
	return the_value

func _on_variables_list_item_selected(idx:int)-> void:
	var variable_id = VariablesList.get_item_metadata(idx)
	load_variable_in_editor(variable_id)
	pass

func smartly_toggle_editor() -> void:
	var selected_variables_in_list = VariablesList.get_selected_items()
	if selected_variables_in_list.size() == 0 || VariablesList.get_item_metadata( selected_variables_in_list[0] ) != _SELECTED_VARIABLE_BEING_EDITED_ID:
		VariableEditorPanel.set("visible", false)
	else:
		VariableEditorPanel.set("visible", true)
	pass
	
func _on_variables_list_empty_clicked(_x = null, _y = null) -> void:
	VariablesList.deselect_all()
	_SELECTED_VARIABLE_BEING_EDITED_ID = -1
	smartly_toggle_editor()
	pass

func _on_list_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_echo() == false && event.is_pressed() == true:
			if event.is_ctrl_pressed():
				match event.get_keycode():
					KEY_C:
						if event.is_shift_pressed():
							var selected = _SELECTED_VARIABLE_BEING_EDITED_ID
							if selected >= 0:
								self.relay_request_mind.emit("clean_clipboard", null)
								self.relay_request_mind.emit("os_clipboard_push", [[selected], "variables", false])
					KEY_V:
						if event.is_shift_pressed():
							self.relay_request_mind.emit("os_clipboard_pull", [null, null]) # (no moving)
		pass
