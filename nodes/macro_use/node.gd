# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Macro-Use Graph Node
extends GraphNode

# Note:
# 'macros' are `scenes` which are marked with `macro: true`
# and receive special treatments from the editor and runtime(s)

@onready var Main = get_tree().get_root().get_child(0)

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_id
@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE") var _node_resource

var This = self

@onready var MacroIdentity = $Display/Title

const MACRO_USE_TARGET_FAILED_MESSAGE = "MACRO_USE_NODE_NO_TARGET_MSG" # Translated ~ "No Macro"
const MACRO_IDENTITY_FORMAT_STRING = "{name}" if Settings.FORCE_UNIQUE_NAMES_FOR_SCENES_AND_MACROS else "{name} ({uid})"

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.is_double_click():
			if event.is_alt_pressed() == true:
				if _node_resource.has("data"):
					var data = _node_resource.data
					if data.has("macro") && (data.macro is int) && data.macro >= 0:
						var the_macro = Main.Mind.lookup_resource(data.macro, "scenes")
						if the_macro.has("entry"):
							Main.Mind.call_deferred("locate_node_on_grid", the_macro.entry)
	pass

func _update_node(data:Dictionary) -> void:
	var the_macro_label = MACRO_USE_TARGET_FAILED_MESSAGE
	if data.has("macro") && (data.macro is int) && data.macro >= 0:
		var the_macro = Main.Mind.lookup_resource(data.macro, "scenes")
		if (the_macro is Dictionary) && the_macro.has("name") && (the_macro.name is String):
			the_macro_label = MACRO_IDENTITY_FORMAT_STRING.format({
				"uid": data.macro,
				"name": the_macro.name,
			})
	MacroIdentity.set_deferred("text", the_macro_label)
	pass
