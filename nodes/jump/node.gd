# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Jump Graph Node
extends GraphNode

@onready var Main = get_tree().get_root().get_child(0)

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_id
@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_resource

var This = self

@onready var Destination = $Display/Destination
@onready var Reason = $Display/Reason

const DESTINATION_FORMAT_STRING = (
	"{target_name}" if Settings.FORCE_UNIQUE_NAMES_FOR_NODES else "{target_name} ({target_uid})"
)
const UNSET_TARGET_NAME = "JUMP_NODE_UNSET_TARGET_NAME" # Translated ~ "Unset"
const UNSET_REASON_MESSAGE = "JUMP_NODE_UNSET_REASON_MSG" # Translated ~ "No Reason"
const HIDE_REASON_IF_UNSET = true

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.is_double_click():
			if event.is_alt_pressed() == true:
				if _node_resource.has("data"):
					var data = _node_resource.data
					if data.has("target") && (data.target is int) && data.target >= 0:
						Main.Mind.call_deferred("locate_node_on_grid", data.target)
	pass

func _update_node(data:Dictionary) -> void:
	var destination = { "target_name": UNSET_TARGET_NAME, "target_uid": "-1" }
	if data.has("target") && (data.target is int) && data.target >= 0:
		destination.target_uid = data.target
		var target_node = Main.Mind.lookup_resource(data.target, "nodes")
		if (target_node is Dictionary) && target_node.has("name") && (target_node.name is String):
			destination.target_name = target_node.name
	Destination.set_deferred("text", DESTINATION_FORMAT_STRING.format(destination))
	if data.has("reason") && (data.reason is String) && data.reason.length() > 0:
		Reason.set_deferred("text", data.reason)
		Reason.set_deferred("visible", true)
	else:
		Reason.set_deferred("text", UNSET_REASON_MESSAGE)
		Reason.set_deferred("visible", (!HIDE_REASON_IF_UNSET))
	pass
