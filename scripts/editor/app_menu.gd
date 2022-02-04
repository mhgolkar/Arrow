# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# App Menu
extends MenuButton

onready var TheTree = get_tree()
onready var Main = TheTree.get_root().get_child(0)

onready var popup = self.get_popup()

var _MENU_ITEMS = [
	"PREFERENCES",
	null,
	"FULLSCREEN",
	"ALWAYS_ON_TOP",
	# "BORDERLESS", # not supported enough yet!
	"MAXIMIZE",
	"MINIMIZE",
	"REFRESH",
	null,
	"ABOUT",
	null,
	"QUIT",
	"CLEAR",
]

var _MENU_ITEMS_DATA = [
	{ "text": "Preferences" },
	null,
	{ "text": "Fullscreen (F11)", "text_toggled": "Exit Fullscreen (F11)" },
	{ "text": "Keep Above", "text_toggled": "Don't Keep Above", "html5": false },
	# { "text": "Go Borderless", "text_toggled": "Show Borders", "html5": false },
	{ "text": "Maximize", "text_toggled": "Restore", "html5": false },
	{ "text": "Minimize", "html5": false },
	{ "text": "Refresh", "html5": true },
	null,
	{ "text": "About" },
	null,
	{ "text": "Quit", "html5": false },
	{ "text": "Clear", "html5": true },
]

# items listed by key to ...
var _IDX = {} # indices
var _ID = {} # ids

func _ready() -> void:
	self.create_menu_items()
	self.update_menu_items_view()
	popup.connect("id_pressed", self, "_on_self_popup_item_id_pressed", [], CONNECT_DEFERRED)
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
	if Html5Helpers.Utils.is_browser():
		# fullscreen is the only available item with switchable state in browser
		if OS.is_window_fullscreen() :
			popup.set_item_text(_IDX.FULLSCREEN, _MENU_ITEMS_DATA[_ID.FULLSCREEN].text_toggled)
		else:
			popup.set_item_text(_IDX.FULLSCREEN, _MENU_ITEMS_DATA[_ID.FULLSCREEN].text)
	else:
		# fullscreen
			# also updates maximize/restore because it's not portable/safe to let maximize happen on a fullscreen window
		if OS.is_window_fullscreen() :
			popup.set_item_text(_IDX.FULLSCREEN, _MENU_ITEMS_DATA[_ID.FULLSCREEN].text_toggled)
			popup.set_item_disabled(_IDX.MAXIMIZE, true)
		else:
			popup.set_item_text(_IDX.FULLSCREEN, _MENU_ITEMS_DATA[_ID.FULLSCREEN].text)
			popup.set_item_disabled(_IDX.MAXIMIZE, false)
		# others
		popup.set_item_text(_IDX.ALWAYS_ON_TOP, (_MENU_ITEMS_DATA[_ID.ALWAYS_ON_TOP].text_toggled if OS.is_window_always_on_top() else _MENU_ITEMS_DATA[_ID.ALWAYS_ON_TOP].text))
		# popup.set_item_text(_IDX.BORDERLESS, (_MENU_ITEMS_DATA[_ID.BORDERLESS].text_toggled if OS.get_borderless_window() else _MENU_ITEMS_DATA[_ID.BORDERLESS].text))
		popup.set_item_text(_IDX.MAXIMIZE, (_MENU_ITEMS_DATA[_ID.MAXIMIZE].text_toggled if OS.is_window_maximized() else _MENU_ITEMS_DATA[_ID.MAXIMIZE].text))
		print_debug('window state', ' -full:', OS.is_window_fullscreen(), ' -max:', OS.is_window_maximized(), ' -top:', OS.is_window_always_on_top())
	pass

func force_clear_browser_storage() -> void:
	Html5Helpers.Utils.clear_browser_storage()
	pass

func prompt_to_clear_browser_storage() -> void:
	if Html5Helpers.Utils.is_browser():
		Main.Mind.Notifier.call_deferred(
			"show_notification",
			"Are you sure ?",
			(
				"You are about to clear storage.\n" +
				"This will permanently remove projects from virtual file-system of Arrow in this browser.\n" +
				"Removed data will not be recoverable.\n"
			),
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
		#_ID.BORDERLESS:
		#	Main.UI.call_deferred("toggle_borderless_window")
		_ID.MAXIMIZE:
			Main.UI.call_deferred("toggle_maximized")
		_ID.MINIMIZE:
			Main.UI.call_deferred("minimize_window")
		_ID.REFRESH:
			Html5Helpers.Utils.refresh_window()
		_ID.ABOUT:
			Main.call_deferred("toggle_about")
		_ID.QUIT:
			Main.call_deferred("safe_quit_app")
		_ID.CLEAR:
			prompt_to_clear_browser_storage()
	pass
