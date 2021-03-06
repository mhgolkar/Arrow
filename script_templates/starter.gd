# Arrow
# Game Narrative Design Tool
# % contributor(s) %

# % module identity %
extends %BASE%

# reference to `Main` (root)
onready var Main = get_tree().get_root().get_child(0)

# called when the node enters the scene tree for the first time
func _ready()%VOID_RETURN%:
	register_connections()
	pass

func register_connections()%VOID_RETURN%:
	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
	pass
