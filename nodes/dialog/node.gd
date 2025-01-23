# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Dialog Graph Node
extends GraphNode

@onready var Main = get_tree().get_root().get_child(0)

const OUT_SLOT_COLOR = Settings.GRID_NODE_SLOT.DEFAULT.OUT.COLOR
# settings for the dynamically generated outgoing slots
const OUT_SLOT_ENABLE_RIGHT = true
const OUT_SLOT_ENABLE_lEFT  = false
const OUT_SLOT_TYPE_RIGHT   = Settings.GRID_NODE_SLOT.DEFAULT.OUT.TYPE
const OUT_SLOT_TYPE_LEFT    = OUT_SLOT_TYPE_RIGHT
const OUT_SLOT_COLOR_RIGHT  = OUT_SLOT_COLOR
const OUT_SLOT_COLOR_LEFT   = OUT_SLOT_COLOR

const LINE_SLOT_ALIGN = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
const LINE_AUTO_WRAP = TextServer.AutowrapMode.AUTOWRAP_WORD_SMART

const ANONYMOUS_CHARACTER = DialogSharedClass.ANONYMOUS_CHARACTER
const DEFAULT_NODE_DATA = DialogSharedClass.DEFAULT_NODE_DATA

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_id
@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_resource

var This = self

@onready var Playable = $Head/State/Playable
@onready var Auto = $Head/State/Auto
@onready var CharacterName  = $Head/Character/Name
@onready var CharacterColor = $Head/Character/Color

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func remove_lines_all() -> void:
	for node in self.get_children():
		if node is Label:
			node.free()
	pass

func update_lines(lines:Array, clear_first:bool = true) -> void:
	if clear_first == true:
		remove_lines_all() 
	# Note: starts from `1` because there is a default `in`coming slot first at 0 index (`./Head`)
	var idx = 1 
	for line_text in lines:
		if line_text is String:
			var line_slot = Label.new()
			line_slot.set_text(line_text)
			line_slot.set_horizontal_alignment(LINE_SLOT_ALIGN)
			line_slot.set_autowrap_mode(LINE_AUTO_WRAP)
			This.add_child(line_slot)
			This.set_slot(
				idx,
				OUT_SLOT_ENABLE_lEFT, OUT_SLOT_TYPE_LEFT, OUT_SLOT_COLOR_LEFT,
				OUT_SLOT_ENABLE_RIGHT, OUT_SLOT_TYPE_RIGHT, OUT_SLOT_COLOR_RIGHT
			)
			idx += 1
	pass

func update_character(profile:Dictionary) -> void:
	if profile.has("name") && (profile.name is String):
		CharacterName.set("text", profile.name)
	if profile.has("color") && (profile.color is String):
		CharacterColor.set("color", Helpers.Utils.rgba_hex_to_color(profile.color))
	pass

func set_character_anonymous() -> void:
	update_character( ANONYMOUS_CHARACTER )
	pass

func set_playable(manual:bool) -> void:
	Playable.set_visible(manual)
	Auto.set_visible(!manual)
	pass

func _update_node(data:Dictionary) -> void:
	if data.has("lines") && (data.lines is Array):
		update_lines(data.lines, true)
	else:
		remove_lines_all()
	if data.has("playable") && (data.playable is bool):
		set_playable(data.playable)
	else:
		set_playable(DEFAULT_NODE_DATA.playable)
	if data.has("character") && (data.character is int) && (data.character >= 0):
		var the_character_profile = Main.Mind.lookup_resource(data.character, "characters")
		if the_character_profile != null :
			update_character( the_character_profile )
	else:
		set_character_anonymous()
	pass
