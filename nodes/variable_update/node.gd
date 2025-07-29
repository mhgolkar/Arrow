# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Variable-Update Graph Node
extends GraphNode

@onready var Main = get_tree().get_root().get_child(0)

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_id
@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_resource

var This = self

@onready var Expr = $Display/Expression

const UNSET_OR_INVALID_MESSAGE = "VARIABLE_UPDATE_NODE_UNSET_OR_INVALID_MSG" # Translated ~ "Unset"
@onready var VarUpExpr = VariableUpdateSharedClass.expression.new(Main.Mind)

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self.the_handler_on_self.bind(...), CONNECT_DEFERRED)
#	pass

func _update_node(data:Dictionary) -> void:
	var expression_text = VarUpExpr.parse(data, null)
	if expression_text is String:
		Expr.set_deferred("text", expression_text)
	else:
		Expr.set_deferred("text", UNSET_OR_INVALID_MESSAGE)
	pass
