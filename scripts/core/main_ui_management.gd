# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Main UI Management
# (general UI functionalities such as tracking main panels and their state of visibility)
class_name MainUserInterface

const PANELS_PATHS = Addressbook.PANELS
const PANELS_OPEN_BY_DEFAULT = Settings.PANELS_OPEN_BY_DEFAULT
const BLOCKING_PANELS:Array = Settings.BLOCKING_PANELS
const BLOCKING_OVERLAY_PATH = Addressbook.BLOCKING_OVERLAY
const MAIN_UI_PATHS = {
	"app_menu": Addressbook.EDITOR.APP_MENU,
	"quick_preferences": Addressbook.EDITOR.QUICK_PREFERENCES_MENU_BUTTON,
	"inspector_view_toggle": Addressbook.EDITOR.INSPECTOR_VIEW_TOGGLE,
}

const THEME_ADJUSTMENT_LAYERS = Addressbook.THEME_ADJUSTMENT_LAYERS

class UiManager :
	
	var Main
	var TheTree
	var PANELS = {}
	var MAIN_UI = {}
	var BLOCKING_OVERLAY
	var _OPEN_PANELS = []
	var _CACHED_THEME_ADJUSTMENT_LAYERS = []
	
	func _init(main) -> void:
		Main = main
		TheTree = main.get_tree()
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
		TheTree.connect("screen_resized", self, "_on_screen_resized")
		MAIN_UI.inspector_view_toggle.connect("toggled", self, "_on_inspector_view_toggle", [], CONNECT_DEFERRED)
		MAIN_UI.quick_preferences.connect("quick_preference", self, "_on_quick_preference", [], CONNECT_DEFERRED)
		PANELS.preferences.connect("preference_modifications_done", Main.Configs, "_on_preference_modifications_done", [], CONNECT_DEFERRED)
		PANELS.preferences.connect("preference_modified", Main.Configs, "_on_preference_modified", [], CONNECT_DEFERRED)
		pass
	
	func setup_defaults_on_ui_and_quick_preferences() -> void:
		for default_open_panel in PANELS_OPEN_BY_DEFAULT:
			set_panel_visibility(default_open_panel, true)
			# Note: it also sets MAIN_UI.inspector_view_toggle
		update_quick_preferences_switchs_view() # ... to the defaults
		pass
	
	func _on_inspector_view_toggle(new_state:bool) -> void:
		set_panel_visibility("inspector", new_state)
		pass
	
	func _on_quick_preference(new_state:bool, command:String) -> void:
		print_debug(command, ":", new_state)
		Main.set_quick_preferences(command, new_state, true)
		pass
	
	func update_quick_preferences_switchs_view() -> void:
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
				MAIN_UI.inspector_view_toggle.set_deferred("pressed", visibility)
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
		OS.set_deferred("window_fullscreen", (! OS.is_window_fullscreen()) )
		pass

	func toggle_always_on_top() -> void:
		OS.set_window_always_on_top( ! OS.is_window_always_on_top() )
		# `always on top / keep above` is not detected by `screen_resized` so we do update manually
		MAIN_UI.app_menu.call_deferred("update_menu_items_view")
		pass
	
	# NOTE: borderless window seems not supported perfectly yet; resize and drag doesn't work as expected.
#	func toggle_borderless_window() -> void:
#		OS.call_deferred("set_borderless_window", (! OS.get_borderless_window()) )
#		# TODO: Keep in the preferences/config file
#		pass
	
	func toggle_maximized() -> void:
		OS.set_window_maximized(! OS.is_window_maximized())
		pass
	
	func minimize_window() -> void:
		OS.set_deferred("window_minimized" , true )
		pass
	
	# NOTE: there seems to be some glitches on some desktop environments:
	# detects 'fullscreen' well, 'maximize/restore' selectively and 'always on top / keep above' almost nowhere
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

	func reset_language(by_id:int = 0) -> int:
		if by_id < 0 || by_id > Settings.SUPPORTED_UI_LANGUAGES.size() :
			by_id = 0
		var lang = Settings.SUPPORTED_UI_LANGUAGES[by_id]
		var locale = lang.locale
		# TODO: i18n
		print_debug("TODO!! NOT IMPLEMENTED YET! UI Language reset to: ", lang)
		return by_id
	
	func reset_scale(factor) -> Vector2:
		if (factor is Vector2) == false:
			var scale = float(factor)
			factor = Vector2(scale, scale)
			factor = factor / Settings.SCALE_RANGE_CENTER
		# TODO: currently there is no satisfying way to scale UI, may be a better time.
		return factor
	
	func read_window_state() -> Dictionary:
		return {
			"position": OS.get_window_position(),
			"size": OS.get_window_size(),
			"full_screen": OS.is_window_fullscreen(),
			"always_on_top": OS.is_window_always_on_top(),
			"maximized": OS.is_window_maximized(),
			# "borderless": OS.get_borderless_window(),
		}
		pass
	
	func restore_window(state:Dictionary) -> void:
		print_debug("restoring window state: ", state)
		for tracked in state:
			var condition = state[tracked]
			match tracked:
				"position":
					OS.call_deferred("set_window_position", condition)
				"size":
					OS.call_deferred("set_window_size", condition)
				"full_screen":
					OS.call_deferred("set_window_fullscreen", condition)
				"always_on_top":
					OS.call_deferred("set_window_always_on_top", condition)
				"maximized":
					OS.call_deferred("set_window_maximized", condition)
				# "borderless":
					# OS.call_deferred("set_borderless_window", condition)
		pass
	
	# updates view partially or fully depending on the `configuration`
	func update_view_from_configuration(configuration:Dictionary) -> void:
		print_debug("View updated:", configuration)
		for config in configuration:
			var cfg = configuration[config]
			match config:
				"ui_scale":
					reset_scale( cfg )
				"appearance_theme":
					reset_theme( cfg )
				"language":
					reset_language( cfg )
				"window":
					if cfg is Dictionary:
						restore_window(cfg)
		pass
