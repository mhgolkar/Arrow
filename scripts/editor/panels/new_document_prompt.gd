# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# New Document/Project Prompt
extends Control

signal request_mind()

@onready var Main = get_tree().get_root().get_child(0)

@onready var NewProjectTitle = $/root/Main/Overlays/Control/NewDocument/Margin/Sections/Path/Structure/Title/Value
@onready var NewProjectFileName = $/root/Main/Overlays/Control/NewDocument/Margin/Sections/Path/Structure/Filename/Value
@onready var NewProjectFinalPath = $/root/Main/Overlays/Control/NewDocument/Margin/Sections/Path/Structure/Preview/Value
@onready var FileRenameWarn = $/root/Main/Overlays/Control/NewDocument/Margin/Sections/Path/Structure/Warning
@onready var CreateProjectButton = $/root/Main/Overlays/Control/NewDocument/Margin/Sections/Actions/Confirm
@onready var DismissButton = $/root/Main/Overlays/Control/NewDocument/Margin/Sections/Actions/Dismiss

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	CreateProjectButton.pressed.connect(self.request_mind_register_project_and_save_from_open, CONNECT_DEFERRED)
	DismissButton.pressed.connect(self.close_this_prompt, CONNECT_DEFERRED)
	NewProjectTitle.text_changed.connect(self._on_project_title_changed, CONNECT_DEFERRED)
	NewProjectFileName.text_changed.connect(self.validate_fields, CONNECT_DEFERRED)
	pass

func close_this_prompt() -> void:
	NewProjectFileName.clear()
	NewProjectTitle.clear()
	Main.UI.call_deferred("set_panel_visibility", "new_project_prompt", false)
	pass

func prompt_with_presets(title:String, filename:String = "") -> void:
	# Reset fields,
	var valid_filename = Helpers.Utils.valid_filename( (filename if (filename.length() > 0) else title), true )
	NewProjectFileName.set_text(valid_filename)
	NewProjectTitle.set_text( title.capitalize() )
	# then to reset the view if it was previously invalidated
	validate_fields()
	# and show the panel
	Main.UI.call_deferred("set_panel_visibility", "new_project_prompt", true)
	NewProjectTitle.call_deferred("grab_focus")
	pass

func request_mind_register_project_and_save_from_open() -> void:
	self.request_mind.emit("register_project_and_save_from_open", {
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
	CreateProjectButton.set_disabled(invalidity)
	var the_final_file_name = Main.Mind.ProMan.valid_unique_project_filename_from(new_filename)
	FileRenameWarn.set_visible(new_filename != the_final_file_name)
	reset_new_project_path(the_final_file_name)
	pass

var cached_absolute_paths = {}
func get_cache_absolute_path(path:String) -> String:
	if cached_absolute_paths.has(path) == false:
		cached_absolute_paths[path] = Helpers.Utils.get_abs_path(path)
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

func _on_project_title_changed(new_text:String) -> void:
	NewProjectFileName.set_text(
		Helpers.Utils.valid_filename(new_text, true)
	)
	validate_fields()
	pass
