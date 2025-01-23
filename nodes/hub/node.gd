# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Hub Graph Node
extends GraphNode

@onready var Main = get_tree().get_root().get_child(0)

# A hub is by definition, to merge inputs,
# so there must be at least two incoming slots for any hub
const MINIMUM_ACCEPTABLE_IN_SLOTS = HubSharedClass.HUB_MINIMUM_ACCEPTABLE_IN_SLOTS

const IN_SLOT_COLOR  = Settings.GRID_NODE_SLOT.DEFAULT.IN.COLOR
# settings for the dynamically generated incoming slots
const IN_SLOT_ENABLE_lEFT  = true
const IN_SLOT_ENABLE_RIGHT = false
const IN_SLOT_TYPE_LEFT    = Settings.GRID_NODE_SLOT.DEFAULT.IN.TYPE
const IN_SLOT_TYPE_RIGHT   = IN_SLOT_TYPE_LEFT
const IN_SLOT_COLOR_LEFT   = IN_SLOT_COLOR
const IN_SLOT_COLOR_RIGHT  = IN_SLOT_COLOR

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_id
@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_resource

var This = self

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass
	
func remove_slots_all() -> void:
	for node in self.get_children():
		if node is Label:
			node.free()
	pass

func _update_node(data:Dictionary) -> void:
	remove_slots_all()
	# append incoming slots
	if data.has("slots") && data.slots is int && data.slots >= MINIMUM_ACCEPTABLE_IN_SLOTS:
		# Note: starts from `1` because there is a default `out`going slot first at 0 index (`./Head`)
		for idx in range(1, data.slots+1):
			var slot = Label.new()
			This.add_child(slot)
			This.set_slot(
				idx,
				IN_SLOT_ENABLE_lEFT, IN_SLOT_TYPE_LEFT, IN_SLOT_COLOR_LEFT,
				IN_SLOT_ENABLE_RIGHT, IN_SLOT_TYPE_RIGHT, IN_SLOT_COLOR_RIGHT
			)
	pass
