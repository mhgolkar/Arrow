# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Preferences Panel
extends Control

signal request_mind()
signal preference_modifications_done()
signal preference_modified()

# @onready var Main = get_tree().get_root().get_child(0)

# panel's ui components
const PREF_PANEL_ACTION_BUTTONS = {
	"dismiss": "/root/Main/Overlays/Control/Preferences/Margin/Sections/Toolbar/Dismiss",
	"confirm": "/root/Main/Overlays/Control/Preferences/Margin/Sections/Toolbar/Confirm",
}
const PREF_PANEL_FIELDS = {
	# CAUTION! handle with care: same lowercase strings (as the keys here,) are used in signaling and saving modified preferences,
	"appearance_theme": "/root/Main/Overlays/Control/Preferences/Margin/Sections/Configs/Scroll/Params/Theme/Selector/Options",
	"appearance_font": "/root/Main/Overlays/Control/Preferences/Margin/Sections/Configs/Scroll/Params/Font/Selector/Tools/Options",
	"appearance_font_browse": "/root/Main/Overlays/Control/Preferences/Margin/Sections/Configs/Scroll/Params/Font/Selector/Tools/Browse",
	"language": "/root/Main/Overlays/Control/Preferences/Margin/Sections/Configs/Scroll/Params/Language/Selector/Options",
	"app_local_dir_path": "/root/Main/Overlays/Control/Preferences/Margin/Sections/Configs/Scroll/Params/WorkDir/Selector/Tools/Path",
	"app_local_dir_browse": "/root/Main/Overlays/Control/Preferences/Margin/Sections/Configs/Scroll/Params/WorkDir/Selector/Tools/Select",
	"app_local_dir_reset_menu": "/root/Main/Overlays/Control/Preferences/Margin/Sections/Configs/Scroll/Params/WorkDir/Selector/Tools/Reset",
	"history_size": "/root/Main/Overlays/Control/Preferences/Margin/Sections/Configs/Scroll/Params/History/Selector/Size/Value",
}
var ACTIONS = {}
var FIELDS = {}

const FIELDS_VALUE_PROPERTY = {
	"appearance_theme": "selected",
	"language": "selected",
	"app_local_dir_path": "text",
	"history_size": "value",
}

const LANGUAGE_ITEM_TEXT_TEMPLATE = "{name} ({code})"

func _ready() -> void:
	get_the_ui_nodes_all()
	refresh_appearance_theme_options()
	refresh_appearance_font_options()
	refresh_language_options()
	register_connections()
	pass

func get_the_ui_nodes_all() -> void:
	for button in PREF_PANEL_ACTION_BUTTONS:
		ACTIONS[button] = get_node( PREF_PANEL_ACTION_BUTTONS[button] )
	for field in PREF_PANEL_FIELDS:
		FIELDS[field] = get_node( PREF_PANEL_FIELDS[field] )
	pass

func refresh_appearance_theme_options() -> void:
	var selected_id = FIELDS.appearance_theme.get_selected_id()
	FIELDS.appearance_theme.clear()
	for theme_id in Settings.THEMES:
		FIELDS.appearance_theme.add_item(tr(Settings.THEMES[theme_id].name), theme_id)
	if selected_id >= 0:
		FIELDS.appearance_theme.select(FIELDS.appearance_theme.get_item_index(selected_id))
	pass

func refresh_appearance_font_options() -> void:
	var selected_value = FIELDS.appearance_font.get_selected_metadata()
	FIELDS.appearance_font.clear()
	add_font_option(tr("Follow Language"), "auto")
	add_font_option(tr("Theme Default"), "default")
	for filename in ResourceLoader.list_directory(Settings.UI_FONTS_DIR):
		if filename.get_extension().to_lower() in Settings.UI_FONT_EXTENSIONS:
			var label = filename.get_basename()
			if filename == "NotoSansCJKtc-Medium.otf":
				label += " (Traditional Chinese Default)"
			add_font_option(label, Settings.UI_FONTS_DIR + filename)
	if selected_value != null:
		select_font_selector_for(selected_value)
	pass

func add_font_option(label:String, value:String) -> int:
	var idx = FIELDS.appearance_font.item_count
	FIELDS.appearance_font.add_item(label)
	FIELDS.appearance_font.set_item_metadata(idx, value)
	return idx

func select_font_selector_for(value) -> int:
	if value is int:
		value = ["auto", "default", "res://assets/fonts/GenSekiGothic2TW-R.otf"][clampi(value, 0, 2)]
	for idx in FIELDS.appearance_font.item_count:
		if FIELDS.appearance_font.get_item_metadata(idx) == value:
			FIELDS.appearance_font.select(idx)
			return idx
	if value is String && FileAccess.file_exists(value):
		var idx = add_font_option(value.get_file().get_basename() + " " + tr("(External)"), value)
		FIELDS.appearance_font.select(idx)
		return idx
	FIELDS.appearance_font.select(0)
	return 0
	
func refresh_language_options() -> void:
	FIELDS.language.clear()
	var translations_dir = Helpers.Utils.normalize_dir_path(Settings.UI_TRANSLATIONS_DIR)
	for each_rel_path in DirAccess.get_files_at(translations_dir):
		# Prefer editable PO sources when both PO and compiled MO files exist.
		if each_rel_path.get_extension().to_lower() == "mo" && FileAccess.file_exists(
			translations_dir + each_rel_path.get_basename() + ".po"
		):
			continue
		var translation: Translation = ResourceLoader.load(translations_dir + each_rel_path, "Translation", ResourceLoader.CacheMode.CACHE_MODE_REUSE)
		if translation != null:
			TranslationServer.add_translation(translation)
	var idx = 0
	var loaded_locals = TranslationServer.get_loaded_locales()
	for locale in loaded_locals:
		var language_item_text = LANGUAGE_ITEM_TEXT_TEMPLATE.format({
			"name": tr( TranslationServer.get_locale_name(locale) ),
			"code": locale,
		})
		FIELDS.language.add_item(language_item_text, idx)
		FIELDS.language.set_item_metadata(idx, locale)
		idx += 1
	print_debug("%s locales loaded: %s" % [idx, loaded_locals])
	pass

func select_language_selector_for(locale = TranslationServer.get_locale()) -> int:
	var all = FIELDS.language.get_item_count()
	for idx in range(0, all):
		if FIELDS.language.get_item_metadata(idx) == locale:
			FIELDS.language.select(idx)
			return idx
	return -1

func reset_language(by_locale:String = "en") -> void:
	# Translations are loaded dynamically after the main scene is instantiated.
	# Force a locale transition when the OS locale already equals the saved one,
	# otherwise existing controls never receive NOTIFICATION_TRANSLATION_CHANGED.
	if TranslationServer.get_locale() == by_locale:
		TranslationServer.set_locale("en" if by_locale != "en" else "fa")
	TranslationServer.set_locale(by_locale)
	refresh_appearance_theme_options()
	refresh_appearance_font_options()
	select_language_selector_for(by_locale)
	pass

func register_connections() -> void:
	# action buttons
	ACTIONS.dismiss.pressed.connect(self._dismiss_preferences)
	ACTIONS.confirm.pressed.connect(self._confirm_preferences)
	# fields
	FIELDS.appearance_theme.item_selected.connect(self.preprocess_and_emit_modification_signal.bind("appearance_theme"), CONNECT_DEFERRED)
	FIELDS.appearance_font.item_selected.connect(self.preprocess_and_emit_modification_signal.bind("appearance_font"), CONNECT_DEFERRED)
	FIELDS.appearance_font_browse.pressed.connect(self.prompt_font_file)
	FIELDS.language.item_selected.connect(self.preprocess_and_emit_modification_signal.bind("language"), CONNECT_DEFERRED)
	FIELDS.app_local_dir_browse.pressed.connect(self.prompt_local_dir_path, CONNECT_DEFERRED)
	FIELDS.app_local_dir_reset_menu.item_selected_value.connect(self._on_app_local_dir_reset_menu_item_selected, CONNECT_DEFERRED)
	FIELDS.history_size.get_line_edit().text_changed.connect(self.preprocess_and_emit_modification_signal.bind("history_size"), CONNECT_DEFERRED)
	FIELDS.history_size.value_changed.connect(self.preprocess_and_emit_modification_signal.bind("history_size"), CONNECT_DEFERRED)
	pass

func refresh_fields_view(preferences:Dictionary) -> void:
	for field in preferences:
		match field:
			"appearance_font":
				select_font_selector_for(preferences[field])
			"language":
				select_language_selector_for.call_deferred(preferences[field])
			_:
				if field in FIELDS:
					FIELDS[field].set_deferred(FIELDS_VALUE_PROPERTY[field], preferences[field])
	pass

func _dismiss_preferences() -> void:
	self.preference_modifications_done.emit(false)
	pass

func _confirm_preferences() -> void:
	self.preference_modifications_done.emit(true)
	pass

func preprocess_and_emit_modification_signal(value, field) -> void:
	# get and preprocess preferences ...
	match field:
		"appearance_theme":
			value = FIELDS[field].get_item_id(value) # Convert idx to resource id
		"appearance_font":
			value = FIELDS.appearance_font.get_item_metadata(value)
		"language":
			value = FIELDS.language.get_item_metadata(value)
		"history_size":
			value = max(0, int(value))
	# .. then signal
	self.preference_modified.emit(field, value)
	pass

func handle_app_local_dir_selection(new_dir_path):
	FIELDS.app_local_dir_path.set_deferred("text", new_dir_path)
	self.preference_modified.emit("app_local_dir_path", new_dir_path)
	pass

func _on_app_local_dir_selected(dir:String) -> void:
	dir = Helpers.Utils.try_making_clean_relative_dir(dir, true)
	handle_app_local_dir_selection(dir)
	pass

func _on_app_local_dir_reset_menu_item_selected(reset_value_dir_path) -> void:
	handle_app_local_dir_selection(reset_value_dir_path)
	pass

func prompt_local_dir_path() -> void:
	var options_adjusted = Settings.PATH_DIALOG_PROPERTIES.DIRECTORY.LOCAL_APP.duplicate(true)
	var app_local_dir_abs_path = Helpers.Utils.get_abs_path( FIELDS.app_local_dir_path.get_text() )
	options_adjusted["current_path"] = app_local_dir_abs_path
	options_adjusted["current_dir"] = app_local_dir_abs_path
	self.request_mind.emit("prompt_path_for_requester", {
		"callback": "_on_app_local_dir_selected",
		"arguments": [],
		"options": options_adjusted
	})
	pass

func prompt_font_file() -> void:
	self.request_mind.emit("prompt_path_for_requester", {
		"callback": "_on_font_file_selected",
		"arguments": [],
		"options": Settings.PATH_DIALOG_PROPERTIES.FONT.OPEN.duplicate(true)
	})
	pass

func _on_font_file_selected(path:String) -> void:
	if path.get_extension().to_lower() not in Settings.UI_FONT_EXTENSIONS:
		return
	select_font_selector_for(path)
	self.preference_modified.emit("appearance_font", path)
	pass
