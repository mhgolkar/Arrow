# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Console Panel
extends PanelContainer

signal request_mind

onready var TheTree = get_tree()
onready var Main = TheTree.get_root().get_child(0)

onready var Terminal = get_node(Addressbook.CONSOLE.TERMINAL)
onready var TerminalScroll = get_node(Addressbook.CONSOLE.TERMINAL_SCROLL_CONTAINER)
onready var ClearConsoleButton = get_node(Addressbook.CONSOLE.CLEAR)
onready var CloseConsoleButton = get_node(Addressbook.CONSOLE.CLOSE)
onready var PlayStepBackButton = get_node(Addressbook.CONSOLE.BACK)
onready var SettingsMenuButton = get_node(Addressbook.CONSOLE.SETTINGS)
onready var SettingsMenuButtonPopup = SettingsMenuButton.get_popup()

const CONSOLE_MESSAGE_DEFAULT_COLOR = Settings.CONSOLE_MESSAGE_DEFAULT_COLOR

var _CACHED_TYPES:Dictionary = {}
var _NODES_IN_TERMINAL = [] # new one first [0]
var _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL = []
var _SKIPPED_NODES:Dictionary = {}

# console settings
var _AUTOSCROLL:bool = true
var _PREVENT_CLEARANCE:bool = false
var _INSPECT_VARIABLES:bool = false
var _SHOW_SKIPPED_NODES:bool = false

const CLEARANCE_PREVENTION_MESSAGE = "Clearance ignored."
const CLEARANCE_PREVENTION_MESSAGE_COLOR = Color.yellow

const CONSOLE_SKIPPED_NODES_SELF_MODULATION_COLOR_ON = Settings.CONSOLE_SKIPPED_NODES_SELF_MODULATION_COLOR_ON
const CONSOLE_SKIPPED_NODES_SELF_MODULATION_COLOR_OFF = Settings.CONSOLE_SKIPPED_NODES_SELF_MODULATION_COLOR_OFF

const CONSOLE_SETTINGS_MENU = {
	# CAUTION! The func `refresh_console_setting_menu_buttons` shall be modified respectively in case
	0: { "label": "Auto-scroll", "is_checkbox": true , "action": "_reset_settings_auto_scroll" },
	1: { "label": "Prevent Clearance", "is_checkbox": true , "action": "_reset_settings_prevent_clearance" },
	2: { "label": "Inspect Variables", "is_checkbox": true , "action": "_reset_settings_inspect_variables" },
	3: { "label": "Show Skipped Nodes", "is_checkbox": true , "action": "_reset_settings_show_skipped_nodes" },
}
var _CONSOLE_SETTINGS_MENU_ITEM_INDEX_BY_ACTION = {}

onready var VariablesInspectorPanel = get_node(Addressbook.CONSOLE.VARIABLE_INSPECTOR.itself)
onready var VariableInspectorSelect = get_node(Addressbook.CONSOLE.VARIABLE_INSPECTOR.VARIABLE_SELECT)
onready var VariableInspectorCurrentValue = {
	"itself": get_node(Addressbook.CONSOLE.VARIABLE_INSPECTOR.VALUE_EDITS.itself),
	"str": get_node(Addressbook.CONSOLE.VARIABLE_INSPECTOR.VALUE_EDITS["str"]),
	"num": get_node(Addressbook.CONSOLE.VARIABLE_INSPECTOR.VALUE_EDITS["num"]),
	"bool": get_node(Addressbook.CONSOLE.VARIABLE_INSPECTOR.VALUE_EDITS["bool"])
}
onready var VariableInspectorUpdateButton = get_node(Addressbook.CONSOLE.VARIABLE_INSPECTOR.UPDATE_BUTTON)

func _ready() -> void:
	register_connections()
	load_console_settings_menu()
	pass

func register_connections() -> void:
	ClearConsoleButton.connect("pressed", self, "_request_mind", ["console_clear"], CONNECT_DEFERRED)
	CloseConsoleButton.connect("pressed", self, "_request_mind", ["console_close"], CONNECT_DEFERRED)
	PlayStepBackButton.connect("pressed", self, "play_step_back", [], CONNECT_DEFERRED)
	SettingsMenuButtonPopup.connect("id_pressed", self, "_on_console_settings_popup_menu_id_pressed", [], CONNECT_DEFERRED)
	VariableInspectorSelect.connect("item_selected", self, "_on_variable_inspector_item_select", [], CONNECT_DEFERRED)
	VariableInspectorUpdateButton.connect("pressed", self, "update_current_inspected_variable", [], CONNECT_DEFERRED)
	pass

func _request_mind(req:String, args = null) -> void:
	emit_signal("request_mind", req, args)
	pass

func load_console_settings_menu() -> void:
	SettingsMenuButtonPopup.clear()
	for item_id in CONSOLE_SETTINGS_MENU:
		var item = CONSOLE_SETTINGS_MENU[item_id]
		if item == null: # separator
			SettingsMenuButtonPopup.add_separator()
		else:
			if item.has("is_checkbox") && item.is_checkbox == true:
				SettingsMenuButtonPopup.add_check_item(item.label, item_id)
			else:
				SettingsMenuButtonPopup.add_item(item.label, item_id)
			_CONSOLE_SETTINGS_MENU_ITEM_INDEX_BY_ACTION[item.action] = SettingsMenuButtonPopup.get_item_index(item_id)
	# update checkboxes ...
	refresh_console_setting_menu_buttons()
	pass

func _on_console_settings_popup_menu_id_pressed(pressed_item_id:int) -> void:
	var the_action = CONSOLE_SETTINGS_MENU[pressed_item_id].action
	if the_action is String && the_action.length() > 0 :
		self.call_deferred(the_action)
	pass

func refresh_variables_list() -> void:
	var the_selected_one_index_before_referesh = VariableInspectorSelect.get_selected()
	VariableInspectorSelect.clear()
	var no_var_yet = true
	if _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.size() >= 1:
		var variables = _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL[0]
		if variables.size() > 0 :
			for variable_id in variables:
				VariableInspectorSelect.add_item(variables[variable_id].name, variable_id)
			# reselect the variable after refresh
			if the_selected_one_index_before_referesh < variables.size():
				VariableInspectorSelect.select(the_selected_one_index_before_referesh)
			no_var_yet = false
	if no_var_yet:
		VariableInspectorSelect.add_item("No Variable Available", -1)
	inspect_variable()
	pass

func inspect_variable(id:int = -1) -> void:
	var a_var_inspected = false
	if id < 0 :
		id = VariableInspectorSelect.get_selected_id()
	if id >= 0 && _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.size() > 0:
		var current_variable_set = _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL[0]
		if current_variable_set.size() > 0:
			if current_variable_set.has(id):
				var selected_variable = current_variable_set[id]
				var value = selected_variable.value
				a_var_inspected = true
				match selected_variable.type:
					"str":
						VariableInspectorCurrentValue["str"].set_text(value)
					"num":
						VariableInspectorCurrentValue["num"].set_value(value)
					"bool":
						VariableInspectorCurrentValue["bool"].select( VariableInspectorCurrentValue["bool"].get_item_index( ( 1 if value else 0 ) ) )
				set_variable_inspector_current_value_editor_to_type(selected_variable.type)
			else:
				# there might be a lingering previously inspected variable after step back or removal
				refresh_variables_list()
	VariableInspectorCurrentValue.itself.set("visible", a_var_inspected)
	pass

func set_variable_inspector_current_value_editor_to_type(the_type_visible:String = "") -> void:
	for type in VariableInspectorCurrentValue:
		VariableInspectorCurrentValue[type].set_visible( (type == the_type_visible) )
	pass

func _on_variable_inspector_item_select(idx:int = -1) -> void:
	# it inspects based on `get_selected_id`, so automatically converts idx to id
	inspect_variable()
	pass

func update_current_inspected_variable() -> void:
	var id = VariableInspectorSelect.get_selected_id()
	if id >= 0 && _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.size() > 0:
		var current_variable_set = _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL[0]
		if current_variable_set.has(id):
			var selected_variable = current_variable_set[id]
			var value
			match selected_variable.type:
				"str":
					value = VariableInspectorCurrentValue["str"].get_text()
				"num":
					value = VariableInspectorCurrentValue["num"].get_value()
				"bool":
					var boolean_integer = VariableInspectorCurrentValue["bool"].get_selected_id()
					value = (true if (boolean_integer == 1) else false)
			selected_variable.value = value
		print(current_variable_set)
	pass

func append_to_terminal(node, variables_current = null) -> void:
	_NODES_IN_TERMINAL.push_front(node)
	if (variables_current is Dictionary) == false:
		variables_current = clone_fresh_variable_set()
	_VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.push_front( variables_current )
	Terminal.call_deferred("add_child", node)
	self.call_deferred("refresh_variables_list")
	self.call_deferred("update_scroll_to_v_max")
	pass

func print_console(message:String, centerize:bool = false, color:Color = CONSOLE_MESSAGE_DEFAULT_COLOR) -> void:
	var message_node = Label.new()
	message_node.set_text(message)
	if centerize:
		message_node.set_align(Label.ALIGN_CENTER)
	message_node.set("custom_colors/font_color", color)
	append_to_terminal(message_node)
	pass

func clone_fresh_variable_set() -> Dictionary:
	var new_set:Dictionary = {}
	if _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.size() > 0 :
		# clone the changes from the last synced set
		new_set = _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL[0].duplicate(true)
	# then check for any new variables, because there might be new ones created since previous play in console;
	# it also loads initial values in empty `new_set` if there has been no previously played set
	var all_registered_variables = Main.Mind.clone_dataset_of("variables")
	for variable_id in all_registered_variables:
		if new_set.has(variable_id) == false:
			new_set[variable_id] = all_registered_variables[variable_id]
			new_set[variable_id].value = all_registered_variables[variable_id].init
	return new_set

# clears console even if clearance prevention setting is on,
# because it's called by core and not console nodes
func clear_console() -> void:
	var all_nodes_count = _NODES_IN_TERMINAL.size()
	while (all_nodes_count > 0):
		_NODES_IN_TERMINAL.pop_front().queue_free()
		all_nodes_count -= 1
	_VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.clear()
	_SKIPPED_NODES.clear()
	print_debug("Console Cleared.")
	self.call_deferred("refresh_variables_list")
	pass

# listens to the playing node for only ONE EMISSION of each possible message,
# because every playing node will finish in a 'play_forward' or a 'status_code'.
# Some nodes may also ask for clearance (like contents) which can happen only once.
const POSSIBLE_SIGNALS_FROM_PLAYING_NODES = {
	"play_forward"   : "request_play_forward",
	"status_code"    : "interpret_status_code",
	"clear_up"       : "clear_nodes_before",
	"reset_variable" : "reset_synced_variable",
}

func listen_to_playing_node(node:Node, node_uid:int = -1) -> void:
	# because in step backs we try to listen back to a playing node,
	# we shall check for existance of the connection first to avoid error
	for the_signal in POSSIBLE_SIGNALS_FROM_PLAYING_NODES:
		var the_method = POSSIBLE_SIGNALS_FROM_PLAYING_NODES[the_signal]
		if node.is_connected(the_signal, self, the_method) == false:
			node.connect(the_signal, self, the_method, [node], CONNECT_ONESHOT)
	# 'console' lets users to double click on a playing node and jump to the respective node on the gird,
	# so we listen for that too ...
	if node.is_connected("gui_input", self, "_on_playing_node_gui_input") == false:
		node.connect("gui_input", self, "_on_playing_node_gui_input", [node, node_uid], CONNECT_DEFERRED)
	pass

var _MACRO_USE_TREATMENT = {
	"ACTIVE": false,
	"ELEMENT": null,
	"TERMINAL": null,
	"MACRO_NODES": []
}

func will_be_macro_pushed(node_uid:int) -> bool:
	return (
		_MACRO_USE_TREATMENT.ACTIVE == true &&
		_MACRO_USE_TREATMENT.MACRO_NODES.has(node_uid)
	)

func macro_use_special_treatments(node_uid:int, node_resource:Dictionary, node_map:Dictionary, node_element:Node) -> bool:
	var macro_terminal_push:bool = false
	if node_resource.type == "macro_use":
		macro_use_treatment_load(node_resource, node_map, node_element)
	elif _MACRO_USE_TREATMENT.ACTIVE == true :
		if _MACRO_USE_TREATMENT.MACRO_NODES.has(node_uid):
			# this is the macro itself being played
			append_to_macro_terminal(node_element)
			macro_terminal_push = true
		else:
			# otherwise we have left the macro, without finishing it (no END_EDGE emission, probably via jump,)
			# so unloade it without playing forward.
			macro_use_treatment_unload(false)
	return macro_terminal_push

func macro_use_treatment_load(node_resource:Dictionary, node_map:Dictionary, node_element:Node) -> void:
	_MACRO_USE_TREATMENT.ACTIVE = true
	_MACRO_USE_TREATMENT.ELEMENT = node_element
	_MACRO_USE_TREATMENT.TERMINAL = node_element.get_node( node_element.get("MACRO_TERMINAL_REL_PATH") )
	# getting macro child nodes from the central mind
	_MACRO_USE_TREATMENT.MACRO_NODES.clear()
	if node_resource.has("data") && node_resource.data.has("macro"):
		if (node_resource.data.macro is int) && node_resource.data.macro >= 0 :
			var the_macro_resource = Main.Mind.lookup_resource(node_resource.data.macro, "scenes", false) # ... bacause a macro is a special scene
			if the_macro_resource is Dictionary:
				if the_macro_resource.has("map") && the_macro_resource.map is Dictionary:
					_MACRO_USE_TREATMENT.MACRO_NODES = the_macro_resource.map.keys()
					# ok! now we have loaded the macro_use, yet we shall ...
					# ... run the macro from its entry node
					if the_macro_resource.has("entry") && (the_macro_resource.entry is int):
						self.call_deferred("request_play_forward", the_macro_resource.entry, 0, node_element)
					else:
						printerr("Unexpected Behavior! Macro has no `entry`. Project data might be corrupted.")
	print_debug("Type `macro_use` special treatments loaded.", _MACRO_USE_TREATMENT)
	pass
	
func macro_use_treatment_unload(play_forward:bool = true) -> void:
	if _MACRO_USE_TREATMENT.ACTIVE && _MACRO_USE_TREATMENT.ELEMENT && (play_forward != false):
		_MACRO_USE_TREATMENT.ELEMENT.call_deferred("play_macro_use_forward")
	_MACRO_USE_TREATMENT.ACTIVE = false
	_MACRO_USE_TREATMENT.TERMINAL = null
	_MACRO_USE_TREATMENT.ELEMENT = null
	_MACRO_USE_TREATMENT.MACRO_NODES.clear()
	pass

func append_to_macro_terminal(node) -> void:
	_MACRO_USE_TREATMENT.TERMINAL.call_deferred("add_child", node)
	self.call_deferred("refresh_variables_list")
	self.call_deferred("update_scroll_to_v_max")
	pass

func play_node(node_uid:int, node_resource:Dictionary, node_map:Dictionary, type:Dictionary, playing_in_slot:int = -1) -> void:
	# print_debug("Console, plays node: ", node_uid, node_resource.type)
	var the_play_node = type.console.instance()
	var is_macro_pushy = will_be_macro_pushed(node_uid)
	var synced_var_set = (
		_VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL[0]
			if (
				is_macro_pushy && _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.size() > 0
			) else (
				clone_fresh_variable_set()
			)
		)
	the_play_node.call_deferred("setup_play",
		node_uid,
		node_resource.duplicate(true),
		node_map.duplicate(true),
		playing_in_slot,
		synced_var_set
	)
	listen_to_playing_node(the_play_node, node_uid)
	# finally add it to the tree
	# Note: we run `macro_use_special_treatments` on every node
	# because the function detects the `macro_use` nodes and handles special treatments (pushes, leaves, etc.) in case,
	var macro_pushed = macro_use_special_treatments(node_uid, node_resource, node_map, the_play_node)
	if macro_pushed == false: # for normal nodes it does nothing, so we treat them normally:
		append_to_terminal(the_play_node, synced_var_set)
	# and...
	if node_map.has("skip") && node_map.skip == true:
		# the node is appended, because it's part of the continuum anyway when played, so we ask it to get skipped (hidden)
		reset_node_skippness_view(the_play_node, (!_SHOW_SKIPPED_NODES), true)
		_SKIPPED_NODES[node_uid] = the_play_node
	# finally (re-)cache types for later uses
	_CACHED_TYPES[ node_resource.type ] = type
	pass
	
func reset_node_skippness_view(element:Node, do_hide:bool = true, do_modulate = null) -> void:
	element.set_visible( ! do_hide )
	# ... and do modulate if set:
	if do_modulate is bool:
		element.set("self_modulate",
			(
				CONSOLE_SKIPPED_NODES_SELF_MODULATION_COLOR_ON
					if do_modulate else
				CONSOLE_SKIPPED_NODES_SELF_MODULATION_COLOR_OFF
			)
		)
	pass

func update_scroll_to_v_max(forced:bool = false) -> void:
	if _AUTOSCROLL || forced:
		yield(TheTree, "idle_frame")
		var v_max = TerminalScroll.get_v_scrollbar().get_max()
		TerminalScroll.set_v_scroll( v_max )
		TerminalScroll.update()
	pass

func play_step_back(how_many:int = 1) -> void:
	if _NODES_IN_TERMINAL.size() >= how_many:
		while (how_many > 0):
			_VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.pop_front()
			var node = _NODES_IN_TERMINAL.pop_front()
			if is_instance_valid(node):
				if "_NODE_ID" in node && _SKIPPED_NODES.has(node._NODE_ID):
					_SKIPPED_NODES.erase(node._NODE_ID)
				node.queue_free()
				how_many -= 1
		# after stepping back, we shall...
		# make the last node manually playable by the user, to able them debug and decide!
		if _NODES_IN_TERMINAL.size() > 0 :
			var now_playing_node = _NODES_IN_TERMINAL[0]
			# yet another treatment for `macro_use` nodes
			if is_instance_valid(now_playing_node) && "_NODE_RESOURCE" in now_playing_node && now_playing_node._NODE_RESOURCE.type == "macro_use":
				play_step_back(1) # another step back
				macro_use_treatment_unload(false) # unload macro if it's still loaded
				# and replay it with `skip` property overloaded to force it being played
				var skip_overloaded_map = now_playing_node._NODE_MAP.duplicate(true)
				skip_overloaded_map.skip = false
				play_node(now_playing_node._NODE_ID, now_playing_node._NODE_RESOURCE, skip_overloaded_map, _CACHED_TYPES["macro_use"])
			# normal nodes
			else:
				now_playing_node.call_deferred("step_back")
				listen_to_playing_node(now_playing_node)
				reset_node_skippness_view(now_playing_node, false) # make sure it's visible even skipped
			self.call_deferred("update_scroll_to_v_max")
		self.call_deferred("refresh_variables_list")
	pass

func request_play_forward(to_node_id:int = -1, to_slot:int = -1, _the_player_one = null):
	print_debug("Play Forward! To node: ", to_node_id, " slot: ", to_slot)
	emit_signal("request_mind", "console_play_node", {
		"id": to_node_id,
		"slot": to_slot
	})
	pass

func interpret_status_code(code:int, the_player_node = null) -> void:
	match code:
		CONSOLE_STATUS_CODE.END_EDGE:
			if _MACRO_USE_TREATMENT.ACTIVE:
				# this is end of a `macro_use`, but there might be still more to play in the parent scene, so ...
				macro_use_treatment_unload(true) # ... with `play_forward=true`
			else:
				# it's end of the parent scene/plot-line
				print_console( CONSOLE_STATUS_CODE.END_EDGE_MESSAGE )
		CONSOLE_STATUS_CODE.NO_DEFAULT:
			if is_instance_valid(the_player_node):
				var full_no_default_message = CONSOLE_STATUS_CODE.NO_DEFAULT_MESSAGE + " (" + the_player_node._NODE_RESOURCE.name + ")"
				print_console( full_no_default_message , true, Settings.CAUTION_COLOR )
				# `macro_use` nodes may also send this status code and they need special treatments:
				if the_player_node._NODE_RESOURCE.type == "macro_use":
					yield(TheTree, "idle_frame")
					self.call_deferred("macro_use_treatment_unload")
			else:
				print_console( CONSOLE_STATUS_CODE.NO_DEFAULT_MESSAGE , false, Settings.CAUTION_COLOR )
	pass

func clear_nodes_before(the_player_node) -> void:
	if _PREVENT_CLEARANCE != true:
		var how_many = (_NODES_IN_TERMINAL.size() - _NODES_IN_TERMINAL.find(the_player_node) - 1)
		while (how_many > 0):
			_VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.pop_back()
			var node = _NODES_IN_TERMINAL.pop_back()
			if node:
				node.queue_free()
				how_many -= 1
		self.call_deferred("refresh_variables_list")
	else:
		print_console( CLEARANCE_PREVENTION_MESSAGE, false, CLEARANCE_PREVENTION_MESSAGE_COLOR )
	pass

# <variable_update_list> { int<variable_ids>: variant<new_values>, ...}
func reset_synced_variable(variable_update_list:Dictionary, the_player_node = null) -> void:
	# print_debug("reset_synced_variable : ", variable_update_list)
	var index_of_the_player_node = _NODES_IN_TERMINAL.find(the_player_node)
	if _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.size() > index_of_the_player_node:
		if index_of_the_player_node < 0 :
			# the player node might not be set or may be a node in a `macro_use` sub-terminal/sub-console,
			# therefore not found, 
			# in those cases, we update the newest first[0] set
			index_of_the_player_node = 0
		var the_set = _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL[index_of_the_player_node]
		for variable_id in variable_update_list:
			if the_set.has(variable_id):
				if typeof( the_set[variable_id].value ) == typeof( variable_update_list[variable_id] ):
					the_set[variable_id].value = variable_update_list[variable_id]
				else:
					printerr("Invalid Console Node Behavior! The variable %s is tried to be reset by value of other type: " % variable_id, variable_update_list[variable_id])
			else:
				printerr("Invalid Console Node Behavior! Trying to reset nonexistent variable: ", variable_id)
	refresh_variables_list()
	pass

func refresh_console_setting_menu_buttons() -> void:
	SettingsMenuButtonPopup.set_item_checked(0, _AUTOSCROLL)
	SettingsMenuButtonPopup.set_item_checked(1, _PREVENT_CLEARANCE)
	SettingsMenuButtonPopup.set_item_checked(2, _INSPECT_VARIABLES)
	SettingsMenuButtonPopup.set_item_checked(3, _SHOW_SKIPPED_NODES)
	VariablesInspectorPanel.set_visible(_INSPECT_VARIABLES)
	if _INSPECT_VARIABLES:
		self.call_deferred("refresh_variables_list")
	pass

func _reset_settings_auto_scroll() -> void:
	_AUTOSCROLL = (! _AUTOSCROLL)
	refresh_console_setting_menu_buttons()
	pass

func _reset_settings_prevent_clearance() -> void:
	_PREVENT_CLEARANCE = (! _PREVENT_CLEARANCE)
	refresh_console_setting_menu_buttons()
	pass

func _reset_settings_inspect_variables() -> void:
	_INSPECT_VARIABLES = (! _INSPECT_VARIABLES)
	refresh_console_setting_menu_buttons()
	pass

func _reset_settings_show_skipped_nodes() -> void:
	_SHOW_SKIPPED_NODES = (! _SHOW_SKIPPED_NODES)
	refresh_console_setting_menu_buttons()
	# for all the skipped nodes reset view (and don't change modulation)
	refresh_skipped_nodes_view_all( (! _SHOW_SKIPPED_NODES) )
	pass

func refresh_skipped_nodes_view_all(do_hide:bool = true, do_modulate = null) -> void:
	for node_uid in _SKIPPED_NODES:
		reset_node_skippness_view(_SKIPPED_NODES[node_uid], do_hide, do_modulate)
	pass

func _on_playing_node_gui_input(event:InputEvent, node = null, node_uid:int = -1) -> void:
	# on mouse click
	if event is InputEventMouseButton:
		# ... double click
		if event.is_doubleclick():
			# jump to the respective node on the grid
			if node_uid >= 0 :
				_request_mind("locate_node_on_grid", { "id": node_uid, "highlight": true } )
	pass

# make this panel,
# dragable
# ... it also makes the panel compete for the parent's top z-index by default
onready var drag_point = get_node(Addressbook.CONSOLE.drag_point)
onready var dragability = Helpers.Dragable.new(self, drag_point)
# and resizable
onready var resize_point = get_node(Addressbook.CONSOLE.resize_point)
onready var resizability = Helpers.Resizable.new(self, resize_point)
