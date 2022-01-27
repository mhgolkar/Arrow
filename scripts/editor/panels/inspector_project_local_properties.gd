# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Inspector :: Project Tab :: Local Project Properties
extends VBoxContainer

signal relay_request_mind

onready var Main = get_tree().get_root().get_child(0)

const SNAPSHOT_LIST_ITEM_TEMPLATE = "{version} - {parsed_time}"
const SNAPSHOT_LIST_ITEM_TIME_TEMPLATE = "{hour}:{minute}:{second}"

var Utils = Helpers.Utils
var ListHelpers = Helpers.ListHelpers

# configs
onready var LocalProjectTitle = get_node(Addressbook.INSPECTOR.PROJECT.LOCAL_PROJECT_PROPERTIES.TITLE_CONFIGURATION.TITLE_EDIT)
onready var SetLocalProjectTitleButton = get_node(Addressbook.INSPECTOR.PROJECT.LOCAL_PROJECT_PROPERTIES.TITLE_CONFIGURATION.SET_BUTTON)
onready var RtlCheckbox = get_node(Addressbook.INSPECTOR.PROJECT.LOCAL_PROJECT_PROPERTIES.RTL_CONFIGURATION_CHECKBOX)
# tools
onready var CloseButton = get_node(Addressbook.INSPECTOR.PROJECT.LOCAL_PROJECT_PROPERTIES.CLOSE)
# more Tools Menu Button
onready var MoreToolsMenuButton = get_node(Addressbook.INSPECTOR.PROJECT.LOCAL_PROJECT_PROPERTIES.MORE_TOOLS_MENU_BUTTON)
onready var MoreToolsPopup = MoreToolsMenuButton.get_popup()
# versioning
onready var LastSaveTimeStamp = get_node(Addressbook.INSPECTOR.PROJECT.LOCAL_PROJECT_PROPERTIES.VERSIONING.LAST_SAVE.TIME_STAMP)
onready var RevertLastSaveButton = get_node(Addressbook.INSPECTOR.PROJECT.LOCAL_PROJECT_PROPERTIES.VERSIONING.LAST_SAVE.REVERT_BUTTON)
# snapshots
onready var SnapshotsList = get_node(Addressbook.INSPECTOR.PROJECT.LOCAL_PROJECT_PROPERTIES.VERSIONING.SNAPSHOTS_LIST)
onready var SnapshotsPreview = get_node(Addressbook.INSPECTOR.PROJECT.LOCAL_PROJECT_PROPERTIES.VERSIONING.SNAPSHOT_TOOLS.PREVIEW_BUTTON)
onready var SnapshotsTakeNew = get_node(Addressbook.INSPECTOR.PROJECT.LOCAL_PROJECT_PROPERTIES.VERSIONING.SNAPSHOT_TOOLS.TAKE_NEW_BUTTON)
onready var SnapshotsRestore = get_node(Addressbook.INSPECTOR.PROJECT.LOCAL_PROJECT_PROPERTIES.VERSIONING.SNAPSHOT_TOOLS.RESTORE_BUTTON)
onready var SnapshotsRemove = get_node(Addressbook.INSPECTOR.PROJECT.LOCAL_PROJECT_PROPERTIES.VERSIONING.SNAPSHOT_TOOLS.REMOVE_BUTTON)

var _CURRENT_TITLE:String
var _CURRENT_META:Dictionary

var _IS_IN_PREVIEW_MODE:bool = false

const MORE_TOOLS_MENU_BUTTON_POPUP = {
	0: { "label": "Save a Copy", "action": "request_save_a_copy_file" },
	1: null, # separator
	2: { "label": "Export JSON", "action": "request_json_export" },
	3: { "label": "Export HTML (Play)", "action": "request_html_export" },
}
var _MORE_TOOLS_ITEM_INDEX_BY_ACTION = {}

func _ready() -> void:
	load_more_tools_menu()
	register_connections()
	refresh_snapshot_tools_view()
	pass

func register_connections() -> void:
	SetLocalProjectTitleButton.connect("pressed", self, "request_title_change", [], CONNECT_DEFERRED)
	RtlCheckbox.connect("toggled", self, "toggle_rtl_config", [], CONNECT_DEFERRED)
	CloseButton.connect("pressed", self, "request_mind_by_relay", ["close_project"], CONNECT_DEFERRED)
	SnapshotsPreview.connect("toggled", self, "set_preview_mode", [], CONNECT_DEFERRED)
	SnapshotsTakeNew.connect("pressed", self, "request_mind_by_relay", ["take_snapshot"], CONNECT_DEFERRED)
	SnapshotsRestore.connect("pressed", self, "restore_snapshot", [], CONNECT_DEFERRED)
	SnapshotsRemove.connect("pressed", self, "remove_snapshot", [], CONNECT_DEFERRED)
	RevertLastSaveButton.connect("pressed", self, "request_mind_by_relay", ["revert_project"], CONNECT_DEFERRED)
	SnapshotsList.connect("item_selected", self, "refresh_snapshot_tools_view", [], CONNECT_DEFERRED)
	SnapshotsList.connect("nothing_selected", self, "_on_snapshots_list_nothing_selected", [], CONNECT_DEFERRED)
	MoreToolsPopup.connect("id_pressed", self, "_on_more_tools_popup_menu_id_pressed", [], CONNECT_DEFERRED)
	pass
	
func load_more_tools_menu() -> void:
	MoreToolsPopup.clear()
	for item_id in MORE_TOOLS_MENU_BUTTON_POPUP:
		var item = MORE_TOOLS_MENU_BUTTON_POPUP[item_id]
		if item == null: # separator
			MoreToolsPopup.add_separator()
		else:
			MoreToolsPopup.add_item(item.label, item_id)
			_MORE_TOOLS_ITEM_INDEX_BY_ACTION[item.action] = MoreToolsPopup.get_item_index(item_id)
	pass

func _on_more_tools_popup_menu_id_pressed(pressed_item_id:int) -> void:
	var the_action = MORE_TOOLS_MENU_BUTTON_POPUP[pressed_item_id].action
	if the_action is String && the_action.length() > 0 :
		self.call_deferred(the_action)
	pass

func clean_snapshots_view() -> void:
	clear_snapshots_list()
	refresh_snapshot_tools_view()
	_IS_IN_PREVIEW_MODE = false
	pass

func refresh_fields(project_title:String, project_meta:Dictionary) -> void:
	_CURRENT_TITLE = project_title
	_CURRENT_META  = project_meta
	# title
	if project_title is String && project_title.length() > 0 :
		LocalProjectTitle.set_text(project_title)
	else:
		LocalProjectTitle.clear()
	# rtl
	if project_meta.has("rtl") && project_meta.rtl is bool:
		RtlCheckbox.set_pressed(project_meta.rtl)
	else:
		RtlCheckbox.set_pressed(false)
	# last save time
	if project_meta.has("last_save") && project_meta is Dictionary:
		var parsed_time_stamp = Utils.parse_time_stamp_dict(project_meta.last_save.local)
		LastSaveTimeStamp.set_text(parsed_time_stamp)
	pass

func refresh_snapshot_tools_view(_x=null) -> void:
	var there_are_snapshots = (SnapshotsList.get_item_count() > 0)
	var snapshot_is_selected = (SnapshotsList.get_selected_items().size() > 0)
	SnapshotsPreview.set_disabled( ! snapshot_is_selected )
	SnapshotsRestore.set_disabled( ! snapshot_is_selected )
	SnapshotsRemove.set_disabled( ! ( there_are_snapshots && snapshot_is_selected ) )
	pass

func clear_snapshots_list() -> void:
	SnapshotsList.clear()
	refresh_snapshot_tools_view()
	pass

func list_snapshot(snapshot_details:Dictionary) -> void:
	var last_item_index = SnapshotsList.get_item_count()
	# list item
	SnapshotsList.add_item(SNAPSHOT_LIST_ITEM_TEMPLATE.format({
			"version": snapshot_details.version,
			"parsed_time": Utils.parse_time_stamp_dict(snapshot_details.time, false, SNAPSHOT_LIST_ITEM_TIME_TEMPLATE)
		})
	)
	# keep the index of the snapshot as meta data
	SnapshotsList.set_item_metadata(last_item_index, snapshot_details.index)
	# and keep it disabled like others if in preview mode
	SnapshotsList.set_item_disabled(last_item_index, _IS_IN_PREVIEW_MODE)
	# new ones first
	SnapshotsList.move_item(last_item_index, 0)
	pass

func request_mind_by_relay(req:String, args=null) -> void:
	emit_signal("relay_request_mind", req, args)
	pass

func request_title_change() -> void:
	var new_project_title = LocalProjectTitle.get_text()
	if new_project_title.length() > 0 :
		request_mind_by_relay("set_project_title", new_project_title)
	else:
		LocalProjectTitle.set_text(_CURRENT_TITLE) # Reset back
		printerr("Projects title is required!")
	pass

func toggle_rtl_config(pressed:bool) -> void:
	# TODO ...
	print_debug("Modifying RTL Configuration !! NOT IMPLEMENTED YET !!", pressed)
	pass

func set_preview_mode(to_active:bool) -> void:
	var selection = SnapshotsList.get_selected_items()
	if selection.size() > 0 :
		var the_snapshot_list_idx = selection[0]
		var snapshot_idx = SnapshotsList.get_item_metadata(the_snapshot_list_idx)
		print_debug("Preview Snapshot: ", snapshot_idx, " : ", to_active)
		if to_active == true:
			ListHelpers.isolate_a_list_item(SnapshotsList, the_snapshot_list_idx)
			if _IS_IN_PREVIEW_MODE == false:
				request_mind_by_relay("toggle_snapshot_preview", snapshot_idx )
				_IS_IN_PREVIEW_MODE = true
		else:
			ListHelpers.isolate_a_list_item(SnapshotsList, -1) # enable all back
			if _IS_IN_PREVIEW_MODE: # because we don't want to send request twice on `restore_snapshot`
				request_mind_by_relay("toggle_snapshot_preview", null )
				_IS_IN_PREVIEW_MODE = false
		# and post actions
		SnapshotsPreview.set_pressed(to_active)
		RevertLastSaveButton.set_disabled(_IS_IN_PREVIEW_MODE)
		refresh_snapshot_tools_view()
	pass

func _on_snapshots_list_nothing_selected() -> void:
	if _IS_IN_PREVIEW_MODE == false:
		SnapshotsList.unselect_all()
	refresh_snapshot_tools_view()
	pass

func get_selected_snapshot_idx() -> int:
	var selection = SnapshotsList.get_selected_items()
	if selection.size() > 0 :
		var the_snapshot_list_idx = selection[0]
		return SnapshotsList.get_item_metadata(the_snapshot_list_idx)
	else:
		return -1
	pass

func restore_snapshot(snapshot_idx:int = -1) -> void:
	if _IS_IN_PREVIEW_MODE:
		set_preview_mode(false)
	if snapshot_idx < 0 :
		snapshot_idx = get_selected_snapshot_idx()
	if snapshot_idx >= 0:
		request_mind_by_relay("restore_snapshot", snapshot_idx)
	pass

func remove_snapshot(snapshot_idx:int = -1) -> void:
	if _IS_IN_PREVIEW_MODE:
		set_preview_mode(false)
	if snapshot_idx < 0 :
		snapshot_idx = get_selected_snapshot_idx()
	if snapshot_idx >= 0:
		request_mind_by_relay("remove_snapshot", snapshot_idx)
	pass

func unlist_snapshot_by_idx(snapshot_idx:int) -> void:
	var list_item_idx = ListHelpers.get_list_item_idx_from_meta_data(SnapshotsList, snapshot_idx)
	print_debug("Removing Snapshot from List: ", snapshot_idx, list_item_idx)
	if list_item_idx >= 0:
		SnapshotsList.remove_item(list_item_idx)
	else:
		printerr("Unexpected Behavior! Trying to remove a snapshot from the list with nonexistent index: ", snapshot_idx)
	pass

func prompt_for_save(dialog_options:Dictionary, extra_arguments:Array = []) -> void:
	# Note: Currently the first item of `extra_arguments<array>` is the format/extension or null for native copy, so ...
	var suggested_extension = ( ("." + extra_arguments[0]) if extra_arguments.size() > 0 else Settings.PROJECT_FILE_EXTENSION )
	var suggested_full_file_name = Main.Mind.get_project_title() + suggested_extension
	dialog_options["current_file"] = suggested_full_file_name
	emit_signal("relay_request_mind", "prompt_path_for_requester", {
		"callback_host": self,
		"callback": "proceed_export",
		"arguments": extra_arguments,
		"options": dialog_options
	})
	pass

func request_save_a_copy_file() -> void:
	prompt_for_save( Settings.PATH_DIALOG_PROPERTIES.PROJECT_FILE.SAVE )
	pass

func request_json_export() -> void:
	prompt_for_save( Settings.PATH_DIALOG_PROPERTIES.PROJECT_FILE.EXPORT_JSON, ["json"] )
	pass

func request_html_export() -> void:
	prompt_for_save( Settings.PATH_DIALOG_PROPERTIES.PROJECT_FILE.EXPORT_HTML, ["html"] )
	pass

func proceed_export(path:String, format = null) -> void:
	var pure_filename = path.get_file().replacen( ( "." + path.get_extension() ) , "")
	if pure_filename.length() >= 1 :
		print_debug("Proceed Copy/Export as %s to file: " % format, pure_filename, " @ ", path)
		emit_signal("relay_request_mind", "export_project", {
			"format": format,
			"filename": pure_filename,
			"base_directory": path.get_base_dir()
		})
	else:
		printerr("Invalid export filename:", path, pure_filename)
		Main.Mind.show_error("Invalid Filename!", "Please choose a filename of at-least 1 character length length.")
	pass
