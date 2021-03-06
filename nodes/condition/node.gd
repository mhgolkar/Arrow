# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Condition Node Type
extends GraphNode

onready var Main = get_tree().get_root().get_child(0)

var _node_id
var _node_resource

var This = self

onready var Condition = get_node("./Condition")

const UNSET_OR_INVALID_MESSAGE = "Unset !"
onready var ConditionStatement = ConditionSharedClass.Statement.new(Main.Mind)

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_node(data:Dictionary) -> void:
	var statement_text = ConditionStatement.parse(data)
	if statement_text is String:
		Condition.set_deferred("text", statement_text)
	else:
		Condition.set_deferred("text", UNSET_OR_INVALID_MESSAGE)
	pass
