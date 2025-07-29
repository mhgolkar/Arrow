# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Content Graph Node
extends GraphNode

@onready var Main = get_tree().get_root().get_child(0)
@onready var Mind = Main.Mind

const DEFAULT_NODE_DATA = ContentSharedClass.DEFAULT_NODE_DATA

const TITLE_UNSET_MESSAGE = "CONTENT_NODE_UNSET_TITLE" # Translated ~ "Untitled"
const HIDE_UNSET_TITLE = true

const BRIEF_UNSET_MESSAGE = ""

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_id
@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_resource

var This = self

@onready var Title = $Display/Title
@onready var Brief = $Display/Brief
@onready var AutoPlay = $Display/Head/AutoPlay
@onready var ClearPage = $Display/Head/ClearPage

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_node(data:Dictionary) -> void:
	# Title
	var the_title = data.title if data.has("title") && data.title is String && data.title.length() > 0 else null
	Title.set_text(the_title if the_title is String else TITLE_UNSET_MESSAGE)
	Title.set_visible(the_title is String || (! HIDE_UNSET_TITLE ))
	# Brief
	Brief.set_visible(false)
	var brief = null;
	if data.has("brief"):
		var brief_length = int(data.brief)
		# Legacy brief (textual, which is not really a number)
		if data.brief is String && data.brief != String.num_uint64(brief_length):
			brief = data.brief
		# Normal brief (numeral length)
		elif data.has("content") && data.content is String:
			brief = data.content.substr(0, brief_length)
		else:
			brief = BRIEF_UNSET_MESSAGE
		# ...
		if brief is String && brief.length() > 0:
			Brief.set_text(brief)
			Brief.set_visible(true)
	# Auto-play indicator
	AutoPlay.set_visible(data.auto if (data.has("auto") && data.auto is bool) else DEFAULT_NODE_DATA.auto)
	# Print on clear page indicator
	ClearPage.set_visible(data.clear if (data.has("clear") && data.clear is bool) else DEFAULT_NODE_DATA.clear)
	pass
