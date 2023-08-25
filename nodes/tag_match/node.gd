# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Tag-Match Node Type
extends GraphNode

onready var Main = get_tree().get_root().get_child(0)

var Utils = Helpers.Utils

const OUT_SLOT_COLOR = Settings.GRID_NODE_SLOT.DEFAULT.OUT.COLOR
# settings for the dynamically generated outgoing slots
const OUT_SLOT_ENABLE_RIGHT = true
const OUT_SLOT_ENABLE_lEFT  = false
const OUT_SLOT_TYPE_RIGHT   = Settings.GRID_NODE_SLOT.DEFAULT.OUT.TYPE
const OUT_SLOT_TYPE_LEFT    = OUT_SLOT_TYPE_RIGHT
const OUT_SLOT_COLOR_RIGHT  = OUT_SLOT_COLOR
const OUT_SLOT_COLOR_LEFT   = OUT_SLOT_COLOR

const LINE_SLOT_ALIGN = Label.ALIGN_RIGHT
const LINE_AUTO_WRAP = true

const INVALID_CHARACTER = TagMatchSharedClass.INVALID_CHARACTER
const DEFAULT_NODE_DATA = TagMatchSharedClass.DEFAULT_NODE_DATA

const INVALID_TAG_KEY_ERROR = "Unset Tag Key!"

var _node_id
var _node_resource

var This = self

onready var RegEx  = get_node("./Head/HBoxContainer/RegEx")
# onready var CharacterProfile  = get_node("./Head/CharacterProfile")
onready var CharacterProfileName  = get_node("./Head/CharacterProfile/Name")
onready var CharacterProfileColor = get_node("./Head/CharacterProfile/Color")
onready var TagKey = get_node("./Head/TagKey")

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func remove_patterns_all() -> void:
	for node in self.get_children():
		if node is Label:
			node.free()
	pass

func update_patterns(patterns:Array, clear_first:bool = true) -> void:
	if clear_first == true:
		remove_patterns_all() 
	# Note: starts from `1` because there is a default `in`coming slot first at 0 index (`./Head`)
	var idx = 1 
	for pattern_text in patterns:
		if pattern_text is String:
			var pattern_slot = Label.new()
			pattern_slot.set_text(pattern_text)
			pattern_slot.set_align(LINE_SLOT_ALIGN)
			pattern_slot.set_autowrap(LINE_AUTO_WRAP)
			This.add_child(pattern_slot)
			This.set_slot(
				idx,
				OUT_SLOT_ENABLE_lEFT, OUT_SLOT_TYPE_LEFT, OUT_SLOT_COLOR_LEFT,
				OUT_SLOT_ENABLE_RIGHT, OUT_SLOT_TYPE_RIGHT, OUT_SLOT_COLOR_RIGHT
			)
			idx += 1
	pass

func update_character(profile:Dictionary) -> void:
	if profile.has("name") && (profile.name is String):
		CharacterProfileName.set("text", profile.name)
	if profile.has("color") && (profile.color is String):
		CharacterProfileColor.set("color", Utils.rgba_hex_to_color(profile.color))
	pass

func set_character_invalid() -> void:
	update_character( INVALID_CHARACTER )
	pass

func _update_node(data:Dictionary) -> void:
	RegEx.set_visible(
		data.regex
		if data.has("regex") && (data.regex is bool)
		else DEFAULT_NODE_DATA.regex
	)
	if data.has("character") && (data.character is int) && (data.character >= 0):
		var the_character_profile = Main.Mind.lookup_resource(data.character, "characters")
		if the_character_profile != null :
			update_character( the_character_profile )
	else:
		set_character_invalid()
	TagKey.set_text(
		data.tag_key
		if data.has("tag_key") && (data.tag_key is String) && data.tag_key.length() > 0
		else INVALID_TAG_KEY_ERROR
	)
	if data.has("patterns") && (data.patterns is Array):
		update_patterns(data.patterns, true)
	else:
		remove_patterns_all()
	pass
