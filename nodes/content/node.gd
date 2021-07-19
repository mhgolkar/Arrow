# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Content Node Type
extends GraphNode

onready var Main = get_tree().get_root().get_child(0)

const TITLE_UNSET_MESSAGE = "Untitled"
const BRIEF_UNSET_MESSAGE = ""

var _node_id
var _node_resource

var This = self

onready var Title = get_node("./VBoxContainer/Title")
onready var Brief = get_node("./VBoxContainer/Brief")

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_node(data:Dictionary) -> void:
	# title
	var title
	if data.has("title"):
		title = String(data.title)
	Title.set_text(
		title
		if (title is String && title.length() > 0)
		else TITLE_UNSET_MESSAGE
	)
	# brief
	Brief.set_text(BRIEF_UNSET_MESSAGE)
	Brief.set_visible(false)
	var brief
	if data.has("brief"):
		brief = String(data.brief)
		if brief is String && brief.length() > 0:
			Brief.clear() # clean up and try to set bbcode
			if Brief.append_bbcode(brief) != OK:
				# or normal text if there was problem parsing it
				Brief.set_text(brief)
			Brief.set_visible(true)
	pass
