# Arrow
# Game Narrative Design Tool
# % contributor(s) %

# % menu identity %
extends %BASE%

# reference to `Main` (root)
onready var Main = get_tree().get_root().get_child(0)

# reference to the menu-button's popup-menu
onready var popup = self.get_popup()

# list of item keys for the menu-button's popup-menu
# order of the items is used as their `id` and `null` means a separator
var _MENU_ITEMS = [] # e.g. ["ITEM_X", null, "ITEM_Y"]
var _MENU_ITEMS_DATA = [
	# { "text": "item x the zero " },
	# null,
	# { "text": "item y", "text_toggled": "item y toggled" },
]
# items listed by key to ...
var _IDX = {} # index
var _ID = {} # id

# called when the node enters the scene tree for the first time
func _ready()%VOID_RETURN%:
	self.create_menu_items()
	self.update_menu_items_view()
	popup.connect("id_pressed", self, "_on_self_popup_item_id_pressed", [], CONNECT_DEFERRED)
	pass

# adds items listed in _MENU_ITEMS to the menu-button's popup-menu
# ... and keeps track of their indices in _IDX by key
func create_menu_items()%VOID_RETURN%:
	popup.clear()
	var item_id = 0; # here, id is the same as order of the item
	for item in _MENU_ITEMS:
		if item != null:
			_ID[item] = item_id
			popup.add_item(_MENU_ITEMS_DATA[item_id].text, item_id)
			_IDX[item] = popup.get_item_index(item_id)
		else:
			popup.add_separator();
		item_id += 1
	pass

# this will come in handy when you want to update the items,
# like them being `enabled` or changing their `text`
func update_menu_items_view()%VOID_RETURN%:
	# popup.set_item_text(_IDX.SOME_ITEM_KEY, (_MENU_ITEMS_DATA[_ID.SOME_ITEM_KEY].text_toggled if SOME_CONDITION  else _MENU_ITEMS_DATA[_ID.SOME_ITEM_KEY].text))
	pass

# handles which action shall be called if an item of the menu-button's popup-menu is pressed
func _on_self_popup_item_id_pressed(id)%VOID_RETURN%:
	print_debug("menu popup item pressed: ", id, " - ", _MENU_ITEMS[id])
	# match id:
		#_ID.SOME_ITEM_KEY:
		#	some_function()
	pass


