# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Preferences Panel
extends PanelContainer

signal request_mind
signal preference_modifications_done
signal preference_modified

# onready var Main = get_tree().get_root().get_child(0)

var Utils = Helpers.Utils

# panel's ui components
var ACTIONS = {}
var FIELDS = {}

const FIELDS_VALUE_PROPERTY = {
	"ui_scale": "value",
	"appearance_theme": "selected",
	"language": "selected",
	"app_local_dir_path": "text",
}

const LANGUAGE_ITEM_TEXT_TEMPLATE = "{name} ({code})"

func _ready() -> void:
	get_the_ui_nodes_all()
	refresh_appearance_theme_options()
	refresh_language_options()
	register_connections()
	pass

func get_the_ui_nodes_all() -> void:
	for button in Addressbook.PREF_PANEL_ACTION_BUTTONS:
		ACTIONS[button] = get_node( Addressbook.PREF_PANEL_ACTION_BUTTONS[button] )
	for field in Addressbook.PREF_PANEL_FIELDS:
		FIELDS[field] = get_node( Addressbook.PREF_PANEL_FIELDS[field] )
	pass

func refresh_appearance_theme_options() -> void:
	FIELDS.appearance_theme.clear()
	for theme_id in Settings.THEMES:
		FIELDS.appearance_theme.add_item(Settings.THEMES[theme_id].name, theme_id)
	pass
	
func refresh_language_options() -> void:
	FIELDS.language.clear()
	for lang_id in Settings.SUPPORTED_UI_LANGUAGES:
		var language_item_text = LANGUAGE_ITEM_TEXT_TEMPLATE.format( Settings.SUPPORTED_UI_LANGUAGES[lang_id] )
		FIELDS.language.add_item(language_item_text, lang_id)
	pass

func register_connections() -> void:
	# action buttons
	ACTIONS.dismiss.connect("pressed", self, "_dismiss_preferences", [], CONNECT_DEFERRED)
	ACTIONS.confirm.connect("pressed", self, "_confirm_preferences", [], CONNECT_DEFERRED)
	# fields
	FIELDS.ui_scale.connect("value_changed", self, "preprocess_and_emit_modification_signal", ["ui_scale"], CONNECT_DEFERRED)
	FIELDS.appearance_theme.connect("item_selected", self, "preprocess_and_emit_modification_signal", ["appearance_theme"], CONNECT_DEFERRED)
	FIELDS.language.connect("item_selected", self, "preprocess_and_emit_modification_signal", ["language"], CONNECT_DEFERRED)
	FIELDS.app_local_dir_browse.connect("pressed", self, "prompt_local_dir_path", [], CONNECT_DEFERRED)
	FIELDS.app_local_dir_reset_menu.connect("item_selected_value", self, "_on_app_local_dir_reset_menu_item_selected", [], CONNECT_DEFERRED)
	pass

func refresh_fields_view(preferences:Dictionary) -> void:
	for field in preferences:
		if field in FIELDS:
			FIELDS[field].set_deferred(FIELDS_VALUE_PROPERTY[field], preferences[field])
	pass

func _dismiss_preferences() -> void:
	self.emit_signal("preference_modifications_done", false)
	pass

func _confirm_preferences() -> void:
	self.emit_signal("preference_modifications_done", true)
	pass

func preprocess_and_emit_modification_signal(value, field) -> void:
	# get and preprocess preferences ...
	match field:
		"appearance_theme":
			value = FIELDS.appearance_theme.get_item_id(value) # Convert idx to theme_id
		"language":
			value = FIELDS.language.get_item_id(value) # Convert idx to lang_id
	# .. then signal
	self.emit_signal("preference_modified", field, value)
	pass

func handle_app_local_dir_selection(new_dir_path):
	FIELDS.app_local_dir_path.set_deferred("text", new_dir_path)
	emit_signal("preference_modified", "app_local_dir_path", new_dir_path)
pass

func _on_app_local_dir_selected(dir:String) -> void:
	dir = Utils.try_making_clean_relative_dir(dir, true)
	handle_app_local_dir_selection(dir)
	pass

func _on_app_local_dir_reset_menu_item_selected(reset_value_dir_path) -> void:
	handle_app_local_dir_selection(reset_value_dir_path)
	pass

func prompt_local_dir_path() -> void:
	var options_adjusted = Settings.PATH_DIALOG_PROPERTIES.DIRECTORY.LOCAL_APP.duplicate(true)
	var app_local_dir_abs_path = Utils.get_abs_path( FIELDS.app_local_dir_path.get_text() )
	options_adjusted["current_path"] = app_local_dir_abs_path
	options_adjusted["current_dir"] = app_local_dir_abs_path
	emit_signal("request_mind", "prompt_path_for_requester", {
		"callback": "_on_app_local_dir_selected",
		"arguments": [],
		"options": options_adjusted
	})
	pass
