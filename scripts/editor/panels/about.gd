# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# About Panel
extends PanelContainer

onready var Main = get_tree().get_root().get_child(0)

onready var OkButton = get_node(Addressbook.ABOUT_PANEL.OK_BUTTON)
onready var AppVersion = get_node(Addressbook.ABOUT_PANEL.VERSION_CODE)

const LINKS = [
	[Addressbook.ABOUT_PANEL.LINKS.SOURCE, "https://github.com/mhgolkar/Arrow"],
	[Addressbook.ABOUT_PANEL.LINKS.DOCS, "https://github.com/mhgolkar/Arrow/wiki"],
	[Addressbook.ABOUT_PANEL.LINKS.WEB_APP, "https://mhgolkar.github.io/Arrow/"],
	[Addressbook.ABOUT_PANEL.LINKS.GODOT, "https://godotengine.org/"]
]

func _ready() -> void:
	AppVersion.set_text( Settings.ARROW_VERSION );
	register_connections()
	pass

func register_connections() -> void:
	OkButton.connect("pressed", self, "_toggle", [], CONNECT_DEFERRED)
	# Link Buttons
	for link in LINKS:
		var link_button = get_node(link[0]);
		link_button.connect("pressed", OS, "shell_open", [ link[1] ], CONNECT_DEFERRED);
	pass

func _toggle() -> void:
	Main.call_deferred("toggle_about")
	pass
