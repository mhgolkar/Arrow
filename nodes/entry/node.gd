# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Entry Node Type
extends GraphNode

onready var Main = get_tree().get_root().get_child(0)

const INVALID_OR_UNSET_PLAQUE_TEXT = "Unset"
const HIDE_UNSET_OR_INVALID_PLAQUE = true

var _node_id
var _node_resource

var This = self

onready var Plaque = get_node("./VBoxContainer/Plaque")

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_node(data:Dictionary) -> void:
	# set plaque name of the entry point
	if data.has("plaque") && data.plaque is String && data.plaque.length() > 0:
		Plaque.set_deferred("text", data.plaque)
		Plaque.set_visible(true)
	else:
		Plaque.set_deferred("text", INVALID_OR_UNSET_PLAQUE_TEXT)
		Plaque.set_visible( ! HIDE_UNSET_OR_INVALID_PLAQUE )
	pass
