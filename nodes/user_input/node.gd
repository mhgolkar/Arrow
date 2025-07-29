# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# User-Input Graph Node
extends GraphNode

@onready var Main = get_tree().get_root().get_child(0)

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_id
@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_resource

var This = self

@onready var Prompt = $Display/Prompt
@onready var TargetVariableName = $Display/Target/Name
@onready var TargetVariableType = $Display/Target/Type

const NO_PROMPT_TEXT = "USER_INPUT_NODE_NO_PROMPT_TXT" # Translated ~ "Unset!"
const NO_TARGET_VARIABLE = { "type": "USER_INPUT_NODE_NO_TARGET_TYPE", "name": "USER_INPUT_NODE_NO_TARGET_NAME" } # Translated ~ "nil", "undefined"

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_node(data:Dictionary) -> void:
	# prompt
	if data.has("prompt") && (data.prompt is String) && data.prompt.length() > 0:
		Prompt.set_deferred("text", data.prompt)
	else:
		Prompt.set_deferred("text", NO_PROMPT_TEXT)
	# variable
	var var_type = NO_TARGET_VARIABLE.type
	var var_name = NO_TARGET_VARIABLE.name
	if data.has("variable") && (data.variable is int) && (data.variable >= 0) :
		var target_variable = Main.Mind.lookup_resource(data.variable, "variables")
		if target_variable is Dictionary:
			if target_variable.has("name") && (target_variable.name is String):
				var_name = target_variable.name
			if target_variable.has("type") && (target_variable.type is String):
				var_type = target_variable.type
	TargetVariableName.set_deferred("text", var_name)
	TargetVariableType.set_deferred("text", var_type)
	pass
