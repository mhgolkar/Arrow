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
onready var CreatePorjectButton = get_node(Addressbook.NEW_PROJECT_PROMPT_PANEL.CREATE_BUTTON)
onready var DismissButton = get_node(Addressbook.NEW_PROJECT_PROMPT_PANEL.DISMISS_BUTTON)

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	CreatePorjectButton.connect("pressed", self, "request_min_register_project_and_save_from_open", [], CONNECT_DEFERRED)
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

func request_min_register_project_and_save_from_open() -> void:
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
	pass
