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
const HIDE_EMPTY_LABLE = true

var _node_id
var _node_resource

var This = self

var _RESIZE_DEBOUNCER = null
var _DELAYED_RESIZE: Dictionary

onready var CollapseToggle = get_node("./MarginContainer/VBoxContainer/Header/CollapseToggle")
onready var FrameLabel = get_node("./MarginContainer/VBoxContainer/FrameLabel")

func _ready() -> void:
	register_connections()
	move_behind_wrapped_nodes()
	pass

func register_connections() -> void:
	self.connect("mouse_exited", self, "_on_mouse_exited", [], CONNECT_DEFERRED)
	self.connect("resize_request", self, "_on_resize_request", [], CONNECT_DEFERRED)
	CollapseToggle.connect("toggled", self, "_handle_collapse_and_size", [], CONNECT_DEFERRED)
	pass

func _handle_delayed_request() -> void:
	Mind.central_event_dispatcher("update_resource", _DELAYED_RESIZE)
	pass

func _on_resize_request(new_min_size) -> void:
	if new_min_size.x < 128 :
		new_min_size.x = 128
	if new_min_size.y < 128 :
		new_min_size.y = 128
	# ...
	var rect_array = Utils.vector2_to_array(new_min_size)
	_DELAYED_RESIZE = {
		"id":_node_id,
		"modification": { "data": { "rect": rect_array } },
		"field": "nodes",
		"auto": true,
	}
	# emulate change for user to see
	_node_resource.data.rect = rect_array
	_handle_collapse_and_size()
	# and plan to request with debounce
	if _RESIZE_DEBOUNCER != null:
		_RESIZE_DEBOUNCER.disconnect("timeout", self, "_handle_delayed_request")
	_RESIZE_DEBOUNCER = TheTree.create_timer( Settings.MIND_REQUEST_DEBOUNCE_TIME_SEC )
	_RESIZE_DEBOUNCER.connect("timeout", self, "_handle_delayed_request", [], CONNECT_DEFERRED)
	pass

func move_behind_wrapped_nodes():
	var z_order = self.get_position_in_parent()
	for wrapped in Grid.get_nodes_in(self.get_global_rect()):
		var wrapped_order = wrapped.node.get_position_in_parent()
		if wrapped_order < z_order:
			z_order = wrapped_order
	Grid.move_child(self, z_order)
	pass

func _on_mouse_exited():
	move_behind_wrapped_nodes()
	pass

func _handle_collapse_and_size(do_collapse: bool = CollapseToggle.is_pressed()) -> void:
	var size_vector = Utils.array_to_vector2(_node_resource.data.rect)
	if do_collapse:
		self.set_deferred("resizable", false)
		var shrink_fill = Vector2(size_vector.x, 0)
		self.set_deferred("rect_min_size", shrink_fill)
		self.set_deferred("rect_size", shrink_fill)
	else:
		self.set_deferred("resizable", true)
		self.set_deferred("rect_min_size", size_vector)
		self.set_deferred("rect_size", size_vector)
	pass

func _gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.is_doubleclick():
			# (We use alt modifier in order not to interfere with double-click to inspect)
			if event.get_alt(): # Alt + Double-click:
				event.set_pressed(false)
				var nodes_there = Grid.get_nodes_under_cursor()
				# Select singular one under the cursor:
				if nodes_there.size() > 1:
					self.set_deferred("selected", false)
					Grid.call_deferred("_on_node_unselection", self)
					for each in nodes_there:
						if each.id != self._node_id:
							each.node.set_deferred("selected", true)
							Grid.call_deferred("_on_node_selection", each.node)
				# Select all framed nodes:
				else:
					Grid.call_deferred("sellect_all_in", self.get_global_rect())
	pass

func _update_node(data:Dictionary) -> void:
	if data.has("label") && (data.label is String) && data.label.length() > 0:
		FrameLabel.set_deferred("text", data.label)
		FrameLabel.set_deferred("visible", true)
	else:
		FrameLabel.set_deferred("text", NO_LABEL_MESSAGE)
		FrameLabel.set_deferred("visible", (!HIDE_EMPTY_LABLE))
	if data.has("color") && (data.color is String):
		This.set("self_modulate", Utils.rgba_hex_to_color(data.color) )
	if data.has("rect") && data.rect is Array && data.rect.size() >= 2:
		_handle_collapse_and_size()
	pass
