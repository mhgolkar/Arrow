# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Variable_Update Node Type
extends GraphNode

onready var Main = get_tree().get_root().get_child(0)

var _node_id
var _node_resource

var This = self

onready var Expr = get_node("./VBoxContainer/Expression")

const UNSET_OR_INVALID_MESSAGE = "Unset"
onready var VarUpExpr = VariableUpdateSharedClass.expression.new(Main.Mind)

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_node(data:Dictionary) -> void:
	var expression_text = VarUpExpr.parse(data, null)
	if expression_text is String:
		Expr.set_deferred("text", expression_text)
	else:
		Expr.set_deferred("text", UNSET_OR_INVALID_MESSAGE)
	pass
