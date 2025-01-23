# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Main (root)
extends Node

signal mind_initialized()

@export var _SANDBOX:bool = Settings.RUN_IN_SANDBOX

@onready var TheTree:SceneTree = self.get_tree()
@onready var UI = MainUserInterface.UiManager.new(self)
@onready var Configs = Configuration.ConfigHandler.new(self)
@onready var Mind = CentralMind.Mind.new(self)
@onready var Grid = $/root/Main/Editor/Center/Grid

# Quick Preferences (defaults)
@export var _AUTO_INSPECT:bool = true
@export var _AUTO_NODE_UPDATE:bool = true
@export var _RESET_ON_REINSPECTION:bool = true
@export var _QUICK_NODE_INSERTION:bool = true
@export var _CONNECTION_ASSIST:bool = true
@export var _AUTO_REBUILD_RUNTIME_TEMPLATES:bool = false

func _ready() -> void:
	# print startup messages
	print(Embedded.Text.Welcome_Message)
	print(Embedded.Text.Legal_Notes)
	# get operational
	handle_cli_arguments()
	register_connections()
	Configs.load_configurations()
	UI.setup_defaults_on_ui_and_quick_preferences()
	UI.update_view_from_configuration(Configs.CONFIRMED)
	Mind.post_initialization()
	self.mind_initialized.emit()
	self.set_process_input(true)
	# show about/welcome panel for browser version
	if Html5Helpers.Utils.is_browser():
		toggle_about()
	# and finally, report app state
	print("Sandbox: ", ("ON" if _SANDBOX else "OFF"))
	pass

func handle_cli_arguments():
	var args = Array( OS.get_cmdline_args() )
	# 1.
	if args.has("--manual"):
		var manual_message = Embedded.Text.Manual.format({ "ver" : Settings.ARROW_VERSION, "www": Settings.ARROW_WEBSITE, "cfn": Settings.CONFIG_FILE_NAME })
		print(manual_message)
	# 2.
	if args.has("--sandbox"):
		_SANDBOX = true
	# 3. --config-dir <path>
	var custom_config_path_index = (args.find("--config-dir") + 1)
	if custom_config_path_index > 0 && args.size() > custom_config_path_index :
		Configs._CONFIG_FILE_BASE_DIR = Helpers.Utils.safe_base_dir( args[custom_config_path_index] ) # will stay null or a safe path ending with "/"
	# 4. --work-dir <path>
	var custom_local_app_dir_path_index = (args.find("--work-dir") + 1)
	if custom_local_app_dir_path_index > 0 && args.size() > custom_local_app_dir_path_index :
		var new_app_local_dir_path = args[custom_local_app_dir_path_index]
		if new_app_local_dir_path is String && Helpers.Utils.is_abs_or_rel_path(new_app_local_dir_path):
			self.call_deferred("change_local_app_dir_path_preference_in_runtime", new_app_local_dir_path)
	pass

func change_local_app_dir_path_preference_in_runtime(new_app_local_dir_path: String):
	# following will call the `dynamically_update_local_app_dir` back from main after some work
	Configs.emulate_preference_modification_and_save("app_local_dir_path", new_app_local_dir_path)
	pass

func dynamically_update_local_app_dir(new_app_local_dir_path:String) -> void:
	if new_app_local_dir_path is String && (new_app_local_dir_path.is_absolute_path() || new_app_local_dir_path.is_relative_path()):
		Mind.ProMan.hold_local_app_dir(new_app_local_dir_path)
		Mind.reset_project_save_status(false)
		Mind.load_projects_list()
	else:
		printerr("Wrong Operation! Trying to dynamically update local app directory with wrong argument: ", new_app_local_dir_path)
	pass

func register_connections() -> void:
	UI.register_connections()
	pass

func set_quick_preferences(preference:String, new_state:bool, refresh_view:bool = true) -> void:
	match preference:
		"auto_inspect":
			_AUTO_INSPECT = new_state
		"auto_node_update":
			_AUTO_NODE_UPDATE = new_state
		"reset_on_reinspection":
			_RESET_ON_REINSPECTION = new_state
		"quick_node_insertion":
			_QUICK_NODE_INSERTION = new_state
			Grid._ALLOW_QUICK_NODE_INSERTION = new_state
		"connection_assist":
			_CONNECTION_ASSIST = new_state
			Grid._ALLOW_ASSISTED_CONNECTION = new_state
		"auto_rebuild_runtime_templates":
			_AUTO_REBUILD_RUNTIME_TEMPLATES = new_state
	if refresh_view != false :
		UI.update_quick_preferences_switches_view()
	pass

func toggle_quick_preferences(preference:String, refresh_view:bool = true):
	var new_state = null
	match preference:
		"auto_inspect":
			new_state = ( ! _AUTO_INSPECT )
		"auto_node_update":
			new_state = ( ! _AUTO_NODE_UPDATE )
		"reset_on_reinspection":
			new_state = ( ! _RESET_ON_REINSPECTION )
		"quick_node_insertion":
			new_state = ( ! _QUICK_NODE_INSERTION )
		"connection_assist":
			new_state = ( ! _CONNECTION_ASSIST )
		"auto_rebuild_runtime_templates":
			new_state = ( ! _AUTO_REBUILD_RUNTIME_TEMPLATES )
	if new_state != null:
		set_quick_preferences(preference, new_state, refresh_view)
	return new_state

func toggle_about() -> void:
	UI.toggle_panel_visibility("about")
	pass

func toggle_authors() -> void:
	UI.toggle_panel_visibility("authors")
	pass

func store_window_state() -> void:
	var window_state = UI.read_window_state()
	Configs.TEMPORARY.window = window_state
	Configs.save_configurations_and_confirm(Configs.TEMPORARY, null, false)
	print_debug("window state saved: ", Configs.CONFIRMED.window)
	pass

func store_panels_state() -> void:
	var panels_state = UI.read_panels_state()
	Configs.TEMPORARY.panels = panels_state
	Configs.save_configurations_and_confirm(Configs.TEMPORARY, null, false)
	print_debug("panel state saved: ", Configs.CONFIRMED.panels)
	pass

func safe_quit_app() -> void:
	store_panels_state()
	store_window_state()
	await TheTree.process_frame
	Mind.close_project(false, true)
	pass

func quit_app(exit_code:int = 0) -> void:
	if exit_code != 0:
		printerr("Quitting app due to unexpected behavior!")
	if Html5Helpers.Utils.is_browser():
		Html5Helpers.Utils.close()
	else:
		TheTree.quit(exit_code)
	pass

# handling quit signal(s) from window manager
func _notification(what) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		safe_quit_app()
	pass

# shortcuts (keybinding/action)
func _input(event:InputEvent) -> void:
	var _handled = Mind.handle_shortcuts(event)
	pass
