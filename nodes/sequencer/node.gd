# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Sequencer Graph Node
extends GraphNode

@onready var Main = get_tree().get_root().get_child(0)

const MINIMUM_ACCEPTABLE_OUT_SLOTS = SequencerSharedClass.SEQUENCER_MINIMUM_ACCEPTABLE_OUT_SLOTS

const OUT_SLOT_COLOR = Settings.GRID_NODE_SLOT.DEFAULT.OUT.COLOR

# settings for the dynamically generated outgoing slots
const OUT_SLOT_ENABLE_RIGHT = true
const OUT_SLOT_ENABLE_lEFT  = false
const OUT_SLOT_TYPE_RIGHT   = Settings.GRID_NODE_SLOT.DEFAULT.OUT.TYPE
const OUT_SLOT_TYPE_LEFT    = OUT_SLOT_TYPE_RIGHT
const OUT_SLOT_COLOR_RIGHT  = OUT_SLOT_COLOR
const OUT_SLOT_COLOR_LEFT   = OUT_SLOT_COLOR

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_id
@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_resource

var This = self

# @onready var X = get_node("./X")

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
	# append outgoing slots
	if data.has("slots") && data.slots is int && data.slots >= MINIMUM_ACCEPTABLE_OUT_SLOTS:
		# Note: starts from `1` because there is a default `in`coming slot first at 0 index (`./Head`)
		for idx in range(1, ( data.slots + 1 )):
			var slot = Label.new()
			This.add_child(slot)
			This.set_slot(
				idx,
				OUT_SLOT_ENABLE_lEFT, OUT_SLOT_TYPE_LEFT, OUT_SLOT_COLOR_LEFT,
				OUT_SLOT_ENABLE_RIGHT, OUT_SLOT_TYPE_RIGHT, OUT_SLOT_COLOR_RIGHT
			)
	pass
