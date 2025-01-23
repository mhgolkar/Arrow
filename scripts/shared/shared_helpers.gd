# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Shared helper classes
class_name Helpers

# Utilities 
class Utils:
	
	# Making sure the dir path ends with "/"
	# ... also strips edges
	static func normalize_dir_path(dir_path:String) -> String:
		dir_path = dir_path.strip_edges(true, true)
		if dir_path.ends_with("/") == false:
			dir_path = dir_path + "/"
		return dir_path
		
	# Getting base directory from a path
	# Note: types are NOT annotated (dir:String -> String) because some functions may give it a `null` and/or expect a null in cases.
	static func safe_base_dir(dir) :
		if dir is String :
			if DirAccess.dir_exists_absolute(dir):
				dir = normalize_dir_path(dir)
			else:
				dir = dir.get_base_dir()
				if dir.length() == 0:
					return null
				else:
					dir = normalize_dir_path(dir)
			return dir
		else:
			return null
	
	static func is_abs_or_rel_path(path) -> bool:
		if path is String:
			return ( path.is_absolute_path() || path.is_relative_path() )
		return false
	
	# This function finds absolute path to `res://`
	# by fetching base directory of an absolute path to a file that we sure is always there!
	static func get_absolute_path_to_res_dir(normalize:bool) -> String:
		var the_file = FileAccess.open(Settings.EVER_THERE_RES_FILE, FileAccess.READ)
		var res_abs_dir = the_file.get_path_absolute().get_base_dir()
		the_file.close()
		if normalize != false:
			res_abs_dir = normalize_dir_path(res_abs_dir)
		return res_abs_dir
	
	static func try_making_clean_relative_dir(path:String, normalize:bool = true):
		var abs_res_dir  = get_absolute_path_to_res_dir(false)
		var abs_user_dir = OS.get_user_data_dir()
		if path.begins_with(abs_user_dir):
			path = path.replace(abs_user_dir, "user://")
		elif path.begins_with(abs_res_dir):
			path = path.replace(abs_res_dir, "res://")
		if normalize != false:
			path = normalize_dir_path(path)
		path = path.replace("///", "//")
		return path
	
	static func get_abs_path(path:String) -> String:
		var absolute_path = path
		if path.begins_with('user://'):
			absolute_path = path.replace(
				'user://',
				normalize_dir_path( OS.get_user_data_dir() )
			)
		elif path.begins_with('res://'):
			absolute_path = path.replace(
				'res://',
				get_absolute_path_to_res_dir(true)
			)
		else:
			var dir = DirAccess.open(path)
			if dir != null:
				absolute_path = normalize_dir_path( dir.get_current_dir() )
		return absolute_path
	
	static func is_access_granted_to_dir(path:String, access_type = FileAccess.WRITE_READ) -> bool:
		var base = safe_base_dir(path)
		if base is String:
			var temp_file_path = base + 'wr_access_check.temp'
			var dir = DirAccess.open(base)
			if dir != null:
				var temp_file = FileAccess.open(temp_file_path, access_type)
				if temp_file != null:
					temp_file.close()
					dir.remove(temp_file_path)
					return true
				else:
					return false
			else:
				return false
		else:
			printerr("Unexpected Behavior! Trying check [mode-", access_type, "] access permission to invalid path: ", path)
			return false
	
	static func file_exists(path: String) -> bool:
		return FileAccess.file_exists(path)
	
	# Caution!
	# using File.Write or File.WRITE_READ will truncate the file or (re-)create it,
	# so be careful about the parameter `mode`
	static func file_is_accessible(path:String, mode = FileAccess.READ_WRITE) -> bool:
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, mode)
			if file != null:
				file.close()
				return true
		return false
	
	static func parse_json(text: String):
		# var json = JSON.new()
		# var parsed = json.parse(text)
		# if parsed == OK:
		# 	return json.data
		# return null
		## Alternatively, because we return null on error anyway, we can use the new GD4 API:
		return JSON.parse_string(text)
	
	static func read_and_parse_json_file(path:String):
		var file = FileAccess.open(path, FileAccess.READ)
		if file != null:
			var json_string = file.get_as_text()
			file.close()
			var parsed_or_null = parse_json(json_string)
			return parsed_or_null
		return null

	static func stringify_json(data, indent:String = Settings.PROJECT_FILE_JSON_DEFAULT_IDENT, sort_keys:bool = false, full_precision:bool = false) -> String:
		return JSON.stringify(data, indent, sort_keys, full_precision)
	
	static func save_data_as_json_file(data, path:String, indent:String = "", sort_keys:bool = false, full_precision:bool = false):
		var data_stringified = JSON.stringify(data, indent, sort_keys, full_precision)
		if data_stringified is String:
			var file = FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_string(data_stringified)
				file.close()
				return OK
			else:
				return file
		else:
			print_stack()
			print_debug("Trying to save data as json: ", data)
			return "JSON.print result is not String!!"
	
	static func is_a_file_path(path) -> bool:
		if is_abs_or_rel_path(path):
			var file_name = path.get_file()
			if (file_name is String) && file_name.length() > 0 :
				return true
		return false
	
	static func save_from_template_file(template_path:String, save_path:String, replacements:Dictionary = {}):
		if is_a_file_path(template_path) && is_a_file_path(save_path):
			var template_file = FileAccess.open(template_path, FileAccess.READ)
			if template_file != null:
				var new_file = FileAccess.open(save_path, FileAccess.WRITE)
				if new_file != null:
					# Copy the template line by line, replacing the tags
					var the_content_line:String
					while template_file.eof_reached() == false:
						the_content_line = template_file.get_line()
						for tag in replacements:
							the_content_line = the_content_line.replace( tag, replacements[tag] )
						new_file.store_line(the_content_line)
					# ...
					new_file.close()
					template_file.close()
					return OK
				else:
					return new_file.get_error()
			else:
				return template_file.get_error()
		else:
			return ERR_INVALID_PARAMETER
	
	static func parse_template(template_path:String, replacements:Dictionary = {}):
		if is_a_file_path(template_path):
			var template_file = FileAccess.open(template_path, FileAccess.READ)
			if template_file != null:
				var parsed: String = ""
				# Copy the template line by line, replacing the tags
				var the_content_line:String
				while template_file.eof_reached() == false:
					the_content_line = template_file.get_line()
					for tag in replacements:
						the_content_line = the_content_line.replace( tag, replacements[tag] )
					parsed = parsed + the_content_line + "\n"
					# (^ It's a line by line append, and `get_line` seems not to keep line-feed so we add it)
				# ...
				template_file.close()
				return parsed
			else:
				return template_file.get_error()
		else:
			return ERR_INVALID_PARAMETER
	
	static func read_text_extended(path: String, strip_comment_lines: StringName = "", return_joined: bool = true):
		var file = FileAccess.open(path, FileAccess.READ)
		if file != null:
			var content = []
			while file.eof_reached() == false:
				var line = file.get_line()
				if strip_comment_lines == "" || false == line.begins_with(strip_comment_lines):
					content.push_back(line)
			file.close()
			if return_joined:
				return "\n".join(content)
			else:
				return content
		return null
	
	static func read_text_file(path: String):
		var file = FileAccess.open(path, FileAccess.READ)
		if file != null:
			var content = file.get_as_text()
			file.close()
			return content
		return null
	
	# Returns OK if write is done or File Error
	static func write_text_file(path: String, content: String):
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(content)
			file.close()
			return OK
		else:
			return file.get_error()
	
	# Returns last modification time of a file, 0 for non-existent and -1 for error
	static func get_modification_time(path: String) -> int:
		var mod_time = FileAccess.get_modified_time(path)
		return (mod_time if mod_time is int && mod_time > 0 else -1)

	const SCRIPT_REGEX = r"<script[a-z1-9\"'\/ =]*?src=['|\"](.*?)[\"|'][a-z1-9\"'\/ =]*?>.*</script>"
	const STYLE_REGEX =  r"<link[a-z1-9\"'\/ =]*?href=['|\"](.*?)[\"|'][a-z1-9\"'\/ =]*?>"
	static func read_html_head_imports(
		path: String, return_source: bool = false,
		start_mark: String = "@inline", end_mark: String = "@inline-end"
	):
		var file = FileAccess.open(path, FileAccess.READ)
		if file != null:
			var source = file.get_as_text()
			file.close()
			var imports = { "styles": [], "scripts": [] }
			var lookup_start = source.find(start_mark)
			var lookup_end = source.find(end_mark)
			# Scripts
			var scripts_regex = RegEx.new()
			scripts_regex.compile(SCRIPT_REGEX)
			var scripts = scripts_regex.search_all(source, lookup_start, lookup_end)
			for scripts_regex_match in scripts:
				imports.scripts.append({
					"block": scripts_regex_match.get_string(0),
					"src": scripts_regex_match.get_string(1)
				})
			# Style sheets
			var styles_regex = RegEx.new()
			styles_regex.compile(STYLE_REGEX)
			var styles = styles_regex.search_all(source, lookup_start, lookup_end)
			for styles_regex_match in styles:
				imports.styles.append({
					"block": styles_regex_match.get_string(0),
					"href": styles_regex_match.get_string(1)
				})
			# ...
			if return_source:
				imports["source"] = source
			return imports
		return null

	static func inline_html_head_imports(index_path: String) -> String:
		var source_dir = Utils.safe_base_dir(Settings.HTML_JS_RUNTIME_INDEX)
		print_debug("inlining index file in source dir:", source_dir)
		var head_imports = read_html_head_imports(index_path, true)
		var index_source: String;
		if head_imports is Dictionary:
			index_source = head_imports.source
			for css in head_imports.styles:
				var css_content = read_text_file(source_dir + css.href)
				if css_content is String:
					index_source = index_source.replace(
						css.block,
						("<style>\n/*" + css.href + "*/\n\n" + css_content + "\n</style>")
					)
			for js in head_imports.scripts:
				var js_content = read_text_file(source_dir + js.src)
				if js_content is String:
					index_source = index_source.replace(
						js.block,
						("<script>\n/*" + js.src + "*/\n\n" + js_content + "\n</script>")
					)
		return index_source
	
	static func read_and_parse_variant_file(path:String):
		var file = FileAccess.open(path, FileAccess.READ)
		if file != null:
			var variant = file.get_var(true)
			file.close()
			return variant
		return null
	
	static func save_data_as_variant_file(data, path:String):
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_var(data, true)
			file.close()
			return OK
		else:
			return file.get_error()
	
	static func remove_file(path:String, move_to_trash:bool = true):
		return (
			OS.move_to_trash(ProjectSettings.globalize_path(path)) if move_to_trash
			else DirAccess.remove_absolute(path)
		)
	
	static func parse_time_stamp(
		time_stamp, mark_utc:bool = false, convert_to_local_time: bool = false, custom_template:String = ""
	):
		var time = time_stamp.utc if time_stamp is Dictionary && time_stamp.has("utc") else time_stamp # (backward compatibility)
		var time_dictionary: Dictionary
		if time is Dictionary:
			time_dictionary = time
		elif time is String:
			time_dictionary = Time.get_datetime_dict_from_datetime_string(time, true)
		elif time is int || time is float:
			time_dictionary = Time.get_datetime_dict_from_unix_time( int(time) )
		else:
			printerr("Unsupported time stamp format to parse! ", time)
		# ...
		if convert_to_local_time:
			var unix_time = Time.get_unix_time_from_datetime_dict(time_dictionary) # (seconds)
			var local_offset = Time.get_time_zone_from_system().bias * 60 # (bias is in minutes)
			var local_unix_time = unix_time + local_offset
			time_dictionary = Time.get_datetime_dict_from_unix_time(local_unix_time)
		# ...
		var template = (custom_template if (custom_template.length() > 0) else Settings.TIME_STAMP_TEMPLATE)
		var parsed_time_stamp = template.format(time_dictionary)
		if mark_utc:
			parsed_time_stamp += Settings.TIME_STAMP_TEMPLATE_UTC_MARK
		return parsed_time_stamp
	
	#  [x, y] -> Vector2(x: float, y: float)
	static func array_to_vector2(from:Array):
		if from.size() >= 2:
			if (from[0] is int || from[0] is float) && (from[1] is int || from[1] is float):
				return Vector2( from[0], from[1] )
			else:
				print_stack()
				printerr("Trying to convert none-numeral Array to Vector2 ! ", from)
		else:
			print_stack()
			printerr("Trying to convert Array with size < 2 to Vector2 ! ", from)
		return null
	
	# Vector2(x: float, y: float) -> [x, y]
	static func vector2_to_array(from:Vector2) -> Array:
		return [from.x, from.y]
	
	static func refactor_array(left: Array, factor: float, divide: bool = false) -> Array:
		var right = []
		for num in left:
			right.append( (num * factor) if divide == false else (num / factor) )
		return right

	static func int_to_base36(val:int = 0) -> String:
		var base36 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		var result = ""
		if val == 0:
			result = "0"
		else:
			while (val > 0):
				result = base36[val % 36] + result
				@warning_ignore("INTEGER_DIVISION")
				val = val / 36
		return result
	
	static func color_to_rgba_hex(from: Color, with_alpha: bool = true) -> String:
		return from.to_html(with_alpha)
	
	static func rgba_hex_to_color(from: String) -> Color:
		return Color.html(from)

	static func objects_differ(left, right) -> bool:
		if typeof(left) == typeof(right):
			if left is Dictionary:
				# `hash` is expected to be faster
				# and most of the times this function is called with identical objects so:
				if left.hash() == right.hash():
					return false
				# yet dictionaries with the same keys/values but in a different order will have a different hash.
				# we don't care about their order in this comparison, so we shall double-check
				else:
					if left.size() == right.size():
						for property in left:
							if right.has(property):
								if objects_differ(left[property], right[property]) == true:
									return true
							else:
								return true
						return false
					else:
						return true
			elif left is Array:
				if left.hash() == right.hash():
					return false
				# though we care about order in Arrays, but arrays may contain dictionaries
				# so we need to recursively check for items all
				else:
					if left.size() == right.size():
						for i in range(0, left.size()):
							if objects_differ(left[i], right[i]) == true:
								return true
						return false
					return true
			else:
				return (! (left == right) )
		else:
			return true
	
	static func recursively_update_dictionary(original:Dictionary, modification:Dictionary, ignore_new_and_strange_pairs:bool = true, updates_to_null_is_erase:bool = false, duplication:bool = false) -> Dictionary:
		var updating = ( original if (duplication != true) else original.duplicate(true) )
		for key in modification:
			# update if the pairs are of the same type ...
			if updating.has(key) && (typeof(updating[key]) == typeof(modification[key])):
				if updating[key] is Dictionary:
					# it doesn't need to duplicate original part again, because it's already a deep clone if duplication=true
					updating[key] = recursively_update_dictionary(updating[key], modification[key], ignore_new_and_strange_pairs, updates_to_null_is_erase, false)
				else:
					updating[key] = modification[key]
			# otherwise don't update unless ...
			elif modification[key] == null && updates_to_null_is_erase == true:
				updating.erase(key)
			elif ignore_new_and_strange_pairs == false:
				updating[key] = modification[key]
		return updating
	
	static func recursively_convert_numbers_to_int(data):
		if data is float:
			data = int(data)
		# stringified numbers in data may be a number-only title or str value, so let's keep them
		#elif data is String && String.num_int64(int(data)) == data:
		#	data = int(data)
		elif data is Array:
			for index in range(0, data.size()):
				data[index] = recursively_convert_numbers_to_int( data[index] )
		elif data is Dictionary:
			var data_with_converted_keys = {}
			for key in data:
				# well, the key itself might also be a stringified int
				if String.num_int64( int(key) ) == key:
					var key_int = int(key)
					var value = ( data[key].duplicate(true) if (data[key] is Dictionary || data[key] is Array) else data[key] )
					data_with_converted_keys[ key_int ]  = recursively_convert_numbers_to_int( value )
				else:
					data_with_converted_keys[key] = recursively_convert_numbers_to_int( data[key] )
			data = data_with_converted_keys
		return data
	
	static func valid_filename(from_string:String, replace_discouraged_characters:bool = true) -> String:
		var filename = from_string.to_lower().strip_edges().strip_escapes()
		var safe:String = ""
		if filename.is_valid_filename() == false || replace_discouraged_characters == true :
			for character in filename:
				if (
						character.is_valid_filename() == false ||
						(
							replace_discouraged_characters == true &&
							Settings.DISCOURAGED_FILENAME_CHARACTERS.has(character)
						)
				):
					safe += "_"
				else:
					safe += character
		else:
			safe = filename
		return safe
	
	static func ellipsis(text: String, length: int) -> String:
		return text.substr(0, length) + ("..." if text.length() > length else "")
	
	# Returns a version of the name that is safe to be used with recursive parsing (text formatting with dictionary)
	static func exposure_safe_resource_name(
		name: String,
		restricted = Settings.EXPOSURE_SAFE_NAME_RESTRICTED_CHARS,
		replacement = Settings.EXPOSURE_SAFE_NAME_RESTRICTED_CHARS_REPLACEMENT
	) -> String:
		for c in restricted:
			name = name.replace(c, replacement)
		return name
	
	static func recursively_replace_string(original, old: String, new: String, case_sensitive: bool = true):
		var revised
		if original is String:
			revised = original.replace(old, new) if case_sensitive else original.replacen(old, new)
		elif original is Array:
			revised = []
			for i in range(0, original.size()):
				revised.push_back( recursively_replace_string(original[i], old, new, case_sensitive) )
		elif original is Dictionary:
			revised = {}
			for key in original:
				revised[key] = recursively_replace_string(original[key], old, new, case_sensitive)
		else:
			revised = original
		return revised
	
	static func filter_pass(text: String, filter: String, reverse: bool = false, ci: bool = true) -> bool:
		filter = "*" + filter + "*"
		var passes = text.matchn(filter) if ci else text.match(filter)
		return ( passes if reverse == false else (! passes ) )
	
	static func find_focal(node: Control):
		for c in range(node.get_child_count() -1, -1, -1):
			var child = node.get_child(c)
			if child is Control:
				if child.get_child_count() > 0:
					return find_focal(child)
				elif child.get_focus_mode() != Control.FocusMode.FOCUS_NONE:
					return child
		return node if node.get_focus_mode() != Control.FocusMode.FOCUS_NONE else null

# List Node Helpers
class ListHelpers:
	
	static func get_item_list_as_text_array(list:ItemList) -> Array:
		var lines = []
		for idx in range(0, list.get_item_count()):
			lines.push_back( list.get_item_text(idx) )
		return lines
	
	# isolates by index
	# -1   : enable all,
	# >= 0 : disable all but this one
	static func isolate_a_list_item(list:ItemList, item_index:int = -1) -> void:
		var enable_all = false
		if item_index < 0:
			enable_all = true
		for idx in range(0, list.get_item_count()):
			list.set_item_disabled(idx, true if (enable_all == false && idx != item_index) else false)
		pass
	
	static func get_list_item_idx_from_meta_data(list:ItemList, target_meta_data) -> int:
		for idx in range(0, list.get_item_count()):
			if target_meta_data == list.get_item_metadata(idx):
				return idx
		return -1

class Vector2d:
	
	static func limit_vector2_y(vec:Vector2, by:Vector2, limit_down:bool = true, limit_padding:float = 0) -> Vector2:
		var limited = vec
		var padded_y_limit = (by.y - limit_padding)
		if limited.y > padded_y_limit:
			limited.y = padded_y_limit
		elif limit_down && limited.y < limit_padding :
			limited.y = limit_padding
		return limited
		
	static func limit_vector2_x(vec:Vector2, by:Vector2, limit_down:bool = true, limit_padding:float = 0) -> Vector2:
		var limited = vec
		var padded_x_limit = (by.x - limit_padding)
		if limited.x > padded_x_limit:
			limited.x = padded_x_limit
		elif limit_down && limited.x < limit_padding :
			limited.x = limit_padding
		return limited
	
	static func limit_vector2(vec:Vector2, by:Vector2, limit_down:bool = true, limit_padding:Vector2 = Vector2.ZERO) -> Vector2:
		var limited = limit_vector2_y(vec, by, limit_down, limit_padding.y)
		limited = limit_vector2_x(limited, by, limit_down, limit_padding.x)
		return limited

# Draggable (Movable) Controls
class Draggable:
	
	var LIMIT_PADDING = Vector2(25, 50) # pixels
	
	var _DRAGGABLE:Node
	var _DRAG_POINT:Node
	var _VIEWPORT:Node
	var _COMPETE_FOR_PARENT_TOP_VIEW:bool = false
	var _PARENT:Node
	
	func _init(draggable:Node, drag_point:Node, compete_for_parent_top_layer:bool = true) -> void:
		_DRAGGABLE = draggable
		_DRAG_POINT = drag_point
		_VIEWPORT = _DRAGGABLE.get_viewport()
		if compete_for_parent_top_layer:
			_COMPETE_FOR_PARENT_TOP_VIEW = true
			_PARENT = _DRAGGABLE.get_parent()
		connect_drag()
		pass
		
	func connect_drag() -> void:
		_DRAG_POINT.gui_input.connect(self.drag_element)
		if _COMPETE_FOR_PARENT_TOP_VIEW && _DRAGGABLE.has_signal("visibility_changed"):
			_DRAGGABLE.visibility_changed.connect(self.steal_top, CONNECT_DEFERRED)
		pass
	
	func drag_element(event:InputEvent) -> void:
		if event is InputEventMouseMotion:
			if event.get_button_mask() == MouseButtonMask.MOUSE_BUTTON_MASK_LEFT:
				var rel_mouse_position = event.get_relative() # ... to its previous pos
				var current_draggable_position  = _DRAGGABLE.get_position()
				var the_viewport_size = _VIEWPORT.get_size()
				var new_draggable_position = (current_draggable_position + rel_mouse_position)
				new_draggable_position = Vector2d.limit_vector2(new_draggable_position, the_viewport_size, true, LIMIT_PADDING)
				_DRAGGABLE.set_position(new_draggable_position)
		if event is InputEventMouseButton:
			if event.is_pressed() && _COMPETE_FOR_PARENT_TOP_VIEW == true:
				steal_top()
		pass
	
	func steal_top() -> void:
		_PARENT.move_child(_DRAGGABLE, _PARENT.get_child_count())
		pass

# Resizable Controls
class Resizable:
	
	var LIMIT_PADDING = Vector2(25, 50) # pixels
	
	var _RESIZABLE:Node
	var _RESIZE_POINT:Node
	var _USE_REVERSE_MOUSE_Y:bool
	var _RESIZE_FROM_TOP:bool
	var _VIEWPORT:Node
	
	func _init(resizable:Node, resize_point:Node, use_reverse_mouse_y:bool = true, resize_from_top:bool = true) -> void:
		_RESIZABLE = resizable
		_RESIZE_POINT = resize_point
		_USE_REVERSE_MOUSE_Y = use_reverse_mouse_y
		_RESIZE_FROM_TOP = resize_from_top
		_VIEWPORT = _RESIZABLE.get_viewport()
		connect_resize()
		pass
		
	func connect_resize() -> void:
		_RESIZE_POINT.gui_input.connect(self.resize_element)
		pass
	
	func resize_element(event:InputEvent) -> void:
		if event is InputEventMouseMotion:
			if event.get_button_mask() == MouseButtonMask.MOUSE_BUTTON_MASK_LEFT:
				var rel_mouse_position = event.get_relative() # ... to its previous pos
				if _USE_REVERSE_MOUSE_Y:
					rel_mouse_position.y = (rel_mouse_position.y * ( -1 ))
				var current_resizable_size  = _RESIZABLE.get_size()
				var the_viewport_size = _VIEWPORT.get_size()
				var new_resizable_size = (current_resizable_size + rel_mouse_position)
				new_resizable_size = Vector2d.limit_vector2(new_resizable_size, the_viewport_size, true, LIMIT_PADDING)
				_RESIZABLE.set_size(new_resizable_size)
				if _USE_REVERSE_MOUSE_Y && _RESIZE_FROM_TOP:
					var current_resizable_position  = _RESIZABLE.get_position()
					current_resizable_position.y = current_resizable_position.y - rel_mouse_position.y
					_RESIZABLE.set_position(current_resizable_position)
		pass

# Generator helpers
# ... to make random variants
class Generators:
	
	## This method is opinionated, trying to make acceptable colors for Characters or node types such as Marker and Frame.
	## NOTE: Negative `alpha` means to use a random value, and the values higher than 1 will be capped.
	static func create_random_color(alpha: float = 1.0) -> Color:
		var the_color:Color = Color.from_hsv(
			randf_range(0.0, 1.0), # hue
			randf_range(0.7, 1.0), # saturation
			randf_range(0.8, 1.0), # velocity
			min(alpha, 1.0) if alpha >= 0 else randf_range(0.5, 1.0) # alpha
		)
		return the_color

	static func create_random_string(length:int = 1, or_longer:bool = false, restriction_regex_pattern:String = "") -> String:
		var random_string = ""
		var restriction_regex = null
		if restriction_regex_pattern.length() > 0:
			restriction_regex = RegEx.new()
			restriction_regex.compile(restriction_regex_pattern)
		while random_string.length() < length:
			var new_substring = Utils.int_to_base36( randi() ).to_lower()
			if restriction_regex != null:
				new_substring = restriction_regex.sub(new_substring, "", true)
			random_string += new_substring
		if random_string.length() > length && or_longer == false:
			random_string = random_string.substr(0, length)
		return random_string
	
	static func random_boolean() -> bool:
		return ( randi() % 2 == 0 )
	
	static func advance_random_integer(
		from:int = 0, to:int = 0,
		negative:bool = false, even:bool = false, odd:bool = false
	) -> int:
		var result = null
		if from >= to:
			result = from
		if (to - from) <= 1:
			# we need at least one odd and one even number in the possibilities
			to += 1
		while result == null:
			result = randi_range(from, to)
			if even != odd : # to be either odd or even
				# (both true or both false means ignore)
				var is_even = (result % 2 == 0)
				if is_even && even == false:
					result = null
				if is_even == false && odd == false:
					result = null
		if negative is bool && negative == true: # negative
			result = (result * (-1))
		print_debug("random: ", from, to, negative, even, odd, " -- result --> ", result)
		return result
	
class Mood:
	
	var snippet: String = ""
	var purged: String
	
	var kind: String = ""
	var level: int = 0
	var reset: bool = true
	
	# Moods are tags added at the beginning of a content mostly as machine readable metadata.
	# This patterns helps extracting mood snippets like [code]Happy,2,true[/code] (inside brackets) (i.e. mood-kind, level, auto-reset)
	# from beginning of a string. We should ignore similar snippets if they are not at the beginning.
	const _REGEX_MOOD_SNIPPET_PATTERN := "^\\s*\\[([a-zA-z \\-_]*)?\\s*,?\\s*(\\-?\\+?[0-9]*)?\\s*,?\\s*(false|keep|~|true|reset)?\\]\\s*"
	
	# This method tries to default for each mood segment (even for empty array) to `["", 0, true]`.
	# It also returns an object with blank snippet and default parameters if no mood is there.
	# This method accepts the sign `~` and "keep" as alternatives for `false` reset value, and every thing else for `true`.
	# For example, `[Excited,~]` is equal to `[Excited,false]`.
	func _init(from: String):
		var regex = RegEx.new()
		var compiled = regex.compile(_REGEX_MOOD_SNIPPET_PATTERN)
		self.purged = from
		if compiled == OK:
			var matched = regex.search(from)
			if matched != null:
				self.snippet = matched.get_string(0)
				self.purged = from.replace(matched.get_string(0), "")
				self.kind = matched.get_string(1).strip_edges()
				self.level = int(matched.get_string(2).strip_edges())
				self.reset = false if ["false", "keep", "~"].has(matched.get_string(3).strip_edges().to_lower()) else true
		else:
			printerr("Unexpectedly unable to compile the Mood._REGEX_MOOD_SNIPPET_PATTERN to extract moods")

	static func purge(from: String) -> String:
		var regex = RegEx.new()
		var compiled = regex.compile(_REGEX_MOOD_SNIPPET_PATTERN)
		if compiled == OK:
			var matched = regex.search(from)
			if matched != null:
				return from.replace(matched.get_string(0), "")
		return from
