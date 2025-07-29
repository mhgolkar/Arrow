# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Frame Graph Node
extends GraphNode

@onready var Main = get_tree().get_root().get_child(0)
@onready var Grid = Main.Grid
@onready var Mind = Main.Mind
@onready var TheTree = Main.TheTree

const NO_LABEL_MESSAGE = "FRAME_NODE_NO_LABEL_MSG" # Translated ~ "No Label!"
const HIDE_EMPTY_LABEL = true

var _node_id
var _node_resource

var This = self

@onready var CollapseToggle = $Display/Head/Collapse
@onready var FrameLabel = $Display/Info

func _ready() -> void:
	register_connections()
	move_behind_wrapped_nodes()
	pass

func register_connections() -> void:
	self.mouse_exited.connect(self._on_mouse_exited, CONNECT_DEFERRED)
	self.resize_request.connect(self._on_resize_request, CONNECT_DEFERRED)
	self.resize_end.connect(self._on_resize_end, CONNECT_DEFERRED)
	CollapseToggle.toggled.connect(self._handle_collapse_and_size, CONNECT_DEFERRED)
	pass

func _on_resize(new_size: Vector2):
	if new_size.x < 128 :
		new_size.x = 128
	if new_size.y < 128 :
		new_size.y = 128
	# ...
	var rect_array = Helpers.Utils.vector2_to_array(new_size)
	_node_resource.data.rect = rect_array
	_handle_collapse_and_size()
	return rect_array

func _on_resize_request(new_size) -> void:
	_on_resize(new_size)
	pass

func _on_resize_end(new_size) -> void:
	var rect_array = _on_resize(new_size)
	Mind.central_event_dispatcher("update_resource",
		{
			"id":_node_id,
			"modification": { "data": { "rect": rect_array } },
			"field": "nodes",
			"auto": true,
		}
	)
	pass

func move_behind_wrapped_nodes():
	var z_order = self.get_index()
	for wrapped in Grid.get_nodes_in(self.get_global_rect()):
		var wrapped_order = wrapped.node.get_index()
		if wrapped_order < z_order:
			z_order = wrapped_order
	Grid.move_child(self, z_order)
	pass

func _on_mouse_exited():
	move_behind_wrapped_nodes()
	pass

func _handle_collapse_and_size(do_collapse: bool = CollapseToggle.is_pressed()) -> void:
	var size_vector = Helpers.Utils.array_to_vector2(_node_resource.data.rect)
	if do_collapse:
		self.set_deferred("resizable", false)
		var shrink_fill = Vector2(size_vector.x, 0)
		self.set_deferred("size", shrink_fill)
	else:
		self.set_deferred("resizable", true)
		self.set_deferred("size", size_vector)
	pass

func _gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.is_double_click():
			# (We use alt modifier in order not to interfere with double-click to inspect)
			if event.is_alt_pressed(): # Alt + Double-click:
				event.set_pressed(false)
				var nodes_there = Grid.get_nodes_under_cursor()
				# Select singular one under the cursor:
				if nodes_there.size() > 1:
					self.set_deferred("selected", false)
					Grid.call_deferred("_on_node_deselection", self)
					for each in nodes_there:
						if each.id != self._node_id:
							each.node.set_deferred("selected", true)
							Grid.call_deferred("_on_node_selection", each.node)
				# Select all framed nodes:
				else:
					Grid.call_deferred("select_all_in", self.get_global_rect())
	pass

func _update_node(data:Dictionary) -> void:
	if data.has("label") && (data.label is String) && data.label.length() > 0:
		FrameLabel.set_deferred("text", data.label)
		FrameLabel.set_deferred("visible", true)
	else:
		FrameLabel.set_deferred("text", NO_LABEL_MESSAGE)
		FrameLabel.set_deferred("visible", (!HIDE_EMPTY_LABEL))
	if data.has("color") && (data.color is String):
		This.set("self_modulate", Helpers.Utils.rgba_hex_to_color(data.color) )
	if data.has("rect") && data.rect is Array && data.rect.size() >= 2:
		_handle_collapse_and_size()
	pass
