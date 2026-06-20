# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Monolog Graph Node
extends GraphNode

@onready var Main = get_tree().get_root().get_child(0)

const ANONYMOUS_CHARACTER = MonologSharedClass.ANONYMOUS_CHARACTER
const DEFAULT_NODE_DATA = MonologSharedClass.DEFAULT_NODE_DATA

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_id
@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_resource

var This = self

@onready var AutoPlay = $Display/Head/AutoPlay
@onready var ClearPage = $Display/Head/ClearPage
@onready var CharacterName  = $Display/Character/Name
@onready var CharacterAvatar = $Display/Character/Avatar
@onready var Brief = $Display/Brief

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
	CharacterAvatar.size = Vector2(48,48)
	pass

func set_character_anonymous() -> void:
	update_character( ANONYMOUS_CHARACTER )
	pass

func _update_node(data:Dictionary) -> void:
	# Character
	if data.has("character") && (data.character is int) && (data.character >= 0):
		var the_character_profile = Main.Mind.lookup_resource(data.character, "characters")
		if the_character_profile != null :
			update_character( the_character_profile )
		else:
			printerr("Use of non-existent character UID in the node data: ", data)
	else:
		set_character_anonymous()
	# Line Brief
	var brief_length = int( data.brief if data.has("brief") else DEFAULT_NODE_DATA.brief)
	var monolog = data.monolog if data.has("monolog") && data.monolog is String else DEFAULT_NODE_DATA.monolog
	Brief.set_text( monolog.substr(0, brief_length) )
	Brief.set_visible( brief_length != 0 )
	# Auto-play indicator
	AutoPlay.set_visible( data.auto if (data.has("auto") && data.auto is bool) else DEFAULT_NODE_DATA.auto)
	# Print on clear page indicator
	ClearPage.set_visible( data.clear if (data.has("clear") && data.clear is bool) else DEFAULT_NODE_DATA.clear)
	pass
