# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Project Management
class_name ProjectManagement

const PROJECT_LIST_FILE_NAME = Settings.PROJECT_LIST_FILE_NAME
const JSON_FLOAT_PRECISION_HACK = 10_000_000

class ProjectManager :
	
	var PROJECT_FILE_EXTENSION_WITHOUT_DOT = Settings.PROJECT_FILE_EXTENSION.replacen(".", "")
	
	var _MAIN
	var _ALDP # app local/work directory path (ends with `/`)
	var _PROJECT_LIST # by UIDs (check out `Embedded::Data::Blank_Project_List`)
	
	var _ACTIVE_PROJECT_UID:int = -1
	var _IS_ACTIVE_PROJECT_SAVED:bool = false

	func _init(current_app_local_dir:String, main: Object) -> void:
		_MAIN = main
		hold_local_app_dir(current_app_local_dir)
		pass
	
	func hold_local_app_dir(app_local_dir:String) -> void:
		_ALDP = Helpers.Utils.normalize_dir_path(app_local_dir)
		print_debug("Project Manager Holding Local App Directory: ", _ALDP)
		# check _ALDP for access
		if Helpers.Utils.is_access_granted_to_dir(_ALDP, FileAccess.WRITE_READ):
			# ... and necessary files (discover or create)
			_PROJECT_LIST = read_project_list_file(true)
		else:
			printerr("ACCESS FAILED! RW Permission to Local App/Work Directory is NOT GRANTED!")
		pass
	
	func validate_project_list_data(content):
		if content is Dictionary:
			var expected_keys = Embedded.Data.Blank_Project_List.keys()
			if content.has_all(expected_keys):
				return content
		return null
	
	# discovers or creates Projects list file
	func read_project_list_file(force_creation:bool = false):
		var project_list = null
		var project_list_file_path = _ALDP + PROJECT_LIST_FILE_NAME
		var file = FileAccess.open(project_list_file_path, FileAccess.READ)
		if file != null:
			var read_list;
			# First try to open the list as JSON:
			var file_content = file.get_as_text()
			var parsed_list = Helpers.Utils.parse_json(file_content)
			if parsed_list is Dictionary:
				read_list = Helpers.Utils.recursively_convert_numbers_to_int(parsed_list)
			else:
				# Try to open the list as stored variant (legacy:)
				read_list = file.get_var(true)
			var validated_project_list = validate_project_list_data(read_list)
			if validated_project_list != null:
				project_list = validated_project_list
			else:
				printerr("Invalid Project List File! ", project_list_file_path)
			file.close()
		else:
			project_list = Embedded.Data.Blank_Project_List.duplicate(true)
			if force_creation == true:
				var new_file = FileAccess.open(project_list_file_path, FileAccess.WRITE_READ)
				if new_file != null:
					var json_list = Helpers.Utils.stringify_json(project_list)
					new_file.store_string(json_list)
					new_file.close()
					print_debug("New project list file created. ", project_list_file_path)
				else:
					printerr("No Project List File Exists and we CAN NOT CREATE one!", _ALDP)
			else:
				printerr("No Project List File Exists! ", _ALDP)
				printerr("... A blank one will be used temporarily.")
		return project_list
	
	func save_project_list_file() -> void:
		var project_list_file_path = _ALDP + PROJECT_LIST_FILE_NAME
		var file = FileAccess.open(project_list_file_path, FileAccess.WRITE_READ)
		if file != null:
			var json_list = Helpers.Utils.stringify_json(_PROJECT_LIST)
			file.store_string(json_list)
			file.close()
		else:
			printerr("Unexpected Behavior! Can not open project list file to save new data in it! ", project_list_file_path)
		pass
	
	func get_projects_listed_by_id() -> Dictionary:
		return _PROJECT_LIST.projects

	func get_project_listing_by_id(pid: int):
		if _PROJECT_LIST.projects.has(pid):
			return _PROJECT_LIST.projects[pid]
		return null
		
	func get_active_project_id() -> int:
		return _ACTIVE_PROJECT_UID
	
	func hold_untitled_project() -> Dictionary:
		_ACTIVE_PROJECT_UID = -1
		_IS_ACTIVE_PROJECT_SAVED = true
		var untitled_project = Embedded.Data.Untitled_Project.duplicate(true)
		if Settings.FORCE_SNOWFLAKE_UID_FOR_NEW_PROJECTS == true:
			untitled_project.meta.epoch = Flake.Snow._unsafe_unix_now_millisecond()
		print_debug("holding untitled (blank) project: ", untitled_project.meta)
		return untitled_project
	
	func is_project_listed(project_uid:int = _ACTIVE_PROJECT_UID) -> bool:
		if project_uid >= 0 && _PROJECT_LIST.projects.has(project_uid):
			return true
		else:
			return false
	
	func get_project_file_path(project_uid:int, fix_extension:bool = true):
		if is_project_listed(project_uid):
			var path = _ALDP + _PROJECT_LIST.projects[project_uid].filename
			if fix_extension:
				if path.ends_with(Settings.PROJECT_FILE_EXTENSION) == false:
					path += Settings.PROJECT_FILE_EXTENSION
			return path
		else:
			return null
	
	func is_project_file_accessible(project_uid_or_path) -> bool:
		# it also checks for project being listed
		var project_file_path = (get_project_file_path(project_uid_or_path) if (project_uid_or_path is int) else project_uid_or_path)
		# ... so if project is listed, there is a path
		if project_file_path is String :
			# but file might not be where listed or accessible anymore, so check:
			if Helpers.Utils.file_is_accessible(project_file_path):
				return true
			else:
				printerr("Project File Inaccessible! Either project list file is corrupted or state of the project file (existence, RW permission) is changed! Inspect this path: ", project_file_path)
		else:
			printerr("Unexpected Behavior! Trying to check existence of none-listed project = %s !" % project_file_path)
		return false
	
	func is_authors_dictionary_valid(checked) -> bool:
		if (checked is Dictionary) == false:
			return false
		else:
			for key in checked:
				if (
					key is int && # Has author ID
					( # and the author meta data
						checked[key] is String || # in old format (only info)
						(
							# or new format including info and resource seed (always -1 if snowflakes are used)
							checked[key] is Array && checked[key].size() >= 2 &&
							checked[key][0] is String && checked[key][1] is int
						)
					)
				) == false:
					return false
		return true
	
	const PROJECT_DATA_MANDATORY_FIELDS = [ "title", "entry", "meta", "resources" ]
	const PROJECT_DATA_RESOURCES_MANDATORY_SETS = [ "scenes", "nodes", "variables", "characters" ]
	const DATASET_ITEM_MANDATORY_FIELDS_FOR_SET = {
		"scenes": [ "name", "entry", "map" ],
		"nodes": [ "type", "name", "data" ],
		"variables": [ "name", "type", "init" ],
		"characters": [ "name", "color" ]
	}
	
	func validate_project_data(project) -> bool:
		# Note: only essential validation (node type related checks shall be done by the respective module)
		if project is Dictionary && project.size() > 0 :
			if project.has_all( PROJECT_DATA_MANDATORY_FIELDS ):
				if project.resources.has_all( PROJECT_DATA_RESOURCES_MANDATORY_SETS ):
					if (
						( # Projects need to have minimum meta data necessary for resource UID management
							( # in old (legacy) format with local (none-distributed) incremental tracker,
								project.has("next_resource_seed") &&
								(project.next_resource_seed is int) && project.next_resource_seed >= 0
							) ||
							( # or new distributed formats with multiple contributors
								project.meta.has("authors") && is_authors_dictionary_valid(project.meta.authors) &&
								# using either
								(
									# time-based (Snowflake) method
									( project.meta.has("epoch") && project.meta.epoch is int && project.meta.epoch > 0 ) ||
									# or native (recommended) method with support for chapters
									(
										project.meta.has("chapter") && project.meta.chapter is int &&
										project.meta.chapter >= 0 && project.meta.chapter < Flake.Native.CHAPTER_ID_EXCLUSIVE_LIMIT
									)
								)
							)
						) && # anyway they need to have valid `entry` node:
						(project.entry is int) && project.resources.nodes.has(project.entry)
					):
						for field in project.resources:
							for uid in project.resources[field]:
								if (
									((uid is int) != true) ||
									((project.resources[field][uid] is Dictionary) != true) ||
									(project.resources[field][uid].has_all( DATASET_ITEM_MANDATORY_FIELDS_FOR_SET[field] ) != true)
								):
									# doesn't pass general dataset checks
									return false
								else:
									# passes? what about dataset special checks?
									match field:
										"scenes":
											for map_uid in project.resources[field][uid].map:
												if (
													((map_uid is int) != true) ||
													((project.resources[field][uid].map[map_uid] is Dictionary) != true) ||
													(
														# offset is mandatory
														project.resources[field][uid].map[map_uid].has("offset") != true ||
														(project.resources[field][uid].map[map_uid].offset is Array) != true ||
														project.resources[field][uid].map[map_uid].offset.size() != 2 # [x, y]
													)
												):
													return false
										"nodes":
											if (project.resources[field][uid].data is Dictionary) != true:
												return false
										"variables":
											pass
										"characters":
											pass
						# passes all
						return true
		# passes none!
		return false
	
	# JSON keys can only be strings, while our resource keys are integers, so...
	# we need to refactor them
	func refactor_parsed_json_project_data(data:Dictionary) -> Dictionary:
		var refactoring = Helpers.Utils.recursively_convert_numbers_to_int(data)
		# print_debug("Refactored JSON project: ", refactoring)
		return refactoring
	
	func read_project_file_data(project_uid_or_file_path, try_json = null):
		# get the full path to the project file
		var full_project_file_path:String
		if project_uid_or_file_path is int:
			full_project_file_path = get_project_file_path(project_uid_or_file_path)
		elif Helpers.Utils.is_abs_or_rel_path(project_uid_or_file_path):
			full_project_file_path = project_uid_or_file_path
		else:
			printerr("Unexpected Behavior! function `read_project_file_data` called with wrong argument: ", project_uid_or_file_path)
			return null
		# and try to read the project out of it
		if is_project_file_accessible(full_project_file_path):
			var project_file_data = null
			var parsed_project_file_data = null
			if Settings.USE_DEPRECATED_BIN_SAVE != true || try_json == true:
				parsed_project_file_data = Helpers.Utils.read_and_parse_json_file(full_project_file_path)
			if parsed_project_file_data is Dictionary:
				project_file_data = refactor_parsed_json_project_data(parsed_project_file_data)
			else :
				project_file_data = Helpers.Utils.read_and_parse_variant_file(full_project_file_path)
			# validate the project file
			if project_file_data is Dictionary:
				if validate_project_data(project_file_data) == true:
					return project_file_data
		return null
	
	func read_browsed_project_content(json: String):
		var parsed = JSON.parse_string(json)
		if parsed is Dictionary:
			var project_file_data = refactor_parsed_json_project_data(parsed)
			if validate_project_data(project_file_data) == true:
				return project_file_data
		return null
	
	func hold_project_by_id(project_uid:int = -1):
		if is_project_listed(project_uid) == true:
			# read project file
			var project_data = read_project_file_data(project_uid)
			if project_data is Dictionary:
				# if seems ok:
				_ACTIVE_PROJECT_UID = project_uid
				_IS_ACTIVE_PROJECT_SAVED = true
				return project_data
		else:
			print_debug("Caution! You're holding a project with none-listed id = %s. Reset to blank!" % project_uid)
		return ERR_CANT_ACQUIRE_RESOURCE
		
	func valid_project_uid_or_default(project_uid:int = -1) -> int: 
		# acts as a conditional helper
		# returns `project_uid` if such an UID exists in the list, otherwise the current active project's UID
		# (the parameter might not be possible to pass (e.g. new blank project) or just not annotated (-1))
		return (project_uid if ((project_uid >= 0) && (_PROJECT_LIST.projects.has(project_uid))) else _ACTIVE_PROJECT_UID)
	
	func set_project_unsaved() -> void:
		_IS_ACTIVE_PROJECT_SAVED = false
		pass
	
	func is_project_saved(project_uid:int = -1) -> bool:
		if project_uid < 0:
			project_uid = _ACTIVE_PROJECT_UID
		# currently open project?
		if project_uid == _ACTIVE_PROJECT_UID:
			return _IS_ACTIVE_PROJECT_SAVED
		else:
			# but if it's not open, it must be saved if it's listed
			return is_project_listed()
	
	func set_project_last_open_scene(scene_id:int, project_uid:int = -1) -> void:
		project_uid = valid_project_uid_or_default(project_uid)
		if project_uid >= 0:
			_PROJECT_LIST.projects[project_uid]["last_open_scene"] = scene_id
		pass
	
	func get_project_last_open_scene(project_uid:int = -1) -> int:
		project_uid = valid_project_uid_or_default(project_uid)
		if project_uid >= 0:
			if "last_open_scene" in _PROJECT_LIST.projects[project_uid]:
				if _PROJECT_LIST.projects[project_uid].last_open_scene is int:
					return _PROJECT_LIST.projects[project_uid].last_open_scene
		return -1
	
	func get_project_description(project_uid:int = -1):
		if is_project_listed(project_uid):
			if _PROJECT_LIST.projects[project_uid].has("description"):
				return _PROJECT_LIST.projects[project_uid].description
		return null
	
	func set_project_last_view(state: Array = [0, 0, 1], scene_uid:int = -1, project_uid:int = -1) -> void:
		if state is Array && state.size() == 3:
			project_uid = valid_project_uid_or_default(project_uid)
			if is_project_listed(project_uid) && (scene_uid >= 0) :
				if _PROJECT_LIST.projects[project_uid].has("last_view") == false:
					_PROJECT_LIST.projects[project_uid].last_view = {}
				_PROJECT_LIST.projects[project_uid].last_view[scene_uid] = Helpers.Utils.refactor_array(state, JSON_FLOAT_PRECISION_HACK, false)
				print_debug("project %s last view set: " % project_uid, _PROJECT_LIST.projects[project_uid].last_view)
		else:
			printerr("Unexpected Behavior! Invalid state to set_project_last_view: ", state)
		pass
	
	func get_project_last_view(project_uid:int = -1, scene_uid:int = 0) -> Array:
		project_uid = valid_project_uid_or_default(project_uid)
		if is_project_listed(project_uid) && (scene_uid >= 0) :
			if _PROJECT_LIST.projects[project_uid].has("last_view"):
				if _PROJECT_LIST.projects[project_uid].last_view.has(scene_uid):
					print_debug("project %s last view get: " % project_uid, _PROJECT_LIST.projects[project_uid].last_view)
					var state = _PROJECT_LIST.projects[project_uid].last_view[scene_uid]
					return Helpers.Utils.refactor_array(state, JSON_FLOAT_PRECISION_HACK, true) # to correct precision
		return [0, 0, 1]
	
	func get_project_active_author(project_uid:int = -1):
		project_uid = valid_project_uid_or_default(project_uid)
		if project_uid >= 0:
			if "active_author" in _PROJECT_LIST.projects[project_uid]:
				if _PROJECT_LIST.projects[project_uid].active_author is int:
					return _PROJECT_LIST.projects[project_uid].active_author
		return null
	
	func set_project_active_author(active_author:int, project_uid:int = -1) -> void:
		project_uid = valid_project_uid_or_default(project_uid)
		if is_project_listed(project_uid):
			_PROJECT_LIST.projects[project_uid].active_author = active_author
		else:
			print_debug("project not listed; setting active author ignored.")
		pass
		
	func create_new_project_id() -> int:
		var the_new_seed_uid = _PROJECT_LIST.next_project_seed
		_PROJECT_LIST.next_project_seed += 1
		return the_new_seed_uid
	
	func valid_unique_project_filename_from(suggestion:String) -> String:
		# we don't want our extension in the file name
		suggestion = suggestion.replacen(PROJECT_FILE_EXTENSION_WITHOUT_DOT, "")
		# and optionally purge and replace some words from the filename
		for purge in Settings.PROJECT_FILE_NAME_PURGED_WORDS:
			suggestion = suggestion.replacen(purge, Settings.PROJECT_FILE_NAME_PURGED_WORDS_REPLACEMENT)
		if suggestion.length() == 0:
			# blank suggestion?! let's suggest a random one
			suggestion = (
				Settings.RANDOM_PROJECT_NAME_PREFIX +
				Helpers.Generators.create_random_string( Settings.RANDOM_PROJECT_NAME_AFFIX_LENGTH )
			)
		var result = Helpers.Utils.valid_filename(suggestion, false)
		var all_project_filenames = []
		for project_id in _PROJECT_LIST.projects:
			all_project_filenames.append(_PROJECT_LIST.projects[project_id].filename)
		while( all_project_filenames.has(result) || Settings.PROJECT_FILE_RESTRICTED_NAMES.has(result) ):
			result += Settings.NONE_UNIQUE_FILENAME_AUTO_POSTFIX
		return result
		
	func valid_unique_project_title_from(suggestion:String) -> String:
		var all_project_titles = []
		for project_id in _PROJECT_LIST.projects:
			all_project_titles.append(_PROJECT_LIST.projects[project_id].title)
		while( all_project_titles.has(suggestion) ):
			suggestion += Settings.NONE_UNIQUE_FILENAME_AUTO_POSTFIX
		return suggestion
	
	func register_project(project_title:String, project_filename:String, is_the_open_one:bool = false, is_local:bool = true) -> int:
		var new_seed_uid = create_new_project_id()
		_PROJECT_LIST.projects[new_seed_uid] = {
			"title": valid_unique_project_title_from(project_title),
			"filename": valid_unique_project_filename_from(project_filename),
			"local": is_local # reserved for possible vcs integration in the future
		}
		if is_the_open_one:
			_ACTIVE_PROJECT_UID = new_seed_uid
		save_project_list_file()
		return new_seed_uid
	
	func update_listed_title(project_uid:int = -1, new_project_title:String = "", save_list:bool = true) -> bool:
		var updated = false
		if project_uid < 0:
			project_uid = _ACTIVE_PROJECT_UID
		if is_project_listed(project_uid) && new_project_title.length() > 0:
			_PROJECT_LIST.projects[project_uid].title = valid_unique_project_title_from(new_project_title)
			updated = true
		if save_list == true:
			save_project_list_file()
		return updated
	
	func try_update_listed_description(project_uid:int = -1, project_data:Dictionary = {}, save_list:bool = true) -> bool:
		var updated = false
		if project_uid < 0:
			project_uid = _ACTIVE_PROJECT_UID
		if is_project_listed(project_uid) && project_data.has("entry"):
			var entry = project_data.entry
			var entry_node = project_data.resources.nodes[entry]
			if entry_node.has("notes"):
				var description = "%s" % entry_node.notes
				if (
					_PROJECT_LIST.projects[project_uid].has("description") == false ||
					_PROJECT_LIST.projects[project_uid].description != description
				):
					_PROJECT_LIST.projects[project_uid].description = description
					updated = true
		if save_list == true:
			save_project_list_file()
		return updated
	
	func unlist_project(project_uid:int, remove_file_too:bool = false):
		if project_uid != _ACTIVE_PROJECT_UID:
			if is_project_listed(project_uid):
				# remove file in case
				if remove_file_too == true:
					var path = get_project_file_path(project_uid, true)
					var removed = Helpers.Utils.remove_file(path)
					if removed == OK:
						print_debug("Alert! Project file removed: ", path)
					else:
						print_debug("Unexpected Behavior! Unable to remove project file! ", removed, " ", path)
				# unlist
				_PROJECT_LIST.projects.erase(project_uid)
				save_project_list_file()
				print_debug("Project unlisted: ", project_uid)
			else:
				printerr("Unexpected Behavior! Trying to unlist a none-listed project with id: ", project_uid)
		else:
			printerr("Disallowed Operation! You can't unlist currently active project.")
		pass
	
	func save_project_native_file(project_data:Dictionary, full_path:String, prefer_json = null):
		var done
		if prefer_json == true || ( prefer_json != false && Settings.USE_DEPRECATED_BIN_SAVE != true ) :
			done = Helpers.Utils.save_data_as_json_file(project_data, full_path, Settings.PROJECT_FILE_JSON_DEFAULT_IDENT, false)
		else:
			done = Helpers.Utils.save_data_as_variant_file(project_data, full_path)
		return done
	
	func save_project_into(project_uid:int, project_data:Dictionary, duplicate:bool = false, textual = null):
		if is_project_listed(project_uid):
			var full_project_file_path = get_project_file_path(project_uid)
			var ready_project_data = (project_data.duplicate(true) if duplicate else project_data)
			# shall we update our listing ?
			var is_title_updated:bool
			var is_description_updated:bool
			# if project title is changed during edit ...
			if ready_project_data.title != _PROJECT_LIST.projects[project_uid].title:
				is_title_updated = update_listed_title(project_uid, ready_project_data.title, false)
			# and ...
			is_description_updated = try_update_listed_description(project_uid, ready_project_data, false)
			# then ...
			if is_title_updated || is_description_updated:
				save_project_list_file()
			# Finally, we can save the project
			var done = save_project_native_file(ready_project_data, full_project_file_path, textual)
			return done
		else:
			printerr("Unexpected Behavior! Saving project to none-listed uid: ", project_uid)
			return ERR_CANT_ACQUIRE_RESOURCE
	
	func save_project(project_data:Dictionary, duplicate:bool = false, textual = null) -> void:
		# save current open project
		if _ACTIVE_PROJECT_UID >= 0:
			print_debug("Saving Project: ", _ACTIVE_PROJECT_UID, " : ", _PROJECT_LIST.projects[_ACTIVE_PROJECT_UID])
			var done = save_project_into(_ACTIVE_PROJECT_UID, project_data, duplicate, textual)
			if done == OK :
				_IS_ACTIVE_PROJECT_SAVED = true
			else:
				printerr("Saving Failed! Error: ", done)
			# ... and save list files to keep the last view records
			save_project_list_file()
		pass
	
	# Playable Exports
	
	func revise_play_ready(project: Dictionary) -> Dictionary:
		var duplicated_project = project.duplicate(true)
		if Settings.PURGE_DEVELOPMENT_DATA_FROM_PLAYABLE == true:
			if Settings.DATA_TO_BE_PURGED_FROM_PLAYABLE_METADATA is Array && project.has('meta'):
				for key in Settings.DATA_TO_BE_PURGED_FROM_PLAYABLE_METADATA:
					duplicated_project.meta.erase(key)
			if Settings.DATA_TO_BE_PURGED_FROM_PLAYABLE_RESOURCES is Dictionary && project.has('resources'):
				var datasets_to_apply_purge = Settings.DATA_TO_BE_PURGED_FROM_PLAYABLE_RESOURCES.keys()
				for dataset in datasets_to_apply_purge:
					if duplicated_project.resources.has(dataset):
						if Settings.DATA_TO_BE_PURGED_FROM_PLAYABLE_RESOURCES[dataset] is Array:
							for res in duplicated_project.resources[dataset]:
								for key in Settings.DATA_TO_BE_PURGED_FROM_PLAYABLE_RESOURCES[dataset]:
									duplicated_project.resources[dataset][res].erase(key);
		return duplicated_project
	
	func save_play_ready_json(full_export_file_path:String, project:Dictionary):
		var play_ready_project = revise_play_ready(project)
		var done = Helpers.Utils.save_data_as_json_file(
			play_ready_project, full_export_file_path, Settings.PROJECT_FILE_JSON_DEFAULT_IDENT, false
		)
		return done
	
	func print_play_ready(project: Dictionary) -> String:
		var play_ready = revise_play_ready(project)
		return JSON.stringify(play_ready, Settings.INLINED_JSON_DEFAULT_IDENT, false)
	
	func tag_replacements_from(project: Dictionary) -> Dictionary:
		return {
			'{{project_title}}':     project.title,
			'{/*project_json*/}':    print_play_ready(project),
			'{{project_last_save}}': Helpers.Utils.parse_time_stamp(project.meta.last_save, true, false),
			'{{arrow_website}}':     Settings.ARROW_WEBSITE,
			'{{arrow_version}}':     Settings.ARROW_VERSION
		}
	
	func is_html_js_runtime_modified() -> bool:
		var template_mod_time = Helpers.Utils.get_modification_time(Settings.HTML_JS_SINGLE_FILE_TEMPLATE_PATH)
		var source_index_mod_time = Helpers.Utils.get_modification_time(Settings.HTML_JS_RUNTIME_INDEX)
		var source_dir = Helpers.Utils.safe_base_dir(Settings.HTML_JS_RUNTIME_INDEX)
		print_debug("html-js source dir:", source_dir)
		if source_index_mod_time > template_mod_time:
			print_debug("Runtime index file modified: ", source_index_mod_time)
			return true
		var head_imports = Helpers.Utils.read_html_head_imports(Settings.HTML_JS_RUNTIME_INDEX)
		if head_imports is Dictionary:
			for css in head_imports.styles:
				var css_mod_time = Helpers.Utils.get_modification_time(source_dir + css.href)
				if css_mod_time > template_mod_time:
					print_debug("Style sheet file modified: ", css, " @ ", css_mod_time)
					return true
			for js in head_imports.scripts:
				var js_mod_time = Helpers.Utils.get_modification_time(source_dir + js.src)
				if js_mod_time > template_mod_time:
					print_debug("Script file modified: ", js, " @ ", js_mod_time)
					return true
		else:
			printerr("Failed to read html <head> imports from: ", Settings.HTML_JS_RUNTIME_INDEX)
		return false
	
	func prepare_html_js_template() -> void:
		var rebuild = (
			Helpers.Utils.file_exists(Settings.HTML_JS_SINGLE_FILE_TEMPLATE_PATH) == false ||
			( _MAIN._AUTO_REBUILD_RUNTIME_TEMPLATES && is_html_js_runtime_modified() )
		)
		if rebuild:
			var rebuilt_template = Helpers.Utils.inline_html_head_imports(Settings.HTML_JS_RUNTIME_INDEX)
			var stored = Helpers.Utils.write_text_file(Settings.HTML_JS_SINGLE_FILE_TEMPLATE_PATH, rebuilt_template)
			if stored == OK:
				print_debug("HTML-JS runtime is re-built: ", Settings.HTML_JS_SINGLE_FILE_TEMPLATE_PATH)
			else:
				printerr(
					"Failed to write (re-)built HTML-JS runtime template! We need RW access to `./runtimes` directory. ",
					stored, Settings.HTML_JS_SINGLE_FILE_TEMPLATE_PATH
				)
		pass

	func save_playable_html(full_export_file_path:String, project:Dictionary):
		# use official html-js runtime template to make playable html (single page) export
		prepare_html_js_template()
		return Helpers.Utils.save_from_template_file (
				Settings.HTML_JS_SINGLE_FILE_TEMPLATE_PATH,
				full_export_file_path,
				tag_replacements_from(project)
		)
	
	func parse_playable_html(project:Dictionary):
		prepare_html_js_template()
		return Helpers.Utils.parse_template(
				Settings.HTML_JS_SINGLE_FILE_TEMPLATE_PATH,
				tag_replacements_from(project)
		)
	
	# Other exports

	static func _sort_csv_by_key_ascending(a, b):
		return a[0].naturalnocasecmp_to(b[0]) < 0

	func recreate_csv_rows(project: Dictionary, try_update_existing_path: String = "", separator: String = Settings.CSV_EXPORT_SEPARATOR) -> Array: # ... of PackedStringArray lines
		var csv_columns_labels = []
		var mapping = {}
		# Read the existing csv file to update if any and remap
		if try_update_existing_path.length() > 0:
			var file = FileAccess.open(try_update_existing_path, FileAccess.READ)
			if file != null:
				var file_length = file.get_len()
				while file.get_position() < file_length:
					var line = file.get_csv_line(separator)
					if csv_columns_labels.size() == 0: # first line is expected to always include the table headings
						csv_columns_labels = line
					else: # other lines
						mapping[line[0]] = {}
						for c in range(0, csv_columns_labels.size()):
							mapping[line[0]][csv_columns_labels[c]] = line[c]
				file.close()
			else:
				print_debug("Warn! no such file existed to recreate CSV, *creating from scratch*")
		# If there was no previously made file, we use default columns
		if csv_columns_labels.size() < 2:
			csv_columns_labels = ["key", "original"] # Note also that we always expect that the first and second columns, no matter the label, to be the key and the original value
		# Now update the data mapping
		var keys_alive = [] # We also keep the keys that are met, to purge the dropped data from CSV file.
		for node_id in project.resources.nodes:
			var node = project.resources.nodes[node_id]
			var type_inspector = _MAIN.Mind.NODE_TYPES_LIST[node.type].inspector.instantiate()
			var parts_mapping =  type_inspector.map_i18n_data(node_id, node) if type_inspector.has_method("map_i18n_data") else {}
			for part_key in parts_mapping:
				keys_alive.push_back(part_key)
				if mapping.has(part_key) == false:
					mapping[part_key] = {}
				if (
					mapping[part_key].has(csv_columns_labels[1]) == false ||
					(
						mapping[part_key][csv_columns_labels[1]] != parts_mapping[part_key] &&
						# NOTE: purged form of the original value is considered unchanged as well
						mapping[part_key][csv_columns_labels[1]] != Helpers.Mood.purge(parts_mapping[part_key])
					)
				):
					mapping[part_key][csv_columns_labels[1]] = parts_mapping[part_key]
					for other in range(2, csv_columns_labels.size()):
						mapping[part_key][csv_columns_labels[other]] = ""
		# Recreate lines and sort them
		var csv = []
		for key in mapping:
			if keys_alive.has(key):
				var line = PackedStringArray()
				line.push_back(key)
				for i in range(1, csv_columns_labels.size()):
					line.push_back(mapping[key][csv_columns_labels[i]] if mapping[key].has(csv_columns_labels[i]) else "")
				csv.push_back(line)
		csv.sort_custom(ProjectManager._sort_csv_by_key_ascending)
		csv.push_front(csv_columns_labels)
		# ...
		return csv

	func parse_project_csv(project: Dictionary, try_update_existing_path: String = "", separator: String = Settings.CSV_EXPORT_SEPARATOR) -> String:
		var csv_rows = recreate_csv_rows(project, try_update_existing_path, separator)
		var processed_rows = []
		for row in csv_rows:
			var processed_columns = []
			for column in row:
				var processed = column.replace('"', '""')
				processed = processed if processed.find("\n") == -1 && processed.find(separator) == -1 && processed.find('""') == -1 else "\"" + processed + "\""
				processed_columns.push_back(processed)
			processed_rows.push_back(separator.join(processed_columns))
		return "\n".join(processed_rows) + "\n"
	
	func save_project_csv(full_export_file_path:String, project:Dictionary, separator: String = Settings.CSV_EXPORT_SEPARATOR):
		var csv_doc = parse_project_csv(project, full_export_file_path, separator)
		var file = FileAccess.open(full_export_file_path, FileAccess.WRITE)
		if file != null:
			file.store_string(csv_doc)
			file.close()
			return OK
		else:
			return file.get_error()
