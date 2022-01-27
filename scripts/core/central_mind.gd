# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Central Mind
# (the core!)
class_name CentralMind

const PREF_PANEL = Addressbook.PANELS.preferences
const EDITOR = Addressbook.EDITOR.itself
const GRID = Addressbook.GRID
const INSPECTOR = Addressbook.INSPECTOR.itself
const QUERY = Addressbook.QUERY.itself
const GRID_CONTEXT_MENU = Addressbook.GRID_CONTEXT_MENU.itself
const NEW_PROJECT_PROMPT = Addressbook.PANELS.new_project_prompt
const PATH_DIALOGE = Addressbook.PATH_DIALOGUE
const CONSOLE = Addressbook.CONSOLE.itself
const NOTIFIER = Addressbook.NOTIFICATION.itself

# nodes which may send `request_mind` signal
const TRANSMITTERS = [
	PREF_PANEL,
	EDITOR,
	GRID, GRID_CONTEXT_MENU,
	INSPECTOR, QUERY,
	NEW_PROJECT_PROMPT,
	CONSOLE
]

const NODE_INITIAL_NAME_TEMPLATE = Settings.NODE_INITIAL_NAME_TEMPLATE
const NODE_INITIAL_NAME_PREFIX_FOR_SCENES = Settings.NODE_INITIAL_NAME_PREFIX_FOR_SCENES
const NODE_INITIAL_NAME_PREFIX_FOR_MACROS = Settings.NODE_INITIAL_NAME_PREFIX_FOR_MACROS

const CLIPBOARD_MODE = Settings.CLIPBOARD_MODE


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
	
	var ProMan # ProjectManager
	
	var Utils = Helpers.Utils
	var Generators = Helpers.Generators
	
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
		"MODE": CLIPBOARD_MODE.EMPTY,
		"DATA": null
	}
	
	func _init(main) -> void:
		Main = main
		pass
	
	func post_initialization() -> void:
		# instance project manager
		var _aldp = Main.Configs.CONFIRMED.app_local_dir_path
		ProMan = ProjectManagement.ProjectManager.new( _aldp )
		# get references
		Editor = Main.get_node(EDITOR)
		Grid = Main.get_node(GRID)
		Inspector = Main.get_node(INSPECTOR)
		Query = Main.get_node(QUERY)
		NewProjectPrompt = Main.get_node(NEW_PROJECT_PROMPT)
		PathDialog = Main.get_node(PATH_DIALOGE)
		Console = Main.get_node(CONSOLE)
		Notifier = Main.get_node(NOTIFIER)
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
			tx.connect("request_mind", self, "central_event_dispatcher", [t, tx], 0)
		# others
		Grid.connect("scroll_offset_changed", self, "update_last_view_offset", [], CONNECT_DEFERRED)
		pass
	
	func load_node_types() -> void:
		var node_types_handler = NodeTypes.NodeTypesHandler.new(Main)
		NODE_TYPES_LIST = node_types_handler.load_node_types()
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
			"node_selection":
				track_nodes_selection(args, true)
			"node_unselection":
				track_nodes_selection(args, false)
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
			"clean_clipboard":
				clipboard_push([], CLIPBOARD_MODE.EMPTY)
			"clipboard_pull":
				clipboard_pull(args)
			"save_project":
				save_project()
			"register_project_and_save_from_open":
				register_project_and_save_from_open(args.title, args.filename)
			"remove_local_project":
				remove_local_project(args)
			"open_local_project":
				open_project(args)
			"close_project":
				close_project()
			"revert_project":
				confirm_revert_project()
			"set_project_title":
				reset_project_title(args)
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
					(
						"`%s` is modified. " +
						"Creating a new blank project will discard all the unsaved data."
					) % _PROJECT.title
				),
				[ # options :
					{ "label": "OK, Proceed Anyway", "callee": Main.Mind, "method": "open_new_blank_project", "arguments": [true] }
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
					self.call_deferred("take_snapshot", "Point Start - v")
		else:
			Notifier.call_deferred(
				"show_notification",
				"Overriding Unsaved Project ?",
				(
					(
						"Editor is holding modifications for `%s`. " +
						"Opening another project will discard these unsaved data. " +
						"Would you like to proceed anyway?"
					) % _PROJECT.title
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
			open_new_blank_project(true)
			project_closed = true
		else:
			# give users a heads-up ...
			Notifier.call_deferred(
				"show_notification",
				"Are you sure ?!",
				(
					(
						"Project `%s` is modified. " +
						"Closing it anyway will discard unsaved changes."
					) % _PROJECT.title
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
			(
				"You're about to revert current project to the last physically saved state. " +
				"This operation will drop any change in memory and re-open the project from the saved file."
			),
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
		# ... loading project in the editor
		reset_project_title()
		reset_project_save_status()
#		reset_auto_save_quick_preference()
		# ... inspector tabs
		initialize_inspector()
		# ... grid
		load_where_user_left_last_time()
		# if it's blank we want to stay where we are (most likely at the projects-list)
		if is_blank == false && ProMan.is_project_listed():
			activate_project_properties()
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
		_PROJECT.meta.last_save = {
			"utc"  : OS.get_datetime(true), # UTC:bool = true
			"local": OS.get_datetime(false)
		}
		pass
	
	# force can only unsave the project not falsely mark it as saved
	func reset_project_save_status(force = null):
		if force is bool && force == false:
			ProMan.set_project_unsaved()
		Editor.call_deferred("set_project_save_status", ProMan.is_project_saved())
		pass
	
	func update_last_view_offset(offset:Vector2) -> void:
		ProMan.set_project_last_view_offset(offset, _CURRENT_OPEN_SCENE_ID)
		pass
	
#	func reset_auto_save_quick_preference() -> void:
#		# state of `auto local save` must be in the project list for ...
#		var auto_save_last_state = ProMan.get_project_auto_save_state() # no-parameter: get the active one's
#		Main.call_deferred("set_quick_preferences", "auto_local_save", auto_save_last_state, true)
#		pass
	
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
		var the_scene_id = ProMan.get_project_last_open_scene()
		scene_editorial_open(the_scene_id)
		pass
	
	func scene_editorial_open(scene_id:int = -1, restore_last_view:bool = true) -> void:
		load_scene(scene_id, -1) # updates _CURRENT_OPEN_SCENE_ID (-1 = to the entry)
		scene_id = _CURRENT_OPEN_SCENE_ID
		if restore_last_view == true:
			var the_offset = ProMan.get_project_last_view_offset(-1, scene_id)
			go_to_grid_offset(the_offset)
		ProMan.call_deferred("set_project_last_open_scene", scene_id)
		pass
	
	func load_scene(scene_id:int = -1, node_id:int = -1) -> void:
		var the_scene = get_scene(scene_id, true) # updates `_CURRENT_OPEN_SCENE_ID` or resets it to the project entry
		scene_id =_CURRENT_OPEN_SCENE_ID # ... so we have a reevaluated `scene_id` here
		# load the scene in the editor
		Grid.call_deferred("clean_grid")
		if the_scene && the_scene.has("map"):
			# ... draw nodes in the grid based on the scene's map
			for node_id in the_scene.map:
				var the_node = _PROJECT.resources.nodes[node_id]
				var the_map  = the_scene.map[node_id]
				var the_type = NODE_TYPES_LIST[the_node.type]
				if  the_map && the_node && the_type :
					Grid.call_deferred("draw_node", node_id, the_node, the_map, the_type)
				else:
					print_stack()
					printerr(
						"Unexpected Behavior! Node inconsistency: Trying to draw a node that may not exist " +
						"in the scene map or dataset or node types ! node = " + node_id + " scene = " + scene_id
					)
			Grid.call_deferred("draw_queued_connection")
			Grid.call_deferred("reset_view_to_initial")
			# load the scene title / name
			Editor.call_deferred("set_scene_name", the_scene.name)
			# then jump to a node if annotated
			if node_id >= 0:
				if the_scene.map.has(node_id):
					jump_to_node(node_id)
				else:
					print_stack()
					printerr(("Trying to jump to nonexistent node = %s" % node_id), (" in the scene = %s " % scene_id))
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
				# it can check only for existance of the key if value is `null`
				for item in _PROJECT.resources[field]:
					for key in filters:
						if _PROJECT.resources[field][item].has(key):
							if filters[key] == null || _PROJECT.resources[field][item][key] == filters[key]:
								_filtered[item] = _PROJECT.resources[field][item]
			# then exclude unwanteds
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
						# and exclude those wich have the key, unless the value is not the same
							if exclusion[key] != null && _filtered[item][key] != exclusion[key]:
								result[item] = _filtered[item]
			return result.duplicate(true)
		else:
			print_stack()
			printerr("Unexpected Behavior! The field = %s is not found in the dataset." % field)
		return {}
	
	# tells you if a node is selected
	# and can also manage selection if a boolean is also passed (true = select, false = unselect)
	func track_nodes_selection(node_id:int, select_or_unselect = null) -> bool:
		var is_already_selected = _SELECTED_NODES_IDS.has(node_id)
		if select_or_unselect is bool:
			if select_or_unselect == true:
			# selection
				if is_already_selected :
					print_stack()
					printerr("Unexpected Behavior! Trying to select an already selected node!", node_id)
				elif node_id >= 0 && _PROJECT.resources.nodes.has(node_id):
					_SELECTED_NODES_IDS.push_front(node_id)
					react_to_selection_change(false, node_id, select_or_unselect)
				else:
					print_stack()
					printerr("Unexpected Behavior! Tracking Invalid or None-existing Node-id ! ", node_id)
			else: # == false
				# unselection
				if is_already_selected :
					_SELECTED_NODES_IDS.erase(node_id)
					react_to_selection_change(false, node_id, select_or_unselect)
				else:
					print_stack()
					printerr("Unexpected Behavior! Trying to unselect a node that is not selected!")
		else: # just wants to know if selected
			return is_already_selected 
		return false

	func force_unsellect_all() -> void:
		_SELECTED_NODES_IDS.clear()
		react_to_selection_change(true)
		Grid.call_deferred("force_unselect_all")
		pass
	
	func react_to_scene_change(new_scene_id:int = -1) -> void:
		# anyway react to selection, because there might be some kind of change not tracked
		react_to_selection_change(true)
		# we shall also tell the inspector's macros tab to react, whether it's a scene or a macro.
		Inspector.Tab.Macros.call_deferred("update_macro_editorial_state", new_scene_id)
		Inspector.Tab.Scenes.call_deferred("update_scene_editorial_state", new_scene_id)
		pass
	
	func react_to_selection_change(_manual_change_happened:bool = false, _last_change_node_id:int = -1, _select_or_unselect = null) -> void:
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
		go_to_grid_offset(destination)
		if select == true:
			_SELECTED_NODES_IDS = [node_id]
			Grid.call_deferred("select_node_by_id", node_id)
		pass
	
	func go_to_grid_offset(offset:Array = [0,0]) -> void:
		Grid.call_deferred("got_to_offset", offset)
		pass
		
	func create_new_resource_id() -> int:
		var the_new_seed_uid = _PROJECT.next_resource_seed
		_PROJECT.next_resource_seed +=1
		return the_new_seed_uid
	
	var _CHACED_COMPILED_REGEXES = {}
	func compiled_regex_from(pattern:String) -> RegEx:
		if _CHACED_COMPILED_REGEXES.has(pattern) == false:
			var the_regex = RegEx.new()
			the_regex.compile(pattern) 
			_CHACED_COMPILED_REGEXES[pattern] = the_regex
		return _CHACED_COMPILED_REGEXES[pattern]

	# creation and caching of the node type name abbreviations (on demand) to use on new node naming
	var _chached_type_abbreviations_by_name = {}
	var _chached_type_abbreviations = {}
	const ALL_VOWELS_BUT_FIRST_CHAR_REGEX_PATTERN = "(\\B[AaEeYyUuIiOo]|\\W|_)*" # ~ /\B[AaEeYyUuIiOo]*/ all vovels other than the character
	const WHITE_SPACE_REGEX_PATTERN = "_"
	const ABBREVIATION_WHITE_SPACE_REPLACEMENT = "_"
	func get_type_name_abbreviation(type_name:String) -> String:
		var type_abbreviation
		# we have made abbreviation already? return from cache
		if _chached_type_abbreviations_by_name.has(type_name):
			type_abbreviation = _chached_type_abbreviations_by_name[type_name]
		# otherwise make abbreviation, cache and return it
		else:
			var abbreviation_length = Settings.MINIMUM_TYPE_ABBREVIATION_LENGTH
			# keep only the consonants and no vowels other than the first character
			var consonant_only_type_name = compiled_regex_from(ALL_VOWELS_BUT_FIRST_CHAR_REGEX_PATTERN).sub(type_name, "", true)
			if consonant_only_type_name.length() < abbreviation_length: # unless the name gets too short, where we use full type name (without whitespaces)
				consonant_only_type_name = compiled_regex_from(WHITE_SPACE_REGEX_PATTERN).sub(type_name, ABBREVIATION_WHITE_SPACE_REPLACEMENT, true)
			# now cut the word to a short sub string
			# and go for a little longer version if the abbreviation is used already for another type
			while _chached_type_abbreviations_by_name.has(type_name) == false :
				type_abbreviation = consonant_only_type_name.substr(0, abbreviation_length).capitalize()
				if _chached_type_abbreviations.has(type_abbreviation):
					abbreviation_length += 1
					# ready for almost impossible situation?
					# in case that any substring of `consonant_only_type_name` is used for other types (?!) ...
					if abbreviation_length > consonant_only_type_name.length() :
						# use full type name (without whitespaces) and a random affix to create the abbreviation
						abbreviation_length = Settings.MINIMUM_TYPE_ABBREVIATION_LENGTH
						consonant_only_type_name = (
							compiled_regex_from(WHITE_SPACE_REGEX_PATTERN).sub(type_name, ABBREVIATION_WHITE_SPACE_REPLACEMENT, true) +
							Generators.create_random_string( abbreviation_length, true, "\\W|\\d" )
						)
				else:
					_chached_type_abbreviations[type_abbreviation] = type_name
					_chached_type_abbreviations_by_name[type_name] = type_abbreviation
		return type_abbreviation
	
	func make_node_name_from(prefix:String, node_id:int, type_name:String) -> String:
		return NODE_INITIAL_NAME_TEMPLATE.format({
			"node_id":  node_id,
			"node_id_base36":  Utils.int_to_base36(node_id).to_lower(),
			"prefix": prefix,
			"type_abbreviation": get_type_name_abbreviation(type_name)
		})
	
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
			name_prefix = (scene_type_prefix + String(_CURRENT_OPEN_SCENE_ID))
		if type in NODE_TYPES_LIST:
			return {
				"type": type,
				"name": make_node_name_from(name_prefix, new_node_seed_uid, type),
				"data": Inspector.Tab.Node.SUB_INSPCETORS[type]._create_new(new_node_seed_uid)
			}
		return null
	
	func create_insert_node(type:String, offset:Vector2, scene_id:int = -1, draw:bool=true, name_prefix:String="", preset:Dictionary = {}) -> int:
		# create the node in memory
		var new_node_seed_uid = create_new_resource_id()
		var the_node = create_new_node(type, new_node_seed_uid, name_prefix)
		if the_node != null:
			var the_type = NODE_TYPES_LIST[type]
			var the_map  = { "offset": Utils.vector2_to_array(offset) }
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
					"Unexpected Behaviour! Entry node = %s" % entry_node_id,
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
	
	func is_node_name_available(name:String) -> bool:
		var matches = query_nodes_by_name(name, -2) # -2 means all the nodes in the dataset
		# `matches` is a dictionary of all identically named nodes by id (case-insensitive)
		if matches.size() == 0 :
			return true
		return false
	
	func update_scene_entry(node_id:int) -> void:
		var the_owner_scene_id = find_scene_owner_of_node(node_id)
		if the_owner_scene_id >= 0 :
			var the_scene = _PROJECT.resources.scenes[the_owner_scene_id]
			var current_scene_entry = the_scene.entry
			if node_id != current_scene_entry:
				the_scene.entry = node_id
		pass
	
	func update_project_entry(node_id:int) -> void:
		var the_owner_scene_id = find_scene_owner_of_node(node_id)
		if the_owner_scene_id >= 0 : # a scene must own this node
			var the_scene = _PROJECT.resources.scenes[the_owner_scene_id] 
			# but the owner scene shall not be a macro
			if the_scene.has("macro") == false || the_scene.macro == false:
				var current_project_entry = _PROJECT.entry
				if node_id != current_project_entry:
					_PROJECT.entry = node_id
			else:
				show_error("Invalid Operation!", "Macros are repeatable scenes, they are not designed to own the project entry node!")
		pass
	
	# because there must always be an entry it can only set/update entry and never unset/remove
	func handle_as_entry_command_parameter(_as_entry:Dictionary) -> void:
		# _as_entry: { id:resource_id, for_scene:bool, for_project:bool }
		# Note: scene_id is auto-detected, first from the open scene, then by looking all the scenes up
		if _as_entry.has("node_id") && _as_entry.node_id is int && _PROJECT.resources.nodes.has(_as_entry.node_id):
			if _as_entry.has("for_scene") && _as_entry.for_scene == true:
				update_scene_entry(_as_entry.node_id)
			if _as_entry.has("for_project") && _as_entry.for_project == true:
				update_project_entry(_as_entry.node_id)
		else:
			print_stack()
			printerr("Unexpected Behaviour! Invalid _as_entry command or trying to make a nonexistent node as entry point. _as_entry: ", _as_entry)
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
			var droping = lookup_resource(job_resource_id, lookup_priority_field, false)
			if droping is Dictionary && droping.has("use"):
				if droping.use is Array && droping.use.has(user_resource_id):
					droping.use.erase(user_resource_id)
				else:
					print_debug("Warn! Tring to drop nonexistent link! user = %s & _use: " % user_resource_id, _use, " used: ", droping)
				# `use` is an optional (array) so when empty, it can be removed from file to optimize size:
				if (droping.use is Array) == false || droping.use.size() == 0:
					droping.erase("use")
		# ... and remove refrences from user resource as well
		if the_user_resource_original.has("ref") && the_user_resource_original.ref is Array:
			for job_resource_id in drops:
				if the_user_resource_original.ref.has(job_resource_id):
					the_user_resource_original.ref.erase(job_resource_id)
		# and referencing jobs
		for job_resource_id in refers:
			var referencee = lookup_resource(job_resource_id, lookup_priority_field, false)
			if referencee is Dictionary:
				if referencee.has("use") == false || (referencee.use is Array) == false:
					referencee.use = [user_resource_id]
				else:
					if referencee.use.has(user_resource_id) == false: # avoid duplicate reference
						referencee.use.append(user_resource_id)
		# ... and add new refrences to user resource as well
		if (the_user_resource_original.has("ref") == false) || ((the_user_resource_original.ref is Array) == false) :
			the_user_resource_original.ref = []
		for job_resource_id in refers:
			if (the_user_resource_original.ref.has(job_resource_id) == false) :
				the_user_resource_original.ref.append(job_resource_id)
		# and because "ref" is an optional field, we will remove it to optimize for size ...
		if the_user_resource_original.ref.size() == 0:
			the_user_resource_original.erase("ref")
		# force update tabs because references may have changed
		# (`_use` command may be sent with different resource types / fields at the same time, so we refresh both)
		for tab in ['Variables', 'Characters', 'Macros']:
			Inspector.Tab[tab].call_deferred("refresh_tab")
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
						if the_user_resource is Dictionary && the_user_resource.has("name"):
							use_cases_id_to_name_list[user_res_id] = the_user_resource.name
		return use_cases_id_to_name_list
	
	func update_inspector_if_node_open(node_id:int) -> void:
		if node_id >= 0 && Inspector.Tab.Node._CURRENT_INSPECTED_NODE_RESOURCE_ID == node_id:
			inspect_node(node_id, -1, false)
		pass
	
	func revise_variable_exposure(referrers_list:Array, old_name:String, new_name:String) -> void:
		var old_exposure = "{%s}" % old_name
		var new_exposure = "{%s}" % new_name
		for referer_resource_id in referrers_list:
			var referrer_original = lookup_resource(referer_resource_id, "nodes", false) # only nodes can expose variables
			if referrer_original.has("data") && referrer_original.data is Dictionary:
				var data_modification = { "data": {} }
				for property in referrer_original.data:
					var value = referrer_original.data[property]
					if value is String && value.find(old_exposure) != -1:
						data_modification.data[property] = value.replace(old_exposure, new_exposure)
					elif value is Array: # mainly for dialogs and interactions
						data_modification.data[property] = value.duplicate(true)
						for i in range(0, value.size()):
							if value[i] is String && value[i].find(old_exposure) != -1:
								data_modification.data[property][i] = value[i].replace(old_exposure, new_exposure)
				if data_modification.data.size() > 0:
					update_resource(referer_resource_id, data_modification, "nodes")
		pass
	
	# updates existing resource. To create one use `write_resource`
	func update_resource(resource_uid:int, modification:Dictionary, field:String = "", is_auto_update:bool = false) -> void:
		var validated_field = find_resource_field(resource_uid, field)
		var the_resource = lookup_resource(resource_uid, validated_field, false) # duplicate = false ...
		var the_recource_old_name = the_resource.name if the_resource.has("name") else null
		# ... so we can directrly update the resource 
		if the_resource is Dictionary:
			# handing special command/parameters (_use, _as_entry, ...?)
			if modification.has("data"): # they come only from nodes (sub-inspectors) so can be find in `data`
				if modification.data.has("_use"):
					# handle then remove the pair, to avoid writing it with database
					if modification.data._use is Dictionary:
						handle_use_command_parameter(resource_uid, modification.data._use)
					modification.data.erase("_use")
				if modification.data.has("_as_entry"):
					# handle then remove the pair, to avoid writing it with database
					if modification.data._as_entry is Dictionary:
						handle_as_entry_command_parameter(modification.data._as_entry)
					modification.data.erase("_as_entry")
			# update the resource
				# passed parameters: 'false: to add optional pairs like notes, true: to remove empty pair keys, false : to edit the original'
			Utils.recursively_update_dictionary(the_resource, modification, false, true, false)
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
					if the_resource.name != the_recource_old_name : # name update means we need to,
						# update all exposures of this variable in other referrer nodes
						if the_resource.has("use") && the_resource.use is Array :
							revise_variable_exposure(the_resource.use, the_recource_old_name, the_resource.name)
				"characters":
					Inspector.Tab.Characters.call_deferred("list_characters", { resource_uid: the_resource })
			# ... also update any node that uses this resource
			if the_resource.has("use"):
				for referrer_id in the_resource.use:
					if _PROJECT.resources.scenes[_CURRENT_OPEN_SCENE_ID].map.has(referrer_id):
						Grid.call_deferred("update_grid_node_box", referrer_id, _PROJECT.resources.nodes[referrer_id])
			# print_debug("Update resource call: ", modification, the_resource, lookup_resource(resource_uid, field, false))
		elif is_auto_update != true: # inspector may try to auto update a recently deleted node automatically
			print_stack()
			printerr("Unexpected Behaviour! Trying to update resource = %s which is not Dictionary!" % resource_uid)
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
			var none_removables
			if field == "scenes":
				# check if we can remove all nodes in the scene
				# returns list
				none_removables = batch_remove_resources(the_resource.map.keys(), "nodes", false, true, true)
				is_removable = (none_removables.ids.size() == 0)
			# for other resources:
			if is_removable == true || forced == true:
				# this resource might be *user* of other nodes/resources, so...
				if the_resource.has("ref") && (the_resource.ref is Array) && the_resource.ref.size() > 0:
					handle_use_command_parameter(resource_uid, {
						# drop all the resources (`ref`erences) this resource is using
						"drop": the_resource.ref.duplicate(true)
					})
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
						# but this side's map shall be removed compeletely from the scene
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
					"Unsafe Operation Discarded!",
					"The resource can not be removed, because some other nodes or resources rely on this one. " +
					(
						"For example, one of the child nodes of the scene might be referenced by a jump in another scene."
						if field == "scenes" else ""
					) +
					(
						"\nReferenced resources are: \n\n\t" + PoolStringArray(none_removables.names).join(", ")
						if none_removables is Dictionary else ""
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
		var nopee_names = []
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
							nopee_names.append(res.name)
							do_drop = false
							break
						else:
							do_drop = true
					if do_drop:
						drop.append([res_id, res.use])
			else:
				nope.append([res_id, "Scene or Project Entry!"])
		var check_result
		if nope.size() == 0:
			if check_only != true:
				# let's sort dropees first, to make sure user-resources will be removed first
				for __ in range(0, drop.size()):
					drop.sort_custom(self, "resource_referrer_custom_sorter")
				print_debug("Batch removal: ", drop)
				for idx in range(0, drop.size()):
					remove_resource(drop[idx][0], field, true)
			check_result = true
		else:
			if check_only != true:
				show_error(
					"Unsafe Operation Discarded.",
					(
						"At least one the resources you want to remove is used by another resource or node. " +
						"We can't proceed this operation, unless you remove referrers as well. \nUsed one(s) are: %s"
					) % nopee_names
				)
				printerr("Batch remove operation discarded due to existing use cases: ", nope)
			check_result = false
		return (
			{
				"ids"  : nope,
				"names": nopee_names
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
			
	func are_nodes_moveable(node_id_list:Array) -> bool:
		return (
			node_id_list.has( Main.Mind.get_scene_entry(-1) ) == false &&
			node_id_list.has( Main.Mind.get_project_entry() ) == false
		)
	
	func update_node_map(node_id:int, modification:Dictionary, scene_id:int = -1) -> void:
		if scene_id == -1:
			scene_id = _CURRENT_OPEN_SCENE_ID
		if _PROJECT.resources.scenes[scene_id].map.has(node_id) == false:
			scene_id = find_scene_owner_of_node(node_id)
		if scene_id >= 0:
			# bacause maps are dictionaries...
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
							new_offset = Utils.vector2_to_array(modification.offset)
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
		var the_name = ("new_variable_" + Utils.int_to_base36(id))
		if Settings.FORCE_UNIQUE_NAMES_FOR_VARIABLES:
			var all_variable_names = list_all_resource_ids_by_name_of("variables")
			while all_variable_names.has(the_name):
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
		var the_name = ("new_character_" + Utils.int_to_base36(id))
		if Settings.FORCE_UNIQUE_NAMES_FOR_CHARACTERS:
			var all_character_names = list_all_resource_ids_by_name_of("characters")
			while all_character_names.has(the_name):
				the_name += Settings.REUSED_CHARACTER_NAMES_AUTO_POSTFIX
		return the_name
	
	func create_new_character() -> void:
		var new_res_seed_id = create_new_resource_id()
		var the_new_character = {
			"name": create_character_name_from_id(new_res_seed_id),
			"color": Generators.create_random_color().to_html()
		}
		write_resource("characters", the_new_character, new_res_seed_id, false)
		Inspector.Tab.Characters.call_deferred("list_characters", ({ new_res_seed_id: the_new_character }))
		pass
	
	func create_new_scene(is_macro:bool = false):
		var new_scene_seed_id = create_new_resource_id()
		var the_new_scene = {
			"name": ("macro_" if is_macro else "scene_") + String(new_scene_seed_id),
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
		var name_prefix = scene_type_prefix + String(new_scene_seed_id)
		var the_node = create_new_node(required_entry_type, new_node_seed_uid, name_prefix)
		if the_node != null:
			var the_map  = { "offset": Utils.vector2_to_array(Settings.NEW_SCENE_OR_MACRO_REQUIRED_INITIAL_ENTRY_NODE_OFFSET) }
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
				elif value != null :
					var value_string = String(value)
					if value_string.length() > 0 :
						for query in what:
							if (regexp == true && query.search(value_string)) || (regexp == false && value_string.matchn(query)):
								result.append(item)
								break
		return result
	
	func report_query(found_node_ids:Array) -> void:
		var report = {}
		for node_id in found_node_ids:
			report[node_id] = _PROJECT.resources.nodes[node_id]
		Query.call_deferred("update_query_results", report)
		pass
	
	func clipboard_push(nodes_list:Array, mode:int = CLIPBOARD_MODE.EMPTY) -> void:
		if mode is int && mode >= 0 && mode < CLIPBOARD_MODE.size():
			if nodes_list is Array && nodes_list.size() > 0:
				_CLIPBOARD.MODE = mode
				_CLIPBOARD.DATA = nodes_list.duplicate(true)
				Grid.call_deferred("highlight_nodes", _CLIPBOARD.DATA, false, true)
			else:
				Grid.call_deferred("highlight_nodes", _CLIPBOARD.DATA, true, true)
				_CLIPBOARD.MODE = CLIPBOARD_MODE.EMPTY
				_CLIPBOARD.DATA = null
			print_debug("Clipboard (%s) : " % CLIPBOARD_MODE.keys()[_CLIPBOARD.MODE], _CLIPBOARD.DATA)
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
		if _CLIPBOARD.MODE != CLIPBOARD_MODE.EMPTY:
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
			if Utils.array_to_vector2(maps_reference[original_id].offset).length() < Utils.array_to_vector2(maps_reference[closest].offset).length():
				closest = original_id
		var offset_adjustment_vector = (offset - Utils.array_to_vector2(maps_reference[closest].offset))
		# then create copies
		var id_conversation_table = {}
		for original_id in copying_nodes_id_list:
			var original = lookup_resource(original_id, "nodes", false)
			var the_offset = (offset_adjustment_vector + Utils.array_to_vector2(maps_reference[original_id].offset))
			var new_id = create_insert_node(original.type, the_offset, -1, true, "", { "data": original.data.duplicate(true) })
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
			if Utils.array_to_vector2(maps_reference[moving_id].offset).length() < Utils.array_to_vector2(maps_reference[closest].offset).length():
				closest = moving_id
		var offset_adjustment_vector = (offset - Utils.array_to_vector2(maps_reference[closest].offset))
		# disconnect moving ones from nodes which aren't in the move list
		# Note: one side of every link keeps the connection data, so we have to iterrate over all the node maps in the same scene
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
			var destination_offset = (offset_adjustment_vector + Utils.array_to_vector2(maps_reference[moving_id].offset))
			maps_reference[moving_id].offset = Utils.vector2_to_array(destination_offset)
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
		
	func clipboard_pull(offset:Vector2) -> void:
		if clipboard_available() :
			offset = offset.floor()
			print_debug("Paste (%s) " % CLIPBOARD_MODE.keys()[_CLIPBOARD.MODE], "at %s :" % offset, _CLIPBOARD.DATA)
			match _CLIPBOARD.MODE:
				CLIPBOARD_MODE.COPY:
					copy_nodes_to_offset(offset, _CLIPBOARD.DATA)
				CLIPBOARD_MODE.CUT:
					if are_nodes_moveable(_CLIPBOARD.DATA) :
						# clipboard pulls replace one another, so all the nodes listed there are from one owner scene
						# and currently paste can only happens to the current open scene
						# these are also the `move_nodes_...` function's defaults
						# so we'll use the default of the move and give only two first parameters
						move_nodes_to_offset(offset, _CLIPBOARD.DATA)
						# and finally clean up the clipboard after move
						clipboard_push([], CLIPBOARD_MODE.EMPTY) 
					else:
						printerr("Unexpected Behavior! The nodes in clipboard are not moveable!, ", _CLIPBOARD)
		pass
	
	func register_project_and_save_from_open(project_title:String, project_filename:String) -> void:
		if project_title.length() > 0 && project_filename.length() > 0 :
			ProMan.register_project(project_title, project_filename, true)
			reset_project_title(project_title) # just registered, no need for re-updating ProMan's list
			reset_project_last_save_time()
			# then saves it
			ProMan.save_project(_PROJECT, false, Main.Configs.CONFIRMED.textual_save_data)
			# and update current view
			reset_project_save_status()
			load_projects_list()
			activate_project_properties()
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
				reset_project_last_save_time()
				ProMan.save_project(_PROJECT, false, Main.Configs.CONFIRMED.textual_save_data)
				reset_project_save_status()
				if try_close_project:
					close_project(false, try_quit_app)
				load_projects_list()
		else:
			show_error(
				"Invalid Operation!",
				(
					"We can not save projects in snapshot preview mode.\n" +
					"If you intend to keep the snapshot, take another snapshot of it to keep modifications in memory, " +
					"or restore the open snapshot as the working draft and save it.\n" +
					"You can also export any previewed snapshot and reimport it as a new project."
				)
			)
		pass
	
	func remove_local_project(project_id) -> void:
		print_debug("Removing project id: ", project_id)
		# currently, removing an item only unlists it
		# file won't be removed to avoid accidents
		ProMan.unlist_project(project_id)
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
		var now = OS.get_datetime(false) # UTC:bool = false
		var to_be_snapshot_index = _SNAPSHOTS.size()
		if _SNAPSHOT_INDEX_OF_PREVIEW < 0 :
			_SNAPSHOTS_COUNT_PURE_ONES += 1
			version = String(_SNAPSHOTS_COUNT_PURE_ONES)
			print_debug("New Snapshot! v%s " % version)
		else:
			var base = _SNAPSHOTS[_SNAPSHOT_INDEX_OF_PREVIEW]
			version = base.version + "." + String(base.branchs.size() + 1)
			# append index of the to-be-added snapshot as the branch of the base
			base.branchs.push_back( to_be_snapshot_index )
			print_debug("A Snapshot of another snapshot made! v%s" % version)
		_SNAPSHOTS.push_back({
			"version": version,
			"time": now,
			"project": _PROJECT.duplicate(true), # Note: it may be a previewed snapshot
			"branchs": [],
		})
		# list it
		if custom_version_prefix.length() == 0 :
			custom_version_prefix = Settings.SNAPSHOT_VERSION_PREFIX 
		var full_version_code = ( custom_version_prefix + version)
		Inspector.Tab.Project.call_deferred("list_snapshot", {
			"index":to_be_snapshot_index, "version": full_version_code, "time": now
		}, is_project_local())
		pass
	
	func preview_snapshot(idx:int) -> void:
		if idx >= 0 && _SNAPSHOTS.size() > idx :
			_SNAPSHOT_INDEX_OF_PREVIEW = idx
			_MASTER_PROJECT_SAFE = _PROJECT.duplicate(true)
			load_project( _SNAPSHOTS[idx].project.duplicate(true), false, true )
		pass
	
	func return_to_master_project() -> void:
		if _SNAPSHOT_INDEX_OF_PREVIEW >= 0:
			_SNAPSHOT_INDEX_OF_PREVIEW = -1
			load_project( _MASTER_PROJECT_SAFE.duplicate(true), false, true )
			_MASTER_PROJECT_SAFE.clear()
		else:
			print_stack()
			printerr("Unexpected Behavior! Trying to return to master branch when no snapshot is open!")
		pass
	
	func restore_snapshot(snapshot_idx:int) -> void:
		if snapshot_idx >= 0 && _SNAPSHOTS.size() > snapshot_idx :
			clean_inspector_tabs()
			load_project( _SNAPSHOTS[snapshot_idx].project.duplicate(true), false, true )
			reset_project_save_status(false)
			_MASTER_PROJECT_SAFE.clear()
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
					(
						"You're about to restore snapshot `%s`. " +
						"This operation will override current state of the project in memory, " +
						"but the file (unless saved afterwards) or other snapshots won't budge.\n" +
						"If you intend to use current draft later, " +
						"make sure to close preview and take a snapshot, before restoring this one."
					) % snapshot_version
				),
				[ { "label": "Restore; I'm Sure", "callee": Main.Mind, "method": "restore_snapshot", "arguments": [index] },],
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
			ProMan.save_project_into(target_registered_uid_to_save_into, importing_data, false, Main.Configs.CONFIRMED.textual_save_data)
			load_projects_list()
		else:
			printerr("Invalid Project File! The file selected is not of a supported format or is corrupted.")
		pass
	
	var _QUICK_EXPORT_FORMAT: String
	var _QUICK_EXPORT_FILENAME: String
	var _QUICK_EXPORT_BASE_DIR: String
	func quick_re_export() -> void:
		if _QUICK_EXPORT_FORMAT.length() > 0 && _QUICK_EXPORT_FILENAME.length() > 0 && _QUICK_EXPORT_BASE_DIR.length() > 0:
			export_project_as(_QUICK_EXPORT_FORMAT, _QUICK_EXPORT_FILENAME, _QUICK_EXPORT_BASE_DIR)
		else:
			show_error(
				"Quick Re-Export Not Available!",
				"You have not yet exported your project in current session.\n" +
				"This shortcut allows re-exporting project with path and format of the latest export.\n" +
				"Please export your project first from `Inspector panel > Project tab > Export`."
			)
		pass
	
	func export_project_as(format, filename:String, base_directory:String) -> void:
		if filename.is_valid_filename() && Utils.is_abs_or_rel_path(base_directory):
			if format is String && format.length() > 0:
				var formated_filename = (filename + "." + format)
				var full_export_file_path = (Utils.normalize_dir_path(base_directory) + formated_filename)
				print_debug("Saving a Copy of the Project as `%s` to: "% (formated_filename), base_directory )
				match format.to_lower():
					"json":
						ProMan.save_project_native_file(_PROJECT, full_export_file_path, true)
					"html":
						var html_creation_state = ProMan.export_playable_html(full_export_file_path, _PROJECT)
						if html_creation_state == OK :
							OS.shell_open(full_export_file_path)
						else:
							printerr('Unable to Read template or Write to the file!', full_export_file_path, html_creation_state)
							show_error(
								"Operation Failed!",
								"We are not able to write to the path. Please check out if arrow has Write Permission to the destination."
							)
				# cache quick re-export data
				_QUICK_EXPORT_FORMAT = format
				_QUICK_EXPORT_FILENAME = filename
				_QUICK_EXPORT_BASE_DIR = base_directory
			else:
				# format is not specified so use native project format
				var full_export_file_path = (Utils.normalize_dir_path(base_directory) + filename + Settings.PROJECT_FILE_EXTENSION)
				ProMan.save_project_native_file(_PROJECT, full_export_file_path, Main.Configs.CONFIRMED.textual_save_data)
				print_debug("Saving a Copy of the Project as `%s` to: "% (filename + Settings.PROJECT_FILE_EXTENSION), base_directory )
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
	
	func locate_node_on_grid(node_id:int = -1, hightlight:bool = true, force_change_scene:bool = true) -> void:
		if node_id >= 0:
			var owner_scene = find_scene_owner_of_node(node_id)
			if owner_scene >= 0:
				if _CURRENT_OPEN_SCENE_ID != owner_scene && force_change_scene == true:
					scene_editorial_open(owner_scene, false)
				# now if we can (~ we was or we are in the scene,) we jump
				if _CURRENT_OPEN_SCENE_ID == owner_scene:
					Grid.call_deferred("go_to_offset_by_node_id", node_id, hightlight)
		pass

	func show_error(heading:String = "Error!", message:String = "Something's going wrong. Check stdout for more information", color:Color = Settings.WARNING_COLOR, actions:Array = []) -> void:
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
			force_unsellect_all()
		elif event.is_action_pressed("arrow_switch_auto_inspection"):
			Main.call_deferred("toggle_quick_preferences", "auto_inspect", true)
		elif event.is_action_pressed("arrow_switch_auto_node_update"):
			Main.call_deferred("toggle_quick_preferences", "auto_node_update", true)
		elif event.is_action_pressed("arrow_switch_quick_node_insertion"):
			Main.call_deferred("toggle_quick_preferences", "quick_node_insertion", true)
		elif event.is_action_pressed("arrow_switch_connection_assist"):
			Main.call_deferred("toggle_quick_preferences", "connection_assist", true)
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
		else:
			handled = false
		return handled
