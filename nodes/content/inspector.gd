# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Content Node Type Inspector
extends ScrollContainer

onready var Main = get_tree().get_root().get_child(0)

const DEFAULT_NODE_DATA = {
	"title": "",
	"content": "",
	"clear": false
}

var _OPEN_NODE_ID
var _OPEN_NODE

var This = self

onready var Title = get_node("./Content/Title")
onready var Content = get_node("./Content/Content")
onready var ClearPage = get_node("./Content/ClearPage")

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	# ... then update parameters, and set defaults if node doesn't provide the right data
	if node.has("data") && node.data is Dictionary:
		# Title
		if node.data.has("title") && node.data.title is String && node.data.title.length() > 0 :
			Title.set_deferred("text", node.data.title)
		else:
			Title.set_deferred("text", DEFAULT_NODE_DATA.title)
		# Content
		if node.data.has("content") && node.data.content is String && node.data.content.length() > 0 :
			Content.set_deferred("text", node.data.content)
		else:
			Content.set_deferred("text", DEFAULT_NODE_DATA.content)
		# Clear (print on a clear console)
		if node.data.has("clear") && node.data.clear is bool :
			ClearPage.set_deferred("pressed", node.data.clear)
		else:
			ClearPage.set_deferred("pressed", DEFAULT_NODE_DATA.clear)
	pass

func _read_parameters() -> Dictionary:
	var parameters = {
		"title"  : Title.get_text(),
		"content": Content.get_text(),
		"clear"  : ClearPage.is_pressed(),
	}
	return parameters

func _create_new(new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data

