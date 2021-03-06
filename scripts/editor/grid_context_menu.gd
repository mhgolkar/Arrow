# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Grid Context Menu
# (right-click popup)
extends PopupPanel

signal request_mind

onready var Main = get_tree().get_root().get_child(0)
onready var Grid = get_node(Addressbook.GRID)

# cached click point position
# (where user has right-clicked and probably wants the node to be placed)
var _CLICK_POINT_POSITION:Vector2
var _CLICK_POINT_OFFSET:Vector2

onready var NodeInsertFilterInput = get_node(Addressbook.GRID_CONTEXT_MENU.NODE_INSERT_FILTER_INPUT)
onready var NodeInsertList = get_node(Addressbook.GRID_CONTEXT_MENU.NODE_INSERT_LIST)
onready var InsertNodesButton = get_node(Addressbook.GRID_CONTEXT_MENU.INSERT_BUTTON)
onready var CleanClipboardButton = get_node(Addressbook.GRID_CONTEXT_MENU.CLEAN_CLIPBOARD_BUTTON)
onready var CopyNodesButton = get_node(Addressbook.GRID_CONTEXT_MENU.COPY_BUTTON)
onready var CutNodesButton = get_node(Addressbook.GRID_CONTEXT_MENU.CUT_BUTTON)
onready var PasteClipboardButton = get_node(Addressbook.GRID_CONTEXT_MENU.PASTE_BUTTON)
onready var RemoveNodesButton = get_node(Addressbook.GRID_CONTEXT_MENU.REMOVE_BUTTON)

const CLIPBOARD_MODE = Settings.CLIPBOARD_MODE

var _NODE_INSERT_LIST_FULL = []

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	self.connect("about_to_show", self, "_on_about_to_show", [], 0)
	Main.connect("mind_initialized", self, "try_cache_node_type_list_from_mind", [true], CONNECT_ONESHOT)
	NodeInsertFilterInput.connect("text_changed", self, "filter_node_insert_list_items_view", [], CONNECT_DEFERRED)
	NodeInsertList.connect("multi_selected", self, "_on_node_insert_list_selection_altered", [], CONNECT_DEFERRED)
	NodeInsertList.connect("item_activated", self, "_on_node_insert_list_item_activated", [], CONNECT_DEFERRED)
	InsertNodesButton.connect("pressed", self, "_on_node_insert_selected_type_button_pressed", [], CONNECT_DEFERRED)
	RemoveNodesButton.connect("pressed", self, "request_mind", ["remove_selected_nodes", null, true], CONNECT_DEFERRED)
	CleanClipboardButton.connect("pressed", self, "request_mind", ["clean_clipboard", null, true], CONNECT_DEFERRED)
	CopyNodesButton.connect("pressed", self, "request_mind", ["clipboard_push_selection", CLIPBOARD_MODE.COPY, true], CONNECT_DEFERRED)
	CutNodesButton.connect("pressed", self, "request_mind", ["clipboard_push_selection", CLIPBOARD_MODE.CUT, true], CONNECT_DEFERRED)
	PasteClipboardButton.connect("pressed", self, "request_clipboard_pull", [], CONNECT_DEFERRED)
	pass

func try_cache_node_type_list_from_mind(refresh_list:bool = true):
	if _NODE_INSERT_LIST_FULL.size() == 0:
		if Main.Mind && Main.Mind.NODE_TYPES_LIST:
			_NODE_INSERT_LIST_FULL = Main.Mind.NODE_TYPES_LIST
	if refresh_list:
		filter_node_insert_list_items_view()
	pass

func show_up(position:Vector2, offset:Vector2) -> void:
	_CLICK_POINT_POSITION = position
	_CLICK_POINT_OFFSET = offset
	disable_insert_button_if_nothing_is_there()
	self.set_position(position)
	self.popup()
	pass

func disable_insert_button_if_nothing_is_there(force_disabled:bool = false) -> void:
	var disable
	if force_disabled == true :
		disable = force_disabled
	else:
		if (NodeInsertList.get_selected_items()).size() == 0 || NodeInsertList.get_item_count() == 0:
			disable = true
		else:
			disable = false
	InsertNodesButton.set_disabled(disable)
	pass

func reset_quick_edit_buttons():
	var there_is_selection = (Grid._ALREADY_SELECTED_NODE_IDS.size() > 0)
	var there_is_highlight = (Grid._HIGHLIGHTED_NODES.size() > 0)
	var selected_nodes_are_removeable = there_is_selection && Main.Mind.batch_remove_resources(Grid._ALREADY_SELECTED_NODE_IDS, "nodes", true, true) # check-only
	var selected_nodes_are_moveable = there_is_selection && Main.Mind.are_nodes_moveable(Grid._ALREADY_SELECTED_NODE_IDS)
	var clipboard_has_copy_or_paste = Main.Mind.clipboard_available()
	PasteClipboardButton.set_disabled( clipboard_has_copy_or_paste == false )
	RemoveNodesButton.set_disabled( selected_nodes_are_removeable == false )
	CutNodesButton.set_disabled( selected_nodes_are_moveable == false )
	# copy and clean-clipboard buttons will switch visibility when there_is_selection
	CleanClipboardButton.set("visible", there_is_selection == false && (clipboard_has_copy_or_paste || there_is_highlight))
	CleanClipboardButton.set_disabled( there_is_selection || there_is_highlight == false )
	CopyNodesButton.set("visible", there_is_selection ||  clipboard_has_copy_or_paste == false )
	CopyNodesButton.set_disabled( there_is_selection == false )
	# Note: `InsertNodesButton` & `NodeInsertList` are handled elsewheres.
	pass

func _on_about_to_show() -> void:
	NodeInsertList.ensure_current_is_visible()
	reset_quick_edit_buttons()
	pass

func get_restricted_types() -> Array:
	var restriction:Array
	if Main.Mind.is_scene_macro():
		restriction = Settings.NODE_TYPES_RESTRICTED_IN_MACROS
	else:
		restriction = []
	return restriction

# refreshes the list of available node types (modules)
# also updates the index and id caches and attaches meta-data to them
func filter_node_insert_list_items_view(query:String = "", try_read_filter_input:bool = false) -> void:
	clear_node_insert_list()
	if query.length() <= 0 && try_read_filter_input == true:
		query = NodeInsertFilterInput.get_text()
	var show_all = true if (query.length() <= 0 || query == "*" ) else false
	var restricted_items = get_restricted_types()
	var item_order = 0;
	for item in _NODE_INSERT_LIST_FULL:
		if (restricted_items.has(item) == false):
			var item_details = _NODE_INSERT_LIST_FULL[item]
			if show_all || (item_details.text.findn(query, 0) >= 0) :
				NodeInsertList.add_item(item_details.text, item_details.icon)
				NodeInsertList.set_item_metadata(item_order, item_details)
				item_order += 1 
	NodeInsertList.sort_items_by_text()
	disable_insert_button_if_nothing_is_there()
	pass

func clear_node_insert_list() -> void :
	NodeInsertList.clear()
	pass

func _on_node_insert_list_selection_altered(_index, _selected) -> void:
	disable_insert_button_if_nothing_is_there()
	pass

func _on_node_insert_list_item_activated(item_index:int) -> void:
	insert_selected_nodes_from_list()
	pass

func _on_node_insert_selected_type_button_pressed() -> void:
	insert_selected_nodes_from_list()
	pass
	
func insert_selected_nodes_from_list() -> void:
	var items_indices = NodeInsertList.get_selected_items()
	if items_indices.size() > 0 :
		var item_types = []
		for item_index in items_indices:
			var item_type = NodeInsertList.get_item_metadata(item_index).type
			item_types.push_back(item_type)
		request_mind("insert_node", { "nodes": item_types, "offset": _CLICK_POINT_OFFSET }, true )
	pass

func request_clipboard_pull() -> void:
	request_mind("clipboard_pull", _CLICK_POINT_OFFSET, true)
	pass

func request_mind(req:String, args, hide_menu:bool = false) -> void:
	self.emit_signal("request_mind", req, args)
	# ... and close the grid context menu (popup)
	if hide_menu:
		self.hide()
	pass

