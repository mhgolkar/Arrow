# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Inspector :: Node Tab
extends Tabs

signal relay_request_mind

onready var Main = get_tree().get_root().get_child(0)
onready var Grid = get_node(Addressbook.GRID)

var NODE_TYPES_LIST_CACHE

var _CURRENT_INSPECTED_NODE_RESOURCE_ID:int = -1
var _CURRENT_INSPECTED_NODE
var _CURRENT_INSPECTED_NODE_MAP
var _CURRENT_INSPECTED_NODE_USECASES

var SUB_INSPCETORS
var _LAST_OPEN_SUB_INSPECTOR
var _CURRENT_STATE_OF_SUB_INSPECTOR_BLOCKER = true

var USECASES_MENU_BUTTON_TEXT_TEMPLATE = "%s Usecase(s)"

onready var SubInspcetorBlockerMessage = get_node(Addressbook.INSPECTOR.NODE.SUB_INSPECTOR_BLOCKER_MESSAGE)
# properties
onready var InspectorNodeProperties = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.itself)
	# head
onready var NodeTypeLabel = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_TYPE_LABEL)
onready var NodeUidEdit = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_UID_EDIT)
onready var NodeIsSkipedCheck = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_IS_SKIPED_CHECK)
onready var NodeUseCasesList = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_USECASES_MENU_BUTTON)
onready var NodeUseCasesListPopUp = NodeUseCasesList.get_popup()
	# body
onready var SubInspectorHolder =  get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.SUB_INSPECTOR_HOLDER)
	# notes
onready var NodeNotesEdit = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_NOTES_EDIT)
# node tools
onready var UpdateNodeButton = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_TOOLS.UPDATE_BUTTON)
onready var ResetNodeParamsButton = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_TOOLS.RESET_BUTTON)
onready var FocusNodeButton = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_TOOLS.FOCUS_BUTTON)

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	NodeIsSkipedCheck.connect("toggled", self, "toggle_node_skip", [], CONNECT_DEFERRED)
	UpdateNodeButton.connect("pressed", self, "read_and_update_inspected_node", [], CONNECT_DEFERRED)
	ResetNodeParamsButton.connect("pressed", self, "reset_inspection", [], CONNECT_DEFERRED)
	FocusNodeButton.connect("pressed", self, "focus_grid_on_inspected", [], CONNECT_DEFERRED)
	NodeUseCasesListPopUp.connect("id_pressed", self, "_request_locating_node_by_id", [], CONNECT_DEFERRED)
	pass

func initialize_tab() -> void:
	block_node_tab()
	pass

func refresh_tab() -> void:
	refresh_sub_inspector_for_current_node()
	pass

func setup_node_type_sub_inspectors(node_type_list:Dictionary) -> void:
	NODE_TYPES_LIST_CACHE = node_type_list
	SUB_INSPCETORS = {}
	for node_type in NODE_TYPES_LIST_CACHE:
		var node_type_data = NODE_TYPES_LIST_CACHE[node_type]
		var the_sub_inspector = node_type_data.inspector.instance()
		the_sub_inspector.set("visible", false)
		SubInspectorHolder.add_child(the_sub_inspector)
		SUB_INSPCETORS[ node_type_data.type ] = the_sub_inspector
	pass

func block_node_tab() -> void:
	toggle_sub_inspector_block(true)
	if _LAST_OPEN_SUB_INSPECTOR != null:
		_LAST_OPEN_SUB_INSPECTOR.set_deferred("visible", false)
		_LAST_OPEN_SUB_INSPECTOR = null
	pass

func toggle_sub_inspector_block(force = null) -> void:
	var new_status = force if (force is bool) else (! _CURRENT_STATE_OF_SUB_INSPECTOR_BLOCKER)
	SubInspcetorBlockerMessage.set_deferred("visible", new_status)
	InspectorNodeProperties.set_deferred("visible", (!new_status))
	_CURRENT_STATE_OF_SUB_INSPECTOR_BLOCKER = new_status
	pass

func update_node_tab(node_id:int, node:Dictionary, node_map:Dictionary) -> void:
	# keep a reference to it for later update requests to the mind,
	_CURRENT_INSPECTED_NODE = node
	_CURRENT_INSPECTED_NODE_MAP = node_map
	_CURRENT_INSPECTED_NODE_RESOURCE_ID = node_id
	# inspect the node
	update_usecases_list()
	var the_sub_inspector = SUB_INSPCETORS[node.type]
	update_parameters(node_id, node, node_map, the_sub_inspector)
	# keep track of the last open sub-inspector
	if _LAST_OPEN_SUB_INSPECTOR != null:
		_LAST_OPEN_SUB_INSPECTOR.set_deferred("visible", false)
	else:
		toggle_sub_inspector_block(false)
	the_sub_inspector.set_deferred("visible", true)
	_LAST_OPEN_SUB_INSPECTOR = the_sub_inspector
	pass

func update_parameters(node_id:int, node:Dictionary, node_map:Dictionary, sub_inspector = null) -> void:
	# head
	NodeTypeLabel.set_deferred("text", NODE_TYPES_LIST_CACHE[node.type].text)
	NodeUidEdit.set_deferred("text", node.name)
	# skip
	var is_node_skip = ( true if (node_map.has("skip") && node_map.skip == true ) else false )
	toggle_node_skip(is_node_skip, false)
	# notes
	NodeNotesEdit.set_deferred("text", (node.notes if node.has("notes") else ""))
	# update sub-inspector
	var the_sub_inspector = sub_inspector if (sub_inspector is Node) else SUB_INSPCETORS[node.type]
	the_sub_inspector.call_deferred("_update_parameters", node_id, node.duplicate(true))
	pass
	
func refresh_sub_inspector_for_current_node():
	if _CURRENT_STATE_OF_SUB_INSPECTOR_BLOCKER == false:
		if _CURRENT_INSPECTED_NODE_RESOURCE_ID >= 0: # and there is a node open
			# naturally the respective sub-inspector shall be open as well
			# so call for update
			_LAST_OPEN_SUB_INSPECTOR.call_deferred("_update_parameters", _CURRENT_INSPECTED_NODE_RESOURCE_ID, _CURRENT_INSPECTED_NODE.duplicate(true))
	pass
	
func read_and_validate_node_name():
	var validated_name = null
	if _CURRENT_INSPECTED_NODE is Dictionary:
		var already = _CURRENT_INSPECTED_NODE.name
		var updated = NodeUidEdit.get_text()
		if updated != already:
			if Main.Mind.is_node_name_available(updated) == true:
				validated_name = updated
	return validated_name

func read_and_update_inspected_node() -> void:
	# the central mind may call this (e.g. on key-shortcuts) even when inspector is hidden,
	# so we shall first check ... 
	if _CURRENT_INSPECTED_NODE_RESOURCE_ID >= 0 && _LAST_OPEN_SUB_INSPECTOR:
		var resource_updater = {
			"id": _CURRENT_INSPECTED_NODE_RESOURCE_ID, 
			"modification": {
				"data": _LAST_OPEN_SUB_INSPECTOR._read_parameters()
			},
			"field": "nodes"
		}
		# name change ?
		var valid_updated_name = read_and_validate_node_name()
		if valid_updated_name is String && valid_updated_name.length() > 0:
			resource_updater.modification["name"] = valid_updated_name
		# note change ?
		var notes = NodeNotesEdit.get_text()
		if notes.length() > 0:
			if _CURRENT_INSPECTED_NODE.has("notes") == false || notes != _CURRENT_INSPECTED_NODE.notes:
				resource_updater.modification["notes"] = notes
		elif _CURRENT_INSPECTED_NODE.has("notes"): 
			resource_updater.modification["notes"] = null # means drop/erase notes
		# send update request
		self.emit_signal("relay_request_mind", "update_resource", resource_updater)
	pass

# Note: this function might be called by scripts or due to ui signals
func toggle_node_skip(change:bool, send_request:bool = false) -> void:
	# update ui ?
	if change != NodeIsSkipedCheck.is_pressed():
		NodeIsSkipedCheck.set_pressed(change)
	# send update request ?
	elif send_request == true || ((_CURRENT_INSPECTED_NODE_MAP.has("skip") && _CURRENT_INSPECTED_NODE_MAP.skip != change) || (_CURRENT_INSPECTED_NODE_MAP.has("skip") == false && change == true)):
		self.emit_signal("relay_request_mind", "update_node_map", { "id": _CURRENT_INSPECTED_NODE_RESOURCE_ID, "skip": change })
		# manually track the update, because we won't get map update from mind here
		_CURRENT_INSPECTED_NODE_MAP.skip = change
	pass

func reset_inspection() -> void:
	if _CURRENT_INSPECTED_NODE_RESOURCE_ID >= 0 :
		# `inspect_node` request will make the central mind to refresh the tab with saved project data
		emit_signal("relay_request_mind", "inspect_node", _CURRENT_INSPECTED_NODE_RESOURCE_ID)
	pass

func focus_grid_on_inspected() -> void:
	if _CURRENT_INSPECTED_NODE_RESOURCE_ID >= 0 :
		Grid.call_deferred("go_to_offset_by_node_id", _CURRENT_INSPECTED_NODE_RESOURCE_ID, true)
	pass

func update_usecases_list(node_id:int = _CURRENT_INSPECTED_NODE_RESOURCE_ID) -> void:
	NodeUseCasesListPopUp.clear()
	_CURRENT_INSPECTED_NODE_USECASES = Main.Mind.list_usecases(node_id)
	var usecases_size = _CURRENT_INSPECTED_NODE_USECASES.size()
	if usecases_size > 0 :
		NodeUseCasesList.set_visible(true)
		NodeUseCasesList.set_text(USECASES_MENU_BUTTON_TEXT_TEMPLATE % usecases_size)
		for user_node_id in _CURRENT_INSPECTED_NODE_USECASES:
			var user_node_name = _CURRENT_INSPECTED_NODE_USECASES[user_node_id]
			NodeUseCasesListPopUp.add_item(user_node_name, user_node_id)
	else:
		NodeUseCasesList.set_visible(false)
	pass

func _request_locating_node_by_id(node_id:int) -> void:
	emit_signal("relay_request_mind", "locate_node_on_grid", {
		"id": node_id,
		"highlight": true,
		"force": true, # ... to change open scene
	})
	pass
