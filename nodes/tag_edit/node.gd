# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Tag-Edit Graph Node
extends GraphNode

@onready var Main = get_tree().get_root().get_child(0)

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_id
@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_resource

var This = self

@onready var Method = $Display/Method
@onready var Tag = $Display/Tag
@onready var CharacterProfile = $Display/Character
@onready var CharacterName = $Display/Character/Name
@onready var CharacterAvatar = $Display/Character/Avatar

const TAG_EDIT_INVALID = "TAG_EDIT_NODE_INVALID_DATA" # Translated ~ "Invalid!"
const TAG_KEY_VALUE_FORMAT_STRING = "TAG_EDIT_NODE_TAG_KEY_VALUE_FORMAT_STR" # Translated ~ "{key}: `{value}`"

const ANONYMOUS_CHARACTER = TagEditSharedClass.ANONYMOUS_CHARACTER
const METHODS = TagEditSharedClass.METHODS

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func update_character(profile:Dictionary) -> void:
	if profile.has("name") && (profile.name is String):
		CharacterName.set("text", profile.name)
	if profile.has("avatar") && (profile.avatar is String):
		var AvatarImage = Image.new()
		AvatarImage.load_png_from_buffer(Marshalls.base64_to_raw(profile.avatar))
		var AvatarTexture = ImageTexture.create_from_image(AvatarImage)
		CharacterAvatar.set("icon", AvatarTexture) 
		CharacterAvatar.modulate = Color(1, 1, 1, 1)
	elif profile.has("color") && (profile.color is String):
		var AvatarTexture = load("res://assets/default_avatar.png")
		CharacterAvatar.set("icon", AvatarTexture)
		CharacterAvatar.modulate = Helpers.Utils.rgba_hex_to_color(profile.color)
	CharacterAvatar.size = Vector2(32,32)
	pass

func _update_node(data:Dictionary) -> void:
	var is_valid = TagEditSharedClass.data_is_valid(data)
	var tag_text = TAG_EDIT_INVALID
	if is_valid:
		Method.set_deferred("text", METHODS[data.edit[0]] )
		var target_character = Main.Mind.lookup_resource(data.character, "characters")
		if target_character != null :
			update_character( target_character )
			tag_text = tr(TAG_KEY_VALUE_FORMAT_STRING).format({
				"key": data.edit[1], "value": data.edit[2]
			})
		else:
			is_valid = false
	Tag.set_deferred("text", tag_text)
	Method.set_deferred("visible", is_valid)
	CharacterProfile.set_deferred("visible", is_valid)
	pass
