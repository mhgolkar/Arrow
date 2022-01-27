# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Frame Node Type
extends GraphNode

onready var Main = get_tree().get_root().get_child(0)
onready var Grid = Main.Grid
onready var Mind = Main.Mind
onready var TheTree = Main.TheTree

var Utils = Helpers.Utils

const NO_LABEL_MESSAGE = "No Label!"

var _node_id
var _node_resource

var This = self

onready var FrameLabel = get_node("./VBoxContainer/FrameLabel")

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	self.connect("resize_request", self, "_on_resize_request", [], CONNECT_DEFERRED)
	pass

func _on_resize_request(new_min_size) -> void:
	if new_min_size.x < 128 :
		new_min_size.x = 128
	if new_min_size.y < 128 :
		new_min_size.y = 128
	Mind.update_resource(
		_node_id, 
		{ "data": { "rect": Utils.vector2_to_array(new_min_size) } },
		"nodes",
		true
	)
	pass

func _gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.is_doubleclick():
			event.set_pressed(false)
			var nodes_there = Grid.get_nodes_under_cursor()
			if nodes_there.size() > 1:
				self.set_deferred("selected", false)
				Grid.call_deferred("_on_node_unselection", self)
				for each in nodes_there:
					if each.id != self._node_id:
						each.node.set_deferred("selected", true)
						Grid.call_deferred("_on_node_selection", each.node)
			else:
				Grid.call_deferred("sellect_all_in", self.get_global_rect())
	pass

func _update_node(data:Dictionary) -> void:
	if data.has("label") && (data.label is String) && data.label.length() > 0:
		FrameLabel.set_deferred("text", data.label)
	else:
		FrameLabel.set_deferred("text", NO_LABEL_MESSAGE)
	if data.has("color") && (data.color is String):
		This.set("self_modulate", Color(data.color) )
	if data.has("rect") && data.rect is Array && data.rect.size() >= 2 :
		var new_size = Utils.array_to_vector2(data.rect)
		self.set_deferred("rect_min_size", new_size)
		self.set_deferred("rect_size", new_size)
	pass
