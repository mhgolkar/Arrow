# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Inspector :: Node Tab
extends Tabs

signal relay_request_mind

onready var Main = get_tree().get_root().get_child(0)
onready var Grid = get_node(Addressbook.GRID)

var Utils = Helpers.Utils

var NODE_TYPES_LIST_CACHE

var _NODE_MODIFICATION_HISTORY = {}
var _CURRENT_NODE_HISTORY_ROTATION_POSE = -1
var _CURRENT_NODE_HISTORY_ROTATION_ID = -1

var _CURRENT_INSPECTED_NODE_RESOURCE_ID:int = -1
var _CURRENT_INSPECTED_NODE
var _CURRENT_INSPECTED_NODE_MAP
var _CURRENT_INSPECTED_NODE_REFERRERS

var SUB_INSPCETORS
var _LAST_OPEN_SUB_INSPECTOR
var _CURRENT_STATE_OF_SUB_INSPECTOR_BLOCKER = true

var REFERRERS_MENU_BUTTON_TEXT_TEMPLATE = "%s Referrer(s)"

onready var SubInspcetorBlockerMessage = get_node(Addressbook.INSPECTOR.NODE.SUB_INSPECTOR_BLOCKER_MESSAGE)
# properties
onready var InspectorNodeProperties = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.itself)
	# head
onready var NodeTypeLabel = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_TYPE_LABEL)
onready var NodeUidEdit = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_UID_EDIT)
onready var NodeIsSkippedCheck = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_IS_SKIPPED_CHECK)
onready var NodeReferrersList = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_REFERRERS_MENU_BUTTON)
onready var NodeReferrersListPopUp = NodeReferrersList.get_popup()
	# body
onready var SubInspectorHolder =  get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.SUB_INSPECTOR_HOLDER)
	# notes
onready var NodeNotesEdit = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_NOTES_EDIT)
# node tools
onready var UpdateNodeButton = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_TOOLS.UPDATE_BUTTON)
onready var NodeHistoryBackButton = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_TOOLS.HISTORY_BACK)
onready var ResetNodeParamsButton = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_TOOLS.RESET_BUTTON)
onready var NodeHistoryForeButton = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.NODE_TOOLS.HISTORY_FORE)
onready var FocusNodeButton = get_node(Addressbook.INSPECTOR.NODE.PROPERTIES.FOCUS_NODE_BUTTON)

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	NodeIsSkippedCheck.connect("toggled", self, "toggle_node_skip", [], CONNECT_DEFERRED)
	UpdateNodeButton.connect("pressed", self, "read_and_update_inspected_node", [], CONNECT_DEFERRED)
	ResetNodeParamsButton.connect("pressed", self, "reset_inspection", [], CONNECT_DEFERRED)
	FocusNodeButton.connect("pressed", self, "focus_grid_on_inspected", [], CONNECT_DEFERRED)
	NodeReferrersListPopUp.connect("id_pressed", self, "_request_locating_node_by_id", [], CONNECT_DEFERRED)
	NodeHistoryBackButton.connect("pressed", self, "rotate_node_history", [true], CONNECT_DEFERRED)
	NodeHistoryForeButton.connect("pressed", self, "rotate_node_history", [false], CONNECT_DEFERRED)
	pass

func initialize_tab() -> void:
	block_node_tab()
	pass

func refresh_tab() -> void:
	refresh_sub_inspector_for_current_node()
	snapshot_preview_mode_precautions()
	pass

func is_snapshot_preview() -> bool:
	return ( Main.Mind._SNAPSHOT_INDEX_OF_PREVIEW >= 0 )

func snapshot_preview_mode_precautions() -> void:
	UpdateNodeButton.set_disabled( is_snapshot_preview() )
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

func total_clean_up(keep_history:bool = false) -> void:
	block_node_tab()
	_CURRENT_INSPECTED_NODE_RESOURCE_ID = -1
	_CURRENT_INSPECTED_NODE = null
	_CURRENT_INSPECTED_NODE_MAP = null
	_CURRENT_INSPECTED_NODE_REFERRERS = null
	_LAST_OPEN_SUB_INSPECTOR = null
	_CURRENT_NODE_HISTORY_ROTATION_POSE = -1
	_CURRENT_NODE_HISTORY_ROTATION_ID = -1
	if keep_history != true:
		_NODE_MODIFICATION_HISTORY = {}
	pass

func toggle_sub_inspector_block(force = null) -> void:
	var new_status = force if (force is bool) else (! _CURRENT_STATE_OF_SUB_INSPECTOR_BLOCKER)
	SubInspcetorBlockerMessage.set_deferred("visible", new_status)
	InspectorNodeProperties.set_deferred("visible", (!new_status))
	_CURRENT_STATE_OF_SUB_INSPECTOR_BLOCKER = new_status
	pass

func update_node_tab(node_id:int, node:Dictionary, node_map:Dictionary, reset_history_rotator:bool = true) -> void:
	# keep a reference to it for later update requests to the mind,
	_CURRENT_INSPECTED_NODE = node
	_CURRENT_INSPECTED_NODE_MAP = node_map
	_CURRENT_INSPECTED_NODE_RESOURCE_ID = node_id
	# inspect the node
	update_referrers_list()
	var the_sub_inspector = SUB_INSPCETORS[node.type]
	update_parameters(node_id, node, node_map, the_sub_inspector)
	# keep track of the last open sub-inspector
	if _LAST_OPEN_SUB_INSPECTOR != null:
		_LAST_OPEN_SUB_INSPECTOR.set_deferred("visible", false)
	else:
		toggle_sub_inspector_block(false)
	the_sub_inspector.set_deferred("visible", true)
	_LAST_OPEN_SUB_INSPECTOR = the_sub_inspector
	if reset_history_rotator:
		reset_node_history_rotation(node_id)
	pass

func update_parameters(node_id:int, node:Dictionary, node_map:Dictionary, sub_inspector = null, update_sub_inspector:bool = true) -> void:
	# head
	NodeTypeLabel.set_deferred("text", NODE_TYPES_LIST_CACHE[node.type].text)
	NodeUidEdit.set_deferred("text", node.name)
	# skip
	var is_node_skip = ( true if (node_map.has("skip") && node_map.skip == true ) else false )
	toggle_node_skip(is_node_skip, false)
	# notes
	NodeNotesEdit.set_deferred("text", (node.notes if node.has("notes") else ""))
	# update sub-inspector
	if update_sub_inspector:
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

func read_and_update_inspected_node(auto:bool = false) -> void:
	if is_snapshot_preview() == false : # No update in snapshot preview mode
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
			# is it an auto update request
			if auto == true:
				resource_updater["auto"] = true
			# before pushing the modifications which will change the current state (original,) 
			track_node_modification(_CURRENT_INSPECTED_NODE_RESOURCE_ID, resource_updater.modification)
			# then send update request
			self.emit_signal("relay_request_mind", "update_resource", resource_updater)
	pass

func try_auto_node_update(next_node_id:int = -1) -> void:
	if next_node_id != _CURRENT_INSPECTED_NODE_RESOURCE_ID:
		read_and_update_inspected_node(true)
	pass

# Note: this function might be called by scripts or due to ui signals
func toggle_node_skip(change:bool, send_request:bool = false) -> void:
	# update ui ?
	if change != NodeIsSkippedCheck.is_pressed():
		NodeIsSkippedCheck.set_pressed(change)
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

func update_referrers_list(node_id:int = _CURRENT_INSPECTED_NODE_RESOURCE_ID) -> void:
	NodeReferrersListPopUp.clear()
	_CURRENT_INSPECTED_NODE_REFERRERS = Main.Mind.list_referrers(node_id)
	var referrers_size = _CURRENT_INSPECTED_NODE_REFERRERS.size()
	if referrers_size > 0 :
		NodeReferrersList.set_visible(true)
		NodeReferrersList.set_text(REFERRERS_MENU_BUTTON_TEXT_TEMPLATE % referrers_size)
		for user_node_id in _CURRENT_INSPECTED_NODE_REFERRERS:
			var user_node_name = _CURRENT_INSPECTED_NODE_REFERRERS[user_node_id]
			NodeReferrersListPopUp.add_item(user_node_name, user_node_id)
	else:
		NodeReferrersList.set_visible(false)
	pass

func _request_locating_node_by_id(node_id:int) -> void:
	emit_signal("relay_request_mind", "locate_node_on_grid", {
		"id": node_id,
		"highlight": true,
		"force": true, # ... to change open scene
	})
	pass

func level_trackage_data(copy:Dictionary, original:Dictionary) -> void:
	# fill the gaps such as `name` and `type`
	for property in original:
			if copy.has(property) == false:
				copy[property] = (
					original[property].duplicate(true)
					if ( typeof(original[property]) == TYPE_DICTIONARY || typeof(original[property]) == TYPE_ARRAY ) 
					else original[property]
				)
	# remove special update commands such as `_use`
	for property in copy.data:
		if original.data.has(property) == false:
			copy.data.erase(property)
	pass

func track_node_modification(node_id:int, node:Dictionary) -> void:
	if ( 
		Settings.MAXIMUM_HISTORY_SIZE_PER_NODE >= 1 && 
		node_id == _CURRENT_INSPECTED_NODE_RESOURCE_ID &&
		is_snapshot_preview() == false # we don't want to mess with history in snapshot preview
	):
		var original = _CURRENT_INSPECTED_NODE
		var the_copy = node.duplicate(true)
		# equalize trivial differences with another side so they can be compared
		level_trackage_data(the_copy, original)
		# now we can compare and track
		if Utils.objects_differ(the_copy, original):
			if _NODE_MODIFICATION_HISTORY.has(node_id) == false:
				# for some node-types, initial data (original) may be unset,
				# so we don't need to track any copy till user updates them manually ...
				if Settings.SKIP_INITIAL_COPY_TRACK_FOR_NODE_TYPE.has(original.type) != true:
					_NODE_MODIFICATION_HISTORY[node_id] = [ original.duplicate(true) ]
					_NODE_MODIFICATION_HISTORY[node_id].push_front(the_copy)
				else:
					# ... in other words we should skip one first round of modification,
					# because the first modification is the real (set) initialization
					_NODE_MODIFICATION_HISTORY[node_id] = null
			elif _NODE_MODIFICATION_HISTORY[node_id] == null:
				_NODE_MODIFICATION_HISTORY[node_id] = [ original.duplicate(true) ]
			# now if we have the right original (initial),
			# we can keep a copy if it's new or different
			if _NODE_MODIFICATION_HISTORY[node_id] != null && (_NODE_MODIFICATION_HISTORY[node_id].size() == 0 || Utils.objects_differ(the_copy, _NODE_MODIFICATION_HISTORY[node_id][0])) :
					_NODE_MODIFICATION_HISTORY[node_id].push_front( the_copy )
					if _NODE_MODIFICATION_HISTORY[node_id].size() > Settings.MAXIMUM_HISTORY_SIZE_PER_NODE:
						_NODE_MODIFICATION_HISTORY[node_id].pop_back()
		#	print_debug("History:", _NODE_MODIFICATION_HISTORY[node_id])
		reset_node_history_rotation(node_id)
	pass

func reset_node_history_rotation(node_id:int = -1) -> void:
	_CURRENT_NODE_HISTORY_ROTATION_ID = node_id
	_CURRENT_NODE_HISTORY_ROTATION_POSE = 0
	NodeHistoryBackButton.set_disabled(
		_NODE_MODIFICATION_HISTORY.has(node_id) == false ||
		_NODE_MODIFICATION_HISTORY[node_id] == null ||
		_NODE_MODIFICATION_HISTORY[node_id].size() == 0 ||
		is_snapshot_preview()
	)
	NodeHistoryForeButton.set_disabled( true )
	pass

func invoke_historic_node(node_id:int = -1, index:int = -1) -> void:
	if ( _NODE_MODIFICATION_HISTORY.has(node_id) && index >= 0 && _NODE_MODIFICATION_HISTORY[node_id].size() > index ):
		var historic_node = _NODE_MODIFICATION_HISTORY[node_id][index]
		update_parameters(
			node_id,
			historic_node, 
			_CURRENT_INSPECTED_NODE_MAP,
			_LAST_OPEN_SUB_INSPECTOR,
			false # do not refresh sub-inspector yet ...
		)
		# ... because some node-types need special care
		match historic_node.type:
			"jump":
				_LAST_OPEN_SUB_INSPECTOR.call_deferred(
					"_update_parameters", node_id, historic_node.duplicate(true),
					# do not refresh cached node, so it keeps the previous target data and may send new respective `_use` command
					false 
				)
				return
			"macro_use":
				# we shall not update the macro_use internals, so it can detect changes itself
				# let's change the selection only
				_LAST_OPEN_SUB_INSPECTOR.call_deferred("refresh_macro_list", historic_node.data.macro)
				return
		# if no special update, then we can update normally
		_LAST_OPEN_SUB_INSPECTOR.call_deferred("_update_parameters", node_id, historic_node.duplicate(true))
	pass

func rotate_node_history(back:bool = true) -> void:
	var node_id = _CURRENT_INSPECTED_NODE_RESOURCE_ID
	if ( _NODE_MODIFICATION_HISTORY.has(node_id) ):
		var history_size = _NODE_MODIFICATION_HISTORY[node_id].size()
		var target_pose = _CURRENT_NODE_HISTORY_ROTATION_POSE + ((+1) if back else (-1))
		if target_pose > -1 && target_pose < history_size:
			_CURRENT_NODE_HISTORY_ROTATION_POSE = target_pose
			invoke_historic_node(node_id, target_pose)
		NodeHistoryBackButton.set_disabled( target_pose >= (history_size - 1) || history_size == 0 )
		NodeHistoryForeButton.set_disabled( target_pose <= 0 ||  history_size == 0)
	else:
		NodeHistoryBackButton.set_disabled(true)
		NodeHistoryForeButton.set_disabled(true)
	pass
