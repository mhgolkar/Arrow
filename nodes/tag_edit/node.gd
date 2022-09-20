# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Tag-Edit Node Type
extends GraphNode

onready var Main = get_tree().get_root().get_child(0)

var Utils = Helpers.Utils

var _node_id
var _node_resource

var This = self

onready var Method = get_node("./Rows/Header/Method")
onready var Tag = get_node("./Rows/Tag")
onready var CharacterProfile = get_node("./Rows/Character")
onready var CharacterProfileColor = get_node("./Rows/Character/Color")
onready var CharacterProfileName = get_node("./Rows/Character/Name")

const TAG_EDIT_INVALID = "Invalid!"
const TAG_KEY_VALUE_FORMAT_STRING = "{key}: `{value}`"

const ANONYMOUS_CHARACTER = TagEditSharedClass.ANONYMOUS_CHARACTER
const METHODS = TagEditSharedClass.METHODS

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func update_character(profile:Dictionary) -> void:
	CharacterProfileName.set(
		"text",
		profile.name if profile.has("name") && (profile.name is String) else ANONYMOUS_CHARACTER.name
	)
	CharacterProfileColor.set(
		"color",
		Utils.rgba_hex_to_color(
			profile.color if profile.has("color") && (profile.color is String) else ANONYMOUS_CHARACTER.color
		)
	)
	pass

func _update_node(data:Dictionary) -> void:
	var is_valid = TagEditSharedClass.data_is_valid(data)
	var tag_text = TAG_EDIT_INVALID
	if is_valid:
		Method.set_deferred("text", METHODS[data.edit[0]] )
		var target_character = Main.Mind.lookup_resource(data.character, "characters")
		if target_character != null :
			update_character( target_character )
			tag_text = TAG_KEY_VALUE_FORMAT_STRING.format({
				"key": data.edit[1], "value": data.edit[2]
			})
		else:
			is_valid = false
	Tag.set_deferred("text", tag_text)
	Method.set_deferred("visible", is_valid)
	CharacterProfile.set_deferred("visible", is_valid)
	pass
