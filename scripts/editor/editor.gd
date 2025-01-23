# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Editor
# (base)
extends Control

signal request_mind()

@onready var Main = get_tree().get_root().get_child(0)

# top
	# history
@onready var HistoryUndo = $/root/Main/Editor/Top/Bar/History/Tools/Undo
@onready var HistoryRedo = $/root/Main/Editor/Top/Bar/History/Tools/Redo
	# title
@onready var ProjectTitle = $/root/Main/Editor/Top/Bar/ProjectTitle
	# save
@onready var SaveButton = $/root/Main/Editor/Top/Bar/Save
@onready var SaveIndicator = $/root/Main/Editor/Top/Bar/Save/Indicator
	# play modes
@onready var PlayFromSelectedNodeButton = $/root/Main/Editor/Top/Bar/Play/From/SelectedNode
@onready var PlayFromSceneEntryButton = $/root/Main/Editor/Top/Bar/Play/From/SceneEntry
@onready var PlayFromProjectEntryButton = $/root/Main/Editor/Top/Bar/Play/From/ProjectEntry
@onready var PlayFromLeftConsoleButton = $/root/Main/Editor/Top/Bar/Play/From/ShowConsole
# bottom
@onready var OpenSceneTitle = $/root/Main/Editor/Bottom/Bar/SceneTitle

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	HistoryUndo.pressed.connect(self._request_mind.bind("history_rotate", -1))
	HistoryRedo.pressed.connect(self._request_mind.bind("history_rotate", +1))
	SaveButton.pressed.connect(self._request_mind.bind("save_project"))
	PlayFromSceneEntryButton.pressed.connect(self._request_mind.bind("console_play_from", "scene_entry"))
	PlayFromProjectEntryButton.pressed.connect(self._request_mind.bind("console_play_from", "project_entry"))
	PlayFromLeftConsoleButton.pressed.connect(self._request_mind.bind("console_play_from", "left_console"))
	PlayFromSelectedNodeButton.pressed.connect(self._request_mind.bind("console_play_from", "selected_node"))
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

func reset_history_tools(current_index: int, history_size: int, is_locked: bool = false) -> void:
	HistoryUndo.set_disabled( is_locked || history_size == 0 || current_index <= 0)
	HistoryRedo.set_disabled( is_locked || history_size == 0 || current_index >= (history_size - 1))
	pass

func _request_mind(req:String, args = null) -> void:
	self.request_mind.emit(req, args)
	pass
