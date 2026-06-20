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
	"left_dock": "/root/Main/Editor/Center/LeftDock",
	"right_dock": "/root/Main/Editor/Center/RightDock",
	"left_dock_highlight": "/root/Main/Editor/Center/LeftDock/Highlight",
	"right_dock_highlight": "/root/Main/Editor/Center/RightDock/Highlight",
	"center": "/root/Main/Editor/Center",
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
	var _PANEL_DOCK_STATE = {}
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
		MAIN_UI.center.drag_ended.connect(self._on_center_docks_drag_ended, CONNECT_DEFERRED)
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
		
	func _on_panel_drag_started(panel_node) -> void:
		var panel_name = get_panel_name(panel_node)
		# If panel is/was docked ...
		if _PANEL_DOCK_STATE.has(panel_name) && _PANEL_DOCK_STATE[panel_name].has("mode") && _PANEL_DOCK_STATE[panel_name].mode == "docked":
			# Undock
			set_panel_dock_state(panel_name, false, null, false)
			# Restore size
			if panel_node.has_meta("size"):
				var viewport_size = Main.get_viewport_rect().size
				panel_node.call_deferred("_set_size", panel_node.get_meta("size") * viewport_size)
		pass
		
	func _on_panel_dragged(_panel_node) -> void:
		var mouse = Main.get_global_mouse_position()
		highlight_dock_slot(mouse)
		pass
		
	func _on_panel_drag_ended(panel_node) -> void:
		var panel_name = get_panel_name(panel_node)
		var global_mouse_position = Main.get_global_mouse_position()
		var viewport_size = Main.get_viewport_rect().size
		
		# hide highlights
		MAIN_UI["right_dock_highlight"].visible = false
		MAIN_UI["left_dock_highlight"].visible = false
		
		# right dock
		if global_mouse_position.x > viewport_size.x - Settings.DOCK_THRESHOLD:
			set_panel_dock_state(panel_name, true, {"dock": "right", "position": get_dock_index_from_position("right_dock", global_mouse_position)})
		# left dock
		elif global_mouse_position.x < 0 + Settings.DOCK_THRESHOLD:
			set_panel_dock_state(panel_name, true, {"dock": "left", "position": get_dock_index_from_position("left_dock", global_mouse_position)})
		# undock (only if panel hasn't been docked previously)
		#elif _PANEL_DOCK_STATE.has(panel_name) && _PANEL_DOCK_STATE[panel_name].has("mode") && _PANEL_DOCK_STATE[panel_name].mode == "docked":
		#	set_panel_dock_state(panel_name, false, null, false)
		
		# hide docks without panels
		if not is_dock_occupied("right"):
			MAIN_UI["right_dock"].visible = false
		if not is_dock_occupied("left"):
			MAIN_UI["left_dock"].visible = false
		pass
	
	func recalculate_dock_panel_split(dock_name:String) -> void:
		var panel_count = get_dock_panel_count(translate_dock_node_name_to_position_name(dock_name), true)
		var panel_height = (1.0 / panel_count) * MAIN_UI[dock_name].size.y
		for index in (panel_count - 1):
			MAIN_UI[dock_name].split_offsets[index] = panel_height * (index + 1)
		pass
		
	func insert_panel_at_index(dock_name:String, panel_node, index:int = -1) -> void:
		MAIN_UI[dock_name].add_child(panel_node)
		MAIN_UI[dock_name].move_child(panel_node, index)
		MAIN_UI[dock_name].queue_sort()
		# Update index of all other panels (not this one since it's being stored in set_panel_dock_state() anyway)
		for panel in _PANEL_DOCK_STATE:
			var as_node = PANELS[panel]
			# if panel isn't current panel and panel is docked in current dock
			if as_node != panel_node && _PANEL_DOCK_STATE[panel].has("mode") && _PANEL_DOCK_STATE[panel].mode == "docked" \
					&& _PANEL_DOCK_STATE[panel].has("slot") && _PANEL_DOCK_STATE[panel].slot.has("dock") \
					&& _PANEL_DOCK_STATE[panel].slot.dock == translate_dock_node_name_to_position_name(dock_name) \
					&& _PANEL_DOCK_STATE[panel].slot.has("position"):
				_PANEL_DOCK_STATE[panel].slot.position = as_node.get_index()
		pass
		
	func highlight_dock_slot(global_mouse_position) -> void:
		var viewport_size = Main.get_viewport_rect().size
		# show right dock highlight
		if global_mouse_position.x > viewport_size.x - Settings.DOCK_THRESHOLD:
			if MAIN_UI["right_dock"].visible == false:
				MAIN_UI["right_dock"].visible = true
			MAIN_UI["right_dock_highlight"].visible = true
			# move highlight to appropiate position
			MAIN_UI["right_dock"].move_child(MAIN_UI["right_dock_highlight"], get_dock_index_from_position("right_dock", global_mouse_position))
		else:
			if not is_dock_occupied("right"):
				MAIN_UI["right_dock"].visible = false
			MAIN_UI["right_dock_highlight"].visible = false
		# show left dock highlight
		if global_mouse_position.x < 0 + Settings.DOCK_THRESHOLD:
			if MAIN_UI["left_dock"].visible == false:
				MAIN_UI["left_dock"].visible = true
			MAIN_UI["left_dock_highlight"].visible = true
			# move highlight to appropiate position
			MAIN_UI["left_dock"].move_child(MAIN_UI["left_dock_highlight"], get_dock_index_from_position("left_dock", global_mouse_position))
		else:
			if not is_dock_occupied("left"):
				MAIN_UI["left_dock"].visible = false
			MAIN_UI["left_dock_highlight"].visible = false
		pass
	
	func is_dock_occupied(dock:String) -> bool:
		for panel in _PANEL_DOCK_STATE:
			# If panel is docked, panel dock is requested dock and panel is open
			if _PANEL_DOCK_STATE[panel].has("mode") && _PANEL_DOCK_STATE[panel].mode == "docked" \
					&& _PANEL_DOCK_STATE[panel].has("slot") && _PANEL_DOCK_STATE[panel].slot.has("dock") \
					&& _PANEL_DOCK_STATE[panel].slot.dock == dock && is_panel_open(panel):
				return true
		return false
		
	func get_dock_panel_count(dock:String, open_only:bool=false) -> int:
		var count = 0
		for panel in _PANEL_DOCK_STATE:
			# If panel is docked and panel dock is requested dock
			if _PANEL_DOCK_STATE[panel].has("mode") && _PANEL_DOCK_STATE[panel].mode == "docked" \
					&& _PANEL_DOCK_STATE[panel].has("slot") && _PANEL_DOCK_STATE[panel].slot.has("dock") \
					&& _PANEL_DOCK_STATE[panel].slot.dock == dock && (is_panel_open(panel) if open_only else true):
				count += 1
		return count
		
	func get_dock_index_from_position(dock_name:String, global_mouse_position) -> int:
		var mouse_y = MAIN_UI[dock_name].make_canvas_position_local(global_mouse_position).y
		var dock_max_y = MAIN_UI[dock_name].size.y
		var dock_panel_count = get_dock_panel_count(translate_dock_node_name_to_position_name(dock_name)) + 1 # Add 1 to account for highlight
		var dock_section_height = dock_max_y / dock_panel_count
		for dock_section in dock_panel_count:
			if mouse_y > dock_section_height * dock_section && mouse_y < dock_section_height * (dock_section + 1):
				return dock_section
		if mouse_y <= 0:
			return 0
		if mouse_y >= dock_max_y:
			return -1
		printerr("Dock index calculation failed")
		return -1
		
	# TODO Maybe make obsolete by using same string for both dock node name and position name?
	# I'd like to avoid storing position as "right_dock" though, and I'd like to avoid using only "right" as dock node name...
	func translate_dock_node_name_to_position_name(dock_name:String) -> String:
		if dock_name == "right_dock":
			return "right"
		elif dock_name == "left_dock":
			return "left"
		return ""
		
	func update_dock_visibility() -> void:
		if is_dock_occupied("left"):
			MAIN_UI["left_dock"].visible = true
		else:
			MAIN_UI["left_dock"].visible = false
		if is_dock_occupied("right"):
			MAIN_UI["right_dock"].visible = true
		else:
			MAIN_UI["right_dock"].visible = false
			
		# Await for frame to be processed to make sure split_offsets[1] exists if both panels have been shown
		await TheTree.process_frame
		# Restore panel size
		if MAIN_UI["left_dock"].visible == true && MAIN_UI["center"].has_meta("left_offset") && MAIN_UI["center"].get_meta("left_offset") != 0 \
				&& MAIN_UI["right_dock"].visible == true && MAIN_UI["center"].has_meta("right_offset") && MAIN_UI["center"].get_meta("right_offset") != 0:
			MAIN_UI["center"].split_offsets[0] = MAIN_UI["center"].get_meta("left_offset")
			MAIN_UI["center"].split_offsets[1] = MAIN_UI["center"].get_meta("right_offset")
		elif MAIN_UI["left_dock"].visible == true && MAIN_UI["center"].has_meta("left_offset") && MAIN_UI["center"].get_meta("left_offset") != 0:
			MAIN_UI["center"].split_offsets[0] = MAIN_UI["center"].get_meta("left_offset")
		elif MAIN_UI["right_dock"].visible == true && MAIN_UI["center"].has_meta("right_offset") && MAIN_UI["center"].get_meta("right_offset") != 0:
			MAIN_UI["center"].split_offsets[0] = MAIN_UI["center"].get_meta("right_offset")
		# Resize panels in dock
		if MAIN_UI["left_dock"].visible == true:
			recalculate_dock_panel_split("left_dock")
		if MAIN_UI["right_dock"].visible == true:
			recalculate_dock_panel_split("right_dock")
		pass
	
	func get_panel_name(panel_node) -> String:
		for panel_name in PANELS:
			if PANELS[panel_name] == panel_node:
				return panel_name
		return ""
		
	func _on_center_docks_drag_ended() -> void:
		if is_dock_occupied("left") && is_dock_occupied("right"):
			MAIN_UI["center"].set_meta("left_offset", MAIN_UI["center"].split_offsets[0])
			MAIN_UI["center"].set_meta("right_offset", MAIN_UI["center"].split_offsets[1])
		elif is_dock_occupied("left"):
			MAIN_UI["center"].set_meta("left_offset", MAIN_UI["center"].split_offsets[0])
		elif is_dock_occupied("right"):
			MAIN_UI["center"].set_meta("right_offset", MAIN_UI["center"].split_offsets[0])
		pass
	
	func read_docks_state() -> Dictionary:
		# TODO implement saving vertical panel sizes of left and right dock (kinda redundant for now since only two panels exist)
		var left_dock_size = 0
		var right_dock_size = 0
		# Read split offsets directly from HSplitContainer if possible, from metadata if not
		if is_dock_occupied("left") && is_dock_occupied("right"):
			left_dock_size = MAIN_UI["center"].split_offsets[0]
			right_dock_size = MAIN_UI["center"].split_offsets[1]
		elif is_dock_occupied("left"):
			left_dock_size = MAIN_UI["center"].split_offsets[0]
			right_dock_size = MAIN_UI["center"].get_meta("right_offset")
		elif is_dock_occupied("right"):
			left_dock_size = MAIN_UI["center"].get_meta("left_offset")
			right_dock_size = MAIN_UI["center"].split_offsets[0]
		else:
			left_dock_size = MAIN_UI["center"].get_meta("left_offset")
			right_dock_size = MAIN_UI["center"].get_meta("right_offset")
		return {"left": left_dock_size, "right": right_dock_size}
	
	func restore_docks_state(config = null) -> void:
		# TODO implement restoring vertical panel sizes of left and right dock (kinda redundant for now since only two panels exist)
		# Write data into metadata, since docks won't be open at this point and writing into split_offsets[] will not work
		# Actually restoring panel size happens in update_dock_visibility()
		# If value not in config file set to default width
		if config.has("left") && config.left != 0:
			MAIN_UI["center"].set_meta("left_offset", config.left)
		else:
			MAIN_UI["center"].set_meta("left_offset", Settings.DEFAULT_PANEL_WIDTH)
		if config.has("right") && config.right != 0:
			MAIN_UI["center"].set_meta("right_offset", config.right)
		else:
			MAIN_UI["center"].set_meta("right_offset", Settings.DEFAULT_PANEL_WIDTH)
		pass
	
	func set_panel_dock_state(panel:String, docked:bool, slot=null, update_position:bool=true) -> void:
		var viewport_size = Main.get_viewport_rect().size
		var as_node = PANELS[panel]
		if docked && slot != null && slot is Dictionary && slot.has("dock") && slot.dock is String:
			# If panel wasn't docked, get panel size/position and store in metadata
			if  not _PANEL_DOCK_STATE.has(panel) || (_PANEL_DOCK_STATE[panel].has("mode") && _PANEL_DOCK_STATE[panel].mode != "docked"):
				as_node.set_meta("size", as_node.get_size() / viewport_size)
				as_node.set_meta("position", as_node.get_global_position() / viewport_size)
			as_node.dock_panel(true, slot)
			_PANEL_DOCK_STATE[panel] = {"mode": "docked", "slot": slot.duplicate()}
			update_dock_visibility()
		else:
			as_node.dock_panel(false)
			_PANEL_DOCK_STATE[panel] = {"mode": "floating"}
			# Get panel size/position from metadata to restore to previous settings
			if as_node.has_meta("size"):
				as_node.call_deferred("_set_size", as_node.get_meta("size") * viewport_size)
			if as_node.has_meta("position") && update_position:
				as_node.call_deferred("_set_position", as_node.get_meta("position") * viewport_size)
			update_dock_visibility()
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
		update_dock_visibility()
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
		
	func change_ui_scaling(scaling_factor:float) -> void:
		Main.get_window().content_scale_factor = scaling_factor
		pass
	
	func read_panels_state() -> Dictionary:
		var stateful: Dictionary = {}
		for panel in STATEFUL_PANELS:
			var as_node = PANELS[panel]
			@warning_ignore("INCOMPATIBLE_TERNARY")
			var is_open = is_panel_open(panel) if PANELS_OPEN_BY_DEFAULT.has(panel) else null
			# Save Panel position in relation to viewport size
			var viewport_size = Main.get_viewport_rect().size
			var mode = null
			var slot = null
			var size = as_node.get_size() / viewport_size
			var position = as_node.get_global_position() / viewport_size
			if _PANEL_DOCK_STATE.has(panel) && _PANEL_DOCK_STATE[panel].has("mode"):
				mode = _PANEL_DOCK_STATE[panel].mode
				if _PANEL_DOCK_STATE[panel].mode == "docked" && _PANEL_DOCK_STATE[panel].has("slot"):
					slot = _PANEL_DOCK_STATE[panel].slot
					# Get size/position from metadata
					if as_node.has_meta("size"):
						size = as_node.get_meta("size", null)
					if as_node.has_meta("position"):
						position = as_node.get_meta("position", null)
			stateful[panel] = {
				"size": size,
				"position": position,
				"open": is_open,
				"mode": mode,
				"slot": slot
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
			# Restore panels in relation to viewport size
			var viewport_size = Main.get_viewport_rect().size
			for panel in _PANELS_TRACKED:
				var as_node = PANELS[panel]
				var state = _PANELS_TRACKED[panel]
				if state.has("mode") && state.mode == "docked" && state.has("slot"):
					set_panel_dock_state(panel, true, state.slot)
					# "Backup" size and position data in metadata
					if state.has("size"):
						as_node.set_meta("size", state.size)
					if state.has("position"):
						as_node.set_meta("position", state.position)
				else:
					_PANEL_DOCK_STATE[panel] = {"mode": "floating"}
					if state.has("size") && state.size.x < 1 && state.size.x > 0 && state.size.y < 1 && state.size.y > 0:
						as_node.call_deferred("_set_size", state.size * viewport_size)
					if state.has("position") && state.position.x < 1 && state.position.x > 0 && state.position.y < 1 && state.position.y > 0:
						as_node.call_deferred("_set_global_position", state.position * viewport_size)
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
					reset_theme(cfg)
				"language":
					reset_language(cfg)
				"ui_scaling":
					change_ui_scaling(cfg)
				"window":
					if cfg is Dictionary:
						restore_window(cfg)
				"panels":
					if cfg is Dictionary:
						restore_panels_state(cfg)
				"docks":
					if cfg is Dictionary:
						restore_docks_state(cfg)
		pass
