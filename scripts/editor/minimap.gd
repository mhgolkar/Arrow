# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Minimap (Drawing)
extends Control

@onready var TheTree = get_tree()
@onready var TheViewport = get_viewport()
@onready var Main = TheTree.get_root().get_child(0)
@onready var Grid = $/root/Main/Editor/Center/Grid
@onready var MinimapBox = get_parent()

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
	TheViewport.size_changed.connect(self.refresh, CONNECT_DEFERRED)
	Grid.scroll_offset_changed.connect(self.set_crosshair, CONNECT_DEFERRED)
	self.mouse_entered.connect(self.toggle_opacity.bind(true), CONNECT_DEFERRED)
	self.mouse_exited.connect(self.toggle_opacity.bind(false), CONNECT_DEFERRED)
	self.gui_input.connect(self._on_gui_input, CONNECT_DEFERRED)
	pass
	
func _draw() -> void:
	# crosshair
	# (values less than 0 for x or y means out of boundaries)
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
			var node_color
			if node._node_resource.data.has("color") && node._node_resource.data.color is String:
				node_color = Helpers.Utils.rgba_hex_to_color(node._node_resource.data.color)
			var node_size = node.get_size()
			var node_offset = node.get_position_offset()
			_DRAWING_BY_ID[node_id] = {
				"offset": node_offset,
				"size": node_size,
				"color": (node_color if node_color is Color else DEFAULT_NODE_DRAWING_COLOR)
			}
			if node_offset.y < corners.top:
				corners.top = node_offset.y
			if node_offset.x < corners.left:
				corners.left = node_offset.x
			if (node_offset.y + node_size.y) > corners.bottom:
				corners.bottom = (node_offset.y + node_size.y)
			if (node_offset.x + node_size.x) > corners.right:
				corners.right = (node_offset.x + node_size.x)
	_MINIMAP_SIZE = self.get_size()
	var full_grid_size = Vector2((abs(corners.right) + abs(corners.left)), (abs(corners.bottom) + abs(corners.top)))
	_GRID_TO_MINIMAP_RATIO = (_MINIMAP_SIZE / full_grid_size)
	_CORNER_ADJUSTMENT = Vector2(corners.left, corners.top)
	set_crosshair()
	set_for_update()
	pass

func set_crosshair(offset = null) -> void:
	if (offset is Vector2) == false:
		offset = Grid.get_scroll_offset()
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
		self.queue_redraw()
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
		handle_seek(event)
	pass

func handle_seek(event:InputEventMouse) -> void:
	var exact = (Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))
	var adjusted = (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) || Input.is_key_pressed(KEY_ALT))
	# ask grid to go to the offset respective to the point selected on the minimap
	if exact || adjusted:
		var mouse_position = event.get_position()
		var offset_from_click = (mouse_position / _GRID_TO_MINIMAP_RATIO) + _CORNER_ADJUSTMENT
		# jump point will be enhanced/centered on adjusted mode
		# and we don't reset zoom anyway to have a smoother seek
		Grid.call_deferred("got_to_offset", offset_from_click, adjusted, false)
		self.call_deferred("set_crosshair")
	pass
