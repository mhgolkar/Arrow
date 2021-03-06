# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Node Type Handler
# (detecting and loading default and custom node types that exist as modules in `res://nodes`)
class_name NodeTypes

const NODES_RES_DIR = Settings.NODES_RES_DIR
const NODE_TYPE_NODE_FILE_NAME = Settings.NODE_TYPE_NODE_FILE_NAME
const NODE_TYPE_INSPECTOR_FILE_NAME = Settings.NODE_TYPE_INSPECTOR_FILE_NAME
const NODE_TYPE_CONSOLE_FILE_NAME = Settings.NODE_TYPE_CONSOLE_FILE_NAME


class NodeTypesHandler :
	
	var Main
	var _NODES_RES_DIR = null
	var _CACHED_NODE_TYPES = {}
	
	var Utils = Helpers.Utils
	
	func _init(main) -> void:
		Main = main
		pass
	
	# do checks for existance and validity of files then load resources and pass them
	func parse_node_type_folder(node_type_dir_name: String):
		var dir_path = Utils.normalize_dir_path(_NODES_RES_DIR + node_type_dir_name)
		var dir = Directory.new()
		var the_node_path = (dir_path + NODE_TYPE_NODE_FILE_NAME)
		var the_inspector_path = (dir_path + NODE_TYPE_INSPECTOR_FILE_NAME)
		var the_console_path = (dir_path + NODE_TYPE_CONSOLE_FILE_NAME)
		if dir.file_exists(the_node_path) && dir.file_exists(the_inspector_path):
			var the_node = load(the_node_path)
			var the_inspector = load(the_inspector_path)
			var the_console = load(the_console_path)
			return {
				"type": node_type_dir_name,
				"text": node_type_dir_name.capitalize(),
				"node": the_node,
				"inspector": the_inspector,
				"console": the_console,
				"icon": null, # TODO: visual enhancement
			}
		else:
			return null
	
	# discover, load nodes from `res://nodes` and cache them
	func load_node_types():
		if _CACHED_NODE_TYPES.size() == 0:
			if _NODES_RES_DIR == null:
				_NODES_RES_DIR = Utils.normalize_dir_path(NODES_RES_DIR)
				var nodes_dir = Directory.new()
				if nodes_dir.open(_NODES_RES_DIR) == OK:
					nodes_dir.list_dir_begin(true, true)
					var current = nodes_dir.get_next()
					while current != "":
						if nodes_dir.current_is_dir():
							var possible_node_type = parse_node_type_folder( current )
							if possible_node_type != null:
								_CACHED_NODE_TYPES[ possible_node_type.type ] = possible_node_type
						current = nodes_dir.get_next()
				else:
					printerr("An error occurred when trying to access the path: ", _NODES_RES_DIR)
					Main.call("quit_app", ERR_FILE_CANT_READ)
		return _CACHED_NODE_TYPES
	
