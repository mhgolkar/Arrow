# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Macro_Use Node Type
extends GraphNode

# Note:
# 'macros' are `scenes` which are marked with `macro: true`
# and receive special treatments from the editor and runtime(s)

onready var Main = get_tree().get_root().get_child(0)

var _node_id
var _node_resource

var This = self

onready var MacroName = get_node("./VBoxContainer/MacroName")

const MACRO_TARGET_FAILED_MESSAGE = "No Macro"

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.is_doubleclick():
			if _node_resource.has("data"):
				var data = _node_resource.data
				if data.has("macro") && (data.macro is int) && data.macro >= 0:
					var the_macro = Main.Mind.lookup_resource(data.macro, "scenes")
					if the_macro.has("entry"):
						Main.Mind.call_deferred("locate_node_on_grid", the_macro.entry)
	pass

func _update_node(data:Dictionary) -> void:
	var the_macro_name_text = MACRO_TARGET_FAILED_MESSAGE
	if data.has("macro") && (data.macro is int) && data.macro >= 0:
		var the_macro = Main.Mind.lookup_resource(data.macro, "scenes")
		if (the_macro is Dictionary) && the_macro.has("name") && (the_macro.name is String):
			the_macro_name_text = the_macro.name
	MacroName.set_deferred("text", the_macro_name_text)
	pass
