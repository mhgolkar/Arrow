# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Inspector :: Project Tab :: Project Properties
extends Control

signal relay_request_mind()

@onready var Main = get_tree().get_root().get_child(0)

const SNAPSHOT_LIST_ITEM_TEMPLATE = "{version} - {parsed_time}"
const SNAPSHOT_LIST_ITEM_TIME_TEMPLATE = "{hour}:{minute}:{second}"

# configs
@onready var ProjectTitle = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Properties/Title/Value
@onready var SetProjectTitleButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Properties/Title/Set
@onready var AuthorsConfiguration = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Properties/Actions/Authors
# tools
@onready var CloseButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Properties/Actions/Close
@onready var ExportMenuButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Properties/Actions/Export
@onready var MoreToolsPopup = ExportMenuButton.get_popup()
# versioning
@onready var LastSaveTimeStamp = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Properties/Drafts/Management/LastSave/Timestamp
@onready var RevertLastSaveButton = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Properties/Drafts/Management/LastSave/Revert
# snapshots
@onready var SnapshotsList = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Properties/Drafts/Management/Snapshots/VBox/List
@onready var SnapshotsTakeNew = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Properties/Drafts/Management/Snapshots/VBox/Actions/Take
@onready var SnapshotsRestore = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Properties/Drafts/Management/Snapshots/VBox/Actions/Restore
@onready var SnapshotsPreview = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Properties/Drafts/Management/Snapshots/VBox/Actions/Preview
@onready var SnapshotsRemove = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Properties/Drafts/Management/Snapshots/VBox/Actions/Remove

var _CURRENT_TITLE:String
var _CURRENT_META:Dictionary

var _IS_IN_PREVIEW_MODE:bool = false

const MORE_TOOLS_MENU_BUTTON_POPUP = {
	0: { "label": "Save a Copy", "action": "request_save_a_copy_file" },
	1: { "label": "Download a Copy", "action": "request_copy_export", "html5": true },
	2: null, # separator
	3: { "label": "Export JSON", "action": "request_json_export" },
	4: { "label": "Export HTML", "action": "request_html_export" },
	5: { "label": "Export CSV", "action": "request_csv_export" },
}
var _MORE_TOOLS_ITEM_INDEX_BY_ACTION = {}

func _ready() -> void:
	load_more_tools_menu()
	register_connections()
	refresh_snapshot_tools_view()
	pass

func register_connections() -> void:
	SetProjectTitleButton.pressed.connect(self.request_title_change, CONNECT_DEFERRED)
	AuthorsConfiguration.pressed.connect(self.open_authors_config, CONNECT_DEFERRED)
	CloseButton.pressed.connect(self.request_mind_by_relay.bind("close_project"), CONNECT_DEFERRED)
	SnapshotsPreview.toggled.connect(self.set_preview_mode, CONNECT_DEFERRED)
	SnapshotsTakeNew.pressed.connect(self.request_mind_by_relay.bind("take_snapshot"), CONNECT_DEFERRED)
	SnapshotsRestore.pressed.connect(self.restore_snapshot, CONNECT_DEFERRED)
	SnapshotsRemove.pressed.connect(self.remove_snapshot, CONNECT_DEFERRED)
	RevertLastSaveButton.pressed.connect(self.request_mind_by_relay.bind("revert_project"), CONNECT_DEFERRED)
	SnapshotsList.item_selected.connect(self.refresh_snapshot_tools_view, CONNECT_DEFERRED)
	SnapshotsList.empty_clicked.connect(self._on_snapshots_list_empty_clicked, CONNECT_DEFERRED)
	MoreToolsPopup.id_pressed.connect(self._on_more_tools_popup_menu_id_pressed, CONNECT_DEFERRED)
	pass
	
func load_more_tools_menu() -> void:
	MoreToolsPopup.clear()
	var being_in_browser = Html5Helpers.Utils.is_browser()
	for item_id in MORE_TOOLS_MENU_BUTTON_POPUP:
		var item = MORE_TOOLS_MENU_BUTTON_POPUP[item_id]
		if item == null: # separator
			MoreToolsPopup.add_separator()
		else:
			if (
				item.has("html5") == false || # (is always available)
				(item.html5 == being_in_browser) # (depending on the environment)
			):
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

func reset_last_save(last_save) -> void:
	# Note: last-save times are saved in UTC and shown in local
	var parsed_time = null
	if last_save is Dictionary: # (backward compatibility)
		if last_save.has("local"):
			parsed_time = Helpers.Utils.parse_time_stamp(last_save.local, false, false) # shown from and in local
		elif last_save.has("utc"):
			parsed_time = Helpers.Utils.parse_time_stamp(last_save.utc, false, true) # shown from utc in local
	elif last_save is String: # (new versions only include UTC time string,
		parsed_time = Helpers.Utils.parse_time_stamp(last_save, false, true) # so conversion is needed) 
	else:
		printerr("Unable to set last save time! ", last_save)
	LastSaveTimeStamp.set_text(parsed_time if parsed_time is String else "ERR!")
	pass

func refresh_fields(project_title:String, project_meta:Dictionary) -> void:
	_CURRENT_TITLE = project_title
	_CURRENT_META  = project_meta
	# title
	if project_title is String && project_title.length() > 0 :
		ProjectTitle.set_text(project_title)
	else:
		ProjectTitle.clear()
	# last save time
	if project_meta.has("last_save"):
		reset_last_save(project_meta.last_save)
	# making sure older (legacy) projects won't mess up with node identifiers by adding authors
	AuthorsConfiguration.set_visible( project_meta.has("authors") )
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
			"parsed_time": Helpers.Utils.parse_time_stamp(
				snapshot_details.time, false, true, SNAPSHOT_LIST_ITEM_TIME_TEMPLATE
			)
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
	self.relay_request_mind.emit(req, args)
	pass

func request_title_change() -> void:
	var new_project_title = ProjectTitle.get_text()
	if new_project_title.length() > 0 :
		request_mind_by_relay("set_project_title", new_project_title)
	else:
		ProjectTitle.set_text(_CURRENT_TITLE) # Reset back
		printerr("Projects title is required!")
	pass

func open_authors_config() -> void:
	Main.call_deferred("toggle_authors")
	pass

func set_preview_mode(to_active:bool) -> void:
	var selection = SnapshotsList.get_selected_items()
	if selection.size() > 0 :
		var the_snapshot_list_idx = selection[0]
		var snapshot_idx = SnapshotsList.get_item_metadata(the_snapshot_list_idx)
		print_debug("Preview Snapshot: ", snapshot_idx, " : ", to_active)
		if to_active == true:
			Helpers.ListHelpers.isolate_a_list_item(SnapshotsList, the_snapshot_list_idx)
			if _IS_IN_PREVIEW_MODE == false:
				request_mind_by_relay("toggle_snapshot_preview", snapshot_idx )
				_IS_IN_PREVIEW_MODE = true
		else:
			Helpers.ListHelpers.isolate_a_list_item(SnapshotsList, -1) # enable all back
			if _IS_IN_PREVIEW_MODE: # because we don't want to send request twice on `restore_snapshot`
				request_mind_by_relay("toggle_snapshot_preview", null )
				_IS_IN_PREVIEW_MODE = false
		# and post actions
		SnapshotsPreview.set_pressed(to_active)
		RevertLastSaveButton.set_disabled(_IS_IN_PREVIEW_MODE)
		refresh_snapshot_tools_view()
	pass

func _on_snapshots_list_empty_clicked(_x = null, _y = null) -> void:
	if _IS_IN_PREVIEW_MODE == false:
		SnapshotsList.deselect_all()
	refresh_snapshot_tools_view()
	pass

func get_selected_snapshot_idx() -> int:
	var selection = SnapshotsList.get_selected_items()
	if selection.size() > 0 :
		var the_snapshot_list_idx = selection[0]
		return SnapshotsList.get_item_metadata(the_snapshot_list_idx)
	else:
		return -1

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
	var list_item_idx = Helpers.ListHelpers.get_list_item_idx_from_meta_data(SnapshotsList, snapshot_idx)
	print_debug("Removing Snapshot from List: ", snapshot_idx, list_item_idx)
	if list_item_idx >= 0:
		SnapshotsList.remove_item(list_item_idx)
	else:
		printerr("Unexpected Behavior! Trying to remove a snapshot from the list with nonexistent index: ", snapshot_idx)
	pass

func prompt_for_save(dialog_options:Dictionary, extra_arguments:Array = []) -> void:
	# Note: Currently the first item of `extra_arguments<array>` is the format/extension or null for native copy, so ...
	var suggested_extension = ( ("." + extra_arguments[0]) if extra_arguments.size() > 0 else Settings.PROJECT_FILE_EXTENSION )
	var suggested_full_file_name = Main.Mind.get_project_title().to_snake_case() + suggested_extension
	var custom_dialog_options = dialog_options.duplicate(true)
	custom_dialog_options["current_file"] = suggested_full_file_name
	self.relay_request_mind.emit("prompt_path_for_requester", {
		"callback_host": self,
		"callback": "proceed_export",
		"arguments": extra_arguments,
		"options": custom_dialog_options
	})
	pass

func request_save_a_copy_file() -> void:
	prompt_for_save( Settings.PATH_DIALOG_PROPERTIES.PROJECT_FILE.SAVE )
	pass

func request_copy_export() -> void:
	if Html5Helpers.Utils.is_browser():
		self.relay_request_mind.emit("export_project_from_browser", "full-copy")
	else:
		printerr("Trying to download project copy out of browser context.")
	pass

func request_json_export() -> void:
	if Html5Helpers.Utils.is_browser():
		self.relay_request_mind.emit("export_project_from_browser", "json")
	else:
		prompt_for_save( Settings.PATH_DIALOG_PROPERTIES.PROJECT_FILE.EXPORT_JSON, ["json"] )
	pass

func request_html_export() -> void:
	if Html5Helpers.Utils.is_browser():
		self.relay_request_mind.emit("export_project_from_browser", "html")
	else:
		prompt_for_save( Settings.PATH_DIALOG_PROPERTIES.PROJECT_FILE.EXPORT_HTML, ["html"] )
	pass

func request_csv_export() -> void:
	if Html5Helpers.Utils.is_browser():
		self.relay_request_mind.emit("export_project_from_browser", "csv")
	else:
		prompt_for_save( Settings.PATH_DIALOG_PROPERTIES.PROJECT_FILE.EXPORT_CSV, ["csv"] )
	pass

func proceed_export(path:String, format = null) -> void:
	var pure_filename = path.get_file().replacen( ( "." + path.get_extension() ) , "")
	if pure_filename.length() >= 1 :
		print_debug("Proceed Copy/Export as %s to file: " % format, pure_filename, " @ ", path)
		self.relay_request_mind.emit("export_project", {
			"format": format,
			"filename": pure_filename,
			"base_directory": path.get_base_dir()
		})
	else:
		printerr("Invalid export filename:", path, pure_filename)
		Main.Mind.show_error("Invalid Filename!", "INVALID_FILENAME_MSG")
	pass
