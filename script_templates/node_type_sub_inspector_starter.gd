# Arrow
# Game Narrative Design Tool
# % contributor(s) %

# % Custom % Node Type Inspector
extends %BASE%

# reference to `Main` (root)
onready var Main = get_tree().get_root().get_child(0)

const DEFAULT_NODE_DATA = {}

# the opened node resource-uid and data
var _OPEN_NODE_ID
var _OPEN_NODE

# the sub-inspector itself
var This = self

# children
# onready var INSPECTOR_CHILD_X = get_node("./X")

# called when the node enters the scene tree for the first time
func _ready() -> void:
	register_connections()
	pass

func register_connections()%VOID_RETURN%:
	# e.g. INSPECTOR_CHILD_X.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
	pass

# this function updates node parameters/resource-data in the sub-inspector view
func _update_parameters(node_id:int, node:Dictionary)%VOID_RETURN%:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	# ... then update parameters
	# TODO ...
	if node.has("data") && node.data is Dictionary:
		print(node_id, ": ", node.data)
	pass

# reads and returns modifications or a full set of parameters
# which has the same structure as the resource `data` for the node type 
func _read_parameters() -> Dictionary:
	var parameters = {}
	# TODO ...
		#
		# If you use another resource(s) make sure you append:
		# 	`_use: { drop:[<resource_uid>,...], refer:[<resource_uid>,...] }`
		# to the `parameters`.
		# Items listed in the `drop` array will be unlinked and the `refer`ed ones will be linked.
		# If the items are of known field (nodes, variables, etc.) adding `field:<String>` optionally to the `_use` helps optimization
		#
		# Handle with care!
		# Other special command(s) you can add to the `parameters`:
		# 	`_as_entry: { { node_id:<node_resource_uid>, for_scene:<bool>, for_project:<bool> }`
		#	`_exposure_revision: [ [old_name<String>, new_name<String>, old_parent<String(e.g. character-name)>, new_parent<String>], ... ]`
		#		> Caution! Variables and Characters automatically does the revision based on their UID and `name` change parameters.
		#		> This command is mostly used for other (UID-less) exposures, including `character_name.exposed_tag`.
		#
		# Note also that all commands are executed before the resource being updated.
		#
	return parameters

# when a new node is created by the core, this function is called
# it shall return the default or customized resource `data` (dictionary) for a new node
# later the central mind may run `_update_parameters` with result of this function
func _create_new(new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data

# central mind tries to translate internal references (by UID) or name exposures,
# that are held by each node if needed, by calling this method if it exists, passing the data as reference
func _translate_internal_ref(data: Dictionary, translation: Dictionary) -> void:
	# if translation.names.has(data.exposure):
	# if translation.ids.has(data.internal_reference):
	pass
