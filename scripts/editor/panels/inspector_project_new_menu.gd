# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Inspector :: Project Tab :: New Project
extends MenuButton

signal relay_request_mind()

@onready var Main = get_tree().get_root().get_child(0)

@onready var popup = self.get_popup()

var _MENU_ITEMS = ["NEW_BLANK", "USE_CURRENT", null, "IMPORT_FILE", "BROWSE_FILE"]
var _MENU_ITEMS_DATA = [
	{ "text": "New Blank Project", "request": "new_project", "arguments": "blank"},
	{ "text": "Save Current & Continue", "request": "new_project", "arguments": "from_current"},
	null,
	{ "text": "Load Project", "request": "new_project", "arguments": "from_file"},
	{ "text": "Import Project File", "request": "new_project", "arguments": "from_browsed", "html5": true }
]
# items listed by key to ...
var _IDX = {} # index
var _ID = {} # id

func _ready() -> void:
	self.create_menu_items()
	# self.update_menu_items_view()
	popup.id_pressed.connect(self._on_self_popup_item_id_pressed, CONNECT_DEFERRED)
	pass

func create_menu_items() -> void:
	popup.clear()
	var being_in_browser = Html5Helpers.Utils.is_browser()
	var item_id = 0; # here, id is the same as order of the item
	for item in _MENU_ITEMS:
		if item != null:
			_ID[item] = item_id
			var the_item = _MENU_ITEMS_DATA[item_id];
			if (
				the_item.has("html5") == false || # (is always available)
				(the_item.html5 == being_in_browser) # (depending on the environment)
			):
				popup.add_item(the_item.text, item_id)
				_IDX[item] = popup.get_item_index(item_id)
		else:
			popup.add_separator();
		item_id += 1
	pass

#func update_menu_items_view() -> void:
#	# popup.set_item_text(_IDX.SOME_ITEM_KEY, (_MENU_ITEMS_DATA[_ID.SOME_ITEM_KEY].text_toggled if SOME_CONDITION  else _MENU_ITEMS_DATA[_ID.SOME_ITEM_KEY].text))
#	pass

func _on_self_popup_item_id_pressed(id) -> void:
	print_debug("new local project popup item pressed: ", id, " - ", _MENU_ITEMS[id])
	var req = _MENU_ITEMS_DATA[ id ].request
	var args = _MENU_ITEMS_DATA[ id ].arguments
	self.relay_request_mind.emit(req, args)
	pass
