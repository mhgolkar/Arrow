# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Jump Node Type
extends GraphNode

onready var Main = get_tree().get_root().get_child(0)

var _node_id
var _node_resource

var This = self

onready var Destination = get_node("./Slot/Destination")
onready var Reason = get_node("./Slot/Reason")

const JUMP_TARGET_FAILED_MESSAGE = "No Target"
const REASON_TEXT_UNSET_MESSAGE = "No Reason"

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.is_doubleclick():
			if _node_resource.has("data"):
				var data = _node_resource.data
				if data.has("target") && (data.target is int) && data.target >= 0:
					Main.Mind.call_deferred("locate_node_on_grid", data.target)
	pass

func _update_node(data:Dictionary) -> void:
	var target_text = JUMP_TARGET_FAILED_MESSAGE
	if data.has("target") && (data.target is int) && data.target >= 0:
		var target_node = Main.Mind.lookup_resource(data.target, "nodes")
		if (target_node is Dictionary) && target_node.has("name") && (target_node.name is String):
			target_text = target_node.name
	Destination.set_deferred("text", target_text)
	if data.has("reason") && (data.reason is String) && data.reason.length() > 0:
		Reason.set_deferred("text", data.reason)
	else:
		Reason.set_deferred("text", REASON_TEXT_UNSET_MESSAGE)
	pass
