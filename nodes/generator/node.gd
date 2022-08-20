# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Generator Node Type
extends GraphNode

onready var Main = get_tree().get_root().get_child(0)

var _node_id
var _node_resource

var This = self

onready var Method = get_node("./VBoxContainer/Method")
onready var Arguments = get_node("./VBoxContainer/Arguments")
onready var Target = get_node("./VBoxContainer/Target")

const UNSET_OR_INVALID_TARGET_VAR_MESSAGE = "Undefined"
const TARGET_VARIABLE_MESSAGE_TEMPLATE = "{name} ({type})"
const UNSET_OR_INVALID_METHOD_MESSAGE = "Unset"
const UNSET_OR_INVALID_ARGUMENTS_MESSAGE = "Null/Invalid"
const HIDE_ARGUMENTS_IF_UNSET = true

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_node(data:Dictionary) -> void:
	if (
		data.has("variable") && (data.variable is int && data.variable >= 0) &&
		data.has("method") && GeneratorSharedClass.METHODS.has(data.method)
	) :
		var the_target_variable = Main.Mind.lookup_resource(data.variable, "variables")
		Target.set_deferred( "text", (
			TARGET_VARIABLE_MESSAGE_TEMPLATE.format(the_target_variable)
			if the_target_variable is Dictionary && the_target_variable.has_all(["name", "type"])
			else UNSET_OR_INVALID_TARGET_VAR_MESSAGE
		))
		Method.set_deferred("text", GeneratorSharedClass.METHODS[data.method])
		var args_preview = GeneratorSharedClass.render_arguments_message(data)
		Arguments.set_deferred("text", args_preview if args_preview is String else UNSET_OR_INVALID_ARGUMENTS_MESSAGE)
		Arguments.set_deferred("visible", args_preview != null)
	else:
		Target.set_deferred("text", UNSET_OR_INVALID_TARGET_VAR_MESSAGE)
		Method.set_deferred("text", UNSET_OR_INVALID_METHOD_MESSAGE)
		Arguments.set_deferred("text", UNSET_OR_INVALID_ARGUMENTS_MESSAGE)
		Arguments.set_deferred("visible", (! HIDE_ARGUMENTS_IF_UNSET))
	pass
