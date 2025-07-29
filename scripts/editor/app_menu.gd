# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# App Menu
extends MenuButton

@onready var TheTree = get_tree()
@onready var TheWindow = TheTree.get_root()
@onready var Main = TheWindow.get_child(0)

@onready var popup = self.get_popup()

var _MENU_ITEMS = [
	"PREFERENCES",
	null,
	"FULLSCREEN",
	"ALWAYS_ON_TOP",
	"REFRESH",
	null,
	"ABOUT",
	null,
	"CLEAR",
	null,
	"QUIT",
]

var _MENU_ITEMS_DATA = [
	{ "text": "Preferences" },
	null,
	{ "text": "Fullscreen (F11)", "text_toggled": "Exit Fullscreen (F11)" },
	{ "text": "Stay Above", "text_toggled": "Leave Above", "html5": false },
	{ "text": "Refresh", "html5": true },
	null,
	{ "text": "About" },
	null,
	{ "text": "Clear", "html5": true },
	null,
	{ "text": "Quit" },
]

# items listed by key to ...
var _IDX = {} # indices
var _ID = {} # ids

func _ready() -> void:
	self.create_menu_items()
	self.update_menu_items_view()
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

func update_menu_items_view() -> void:
	var is_fullscreen = (DisplayServer.window_get_mode() >= DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	popup.set_item_text(
		_IDX.FULLSCREEN,
		_MENU_ITEMS_DATA[_ID.FULLSCREEN].text_toggled if is_fullscreen else _MENU_ITEMS_DATA[_ID.FULLSCREEN].text
	)
	if _IDX.has("ALWAYS_ON_TOP"):
		popup.set_item_text(
			_IDX.ALWAYS_ON_TOP,
			_MENU_ITEMS_DATA[_ID.ALWAYS_ON_TOP].text_toggled if TheWindow.always_on_top else _MENU_ITEMS_DATA[_ID.ALWAYS_ON_TOP].text
		)
	pass

func force_clear_browser_storage() -> void:
	Html5Helpers.Utils.clear_browser_storage()
	pass

func prompt_to_clear_browser_storage() -> void:
	if Html5Helpers.Utils.is_browser():
		Main.Mind.Notifier.call_deferred(
			"show_notification",
			"Are you sure ?",
			"BROWSER_STORAGE_CLEAR_PROMPT",
			[
				{ 
					"label": "Ok; Terminate!",
					"callee": self,
					"method": "force_clear_browser_storage",
					"arguments": []
				},
			],
			Settings.WARNING_COLOR
		)
	else:
		printerr("Trying to clear browser storage out of context!")
	pass

func _on_self_popup_item_id_pressed(id:int) -> void:
	print_debug("app menu popup item pressed: ", id, " - ", _MENU_ITEMS[id])
	match id:
		_ID.PREFERENCES:
			Main.UI.call_deferred("set_panel_visibility", "preferences", true)
		_ID.FULLSCREEN:
			Main.UI.call_deferred("toggle_fullscreen")
		_ID.ALWAYS_ON_TOP:
			Main.UI.call_deferred("toggle_always_on_top")
		_ID.REFRESH:
			Html5Helpers.Utils.refresh_window()
		_ID.ABOUT:
			Main.call_deferred("toggle_about")
		_ID.QUIT:
			Main.call_deferred("safe_quit_app")
		_ID.CLEAR:
			prompt_to_clear_browser_storage()
	pass
