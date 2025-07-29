# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Central Mind
# (the core!)
class_name CentralMind

const PREF_PANEL = "/root/Main/Overlays/Control/Preferences"
const EDITOR = "/root/Main/Editor"
const GRID = "/root/Main/Editor/Center/Grid"
const INSPECTOR = "/root/Main/FloatingTools/Control/Inspector"
const QUERY = "/root/Main/Editor/Bottom/Bar/Query"
const GRID_CONTEXT_MENU = "/root/Main/FloatingTools/Control/Context"
const NEW_PROJECT_PROMPT = "/root/Main/Overlays/Control/NewDocument"
const PATH_DIALOG = "/root/Main/Overlays/Control/PathDialog"
const CONSOLE = "/root/Main/FloatingTools/Control/Console"
const NOTIFIER = "/root/Main/Overlays/Control/Notification"
const AUTHORS = "/root/Main/Overlays/Control/Authors"

# nodes which may send `request_mind` signal
const TRANSMITTERS = [
	PREF_PANEL,
	EDITOR,
	GRID, GRID_CONTEXT_MENU,
	INSPECTOR, QUERY,
	NEW_PROJECT_PROMPT,
	CONSOLE,
	AUTHORS,
]

const NODE_INITIAL_NAME_TEMPLATE = Settings.NODE_INITIAL_NAME_TEMPLATE
const NODE_INITIAL_NAME_PREFIX_FOR_SCENES = Settings.NODE_INITIAL_NAME_PREFIX_FOR_SCENES
const NODE_INITIAL_NAME_PREFIX_FOR_MACROS = Settings.NODE_INITIAL_NAME_PREFIX_FOR_MACROS

class Mind :
	
	var Main
	var Editor
	var Grid
	var Inspector
	var Query
	var NewProjectPrompt
	var PathDialog
	var Console
	var Notifier
	var Flaker
	var Authors
	
	var ProMan # ProjectManager
	
	var NODE_TYPES_LIST
	
	# the active project (in-memory)
	var _PROJECT:Dictionary = {}
	var _CURRENT_OPEN_SCENE_ID:int = -1
	var _SELECTED_NODES_IDS:Array = [] # index[0] is the last selected
	
	# in-memory snapshots
	var _MASTER_PROJECT_SAFE:Dictionary
	var _SNAPSHOTS:Array = [] # [ { version:string, time:{}, project:{}<project-clone>, ... }, ... ]
	var _SNAPSHOTS_COUNT_PURE_ONES:int = -1 # number of snapshots that are made from the project itself, not another snapshot
	var _SNAPSHOT_INDEX_OF_PREVIEW:int = -1
	
	var _CLIPBOARD:Dictionary = {
		"MODE": Settings.CLIPBOARD_MODE.EMPTY,
		"DATA": []
	}

	var _HISTORY:Dictionary = {
		"MEMORY": [],
		"INDEX": -1,
	}
	
	var _BROWSER_READER_HELPER = Html5Helpers.Reader.new()
	
	func _init(main) -> void:
		Main = main
		pass
	
	func post_initialization() -> void:
		# instance project manager
		var _aldp = Main.Configs.CONFIRMED.app_local_dir_path
		ProMan = ProjectManagement.ProjectManager.new(_aldp, Main)
		# get references
		Editor = Main.get_node(EDITOR)
		Grid = Main.get_node(GRID)
		Inspector = Main.get_node(INSPECTOR)
		Query = Main.get_node(QUERY)
		NewProjectPrompt = Main.get_node(NEW_PROJECT_PROMPT)
		PathDialog = Main.get_node(PATH_DIALOG)
		Console = Main.get_node(CONSOLE)
		Notifier = Main.get_node(NOTIFIER)
		Authors = Main.get_node(AUTHORS)
		# then ...
		register_connections()
		load_node_types()
		load_projects_list()
		# and finally, create a new blank project
		open_new_blank_project(true)
		pass
	
	func register_connections() -> void:
		# `request_mind` transmitters
		for t in TRANSMITTERS:
			var tx = Main.get_node(t)
			tx.connect("request_mind", self.central_event_dispatcher.bind(t, tx))
		pass
	
	func load_node_types() -> void:
		var node_types_handler = NodeTypes.NodeTypesHandler.new(Main)
		NODE_TYPES_LIST = node_types_handler.load_node_types()
		# print_debug("Node types loaded: ", NODE_TYPES_LIST)
		pass
		
	func load_projects_list() -> void:
		var listed_projects = ProMan.get_projects_listed_by_id()
		Inspector.Tab.Project.call_deferred("list_local_projects", listed_projects, true)
		pass
	
	const SAVED_MODIFIER_EVENTS = [
		# CAUTION! list any request to the central mind that modifies content of the active project here
		"insert_node",
		"quick_insert_node",
		"update_resource",
		"remove_resource",
		"update_node_map",
		"create_variable",
		"create_character",
		"create_scene",
		"remove_selected_nodes",
		"set_project_title",
		"restore_snapshot",
		"update_author",
		"remove_author",
		"update_chapter",
	]
	func central_event_dispatcher(request:String, args=null, _t_address=null, _tx_node=null) -> void:
		print_debug("Mind:: Request : ", request, " (", args, ") ")
		match request:
			"new_project":
				match args:
					"blank":
						open_new_blank_project()
					"from_current":
						save_project()
					"from_file":
						prompt_path_to(self, "import_project_from_file", [-2], Settings.PATH_DIALOG_PROPERTIES.PROJECT_FILE.OPEN)
					"from_browsed":
						if Html5Helpers.Utils.is_browser():
							_BROWSER_READER_HELPER.read_file_then(self.import_project_from_browsed)
			"node_selection":
				track_nodes_selection(args, true)
			"node_deselection":
				track_nodes_selection(args, false)
			"branch_selection":
				select_branch(args[0], args[1], args[2])
			"insert_node":
				create_insert_nodes(args.nodes, args.offset)
			"quick_insert_node":
				quick_insert_node(args.node, args.offset, (args.connection if args.has("connection") else null))
			"update_resource":
				update_resource(args.id, args.modification, args.field, (args.has('auto') && args.auto == true))
			"remove_resource":
				remove_resource(args.id, args.field)
			"update_node_map":
				update_node_map(args.id, args)
			"create_variable":
				create_new_variable(args)
			"create_character":
				create_new_character()
			"switch_scene":
				if args is int && args >= 0 :
					scene_editorial_open(args)
				else:
					load_where_user_left_last_time()
			"create_scene":
				create_new_scene(args)
			"inspect_node":
				inspect_node(args, -1, true)
			"query_nodes":
				query_nodes(args)
			"remove_selected_nodes":
				if _SELECTED_NODES_IDS.size() > 0:
					batch_remove_resources(_SELECTED_NODES_IDS, "nodes", true)
			"clipboard_push_selection":
				if _SELECTED_NODES_IDS.size() > 0:
					clipboard_push(_SELECTED_NODES_IDS, args)
			"os_clipboard_push":
				os_clipboard_push(args[0], args[1], args[2])
			"os_clipboard_pull":
				os_clipboard_pull(args[0], args[1])
			"clean_clipboard":
				clipboard_clear()
			"clipboard_pull":
				clipboard_pull(args)
			"save_project":
				save_project()
			"register_project_and_save_from_open":
				register_project_and_save_from_open(args.title, args.filename)
			"remove_local_project":
				try_remove_local_project(args)
			"open_local_project":
				open_project(args)
			"close_project":
				close_project()
			"revert_project":
				confirm_revert_project()
			"set_project_title":
				reset_project_title(args)
			"update_author":
				update_project_author(args.id, args.info, args.active)
			"remove_author":
				remove_project_author(args)
			"update_chapter":
				update_project_chapter(args)
			"take_snapshot":
				take_snapshot()
			"toggle_snapshot_preview":
				if args is int && args >= 0:
					preview_snapshot(args)
				else:
					return_to_master_project()
			"restore_snapshot":
				try_restore_snapshot(args)
			"remove_snapshot":
				try_remove_snapshot(args)
			"prompt_path_for_requester":
				prompt_path_to(
					(args.callback_host if args.has("callback_host") else _tx_node),
					args.callback, args.arguments, args.options
				)
			"export_project":
				export_project_as(args.format, args.filename, args.base_directory)
			"export_project_from_browser":
				export_project_from_browser(args)
			"console_play_from":
				play_from(args)
			"console_clear":
				console( -1, true )
			"console_close":
				console( -1, false, false )
			"console_play_node":
				console( args.id, false, null, args.slot )
			"locate_node_on_grid":
				locate_node_on_grid(args.id, args.highlight, (args.force if args.has("force") else true))
			"history_rotate":
				history_rotate(args)
			"show_error":
				show_error(
					args.heading, args.message,
					(args.color if args.has("color") else Settings.WARNING_COLOR),
					(args.actions if args.has("actions") else [])
				)
		if SAVED_MODIFIER_EVENTS.has(request):
			reset_project_save_status(false)
		pass
		
	func drop_current_project() -> void:
		_PROJECT.clear()
		clean_snapshots_all()
		clipboard_clear()
		forget_history()
		_CURRENT_OPEN_SCENE_ID = -1
		_SELECTED_NODES_IDS.clear()
		pass

	func open_new_blank_project(forced:bool = false) -> void:
		if forced || ProMan.is_project_saved():
			var new_untitled = ProMan.hold_untitled_project()
			load_project( new_untitled, true )
		else:
			# heads-up ...
			Notifier.call_deferred(
				"show_notification",
				"Discarding New Project ?",
				(
					tr("PROJECT_DISCARD_WARNING")
					% _PROJECT.title
				),
				[ # options :
					{ "label": "OK! Proceed Anyway", "callee": Main.Mind, "method": "open_new_blank_project", "arguments": [true] }
					# `Dismiss` button will be added by default
				],
				Settings.WARNING_COLOR
			)
		pass
	
	func open_project(project_id:int, forced:bool = false) -> void:
		if forced || ProMan.is_project_saved():
			var project_data = ProMan.hold_project_by_id(project_id)
			if project_data is Dictionary:
				load_project(project_data)
				if Settings.TAKE_INITIAL_SNAPSHOT == true:
					self.call_deferred("take_snapshot")
			else:
				var expected = ProMan.get_project_listing_by_id(project_id)
				printerr("Unable to open (hold) project by ID: ", project_id)
				Notifier.call_deferred(
					"show_notification",
					"Lost Project!",
					(
						(
							tr("LOST_PROJECT_WARNING") % project_id
							+ (
								( tr("Expected file: ") + expected.filename + Settings.PROJECT_FILE_EXTENSION + "\n" )
								if expected is Dictionary && expected.has("filename")
								else ""
							)
						)
					),
					[ { "label": "Unlist Project", "callee": Main.Mind, "method": "remove_local_project", "arguments": [project_id] },],
					Settings.WARNING_COLOR
				)
		else:
			Notifier.call_deferred(
				"show_notification",
				"Overriding Unsaved Project ?",
				(
					tr("UNSAVED_PROJECT_WARNING")
					% _PROJECT.title
				),
				[ # options :
					{ "label": "Yes, Open", "callee": Main.Mind, "method": "open_project", "arguments": [project_id, true] }
					# `Dismiss` button will be added by default
				],
				Settings.WARNING_COLOR
			)
		pass
	
	func close_project(close_anyway:bool = false, try_quit_app:bool = false) -> bool:
		var project_closed = false
		if ProMan.is_project_saved() || close_anyway == true :
			deactivate_project_properties()
			clean_snapshots_all()
			clean_inspector_tabs()
			clean_quick_re_export()
			open_new_blank_project(true)
			project_closed = true
		else:
			# give users a heads-up ...
			Notifier.call_deferred(
				"show_notification",
				"Are you sure ?!",
				(
					tr("UNSAVED_CHANGES_WARNING")
					% _PROJECT.title
				),
				[ # options :
					{ "label": "Close Anyway", "callee": Main.Mind, "method": "close_project", "arguments": [true, try_quit_app] },
					{ "label": "Save Project", "callee": Main.Mind, "method": "save_project", "arguments": [true, try_quit_app] }
					# `Dismiss` button will be added by default
				],
				Settings.WARNING_COLOR
			)
		if project_closed && try_quit_app:
			Main.call_deferred("quit_app", 0)
		return project_closed
	
	func is_project_local() -> bool:
		return (_PROJECT.has("offline") == true && _PROJECT.offline == true) || (_PROJECT.has("remote") == false)
	
	func revert_project() -> void:
		clean_inspector_tabs()
		clean_snapshots_all()
		open_project( ProMan.get_active_project_id(), true )
		pass
	
	func confirm_revert_project() -> void:
		Notifier.call_deferred(
			"show_notification",
			"Are you sure ?!",
			"PROJECT_REVERT_WARNING",
			[ { "label": "Revert; I'm Sure", "callee": Main.Mind, "method": "revert_project", "arguments": [] }, ],
			Settings.WARNING_COLOR
		)
		pass
	
	func load_project(project_data:Dictionary, is_blank:bool = false, do_not_drop:bool = false) -> void:
		# drop the previous one by default (and not if it's a snapshot preview)
		if do_not_drop != true:
			drop_current_project()
		# holding the project/snapshot data as the active one
		_PROJECT = project_data
		reset_node_id_generator()
		# ... loading project in the editor
		reset_project_title()
		reset_project_save_status()
		# ... inspector tabs
		initialize_inspector()
		# ... grid
		if do_not_drop != true:
			load_where_user_left_last_time()
			history_check_point()
		# if it's blank we want to stay where we are (most likely at the projects-list)
		if is_blank == false && ProMan.is_project_listed():
			activate_project_properties()
		reset_project_authors_list(true)
		# clean up and close console
		console( -1, true, false )
		pass
	
	func get_project_title() -> String:
		return _PROJECT.title
	
	func reset_project_title(replacement = null, force_update_project_list:bool = false):
		if replacement is String && replacement.length() > 0:
			_PROJECT.title = replacement
			# Note: project list will get updated automatically on normal saves
			# so you don't need to force it, unless there is a reason
			if force_update_project_list == true:
				ProMan.update_listed_title(-1, replacement)
		Editor.call_deferred("set_project_title", _PROJECT.title)
		pass
	
	func reset_project_last_save_time():
		_PROJECT.meta.last_save = Time.get_datetime_string_from_system(true, true) # UTC:bool = true
		Inspector.Tab.Project.call_deferred("reset_last_save", _PROJECT.meta.last_save, is_project_local())
		pass
	
	# We can use `new_state = false` to force the project being unsaved
	func reset_project_save_status(new_state = null, history_checkpoint: bool = true):
		if new_state is bool && new_state == false:
			ProMan.set_project_unsaved()
			if history_checkpoint != false:
				history_check_point()
		Editor.call_deferred("set_project_save_status", ProMan.is_project_saved())
		pass
	
	func capture_full_project_image(version: String) -> Dictionary:
		var now = Time.get_datetime_string_from_system(true, true) # UTC:bool = true
		return {
			"version": version,
			"time": now,
			"project": _PROJECT.duplicate(true), # Note: it may be a previewed snapshot
			"view": get_current_view_state(),
			"open_scene": _CURRENT_OPEN_SCENE_ID,
		}
	
	func load_full_project_image(snapshot: Dictionary) -> void:
		load_project( snapshot.project.duplicate(true), false, true )
		scene_editorial_open(snapshot.open_scene, false)
		go_to_grid_view(snapshot.view)
		pass
	
	func history_check_point() -> void:
		if _SNAPSHOT_INDEX_OF_PREVIEW < 0:
			if Main.Configs.CONFIRMED.history_size > 0:
				if _HISTORY.INDEX < (_HISTORY.MEMORY.size() - 1) : # to avoid possible conflicts with new history,
					_HISTORY.MEMORY.resize(_HISTORY.INDEX + 1) # dropping the redo (after index)
				# ...
				_HISTORY.MEMORY.push_back( capture_full_project_image("_history_checkpoint") )
				# ...
				while _HISTORY.MEMORY.size() > Main.Configs.CONFIRMED.history_size:
					_HISTORY.MEMORY.pop_front()
				_HISTORY.INDEX = _HISTORY.MEMORY.size() - 1
				print_debug("History check point: index %s, size %s" % [_HISTORY.INDEX, _HISTORY.MEMORY.size()])
			else:
				forget_history()
		reset_history_tools()
		pass
	
	func history_rotate(direction: int) -> void:
		if _SNAPSHOT_INDEX_OF_PREVIEW < 0:
			if _HISTORY.MEMORY.size() > 0:
				var already = _HISTORY.INDEX
				_HISTORY.INDEX += direction
				if _HISTORY.INDEX < 0:
					_HISTORY.INDEX = 0
				if _HISTORY.INDEX >= _HISTORY.MEMORY.size() - 1:
					_HISTORY.INDEX = _HISTORY.MEMORY.size() - 1
				# ...
				if already != _HISTORY.INDEX:
					clipboard_clear() # to avoid trying to move nodes that do not exist anymore
					load_full_project_image( _HISTORY.MEMORY[_HISTORY.INDEX] )
					reset_project_save_status(false, false)
					print_debug("History rotation %s: index %s, size %s" % [direction, _HISTORY.INDEX, _HISTORY.MEMORY.size()])
		reset_history_tools()
		pass
	
	func reset_history_tools() -> void:
		Editor.reset_history_tools(_HISTORY.INDEX, _HISTORY.MEMORY.size(), _SNAPSHOT_INDEX_OF_PREVIEW >= 0)
		pass
	
	func forget_history() -> void:
		_HISTORY = {
			"MEMORY": [],
			"INDEX": -1,
		}
		pass
	
	func get_current_view_state() -> Array:
		var current = Helpers.Utils.vector2_to_array( Grid.get_scroll_offset() )
		current.append( Grid.get_zoom() )
		return current
	
	func track_last_view(offset: Vector2 = Vector2.INF, zoom: float = -INF, scene_id: int = -1) -> void:
		var state = Helpers.Utils.vector2_to_array(offset if offset < Vector2.INF else Grid.get_scroll_offset())
		state.append(zoom if zoom > 0 else Grid.get_zoom())
		ProMan.set_project_last_view(state, (scene_id if scene_id >= 0 else _CURRENT_OPEN_SCENE_ID))
		pass
	
	func reset_active_author(id:int) -> void:
		# Track the active author for the next time project is opened
		ProMan.set_project_active_author(id)
		# ...
		if Flaker is Flake.Native:
			Flaker.reset_active_author(id)
		if Flaker is Flake.Snow:
			# (when time-based flaker is defined) we need to change
			Flaker.reset_producer(id)
		pass
	
	func standardize_authors_list() -> void:
		if _PROJECT.meta.has("authors") == false || (_PROJECT.meta.authors is Dictionary) == false:
			_PROJECT.meta.authors = {}
		# This is supposed to impact projects with snowflake/epoch method only where an author was only a name:
		var zero_seed = (-1) if (_PROJECT.meta.has("epoch") && _PROJECT.meta.epoch is int && _PROJECT.meta.epoch > 0) else 0;
		for key in _PROJECT.meta.authors:
			if _PROJECT.meta.authors[key] is String:
				_PROJECT.meta.authors[key] = [_PROJECT.meta.authors[key], zero_seed]
		# Backward compatibility for 1st generation projects:
		if _PROJECT.has("next_resource_seed"):
			_PROJECT.meta.chapter = 0
			_PROJECT.meta.authors = { 0: [Settings.ANONYMOUS_AUTHOR_INFO, _PROJECT.next_resource_seed] }
			_PROJECT.erase("next_resource_seed")
			print_debug("CAUTION! Global seed moved to anonymous author for backward compatibility: ", _PROJECT.meta.authors)
		pass

	func reset_node_id_generator() -> void:
		standardize_authors_list() # (automatic compatibility update)
		# We expect projects to have at least one (even 0-Anonymous) author.
		var active_author = ProMan.get_project_active_author() # (current record in projects list or null)
		if (active_author is int) == false || _PROJECT.meta.authors.has(active_author) == false:
			if _PROJECT.meta.authors.size() == 0:
				active_author = 0
				var zero_seed = (-1) if (_PROJECT.meta.has("epoch") && _PROJECT.meta.epoch is int && _PROJECT.meta.epoch > 0) else 0;
				_PROJECT.meta.authors[0] = [ Settings.ANONYMOUS_AUTHOR_INFO, zero_seed ]
			else:
				active_author = _PROJECT.meta.authors.keys()[0] # (the first author-id)
			print(
				"Contributor reset! Active author of this document is now: ",
				active_author, " = ", _PROJECT.meta.authors[active_author]
			)
		# ...
		# + Time-based (Snowflake) UID:
		if _PROJECT.meta.has("epoch") && _PROJECT.meta.epoch is int && _PROJECT.meta.epoch > 0:
			Flaker = Flake.Snow.new(_PROJECT.meta.epoch, active_author)
		# + Default (native, recommended) UID:
		else:
			Flaker = Flake.Native.new(_PROJECT.meta, active_author)
		# ...
		reset_active_author(active_author)
		pass
	
	func reset_project_authors_list(auto_select:bool = false) -> void:
		Authors.call_deferred(
			"reset_authors", _PROJECT.meta, ProMan.get_project_active_author(), auto_select
		)
		pass
	
	func update_project_author(id:int, info:String, is_active:bool) -> void:
		var author_info = (info if info.length() > 0 else Settings.ANONYMOUS_AUTHOR_INFO)
		if _PROJECT.meta.authors.has(id): # existent
			_PROJECT.meta.authors[id][0] = author_info
		else: # new author
			_PROJECT.meta.authors[id] = [author_info, 0]
		if is_active:
			reset_active_author(id)
		reset_project_authors_list()
		pass
	
	func remove_project_author(id:int, forced: bool = false) -> void:
		if _PROJECT.meta.authors.has(id):
			if _PROJECT.meta.authors.size() > 1: # ( At least one author should remain in the list, and
				# the removed author better not to have any UID created yet.)
				if _PROJECT.meta.authors[id][1] <= 0 || forced == true:
					_PROJECT.meta.authors.erase(id)
					# reset the active author if the one remove was the one in charge:
					if ProMan.get_project_active_author() == id:
						var new_active_author = _PROJECT.meta.authors.keys()[0] # (the first author-id)
						reset_active_author(new_active_author)
					reset_project_authors_list()
				else:
					printerr("Trying to remove author with positive seed! Ignored to obsessively avoid future UID conflicts.")
			else:
				printerr("Trying to remove the only author of the document! Authors: ", _PROJECT.meta.authors)
		else:
			printerr("Trying to remove non-existent author: ", id, " from: ", _PROJECT.meta.authors)
		pass
	
	func update_project_chapter(id: int, quick: bool = false) -> void:
		if quick:
			_PROJECT.meta.chapter = id
		else:
			Notifier.call_deferred(
				"show_notification",
				"Are you sure ?!",
				"UPDATE_CHAPTER_ID_NOTIFICATION",
				[ { "label": "OK; Update", "callee": Main.Mind, "method": "update_project_chapter", "arguments": [id, true] },],
				Settings.CAUTION_COLOR
			)
		pass
	
	func clean_inspector_tabs(keep_history:bool = false) -> void:
		Inspector.Tab.Node.call("total_clean_up", keep_history)
		pass
	
	func initialize_inspector() -> void:
		Inspector.call_deferred("initialize_tabs")
		# and create sub-inspector panels for each node type
		Inspector.Tab.Node.call_deferred("setup_node_type_sub_inspectors", NODE_TYPES_LIST)
		clean_inspector_tabs(true)
		pass
	
	func load_where_user_left_last_time() -> void:
		var last_left_scene = ProMan.get_project_last_open_scene()
		# The last open scene tracked by editor may not exist in the project anymore
		# (e.g. removed by another contributor, or reverted before save.)
		if _PROJECT.resources.scenes.has(last_left_scene) == false:
			# In such cases, we fall back on the scene that includes the current project entry:
			last_left_scene = find_scene_owner_of_node(_PROJECT.entry)
		# ...
		scene_editorial_open(last_left_scene)
		pass
	
	func scene_editorial_open(scene_id:int = -1, restore_last_view:bool = true) -> void:
		track_last_view() # for the previously open scene
		load_scene(scene_id, -1) # updates _CURRENT_OPEN_SCENE_ID (-1 = to the entry)
		scene_id = _CURRENT_OPEN_SCENE_ID
		if restore_last_view == true:
			var state = ProMan.get_project_last_view(-1, scene_id)
			go_to_grid_view(state)
		ProMan.set_project_last_open_scene(scene_id)
		pass
	
	func load_scene(scene_id:int = -1, focus_node_id:int = -1) -> void:
		var the_scene = get_scene(scene_id, true) # updates `_CURRENT_OPEN_SCENE_ID` or resets it to the project entry
		scene_id =_CURRENT_OPEN_SCENE_ID # ... so we have a reevaluated `scene_id` here
		# load the scene in the editor
		Grid.call_deferred("clean_grid")
		if the_scene && the_scene.has("map"):
			# ... draw nodes in the grid based on the scene's map
			for each_nid in the_scene.map:
				var the_node = _PROJECT.resources.nodes[each_nid]
				var the_map  = the_scene.map[each_nid]
				var the_type = NODE_TYPES_LIST[the_node.type]
				if  the_map && the_node && the_type :
					Grid.call_deferred("draw_node", each_nid, the_node, the_map, the_type)
				else:
					print_stack()
					printerr(
						"Unexpected Behavior! Node inconsistency: Trying to draw a node that may not exist " +
						"in the scene map or dataset or node types! node = " + String.num_int64(each_nid) +
						" scene = " + String.num_int64(scene_id)
					)
			Grid.call_deferred("draw_queued_connection")
			Grid.call_deferred("reset_view_to_initial")
			# load the scene title / name
			Editor.call_deferred("set_scene_name", the_scene.name)
			# then jump to a node if annotated
			if focus_node_id >= 0:
				if the_scene.map.has(focus_node_id):
					jump_to_node(focus_node_id)
				else:
					print_stack()
					printerr(("Trying to jump to nonexistent node = %s" % focus_node_id), (" in the scene = %s " % scene_id))
			else:
				_SELECTED_NODES_IDS.clear()
			react_to_scene_change(scene_id)
		pass
	
	# remember: macros are scenes too
	func get_scene(scene_id:int = -1, reset_current_open_scene_id_tracker:bool = false) -> Dictionary:
		var the_scene
		# ... then get the scene from id
		if scene_id >= 0:
			if _PROJECT.resources.scenes.has(scene_id):
				the_scene = _PROJECT.resources.scenes[scene_id]
			else:
				print_stack()
				printerr(("Invalid call! `get_scene` with nonexistent scene or macro id = %s " % scene_id))
		# if not successful, fall back to the project's entry
		else:
			scene_id = find_scene_owner_of_node(_PROJECT.entry)
			if _PROJECT.resources.scenes.has(scene_id):
				the_scene = _PROJECT.resources.scenes[scene_id]
			else:
				print_stack()
				printerr(
					(
						"Invalid call! Trying to `load_scene` with none-annotated `scene_id` " +
						"(<= -1) defaulted to the nonexistent project entry scene = %s ! project data might be corrupt. "
					) % scene_id
				)
		if reset_current_open_scene_id_tracker:
			_CURRENT_OPEN_SCENE_ID = scene_id
		return the_scene
	
	func find_resource_field(resource_uid:int, priority_field:String = "") -> String:
		# when priority field is provided, first check it
		if priority_field.length() > 0:
			if _PROJECT.resources.has(priority_field):
				if _PROJECT.resources[priority_field].has(resource_uid):
					# the provided priority_field is valid:
					return priority_field
			else:
				print_stack()
				printerr("Unexpected Behavior! Provided `priority_field = %s` doesn't exist in the resources." % priority_field)
		# not found and returned yet,
		# we can look up based on the resource uid in all the possible fields
		for field in _PROJECT.resources:
			if _PROJECT.resources[field].has(resource_uid):
				return field
		return ""
	
	func get_current_open_scene_id() -> int:
		return _CURRENT_OPEN_SCENE_ID
	
	# finds the resource with uid, looking up in all the fields, but first in the `priority_field` if provided
	func lookup_resource(resource_uid:int, priority_field:String = "", duplicate:bool = true):
		var resource = null
		if resource_uid >= 0 :
			var valid_field_owning_resource = find_resource_field(resource_uid, priority_field)
			if valid_field_owning_resource.length() > 0:
				resource = _PROJECT.resources[valid_field_owning_resource][resource_uid]
		if resource is Dictionary:
			# Note: this function may be called by (custom) node types
			return (resource.duplicate(true) if (duplicate == true) else resource)
		else: # null or something naturally cloned
			return resource

	# returns found resource (as tagged) using uid,
	# looking up in all the fields, but first in the `priority_field` if provided
	func lookup_resource_tagged(resource_uid:int, priority_field:String = "", duplicate:bool = true):
		var resource = null
		var field = null
		if resource_uid >= 0 :
			var valid_field_owning_resource = find_resource_field(resource_uid, priority_field)
			if valid_field_owning_resource.length() > 0:
				resource = _PROJECT.resources[valid_field_owning_resource][resource_uid]
				field = valid_field_owning_resource
		if resource is Dictionary:
			# Note: this function may be called by (custom) node types
			return { "field": field, "data": (resource.duplicate(true) if (duplicate == true) else resource) }
		else: # null or something naturally cloned
			return { "field": field, "data": resource }
			
	func lookup_map_by_node_id(node_id:int, duplicate:bool = true):
		# it checks if the node exist when trying to find scene owner, so...
		var owner_scene_id = find_scene_owner_of_node(node_id)
		if owner_scene_id >=0 : # having scene owner means, the node is there in maps:
			var the_map = _PROJECT.resources.scenes[owner_scene_id].map[node_id]
			return ( the_map if (duplicate == false) else the_map.duplicate(true) )
		return null
	
	# queries `nodes` dataset by name (using `matchn`)
	# optionally restricted to a `scene_id` where:
	# 	`-1` means the open scene (default)
	# 	`-2` means all the nodes in dataset
	func query_nodes_by_name(query:String, scene_id:int = -1, full_node:bool = false) -> Dictionary:
		var result = {}
		var the_scene_node_list_to_lookup
		if scene_id >= 0 && _PROJECT.resources.scenes.has(scene_id) && _PROJECT.resources.scenes[scene_id].has("map"):
			the_scene_node_list_to_lookup = _PROJECT.resources.scenes[scene_id].map
		elif scene_id == -2:
			the_scene_node_list_to_lookup = _PROJECT.resources.nodes
		else: # unset or -1
			the_scene_node_list_to_lookup = _PROJECT.resources.scenes[_CURRENT_OPEN_SCENE_ID].map
		# now look up:
		for node_id in the_scene_node_list_to_lookup:
			if _PROJECT.resources.nodes.has(node_id):
				var the_node = _PROJECT.resources.nodes[node_id]
				if the_node is Dictionary && the_node.has("name") && the_node.name is String && the_node.name.matchn(query):
					result[node_id] = (the_node.duplicate() if (full_node == true) else the_node.name)
		return result
	
	# filters with null values ({ x: null,... }) mean to include whatever has the key (`x`) no matter what the value is
	# the same works for exclusion, where having the mentioned key excludes the item no matter the value, otherwise pairs shall be identical
	func clone_dataset_of(field:String, filters:Dictionary = {}, exclusion:Dictionary = {}) -> Dictionary:
		if _PROJECT.resources.has(field) :
			var _filtered = {}
			# first filter elements
			if filters.size() == 0:
				# asked for all
				_filtered = _PROJECT.resources[field].duplicate(true)
			else:
				# filter it by a special pair in each item of the dataset, e.g. { macro: true }
				# it can check only for existence of the key if value is `null`
				for item in _PROJECT.resources[field]:
					for key in filters:
						if _PROJECT.resources[field][item].has(key):
							if filters[key] == null || _PROJECT.resources[field][item][key] == filters[key]:
								_filtered[item] = _PROJECT.resources[field][item]
			# then exclude unwanted ones
			var result
			if exclusion.size() == 0:
				result = _filtered
			else:
				# filtering again, this time exclusively
				result = {}
				for item in _filtered:
					for key in exclusion:
						# keep those which doesn't have the key
						if ( _filtered[item].has(key) == false ):
							result[item] = _filtered[item]
						else:
						# and exclude those which have the key, unless the value is not the same
							if exclusion[key] != null && _filtered[item][key] != exclusion[key]:
								result[item] = _filtered[item]
			return result.duplicate(true)
		else:
			print_stack()
			printerr("Unexpected Behavior! The field = %s is not found in the dataset." % field)
		return {}
	
	# tells you if a node is selected
	# and can also manage selection if a boolean is also passed (true = select, false = unselect)
	func track_nodes_selection(node_id:int, select_or_unselect = null, ignore_error:bool = false) -> bool:
		var is_already_selected = _SELECTED_NODES_IDS.has(node_id)
		if select_or_unselect is bool:
			if select_or_unselect == true:
			# selection
				if is_already_selected :
					if ignore_error == false:
						print_stack()
						printerr("Unexpected Behavior! Trying to select an already selected node!", node_id)
				elif node_id >= 0 && _PROJECT.resources.nodes.has(node_id):
					_SELECTED_NODES_IDS.push_front(node_id)
					react_to_selection_change()
				else:
					print_stack()
					printerr("Unexpected Behavior! Tracking Invalid or None-existing Node-id ! ", node_id)
			else: # == false
				# deselection
				if is_already_selected :
					_SELECTED_NODES_IDS.erase(node_id)
					react_to_selection_change()
				else:
					if ignore_error == false:
						print_stack()
						printerr("Unexpected Behavior! Trying to unselect a node that is not selected!")
		else: # just wants to know if selected
			return is_already_selected 
		return false

	func force_unselect_all() -> void:
		_SELECTED_NODES_IDS.clear()
		react_to_selection_change()
		Grid.call_deferred("force_unselect_all")
		pass
	
	func force_select_group(list: Array, clear: bool = false) -> void:
		if clear:
			force_unselect_all()
		for node_id in list:
			if _SELECTED_NODES_IDS.has(node_id) == false:
				_SELECTED_NODES_IDS.push_front(node_id)
		Grid.call_deferred("force_select_group", list, false)
		pass

	func flat_branch_map(start_node_id: int, end_node_id: int, with_waterfall: bool = false, scene_id: int = _CURRENT_OPEN_SCENE_ID) -> Array:
		var flat_map = []
		var level = [start_node_id]
		if _PROJECT.resources.scenes[scene_id].map.has(start_node_id):
			var start_map = _PROJECT.resources.scenes[scene_id].map[start_node_id]
			if start_map.has("io") && start_map.io is Array && start_map.io.size() > 0:
				for outgoing_link in start_map.io:
					var next_node_id = outgoing_link[2]
					if next_node_id == end_node_id:
						level.append(end_node_id)
					else:
						var next_flat_map = flat_branch_map(next_node_id, end_node_id, with_waterfall, scene_id)
						level.append_array(next_flat_map)
		if level.has(end_node_id) || with_waterfall:
			for node_id in level:
				if flat_map.has(node_id) == false:
					flat_map.append(node_id)
		return flat_map

	func select_branch(from: Array, to: int, with_waterfall: bool = false, dry_run: bool = false) -> Array:
		var selection = from.duplicate()
		var name_list = []
		for start in from:
			var branch_flat = flat_branch_map(start, to, with_waterfall)
			if branch_flat.has(to) || with_waterfall:
				for node_id in branch_flat:
					if selection.has(node_id) == false:
						selection.append(node_id)
						name_list.append(_PROJECT.resources.nodes[node_id].name)
		# ...
		print_debug("Branch(s) selected %s nodes from %s to %s: " % [selection.size(), from, to], name_list, " + ", with_waterfall)
		if dry_run != true:
			force_select_group(selection, true)
		return selection
	
	func react_to_scene_change(new_scene_id:int = -1) -> void:
		# anyway react to selection, because there might be some kind of change not tracked
		react_to_selection_change()
		# we shall also tell the inspector's macros tab to react, whether it's a scene or a macro.
		Inspector.Tab.Macros.call_deferred("update_macro_editorial_state", new_scene_id)
		Inspector.Tab.Scenes.call_deferred("update_scene_editorial_state", new_scene_id)
		pass
	
	func react_to_selection_change() -> void:
		# print_debug("Current Selected Nodes: ", _SELECTED_NODES_IDS)
		inspector_reaction_to_selection_change()
		pass
	
	func inspector_reaction_to_selection_change(force:bool = false) -> void:
		var selection_size = _SELECTED_NODES_IDS.size()
		# first pull modifications, in case
		if Main._AUTO_NODE_UPDATE == true:
			Inspector.Tab.Node.call("try_auto_node_update")
		# ...
		if force == true || Main._AUTO_INSPECT == true:
			if selection_size == 1:
				inspect_node( _SELECTED_NODES_IDS[0], -1, Main._AUTO_INSPECT)
			else:
				Inspector.Tab.Node.call_deferred("block_node_tab")
		# Note: inspector keeps the last opened node's resource id so inspector sends the right resource id,
		# in case of updating a node while selecting another one on the grid (auto-inspection off) 
		pass
	
	# cleans and opens node parameters in the node tab of the inspector panel
	# `scene_id = -1` means current open scene
	func inspect_node(node_id:int, scene_id:int = -1, switch_tab:bool = false) -> void:
		if _PROJECT.resources.nodes.has(node_id):
			# get ...
			var the_node = _PROJECT.resources.nodes[node_id]
			# and the owner (for the `map`, at least because of the `skip` parameter)
			if scene_id < 0 :
				scene_id = _CURRENT_OPEN_SCENE_ID
			if _PROJECT.resources.scenes.has(scene_id) == false || _PROJECT.resources.scenes[scene_id].map.has(node_id) == false :
				scene_id = find_scene_owner_of_node(node_id)
			# then ..
			if scene_id >= 0:
				var the_node_map = _PROJECT.resources.scenes[scene_id].map[node_id]
				if the_node is Dictionary && the_node_map is Dictionary:
					if Main._AUTO_NODE_UPDATE == true:
						# ... ask inspector::node to send up modifications of the previously inspected node
						Inspector.Tab.Node.call("try_auto_node_update", node_id)
						# ... then we can push the new one
					Inspector.Tab.Node.call_deferred("update_node_tab", node_id, the_node, the_node_map)
					if switch_tab == true:
						Inspector.call_deferred("show_tab_of_title", "Node")
		pass
	
	func jump_to_node(node_id:int, select:bool = false) -> void:
		# (to the node's on-grid offset)
		var the_scene_id = find_scene_owner_of_node(node_id)
		var destination = _PROJECT.resources.scenes[the_scene_id].map[node_id].offset
		go_to_grid_view(destination)
		if select == true:
			_SELECTED_NODES_IDS = [node_id]
			Grid.call_deferred("select_node_by_id", node_id, true)
		pass
	
	func go_to_grid_view(offset_or_state: Array = [0, 0, 1]) -> void:
		Grid.call_deferred("got_to_offset", [offset_or_state[0], offset_or_state[1]], false, false)
		Grid.set_deferred("zoom", offset_or_state[2] if offset_or_state.size() >= 3 else 1)
		pass
	
	func uid_is_used(uid: int) -> bool:
		for field in _PROJECT.resources:
			if _PROJECT.resources[field].has(uid):
				return true
		return false
	
	func next_resource_id() -> int:
		if Flaker is Flake.Native:
			return Flaker.next()
		if Flaker is Flake.Snow:
			if Settings.ALWAYS_USE_REALTIME_IDS:
				return Flaker.realtime_next()
			else:
				return Flaker.lazy_next()
		else:
			printerr("Invalid state of Flaker!")
			return -888
	
	func create_new_resource_id() -> int:
		var new_uid = null
		# (this additional safety check makes sure you won't get a duplicated UID,
		# even in case of manual edits or merger of unreliably chaptered documents)
		while new_uid == null || (uid_is_used(new_uid) && new_uid > 0):
			new_uid = next_resource_id()
		return new_uid
	
	var _CACHED_COMPILED_REGEXES = {}
	func compiled_regex_from(pattern:String) -> RegEx:
		if _CACHED_COMPILED_REGEXES.has(pattern) == false:
			var the_regex = RegEx.new()
			the_regex.compile(pattern) 
			_CACHED_COMPILED_REGEXES[pattern] = the_regex
		return _CACHED_COMPILED_REGEXES[pattern]

	# creation and caching of the node type name abbreviations (on demand) to use on new node naming
	var _cached_type_abbreviations_by_name = {}
	var _cached_type_abbreviations = {}
	const ALL_VOWELS_BUT_FIRST_CHAR_REGEX_PATTERN = "(\\B[AaEeYyUuIiOo]|\\W|_)*" # ~ /\B[AaEeYyUuIiOo]*/ all vowels other than the character
	const WHITE_SPACE_REGEX_PATTERN = "_"
	const ABBREVIATION_WHITE_SPACE_REPLACEMENT = "_"
	
	func get_type_name_abbreviation(type_name:String) -> String:
		var type_abbreviation
		# we have made abbreviation already? return from cache
		if _cached_type_abbreviations_by_name.has(type_name):
			type_abbreviation = _cached_type_abbreviations_by_name[type_name]
		# otherwise make abbreviation, cache and return it
		else:
			var abbreviation_length = Settings.MINIMUM_TYPE_ABBREVIATION_LENGTH
			# keep only the consonants and no vowels other than the first character
			var consonant_only_type_name = compiled_regex_from(ALL_VOWELS_BUT_FIRST_CHAR_REGEX_PATTERN).sub(type_name, "", true)
			if consonant_only_type_name.length() < abbreviation_length: # unless the name gets too short, where we use full type name (without whitespaces)
				consonant_only_type_name = compiled_regex_from(WHITE_SPACE_REGEX_PATTERN).sub(type_name, ABBREVIATION_WHITE_SPACE_REPLACEMENT, true)
			# now cut the word to a short sub string
			# and go for a little longer version if the abbreviation is used already for another type
			while _cached_type_abbreviations_by_name.has(type_name) == false :
				type_abbreviation = consonant_only_type_name.substr(0, abbreviation_length).capitalize()
				if _cached_type_abbreviations.has(type_abbreviation):
					abbreviation_length += 1
					# ready for almost impossible situation?
					# in case that any substring of `consonant_only_type_name` is used for other types (?!) ...
					if abbreviation_length > consonant_only_type_name.length() :
						# use full type name (without whitespaces) and a random affix to create the abbreviation
						abbreviation_length = Settings.MINIMUM_TYPE_ABBREVIATION_LENGTH
						consonant_only_type_name = (
							compiled_regex_from(WHITE_SPACE_REGEX_PATTERN).sub(type_name, ABBREVIATION_WHITE_SPACE_REPLACEMENT, true) +
							Helpers.Generators.create_random_string( abbreviation_length, true, "\\W|\\d" )
						)
				else:
					_cached_type_abbreviations[type_abbreviation] = type_name
					_cached_type_abbreviations_by_name[type_name] = type_abbreviation
		return type_abbreviation
	
	# Unlike `query_nodes_by_name`, it works for any resource and detects only the one with identical name.
	# Returns the resource as a dictionary (i.e. `{ UID: Resource }`) or null if field or resource do not exist.
	func fetch_resource_by_exact_name(res_name: String, field: String):
		if _PROJECT.resources.has(field) && _PROJECT.resources[field] is Dictionary:
			for resource_id in _PROJECT.resources[field]:
				if _PROJECT.resources[field][resource_id] is Dictionary && _PROJECT.resources[field][resource_id].has("name"):
					if _PROJECT.resources[field][resource_id].name == res_name:
						return { resource_id: _PROJECT.resources[field][resource_id] }
		else:
			printerr("Trying to fetch resource by name from non-existent field: ", field)
		return null

	func is_resource_name_duplicate(name: String, field: String) -> bool:
		var fetched = fetch_resource_by_exact_name(name, field)
		if fetched != null && fetched is Dictionary && fetched.size() > 0:
			print_debug("duplicate node name detected: ", fetched)
			return true
		return false

	func make_node_name_from(prefix:String, node_id:int, type_name:String) -> String:
		var node_name = NODE_INITIAL_NAME_TEMPLATE.format({
			"node_id":  node_id,
			"node_id_base36": Helpers.Utils.int_to_base36(node_id).to_lower(),
			"prefix": prefix,
			"type_abbreviation": get_type_name_abbreviation(type_name)
		})
		if Settings.FORCE_UNIQUE_NAMES_FOR_NODES:
			while is_resource_name_duplicate(node_name, "nodes"):
				node_name += Settings.REUSED_NODE_NAMES_AUTO_POSTFIX
		return node_name
	
	func write_resource(field:String, resource:Dictionary, resource_id:int = -1, deep_clone:bool = true) -> int:
		if resource_id < 0 :
			resource_id = create_new_resource_id()
		var resource_to_write = ( resource.duplicate(true) if (deep_clone == true) else resource )
		_PROJECT.resources[field][resource_id] = resource_to_write
		return resource_id
	
	func write_node_map(node_id:int, map:Dictionary, scene_id:int = -1, deep_clone:bool = true) -> void:
		if scene_id < 0 :
			scene_id = _CURRENT_OPEN_SCENE_ID
		var map_to_write = ( map.duplicate(true) if (deep_clone == true) else map )
		_PROJECT.resources.scenes[scene_id].map[node_id] = map_to_write
		pass
	
	func is_scene_macro(scene_id:int = -1) -> bool:
		if scene_id < 0:
			scene_id = _CURRENT_OPEN_SCENE_ID
		if _PROJECT.resources.scenes.has(scene_id):
			if _PROJECT.resources.scenes[scene_id].has("macro") && _PROJECT.resources.scenes[scene_id].macro == true:
				return true
		else:
			print_stack()
			printerr("Unexpected Behavior! Trying to check if nonexistent scene = %s is macro!" % scene_id)
		return false
	
	func create_new_node(type:String, new_node_seed_uid:int, name_prefix:String=""):
		if name_prefix.length() == 0:
			var open_scene_is_macro = is_scene_macro(_CURRENT_OPEN_SCENE_ID)
			var scene_type_prefix = (NODE_INITIAL_NAME_PREFIX_FOR_MACROS if open_scene_is_macro else NODE_INITIAL_NAME_PREFIX_FOR_SCENES)
			name_prefix = (scene_type_prefix + Helpers.Utils.int_to_base36(_CURRENT_OPEN_SCENE_ID).to_lower())
		if type in NODE_TYPES_LIST:
			return {
				"type": type,
				"name": make_node_name_from(name_prefix, new_node_seed_uid, type),
				"data": Inspector.Tab.Node.SUB_INSPECTORS[type]._create_new(new_node_seed_uid)
			}
		return null
	
	func create_insert_node(type:String, offset:Vector2, scene_id:int = -1, draw:bool=true, name_prefix:String="", preset:Dictionary = {}) -> int:
		# create the node in memory
		var new_node_seed_uid = create_new_resource_id()
		var the_node = create_new_node(type, new_node_seed_uid, name_prefix)
		if the_node != null:
			var the_type = NODE_TYPES_LIST[type]
			var the_map  = { "offset": Helpers.Utils.vector2_to_array(offset) }
			# add it to resource datasets of the project
			write_resource("nodes", the_node, new_node_seed_uid, false)
			write_node_map(new_node_seed_uid, the_map, scene_id, false)
			if preset.size() > 0 :
				update_resource(new_node_seed_uid, preset, "nodes")
			# print it to the grid
			if draw == true:
				Grid.call_deferred("draw_node", new_node_seed_uid, the_node, the_map, the_type)
			return new_node_seed_uid
		return -1
	
	func create_insert_nodes(types:Array, offset:Vector2, scene_id:int = -1, draw:bool=true, name_prefix:String="") -> void:
		offset = offset.floor()
		for type in types:
			if type in NODE_TYPES_LIST:
				create_insert_node(type, offset, scene_id, draw, name_prefix)
				# the next node in the batch will be a little moved, so won't mask the previously inserted ones
				offset += Settings.BATCH_NODE_INSERTION_POSITION_ADJUSTMENT_VECTOR2
		pass
	
	func quick_insert_node(node_type:String, offset:Vector2, connection = null) -> void:
		var new_node_id = create_insert_node(node_type, offset)
		if connection is Array && connection.size() == 3:
			if connection[2] is bool:
				var full_connection = null
				if connection[2] == true:
					if Settings.INVALID_QUICK_CONNECTION.TO.has(node_type) == false:
						full_connection = [ connection[0], connection[1], new_node_id, 0 ]
				else:
					if Settings.INVALID_QUICK_CONNECTION.FROM.has(node_type) == false:
						full_connection = [ new_node_id, 0, connection[0], connection[1] ]
				if full_connection != null:
					update_node_map(full_connection[0], {
						"id": full_connection[0],
						"io": { "push": [ full_connection ] } 
					})
					Grid.call_deferred("draw_connections_batch", [ full_connection ])
		pass
	
	# -1 means current open scene
	func get_scene_entry(scene_id:int = -1) -> int:
		var entry_node_id = -1
		if scene_id < 0 || _PROJECT.resources.scenes.has(scene_id) == false:
			scene_id = _CURRENT_OPEN_SCENE_ID
		if _PROJECT.resources.scenes[scene_id].has("entry") && _PROJECT.resources.scenes[scene_id].entry is int:
			entry_node_id = _PROJECT.resources.scenes[scene_id].entry
			if _PROJECT.resources.nodes.has(entry_node_id) == false :
				printerr(
					"Unexpected Behavior! Entry node = %s" % entry_node_id,
					" from scene = %s" % scene_id, " doesn't exist in the nodes dataset!"
				)
				entry_node_id = -1
		else:
			printerr("Corrupt Project File! Invalid entry for scene = %s" % scene_id)
		return entry_node_id
		
	func get_project_entry() -> int:
		var project_entry = -1
		if _PROJECT.has("entry") && _PROJECT.entry is int:
			if _PROJECT.resources.nodes.has(_PROJECT.entry):
				if find_scene_owner_of_node(_PROJECT.entry) >= 0:
					project_entry = _PROJECT.entry
				else:
					printerr("Corrupt Project File! No scene owns the project's entry node resource id = %s!" % _PROJECT.entry)
			else:
				printerr("Corrupt Project File! Project entry node = %s doesn't exist in the nodes dataset!" % _PROJECT.entry)
		return project_entry

	func find_scene_owner_of_node(node_id:int) -> int:
		var the_owner_scene_id = -1
		if node_id >= 0 :
			# this function is most of the times called to search in the open scene,
			# so it's much faster to check the open scene first:
			if _CURRENT_OPEN_SCENE_ID >= 0 && _PROJECT.resources.scenes[_CURRENT_OPEN_SCENE_ID].map.has(node_id):
				the_owner_scene_id = _CURRENT_OPEN_SCENE_ID
			# then we go for all the scenes
			else:
				for scene_id in _PROJECT.resources.scenes:
					if _PROJECT.resources.scenes[scene_id].map.has(node_id):
						the_owner_scene_id = scene_id
						break
		else:
			print_stack()
			printerr("Unexpected Behavior! The function `find_scene_owner_of_node` is called with resource id < 0")
		return the_owner_scene_id
	
	# Returns a dictionary including node id, resource, and map in the scene if scene owns that node otherwise null
	func scene_owns_node(node_id: int, scene_id: int = -1):
		var found = null
		var check_scene_id = scene_id if scene_id >= 0 else _CURRENT_OPEN_SCENE_ID
		if _PROJECT.resources.scenes.has(check_scene_id):
			if _PROJECT.resources.scenes[check_scene_id].map.has(node_id):
				found = {
					"uid": node_id,
					"resource": _PROJECT.resources.nodes[node_id],
					"map": _PROJECT.resources.scenes[check_scene_id].map[node_id],
				}
		else:
			print_stack()
			printerr("Failed trying to check node from invalid scene: ", node_id, " of ", scene_id)
		return found
	
	func resource_is_used_in_scene(res_id: int, priority_field:String = "", scene_id: int = -1) -> bool:
		var res = lookup_resource(res_id, priority_field);
		if res is Dictionary && res.has("use"):
			for user in res.use:
				if scene_owns_node(user, scene_id) != null:
					return true
		return false
	
	func update_scene_entry(node_id:int) -> int:
		var the_owner_scene_id = find_scene_owner_of_node(node_id)
		if the_owner_scene_id >= 0 :
			var the_scene = _PROJECT.resources.scenes[the_owner_scene_id]
			var previous_scene_entry = the_scene.entry
			if node_id != previous_scene_entry:
				the_scene.entry = node_id
				return previous_scene_entry
		return -1
	
	func update_project_entry(node_id:int) -> int:
		var the_owner_scene_id = find_scene_owner_of_node(node_id)
		if the_owner_scene_id >= 0 : # a scene must own this node
			var the_scene = _PROJECT.resources.scenes[the_owner_scene_id] 
			# but the owner scene shall not be a macro
			if the_scene.has("macro") == false || the_scene.macro == false:
				var previous_project_entry = _PROJECT.entry
				if node_id != previous_project_entry:
					_PROJECT.entry = node_id
					return previous_project_entry
			else:
				show_error("Invalid Operation!", "PROJECT_ENTRY_IN_MACRO_ERROR")
		return -1
	
	# because there must always be an entry it can only set/update entry and never unset/remove
	func handle_as_entry_command_parameter(_as_entry:Dictionary) -> void:
		# _as_entry: { id:resource_id, for_scene:bool, for_project:bool }
		# Note: scene_id is auto-detected, first from the open scene, then by looking all the scenes up
		if _as_entry.has("node_id") && _as_entry.node_id is int && _PROJECT.resources.nodes.has(_as_entry.node_id):
			if _as_entry.has("for_scene") && _as_entry.for_scene == true:
				var previous = update_scene_entry(_as_entry.node_id)
				if previous >= 0:
					Grid.call_deferred("update_grid_node_box", previous, lookup_resource(previous, "nodes", false))
			if _as_entry.has("for_project") && _as_entry.for_project == true:
				var previous = update_project_entry(_as_entry.node_id)
				if previous >= 0:
					Grid.call_deferred("update_grid_node_box", previous, lookup_resource(previous, "nodes", false))
		else:
			print_stack()
			printerr("Unexpected Behavior! Invalid _as_entry command or trying to make a nonexistent node as entry point. _as_entry: ", _as_entry)
		pass
	
	func handle_use_command_parameter(user_resource_id:int, _use:Dictionary) -> void:
		# `_use: { drop:[<resource_id>,...], refer:[<resource_id>,...], field<optional>:String }`
		var lookup_priority_field:String = ( _use.field if ( _use.has("field") &&  (_use.field is String)) else "" )
		# sort stuff to avoid doing the same job twice
		var drops = []
		var refers = []
		if _use.has("drop") && (_use.drop is Array):
			for job in _use.drop:
				if (drops.has(job) == false) && (job >= 0):
					drops.append(job)
		if _use.has("refer") && (_use.refer is Array):
			for job in _use.refer:
				if (refers.has(job) == false) && (job >= 0):
					refers.append(job)
		# and get the user resource to update references there as well
		# Note: most of the times, user resource is a node, so it's faster to set `priority_field` to `nodes`, it'll be found anyway
		var the_user_resource_original = lookup_resource(user_resource_id, "nodes", false)
		# now do the drop jobs
		for job_resource_id in drops:
			var dropping = lookup_resource(job_resource_id, lookup_priority_field, false)
			if dropping is Dictionary && dropping.has("use"):
				if dropping.use is Array && dropping.use.has(user_resource_id):
					dropping.use.erase(user_resource_id)
				else:
					print_debug("Warn! Trying to drop nonexistent link! user = %s & _use: " % user_resource_id, _use, " used: ", dropping)
				# `use` is an optional (array) so when empty, it can be removed from file to optimize size:
				if (dropping.use is Array) == false || dropping.use.size() == 0:
					dropping.erase("use")
		# ... and remove references from user resource as well
		if the_user_resource_original.has("ref") && the_user_resource_original.ref is Array:
			for job_resource_id in drops:
				if the_user_resource_original.ref.has(job_resource_id):
					the_user_resource_original.ref.erase(job_resource_id)
		# and referencing jobs
		for job_resource_id in refers:
			var referenced = lookup_resource(job_resource_id, lookup_priority_field, false)
			if referenced is Dictionary:
				if referenced.has("use") == false || (referenced.use is Array) == false:
					referenced.use = [user_resource_id]
				else:
					if referenced.use.has(user_resource_id) == false: # avoid duplicate reference
						referenced.use.append(user_resource_id)
		# ... and add new references to user resource as well
		if (the_user_resource_original.has("ref") == false) || ((the_user_resource_original.ref is Array) == false) :
			the_user_resource_original.ref = []
		for job_resource_id in refers:
			if (the_user_resource_original.ref.has(job_resource_id) == false) :
				the_user_resource_original.ref.append(job_resource_id)
		# and because "ref" is an optional field, we will remove it to optimize for size ...
		if the_user_resource_original.ref.size() == 0:
			the_user_resource_original.erase("ref")
		# finally, refresh referrer lists
		for tab in ['Node', 'Variables', 'Characters', 'Macros']:
			Inspector.Tab[tab].call_deferred("refresh_referrers_list")
		pass
	
	func list_referrers(resource_uid:int = -1, priority_field:String = "") -> Dictionary:
		var use_cases_id_to_name_list = {}
		if resource_uid >= 0:
			var the_resource = lookup_resource(resource_uid, priority_field, false)
			if the_resource is Dictionary:
				if the_resource.has("use"):
					for user_res_id in the_resource.use:
						# `priority_field = nodes` because most/all of the resources are used by nodes
						var the_user_resource = lookup_resource(user_res_id, "nodes", false)
						if the_user_resource is Dictionary:
							use_cases_id_to_name_list[user_res_id] = the_user_resource
		return use_cases_id_to_name_list
	
	func update_inspector_if_node_open(node_id:int) -> void:
		if node_id >= 0 && Inspector.Tab.Node._CURRENT_INSPECTED_NODE_RESOURCE_ID == node_id:
			inspect_node(node_id, -1, false)
		pass
	
	func revise_name_exposure(
		referrers_list:Array, old_name:String, new_name:String, old_parent: String = "", new_parent: String = ""
	) -> void:
		var old_exposure = "{" + ((old_parent + ".") if old_parent.length() > 0 else "") + old_name + "}"
		var new_exposure = "{" + ((new_parent + ".") if new_parent.length() > 0 else "") + new_name + "}"
		for referrer_resource_id in referrers_list:
			var referrer_original = lookup_resource(referrer_resource_id, "nodes", false) # only nodes can expose variables
			if referrer_original.has("data") && referrer_original.data is Dictionary:
				var data_modification = {
					"data": Helpers.Utils.recursively_replace_string(referrer_original.data, old_exposure, new_exposure, true)
				}
				if Settings.NODE_TYPES_WITH_DIRECT_EXPOSURES.has(referrer_original.type):
					data_modification.data = Helpers.Utils.recursively_replace_string(data_modification.data, old_name, new_name, true)
				if data_modification.data.size() > 0:
					update_resource(referrer_resource_id, data_modification, "nodes")
		pass
	
	# updates existing resource. To create one use `write_resource`
	func update_resource(resource_uid:int, modification:Dictionary, field:String = "", is_auto_update:bool = false) -> void:
		var validated_field = find_resource_field(resource_uid, field)
		var the_resource = lookup_resource(resource_uid, validated_field, false) # duplicate = false ...
		# ... so we can directly update the resource 
		if the_resource is Dictionary:
			var the_resource_old_name = the_resource.name if the_resource.has("name") else null
			# handing special command/parameters (_use, _as_entry, etc.)
			if modification.has("data"): # that come with `data` field.
				# we handle, then remove them, to avoid writing the command with data in the project file:
				# > Use and Reference Update
				if modification.data.has("_use"):
					if modification.data._use is Dictionary:
						handle_use_command_parameter(resource_uid, modification.data._use)
					modification.data.erase("_use")
				# > Entry Update
				if modification.data.has("_as_entry"):
					if modification.data._as_entry is Dictionary:
						handle_as_entry_command_parameter(modification.data._as_entry)
					modification.data.erase("_as_entry")
				# > Name Exposure Revision
				if modification.data.has("_exposure_revision"):
					# (besides the variable name's automatic handling below for each name we do revision:)
					if modification.data._exposure_revision is Array:
						if the_resource.has("use") && the_resource.use is Array :
							for revision in modification.data._exposure_revision:
								revise_name_exposure(the_resource.use, revision[0], revision[1], revision[2], revision[3])
					modification.data.erase("_exposure_revision")
			# update the resource
				# passed parameters: 'false: to add optional pairs like notes, true: to remove empty pair keys, false : to edit the original'
			Helpers.Utils.recursively_update_dictionary(the_resource, modification, false, true, false)
			# finally...
			# post update actions
			match validated_field:
				"scenes":
					var cloned_resource = lookup_resource(resource_uid, "scenes", true)
					if the_resource.has("macro") && the_resource.macro == true:
						Inspector.Tab.Macros.call_deferred("list_macros", { resource_uid : cloned_resource })
					else:
						Inspector.Tab.Scenes.call_deferred("list_scenes", { resource_uid : cloned_resource })
					if resource_uid == get_current_open_scene_id():
						Editor.call_deferred("set_scene_name", cloned_resource.name)
				"nodes":
					# update the grid view
					Grid.call_deferred("update_grid_node_box", resource_uid, the_resource)
					# and the inspector (some changes need to update all the related caches)
					update_inspector_if_node_open(resource_uid)
				"variables":
					Inspector.Tab.Variables.call_deferred("list_variables", { resource_uid: the_resource })
					if the_resource.name != the_resource_old_name : # name update means we need to,
						# update all exposures of this variable in other referrer nodes
						if the_resource.has("use") && the_resource.use is Array :
							revise_name_exposure(the_resource.use, the_resource_old_name, the_resource.name)
				"characters":
					Inspector.Tab.Characters.call_deferred("list_characters", { resource_uid: the_resource })
					if the_resource.name != the_resource_old_name : # name update means we need to,
						# update all exposures of this characters in other referrer nodes per tag:
						if the_resource.has("use") && the_resource.use is Array && the_resource.has("tags") && the_resource.tags is Dictionary:
							for key in the_resource.tags:
								revise_name_exposure(the_resource.use, key, key, the_resource_old_name, the_resource.name)
			# ... also update grid view of any node that uses this resource
			if the_resource.has("use"):
				for referrer_id in the_resource.use:
					if _PROJECT.resources.scenes[_CURRENT_OPEN_SCENE_ID].map.has(referrer_id):
						Grid.call_deferred("update_grid_node_box", referrer_id, _PROJECT.resources.nodes[referrer_id])
			# print_debug("Update resource call: ", resource_uid, " = ", the_resource, " * ", modification, " = ", lookup_resource(resource_uid, field, false))
		elif is_auto_update != true: # inspector may try to auto update a recently deleted node automatically
			print_stack()
			printerr("Unexpected Behavior! Trying to update resource = %s which is not Dictionary!" % resource_uid)
		pass
	
	# this will remove a resource by id in any field it resides, the argument `field` is just for optimization
	# WON'T REMOVE USED RESOURCES and warns in those cases
	func remove_resource(resource_uid:int, field:String = "", forced:bool = false) -> bool:
		# make sure the field is right, or find the right one
		field = find_resource_field(resource_uid, field)
		if field.length() > 0: # if empty ("") field is returned, there is no such resource
			var the_resource = _PROJECT.resources[field][resource_uid]
			# make sure target resource is not used by other resources
			var is_removable:bool = (
					the_resource.has("use") == false || (the_resource.use is Array) == false ||
					the_resource.use.size() == 0
				)
			var non_removables
			if field == "scenes":
				# check if we can remove all nodes in the scene
				# returns list
				non_removables = batch_remove_resources(the_resource.map.keys(), "nodes", false, true, true)
				is_removable = (non_removables.ids.size() == 0)
			# for other resources:
			if is_removable == true || forced == true:
				# this resource might be *user* of other nodes/resources, so...
				if the_resource.has("ref") && (the_resource.ref is Array) && the_resource.ref.size() > 0:
					handle_use_command_parameter(resource_uid, {
						# drop all the resources (`ref`s) this resource is using
						"drop": the_resource.ref.duplicate(true)
					})
				# it might also be in the clipboard and cause trouble on paste, so we remove it there too
				clipboard_drop([resource_uid])
				# ...
				if is_removable == false && forced == true:
					print_debug("Forced removal of resource %s: " % resource_uid, the_resource)
				# ... then, removal precautions and recursive clean-ups
				match field:
					"nodes":
						# block the inspector in case
						if resource_uid == Inspector.Tab.Node._CURRENT_INSPECTED_NODE_RESOURCE_ID:
							Inspector.Tab.Node.call_deferred("block_node_tab")
						# update the grid view
						Grid.call_deferred("clean_node_off", resource_uid)
						# Note: `Grid` will call for `map::io` updates on the other or both side(s)
						# but this side's map shall be removed completely from the scene
						var the_owner_scene_id = find_scene_owner_of_node(resource_uid)
						var the_scene_map = _PROJECT.resources.scenes[the_owner_scene_id].map
						if the_scene_map.has(resource_uid):
							the_scene_map.erase(resource_uid)
					"scenes":
						# CAUTION!
						# currently we force projects to have one entry point,
						# and the editor (UI) doesn't let users to remove the scene containing the entry,
						# so currently we don't need to worry about keeping the last standing scene.
						# ...
						# firstly, remove child node resources, they are not needed any more
						var node_id_list_of_the_scene = _PROJECT.resources.scenes[resource_uid].map.keys()
						batch_remove_resources(node_id_list_of_the_scene, "nodes", false)
						# ... then tell the tab to react
						if the_resource.has("macro") && the_resource.macro == true:
							Inspector.Tab.Macros.call_deferred("unlist_macros", [resource_uid])
						else:
							Inspector.Tab.Scenes.call_deferred("unlist_scenes", [resource_uid])
					"variables":
						Inspector.Tab.Variables.call_deferred("unlist_variables", [resource_uid])
					"characters":
						Inspector.Tab.Characters.call_deferred("unlist_characters", [resource_uid])
				# and finally, erase the resource from datasets
				_PROJECT.resources[field].erase(resource_uid)
				return true # ... removed
			else:
				# resource is used, so can't be deleted:
				show_error(
					"Unsafe Operation Ignored!",
					(
						tr("USED_RESOURCE_NOT_REMOVED") +
						( tr("MAY_BE_USED_SCENE_NOT_REMOVED") if field == "scenes" else "" ) + "\n\n" +
						tr("Referenced resource(s): ") + Helpers.Utils.stringify_json(non_removables.names, "") + "\n"
					)
				)
		else:
			print_stack()
			printerr("Unexpected Behavior! Trying to remove nonexistent resource=%s ."% resource_uid)
		return false # if we reach here, it means nothing's removed
	
	func batch_remove_resources(
		resource_id_list:Array, field:String = "", duplicate_list_before_use:bool = false,
		check_only:bool = false, return_non_removables_list:bool = false
	):
		var list = (resource_id_list.duplicate(true) if duplicate_list_before_use else resource_id_list)
		var drop = [] # [[<res_id>, [<user_id, ...>]], ...]
		var nope = []
		var nope_names = []
		var scene_entry = get_scene_entry(-1)
		var project_entry = get_project_entry()
		for res_id in list:
			# we may only remove resources which are not referred by any other,
			# or together with all of their referrers, so let's list the resources to remove ...
			if res_id != project_entry && res_id != scene_entry:
				field = find_resource_field(res_id, field) # make sure the field is right
				var res = lookup_resource(res_id, field, false)
				if res.has("use") == false || (res.use is Array == false) || res.use.size() == 0 :
					drop.append([res_id, []])
				else: # otherwise we are not going to proceed
					var do_drop = false
					for user_id in res.use: # unless all the user-resources are also in the drops
						if list.has(user_id) == false:
							nope.append([res_id, res.use])
							nope_names.append(res.name)
							do_drop = false
							break
						else:
							do_drop = true
					if do_drop:
						drop.append([res_id, res.use])
			else:
				nope.append([res_id, "Scene or Project Entry!"])
				nope_names.append( lookup_resource(res_id, "nodes").name )
		var check_result
		if nope.size() == 0:
			if check_only != true:
				# let's sort dropping ones first, to make sure user-resources will be removed first
				for __ in range(0, drop.size()):
					drop.sort_custom(self.resource_referrer_custom_sorter)
				print_debug("Batch removal: ", drop)
				for idx in range(0, drop.size()):
					remove_resource(drop[idx][0], field, true)
			check_result = true
		else:
			if check_only != true:
				show_error(
					"Unsafe Operation Ignored.",
					(
						tr("REFERENCED_RESOURCE_NOT_REMOVED") + "\n\n" +
						tr("Referenced resource(s): ") + Helpers.Utils.stringify_json(nope_names, "") + "\n"
					)
				)
				printerr("Batch remove operation discarded due to existing use cases: ", nope)
			check_result = false
		return (
			{
				"ids"  : nope,
				"names": nope_names
			}
			if return_non_removables_list
			else check_result
		)
	
	static func resource_referrer_custom_sorter(a, b) -> bool:
		# true means earlier, so...
		# if no use at all
		if a[1].size() == 0:
			return true
		# else if `use` of the a has `id` of the b
		elif a[1].has( b[0] ):
			# means b is a user of a and shall be removed first
			return true
		else:
			return false
			
	func immovable_nodes(node_id_list:Array, to_scene: int = -1) -> Array:
		var unsafe_to_move = []
		var destination_scene = to_scene if _PROJECT.resources.scenes.has(to_scene) else _CURRENT_OPEN_SCENE_ID
		var project_entry = get_project_entry()
		for uid in node_id_list:
			var unsafe = false
			var node = _PROJECT.resources.nodes[uid]
			var owner_scene_id = find_scene_owner_of_node(uid)
			match node.type:
				"entry":
					unsafe = (
						( owner_scene_id != destination_scene && get_scene_entry(owner_scene_id) == uid ) ||
						( uid == project_entry && is_scene_macro(destination_scene) )
					)
				# (Currently only entry nodes can be unsafe to move)
			# ...
			if unsafe:
				unsafe_to_move.append(uid)
		return unsafe_to_move
	
	func update_node_map(node_id:int, modification:Dictionary, scene_id:int = -1) -> void:
		if scene_id == -1:
			scene_id = _CURRENT_OPEN_SCENE_ID
		if _PROJECT.resources.scenes[scene_id].map.has(node_id) == false:
			scene_id = find_scene_owner_of_node(node_id)
		if scene_id >= 0:
			# because maps are dictionaries...
			var original_map = _PROJECT.resources.scenes[scene_id].map[node_id] # this will point to the very data in the_project
			for key in modification:
				match key:
					"skip":
						if modification.skip is bool:
							if modification.skip == true:
								original_map.skip = true
							elif original_map.has("skip"):
								original_map.erase("skip")
							# the `skip` state is changed by `Inspector`, so only `Grid` needs to be updated
							Grid.call_deferred("set_node_skip", node_id, modification.skip)
					"io":
						if modification.io is Dictionary:
							for job in modification.io:
								match job:  # io jobs are arrays of connection-arrays, such as:
									"push": #  io: { push: [ [f, f_slot, t, t_slot], ... ] ,...
										if modification.io.push is Array && modification.io.push.size() > 0:
											if original_map.has("io") == false || (original_map.io is Array) == false:
												original_map.io = []
											for connection in modification.io.push:
												if connection is Array:
													original_map.io.push_back(connection)
									"pop": # ... pop: [ [<connection>],...] } 
										if modification.io.pop is Array && original_map.has("io") && original_map.io is Array:
											for connection in  modification.io.pop:
												if connection is Array:
													original_map.io.erase(connection)
										else:
											print_stack()
											printerr(
												(
													"Unexpected Behavior! Trying to pop io from map of the node=%s, " +
													"where there is no io at all!"
												) % node_id
											)
					"offset":
						var new_offset = null
						if modification.offset is Array && modification.offset.size() == 2:
							new_offset = modification.offset
						elif modification.offset is Vector2:
							new_offset = Helpers.Utils.vector2_to_array(modification.offset)
						if new_offset != null:
							original_map.offset = new_offset
						else:
							print_stack()
							printerr(
								"Unexpected Behavior! Trying to update offset in the map of the node=%s with wrong offset value: " % node_id,
								modification.offset
							)
			print_debug("Update node map call: ", modification, _PROJECT.resources.scenes[scene_id].map[node_id])
		else:
			print_stack()
			print_debug("Task Ignored! Trying to update node = %s map which doesn't exist in any scene!" % node_id)
		pass
	
	func list_all_resource_ids_by_name_of(field:String) -> Dictionary:
		var list:Dictionary = {}
		if _PROJECT.resources.has(field):
			for resource_id in _PROJECT.resources[field]:
				var resource = _PROJECT.resources[field][resource_id]
				if resource.has("name"):
					list[resource.name] = resource_id
				else:
					printerr(
						(
							"Unexpected Behavior! Loop broke. " +
							"Trying to list_all_resource_ids_by_name_of the field %s " +
							"where one or more resources doesn't have `name` key, starting at: "
						) % field,
						resource_id
					)
					break
		else:
			printerr(
				(
					"Unexpected Behavior! Call to list_all_resource_ids_by_name_of failed! " +
					"The field `%s` doesn't exist in the project resources."
				) % field
			)
		return list
	
	func create_variable_name_from_id(id:int) -> String:
		var the_name = (
			Settings.VARIABLE_NAMES_PREFIX +
			Helpers.Utils.int_to_base36(id).to_lower()
		)
		if Settings.FORCE_UNIQUE_NAMES_FOR_VARIABLES:
			while is_resource_name_duplicate(the_name, "variables"):
				the_name += Settings.REUSED_VARIABLE_NAMES_AUTO_POSTFIX
		return the_name
	
	func create_new_variable(type:String) -> void:
		if Settings.VARIABLE_TYPES.has(type):
			var the_type = Settings.VARIABLE_TYPES[type]
			var new_res_seed_id = create_new_resource_id()
			var the_new_variable = {
				"name": create_variable_name_from_id(new_res_seed_id),
				"type": type,
				"init": the_type.default
			}
			write_resource("variables", the_new_variable, new_res_seed_id, false)
			Inspector.Tab.Variables.call_deferred("list_variables", ({ new_res_seed_id: the_new_variable }))
		pass
	
	func create_character_name_from_id(id:int) -> String:
		var the_name = (
			Settings.CHARACTER_NAMES_PREFIX +
			Helpers.Utils.int_to_base36(id).to_lower()
		)
		if Settings.FORCE_UNIQUE_NAMES_FOR_CHARACTERS:
			while is_resource_name_duplicate(the_name, "characters"):
				the_name += Settings.REUSED_CHARACTER_NAMES_AUTO_POSTFIX
		return the_name
	
	func create_new_character() -> void:
		var new_res_seed_id = create_new_resource_id()
		var the_new_character = {
			"name": create_character_name_from_id(new_res_seed_id),
			"color": Helpers.Utils.color_to_rgba_hex(Helpers.Generators.create_random_color(), false)
		}
		write_resource("characters", the_new_character, new_res_seed_id, false)
		Inspector.Tab.Characters.call_deferred("list_characters", ({ new_res_seed_id: the_new_character }))
		pass
	
	func create_new_scene(is_macro:bool = false):
		var new_scene_seed_id = create_new_resource_id()
		var new_scene_name = (
			(Settings.MACRO_NAME_PREFIX if is_macro else Settings.SCENE_NAME_PREFIX)
			+ Helpers.Utils.int_to_base36(new_scene_seed_id).to_lower()
		)
		if Settings.FORCE_UNIQUE_NAMES_FOR_SCENES_AND_MACROS:
			while is_resource_name_duplicate(new_scene_name, "scenes"):
				new_scene_name += Settings.REUSED_SCENE_OR_MACRO_NAMES_AUTO_POSTFIX
		var the_new_scene = {
			"name": new_scene_name,
			"entry": null, # will be updated later
			"map": {}
		}
		if is_macro:
			the_new_scene["macro"] = true
		write_resource("scenes", the_new_scene, new_scene_seed_id, false)
		# ... then make required initial entry node
		var new_node_seed_uid = create_new_resource_id()
		var required_entry_type = Settings.NEW_SCENE_OR_MACRO_REQUIRED_INITIAL_ENTRY_NODE_TYPE
		var scene_type_prefix = (NODE_INITIAL_NAME_PREFIX_FOR_MACROS if is_macro else NODE_INITIAL_NAME_PREFIX_FOR_SCENES)
		var name_prefix = scene_type_prefix + String.num_int64(new_scene_seed_id)
		var the_node = create_new_node(required_entry_type, new_node_seed_uid, name_prefix)
		if the_node != null:
			var the_map  = { "offset": Helpers.Utils.vector2_to_array(Settings.NEW_SCENE_OR_MACRO_REQUIRED_INITIAL_ENTRY_NODE_OFFSET) }
			write_resource("nodes", the_node, new_node_seed_uid, false)
			write_node_map(new_node_seed_uid, the_map, new_scene_seed_id, false)
			# ... and update the new scene's entry, manually.
			_PROJECT.resources.scenes[new_scene_seed_id].entry = new_node_seed_uid
			# finally, tell the respective inspector to react to this new scene
			var cloned_resource = lookup_resource(new_scene_seed_id, "scenes", true)
			if is_macro:
				Inspector.Tab.Macros.call_deferred("list_macros", { new_scene_seed_id : cloned_resource })
			else:
				Inspector.Tab.Scenes.call_deferred("list_scenes", { new_scene_seed_id : cloned_resource })
		else:
			print_stack()
			printerr("Unexpected Behavior! Unable to create entry node for new scene with type=%s", required_entry_type)
		pass
	
	func query_nodes(query_object:Dictionary) -> void:
		if query_object.has_all(["what", "how"]):
			if query_object.what is String && query_object.what.length() > 0:
				var result
				var dataset
				# if a scene is mentioned
				if query_object.has("scene") && query_object.scene is int:
					if query_object.scene == -1: # which can be -1 meaning current scene
						query_object.scene = _CURRENT_OPEN_SCENE_ID
					# then filter scene nodes first if it's valid
					if query_object.scene >= 0 && _PROJECT.resources.scenes.has(query_object.scene):
						dataset = {}
						for node_id in _PROJECT.resources.scenes[query_object.scene].map:
							dataset[node_id] = _PROJECT.resources.nodes[node_id]
					else: # otherwise try all the nodes
						dataset = _PROJECT.resources.nodes
				# if no scene is mentioned, target all the nodes
				else:
					dataset = _PROJECT.resources.nodes
				# now decide how to search in the database
				match query_object.how :
					"any":
						var queries = query_object.what.split(" ", false)
						for q in range(0, queries.size()):
							queries[q] = ("*" + queries[q] + "*")
						result = recursive_query_dataset(dataset, queries)
					"including":
						# asterisks are added to enhance for `String::matchn`
						result = recursive_query_dataset(dataset, ["*" + query_object.what + "*"])
					"exact":
						result = recursive_query_dataset(dataset, [query_object.what])
					"regexp":
						var regex = RegEx.new()
						regex.compile(query_object.what)
						result = recursive_query_dataset(dataset, [regex], false, true)
				report_query(result)
		pass

	# returns an array of resource-ids
	func recursive_query_dataset(dataset:Dictionary = {}, what:Array = [], brake_on_level:bool = false, regexp:bool = false) -> Array:
		var result = []
		for item in dataset:
			if result.has(item) == false:
				var value = dataset[item]
				if value is Dictionary:
					var recursive_result = recursive_query_dataset(value, what, true, regexp)
					if recursive_result.size() > 0 :
						result.append(item)
						if brake_on_level:
							break
				elif value is String:
					if value.length() > 0 :
						for query in what:
							if (regexp == true && query.search(value) != null) || (regexp == false && value.matchn(query)):
								result.append(item)
								break
		return result
	
	func report_query(found_node_ids:Array) -> void:
		var report = {}
		for node_id in found_node_ids:
			report[node_id] = _PROJECT.resources.nodes[node_id]
		Query.call_deferred("update_query_results", report)
		pass
	
	func clipboard_push(nodes_list:Array, mode:int = Settings.CLIPBOARD_MODE.EMPTY) -> void:
		if mode is int && mode >= 0 && mode < Settings.CLIPBOARD_MODE.size():
			if nodes_list is Array && nodes_list.size() > 0:
				_CLIPBOARD.MODE = mode
				_CLIPBOARD.DATA = nodes_list.duplicate(true)
			else:
				_CLIPBOARD.MODE = Settings.CLIPBOARD_MODE.EMPTY
				_CLIPBOARD.DATA = []
			print_debug("Clipboard (%s) : " % Settings.CLIPBOARD_MODE.keys()[_CLIPBOARD.MODE], _CLIPBOARD.DATA)
		else:
			print_stack()
			printerr("Unexpected clipboard mode: ", mode, ". Expected values are indices from ", Settings.CLIPBOARD_MODE)
		@warning_ignore("INCOMPATIBLE_TERNARY")
		Grid.call_deferred("highlight_nodes", _CLIPBOARD.DATA, true, _CLIPBOARD.MODE)
		pass
	
	func clipboard_clear() -> void:
		clipboard_push([], Settings.CLIPBOARD_MODE.EMPTY)

	func clipboard_drop(node_list: Array) -> void:
		for node_id in node_list:
			while _CLIPBOARD.DATA.has(node_id): # (to make sure no duplicated node_id is there)
				_CLIPBOARD.DATA.erase(node_id)
		if _CLIPBOARD.DATA.size() == 0:
			_CLIPBOARD.MODE = Settings.CLIPBOARD_MODE.EMPTY
		Grid.call_deferred("highlight_nodes", _CLIPBOARD.DATA, true, null)
		pass
	
	# following function replaces all the connections between nodes mentioned in a `conversation_table: { n_id:o_id , ... }`.
	# ( every connection of n1, n2, etc. will be replaced with the o1, o2, etc. )
	# it returns newly made connections
	func node_connection_replacement(conversation_table:Dictionary, remake_lost_connections:bool = true) -> Array:
		var new_connections = []
		var originals = conversation_table.keys()
		var new_ones  = [] 
		# to make sure both have the same order ...
		for idx in range(0, originals.size()):
			new_ones.push_back( conversation_table[ originals[idx] ] )
		# now do the job
		for idx in range(0, new_ones.size()):
			var old_map = lookup_map_by_node_id( originals[idx], false)
			var new_map = lookup_map_by_node_id( new_ones[idx], false )
			if old_map.has("io"):
				for old_connection in old_map.io:
					# <connection>[f, f_slot, t, t_slot]
					var old_from = old_connection[0]
					var old_to   = old_connection[2]
					if conversation_table.has(old_from) && conversation_table.has(old_to):
						if new_map.has("io") == false:
							new_map.io = []
						var new_connection_index = new_map.io.find(old_connection)
						if new_connection_index != -1 || remake_lost_connections :
							var old_slot_from = old_connection[1]
							var old_slot_to   = old_connection[3]
							var replacement_connection = [ conversation_table[old_from], old_slot_from, conversation_table[old_to], old_slot_to ]
							if new_connection_index != -1:
								new_map.io[new_connection_index] = replacement_connection
							else:
								if remake_lost_connections:
									new_map.io.push_back(replacement_connection)
									new_connections.append(replacement_connection)
		return new_connections
	
	func clipboard_available() -> bool:
		# print_debug("Clipboard: ", _CLIPBOARD)
		if _CLIPBOARD.MODE != Settings.CLIPBOARD_MODE.EMPTY:
			if _CLIPBOARD.DATA is Array && _CLIPBOARD.DATA.size() > 0 :
				return true
		return false
	
	func copy_nodes_to_offset(offset:Vector2, copying_nodes_id_list:Array) -> void:
		# reference to maps
		var maps_reference = {}
		# keep offset relativity
		var closest = copying_nodes_id_list[0] # to start from some of them
		# find the closest one to corner (0,0)
		for original_id in copying_nodes_id_list:
			maps_reference[original_id] = lookup_map_by_node_id(original_id, false)
			if Helpers.Utils.array_to_vector2(maps_reference[original_id].offset).length() < Helpers.Utils.array_to_vector2(maps_reference[closest].offset).length():
				closest = original_id
		var offset_adjustment_vector = (offset - Helpers.Utils.array_to_vector2(maps_reference[closest].offset))
		# then create copies
		var id_conversation_table = {}
		for original_id in copying_nodes_id_list:
			var original = lookup_resource(original_id, "nodes", false)
			var the_offset = (offset_adjustment_vector + Helpers.Utils.array_to_vector2(maps_reference[original_id].offset))
			var the_resource_update = { "data": original.data.duplicate(true) }
			if original.has("ref") && original.ref is Array && original.ref.size() > 0:
				the_resource_update.data._use = { "refer": original.ref.duplicate(true) }
			var new_id = create_insert_node(original.type, the_offset, -1, true, "", the_resource_update)
			id_conversation_table[original_id] = new_id
		# and try to re-connect the copied ones similar to the originals
		var replaced_connections = node_connection_replacement(id_conversation_table, true)
		Grid.call_deferred("draw_connections_batch", replaced_connections)
		pass
	
	# `origin_scene_id = -1` means the owner of the first node from nodes_list
	# `destination_scene_id = -1` means current open scene
	# Note: move actions keep the UIDs and names the same, only maps will be updated
	func move_nodes_to_offset(offset:Vector2, moving_nodes_id_list:Array, origin_scene_id:int = -1, destination_scene_id:int = -1) -> void:
		if origin_scene_id < 0 :
			origin_scene_id = find_scene_owner_of_node( moving_nodes_id_list[0] )
		if destination_scene_id < 0 :
			destination_scene_id = _CURRENT_OPEN_SCENE_ID
		# reference to maps
		var maps_reference = {}
		# keep offset relativity
		var closest = moving_nodes_id_list[0] # to start from some of them
		# find the closest one to corner (0,0)
		for moving_id in moving_nodes_id_list:
			maps_reference[moving_id] = lookup_map_by_node_id(moving_id, false)
			if Helpers.Utils.array_to_vector2(maps_reference[moving_id].offset).length() < Helpers.Utils.array_to_vector2(maps_reference[closest].offset).length():
				closest = moving_id
		var offset_adjustment_vector = (offset - Helpers.Utils.array_to_vector2(maps_reference[closest].offset))
		# disconnect moving ones from nodes which aren't in the move list
		# Note: one side of every link keeps the connection data, so we have to iterate over all the node maps in the same scene
		var the_origin_scene = _PROJECT.resources.scenes[origin_scene_id]
		var lost_connections = [] # keep connections so we can update view later
		for node_map_id in the_origin_scene.map:
			if the_origin_scene.map[node_map_id].has("io"):
				for connection in the_origin_scene.map[node_map_id].io:
					var connection_from = connection[0]
					var connection_to   = connection[2]
					# if one side of a connection and not the both sides, is moving ...
					if ( moving_nodes_id_list.has(connection_from) != moving_nodes_id_list.has(connection_to) ):
							# ... then keep record of the connection and remove it from the map
							if lost_connections.has(connection) == false:
								lost_connections.append( connection.duplicate(true) )
							the_origin_scene.map[node_map_id].io.erase(connection)
		# ... then, 
		for moving_id in moving_nodes_id_list:
			# update maps to new offset
			var destination_offset = (offset_adjustment_vector + Helpers.Utils.array_to_vector2(maps_reference[moving_id].offset))
			maps_reference[moving_id].offset = Helpers.Utils.vector2_to_array(destination_offset)
			# now data is updated, but...
			# if they're going to be moved to another scene, the map data shall be moved there too
			if origin_scene_id != destination_scene_id:
				var duplicated_map = maps_reference[moving_id].duplicate(true)
				_PROJECT.resources.scenes[destination_scene_id].map[moving_id] = duplicated_map
				_PROJECT.resources.scenes[origin_scene_id].map.erase(moving_id)
				# and finally draw the node(s)
				if destination_scene_id == _CURRENT_OPEN_SCENE_ID:
					var the_node = _PROJECT.resources.nodes[moving_id]
					var the_type = NODE_TYPES_LIST[the_node.type]
					Grid.call_deferred("draw_node", moving_id, the_node, duplicated_map, the_type)
			else:
				# if we are moving in the same scene, we only need to update the offsets
				Grid.call_deferred("update_grid_node_map", moving_id, maps_reference[moving_id])
		# and final drawing
		if destination_scene_id == _CURRENT_OPEN_SCENE_ID:
			if destination_scene_id != origin_scene_id :
				Grid.call_deferred("draw_queued_connection")
			else:
				for disconnection in lost_connections:
					Grid.call_deferred("disconnection_from_view", disconnection)
		pass
		
	func clipboard_pull(offset:Vector2, drop: Array = []) -> void:
		if clipboard_available():
			if drop.size() > 0: # (`drop` includes the immovable nodes confirmed to be left off after the prompt below)
				clipboard_drop(drop)
			offset = offset.floor()
			print_debug("Paste (%s) " % Settings.CLIPBOARD_MODE.keys()[_CLIPBOARD.MODE], "at %s :" % offset, _CLIPBOARD.DATA)
			match _CLIPBOARD.MODE:
				Settings.CLIPBOARD_MODE.COPY:
					copy_nodes_to_offset(offset, _CLIPBOARD.DATA)
				Settings.CLIPBOARD_MODE.CUT:
					var immovable_here = immovable_nodes(_CLIPBOARD.DATA);
					if immovable_here.size() == 0:
						# clipboard pulls replace one another, so all the nodes listed there are from one owner scene
						# and currently paste can only happens to the current open scene
						# these are also the `move_nodes_...` function's defaults
						# so we'll use the default of the move and give only two first parameters
						move_nodes_to_offset(offset, _CLIPBOARD.DATA)
						# and finally clean up the clipboard after move
						clipboard_clear()
					else:
						# print("Caution! Not movable clipboard: ", _CLIPBOARD, " due to ", immovable_here)
						var movable_size = _CLIPBOARD.DATA.size() - immovable_here.size()
						var immovable_names = []
						for uid in immovable_here:
							immovable_names.append( _PROJECT.resources.nodes[uid].name )
						Notifier.call_deferred(
							"show_notification",
							"Unsafe Move Detected!",
							(
								tr("IMMOVABLE_NODES_ERROR") +
								tr("Immovable(s): ") + Helpers.Utils.stringify_json(immovable_names, "") + "\n"
							),
							[{
								"label": ( tr("Move What's Safe (%s)") % movable_size ),
								"callee": Main.Mind, "method": "clipboard_pull", "arguments": [offset, immovable_here]
							}],
							Settings.CAUTION_COLOR
						)
		pass
	
	# collects resources and their dependencies flattened in an object and an array
	func collect_resources(list_or_one, priority_field:String = "", duplicate:bool = false) -> Dictionary:
		var found = {}
		if list_or_one is Array:
			for res_id in list_or_one:
				found[res_id] = collect_resources(res_id)
		else:
			var looked = lookup_resource_tagged(list_or_one, priority_field, duplicate)
			var dependencies: Array
			match looked.field:
				"scenes":
					# when resource is a whole scene
					dependencies = looked.data.map.keys()
					dependencies.append(looked.data.entry)
				"nodes":
					dependencies = looked.data.ref if looked.data.has("ref") else []
					# nodes need to have their owner also collected, for offset and connection data,
					# as well as a target to be pasted into for the dependency nodes
					var owner_scene_id = find_scene_owner_of_node(list_or_one)
					# we'll take a scene shell (without all the nodes but this collected one and the entry)
					var owner_shell = lookup_resource(owner_scene_id, "scenes", true)
					owner_shell.map = { list_or_one: owner_shell.map[list_or_one] }
					# we need to update shells to keep map data for previously collected nodes as well
					if found.has(owner_scene_id):
						Helpers.Utils.recursively_update_dictionary(owner_shell, found[owner_scene_id], false)
					found[owner_scene_id] = {
						"resources": { "scenes": { owner_scene_id: owner_shell } },
						"dependencies": [owner_shell.entry]
					}
				"variables":
					dependencies = [] # currently holds no dependency (`ref`s)
				"characters":
					dependencies = [] # ditto
			found[list_or_one] = { "resources": { looked.field: { list_or_one: looked.data } }, "dependencies": dependencies }
		# mix found data all in one collected batch
		var collected = { "resources": {}, "dependencies": [] }
		# first flatten all dependencies
		for res_id in found:
			for id in found[res_id].dependencies:
				if collected.dependencies.has(id) == false:
					collected.dependencies.append(id)
			# then make sure they are also collected as resources
			for ref_id in collected.dependencies:
				if found.has(ref_id) == false:
					found[ref_id] = collect_resources(ref_id)
		# finally mix all the resources
		for res_id in found:
			# (recursive update is necessary because we may collect pieces of a single resource _e.g. scene map_ in multiple steps)
			Helpers.Utils.recursively_update_dictionary(collected.resources, found[res_id].resources, false)
		return collected
	
	# copies selected resources and their dependencies into OS clipboard
	# as a JSON stringified structured dictionary;
	# also returns the created dictionary (by default without duplication).
	# note: if no resource_list is provided, selected nodes (from grid) will be pushed
	func os_clipboard_push(resource_list:Array = [], priority_field:String = "nodes", duplicate:bool = false) -> Dictionary:
		var list = resource_list if resource_list.size() > 0 else _SELECTED_NODES_IDS;
		var collected = collect_resources(list, priority_field, duplicate)
		# after collecting the data we need to clean it up
		for field in collected.resources:
			for res_id in collected.resources[field]:
				var data = collected.resources[field][res_id]
				# collected scenes shall not keep those grid connections in which one side is not collected
				if field == "scenes" && data.has("map"):
					for nid in data.map:
						if data.map[nid].has("io"):
							var new_io = []
							for con in data.map[nid].io:
								if list.has(con[2]) || collected.dependencies.has(con[2]):
									new_io.append(con)
							if new_io.size() > 0:
								data.map[nid].io = new_io
							else:
								data.map[nid].erase("io")
				# and generally for every resource type,
				# unlike `ref`s that are all collected as dependencies,
				# we shall not keep `use` data where the user is not collected so the relation is broken
				if data.has("use"):
					var new_use = []
					for user_id in data.use:
						if list.has(user_id) || collected.dependencies.has(user_id):
							new_use.append(user_id)
					if new_use.size() > 0:
						data.use = new_use
					else:
						data.erase("use")
		# finally pack the collection with some metadata and set it into the OS clipboard
		var packed = {
			"arrow": { "version": Settings.ARROW_VERSION },
			"chunk": {
				"title": _PROJECT.title,
				"chapter": _PROJECT.meta.chapter,
				"list": list, "dependencies": collected.dependencies,
				"resources": collected.resources,
			}
		};
		var packed_as_text = Helpers.Utils.stringify_json(packed)
		DisplayServer.clipboard_set(packed_as_text)
		return packed
	
	# cache for data pulled from the OS clipboard
	var _OS_CLIPBOARD_PULLED: Dictionary = {}

	# prompts for the mode (if not already set) and merges the data if any, from the OS clipboard
	func os_clipboard_pull(merge_mode = null, offset_for_nodes = null) -> void:
		if merge_mode == null:
			_OS_CLIPBOARD_PULLED = {}
			var os_clipboard = DisplayServer.clipboard_get()
			if os_clipboard.find("arrow") >= 0:
				var pulled = Helpers.Utils.recursively_convert_numbers_to_int( Helpers.Utils.parse_json(os_clipboard) );
				if pulled is Dictionary && pulled.has_all(["arrow", "chunk"]):
					_OS_CLIPBOARD_PULLED = pulled
					var allow_reuse = (pulled.chunk.chapter != _PROJECT.meta.chapter)
					var statistics = ""
					for field in pulled.chunk.resources:
						var count_by_field = pulled.chunk.resources[field].size()
						var field_name = field.to_upper() + "_FIELD_NAME"
						var field_name_plural = field_name + "_PLURAL"
						statistics += "\n• " + String.num_uint64(count_by_field) + " " + tr_n(field_name, field_name_plural, count_by_field)
					Notifier.call_deferred(
						"show_notification",
						"Merger Detected [Experimental!]",
						(
							(
								tr("MERGER_OPERATION_DESCRIPTION")
								.format({
									"origin": pulled.chunk.title,
									"cid": String.num_int64(pulled.chunk.chapter),
									"statistics": statistics,
									"main_count": String.num_uint64(pulled.chunk.list.size()),
								})
							) +
							(
								tr("MERGER_OPERATION_STRATEGY_CHOICE")
								if allow_reuse
								else ""
							)
						),
						[
							{ "label": "Reuse", "callee": Main.Mind, "method": "os_clipboard_pull", "arguments": [Settings.OS_CLIPBOARD_MERGE_MODE.REUSE, offset_for_nodes] },
							{ "label": "Recreate", "callee": Main.Mind, "method": "os_clipboard_pull", "arguments": [Settings.OS_CLIPBOARD_MERGE_MODE.RECREATE, offset_for_nodes] },
						] if allow_reuse else [
							{ "label": "Recreate", "callee": Main.Mind, "method": "os_clipboard_pull", "arguments": [Settings.OS_CLIPBOARD_MERGE_MODE.RECREATE, offset_for_nodes] },
						],
						Settings.INFO_COLOR
					)
		else:
			var dependencies = _OS_CLIPBOARD_PULLED.chunk.dependencies;
			var moving_list = _OS_CLIPBOARD_PULLED.chunk.list;
			var new_resources = _OS_CLIPBOARD_PULLED.chunk.resources;
			# ...
			var import_table = { "names": {}, "ids": {} }
			var new_moving_list = []
			# depending on the merge mode, we decide which UIDs can be set as is, which need to be changed with new IDs,
			# and what pulled resources shall be ignored to reuse similar ones already existing
			for field in new_resources:
				for pulled_id in new_resources[field]:
					var pulled_data = new_resources[field][pulled_id]
					var existing = lookup_resource_tagged(pulled_id, field, false)
					# if the pulled UID is not used in this document, our priority is to reuse the UID, unless recreation is explicitly decided
					if existing.data == null:
						import_table.ids[pulled_id] = create_new_resource_id() if merge_mode == Settings.OS_CLIPBOARD_MERGE_MODE.RECREATE else pulled_id
					else:
						# if a resource with identical UID exists, depending on the chosen strategy:
						var new_id = null
						match merge_mode:
							Settings.OS_CLIPBOARD_MERGE_MODE.REUSE:
								# the existing data should be used and resources from the pulled ones will be ignored,
								# unless the data type is different from the clipboard data or is not sharable
								if (
									["characters", "variables"].has(field) == false ||
									field != existing.field || pulled_data.has("type") != existing.data.has("type") ||
									(pulled_data.has("type") && pulled_data.type != existing.data.type)
								):
									new_id = create_new_resource_id()
								# (else: new_id = null) resources that has no ID in the table would not be imported
							Settings.OS_CLIPBOARD_MERGE_MODE.RECREATE:
								# or we assign a new UID to every clipboard resource anyway and import them as totally new data
								new_id = create_new_resource_id()
						# make sure this new ID would not collide with any of the IDs used directly from the pulled data
						# (i.e. with those reused because of `existing.data == null`)
						while new_id != null && (moving_list.has(new_id) || dependencies.has(new_id)):
							new_id = create_new_resource_id()
						# ...
						if new_id != null:
							import_table.ids[pulled_id] = new_id
					# if we decided to import the resource
					if import_table.ids.has(pulled_id):
						# we may also fix the name when it's duplicate
						if pulled_data.has("name"):
							var old_name = pulled_data.name
							while is_resource_name_duplicate(pulled_data.name, field):
								pulled_data.name += Settings.REUSED_NODE_NAMES_AUTO_POSTFIX
							if pulled_data.name != old_name:
								import_table.names[old_name] = pulled_data.name
			# ...
			for field in new_resources:
				for old_id in new_resources[field]:
					if import_table.ids.has(old_id):
						var new_id = import_table.ids[old_id]
						var import = new_resources[field][old_id]
						# common
						# ------
						# we also need to revise old uses and references
						if import.has("ref"):
							var new_ref = []
							for rid in import.ref:
								if import_table.ids.has(rid):
									new_ref.append(import_table.ids[rid])
								else:
									new_ref.append(rid)
									# (reused resources _ref here_ get their new relations later below)
							import.ref = new_ref
						if import.has("use"):
							var new_use = []
							for uid in import.use:
								if import_table.ids.has(uid):
									new_use.append(import_table.ids[uid])
								# 🡦 we may not keep track of dropped users in case they are not imported
							import.use = new_use
						# ...
						# type-specific
						# -------------
						match field:
							"scenes":
								if import_table.ids.has(import.entry):
									import.entry = import_table.ids[import.entry]
								var new_map = {}
								for nid in import.map:
									var new_nid;
									if import_table.ids.has(nid):
										new_nid = import_table.ids[nid]
									else:
										new_nid = nid
									new_map[new_nid] = import.map[nid]
									if new_map[new_nid].has("io"):
										var new_io = []
										for con in new_map[new_nid].io:
											var new_dst = import_table.ids[con[2]] if import_table.ids.has(con[2]) else con[2]
											new_io.append([new_nid, con[1], new_dst, con[3]])
										new_map[new_nid].io = new_io
								import.map = new_map
							"nodes":
									# moving (list) nodes that are collected from a grid in origin,
									if moving_list.has(old_id):
										# may be placed to the currently open grid in the destination
										new_moving_list.append(new_id)
									# nodes that keep references internally (e.g. condition, content, jump, etc.) may update them as well
									if Inspector.Tab.Node.SUB_INSPECTORS[import.type].has_method("_translate_internal_ref"):
										Inspector.Tab.Node.SUB_INSPECTORS[import.type]._translate_internal_ref(import.data, import_table)
							"variables":
								# currently, only generals may apply
								pass
							"characters":
								# ditto
								pass
						# ...
						# now we can import the pulled and revised data into our project
						_PROJECT.resources[field][new_id] = import.duplicate(true)
						# ...
			# move main selected nodes to the currently open scene if desired
			if offset_for_nodes is Vector2 && new_moving_list.size() > 0:
				move_nodes_to_offset(offset_for_nodes, new_moving_list)
			# clean-up empty imported scenes
			# these are scenes that all their nodes (expect their mandatory entry) is moved to another scene in destination
			# and the entry node is not referenced by any other resource (e.g. no jump to that entry exists)
			var empty_scenes = []
			if new_resources.has("scenes"):
				for imported_scene_old_id in new_resources.scenes:
					var new_scene_id = import_table.ids[imported_scene_old_id]
					var imported_scene = _PROJECT.resources.scenes[new_scene_id]
					var its_entry = _PROJECT.resources.nodes[imported_scene.entry]
					if (
						( # is not used itself (e.g. by a `macro_use` node)
							imported_scene.has("use") == false || imported_scene.use.size() == 0
						) &&
						( # no referenced or mapped inner node
							imported_scene.map.size() == 0 ||
							( imported_scene.map.size() == 1 && ( its_entry.has("use") == false || its_entry.use.size() == 0 ))
						)
					):
						empty_scenes.append(new_scene_id)
			batch_remove_resources(empty_scenes)
			# now that all the resources are in their place, 
			# we need to update `use` relations for already existing resources that are referenced by newly imported ones
			for pulled_id in import_table.ids:
				var imported_id = import_table.ids[pulled_id]
				var import = lookup_resource(imported_id, "", false)
				if import != null && import.has("ref"):
					for ref in import.ref:
						var referenced = lookup_resource(ref, "", false)
						if referenced.has("use") == false:
							referenced.use = [imported_id]
						elif referenced.use.has(imported_id) == false:
							referenced.use.append(imported_id)
			# ...
			var state = get_current_view_state()
			load_scene()
			go_to_grid_view(state)
			reset_project_save_status(false)
			Inspector.call_deferred("refresh_inspector_tabs")
			_OS_CLIPBOARD_PULLED = {}
		pass
	
	func register_project_and_save_from_open(project_title:String, project_filename:String) -> void:
		if project_title.length() > 0 && project_filename.length() > 0 :
			ProMan.register_project(project_title, project_filename, true)
			reset_project_title(project_title) # just registered, no need for re-updating ProMan's list
			reset_project_last_save_time()
			# then saves it
			ProMan.save_project(_PROJECT, false, (Settings.USE_DEPRECATED_BIN_SAVE != true))
			# and update current view
			reset_project_save_status()
			load_projects_list()
			activate_project_properties()
			reset_project_authors_list(true)
		else:
			print_debug("Unexpected Behavior! Calling register_and_save_project with wrong data. ", [project_title, project_filename] )
		pass
	
	func save_project(try_close_project:bool = false, try_quit_app:bool = false) -> void:
		if _SNAPSHOT_INDEX_OF_PREVIEW < 0 :
			if ProMan.is_project_listed() == false:
				# the project is being saved from untitled blank
				# so ask for a title
				var suggested_title = ProMan.valid_unique_project_filename_from( _PROJECT.title )
				NewProjectPrompt.call_deferred("prompt_with_presets", suggested_title)
					# will ask for a title and a name
					# then calls `register_and_save_project`
			else:
				track_last_view()
				reset_project_last_save_time()
				ProMan.save_project(_PROJECT, false, (Settings.USE_DEPRECATED_BIN_SAVE != true))
				reset_project_save_status()
				if try_close_project:
					close_project(false, try_quit_app)
				load_projects_list()
		else:
			show_error("Invalid Operation!", "NO_SAVE_IN_SNAPSHOT_PREVIEW")
		pass
	
	func try_remove_local_project(project_id) -> void:
		var project_listed = ProMan.get_project_listing_by_id(project_id)
		var project_name = ("%s" % project_listed.title) if project_listed is Dictionary && project_listed.has("title") else ""
		Notifier.call_deferred(
				"show_notification",
				"Are you sure ?!",
				(
					(
						tr("PROJECT_REMOVAL_PROMPT")
						.format({
							"name": project_name,
							"pid": project_id,
						})
					) +
					(
						( tr("Project file: `%s`") % (project_listed.filename + Settings.PROJECT_FILE_EXTENSION) )
						if project_listed is Dictionary && project_listed.has("filename")
						else ""
					)
				),
				[
					{ "label": "Delete File!", "callee": Main.Mind, "method": "remove_local_project", "arguments": [project_id, true] },
					{ "label": "Unlist", "callee": Main.Mind, "method": "remove_local_project", "arguments": [project_id, false] },
				],
				Settings.WARNING_COLOR
			)
		pass
	
	func remove_local_project(project_id, remove_file_too: bool = false) -> void:
		print_debug("Removing project id: ", project_id)
		# currently, removing an item only unlists it
		# file won't be removed to avoid accidents
		ProMan.unlist_project(project_id, remove_file_too)
		load_projects_list()
		pass
	
	func activate_project_properties() -> void:
		Inspector.Tab.Project.call_deferred("open_properties_editor", _PROJECT.title, _PROJECT.meta, is_project_local())
		pass
		
	func deactivate_project_properties() -> void:
		Inspector.Tab.Project.call_deferred("reset_to_project_lists")
		pass
	
	func take_snapshot(custom_version_prefix:String = "") -> void:
		var version:String
		var to_be_snapshot_index = _SNAPSHOTS.size()
		if _SNAPSHOT_INDEX_OF_PREVIEW < 0 :
			_SNAPSHOTS_COUNT_PURE_ONES += 1
			version = String.num_uint64(_SNAPSHOTS_COUNT_PURE_ONES)
			print_debug("New Snapshot! v%s " % version)
		else:
			var base = _SNAPSHOTS[_SNAPSHOT_INDEX_OF_PREVIEW]
			version = base.version + "." + String.num_uint64(base.branches.size() + 1)
			# append index of the to-be-added snapshot as the branch of the base
			base.branches.push_back( to_be_snapshot_index )
			print_debug("A Snapshot of another snapshot made! v%s" % version)
		var snapshot = capture_full_project_image(version)
		snapshot["branches"] = []
		_SNAPSHOTS.push_back(snapshot)
		# list it
		if custom_version_prefix.length() == 0 :
			custom_version_prefix = Settings.SNAPSHOT_VERSION_PREFIX 
		var full_version_code = ( custom_version_prefix + snapshot.version)
		Inspector.Tab.Project.call_deferred("list_snapshot", {
			"index": to_be_snapshot_index,
			"version": full_version_code,
			"time": snapshot.time,
		}, is_project_local())
		pass
	
	func preview_snapshot(idx:int) -> void:
		if idx >= 0 && _SNAPSHOTS.size() > idx :
			_SNAPSHOT_INDEX_OF_PREVIEW = idx
			_MASTER_PROJECT_SAFE = capture_full_project_image("_master_project_safe")
			load_full_project_image( _SNAPSHOTS[idx] )
		pass
	
	func return_to_master_project() -> void:
		if _SNAPSHOT_INDEX_OF_PREVIEW >= 0:
			_SNAPSHOT_INDEX_OF_PREVIEW = -1
			load_full_project_image( _MASTER_PROJECT_SAFE )
			_MASTER_PROJECT_SAFE = {}
		else:
			print_stack()
			printerr("Unexpected Behavior! Trying to return to master branch when no snapshot is open!")
		pass
	
	func restore_snapshot(snapshot_idx:int) -> void:
		if snapshot_idx >= 0 && _SNAPSHOTS.size() > snapshot_idx :
			clean_inspector_tabs()
			load_full_project_image( _SNAPSHOTS[snapshot_idx] )
			reset_project_save_status(false)
			_MASTER_PROJECT_SAFE = {}
			_SNAPSHOT_INDEX_OF_PREVIEW = -1
			print_debug("Project Snapshot Restored: ", snapshot_idx)
		pass
	
	func try_restore_snapshot(index) -> void:
		if (index is int) && index >= 0 && _SNAPSHOTS.size() > index :
			var snapshot_version = _SNAPSHOTS[index].version
			Notifier.call_deferred(
				"show_notification",
				"Are you sure ?!",
				(
					tr("SNAPSHOT_RESTORATION_PROMPT")
					% snapshot_version
				),
				[ { "label": "Restore; I'm Sure", "callee": Main.Mind, "method": "restore_snapshot", "arguments": [index] }, ],
				Settings.CAUTION_COLOR
			)
		else:
			printerr("Unexpected Behavior! Invalid snapshot index on restore: ", index)
		pass
	
	func try_remove_snapshot(index) -> void:
		if (index is int) && index >= 0 && _SNAPSHOTS.size() > index :
			_SNAPSHOTS[index] = null # don't erase it to keep indices the same
			Inspector.Tab.Project.call_deferred("unlist_snapshot", index, is_project_local())
		else:
			printerr("Unexpected Behavior! Invalid snapshot index on remove: ", index)
		pass
	
	func clean_snapshots_all() -> void:
		_SNAPSHOTS.clear()
		_SNAPSHOTS_COUNT_PURE_ONES = -1
		_SNAPSHOT_INDEX_OF_PREVIEW = -1
		Inspector.Tab.Project.call_deferred("clean_snapshots_view")
		pass
	
	func prompt_path_to(callback_host:Object, callback_ident:String, extra_arguments:Array, dialog_options:Dictionary) -> void:
		PathDialog.call_deferred("refresh_prompt_for", callback_host, callback_ident, extra_arguments, dialog_options)
		pass
		
	# imports a project (from file) to another one
	# `into_project_uid >= 0` means to specified project otherwise: ...
	# -1 : this project
	# -2 : new project
	func import_project_from_file(file_path:String, into_project_uid:int = -2) -> void:
		print_debug("Importing Project from File (into %s): " % into_project_uid, file_path)
		var filename = file_path.get_file()
		var extension = file_path.get_extension()
		var importing_data = ProMan.read_project_file_data(file_path, true) # always try json
		# project manager will return `null` if the file is invalid
		if importing_data is Dictionary:
			# where to import data ?
			var target_registered_uid_to_save_into
			if into_project_uid >= 0 : # specified project uid
				target_registered_uid_to_save_into = into_project_uid
			if into_project_uid == -1 : # this project (current active ...)
				target_registered_uid_to_save_into = ProMan.get_active_project_id()
			elif into_project_uid <= -2 : # as new one
				var pure_filename = filename.replacen(("." + extension), "")
				target_registered_uid_to_save_into = ProMan.register_project(importing_data.title, pure_filename, false)
			# finally writing data
			ProMan.save_project_into(target_registered_uid_to_save_into, importing_data, false, (Settings.USE_DEPRECATED_BIN_SAVE != true))
			load_projects_list()
		else:
			printerr("Invalid Project File! The imported file is not of a supported format or is corrupted: ", file_path)
			Notifier.call_deferred(
				"show_notification",
				"Invalid Project File!",
				"INVALID_PROJECT_FILE_IMPORT",
				[],
				Settings.CAUTION_COLOR
			)
		pass
	
	func import_project_from_browsed(json: String, filename: String) -> void:
		var importing_data = ProMan.read_browsed_project_content(json)
		# project manager will return `null` if anything goes wrong
		if importing_data is Dictionary:
			print_debug("valid project file browsed: ", filename)
			var pure_filename = filename.replacen(".json", "").replacen(Settings.PROJECT_FILE_EXTENSION, "")
			var target_registered_uid_to_save_into = ProMan.register_project(importing_data.title, pure_filename, false)
			ProMan.save_project_into(target_registered_uid_to_save_into, importing_data, false, (Settings.USE_DEPRECATED_BIN_SAVE != true))
			load_projects_list()
		else:
			show_error("Invalid Project File!", "INVALID_PROJECT_FILE_IMPORT")
		pass
	
	var _QUICK_EXPORT_FORMAT: String
	var _QUICK_EXPORT_FILENAME: String
	var _QUICK_EXPORT_BASE_DIR: String
	
	func clean_quick_re_export() -> void:
		_QUICK_EXPORT_FORMAT = ""
		_QUICK_EXPORT_FILENAME = ""
		_QUICK_EXPORT_BASE_DIR = ""
		pass
	
	func quick_re_export() -> void:
		if Html5Helpers.Utils.is_browser() && _QUICK_EXPORT_FORMAT.length() > 0:
			export_project_from_browser(_QUICK_EXPORT_FORMAT)
		elif _QUICK_EXPORT_FORMAT.length() > 0 && _QUICK_EXPORT_FILENAME.length() > 0 && _QUICK_EXPORT_BASE_DIR.length() > 0:
			export_project_as(_QUICK_EXPORT_FORMAT, _QUICK_EXPORT_FILENAME, _QUICK_EXPORT_BASE_DIR)
		else:
			show_error("Quick Re-Export Not Available!", "QUICK_REEXPORT_NOT_YET")
		pass
	
	func export_project_as(format, filename:String, base_directory:String) -> void:
		if filename.is_valid_filename() && Helpers.Utils.is_abs_or_rel_path(base_directory):
			if format is String && format.length() > 0:
				var formatted_filename = (filename + "." + format)
				var full_export_file_path = (Helpers.Utils.normalize_dir_path(base_directory) + formatted_filename)
				print_debug("Saving a Copy of the Project as `%s` to: "% (formatted_filename), base_directory )
				var saved;
				match format.to_lower():
					"json":
						saved = ProMan.save_play_ready_json(full_export_file_path, _PROJECT)
					"html":
						saved = ProMan.save_playable_html(full_export_file_path, _PROJECT)
						if saved == OK :
							OS.shell_open(full_export_file_path)
					"csv":
						saved = ProMan.save_project_csv(full_export_file_path, _PROJECT)
				if saved != OK:
					printerr('Unable to Read template or Write to the file!', full_export_file_path, saved)
					show_error("IO Operation Failed!", "EXPORT_IO_FAILED")
				# cache quick re-export data
				_QUICK_EXPORT_FORMAT = format
				_QUICK_EXPORT_FILENAME = filename
				_QUICK_EXPORT_BASE_DIR = base_directory
			else:
				# format is not specified so use native project format
				var full_export_file_path = (Helpers.Utils.normalize_dir_path(base_directory) + filename + Settings.PROJECT_FILE_EXTENSION)
				ProMan.save_project_native_file(_PROJECT, full_export_file_path, (Settings.USE_DEPRECATED_BIN_SAVE != true))
				print_debug("Saving a Copy of the Project as `%s` to: "% (filename + Settings.PROJECT_FILE_EXTENSION), base_directory )
		pass
	
	func export_project_from_browser(format: String) -> void:
		if Html5Helpers.Utils.is_browser():
			var suggested_filename = Helpers.Utils.valid_filename(_PROJECT.title)
			match format.to_lower():
				"full-copy":
					var full_json = Helpers.Utils.stringify_json(_PROJECT)
					JavaScriptBridge.download_buffer(full_json.to_utf8_buffer(), suggested_filename + Settings.PROJECT_FILE_EXTENSION)
				"json":
					var play_ready = ProMan.revise_play_ready(_PROJECT);
					var play_json = Helpers.Utils.stringify_json(play_ready)
					JavaScriptBridge.download_buffer(play_json.to_utf8_buffer(), suggested_filename + ".json")
				"html":
					var html = ProMan.parse_playable_html(_PROJECT)
					if html is String:
						JavaScriptBridge.download_buffer(html.to_utf8_buffer(), suggested_filename + ".html")
					else:
						printerr("Unable to parse_playable_html", html)
				"csv":
					var path = suggested_filename + ".csv"
					var csv = ProMan.parse_project_csv(_PROJECT, path, Settings.CSV_EXPORT_SEPARATOR)
					JavaScriptBridge.download_buffer(csv.to_utf8_buffer(), path)
			_QUICK_EXPORT_FORMAT = format
		else:
			printerr("Trying to export_project_from_browser out of the context!")
		pass
	
	# plays the project in console
	var _CONSOLE_CURRENT_VISIBILITY:bool
	func console( play_node_uid:int = -1, clear_console:bool = true, update_visibility = null, playing_in_slot:int = -1 ) -> void :
		if clear_console == true:
			Console.call_deferred("clear_console")
		if update_visibility is bool && update_visibility != _CONSOLE_CURRENT_VISIBILITY:
			Main.UI.call_deferred("set_panel_visibility", "console", update_visibility)
			_CONSOLE_CURRENT_VISIBILITY = update_visibility
		# `play_node <= -1` means just open the console
		if play_node_uid >= 0 :
			var the_node = lookup_resource(play_node_uid, "nodes", false)
			var the_node_map = lookup_map_by_node_id(play_node_uid, false)
			var the_type = NODE_TYPES_LIST[the_node.type]
			if the_node && the_node_map:
				Console.call_deferred("play_node", play_node_uid, the_node, the_node_map, the_type, playing_in_slot)
		pass
	
	func play_from(there:String) -> void:
		match there:
			"scene_entry":
				console( get_scene_entry(), true, true )
			"project_entry":
				console( get_project_entry(), true, true )
			"left_console":
				console( -1, false, true )
			"selected_node":
				# it won't clear console, it just plays the node
				if _SELECTED_NODES_IDS.size() > 0 :
					console( _SELECTED_NODES_IDS[0], false, true )
		pass
	
	func locate_node_on_grid(node_id:int = -1, highlight:bool = true, force_change_scene:bool = true) -> void:
		if node_id >= 0:
			var owner_scene = find_scene_owner_of_node(node_id)
			if owner_scene >= 0:
				if _CURRENT_OPEN_SCENE_ID != owner_scene && force_change_scene == true:
					scene_editorial_open(owner_scene, false)
				# now if we can (~ we was or we are in the scene,) we jump
				if _CURRENT_OPEN_SCENE_ID == owner_scene:
					Grid.call_deferred("go_to_offset_by_node_id", node_id, highlight)
		pass

	func show_error(heading:String = "Error!", message:String = "SHOW_ERROR_FALLBACK_MSG", color:Color = Settings.WARNING_COLOR, actions:Array = []) -> void:
		Notifier.call_deferred("show_notification", heading, message, actions, color)
		pass

	# will handle actions defined in `Project Settings > Input Map` (sent by `Main`)
	func handle_shortcuts(event) -> bool:
		var handled = true
		if event.is_action_pressed("arrow_save"):
			save_project()
		elif event.is_action_pressed("arrow_switch_fullscreen"):
			Main.UI.call_deferred("toggle_fullscreen")
		elif event.is_action_pressed("arrow_query_set"):
			# do_query with existing string and grab_focus
			Query.call_deferred("do_query", "", true)
		elif event.is_action_pressed("arrow_query_next"):
			Query.call_deferred("rotate_matches", 1)
		elif event.is_action_pressed("arrow_query_previous"):
			Query.call_deferred("rotate_matches", -1)
		elif event.is_action_pressed("arrow_reset_node"):
			Inspector.Tab.Node.call_deferred("reset_inspection")
		elif event.is_action_pressed("arrow_update_node"):
			Inspector.Tab.Node.call_deferred("read_and_update_inspected_node")
		elif event.is_action_pressed("arrow_focus_node"):
			Inspector.Tab.Node.call_deferred("focus_grid_on_inspected")
		elif event.is_action_pressed("arrow_unselect_nodes_all"):
			force_unselect_all()
		elif event.is_action_pressed("arrow_switch_auto_inspection"):
			Main.call_deferred("toggle_quick_preferences", "auto_inspect", true)
		elif event.is_action_pressed("arrow_switch_auto_node_update"):
			Main.call_deferred("toggle_quick_preferences", "auto_node_update", true)
		elif event.is_action_pressed("arrow_switch_quick_node_insertion"):
			Main.call_deferred("toggle_quick_preferences", "quick_node_insertion", true)
		elif event.is_action_pressed("arrow_switch_connection_assist"):
			Main.call_deferred("toggle_quick_preferences", "connection_assist", true)
		elif event.is_action_pressed("arrow_switch_auto_rebuild_runtime_templates"):
			Main.call_deferred("toggle_quick_preferences", "auto_rebuild_runtime_templates", true)
		elif event.is_action_pressed("arrow_toggle_inspector_panel_view"):
			Main.UI.call_deferred("toggle_panel_visibility", "inspector")
		elif event.is_action_pressed("arrow_play_from_scene_entry"):
			play_from("scene_entry")
		elif event.is_action_pressed("arrow_play_from_project_entry"):
			play_from("project_entry")
		elif event.is_action_pressed("arrow_play_from_left_console"):
			play_from("left_console")
		elif event.is_action_pressed("arrow_play_from_selected_node"):
			play_from("selected_node")
		elif event.is_action_pressed("arrow_take_snapshot"):
			take_snapshot()
		elif event.is_action_pressed("arrow_quick_re_export"):
			quick_re_export()
		elif event.is_action_pressed("arrow_history_redo"):
			history_rotate(+1)
		elif event.is_action_pressed("arrow_history_undo"):
			history_rotate(-1)
		else:
			handled = false
		return handled
