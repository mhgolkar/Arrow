# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Content Node Type
extends GraphNode

onready var Main = get_tree().get_root().get_child(0)
onready var Mind = Main.Mind

var Utils = Helpers.Utils

const TITLE_UNSET_MESSAGE = "Untitled"
const BRIEF_UNSET_MESSAGE = ""

var _node_id
var _node_resource

var This = self

onready var Title = get_node("./VBoxContainer/Title")
onready var Brief = get_node("./VBoxContainer/Brief")

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	self.connect("resize_request", self, "_on_resize_request", [], CONNECT_DEFERRED)
	pass

func _on_resize_request(new_min_size) -> void:
	Mind.update_resource(
		_node_id, 
		{ "data": { "rect": Utils.vector2_to_array(new_min_size) } },
		"nodes",
		true
	)
	# Because we are updating resource out of signal hierarchy,
	# we need to manually toggle the save status as well:
	Mind.reset_project_save_status(false)
	pass

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
	Brief.set_visible(false)
	var brief = null;
	if data.has("brief"):
		var brief_length = int(data.brief)
		# Legacy brief (textual, which is not really a number)
		if data.brief is String && data.brief != String(brief_length):
			brief = data.brief
		# Normal brief (numeral length)
		elif data.has("content") && data.content is String:
			brief = data.content.substr(0, brief_length)
		else:
			brief = BRIEF_UNSET_MESSAGE
		if brief is String && brief.length() > 0:
			Brief.set_bbcode(brief)
			Brief.set_visible(true)
	# Custom node size
	if data.has("rect") && data.rect is Array && data.rect.size() >= 2 :
		var new_size = Utils.array_to_vector2(data.rect)
		self.set_deferred("rect_min_size", new_size)
		self.set_deferred("rect_size", new_size)
	pass