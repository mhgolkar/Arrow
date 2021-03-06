# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Marker Node Type
extends GraphNode

onready var Main = get_tree().get_root().get_child(0)

const NO_LABEL_MESSAGE = "No Label!"

var _node_id
var _node_resource

var This = self

onready var MarkerLabel = get_node("./VBoxContainer/MarkerLabel")

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_node(data:Dictionary) -> void:
	if data.has("label") && (data.label is String) && data.label.length() > 0:
		MarkerLabel.set_deferred("text", data.label)
	else:
		MarkerLabel.set_deferred("text", NO_LABEL_MESSAGE)
	if data.has("color") && (data.color is String):
		This.set("self_modulate", Color(data.color) )
	pass
