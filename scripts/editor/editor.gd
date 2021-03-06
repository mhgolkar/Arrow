# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Editor
# (base)
extends VBoxContainer

signal request_mind

onready var Main = get_tree().get_root().get_child(0)

# top
onready var ProjectTitle = get_node( Addressbook.EDITOR.PROJECT_TITLE )
	# save
onready var SaveButton = get_node(Addressbook.EDITOR.QUICK_TOOLS.SAVE)
onready var SaveIndicator = get_node(Addressbook.EDITOR.QUICK_TOOLS.SAVE_INDICATOR)
	# play modes
onready var PlayFromSelectedNodeButton = get_node(Addressbook.EDITOR.PLAY.FROM_SELECTED_NODE)
onready var PlayFromSceneEntryButton = get_node(Addressbook.EDITOR.PLAY.FROM_SCENE_ENTRY)
onready var PlayFromProjectEntryButton = get_node(Addressbook.EDITOR.PLAY.FROM_PROJECT_ENTRY)
onready var PlayFromLeftConsoleButton = get_node(Addressbook.EDITOR.PLAY.FROM_LEFT_CONSOLE)
# bottom
onready var OpenSceneTitle = get_node(Addressbook.EDITOR.OPEN_SCENE_TITLE)

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	SaveButton.connect("pressed", self, "_request_mind", ["save_project"])
	PlayFromSceneEntryButton.connect("pressed", self, "_request_mind", ["console_play_from", "scene_entry"])
	PlayFromProjectEntryButton.connect("pressed", self, "_request_mind", ["console_play_from", "project_entry"])
	PlayFromLeftConsoleButton.connect("pressed", self, "_request_mind", ["console_play_from", "left_console"])
	PlayFromSelectedNodeButton.connect("pressed", self, "_request_mind", ["console_play_from", "selected_node"])
	pass

func set_project_title(title:String) -> void:
	ProjectTitle.set_deferred("text", title)
	pass

func set_project_save_status(is_saved:bool = false) -> void:
	var color = (Settings.PROJECT_SAVE_INDICATION_COLOR if is_saved else Settings.PROJECT_UNSAVE_INDICATION_COLOR)
	SaveIndicator.set_deferred("color", color)
	pass

func set_scene_name(the_scene_name:String) -> void:
	OpenSceneTitle.set_deferred("text", the_scene_name)
	pass

func _request_mind(req:String, args = null) -> void:
	emit_signal("request_mind", req, args)
	pass
