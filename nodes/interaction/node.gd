# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Interaction Graph Node
extends GraphNode

@onready var Main = get_tree().get_root().get_child(0)

const OUT_SLOT_COLOR = Settings.GRID_NODE_SLOT.DEFAULT.OUT.COLOR
# settings for the dynamically generated outgoing slots
const OUT_SLOT_ENABLE_RIGHT = true
const OUT_SLOT_ENABLE_lEFT  = false
const OUT_SLOT_TYPE_RIGHT   = Settings.GRID_NODE_SLOT.DEFAULT.OUT.TYPE
const OUT_SLOT_TYPE_LEFT    = OUT_SLOT_TYPE_RIGHT
const OUT_SLOT_COLOR_RIGHT  = OUT_SLOT_COLOR
const OUT_SLOT_COLOR_LEFT   = OUT_SLOT_COLOR

const ACTION_SLOT_ALIGN = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
const ACTION_AUTO_WRAP = TextServer.AutowrapMode.AUTOWRAP_WORD_SMART

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_id
@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_resource

var This = self

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func remove_actions_all() -> void:
	for node in self.get_children():
		if node is Label:
			node.free()
	pass

func _update_node(data:Dictionary) -> void:
	remove_actions_all()
	if data.has("actions") && data.actions is Array:
		# Note: starts from `1` because there is a default `in`coming slot first at 0 index (`./Head`)
		var idx = 1 
		for action_text in data.actions:
			if action_text is String:
				var action_slot = Label.new()
				action_slot.set_text(action_text)
				action_slot.set_horizontal_alignment(ACTION_SLOT_ALIGN)
				action_slot.set_autowrap_mode(ACTION_AUTO_WRAP)
				This.add_child(action_slot)
				This.set_slot(
					idx,
					OUT_SLOT_ENABLE_lEFT, OUT_SLOT_TYPE_LEFT, OUT_SLOT_COLOR_LEFT,
					OUT_SLOT_ENABLE_RIGHT, OUT_SLOT_TYPE_RIGHT, OUT_SLOT_COLOR_RIGHT
				)
				idx += 1
	pass
