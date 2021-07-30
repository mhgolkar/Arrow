# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Project Management
class_name ProjectManagement

const PROJECT_LIST_FILE_NAME = Settings.PROJECT_LIST_FILE_NAME

class ProjectManager :
	
	var Utils = Helpers.Utils
	var Generators = Helpers.Generators
	var PROJECT_FILE_EXTENSION_WITHOUT_DOT = Settings.PROJECT_FILE_EXTENSION.replacen(".", "")
	
	var _ALDP # app local/work directory path (ends with `/`)
	var _PROJECT_LIST # by UIDs (check out `Embedded::Data::Blank_Project_List`)
	
	var _ACTIVE_PROJECT_UID:int = -1
	var _IS_ACTIVE_PROJECT_SAVED:bool = false

	func _init(current_app_local_dir:String) -> void:
		hold_local_app_dir(current_app_local_dir)
		pass
	
	func hold_local_app_dir(app_local_dir:String) -> void:
		_ALDP = Utils.normalize_dir_path(app_local_dir)
		print_debug("Project Manager Holding Local App Directory: ", _ALDP)
		# check _ALDP for access
		if Utils.is_access_granted_to_dir(_ALDP, File.WRITE_READ):
			# ... and neccessary files (discover or create)
			_PROJECT_LIST = read_project_list_file(true)
		else:
			printerr("ACCESS FAILED! RW Permission to Local App/Work Directory is NOT GRANTED!")
		pass
	
	func validate_project_list_data(content):
		# TODO: `arrow_editor_version` compatibility checks and updates in case
		if content is Dictionary:
			var expected_keys = Embedded.Data.Blank_Project_List.keys()
			if content.has_all(expected_keys):
				return content
		return null
	
	# discovers or creates Projects list file
	func read_project_list_file(force_creation:bool = false):
		var project_list = null
		var project_list_file_path = _ALDP + PROJECT_LIST_FILE_NAME
		var file = File.new()
		if file.file_exists( project_list_file_path ):
			file.open(project_list_file_path, File.READ)
			var file_content = file.get_var(true)
			var validated_project_list = validate_project_list_data(file_content)
			if validated_project_list != null:
				project_list = validated_project_list
			else:
				printerr("Invalid Project List File! ", project_list_file_path)
			file.close()
		else:
			project_list = Embedded.Data.Blank_Project_List.duplicate(true)
			if force_creation == true:
				if file.open(project_list_file_path, File.WRITE_READ) == OK:
					file.store_var(project_list)
					file.close()
					print_debug("New project list file created. ", project_list_file_path)
				else:
					printerr("No Project List File Exists and we CAN NOT CREATE one!", _ALDP)
			else:
				printerr("No Project List File Exists! ", _ALDP)
				printerr("... A blank one will be used temporarily.")
		return project_list
	
	func save_project_list_file() -> void:
		var project_list_file_path = _ALDP + PROJECT_LIST_FILE_NAME
		var file = File.new()
		if file.open(project_list_file_path, File.WRITE_READ) == OK:
			file.store_var(_PROJECT_LIST)
			file.close()
		else:
			printerr("Unexpected Behavior! Can not open project list file to save new data in it! ", project_list_file_path)
		pass
	
	func get_projects_listed_by_id() -> Dictionary:
		return _PROJECT_LIST.projects
		
	func get_active_project_id() -> int:
		return _ACTIVE_PROJECT_UID
	
	func hold_untitled_project() -> Dictionary:
		_ACTIVE_PROJECT_UID = -1
		_IS_ACTIVE_PROJECT_SAVED = true
		var untitled_project = Embedded.Data.Untitled_Project.duplicate(true)
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
			if Utils.file_is_accessible(project_file_path):
				return true
			else:
				printerr("Project File Inaccessible! Either project list file is corrupted or state of the project file (existance, RW permission) is changed! Inspect this path: ", project_file_path)
		else:
			printerr("Unexpected Behavior! Trying to check existance of none-listed project = %s !" % project_file_path)
		return false
	
	const PROJECT_DATA_MANDATORY_FIELDS = [ "title", "entry", "meta", "next_resource_seed", "resources" ]
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
						(project.next_resource_seed is int) && project.next_resource_seed >= 0 &&
						(project.entry is int) && project.resources.nodes.has(project.entry)
					):
						for set in project.resources:
							for uid in project.resources[set]:
								if (
									((uid is int) != true) ||
									((project.resources[set][uid] is Dictionary) != true) ||
									(project.resources[set][uid].has_all( DATASET_ITEM_MANDATORY_FIELDS_FOR_SET[set] ) != true)
								):
									# doesn't pass general dataset checks
									return false
								else:
									# passes? what about dataset special checks?
									match set:
										"scenes":
											for map_uid in project.resources[set][uid].map:
												if (
													((map_uid is int) != true) ||
													((project.resources[set][uid].map[map_uid] is Dictionary) != true) ||
													(
														# offset is mandatory
														project.resources[set][uid].map[map_uid].has("offset") != true ||
														(project.resources[set][uid].map[map_uid].offset is Array) != true ||
														project.resources[set][uid].map[map_uid].offset.size() != 2 # [x, y]
													)
												):
													return false
										"nodes":
											if (project.resources[set][uid].data is Dictionary) != true:
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
	func refactore_parsed_json_project_data(data:Dictionary) -> Dictionary:
		var refactoring = Utils.recursively_convert_numbers_to_int(data)
		# print_debug("Refactored JSON project: ", refactoring)
		return refactoring
	
	func read_project_file_data(project_uid_or_file_path, try_json = null):
		# get the full path to the project file
		var full_project_file_path:String
		if project_uid_or_file_path is int:
			full_project_file_path = get_project_file_path(project_uid_or_file_path)
		elif Utils.is_abs_or_rel_path(project_uid_or_file_path):
			full_project_file_path = project_uid_or_file_path
		else:
			printerr("Unexpected Behavior! function `read_project_file_data` called with wrong argument: ", project_uid_or_file_path)
			return null
		# and try to read the project out of it
		if is_project_file_accessible(full_project_file_path):
			var project_file_data = null
			var parsed_project_file_data = null
			if Settings.USE_JSON_FOR_PROJECT_FILES != false || try_json == true:
				parsed_project_file_data = Utils.read_and_parse_json_file(full_project_file_path)
			if parsed_project_file_data is Dictionary:
				project_file_data = refactore_parsed_json_project_data(parsed_project_file_data)
			else :
				project_file_data = Utils.read_and_parse_variant_file(full_project_file_path)
			# validate the project file
			if project_file_data is Dictionary:
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
	
	func set_project_last_view_offset(offset = [0, 0], scene_uid:int = 0, project_uid:int = -1) -> void:
		if (offset is Vector2):
			offset = Utils.vector2_to_array(offset)
		if (offset is Array) && (offset.size() == 2) && (offset[0] is float || offset[0] is int) && (offset[1] is float || offset[1] is int):
			project_uid = valid_project_uid_or_default(project_uid)
			if is_project_listed(project_uid) && (scene_uid >= 0) :
				if _PROJECT_LIST.projects[project_uid].has("last_view_offset") == false:
					_PROJECT_LIST.projects[project_uid].last_view_offset = {}
				_PROJECT_LIST.projects[project_uid].last_view_offset[scene_uid] = offset
		else:
			printerr("Unexpected Behavior! Invalid Offset to set_project_last_view_offset: ", offset)
		pass
	
	func get_project_last_view_offset(project_uid:int = -1, scene_uid:int = 0) -> Array:
		project_uid = valid_project_uid_or_default(project_uid)
		if is_project_listed(project_uid) && (scene_uid >= 0) :
			if _PROJECT_LIST.projects[project_uid].has("last_view_offset"):
				if _PROJECT_LIST.projects[project_uid].last_view_offset.has(scene_uid):
					return _PROJECT_LIST.projects[project_uid].last_view_offset[scene_uid]
		return [0, 0]
		
	func create_new_project_id() -> int:
		var the_new_seed_uid = _PROJECT_LIST.next_project_seed
		_PROJECT_LIST.next_project_seed += 1
		return the_new_seed_uid
	
	func valid_unique_project_filename_from(suggestion:String) -> String:
		# we don't want our extension in the file name
		suggestion = suggestion.replacen(PROJECT_FILE_EXTENSION_WITHOUT_DOT, "")
		# and though it might be valid, let's avoid dots too
		suggestion = suggestion.replacen(".", "_")
		if suggestion.length() == 0 || suggestion == "_":
			# blank suggestion?! let's suggest a random one
			suggestion = (
				Settings.RANDOM_PROJECT_NAME_PREFIX +
				Generators.create_random_string( Settings.RANDOM_PROJECT_NAME_AFFIX_LENGTH )
			)
		var result = Utils.valid_filename(suggestion, false)
		var all_project_filenames = []
		for project_id in _PROJECT_LIST.projects:
			all_project_filenames.append(_PROJECT_LIST.projects[project_id].filename)
		while( all_project_filenames.has(result) ):
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
				var description = String(entry_node.notes)
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
					var removed = Utils.remove_file(path)
					if removed == OK:
						print_debug("Alert! Project file removed: ", path)
					else:
						print_debug("Unexpected Behavior! Unable to remove project file! ", removed, " ", path)
				# unlist
				_PROJECT_LIST.projects.erase(project_uid)
				save_project_list_file()
				print_debug("Project unlisted: ", project_uid)
			else:
				printerr("Unexbected Behavior! Trying to unlist a none-listed project with id: ", project_uid)
		else:
			printerr("Disallowed Operation! You can't unlist currently active project.")
		pass
	
	func save_project_native_file(project_data:Dictionary, full_path:String, prefer_json = null):
		var done
		if prefer_json == true || ( prefer_json != false && Settings.USE_JSON_FOR_PROJECT_FILES != false ) :
			done = Utils.save_data_as_json_file(project_data, full_path, Settings.PROJECT_FILE_JSON_DEFAULT_IDENT, false)
		else:
			done = Utils.save_data_as_variant_file(project_data, full_path)
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
	
	func print_play_ready_project(project: Dictionary) -> String:
		if Settings.PURGE_DEVELOPMENT_DATA_FROM_PLAYABLES == true:
			var duplicated_project = project.duplicate(true)
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
			return JSON.print(duplicated_project)
		else:
			return JSON.print(project)
		pass
	
	func export_playable_html(full_export_file_path:String, project:Dictionary):
		# use official html-js runtime template to make playable html (single page) export
		return Utils.create_from_template_file (
				Settings.HTML_JS_SINGLE_FILE_TEMPLATE_PATH,
				full_export_file_path,
				{
					'{{project_title}}':     project.title,
					'{{project_json}}':      print_play_ready_project(project),
					'{{project_last_save}}': Utils.parse_time_stamp_dict(project.meta.last_save.utc, true),
					'{{arrow_website}}':     Settings.ARROW_WEBSITE,
					'{{arrow_version}}':     Settings.ARROW_VERSION
				}
		)
		pass
