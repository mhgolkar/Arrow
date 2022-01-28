# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Grid
extends GraphEdit

signal request_mind

onready var TheTree = get_tree() 
onready var Main = TheTree.get_root().get_child(0)
onready var TheViewport = get_viewport()
onready var GridContextMenu = get_node(Addressbook.GRID_CONTEXT_MENU.itself)

onready var Minimap = get_node(Addressbook.MINIMAP)
onready var MinimapBox = Minimap.get_parent()
const USE_ARROW_MINIMAP:bool = Settings.CLASSIC_MINIMAP_ENABLED

const CLIPBOARD_MODE = Settings.CLIPBOARD_MODE

var Utils = Helpers.Utils

const NODE_NAME_FROM_ID_PREFIX = "GRID_GRAPH_NODE_WITH_ID_"

var DEFAULT_ZOOM:float
var _ALLOW_ASSISTED_CONNECTION = true
var _ALLOW_QUICK_NODE_INSERTION = true

var _DRAWN_NODES_BY_ID = {}
var _CONNECTION_RELATIONS = {}
var _CONNECTION_RELATIONS_BY_ID_DIR_SLOT = {}

var _CONNECTION_DRAWING_QUEUE = []

var _ALREADY_SELECTED_NODE_IDS = []
var _ALREADY_SELECTED_NODES_BY_ID = {}

var _HIGHLIGHTED_NODES = []

func _ready() -> void:
	DEFAULT_ZOOM = self.get('zoom')
	register_connections()
	setup_valid_connection_types()
	# classic minimap ?
	if USE_ARROW_MINIMAP :
		MinimapBox.set_visible( ! self.is_minimap_enabled() )
	else:
		self.set_minimap_enabled(true)
	resize_native_minimap()
	pass

func register_connections() -> void:
	self.connect("popup_request", self, "_on_popup_request", [], CONNECT_DEFERRED)
	self.connect("connection_to_empty", self, "_on_connection_with_empty", [true], CONNECT_DEFERRED )
	self.connect("connection_from_empty", self, "_on_connection_with_empty", [false], CONNECT_DEFERRED )
	self.connect("node_selected", self, "_on_node_selection", [], CONNECT_DEFERRED)
	self.connect("node_unselected", self, "_on_node_unselection", [], CONNECT_DEFERRED)
	self.connect("connection_request", self, "_on_connection_request", [], CONNECT_DEFERRED )
	self.connect("disconnection_request", self, "_on_disconnection_request", [], CONNECT_DEFERRED )
	self.connect("_end_node_move", self, "_on_node_move_end", [], CONNECT_DEFERRED )
	pass

func setup_valid_connection_types() -> void:
	for pair in Settings.GRID_VALID_CONNECTIONS:
		var valid_connection = Settings.GRID_VALID_CONNECTIONS[pair]
		# defining valid connections both ways lets users draw connections from or to in or out valid ports.
		add_valid_connection_type(valid_connection.from, valid_connection.to)
		add_valid_connection_type(valid_connection.to, valid_connection.from)
		# also valid disconnections for both hands, besides convenience ...
		# generates a helpful side-effect that users can't connect from one out slot to two different in slots
		add_valid_right_disconnect_type(valid_connection.to)
		add_valid_left_disconnect_type(valid_connection.to)
	pass

func request_mind(req:String, args) -> void:
	self.emit_signal("request_mind", req, args)
	pass

func offset_from_position(position:Vector2) -> Vector2:
	# scroll offset of a GraphEdit is the offset of the visible top left corner
	var scroll_offset = self.get_scroll_ofs()
	# position is also relative to the top left corner of the parent (visible part)
	# therefore : 
	var grid_offset_of_position = (scroll_offset + position) / self.get_zoom()
	return grid_offset_of_position

# (right-click on the grid)
func _on_popup_request(position:Vector2) -> void:
	var relative_click_position = self.get_local_mouse_position()
	GridContextMenu.call_deferred("show_up", position, offset_from_position(relative_click_position))
	pass

func get_nodes_under_cursor(return_id:bool = false, return_first:bool = false) -> Array:
	var nodes_there = []
	var mouse_position = TheViewport.get_mouse_position()
	for node_id in _DRAWN_NODES_BY_ID:
		var node = _DRAWN_NODES_BY_ID[node_id]
		if (
			is_instance_valid(node) &&
			node.get_global_rect().has_point(mouse_position)
		):
			nodes_there.append(
				node_id
				if return_id == true
				else
				{ "id": node_id, "node": node }
			)
			if return_first:
				return nodes_there
	return nodes_there

func get_nodes_in(boundry: Rect2, return_id:bool = false, return_first:bool = false) -> Array:
	var nodes_in_boundry = []
	for node_id in _DRAWN_NODES_BY_ID:
		var node = _DRAWN_NODES_BY_ID[node_id]
		if (
			is_instance_valid(node) &&
			boundry.encloses( node.get_global_rect() )
		):
			nodes_in_boundry.append(
				node_id
				if return_id == true
				else
				{ "id": node_id, "node": node }
			)
			if return_first:
				return nodes_in_boundry
	return nodes_in_boundry

func sellect_all_in(boundry: Rect2) -> void:
	var nodes_in_boundry = get_nodes_in(boundry)
	for each in nodes_in_boundry:
		each.node.set_deferred("selected", true)
		self.call_deferred("_on_node_selection", each.node)
	pass

func slot_is_available(node_id:int, slot_idx:int, in_else_out:bool = true) -> bool:
	if _CONNECTION_RELATIONS_BY_ID_DIR_SLOT.has(node_id):
		return (
			_CONNECTION_RELATIONS_BY_ID_DIR_SLOT[node_id][
			"in" if in_else_out else "out"
			].has(slot_idx) == false
		)
	return true

func get_node_slot_count(node_id:int = -1) -> int:
	if _DRAWN_NODES_BY_ID.has(node_id):
		var the_node = _DRAWN_NODES_BY_ID[node_id]
		var dynamic_count = (
			the_node._node_resource.data.slots
			if the_node._node_resource.data.has("slots")
			else 0
		)
		var static_count = the_node.get_child_count()
		return int( max(dynamic_count, static_count) )
	return 0

func get_first_available_slot(node_id:int, incoming:bool) -> int:
	if node_id >= 0 && _DRAWN_NODES_BY_ID.has(node_id):
		var drawn_node = _DRAWN_NODES_BY_ID[node_id]
		var slot_availability_map = []
		var slot_count = get_node_slot_count(node_id)
		if slot_count > 0:
			for idx in range(0, slot_count):
				var rel_slot_idx = slot_availability_map.size()
				if incoming:
					if drawn_node.is_slot_enabled_left(idx):
						slot_availability_map.push_back(
							slot_is_available(node_id, rel_slot_idx, true)
						)
				else:
					if drawn_node.is_slot_enabled_right(idx):
						slot_availability_map.push_back(
							slot_is_available(node_id, rel_slot_idx, false)
						)
			# print_debug("assisted connection availability map: ", slot_availability_map, " of ", slot_count)
			return slot_availability_map.find(true)
	return -1

func try_assisted_connection(outgoing:bool, first_side_slot:int, first_side_name:String) -> bool:
	if _ALLOW_ASSISTED_CONNECTION:
		var nodes_there = get_nodes_under_cursor()
		if nodes_there.size() > 0:
			# We try to coonect to the first target ...
			for target in nodes_there:
				# in all the nodes under the cursor,
				if target.node.name != first_side_name: # which is not the first side,
					var target_slot = get_first_available_slot(target.id, outgoing) # = incoming for the other side
					# and has at least one slot:
					if target_slot >= 0 :
						if outgoing:
							_on_connection_request(first_side_name, first_side_slot, target.node.name, target_slot)
						else:
							_on_connection_request(target.node.name, target_slot, first_side_name, first_side_slot)
						# Return early and break the loop
						return true
	return false

func _on_connection_with_empty(node_name:String, slot:int, release_position:Vector2, outgoing:bool) -> void:
	if try_assisted_connection(outgoing, slot, node_name) == false:
		if _ALLOW_QUICK_NODE_INSERTION:
			GridContextMenu.call_deferred(
				"show_up",
				release_position, offset_from_position(release_position),
				[node_name.to_int(), slot, outgoing]
			)
	pass

func _on_node_selection(node) -> void:
	var the_node_id = node._node_id;
	# Note: following check is necessary,
	# because `GraphEdit` lets (fires event for) reselection of a selected node.
	if _ALREADY_SELECTED_NODE_IDS.has(the_node_id) == false:
		request_mind("node_selection", the_node_id)
		_ALREADY_SELECTED_NODES_BY_ID[the_node_id] = node
		_ALREADY_SELECTED_NODE_IDS.push_front(the_node_id)
	else:
		request_mind("inspect_node", the_node_id)
	pass

func force_unselect_all():
	_ALREADY_SELECTED_NODE_IDS.clear()
	_ALREADY_SELECTED_NODES_BY_ID.clear()
	set_selected(null)
	pass
	
func select_node_by_id(node_id:int, unselect_others:bool = false, go_to:bool = false) -> void:
	if unselect_others:
		force_unselect_all()
	if _DRAWN_NODES_BY_ID.has(node_id):
		set_selected( _DRAWN_NODES_BY_ID[node_id] )
		_ALREADY_SELECTED_NODE_IDS.push_back(node_id)
		_ALREADY_SELECTED_NODES_BY_ID[node_id] = _DRAWN_NODES_BY_ID[node_id]
		if go_to == true:
			go_to_offset_by_node_id(node_id)
	else:
		print_stack()
		printerr("Unexpected Behavior! Trying to select a grid node = %s that is not drawn!" % node_id)
	pass

func _on_node_unselection(node) -> void:
	var the_node_id = node._node_id
	proceed_unselection_by_id(the_node_id)
	pass

func proceed_unselection_by_id(node_id:int) -> void:
	if _ALREADY_SELECTED_NODES_BY_ID.has(node_id):
		request_mind("node_unselection", node_id)
		_ALREADY_SELECTED_NODES_BY_ID.erase(node_id)
		_ALREADY_SELECTED_NODE_IDS.erase(node_id)
	pass

func clean_grid() -> void:
	force_unselect_all()
	clear_connections()
	for node_id in _DRAWN_NODES_BY_ID:
		var node = _DRAWN_NODES_BY_ID[node_id]
		if is_instance_valid(node) :
			node.free()
	_DRAWN_NODES_BY_ID.clear()
	_CONNECTION_DRAWING_QUEUE.clear()
	_CONNECTION_RELATIONS.clear()
	_HIGHLIGHTED_NODES.clear()
	# `clean_grid` is called on scene/macro opening.
	# we also need to refresh context menu once on every scene change, to make sure
	# special item restrictions (e.g. no `macro_use` in a macro) is applied.
	GridContextMenu.call_deferred("filter_node_insert_list_items_view", "", true)
	# ... is neccessary here because refreshing item list (filtering) won't happen unless there is a user action
	# this is why we did it manually here.
	pass

func got_to_offset(destination, auto_adjust:bool = false, reset_zoom:bool = true) -> void:
	if destination is Array:
		destination = Utils.array_to_vector2(destination)
	if destination is Vector2:
		if auto_adjust:
			if reset_zoom:
				self.set_zoom(1)
			var adjustment = ( self.get_size() * Settings.GRID_GO_TO_AUTO_ADJUSTMENT_FACTOR )
			destination = (destination - adjustment).floor()
		self.call_deferred("set_scroll_ofs", destination)
	if USE_ARROW_MINIMAP:
		Minimap.call_deferred("set_crosshair")
	pass

func go_to_offset_by_node_id(node_id:int, highlight:bool = false) -> void:
	yield(TheTree, "idle_frame")
	if _DRAWN_NODES_BY_ID.has(node_id):
		got_to_offset( _DRAWN_NODES_BY_ID[node_id].get_offset() , true)
		if highlight:
			highlight_node(node_id, true)
	pass

func highlight_node(node_id:int = -1, fade_out:bool = false) -> void:
	# is there such node?
	if node_id >=0 && _DRAWN_NODES_BY_ID.has(node_id):
		if _HIGHLIGHTED_NODES.has(node_id) && fade_out == true:
			_DRAWN_NODES_BY_ID[node_id].set_overlay(GraphNode.OVERLAY_DISABLED)
			_HIGHLIGHTED_NODES.erase(node_id)
		else:
			_DRAWN_NODES_BY_ID[node_id].set_overlay(GraphNode.OVERLAY_POSITION)
			_HIGHLIGHTED_NODES.append(node_id)
			if fade_out == true:
				# set for auto fade out
				var highlight_timer = TheTree.create_timer(Settings.NODE_HIGHLIGHT_FADE_TIME_OUT)
				highlight_timer.connect("timeout", self, "highlight_node", [node_id, true])
	else:
		# otherwise off-light for all
		for node_id in _HIGHLIGHTED_NODES:
			if _DRAWN_NODES_BY_ID.has(node_id) && is_instance_valid(_DRAWN_NODES_BY_ID[node_id]):
				highlight_node(node_id, true)
		_HIGHLIGHTED_NODES.clear()
	pass
	
func highlight_nodes(list, fade_out:bool = false, reset_previous:bool = false) ->void:
	if reset_previous == true:
		highlight_node(-1)
	if list is Array && list.size() > 0:
		for node_id in list:
			highlight_node(node_id, fade_out)
	pass

func reset_view_to_initial() -> void:
	set_grid_view(Vector2.ZERO, Settings.GRID_INITIAL_ZOOM)
	pass

func set_grid_view(offset = null, zoom = null ) -> void:
	# Note: setting zoom and offset at the same frame, won't work as expected! hence `set_deferred` (Godot 3.2.3)
	if zoom is float || zoom is int :
		self.set("zoom", zoom )
	if offset is Vector2:
		self.set_deferred("scroll_offset", offset )
	elif offset is Array:
		var validated_offset = Utils.array_to_vector2(offset)
		if validated_offset is Vector2:
			self.set_deferred("scroll_offset", validated_offset )
	pass

func draw_node(node_id:int, node:Dictionary, map:Dictionary, type:Dictionary) -> void:
	# printt("Node Drawn: ", id, node, map, type)
	# creating the node
	var node_instance = type.node.instance()
	node_instance._node_id = node_id
	node_instance._node_resource = node
	# Note: Godot uses the property `name` of `Node`s to handle connections between `GraphNode`s in a `GraphEdit`
	# we will use the node id (which is fixed and unique) for this purpose and NEVER node.name because it can be edited though unique
	node_instance.set_name( (NODE_NAME_FROM_ID_PREFIX + String( node_id)) )
	# and keeping a reference to it
	_DRAWN_NODES_BY_ID[node_id] = node_instance
	add_child(node_instance)
	update_grid_node_box(node_id, node)
	update_grid_node_map(node_instance, map)
	if map.has("io"):
		for connection in map.io:
			queue_drawing_connection(connection)
	make_auto_resize(node_instance)
	pass

func get_node_instance(node_id_or_instance):
	return (_DRAWN_NODES_BY_ID[node_id_or_instance] if ((node_id_or_instance is int) && _DRAWN_NODES_BY_ID.has(node_id_or_instance)) else node_id_or_instance )

func update_grid_node_box(instance_or_id, node:Dictionary) -> void:
	var node_instance = get_node_instance(instance_or_id)
	if is_instance_valid(node_instance):
		node_instance._node_resource = node
		node_instance.set_deferred("title", node.name)
		# pass a clone of data to the plot node
		var data_clone = node.data.duplicate(true) 
		node_instance.call_deferred("_update_node", data_clone)
	# now that we've changed a node box, we shall update minimap too
	if USE_ARROW_MINIMAP:
		yield(TheTree, "idle_frame") # wait (none-blocking) skipping one _process
		Minimap.call_deferred("refresh")
	pass

func update_grid_node_map(instance_or_id, map:Dictionary) -> void:
	var node_instance = get_node_instance(instance_or_id)
	if node_instance is Node:
		node_instance.set_deferred("offset", Utils.array_to_vector2(map.offset) )
		if map.has("skip") && map.skip == true:
			set_node_skip(node_instance, true)
	if USE_ARROW_MINIMAP:
		Minimap.call_deferred("refresh")
	pass

func set_node_skip(instance_or_id, is_skip:bool = false):
	# Note: DO NOT USE `comment` property for skip. it conflicts with selection so ...
	# we use `modulate` property
	var node_instance = get_node_instance(instance_or_id)
	if is_instance_valid(node_instance):
		node_instance.set_deferred("modulate", (
				Settings.SKIP_NODE_SELF_MODULATION_COLOR_ON if is_skip else Settings.SKIP_NODE_SELF_MODULATION_COLOR_OFF
			)
		)
	pass

func keep_relationship(from_id:int, from_out_slot:int, to_id:int, to_in_slot:int) -> void:
	# outputer
	if _CONNECTION_RELATIONS.has(from_id) == false:
		_CONNECTION_RELATIONS[from_id] = { "in" : {}, "out": {} }
		_CONNECTION_RELATIONS_BY_ID_DIR_SLOT[from_id] = { "in" : {}, "out": {} }
	if _CONNECTION_RELATIONS[from_id]["out"].has(to_id) == false:
		_CONNECTION_RELATIONS[from_id]["out"][to_id] = []
	_CONNECTION_RELATIONS[from_id]["out"][to_id].append( [from_id, from_out_slot, to_id, to_in_slot] )
	_CONNECTION_RELATIONS_BY_ID_DIR_SLOT[from_id]["out"][from_out_slot] = [to_id, to_in_slot]
	# inputer
	if _CONNECTION_RELATIONS.has(to_id) == false:
		_CONNECTION_RELATIONS[to_id] = { "in" : {}, "out": {} }
		_CONNECTION_RELATIONS_BY_ID_DIR_SLOT[to_id] = { "in" : {}, "out": {} }
	if _CONNECTION_RELATIONS[to_id]["in"].has(from_id) == false:
		_CONNECTION_RELATIONS[to_id]["in"][from_id] = []
	_CONNECTION_RELATIONS[to_id]["in"][from_id].append( [from_id, from_out_slot, to_id, to_in_slot] )
	_CONNECTION_RELATIONS_BY_ID_DIR_SLOT[to_id]["in"][to_in_slot] = [from_id, from_out_slot]
	pass

func unkeep_relationship(from_id:int, from_out_slot:int, to_id:int, to_in_slot:int) -> void:
	if _CONNECTION_RELATIONS.has(from_id) && _CONNECTION_RELATIONS[from_id]["out"].has(to_id):
		_CONNECTION_RELATIONS[from_id]["out"][to_id].erase( [from_id, from_out_slot, to_id, to_in_slot] )
		_CONNECTION_RELATIONS_BY_ID_DIR_SLOT[from_id]["out"].erase(from_out_slot)
	if _CONNECTION_RELATIONS.has(to_id) && _CONNECTION_RELATIONS[to_id]["in"].has(from_id):
		_CONNECTION_RELATIONS[to_id]["in"][from_id].erase( [from_id, from_out_slot, to_id, to_in_slot] )
		_CONNECTION_RELATIONS_BY_ID_DIR_SLOT[to_id]["in"].erase(to_in_slot)
	pass

func draw_connections_batch(connections_batch:Array) -> void:
	for connection in connections_batch:
		if connection is Array && connection.size() == 4:
			var from_id = connection[0]
			var to_id = connection[2]
			if _DRAWN_NODES_BY_ID.has(from_id) && _DRAWN_NODES_BY_ID.has(to_id):
				var from = _DRAWN_NODES_BY_ID[ from_id ].name
				var from_slot = connection[1]
				var to = _DRAWN_NODES_BY_ID[ to_id ].name
				var to_slot = connection[3]
				self.call_deferred("connect_node", from, from_slot, to, to_slot)
				keep_relationship(connection[0], connection[1], connection[2], connection[3])
			else:
				printerr("Unexpected Behavior! Trying to connect none-drawn nodes: ", connection)
	pass

func draw_queued_connection() -> void:
	draw_connections_batch(_CONNECTION_DRAWING_QUEUE)
	_CONNECTION_DRAWING_QUEUE.clear()
	pass
	
func queue_drawing_connection(connection:Array) -> void:
	if _CONNECTION_DRAWING_QUEUE.has(connection) == false:
		_CONNECTION_DRAWING_QUEUE.push_back(connection)
	pass

func _on_connection_request(from_name:String, from_slot:int, to_name:String, to_slot:int) -> void:
	if from_name != to_name: # ... to avoid loops by connecting from and to the same point
		# Note: the signal connected to this handler uses the `Node::name` property (different than `<node-resource>.name`)
		# which we have set by adding a prefix to unique resource id the node-resource;
		# so to get the id from name property we just need to extract the integer part of the name
		var the_from_id = from_name.to_int()
		var the_to_id = to_name.to_int()
		if slot_is_available(the_from_id, from_slot, false) || Settings.RESTRICT_OUT_SLOTS_TO_ONE_CONNECTION == false: # only from side has outgoing slot
			connect_node(from_name, from_slot, to_name, to_slot)
			var mind_update_node_map_job = {
				"id": the_from_id, # the keeper side of the connection 
				"io": {
					"push": [
						[the_from_id, from_slot, the_to_id, to_slot]
					]
				}
			}
			keep_relationship(the_from_id, from_slot, the_to_id, to_slot)
			emit_signal("request_mind", "update_node_map", mind_update_node_map_job)
	pass

func disconnect_from_view_by_id(from_id:int, from_slot:int, to_id:int, to_slot:int) -> void:
	var from_name = _DRAWN_NODES_BY_ID[ from_id ].name
	var to_name = _DRAWN_NODES_BY_ID[ to_id ].name
	disconnect_node(from_name, from_slot, to_name, to_slot)
	unkeep_relationship(from_id, from_slot, to_id, to_slot)
	pass

func disconnect_nodes_by_id(from_id:int, from_slot:int, to_id:int, to_slot:int) -> void:
	disconnect_from_view_by_id(from_id, from_slot, to_id, to_slot)
	proceed_disconnection(from_id, from_slot, to_id, to_slot)
	pass

func _on_disconnection_request(from_name:String, from_slot:int, to_name:String, to_slot:int) -> void:
	var the_from_id = from_name.to_int()
	var the_to_id = to_name.to_int()
	disconnect_nodes_by_id(the_from_id, from_slot, the_to_id, to_slot)
	pass

func proceed_disconnection(from_id:int, from_slot:int, to_id:int, to_slot:int) -> void:
	var mind_update_node_map_job = {
		"id": from_id, # the keeper side of the connection 
		"io": {
			"pop": [
				[from_id, from_slot, to_id, to_slot]
			]
		}
	}
	emit_signal("request_mind", "update_node_map", mind_update_node_map_job)
	pass

func _on_node_move_end() -> void:
	# here might be more than one node selected and moved, so...
	for node_id in _ALREADY_SELECTED_NODES_BY_ID:
		var the_node_offset_vector = _ALREADY_SELECTED_NODES_BY_ID[node_id].get_offset()
		emit_signal("request_mind", "update_node_map", {
			"id": node_id,
			"offset": Utils.vector2_to_array(the_node_offset_vector)
		})
	# because boxes moved ...
	if USE_ARROW_MINIMAP:
		Minimap.call_deferred("refresh")
	pass

func update_sellected_nodes_offset(direction:Vector2, speed: float = (self.snap_distance / 2)) -> void:
	var movement = direction * speed
	for node_id in _ALREADY_SELECTED_NODES_BY_ID:
		var current_offset = _ALREADY_SELECTED_NODES_BY_ID[node_id].get_offset()
		_ALREADY_SELECTED_NODES_BY_ID[node_id].set_offset(current_offset + movement)
	_on_node_move_end()
	pass

func clean_node_off(node_id:int = -1):
	if _DRAWN_NODES_BY_ID.has(node_id):
		# first remove connections
		# we can find them in _CONNECTION_RELATIONS
		if _CONNECTION_RELATIONS.has(node_id): # this node is connected to others:
			for direction in _CONNECTION_RELATIONS[node_id]: # directions: in, out
				for other_side_id in _CONNECTION_RELATIONS[node_id][direction]:
					for connection in _CONNECTION_RELATIONS[node_id][direction][other_side_id]:
						disconnect_nodes_by_id(connection[0], connection[1], connection[2],connection[3])
						# ... which asks core mind to update the maps as well
		# then manually trigger the unselection
		proceed_unselection_by_id(node_id)
		var node_instance = _DRAWN_NODES_BY_ID[node_id]
		_DRAWN_NODES_BY_ID.erase(node_id)
		node_instance.free()
		if USE_ARROW_MINIMAP:
			Minimap.call_deferred("refresh")
	pass

func disconnection_from_view(connection:Array) -> void:
	disconnect_from_view_by_id(connection[0], connection[1], connection[2],connection[3])
	pass

# [ auto-resizer ]

func make_auto_resize(resizing_node:Node) -> void:
	# every time a node is changed, it's redrawn so ...
	resizing_node.connect("draw", self, "shrink_to_fit", [resizing_node], CONNECT_DEFERRED)
	pass

func shrink_to_fit(resizing_node:Node) -> void:
	# find the real fit boundry (biggest x and y)
	if is_instance_valid(resizing_node):
		var real_fit = Vector2.ZERO
		for child in resizing_node.get_children():
			var child_size = child.get_size()
			if child_size.x > real_fit.x:
				real_fit.x = child_size.x
			if child_size.y > real_fit.y:
				real_fit.y = child_size.y
		# then shrink the node to that
		resizing_node.set_size(real_fit)
	pass

func resize_native_minimap() -> void:
	# to make sure the native minimap is not masked by inspector
	self.set_minimap_size(
		Vector2(
			self.get_size().x - 10, # (with a gap to make sure the resize handle is visible)
			(self.get_size().y / 4)
		)
	)
	pass

func update_zoom(magnitude: float, direction: bool) -> void:
	var current_zoom = self.get("zoom");
	var zoom_direction = ( 1 if direction else -1 )
	var new_zoom = current_zoom + (
		magnitude * zoom_direction *
		Settings.ZOOM_ENHANCEMENT_FACTOR
	)
	if new_zoom != current_zoom:
		self.set("zoom", new_zoom)
	pass

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		# Without Modifiers
		# > Press
		if event.is_echo() == false && event.is_pressed() == true:
			match event.get_scancode():
				KEY_DELETE:
					request_mind("clean_clipboard", null)
					if _ALREADY_SELECTED_NODE_IDS.size() != 0:
						if Main.Mind.batch_remove_resources(_ALREADY_SELECTED_NODE_IDS, "nodes", true, true): # check-only
							request_mind("remove_selected_nodes", null)
		# With Modifiers
		if event.get_control():
			# > Press
			if event.is_echo() == false && event.is_pressed() == true:
				match event.get_scancode():
					KEY_C:
						request_mind("clean_clipboard", null)
						if _ALREADY_SELECTED_NODE_IDS.size() != 0:
							request_mind("clipboard_push_selection", CLIPBOARD_MODE.COPY)
					KEY_X:
						request_mind("clean_clipboard", null)
						if _ALREADY_SELECTED_NODE_IDS.size() != 0:
							request_mind("clipboard_push_selection", CLIPBOARD_MODE.CUT)
					KEY_V:
						request_mind("clipboard_pull", offset_from_position( self.get_local_mouse_position() ) )
			# > Echo
			match event.get_scancode():
				KEY_KP_ADD:
					update_zoom(1, true)
				KEY_KP_SUBTRACT:
					update_zoom(1, false)
				KEY_KP_0:
					self.set("zoom", DEFAULT_ZOOM)
				KEY_0:
					self.set("zoom", DEFAULT_ZOOM)
				KEY_EQUAL:
					update_zoom(1, true)
				KEY_PLUS:
					update_zoom(1, true)
				KEY_MINUS:
					update_zoom(1, false)
				KEY_UP:
					update_sellected_nodes_offset(Vector2.UP)
				KEY_DOWN:
					update_sellected_nodes_offset(Vector2.DOWN)
				KEY_LEFT:
					update_sellected_nodes_offset(Vector2.LEFT)
				KEY_RIGHT:
					update_sellected_nodes_offset(Vector2.RIGHT)
	pass

func _process(delta):
	# Because there is no event for godot built-in minimap being activated
	MinimapBox.set_visible( ! self.is_minimap_enabled() )
	pass
