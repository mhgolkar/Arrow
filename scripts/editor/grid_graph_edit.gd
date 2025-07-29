# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Grid
extends GraphEdit

signal request_mind()

@onready var TheTree = get_tree() 
@onready var Main = TheTree.get_root().get_child(0)
@onready var TheViewport = get_viewport()
@onready var GridContextMenu = $/root/Main/FloatingTools/Control/Context

@onready var Minimap = $/root/Main/Editor/Center/MiniMap/Area
@onready var MinimapBox = Minimap.get_parent()
const USE_ARROW_MINIMAP:bool = Settings.CLASSIC_MINIMAP_ENABLED

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

var _VARIATION_AFFIXES
var _HIGHLIGHTED_NODES = []

func _ready() -> void:
	DEFAULT_ZOOM = self.get('zoom')
	_VARIATION_AFFIXES = [Settings.NODE_THEME_VARIATION_AFFIX_FLICK]
	_VARIATION_AFFIXES.append_array(Settings.NODE_THEME_VARIATION_AFFIX_HIGHLIGHT.values())
	# ...
	register_connections()
	setup_valid_connection_types()
	# classic minimap ?
	if USE_ARROW_MINIMAP :
		MinimapBox.set_visible( ! self.is_minimap_enabled() )
	else:
		self.set_minimap_enabled(true)
	pass

func register_connections() -> void:
	self.popup_request.connect(self._on_popup_request, CONNECT_DEFERRED)
	self.connection_to_empty.connect(self._on_connection_with_empty.bind(true), CONNECT_DEFERRED )
	self.connection_from_empty.connect(self._on_connection_with_empty.bind(false), CONNECT_DEFERRED )
	self.node_selected.connect(self._on_node_selection, CONNECT_DEFERRED)
	self.node_deselected.connect(self._on_node_deselection, CONNECT_DEFERRED)
	self.connection_request.connect(self._on_connection_request, CONNECT_DEFERRED )
	self.disconnection_request.connect(self._on_disconnection_request, CONNECT_DEFERRED )
	self.end_node_move.connect(self._on_node_move_end, CONNECT_DEFERRED )
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

func _request_mind(req:String, args) -> void:
	self.request_mind.emit(req, args)
	pass

func offset_from_position(local_pose:Vector2) -> Vector2:
	# scroll offset of a GraphEdit is the offset of the visible top left corner
	var sc_offset = self.get_scroll_offset()
	# position is also relative to the top left corner of the parent (visible part), therefore:
	var grid_offset_of_position = (sc_offset + local_pose) / self.get_zoom()
	return grid_offset_of_position

func current_mouse_offset() -> Vector2:
	return offset_from_position( self.get_local_mouse_position() )

# (right-click on the grid)
func _on_popup_request(_p = null) -> void:
	var local = self.get_local_mouse_position()
	var global = self.get_global_mouse_position()
	GridContextMenu.call_deferred("show_up", global, offset_from_position(local))
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

func get_nodes_in(boundary: Rect2, return_id:bool = false, return_first:bool = false) -> Array:
	var nodes_in_boundary = []
	for node_id in _DRAWN_NODES_BY_ID:
		var node = _DRAWN_NODES_BY_ID[node_id]
		if (
			is_instance_valid(node) &&
			boundary.encloses( node.get_global_rect() )
		):
			nodes_in_boundary.append(
				node_id
				if return_id == true
				else
				{ "id": node_id, "node": node }
			)
			if return_first:
				return nodes_in_boundary
	return nodes_in_boundary

func select_all_in(boundary: Rect2) -> void:
	var nodes_in_boundary = get_nodes_in(boundary)
	for each in nodes_in_boundary:
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
			# We try to connect to the first target ...
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
		if Input.is_key_pressed(KEY_SHIFT): # Branch selection it is
			var with_waterfall = Input.is_key_pressed(KEY_ALT)
			self._request_mind.call_deferred(
				"branch_selection",
				[_ALREADY_SELECTED_NODE_IDS.duplicate(true), the_node_id, with_waterfall]
			)
		else: # Normal selection
			_request_mind("node_selection", the_node_id)
			select_node_by_id(the_node_id)
	else:
		_request_mind("inspect_node", the_node_id)
	pass

func force_unselect_all():
	_ALREADY_SELECTED_NODE_IDS.clear()
	_ALREADY_SELECTED_NODES_BY_ID.clear()
	set_selected(null)
	pass

func force_select_group(list: Array, clear: bool = false) -> void:
	if clear:
		force_unselect_all()
	await TheTree.process_frame
	for node_id in list:
		select_node_by_id(node_id)
	pass
	
func select_node_by_id(node_id:int, unselect_others:bool = false, go_to:bool = false) -> void:
	if unselect_others:
		force_unselect_all()
	if _DRAWN_NODES_BY_ID.has(node_id):
		_DRAWN_NODES_BY_ID[node_id].set_selected(true)
		if _ALREADY_SELECTED_NODE_IDS.has(node_id) == false:
			_ALREADY_SELECTED_NODE_IDS.push_back(node_id)
			_ALREADY_SELECTED_NODES_BY_ID[node_id] = _DRAWN_NODES_BY_ID[node_id]
		if go_to == true:
			go_to_offset_by_node_id(node_id)
	else:
		print_stack()
		printerr("Unexpected Behavior! Trying to select a grid node = %s that is not drawn!" % node_id)
	pass

func _on_node_deselection(node) -> void:
	if node != null:
		proceed_deselection_by_id(node._node_id)
	pass

func proceed_deselection_by_id(node_id:int) -> void:
	if _ALREADY_SELECTED_NODES_BY_ID.has(node_id):
		_request_mind("node_deselection", node_id)
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
	# ... is necessary here because refreshing item list (filtering) won't happen unless there is a user action
	# this is why we did it manually here.
	pass

func got_to_offset(destination, auto_adjust:bool = false, reset_zoom:bool = true) -> void:
	if destination is Array:
		destination = Helpers.Utils.array_to_vector2(destination)
	if destination is Vector2:
		if auto_adjust:
			if reset_zoom:
				self.set_zoom(1)
			var adjustment = ( self.get_size() * Settings.GRID_GO_TO_AUTO_ADJUSTMENT_FACTOR )
			destination = (destination - adjustment).floor()
		self.call_deferred("set_scroll_offset", destination)
	if USE_ARROW_MINIMAP:
		Minimap.call_deferred("set_crosshair")
	pass

func go_to_offset_by_node_id(node_id:int, flick:bool = false) -> void:
	await TheTree.process_frame
	if _DRAWN_NODES_BY_ID.has(node_id):
		got_to_offset( _DRAWN_NODES_BY_ID[node_id].get_position_offset() , true)
		if flick:
			flick_node(node_id)
	pass

# If any affix is null, it would be left unchanged, otherwise it would be set or unset depending on the flag.
func _theme_variation_affix(node: Control, flick = null, highlight = null) -> void:
	var current_variation = node.get_theme_type_variation()
	var pure_variation = current_variation
	for styling_keyword in _VARIATION_AFFIXES:
		pure_variation = pure_variation.replace(styling_keyword, "")
	var flicking = (
		Settings.NODE_THEME_VARIATION_AFFIX_FLICK
		if (flick if flick is bool else current_variation.contains(Settings.NODE_THEME_VARIATION_AFFIX_FLICK))
		else ""
	)
	var highlighting = ""
	for mode in Settings.NODE_THEME_VARIATION_AFFIX_HIGHLIGHT:
		if (
			highlight == mode ||
			(highlight == null && current_variation.contains(Settings.NODE_THEME_VARIATION_AFFIX_HIGHLIGHT[mode]))
		):
			highlighting = Settings.NODE_THEME_VARIATION_AFFIX_HIGHLIGHT[mode]
			break
	# DEV: Set with the order kept to ease theming
	node.set_theme_type_variation(pure_variation + flicking + highlighting)
	pass

func flick_node(node_id: int = -1, fade_out: float = Settings.NODE_FLICK_FADE_TIME_OUT) -> void:
	if node_id is int && node_id >= 0 && _DRAWN_NODES_BY_ID.has(node_id):
		_theme_variation_affix(_DRAWN_NODES_BY_ID[node_id], true, null)
		# ...
		# and set for auto fade out
		var flicker = TheTree.create_timer(fade_out)
		flicker.timeout.connect(self.flick_node_out.bind(node_id))
	pass

func flick_node_out(node_id: int = -1) -> void:
	if node_id is int && node_id >= 0 && _DRAWN_NODES_BY_ID.has(node_id):
		_theme_variation_affix(_DRAWN_NODES_BY_ID[node_id], false, null)
	pass

func highlight_node_on(list: Array, mode = Settings.CLIPBOARD_MODE.COPY) -> void:
	for node_id in list:
		if node_id is int && node_id >= 0 && _DRAWN_NODES_BY_ID.has(node_id):
			if _HIGHLIGHTED_NODES.has(node_id) == false:
				_HIGHLIGHTED_NODES.append(node_id)
			_theme_variation_affix(_DRAWN_NODES_BY_ID[node_id], null, mode)
	pass

func highlight_node_off(list: Array) -> void:
	for node_id in list:
		if node_id is int && node_id >= 0 && _DRAWN_NODES_BY_ID.has(node_id):
			while _HIGHLIGHTED_NODES.has(node_id):
				_HIGHLIGHTED_NODES.erase(node_id)
			_theme_variation_affix(_DRAWN_NODES_BY_ID[node_id], null, Settings.CLIPBOARD_MODE.EMPTY)
	pass
	
func highlight_nodes(list: Array, reset_others: bool = true, mode = Settings.CLIPBOARD_MODE.EMPTY) ->void:
	if reset_others:
		highlight_node_off(_HIGHLIGHTED_NODES.duplicate(true))
	highlight_node_on(list, mode)
	pass

func reset_view_to_initial() -> void:
	set_grid_view(Vector2.ZERO, Settings.GRID_INITIAL_ZOOM)
	pass

@warning_ignore("SHADOWED_VARIABLE_BASE_CLASS")
func set_grid_view(offset = null, zoom = null ) -> void:
	# Note: setting zoom and offset at the same frame, won't work as expected! hence `set_deferred` (Godot 3.2.3)
	if zoom is float || zoom is int :
		self.set("zoom", zoom )
	if offset is Vector2:
		self.set_deferred("scroll_offset", offset )
	elif offset is Array:
		var validated_offset = Helpers.Utils.array_to_vector2(offset)
		if validated_offset is Vector2:
			self.set_deferred("scroll_offset", validated_offset )
	pass

func draw_node(node_id:int, node:Dictionary, map:Dictionary, type:Dictionary) -> void:
	# print("Node Drawn: ", id, node, map, type)
	# creating the node
	var node_instance = type.node.instantiate()
	node_instance._node_id = node_id
	node_instance._node_resource = node
	# Note: Godot uses the property `name` of `Node`s to handle connections between `GraphNode`s in a `GraphEdit`
	# we will use the node id (which is fixed and unique) for this purpose and NEVER node.name because it can be edited though unique
	node_instance.set_name( (NODE_NAME_FROM_ID_PREFIX + String.num_int64( node_id)) )
	# and keeping a reference to it
	_DRAWN_NODES_BY_ID[node_id] = node_instance
	add_child(node_instance)
	update_grid_node_box(node_id, node)
	update_grid_node_map(node_instance, map)
	if map.has("io"):
		for connection in map.io:
			queue_drawing_connection(connection)
	enable_manual_inspection(node_instance)
	make_reselectable(node_instance) # DEV: Read comments on the method
	make_resizable(node_instance)
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
		resize_to_best_fit(node_instance, data_clone)
	# now that we've changed a node box, we shall update minimap too
	if USE_ARROW_MINIMAP:
		await TheTree.process_frame # wait (none-blocking) skipping one _process
		Minimap.call_deferred("refresh")
	pass

func update_grid_node_map(instance_or_id, map:Dictionary) -> void:
	var node_instance = get_node_instance(instance_or_id)
	if node_instance is Node:
		node_instance.set_deferred("position_offset", Helpers.Utils.array_to_vector2(map.offset) )
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
	# outgoing
	if _CONNECTION_RELATIONS.has(from_id) == false:
		_CONNECTION_RELATIONS[from_id] = { "in" : {}, "out": {} }
		_CONNECTION_RELATIONS_BY_ID_DIR_SLOT[from_id] = { "in" : {}, "out": {} }
	if _CONNECTION_RELATIONS[from_id]["out"].has(to_id) == false:
		_CONNECTION_RELATIONS[from_id]["out"][to_id] = []
	_CONNECTION_RELATIONS[from_id]["out"][to_id].append( [from_id, from_out_slot, to_id, to_in_slot] )
	_CONNECTION_RELATIONS_BY_ID_DIR_SLOT[from_id]["out"][from_out_slot] = [to_id, to_in_slot]
	# incoming
	if _CONNECTION_RELATIONS.has(to_id) == false:
		_CONNECTION_RELATIONS[to_id] = { "in" : {}, "out": {} }
		_CONNECTION_RELATIONS_BY_ID_DIR_SLOT[to_id] = { "in" : {}, "out": {} }
	if _CONNECTION_RELATIONS[to_id]["in"].has(from_id) == false:
		_CONNECTION_RELATIONS[to_id]["in"][from_id] = []
	_CONNECTION_RELATIONS[to_id]["in"][from_id].append( [from_id, from_out_slot, to_id, to_in_slot] )
	_CONNECTION_RELATIONS_BY_ID_DIR_SLOT[to_id]["in"][to_in_slot] = [from_id, from_out_slot]
	pass

func drop_relationship(from_id:int, from_out_slot:int, to_id:int, to_in_slot:int) -> void:
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
			_request_mind("update_node_map", mind_update_node_map_job)
	pass

func disconnect_from_view_by_id(from_id:int, from_slot:int, to_id:int, to_slot:int) -> void:
	var from_name = _DRAWN_NODES_BY_ID[ from_id ].name
	var to_name = _DRAWN_NODES_BY_ID[ to_id ].name
	disconnect_node(from_name, from_slot, to_name, to_slot)
	drop_relationship(from_id, from_slot, to_id, to_slot)
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
	_request_mind("update_node_map", mind_update_node_map_job)
	pass

func cut_off_connections(node_id: int, direction: String, last_kept: int) -> void:
	var slots = _CONNECTION_RELATIONS_BY_ID_DIR_SLOT[node_id][direction].keys()
	slots.sort()
	print_debug("cutting off ", node_id, "'s ", direction, " slots from ", slots, " up to the last one: ", last_kept)
	for order in slots:
		if order > last_kept:
			var other_side = _CONNECTION_RELATIONS_BY_ID_DIR_SLOT[node_id][direction][order]
			if direction == "in":
				disconnect_nodes_by_id(other_side[0], other_side[1], node_id, order)
			else:
				disconnect_nodes_by_id(node_id, order, other_side[0], other_side[1])
	pass

func _on_node_move_end() -> void:
	# here might be more than one node selected and moved, so...
	for node_id in _ALREADY_SELECTED_NODES_BY_ID:
		var the_node_offset_vector = _ALREADY_SELECTED_NODES_BY_ID[node_id].get_position_offset()
		_request_mind("update_node_map", {
			"id": node_id,
			"offset": Helpers.Utils.vector2_to_array(the_node_offset_vector)
		})
	# because boxes moved ...
	if USE_ARROW_MINIMAP:
		Minimap.call_deferred("refresh")
	pass

func update_selected_nodes_offset(direction:Vector2, speed = null, fast_mode = null) -> void:
	var fast_mode_factor = (10 if fast_mode is bool && fast_mode == true else (fast_mode if fast_mode is int || fast_mode is float else 1))
	@warning_ignore("INTEGER_DIVISION")
	var final_speed = (speed if speed is float else float(self.snapping_distance / 2)) * fast_mode_factor
	var movement = direction * final_speed
	for node_id in _ALREADY_SELECTED_NODES_BY_ID:
		var current_offset = _ALREADY_SELECTED_NODES_BY_ID[node_id].get_position_offset()
		_ALREADY_SELECTED_NODES_BY_ID[node_id].set_position_offset(current_offset + movement)
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
						disconnect_nodes_by_id(connection[0], connection[1], connection[2], connection[3])
						# ... which asks core mind to update the maps as well
		# then manually trigger the deselection
		proceed_deselection_by_id(node_id)
		var node_instance = _DRAWN_NODES_BY_ID[node_id]
		_DRAWN_NODES_BY_ID.erase(node_id)
		node_instance.free()
		if USE_ARROW_MINIMAP:
			Minimap.call_deferred("refresh")
	pass

func disconnection_from_view(connection:Array) -> void:
	disconnect_from_view_by_id(connection[0], connection[1], connection[2],connection[3])
	pass

func _on_node_raise_request(instance) -> void:
	if Main._AUTO_INSPECT && (_ALREADY_SELECTED_NODE_IDS.has(instance._node_id) == false || Main._RESET_ON_REINSPECTION):
		_on_node_selection(instance)
	pass

func make_reselectable(instance) -> void:
	# DEV: Godot v3.x GraphEdit nodes (grid) used to allow node re-selection.
	# In current Godot version (v4.x) the behavior is gone; so to achieve the same,
	# we piggyback on the `raise_request` signal of each node:
	instance.raise_request.connect(self._on_node_raise_request.bind(instance), CONNECT_DEFERRED)
	pass

func make_resizable(instance) -> void:
	instance.set_resizable(true)
	if false == Settings.LOCALLY_HANDLED_RESIZABLE_NODES.has(instance._node_resource.type):
		instance.draw.connect(self.resize_to_best_fit.bind(instance, instance._node_resource.data), CONNECT_DEFERRED)
		instance.resize_request.connect(self._on_resize_request.bind(instance), CONNECT_DEFERRED)
		instance.resize_end.connect(self._on_resize_end.bind(instance), CONNECT_DEFERRED)
	pass

func _on_node_gui_input(event: InputEvent, instance) -> void:
	if event is InputEventMouseButton:
		if event.is_double_click() && event.get_button_mask() == MouseButtonMask.MOUSE_BUTTON_MASK_LEFT:
			# 🡦 To avid conflict with events handled by the `node.tscn` local scripts
			if !(event.shift_pressed || event.alt_pressed || event.ctrl_pressed || event.meta_pressed):
				_on_node_selection(instance)
	pass

func enable_manual_inspection(instance) -> void:
	instance.gui_input.connect(self._on_node_gui_input.bind(instance), CONNECT_DEFERRED)
	pass

func get_min_content_bounding_box(instance) -> Vector2:
	var real_fit = Vector2.ZERO
	for child in instance.get_children():
		var child_size = child.get_size()
		if child_size.x > real_fit.x:
			real_fit.x = child_size.x
		if child_size.y > real_fit.y:
			real_fit.y = child_size.y
	return real_fit

func shrink_to_fit(instance:Node) -> void:
	if is_instance_valid(instance):
		var minimum_fit = get_min_content_bounding_box(instance)
		instance.set_deferred("size", minimum_fit)
	pass

func resize_to_best_fit(instance, data: Dictionary) -> void:
	if data.has("rect") && data.rect is Array && data.rect.size() >= 2 :
		var new_size = Helpers.Utils.array_to_vector2(data.rect)
		instance.set_deferred("size", new_size)
	else:
		shrink_to_fit(instance)
	pass

func _on_resize_request(new_size, instance) -> void:
	var min_bounding = get_min_content_bounding_box(instance)
	@warning_ignore("INCOMPATIBLE_TERNARY")
	var rect_size_array = Helpers.Utils.vector2_to_array(new_size) if new_size > min_bounding else null
	# emulate change for user to see
	instance._node_resource.data.rect = rect_size_array
	resize_to_best_fit(instance, instance._node_resource.data)
	pass

func _on_resize_end(new_size, instance) -> void:
	var rect_size_array = Helpers.Utils.vector2_to_array(new_size)
	Main.Mind.central_event_dispatcher.call(
		"update_resource",
		{
			"id": instance._node_id,
			"modification": { "data": { "rect": rect_size_array } },
			"field": "nodes",
			"auto": true,
		}
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
			match event.get_keycode():
				KEY_DELETE:
					if _ALREADY_SELECTED_NODE_IDS.size() != 0:
						var non_removables = Main.Mind.batch_remove_resources(_ALREADY_SELECTED_NODE_IDS, "nodes", true, true, true)
						if non_removables.names.size() == 0:
							_request_mind("remove_selected_nodes", null)
						else:
							Main.Mind.Notifier.call_deferred(
								"show_notification",
								"Unable to Remove!",
								(
									tr("UNABLE_TO_REMOVE_FROM_GRID") +
									tr("Non-removable(s): ") + Helpers.Utils.stringify_json(non_removables.names, "") + "\n"
								),
								[],
								Settings.CAUTION_COLOR
							)
		# With Modifiers
		if event.is_ctrl_pressed():
			# > Press
			if event.is_echo() == false && event.is_pressed() == true:
				match event.get_keycode():
					KEY_C:
						_request_mind("clean_clipboard", null)
						if _ALREADY_SELECTED_NODE_IDS.size() != 0:
							if event.is_shift_pressed():
								_request_mind("os_clipboard_push", [[], "nodes", false])
							else:
								_request_mind("clipboard_push_selection", Settings.CLIPBOARD_MODE.COPY)
					KEY_X:
						_request_mind("clean_clipboard", null)
						if _ALREADY_SELECTED_NODE_IDS.size() != 0:
							_request_mind("clipboard_push_selection", Settings.CLIPBOARD_MODE.CUT)
					KEY_V:
						if event.is_shift_pressed():
							_request_mind("os_clipboard_pull", [null, current_mouse_offset()])
						else:
							_request_mind("clipboard_pull", current_mouse_offset() )
			# > Echo
			match event.get_keycode():
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
					update_selected_nodes_offset(Vector2.UP, null, event.is_shift_pressed())
				KEY_DOWN:
					update_selected_nodes_offset(Vector2.DOWN, null, event.is_shift_pressed())
				KEY_LEFT:
					update_selected_nodes_offset(Vector2.LEFT, null, event.is_shift_pressed())
				KEY_RIGHT:
					update_selected_nodes_offset(Vector2.RIGHT, null, event.is_shift_pressed())
	pass

func _process(_delta):
	# Because there is no event for godot built-in minimap being activated
	MinimapBox.set_visible( ! self.is_minimap_enabled() )
	pass
