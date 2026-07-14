# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# About Panel
extends Control

@onready var Main = get_tree().get_root().get_child(0)

@onready var CloseButton = $/root/Main/Overlays/Control/About/Margin/Half/Right/Toolbar/Close
@onready var AppVersionDisplay = $/root/Main/Overlays/Control/About/Margin/Half/Left/Information/Version
@onready var Copyright = $/root/Main/Overlays/Control/About/Margin/Half/Right/Tabs/Copyright
@onready var Welcome = $/root/Main/Overlays/Control/About/Margin/Half/Right/Tabs/Hello

const LINKS = [
	["/root/Main/Overlays/Control/About/Margin/Half/Left/Information/Website", "https://mhgolkar.github.io/Arrow/"],
	["/root/Main/Overlays/Control/About/Margin/Half/Left/Information/Repository", "https://github.com/mhgolkar/Arrow"],
	["/root/Main/Overlays/Control/About/Margin/Half/Left/Information/Documentation", "https://github.com/mhgolkar/Arrow/wiki"],
	["/root/Main/Overlays/Control/About/Margin/Half/Left/Information/TranslatorRepository", "https://github.com/UlinRei/Arrow-zh-tw"],
]

const LICENSE = "res://license"
const COPYRIGHT = "res://copyright"
const LOCALIZED_LEGAL_FILES = {
	"zh_TW": {
		"license": "res://license.zh_TW",
		"copyright": "res://copyright.zh_TW",
		"godot_license": "res://godot_license.zh_TW",
		"copyright_plus": ["res://assets/fonts/copyright.zh_TW"],
	},
}
const COPYRIGHT_PLUS = ["res://assets/fonts/copyright"]

func _ready() -> void:
	AppVersionDisplay.set_text("%s-ZhTW-1" % Settings.ARROW_VERSION)
	Copyright.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	Welcome.fit_content = false
	Welcome.scroll_active = true
	Copyright.fit_content = false
	Copyright.scroll_active = true
	register_connections()
	print_copyright()
	pass

func _notification(what:int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED && is_node_ready():
		print_copyright.call_deferred()

func register_connections() -> void:
	CloseButton.pressed.connect(self._toggle)
	# Link Buttons
	for link in LINKS:
		# var link_button = get_node(link[0])
		# link_button.pressed.connect(OS.shell_open.bind(link[1]), CONNECT_DEFERRED)
		get_node(link[0]).set_uri(link[1])
	pass

func _toggle() -> void:
	Main.UI.set_panel_visibility("about", false)
	pass

func print_copyright() -> void:
	var localized_files: Dictionary = LOCALIZED_LEGAL_FILES.get(TranslationServer.get_locale(), {})
	var copyright_path: String = localized_files.get("copyright", COPYRIGHT)
	var license_path: String = localized_files.get("license", LICENSE)
	var localized := !localized_files.is_empty()
	var copyright: String = Helpers.Utils.read_text_extended(copyright_path, "#")
	# ...
	copyright = copyright.replacen("@Import:ARROW_LICENSE", Helpers.Utils.read_text_file(license_path))
	# ...
	var godot_license_text := Engine.get_license_text()
	if localized_files.has("godot_license"):
		godot_license_text = Helpers.Utils.read_text_file(localized_files.godot_license)
	copyright = copyright.replacen("@Import:GODOT_LICENSE_FROM_ENGINE", godot_license_text)
	# ...
	var all_godot_components := Engine.get_copyright_info()
	var all_godot_components_text := ""
	for dict in all_godot_components:
		for parts in dict.parts:
			var files_label := "涉及的 Godot 原始碼檔案" if localized else "Godot source files concerned"
			all_godot_components_text += "\n• %s (%s): %s \n\t %s：%s \n" % [dict.name, parts.license, ", ".join(parts.copyright), files_label, ", ".join(parts.files)]
	copyright = copyright.replacen("@Import:GODOT_THIRD_PARTY_COMPONENTS_FROM_ENGINE", all_godot_components_text)
	# ...
	var all_godot_licenses := Engine.get_license_info()
	var all_godot_licenses_text := ""
	for license_name in all_godot_licenses:
		if localized:
			all_godot_licenses_text += "\n• 授權名稱：%s\n  完整法律原文保留於英文介面及原始散布檔案。\n" % license_name
		else:
			all_godot_licenses_text += "\n• License: %s \n\n%s\n" % [license_name, all_godot_licenses[license_name]]
	copyright = copyright.replacen("@Import:GODOT_LICENSES_TEXT_FROM_ENGINE", all_godot_licenses_text)
	# ...
	copyright = copyright.replacen("@GODOT_VERSION", Engine.get_version_info().string)
	# ...
	var copyright_pluses = String()
	var copyright_plus_files = localized_files.get("copyright_plus", COPYRIGHT_PLUS)
	for plus in copyright_plus_files:
		copyright_pluses += Helpers.Utils.read_text_extended(plus, "#") + "\n"
	copyright = copyright.replacen("@Import:COPYRIGHT_PLUS_FILES", copyright_pluses)
	# ...
	Copyright.set_text(copyright)
