# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Console Panel
extends Control

signal request_mind()

@onready var TheTree = get_tree()
@onready var Main = TheTree.get_root().get_child(0)

@onready var TerminalScroll = $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/Display/Scroll
@onready var Terminal = $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/Display/Scroll/Terminal
@onready var ClearConsoleButton = $/root/Main/FloatingTools/Control/Console/Sections/Toolbar/Clear
@onready var CloseConsoleButton = $/root/Main/FloatingTools/Control/Console/Sections/Toolbar/Close
@onready var PlayStepBackButton = $/root/Main/FloatingTools/Control/Console/Sections/Toolbar/Back
@onready var SettingsMenuButton = $/root/Main/FloatingTools/Control/Console/Sections/Toolbar/Settings
@onready var SettingsMenuButtonPopup = SettingsMenuButton.get_popup()

const CONSOLE_MESSAGE_DEFAULT_COLOR = Settings.CONSOLE_MESSAGE_DEFAULT_COLOR
const CONSOLE_MESSAGE_PRINT_PROPERTIES = {
	"size_flags_vertical": Control.SizeFlags.SIZE_EXPAND_FILL,
	"horizontal_alignment": HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT,
	"autowrap_mode": TextServer.AutowrapMode.AUTOWRAP_WORD_SMART,
}

var _CACHED_TYPES:Dictionary = {}
var _NODES_IN_TERMINAL = [] # new one first [0]
var _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL = []
var _CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL = []
var _SKIPPED_NODES:Dictionary = {}
var _OPEN_MACRO = null # or { "ELEMENT": ..., "TERMINAL": ..., "MACRO_NODES": [...] }

# console settings
var _AUTOSCROLL:bool = true
var _ALLOW_AUTO_PLAY:bool = true
var _PREVENT_CLEARANCE:bool = false
var _INSPECT_VARIABLES:bool = false
var _INSPECT_CHAR_TAGS:bool = false
var _SHOW_SKIPPED_NODES:bool = false

const CLEARANCE_PREVENTION_MESSAGE = "CONSOLE_CLEARANCE_PREVENTION_MESSAGE" # Translated ~ "Clearance ignored."
const CLEARANCE_PREVENTION_MESSAGE_COLOR = Color.YELLOW

const CONSOLE_SKIPPED_NODES_SELF_MODULATION_COLOR_ON = Settings.CONSOLE_SKIPPED_NODES_SELF_MODULATION_COLOR_ON
const CONSOLE_SKIPPED_NODES_SELF_MODULATION_COLOR_OFF = Settings.CONSOLE_SKIPPED_NODES_SELF_MODULATION_COLOR_OFF

const CONSOLE_SETTINGS_MENU = {
	# CAUTION! The func `refresh_console_setting_menu_buttons` shall be modified respectively in case
	0: { "label": "Auto-scroll", "is_checkbox": true , "action": "_reset_settings_auto_scroll" },
	1: { "label": "Allow Auto-play", "is_checkbox": true , "action": "_reset_settings_allow_auto_play" },
	2: { "label": "Prevent Clearance", "is_checkbox": true , "action": "_reset_settings_prevent_clearance" },
	3: { "label": "Show Skipped Nodes", "is_checkbox": true , "action": "_reset_settings_show_skipped_nodes" },
	4: { "label": "Inspect Variables", "is_checkbox": true , "action": "_reset_settings_inspect_variables" },
	5: { "label": "Inspect Character Tags", "is_checkbox": true , "action": "_reset_settings_inspect_char_tags" },
}
var _CONSOLE_SETTINGS_MENU_ITEM_INDEX_BY_ACTION = {}

@onready var DisplayStatesSplitter = $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split

@onready var VariablesInspectorPanel = $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/States/Variables
@onready var VariableInspectorSelect = $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/States/Variables/Current/List
@onready var VariableInspectorCurrentValue = {
	"itself": $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/States/Variables/Current/State/Value,
	"str": $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/States/Variables/Current/State/Value/String,
	"num": $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/States/Variables/Current/State/Value/Number,
	"bool": $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/States/Variables/Current/State/Value/Boolean,
}
@onready var VariableInspectorUpdateButton = $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/States/Variables/Current/State/Update

@onready var CharTagsInspectorPanel = $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/States/Characters
@onready var CharTagsInspectorSelect = $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/States/Characters/Current/List
@onready var CharTagsInspectorCurrent = $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/States/Characters/Current/Current
@onready var CharTagsInspectorTagBox = $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/States/Characters/Current/Current/Scroll/Pairs
@onready var CharTagsInspectorNoneMessage = $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/States/Characters/Current/Current/Scroll/None
@onready var CharTagsInspectorEditKey = $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/States/Characters/Current/Current/Edit/Key
@onready var CharTagsInspectorEditValue = $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/States/Characters/Current/Current/Edit/Value
@onready var CharTagsInspectorEditOverset = $/root/Main/FloatingTools/Control/Console/Sections/Interpreter/Split/States/Characters/Current/Current/Edit/Overset

const CHAR_TAG_KEY_VALUE_DISPLAY_TEMPLATE = "`{value}`" # also available: {key}

func _ready() -> void:
	register_connections()
	load_console_settings_menu()
	pass

func register_connections() -> void:
	ClearConsoleButton.pressed.connect(self._request_mind.bind("console_clear"), CONNECT_DEFERRED)
	CloseConsoleButton.pressed.connect(self._request_mind.bind("console_close"), CONNECT_DEFERRED)
	PlayStepBackButton.pressed.connect(self.play_step_back, CONNECT_DEFERRED)
	SettingsMenuButtonPopup.id_pressed.connect(self._on_console_settings_popup_menu_id_pressed, CONNECT_DEFERRED)
	VariableInspectorSelect.item_selected.connect(self._on_variable_inspector_item_select, CONNECT_DEFERRED)
	VariableInspectorUpdateButton.pressed.connect(self.update_current_inspected_variable, CONNECT_DEFERRED)
	CharTagsInspectorSelect.item_selected.connect(self._on_char_tags_inspector_item_select, CONNECT_DEFERRED)
	CharTagsInspectorEditOverset.pressed.connect(self.read_and_overset_current_inspected_char_tag, CONNECT_DEFERRED)
	pass

func _request_mind(req:String, args = null) -> void:
	self.request_mind.emit(req, args)
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
	var the_selected_one_index_before_refresh = VariableInspectorSelect.get_selected()
	VariableInspectorSelect.clear()
	var no_var_yet = true
	if _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.size() >= 1:
		var variables = _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL[0]
		if variables.size() > 0 :
			var item_index := 0
			for variable_id in variables:
				VariableInspectorSelect.add_item(variables[variable_id].name, variable_id)
				VariableInspectorSelect.set_item_metadata(item_index, variable_id)
				item_index += 1
			# reselect the variable after refresh
			if the_selected_one_index_before_refresh < variables.size():
				VariableInspectorSelect.select(the_selected_one_index_before_refresh)
			no_var_yet = false
	if no_var_yet:
		VariableInspectorSelect.add_item("No Variable Available", -1)
		VariableInspectorSelect.set_item_metadata(0, -1)
	inspect_variable()
	pass

func inspect_variable(id:int = -1) -> void:
	var a_var_inspected = false
	if id < 0 :
		id = VariableInspectorSelect.get_selected_metadata()
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

func _on_variable_inspector_item_select(_idx:int = -1) -> void:
	inspect_variable()
	pass

func update_current_inspected_variable() -> void:
	var id = VariableInspectorSelect.get_selected_metadata()
	if id >= 0 && _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.size() > 0:
		var current_variable_set = _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL[0]
		if current_variable_set.has(id):
			var selected_variable = current_variable_set[id]
			var value
			match selected_variable.type:
				"str":
					value = VariableInspectorCurrentValue["str"].get_text()
				"num":
					value = int( VariableInspectorCurrentValue["num"].get_value() )
				"bool":
					var boolean_integer = VariableInspectorCurrentValue["bool"].get_selected_id()
					value = (true if (boolean_integer == 1) else false)
			selected_variable.value = value
		print(current_variable_set)
	pass

func refresh_characters_list() -> void:
	var the_selected_one_index_before_refresh = CharTagsInspectorSelect.get_selected()
	CharTagsInspectorSelect.clear()
	var no_char_yet = true
	if _CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL.size() >= 1:
		var characters = _CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL[0]
		if characters.size() > 0 :
			var item_index := 0
			for character_id in characters:
				CharTagsInspectorSelect.add_item(characters[character_id].name, character_id)
				CharTagsInspectorSelect.set_item_metadata(item_index, character_id)
				item_index += 1
			# reselect the character after refresh
			if the_selected_one_index_before_refresh < characters.size():
				CharTagsInspectorSelect.select(the_selected_one_index_before_refresh)
			no_char_yet = false
	if no_char_yet:
		CharTagsInspectorSelect.add_item("No Character Available", -1)
		CharTagsInspectorSelect.set_item_metadata(0, -1)
	inspect_character()
	pass

func take_char_tag_action(action_id: int, char_id: int, key: String, value: String) -> void:
	if char_id >= 0 && _CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL.size() > 0:
		var current_character_set = _CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL[0]
		if current_character_set.has(char_id):
			var selected_character = current_character_set[char_id]
			match action_id:
				1: # Edit
					CharTagsInspectorEditKey.set_text(key)
					CharTagsInspectorEditValue.set_text(value)
					CharTagsInspectorEditValue.grab_focus()
				2: # Unset
					CharTagsInspectorEditKey.set_text(key)
					CharTagsInspectorEditKey.grab_focus()
					CharTagsInspectorEditValue.set_text(value)
					selected_character.tags.erase(key)
				3: # Overset
					selected_character.tags[key] = value
	inspect_character()
	pass

func clean_all_char_tags() -> void:
	for node in CharTagsInspectorTagBox.get_children():
		if node is Button:
			node.free()
	pass

func append_char_tag_to_box(char_id: int, key: String, value: String) -> void:
	var key_value_display = CHAR_TAG_KEY_VALUE_DISPLAY_TEMPLATE.format({ "key": key, "value": value })
	var the_tag = MenuButton.new()
	the_tag.set_text(key)
	the_tag.set_tooltip_text(key_value_display)
	the_tag.set_flat(false)
	var the_popup = the_tag.get_popup()
	the_popup.add_item(key_value_display, 0)
	the_popup.set_item_disabled(0, true)
	the_popup.add_separator("", 0)
	the_popup.add_item("Edit", 1)
	the_popup.add_item("Unset", 2)
	the_popup.id_pressed.connect(self.take_char_tag_action.bind(char_id, key, value), CONNECT_DEFERRED)
	# ...
	CharTagsInspectorTagBox.add_child(the_tag)
	pass
	
func inspect_character(id:int = -1) -> void:
	clean_all_char_tags()
	var a_char_inspected = false
	var tags_available = false
	if id < 0 :
		id = CharTagsInspectorSelect.get_selected_metadata()
	if id >= 0 && _CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL.size() > 0:
		var current_character_set = _CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL[0]
		if current_character_set.size() > 0:
			if current_character_set.has(id):
				a_char_inspected = true
				var selected_character = current_character_set[id]
				tags_available = (
					selected_character is Dictionary && selected_character.has("tags") &&
					selected_character.tags is Dictionary && selected_character.tags.size() > 0
				)
				if tags_available:
					# print_debug("Console + Inspected character tags available: ", selected_character.tags)
					for key in selected_character.tags:
						append_char_tag_to_box(id, key, selected_character.tags[key])
			else:
				# there might be a lingering previously inspected character after step back or removal
				refresh_characters_list()
	CharTagsInspectorTagBox.set_visible(tags_available)
	CharTagsInspectorNoneMessage.set_visible( ! tags_available )
	CharTagsInspectorPanel.set_v_size_flags( SIZE_EXPAND_FILL if tags_available else SIZE_FILL )
	CharTagsInspectorCurrent.set("visible", a_char_inspected)
	pass

func _on_char_tags_inspector_item_select(_idx:int = -1) -> void:
	inspect_character()
	pass

func read_and_overset_current_inspected_char_tag() -> void:
	var char_id = CharTagsInspectorSelect.get_selected_metadata()
	var key = Helpers.Utils.exposure_safe_resource_name( CharTagsInspectorEditKey.get_text() )
	CharTagsInspectorEditKey.set_text(key) # ... so the user can see the safe key if we have changed it
	var value = CharTagsInspectorEditValue.get_text()
	if key.length() > 0:
		take_char_tag_action(3, char_id, key, value)
	pass

func update_scroll_to_v_max(forced:bool = false) -> void:
	if _AUTOSCROLL || forced:
		await TheTree.process_frame
		var v_max = TerminalScroll.get_v_scroll_bar().get_max()
		TerminalScroll.set_v_scroll( v_max )
		TerminalScroll.queue_redraw()
	pass

func try_focus_on_playing() -> bool:
	var in_macro = (_OPEN_MACRO != null && _OPEN_MACRO.ELEMENT.TERMINAL.get_child_count() > 0)
	var focal = Helpers.Utils.find_focal(_OPEN_MACRO.ELEMENT.TERMINAL if in_macro else Terminal)
	if focal != null && focal.is_visible() && focal.get("disabled") != true:
		focal.call_deferred("grab_focus")
		return true
	return false

func _react_to_terminal_changes() -> void:
	update_scroll_to_v_max()
	try_focus_on_playing()

func append_to_terminal(
	node_instance, node_uid: int = -1, node_resource = null, variables_current = null, characters_current = null
) -> void:
	if _OPEN_MACRO != null && (_OPEN_MACRO.MACRO_NODES.has(node_uid) || node_uid == -1):
		_OPEN_MACRO.ELEMENT.call("append_subnode", node_instance)
	else:
		_OPEN_MACRO = null
		Terminal.call_deferred("add_child", node_instance)
	# ...
	_NODES_IN_TERMINAL.push_front({
		"id": node_uid,
		"resource": node_resource,
		"instance": node_instance,
		"wrapper": _OPEN_MACRO.duplicate(false) if _OPEN_MACRO is Dictionary else null,
	});
	if (variables_current is Dictionary) == false:
		variables_current = clone_fresh_variable_set()
	_VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.push_front( variables_current )
	if (characters_current is Dictionary) == false:
		characters_current = clone_fresh_character_set()
	_CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL.push_front( characters_current )
	# ...
	self.call_deferred("refresh_variables_list")
	self.call_deferred("refresh_characters_list")
	self.call_deferred("_react_to_terminal_changes")
	pass

func print_console(message:String, color:Color = CONSOLE_MESSAGE_DEFAULT_COLOR, origin = null) -> void:
	var message_node = Label.new()
	message_node.set_text(message)
	for property in CONSOLE_MESSAGE_PRINT_PROPERTIES:
		message_node.set(property, CONSOLE_MESSAGE_PRINT_PROPERTIES[property])
	message_node.add_theme_color_override("font_color", color)
	if origin != null:
		message_node.set_mouse_filter(MOUSE_FILTER_PASS)
		message_node.gui_input.connect(self._on_playing_node_gui_input.bind(origin, origin._NODE_ID), CONNECT_DEFERRED)
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

func clone_fresh_character_set() -> Dictionary:
	var new_set:Dictionary = {}
	if _CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL.size() > 0 :
		# clone the changes from the last synced set
		new_set = _CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL[0].duplicate(true)
	# then check for any new characters, because there might be new ones created since previous play in console;
	# it also loads initial values in empty `new_set` if there has been no previously played set
	var all_registered_characters = Main.Mind.clone_dataset_of("characters")
	for character_id in all_registered_characters:
		if new_set.has(character_id) == false:
			new_set[character_id] = all_registered_characters[character_id]
			if new_set[character_id].has("tags") == false:
				new_set[character_id].tags = {}
	return new_set

# clears console even if clearance prevention setting is on,
# because it's called by core and not console nodes
func clear_console() -> void:
	var all_nodes_count = _NODES_IN_TERMINAL.size()
	while (all_nodes_count > 0):
		_NODES_IN_TERMINAL.pop_front().instance.queue_free()
		all_nodes_count -= 1
	_VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.clear()
	_CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL.clear()
	_SKIPPED_NODES.clear()
	print_debug("Console Cleared.")
	self.call_deferred("refresh_variables_list")
	self.call_deferred("refresh_characters_list")
	pass

# listens to the playing node for only ONE EMISSION of each possible message,
# because every playing node will finish in a 'play_forward' or a 'status_code'.
# Some nodes may also ask for clearance (like contents) which can happen only once.
const POSSIBLE_SIGNALS_FROM_PLAYING_NODES = {
	"play_forward"   : "request_play_forward",
	"status_code"    : "interpret_status_code",
	"clear_up"       : "clear_nodes_before",
	"reset_variables" : "reset_synced_variables",
	"reset_characters_tags" : "reset_synced_characters_tags",
}

func listen_to_playing_node(node:Node, node_uid:int = -1) -> void:
	# because in step backs we try to listen back to a playing node,
	# we shall check for existence of the connection first to avoid error
	for the_signal in POSSIBLE_SIGNALS_FROM_PLAYING_NODES:
		var the_method = POSSIBLE_SIGNALS_FROM_PLAYING_NODES[the_signal]
		if node.has_signal(the_signal):
			if node.is_connected(the_signal, Callable(self, the_method)) == false:
				node.connect(the_signal, Callable(self, the_method).bind(node, node_uid), CONNECT_DEFERRED)
	# 'console' lets users to double click on a playing node and jump to the respective node on the gird,
	# so we listen for that too ...
	if node.is_connected("gui_input", self._on_playing_node_gui_input) == false:
		node.connect("gui_input", self._on_playing_node_gui_input.bind(node, node_uid), CONNECT_DEFERRED)
	pass

func open_macro(node_uid: int, node_resource:Dictionary, node_element:Node) -> void:
	_OPEN_MACRO = {
		"ID": node_uid,
		"ELEMENT": node_element,
		"MACRO_NODES": [],
	}
	# getting macro child nodes from the central mind
	if node_resource.has("data") && node_resource.data.has("macro"):
		if (node_resource.data.macro is int) && node_resource.data.macro >= 0 :
			var the_macro_resource = Main.Mind.lookup_resource(node_resource.data.macro, "scenes", false) # ... because a macro is a special scene
			if the_macro_resource is Dictionary:
				if the_macro_resource.has("map") && the_macro_resource.map is Dictionary:
					_OPEN_MACRO.MACRO_NODES = the_macro_resource.map.keys()
	print_debug("Type `macro_use` special treatments loaded.", _OPEN_MACRO)
	pass

func play_node(node_uid:int, node_resource:Dictionary, node_map:Dictionary, type:Dictionary, playing_in_slot:int = -1) -> void:
	print_debug("Console, plays node: %s - %s" % [node_uid, node_resource.type])
	var the_play_node = type.console.instantiate()
	var synced_var_set = (
		_VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL[0].duplicate(true)
		if _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.size() > 0 else
		clone_fresh_variable_set()
	)
	var synced_char_set = (
		_CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL[0].duplicate(true)
		if _CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL.size() > 0 else
		clone_fresh_character_set()
	)
	the_play_node.call_deferred("setup_play",
		node_uid,
		node_resource.duplicate(true),
		node_map.duplicate(true),
		playing_in_slot,
		synced_var_set,
		synced_char_set
	)
	listen_to_playing_node(the_play_node, node_uid)
	append_to_terminal(the_play_node, node_uid, node_resource, synced_var_set)
	if node_resource.type == 'macro_use':
		open_macro(node_uid, node_resource, the_play_node)
	# and...
	if node_map.has("skip") && node_map.skip == true:
		# the node is appended, because it's part of the continuum anyway when played, so we ask it to get skipped (hidden)
		reset_node_view_skipped(the_play_node, (!_SHOW_SKIPPED_NODES), true)
		_SKIPPED_NODES[node_uid] = the_play_node
	# finally (re-)cache types for later uses
	_CACHED_TYPES[ node_resource.type ] = type
	pass
	
func reset_node_view_skipped(element:Node, do_hide:bool = true, do_modulate = null) -> void:
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

func play_step_back(how_many:int = 1) -> void:
	if _NODES_IN_TERMINAL.size() >= how_many:
		while (how_many > 0):
			_VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.pop_front()
			_CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL.pop_front()
			var node = _NODES_IN_TERMINAL.pop_front().instance
			if is_instance_valid(node):
				if "_NODE_ID" in node && _SKIPPED_NODES.has(node._NODE_ID):
					_SKIPPED_NODES.erase(node._NODE_ID)
				node.queue_free()
				how_many -= 1
		# after stepping back, we shall...
		# make the last node manually playable by the user, to able them debug and decide!
		if _NODES_IN_TERMINAL.size() > 0 :
			var last = _NODES_IN_TERMINAL[0]
			# yet another treatment for `macro_use` nodes
			if last.wrapper != null: # last was a noe inside an open-macro instance
				_OPEN_MACRO = last.wrapper
				_OPEN_MACRO.ELEMENT.set_view_unplayed()
			elif _OPEN_MACRO != null && _OPEN_MACRO.ID != last.id: # out of the macro
				_OPEN_MACRO.ELEMENT.set_view_played();
				_OPEN_MACRO = null;
			elif last.resource != null && last.resource.type == 'macro_use':
				open_macro(last.id, last.resource, last.instance)
			# ...
			if last.id >= 0: # Non-node printed messages are expected to be `< 0 ~= -1`
				last.instance.call_deferred("step_back")
			reset_node_view_skipped(last.instance, false) # make sure it's visible even skipped
			self.call_deferred("update_scroll_to_v_max")
		self.call_deferred("refresh_variables_list")
		self.call_deferred("refresh_characters_list")
	pass

func request_play_forward(to_node_id:int = -1, to_slot:int = -1, _the_player_one = null, _the_player_one_uid = null):
	print_debug("Play Forward! To node: ", to_node_id, " slot: ", to_slot)
	self.request_mind.emit("console_play_node", {
		"id": to_node_id,
		"slot": to_slot
	})
	pass

func interpret_status_code(code:int, the_player_node = null, the_player_node_uid = null) -> void:
	var caller = {
		"uid": the_player_node_uid if the_player_node_uid != null else (-1)
	}
	if is_instance_valid(the_player_node):
		caller.name = the_player_node._NODE_RESOURCE.name
	else:
		var resource = Main.Mind.lookup_resource(the_player_node_uid)
		caller.name = resource.name if resource is Dictionary && resource.has("name") else "Undefined"
	# ...
	match code:
		CONSOLE_STATUS_CODE.END_EDGE:
			if _OPEN_MACRO != null && the_player_node_uid != _OPEN_MACRO.ID:
				# It seems like a macro's end of line
				_OPEN_MACRO.ELEMENT.play_forward_from() # ~ PLAY_MACRO_END_SLOT
			else:
				print_console( tr(CONSOLE_STATUS_CODE.END_EDGE_MESSAGE).format(caller), Settings.INFO_COLOR, the_player_node )
		CONSOLE_STATUS_CODE.NO_DEFAULT:
			print_console( tr(CONSOLE_STATUS_CODE.NO_DEFAULT_MESSAGE).format(caller), Settings.CAUTION_COLOR, the_player_node )
	pass

func clear_nodes_before(the_player_node, the_player_node_uid) -> void:
	if _PREVENT_CLEARANCE != true:
		if _NODES_IN_TERMINAL.size() > 0:
			while true:
				var oldest = _NODES_IN_TERMINAL[ _NODES_IN_TERMINAL.size() - 1 ] # (we did `push_front` to the array)
				if oldest.id != the_player_node_uid:
					_NODES_IN_TERMINAL.pop_back().instance.queue_free()
					_VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.pop_back()
					_CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL.pop_back()
				else:
					break
			self.call_deferred("refresh_variables_list")
			self.call_deferred("refresh_characters_list")
	else:
		print_console( tr(CLEARANCE_PREVENTION_MESSAGE), CLEARANCE_PREVENTION_MESSAGE_COLOR, the_player_node )
	pass

func reset_synced_variables(update_list:Dictionary, _the_player_node = null, the_player_node_uid = null) -> void:
	# print_debug("reset_synced_variables : ", update_list)
	if _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.size() > 0:
		assert(
			_VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL.size() == _NODES_IN_TERMINAL.size(),
			"Size of synced variable sets are expected to be the same as nodes in terminal!"
		)
		if _NODES_IN_TERMINAL[0].id == the_player_node_uid:
			var the_set = _VARIABLES_SYNCED_WITH_NODES_IN_TERMINAL[0]
			for variable_id in update_list:
				if the_set.has(variable_id):
					if typeof( the_set[variable_id].value ) == typeof( update_list[variable_id] ):
						the_set[variable_id].value = update_list[variable_id]
					else:
						printerr("Invalid Console Node Behavior! The variable %s is tried to be reset by value of other type: " % variable_id, update_list[variable_id])
				else:
					printerr("Invalid Console Node Behavior! Trying to reset nonexistent variable %s by node %s " % [variable_id, the_player_node_uid])
		else:
			printerr(
				"Unexpected behavior: Variable update ignored! Only the last node (%s) is allowed to update variable sets (not requesting %s.)"
				% [_NODES_IN_TERMINAL[0].id, the_player_node_uid]
			)
	else:
		printerr("Unexpected behavior: node " + the_player_node_uid + " tried to update variables while no one is set up in memory!")
	refresh_variables_list()
	pass

func reset_synced_characters_tags(update_list:Dictionary, _the_player_node = null, the_player_node_uid = null) -> void:
	# print_debug("reset_synced_characters_tags : ", update_list)
	if _CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL.size() > 0:
		assert(
			_CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL.size() == _NODES_IN_TERMINAL.size(),
			"Size of synced character sets are expected to be the same as nodes in terminal!"
		)
		if _NODES_IN_TERMINAL[0].id == the_player_node_uid:
			var the_set = _CHARACTERS_SYNCED_WITH_NODES_IN_TERMINAL[0]
			for character_id in update_list:
				if the_set.has(character_id):
					for key in update_list[character_id]:
						if key is String && key.length() > 0:
							var value = update_list[character_id][key]
							if value is String:
								the_set[character_id].tags[ key ] = value
							elif value == null:
								the_set[character_id].tags.erase(key)
							else:
								printerr("Trying to update character %s's tags by node %s with invalid value: " % [character_id, the_player_node_uid], value)
				else:
					printerr("Invalid Console Node Behavior! Trying to reset tag(s) for nonexistent character %s by node %s " % [character_id, the_player_node_uid])
		else:
			printerr(
				"Unexpected behavior: Variable update ignored! Only the last node (%s) is allowed to update character sets (not requesting %s.)"
				% [_NODES_IN_TERMINAL[0].id, the_player_node_uid]
			)
	else:
		printerr("Unexpected behavior: node " + the_player_node_uid + " tried to update characters while no one is set up in memory!")
	refresh_characters_list()
	pass

func refresh_console_setting_menu_buttons() -> void:
	SettingsMenuButtonPopup.set_item_checked(0, _AUTOSCROLL)
	SettingsMenuButtonPopup.set_item_checked(1, _ALLOW_AUTO_PLAY)
	SettingsMenuButtonPopup.set_item_checked(2, _PREVENT_CLEARANCE)
	SettingsMenuButtonPopup.set_item_checked(3, _SHOW_SKIPPED_NODES)
	SettingsMenuButtonPopup.set_item_checked(4, _INSPECT_VARIABLES)
	SettingsMenuButtonPopup.set_item_checked(5, _INSPECT_CHAR_TAGS)
	VariablesInspectorPanel.set_visible(_INSPECT_VARIABLES)
	CharTagsInspectorPanel.set_visible(_INSPECT_CHAR_TAGS)
	if _INSPECT_VARIABLES:
		self.call_deferred("refresh_variables_list")
	if _INSPECT_CHAR_TAGS:
		self.call_deferred("refresh_characters_list")
	if !(_INSPECT_VARIABLES || _INSPECT_CHAR_TAGS):
		DisplayStatesSplitter.set_split_offset(0)
	pass

func _reset_settings_auto_scroll() -> void:
	_AUTOSCROLL = (! _AUTOSCROLL)
	refresh_console_setting_menu_buttons()
	pass

func _reset_settings_allow_auto_play() -> void:
	_ALLOW_AUTO_PLAY = (! _ALLOW_AUTO_PLAY)
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

func _reset_settings_inspect_char_tags() -> void:
	_INSPECT_CHAR_TAGS = (! _INSPECT_CHAR_TAGS)
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
		reset_node_view_skipped(_SKIPPED_NODES[node_uid], do_hide, do_modulate)
	pass

func _on_playing_node_gui_input(event:InputEvent, _node = null, node_uid:int = -1) -> void:
	# on mouse click
	if event is InputEventMouseButton:
		# ... double click
		if event.is_double_click():
			# jump to the respective node on the grid
			if node_uid >= 0 :
				_request_mind("locate_node_on_grid", { "id": node_uid, "highlight": true } )
	pass

# make this panel,
# draggable
# ... it also makes the panel compete for the parent's top z-index by default
@onready var drag_point = $/root/Main/FloatingTools/Control/Console/Sections/Titlebar/Drag
@onready var draggable = Helpers.Draggable.new(self, drag_point)
# and resizable
@onready var resize_point = $/root/Main/FloatingTools/Control/Console/Sections/Titlebar/Resizer
@onready var resizable = Helpers.Resizable.new(self, resize_point)
