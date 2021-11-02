# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Minimap (Drawing)
extends Control

onready var TheTree = get_tree()
onready var Main = TheTree.get_root().get_child(0)
onready var Grid = get_node(Addressbook.GRID)
onready var MinimapBox = get_parent()

const PANEL_OPACITY_MODULATION_COLOR_HIDE = Settings.MINIMAP_PANEL_OPACITY_MODULATION_COLOR_HIDE
const PANEL_OPACITY_MODULATION_COLOR_SHOW = Settings.MINIMAP_PANEL_OPACITY_MODULATION_COLOR_SHOW
const DEFAULT_NODE_DRAWING_COLOR = Settings.MINIMAP_DEFAULT_NODE_DRAWING_COLOR
const CROSSHAIR_COLOR = Settings.MINIMAP_CROSSHAIR_COLOR
const CROSSHAIR_COLOR_OUT_OF_BOUND = Settings.MINIMAP_CROSSHAIR_COLOR_OUT_OF_BOUND
const CROSSHAIR_WIDTH = Settings.MINIMAP_CROSSHAIR_WIDTH

var _CURRENT_MINIMAP_OPACITY_STATE:bool = false

var _DRAWING_BY_ID:Dictionary = {}
var _MINIMAP_SIZE:Vector2
var _GRID_TO_MINIMAP_RATIO:Vector2
var _CORNER_ADJUSTMENT:Vector2
var _CROSSHAIR:Vector2 = Vector2(0,0)
var _CROSSHAIR_COLOR:Dictionary = { "x": CROSSHAIR_COLOR, "y": CROSSHAIR_COLOR }
var _ALREADY_SET_FOR_UPDATE:bool = false

func _ready() -> void:
	register_connections()
	toggle_opacity(false)
	pass

func register_connections() -> void:
	TheTree.connect("screen_resized", self, "refresh", [], CONNECT_DEFERRED)
	Grid.connect("scroll_offset_changed", self, "set_crosshair", [], CONNECT_DEFERRED)
	self.connect("mouse_entered", self, "toggle_opacity", [true], CONNECT_DEFERRED)
	self.connect("mouse_exited", self, "toggle_opacity", [false], CONNECT_DEFERRED)
	self.connect("gui_input", self, "_on_gui_input", [], CONNECT_DEFERRED)
	pass
	
func _draw() -> void:
	# crosshair
	# (values less than 0 for x or y means out of boundries)
	if _CROSSHAIR.x >= 0:
		draw_line( Vector2(_CROSSHAIR.x, _CROSSHAIR.y), Vector2(_CROSSHAIR.x, _MINIMAP_SIZE.y), _CROSSHAIR_COLOR.x, CROSSHAIR_WIDTH)
	if _CROSSHAIR.y >= 0:
		draw_line( Vector2(_CROSSHAIR.x, _CROSSHAIR.y), Vector2(_MINIMAP_SIZE.x, _CROSSHAIR.y), _CROSSHAIR_COLOR.y, CROSSHAIR_WIDTH)
	# nodes (boxes on the map)
	for node_id in _DRAWING_BY_ID:
		var box = _DRAWING_BY_ID[node_id]
		var rect_position = (box.offset - _CORNER_ADJUSTMENT) * _GRID_TO_MINIMAP_RATIO
		var rect_size = ( box.size * _GRID_TO_MINIMAP_RATIO )
		draw_rect(Rect2(rect_position, rect_size), box.color, true)
	# reset the flag
	_ALREADY_SET_FOR_UPDATE = false
	pass

func refresh() -> void:
	_DRAWING_BY_ID.clear()
	var visible_grid_size = Grid.get_size()
	var corners = { "top": 0, "left": 0, "right": visible_grid_size.x, "bottom": visible_grid_size.y }
	for node in Grid.get_children():
		if node is GraphNode:
			var node_id = node._node_id
			var color
			if node._node_resource.data.has("color") && node._node_resource.data.color is String:
				color = Color(node._node_resource.data.color)
			var size = node.get_size()
			var offset = node.get_offset()
			_DRAWING_BY_ID[node_id] = {
				"offset": offset, "size": size,
				"color": (color if color is Color else DEFAULT_NODE_DRAWING_COLOR)
			}
			if offset.y < corners.top:
				corners.top = offset.y
			if offset.x < corners.left:
				corners.left = offset.x
			if (offset.y + size.y) > corners.bottom:
				corners.bottom = (offset.y + size.y)
			if (offset.x + size.x) > corners.right:
				corners.right = (offset.x + size.x)
	_MINIMAP_SIZE = self.get_size()
	var full_grid_size = Vector2((abs(corners.right) + abs(corners.left)), (abs(corners.bottom) + abs(corners.top)))
	_GRID_TO_MINIMAP_RATIO = (_MINIMAP_SIZE / full_grid_size)
	_CORNER_ADJUSTMENT = Vector2(corners.left, corners.top)
	set_crosshair()
	set_for_update()
	pass

func set_crosshair(offset = null) -> void:
	if (offset is Vector2) == false:
		offset = Grid.get_scroll_ofs()
	_MINIMAP_SIZE = self.get_size()
	_CROSSHAIR = ((offset - _CORNER_ADJUSTMENT)) * _GRID_TO_MINIMAP_RATIO
	# clamp crosshair to bounds
	for axis in ["x", "y"]:
		if _CROSSHAIR[axis] < 0 || _CROSSHAIR[axis] > _MINIMAP_SIZE[axis]:
			if _CROSSHAIR[axis] < 0 :
				_CROSSHAIR[axis] = 0
			if _CROSSHAIR[axis] > _MINIMAP_SIZE[axis] :
				_CROSSHAIR[axis] = _MINIMAP_SIZE[axis]
			_CROSSHAIR_COLOR[axis] = CROSSHAIR_COLOR_OUT_OF_BOUND
		else:
			_CROSSHAIR_COLOR[axis] = CROSSHAIR_COLOR
	set_for_update()
	pass

func set_for_update():
	if _ALREADY_SET_FOR_UPDATE == false:
		self.call_deferred( "update" )
		_ALREADY_SET_FOR_UPDATE = true
	pass

func toggle_visibility(force = null) -> void:
	var visibility = ( force if (force is bool) else (! self.is_visible()))
	self.set_visible(visibility)
	pass

func toggle_opacity(force = null):
	_CURRENT_MINIMAP_OPACITY_STATE = ( force if (force is bool) else (!_CURRENT_MINIMAP_OPACITY_STATE))
	var modulation_color = (PANEL_OPACITY_MODULATION_COLOR_SHOW if _CURRENT_MINIMAP_OPACITY_STATE else PANEL_OPACITY_MODULATION_COLOR_HIDE)
	MinimapBox.set("modulate", modulation_color)
	pass

func _on_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton || event is InputEventMouseMotion:
		handle_mouse_gui_inputs(event.get_position())
	pass

func handle_mouse_gui_inputs(mouse_position:Vector2) -> void:
	var is_left_click = (Input.is_mouse_button_pressed(BUTTON_LEFT) )
	var is_right_click = (Input.is_mouse_button_pressed(BUTTON_RIGHT) )
	
	if is_left_click || is_right_click: # (we don't want this on scroll (middle button))
		var offset_from_click = (mouse_position / _GRID_TO_MINIMAP_RATIO) + _CORNER_ADJUSTMENT
		# ask grid to go to the offset respective to the point selected on the minimap
		Grid.call_deferred("got_to_offset", offset_from_click, is_left_click) # jump point will be enhanced/centered on left-click
		self.call_deferred("set_crosshair")
	pass
