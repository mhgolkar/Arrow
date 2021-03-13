# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# New Project Prompt
extends PanelContainer

signal request_mind

onready var Main = get_tree().get_root().get_child(0)

var Utils = Helpers.Utils

onready var NewProjectTitle = get_node(Addressbook.NEW_PROJECT_PROMPT_PANEL.FIELDS.TITLE)
onready var NewProjectFileName = get_node(Addressbook.NEW_PROJECT_PROMPT_PANEL.FIELDS.FILENAME)
onready var NewProjectFinalPath = get_node(Addressbook.NEW_PROJECT_PROMPT_PANEL.FIELDS.FINAL_PATH)
onready var FileRenameWarn = get_node(Addressbook.NEW_PROJECT_PROMPT_PANEL.RENAME_WARN)
onready var CreatePorjectButton = get_node(Addressbook.NEW_PROJECT_PROMPT_PANEL.CREATE_BUTTON)
onready var DismissButton = get_node(Addressbook.NEW_PROJECT_PROMPT_PANEL.DISMISS_BUTTON)

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	CreatePorjectButton.connect("pressed", self, "request_mind_register_project_and_save_from_open", [], CONNECT_DEFERRED)
	DismissButton.connect("pressed", self, "close_this_prompt", [], CONNECT_DEFERRED)
	NewProjectTitle.connect("text_changed", self, "validate_fields", [], CONNECT_DEFERRED)
	NewProjectFileName.connect("text_changed", self, "validate_fields", [], CONNECT_DEFERRED)
	pass

func close_this_prompt() -> void:
	NewProjectFileName.clear()
	NewProjectTitle.clear()
	Main.UI.call_deferred("set_panel_visibility", "new_project_prompt", false)
	pass

func prompt_with_presets(title:String, filename:String = "") -> void:
	# Reset fields,
	var valid_filename = Utils.valid_filename( (filename if (filename.length() > 0) else title), true )
	NewProjectFileName.set_text(valid_filename)
	NewProjectTitle.set_text( title.capitalize() )
	# then to reset the view if it was previously invalidated
	validate_fields()
	# and show the panel
	Main.UI.call_deferred("set_panel_visibility", "new_project_prompt", true)
	NewProjectTitle.call_deferred("grab_focus")
	pass

func request_mind_register_project_and_save_from_open() -> void:
	emit_signal("request_mind", "register_project_and_save_from_open", {
		"title": NewProjectTitle.get_text(),
		"filename": NewProjectFileName.get_text()
	})
	close_this_prompt()
	pass

func validate_fields(_x = null) -> void:
	var invalidity:bool = false
	var new_title = NewProjectTitle.get_text()
	var new_filename = NewProjectFileName.get_text()
	if (
		new_title.length() == 0 ||
		new_filename.length() == 0 ||
		new_filename.is_valid_filename() == false
	):
		invalidity = true
	CreatePorjectButton.set_disabled(invalidity)
	var the_final_file_name = Main.Mind.ProMan.valid_unique_project_filename_from(new_filename)
	FileRenameWarn.set_visible(new_filename != the_final_file_name)
	reset_new_project_path(the_final_file_name)
	pass

var cached_absolute_paths = {}
func get_cache_absolute_path(path:String) -> String:
	if cached_absolute_paths.has(path) == false:
		cached_absolute_paths[path] = Utils.get_abs_path(path)
	return cached_absolute_paths[path]

func reset_new_project_path(filename:String) -> void:
	NewProjectFinalPath.set_text(
		get_cache_absolute_path(
			Main.Configs.CONFIRMED.app_local_dir_path
		) +
		filename +
		Settings.PROJECT_FILE_EXTENSION
	)
	pass
