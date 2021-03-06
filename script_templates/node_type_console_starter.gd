# Arrow
# Game Narrative Design Tool
# % contributor(s) %

# % Custom % Node Type Console
extends %BASE%

# this signal will tell console which node (id:int) and slot (idx:int) shall be played next
signal play_forward

# this signal tells the console that something special has happend, including:
# CONSOLE_STATUS_CODE
	# END_EDGE  : outgoing slot connects to no other node
	# NO_DEFAULT : no default action is taken (e.g. due to being skipped)
signal status_code

# nodes can ask to be printed on clean console
# warning-ignore:unused_signal
signal clear_up

# nodes can (re-)set one or some variables
# by signaling a list of { variable_id<int> : new_value<variant> ,...}
# The existing states of variables are sent in `setup_play` as a dictionary of `{ var_uid: resource_data, ... }`
# warning-ignore:unused_signal
signal reset_variable

# reference to `Main` (root)
onready var Main = get_tree().get_root().get_child(0)

# will automatically play the next node (if there is any connection) or END_EDGE
# -1 means no auto-play
const AUTO_PLAY_SLOT = -1

# cache
var _NODE_ID:int
var _NODE_RESOURCE:Dictionary
var _NODE_MAP:Dictionary
var _NODE_SLOTS_MAP:Dictionary

# the node (element) itself
var This = self
var _PLAY_IS_SET_UP:bool = false
var _NODE_IS_READY:bool = false
var _DEFERRED_VIEW_PLAY_SLOT:int = -1

# children
# onready var CONSOLE_CHILD_X = get_node("./X")

# called when the node enters the scene tree for the first time
func _ready()%VOID_RETURN%:
	register_connections()
	_NODE_IS_READY = true
	if _PLAY_IS_SET_UP:
		setup_view()
	if _DEFERRED_VIEW_PLAY_SLOT >= 0:
		set_view_played(_DEFERRED_VIEW_PLAY_SLOT)
	pass

func register_connections()%VOID_RETURN%:
	# e.g. CONSOLE_CHILD_X.connect("the_signal", self, "_on_self_signal_handler", [], CONNECT_DEFERRED)
	pass
	
func remap_connections_for_slots(map:Dictionary = _NODE_MAP, this_node_id:int = _NODE_ID)%VOID_RETURN%:
	if map.has("io") && map.io is Array:
		for connection in map.io:
			# <connection>[ from_id, from_slot, to_id, to_slot ]
			if connection.size() >= 4 && connection[0] == this_node_id:
				_NODE_SLOTS_MAP[ connection[1] ] = { "id": connection[2], "slot": connection[3] }
	pass

# update view parts, normally called right after instancing via setup_play
func setup_view()%VOID_RETURN%:
	# TODO ...
	pass
	
# this function is called by the parent console to customize this instance for the respective node resource data
func setup_play(node_id:int, node_resource:Dictionary, node_map:Dictionary, _playing_in_slot:int = -1, _variables_current:Dictionary={})%VOID_RETURN%:
	_NODE_ID = node_id
	_NODE_RESOURCE = node_resource
	_NODE_MAP = node_map
	remap_connections_for_slots()
	# update fields and parts
	if _NODE_IS_READY:
		setup_view()
	# handle skip in case
	if _NODE_MAP.has("skip") && _NODE_MAP.skip == true:
		skip_play()
	# otherwise auto-play if set
	elif AUTO_PLAY_SLOT >= 0:
		play_forward_from(AUTO_PLAY_SLOT)
	_PLAY_IS_SET_UP = true
	pass

func play_forward_from(slot_idx:int = AUTO_PLAY_SLOT)%VOID_RETURN%:
	if slot_idx >= 0:
		if _NODE_SLOTS_MAP.has(slot_idx):
			var next = _NODE_SLOTS_MAP[slot_idx]
			self.emit_signal("play_forward", next.id, next.slot)
		else:
			emit_signal("status_code", CONSOLE_STATUS_CODE.END_EDGE)
		set_view_played_on_ready(slot_idx)
	pass

func set_view_played_on_ready(slot_idx:int) -> void:
	if _NODE_IS_READY:
		set_view_played(slot_idx)
	else:
		_DEFERRED_VIEW_PLAY_SLOT = slot_idx
	pass

# change view as if the node has never been played
func set_view_unplayed()%VOID_RETURN%:
	# TODO ?
		# remove newly made fields
		# and/or (re-)setup view fields
			# setup_view()
	pass

# change view to what indicates the node is played
# normally called after auto-play or some interactions by the user
func set_view_played(slot_idx:int = AUTO_PLAY_SLOT)%VOID_RETURN%:
	# TODO ?
	pass

func skip_play()%VOID_RETURN%:
	# TODO ?
	pass

# resets the view and other variables as if the node has not been played
# called when users go backwards in the parent console to debug the narrative or try different decisions
# this is why it's recommended to design node types so even auto-play ones can be manually (re-)played
func step_back()%VOID_RETURN%:
	set_view_unplayed()
	pass
	
