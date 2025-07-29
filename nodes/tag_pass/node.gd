# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Tag-Pass Graph Node
extends GraphNode

@onready var Main = get_tree().get_root().get_child(0)
@onready var Mind = Main.Mind

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_id
@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_resource

var This = self

const TAG_KEY_ONLY_FORMAT_STRING = "{key}: *"
const TAG_KEY_VALUE_FORMAT_STRING = "{key}: `{value}`"

const ANONYMOUS_CHARACTER = TagPassSharedClass.ANONYMOUS_CHARACTER
const METHODS = TagPassSharedClass.METHODS

const METHOD_INVALID = ""

@onready var Method = $Pass/Method
@onready var CharacterProfile = $Pass/Character
@onready var CharacterProfileColor = $Pass/Character/Color
@onready var CharacterProfileName = $Pass/Character/Name
@onready var Invalid = $Pass/Invalid
@onready var TagTemplate = $Pass/Margin/TagTemplate
@onready var TagBox = $Pass/Margin/Checks
@onready var Tags = $Pass/Margin/Checks/Tags
@onready var TagNoneMessage = $Pass/Margin/NoTagsToCheck

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
		Helpers.Utils.rgba_hex_to_color(
			profile.color if profile.has("color") && (profile.color is String) else ANONYMOUS_CHARACTER.color
		)
	)
	pass

func update_tag_box(entities: Array) -> void:
	var checkables = 0
	for node in Tags.get_children():
		if node is Label:
			node.free()
	for entity in entities:
		if TagPassSharedClass.tag_is_checkable(entity):
			checkables += 1
			var value_is_checked = (entity.size() >= 1 && entity[1] is String)
			var checkable_tag = TagTemplate.duplicate()
			var _FORMAT_STRING =  TAG_KEY_VALUE_FORMAT_STRING if value_is_checked else TAG_KEY_ONLY_FORMAT_STRING
			checkable_tag.set_text(
				_FORMAT_STRING.format({
					"key": entity[0], "value": entity[1] if value_is_checked else "N/A"
				})
			)
			checkable_tag.set_visible(true)
			Tags.add_child(checkable_tag)
	TagNoneMessage.set_visible(checkables == 0)
	pass

func _update_node(data:Dictionary) -> void:
	var is_valid = TagPassSharedClass.data_is_valid(data)
	var method_text = METHOD_INVALID
	if is_valid:
		var method_id = data.pass[0]
		method_text = METHODS[method_id]
		var target_character = Main.Mind.lookup_resource(data.character, "characters")
		if target_character != null :
			update_character( target_character )
		else:
			is_valid = false
	Invalid.set_deferred("visible", (! is_valid))
	TagBox.set_deferred("visible", is_valid)
	Method.set_deferred("text", method_text)
	Method.set_deferred("visible", is_valid)
	CharacterProfile.set_deferred("visible", is_valid)
	update_tag_box(data.pass[1] if is_valid else [])
	pass
