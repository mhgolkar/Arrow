# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Condition Graph Node
extends GraphNode

@onready var Main = get_tree().get_root().get_child(0)

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_id
@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_resource

var This = self

@onready var Condition = $Statement

@onready var ConditionStatement = ConditionSharedClass.Statement.new(Main.Mind)

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_node(data:Dictionary) -> void:
	var statement_text = ConditionStatement.parse(data, null)
	if statement_text is String:
		Condition.set_deferred("text", statement_text)
	else:
		Condition.set_deferred("text", "CONDITION_NODE_UNSET_OR_INVALID")
	pass
