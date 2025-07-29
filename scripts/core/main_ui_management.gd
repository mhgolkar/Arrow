# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Main UI Management
# (general UI functionalities such as tracking main panels and their state of visibility)
class_name MainUserInterface

const PANELS_PATHS = {
	"inspector": "/root/Main/FloatingTools/Control/Inspector",
	"preferences": "/root/Main/Overlays/Control/Preferences",
	"authors": "/root/Main/Overlays/Control/Authors",
	"new_project_prompt":  "/root/Main/Overlays/Control/NewDocument",
	"console": "/root/Main/FloatingTools/Control/Console",
	"about": "/root/Main/Overlays/Control/About",
	"notification": "/root/Main/Overlays/Control/Notification",
}
const PANELS_OPEN_BY_DEFAULT = Settings.PANELS_OPEN_BY_DEFAULT
const BLOCKING_PANELS:Array = Settings.BLOCKING_PANELS
const STATEFUL_PANELS:Array = Settings.STATEFUL_PANELS
const BLOCKING_OVERLAY_PATH = "/root/Main/Overlays/Control/Blocker"
const MAIN_UI_PATHS = {
	"app_menu": "/root/Main/Editor/Top/Bar/AppMenu",
	"quick_preferences": "/root/Main/Editor/Bottom/Bar/Quick/Access/SpecialPreferences",
	"inspector_view_toggle": "/root/Main/Editor/Bottom/Bar/Quick/Access/InspectorVisibility",
}

const THEME_ADJUSTMENT_LAYERS = [
	"/root/Main",
	"/root/Main/Overlays/Control",
	"/root/Main/FloatingTools/Control"
]

class UiManager :
	
	var Main
	var TheTree
	var TheViewport
	var TheWindow
	var PANELS = {}
	var MAIN_UI = {}
	var BLOCKING_OVERLAY
	var _OPEN_PANELS = []
	var _CACHED_THEME_ADJUSTMENT_LAYERS = []
	
	func _init(main) -> void:
		Main = main
		TheTree = main.get_tree()
		TheWindow = TheTree.get_root()
		TheViewport = main.get_viewport()
		# fin Ui components and reference to them
		for component in MAIN_UI_PATHS:
			MAIN_UI[component] = Main.get_node(MAIN_UI_PATHS[component])
		# ... then
		for panel in PANELS_PATHS:
			PANELS[panel] = Main.get_node(PANELS_PATHS[panel])
		# ... and special ones
		BLOCKING_OVERLAY = Main.get_node(BLOCKING_OVERLAY_PATH)
		pass
		
	func register_connections():
		TheViewport.size_changed.connect(self._on_screen_resized)
		MAIN_UI.inspector_view_toggle.toggled.connect(self._on_inspector_view_toggle, CONNECT_DEFERRED)
		MAIN_UI.quick_preferences.quick_preference.connect(self._on_quick_preference, CONNECT_DEFERRED)
		PANELS.preferences.preference_modifications_done.connect(Main.Configs._on_preference_modifications_done, CONNECT_DEFERRED)
		PANELS.preferences.preference_modified.connect(Main.Configs._on_preference_modified, CONNECT_DEFERRED)
		pass
	
	func setup_defaults_on_ui_and_quick_preferences() -> void:
		for default_open_panel in PANELS_OPEN_BY_DEFAULT:
			set_panel_visibility(default_open_panel, true)
			# Note: it also sets MAIN_UI.inspector_view_toggle
		update_quick_preferences_switches_view() # ... to the defaults
		pass
	
	func _on_inspector_view_toggle(new_state:bool) -> void:
		set_panel_visibility("inspector", new_state)
		pass
	
	func _on_quick_preference(new_state:bool, command:String) -> void:
		print_debug(command, ":", new_state)
		Main.set_quick_preferences(command, new_state, true)
		pass
	
	func update_quick_preferences_switches_view() -> void:
		MAIN_UI.quick_preferences.call_deferred("refresh_quick_preferences_menu_view")
		pass
	
	func set_panel_visibility(panel:String, visibility:bool) -> void:
		# first, take care of panel specific behavior ...
			# if the `panel` is blocking/strictly-modal
		if BLOCKING_PANELS.has(panel) :
			BLOCKING_OVERLAY.set_deferred("visible", visibility)
			# or needs any other treatments
		match panel:
			"preferences": 
				PANELS.preferences.call_deferred("refresh_fields_view", Main.Configs.CONFIRMED)
			"inspector":
				MAIN_UI.inspector_view_toggle.set_deferred("button_pressed", visibility)
		# ... then open and track the `panel`
		PANELS[panel].set_deferred("visible", visibility)
		track_open_panels(panel, visibility)
		pass
		
	func toggle_panel_visibility(panel:String) -> void:
		if PANELS.has(panel):
			var visibility = ( ! is_panel_open(panel) )
			set_panel_visibility(panel, visibility)
		else:
			printerr("Unexpected Behavior! Trying to toggle_panel_visibility of nonexistent panel: ", panel)
		pass
	
	# NOTE! There can only be one instance of every panel open
	func is_panel_open(panel:String) -> bool:
		return _OPEN_PANELS.has(panel)
		
	func track_open_panels(panel:String, shall_be:bool) -> void:
		if panel in PANELS :
			var current_state_of_panel = is_panel_open(panel)
			if  current_state_of_panel == true && shall_be == false:
				_OPEN_PANELS.erase(panel)
			elif current_state_of_panel == false && shall_be == true :
				_OPEN_PANELS.append(panel)
			print_debug("Open Panels", _OPEN_PANELS)
		else:
			printerr("Trying to Track None-Existing Panel: ", panel)
		pass
	
	func toggle_fullscreen() -> void:
		var is_fullscreen = (DisplayServer.window_get_mode() >= DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_mode.call_deferred(
			DisplayServer.WindowMode.WINDOW_MODE_WINDOWED if is_fullscreen else DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN
		)
		# Setting the window to full screen forcibly sets the borderless flag to true, so we should set it back to false when not wanted.
		TheWindow.set_deferred("borderless", !is_fullscreen)
		MAIN_UI.app_menu.call_deferred("update_menu_items_view")
		pass

	func toggle_always_on_top() -> void:
		TheWindow.set_deferred("always_on_top", !TheWindow.always_on_top)
		MAIN_UI.app_menu.call_deferred("update_menu_items_view")
		pass
	
	func _on_screen_resized() -> void:
		MAIN_UI.app_menu.call_deferred("update_menu_items_view")
		pass

	func get_theme_adjustment_layers() -> Array:
		if _CACHED_THEME_ADJUSTMENT_LAYERS.size() != THEME_ADJUSTMENT_LAYERS.size() :
			_CACHED_THEME_ADJUSTMENT_LAYERS.clear()
			for adjustment_layer in THEME_ADJUSTMENT_LAYERS:
				_CACHED_THEME_ADJUSTMENT_LAYERS.append( Main.get_node(adjustment_layer) )
		return _CACHED_THEME_ADJUSTMENT_LAYERS

	func reset_theme(by_id:int = 0) -> int:
		if by_id < 0 || by_id > Settings.THEMES.size() :
			by_id = 0
		var theme = Settings.THEMES[by_id].resource
		for adjustment_layer in get_theme_adjustment_layers():
			adjustment_layer.call_deferred("set_theme", theme)
		return by_id

	func reset_language(by_locale:String = "en") -> String:
		PANELS.preferences.reset_language(by_locale)
		return by_locale
	
	func read_panels_state() -> Dictionary:
		var stateful: Dictionary = {}
		for panel in STATEFUL_PANELS:
			var as_node = PANELS[panel]
			@warning_ignore("INCOMPATIBLE_TERNARY")
			var is_open = is_panel_open(panel) if PANELS_OPEN_BY_DEFAULT.has(panel) else null
			stateful[panel] = {
				"size": as_node.get_size(),
				"position": as_node.get_position(),
				"open": is_open,
			}
		return stateful
	
	var _WINDOW_RESTORED: bool = false
	var _PANELS_TRACKED: Dictionary = {}

	func _panels_restoration_after_window() -> void:
		_WINDOW_RESTORED = true
		# We use a timeout to make sure the window has done restoration
		# to reduce the chance of sliding in few corner cases:
		await TheTree.create_timer(0.25).timeout
		restore_panels_state()
		pass
	
	func restore_panels_state(tracked = null) -> void:
		if tracked is Dictionary:
			_PANELS_TRACKED = tracked
		if _WINDOW_RESTORED && _PANELS_TRACKED.size() > 0:
			print_debug("restoring panels state: ", _PANELS_TRACKED)
			for panel in _PANELS_TRACKED:
				var as_node = PANELS[panel]
				var state = _PANELS_TRACKED[panel]
				as_node.call_deferred("_set_size", state.size)
				as_node.call_deferred("_set_position", state.position)
				if state.open is bool:
					self.call_deferred("set_panel_visibility", panel, state.open)
			_PANELS_TRACKED = {}
		pass

	func read_window_state() -> Dictionary:
		return {
			"position": DisplayServer.window_get_position(),
			"size": DisplayServer.window_get_size(),
			"full_screen": DisplayServer.window_get_mode(),
			"always_on_top": TheWindow.always_on_top,
		}
	
	func restore_window(state:Dictionary) -> void:
		print_debug("restoring window state: ", state)
		for tracked in state:
			var condition = state[tracked]
			match tracked:
				"position":
					DisplayServer.window_set_position.call_deferred(condition)
				"size":
					DisplayServer.window_set_size.call_deferred(condition)
				"full_screen":
					DisplayServer.window_set_mode.call_deferred(condition)
				"always_on_top":
					TheWindow.set_deferred("always_on_top", condition)
		# ...
		self.call_deferred("_panels_restoration_after_window")
		pass
	
	# updates view partially or fully depending on the `configuration`
	func update_view_from_configuration(configuration:Dictionary) -> void:
		# print_debug("View updated:", configuration)
		for config in configuration:
			var cfg = configuration[config]
			match config:
				"appearance_theme":
					reset_theme( cfg )
				"language":
					reset_language( cfg )
				"window":
					if cfg is Dictionary:
						restore_window(cfg)
				"panels":
					if cfg is Dictionary:
						restore_panels_state(cfg)
		pass
