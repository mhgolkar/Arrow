# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Marker Graph Node
extends GraphNode

@onready var Main = get_tree().get_root().get_child(0)

const SET_SLOT_COLORS := false

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_id
@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_resource

@onready var MarkerLabel = $Display/MarkerLabel

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
		MarkerLabel.set_deferred("text", "") # ~ No label
	if data.has("color") && (data.color is String):
		var the_color = Helpers.Utils.rgba_hex_to_color(data.color)
		self.set("self_modulate", the_color)
		if SET_SLOT_COLORS:
			self.set_slot_color_left(0, the_color)
			self.set_slot_color_right(0, the_color)
	pass
