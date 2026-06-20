# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Jump Graph Node
extends GraphNode

@onready var Main = get_tree().get_root().get_child(0)

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_id
@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_resource

var This = self

@onready var Reason = $Display/Reason

const UNSET_REASON_MESSAGE = "EXIT_NODE_UNSET_REASON_MSG" # Translated ~ "No Reason"
const HIDE_REASON_IF_UNSET = true

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_node(data:Dictionary) -> void:
	if data.has("reason") && (data.reason is String) && data.reason.length() > 0:
		Reason.set_deferred("text", data.reason)
		Reason.set_deferred("visible", true)
	else:
		Reason.set_deferred("text", UNSET_REASON_MESSAGE)
		Reason.set_deferred("visible", (!HIDE_REASON_IF_UNSET))
	pass
