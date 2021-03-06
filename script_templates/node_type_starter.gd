# Arrow
# Game Narrative Design Tool
# % contributor(s) %

# % Custom % Node Type
extends %BASE%

# reference to `Main` (root)
onready var Main = get_tree().get_root().get_child(0)

# resource-uid of the node instance
var _node_id

# the node (element) itself
var This = self

# children
# onready var NODE_CHILD_X = get_node("./X")

# called when the node enters the scene tree for the first time
func _ready()%VOID_RETURN%:
	register_connections()
	pass

func register_connections()%VOID_RETURN%:
	# e.g. NODE_CHILD_X.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
	pass

# this function updates the node inner parts (children,)
# and is called with resource `data` on updates or initial creation
func _update_node(data:Dictionary)%VOID_RETURN%:
	# if data.has("x") && (data.x is X):
	#	NODE_CHILD_X.set_deferred("property/x", data.x)
	pass
