# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Query Toolbox
extends PanelContainer

signal request_mind

onready var Main = get_tree().get_root().get_child(0)
onready var Grid = get_node(Addressbook.GRID)

onready var QueryInput = get_node(Addressbook.QUERY.QUERY_INPUT)
onready var QuerySearchButton = get_node(Addressbook.QUERY.SEARCH_BUTTON)
onready var QueryHowOptions = get_node(Addressbook.QUERY.HOW_OPTIONS)
onready var QueryPreviousButton = get_node(Addressbook.QUERY.PREVIOUS_BUTTON)
onready var QueryMatchsOptionButton = get_node(Addressbook.QUERY.MATCHS_OPTION_BUTTON)
onready var QueryMatchsOptionButtonPopup = QueryMatchsOptionButton.get_popup()
onready var QueryNextButton = get_node(Addressbook.QUERY.NEXT_BUTTON)

const NO_ITEM_IN_MATCH_OPTIONS_TEXT = "No Match"
const MATCH_OPTION_BUTTON_TEXT_TEMPLATE = "{current} : {total} Matchs"
const MATCH_ITEM_TEXT_TEMPLATE = "{name} - {capitalized_type}"
var _QUERIED_NODES_BY_ID = {}
var _QUERIED_NODES_IDS_LIST = []
var _QUERIED_NODES_ROTATION_SIZE = 0
var _QUERIED_NODES_ROTATION_CURRENT_INDEX = -1
var _STATISTICS = { "current": 0 , "total": 0 }

# CAUTION! This should correspond to the match arms in `central_mind::query_dataset`
const HOWS = {
	1: { "text": "Any Match", "command": "any" },
	2: { "text": "Including", "command": "including" },
	3: { "text": "Exact Match", "command": "exact" },
	4: { "text": "RegEx", "command": "regexp" },
}

func _ready() -> void:
	register_connections()
	load_how_options()
	cleanup_query()
	pass

func register_connections() -> void:
	QueryInput.connect("text_entered", self, "do_query")
	QuerySearchButton.connect("pressed", self, "do_query")
	QueryMatchsOptionButtonPopup.connect("id_pressed", self, "jump_to_match_by_id")
	QueryNextButton.connect("pressed", self, "rotate_matchs", [1], CONNECT_DEFERRED)
	QueryPreviousButton.connect("pressed", self, "rotate_matchs", [-1], CONNECT_DEFERRED)
	pass


func load_how_options() -> void:
	QueryHowOptions.clear()
	for id in HOWS:
		QueryHowOptions.add_item(HOWS[id].text, id)
	pass

func do_query(string:String = "", grab_focus:bool = false) -> void:
	var what = (string if (string.length() > 0) else QueryInput.get_text())
	if what.length() > 0:
		emit_signal("request_mind", "query_nodes", {
			"what": what,
			"how": HOWS[ QueryHowOptions.get_selected_id() ].command,
			"scene": -2 # -1 means current scene, -2 or undefined means all the scenes
		})
	else:
		cleanup_query()
	if grab_focus:
		QueryInput.grab_focus()
	pass

func reset_match_statistics_text() -> void:
	QueryMatchsOptionButton.set_text(
		MATCH_OPTION_BUTTON_TEXT_TEMPLATE.format(_STATISTICS)
	)
	pass

func cleanup_query() -> void:
	_QUERIED_NODES_BY_ID.clear()
	_QUERIED_NODES_IDS_LIST.clear()
	_QUERIED_NODES_ROTATION_SIZE = 0
	_QUERIED_NODES_ROTATION_CURRENT_INDEX = -1
	_STATISTICS.total = 0
	_STATISTICS.current = 0
	reset_match_statistics_text()
	QueryMatchsOptionButtonPopup.clear()
	QueryMatchsOptionButton.set_disabled(true)
	pass

func update_query_results(nodes_dataset:Dictionary = {}) -> void:
	cleanup_query()
	_QUERIED_NODES_BY_ID = nodes_dataset
	_QUERIED_NODES_IDS_LIST = _QUERIED_NODES_BY_ID.keys()
	_STATISTICS.total = nodes_dataset.size()
	_QUERIED_NODES_ROTATION_SIZE = _STATISTICS.total
	if _STATISTICS.total > 0:
		QueryMatchsOptionButton.set_disabled(false) # ... to activate menu back after `cleanup_query`
		# update match button
		for node_id in _QUERIED_NODES_BY_ID:
			var the_node = _QUERIED_NODES_BY_ID[node_id]
			QueryMatchsOptionButtonPopup.add_item(MATCH_ITEM_TEXT_TEMPLATE.format({
					"name": the_node.name,
					"capitalized_type": the_node.type.capitalize()
				}), node_id)
	reset_match_statistics_text()
	pass

func jump_to_match_by_id(node_id:int = -1) -> void:
	if node_id >= 0:
		emit_signal("request_mind", "locate_node_on_grid", { "id": node_id, "highlight": true } )
	pass
	
func rotate_matchs(direction:int = 1) -> void:
	# move in a direction some index forward (+int) or backward (-int)
	_QUERIED_NODES_ROTATION_CURRENT_INDEX += direction
	# make sure we stay in the bound
	if _QUERIED_NODES_ROTATION_CURRENT_INDEX >= _QUERIED_NODES_ROTATION_SIZE:
		_QUERIED_NODES_ROTATION_CURRENT_INDEX = 0
	elif _QUERIED_NODES_ROTATION_CURRENT_INDEX < 0 :
		_QUERIED_NODES_ROTATION_CURRENT_INDEX = (_QUERIED_NODES_ROTATION_SIZE - 1)
	# finally jump to the index if exists
	if _QUERIED_NODES_ROTATION_CURRENT_INDEX >=0 && _QUERIED_NODES_ROTATION_CURRENT_INDEX < _QUERIED_NODES_ROTATION_SIZE:
		jump_to_match_by_id(
			_QUERIED_NODES_IDS_LIST[ _QUERIED_NODES_ROTATION_CURRENT_INDEX ]
		)
		# +1 to convert index to human readable order
		_STATISTICS.current = (_QUERIED_NODES_ROTATION_CURRENT_INDEX + 1)
	else:
		_STATISTICS.current = 0
	reset_match_statistics_text()
	pass
