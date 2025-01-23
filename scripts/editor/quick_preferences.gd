# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Quick Preferences
extends MenuButton

signal quick_preference()

@onready var Main = get_tree().get_root().get_child(0)

@onready var QuickPreferencesPopup = self.get_popup()

const QUICK_PREFERENCES_MENU = {
	0: { "label": "Auto Inspection", "is_checkbox": true , "preference": "_AUTO_INSPECT", "command": "auto_inspect" },
	1: { "label": "Auto Node Update", "is_checkbox": true , "preference": "_AUTO_NODE_UPDATE", "command": "auto_node_update" },
	2: { "label": "Reset on Reinspection", "is_checkbox": true , "preference": "_RESET_ON_REINSPECTION", "command": "reset_on_reinspection" },
	3: { "label": "Quick Node Insertion", "is_checkbox": true , "preference": "_QUICK_NODE_INSERTION", "command": "quick_node_insertion" },
	4: { "label": "Connection Assist", "is_checkbox": true , "preference": "_CONNECTION_ASSIST", "command": "connection_assist" },
	5: { "label": "Auto Rebuild Runtime(s)", "is_checkbox": true , "preference": "_AUTO_REBUILD_RUNTIME_TEMPLATES", "command": "auto_rebuild_runtime_templates" },
}

func _ready() -> void:
	load_quick_preferences_menu()
	QuickPreferencesPopup.id_pressed.connect(self._on_quick_preferences_popup_item_id_pressed, CONNECT_DEFERRED)
	pass

func load_quick_preferences_menu() -> void:
	QuickPreferencesPopup.clear()
	for item_id in QUICK_PREFERENCES_MENU:
		var item = QUICK_PREFERENCES_MENU[item_id]
		if item == null: # separator
			QuickPreferencesPopup.add_separator()
		else:
			if item.has("is_checkbox") && item.is_checkbox == true:
				QuickPreferencesPopup.add_check_item(item.label, item_id)
			else:
				QuickPreferencesPopup.add_item(item.label, item_id)
	# update checkboxes ...
	refresh_quick_preferences_menu_view()
	pass

func refresh_quick_preferences_menu_view() -> void:
	for item_id in QUICK_PREFERENCES_MENU:
		if QUICK_PREFERENCES_MENU[item_id] != null:
			QuickPreferencesPopup.set_item_checked( item_id, Main[ QUICK_PREFERENCES_MENU[item_id].preference ] )
	pass

func _on_quick_preferences_popup_item_id_pressed(id) -> void:
	# print_debug("Quick Preference Pressed: ", id, QUICK_PREFERENCES_MENU[id])
	self.quick_preference.emit(
		( ! Main[ QUICK_PREFERENCES_MENU[id].preference ] ),
		QUICK_PREFERENCES_MENU[id].command
	)
	pass
