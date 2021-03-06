# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Content Node Type
extends GraphNode

onready var Main = get_tree().get_root().get_child(0)

const TITLE_UNSET_MESSAGE = "Untitled"

var _node_id
var _node_resource

var This = self

onready var Title = get_node("./VBoxContainer/Title")

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_node(data:Dictionary) -> void:
	if data.has("title") && data.title is String && data.title.length() > 0 :
		Title.set_deferred("text", data.title)
	else:
		Title.set_deferred("text", TITLE_UNSET_MESSAGE)
	pass
