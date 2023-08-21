# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Macro_Use Node Type Inspector
extends ScrollContainer

# Note:
# 'macros' are `scenes` which are marked with `macro: true`
# and receive special treatments from the editor and runtime(s)

onready var Main = get_tree().get_root().get_child(0)

const NO_MACRO_TEXT = "No Macro Available"
const NO_MACRO_ID = -1

const DEFAULT_NODE_DATA = {
	"macro": NO_MACRO_ID
}

var _OPEN_NODE_ID
var _OPEN_NODE

var This = self

onready var MacroOptions = get_node("./Macro/Options")
const MACRO_IDENTITY_FORMAT_STRING = "{name}" if Settings.FORCE_UNIQUE_NAMES_FOR_SCENES_AND_MACROS else "{name} ({uid})" 

var _CACHED_MACROS_LIST = {}

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func a_node_is_open() -> bool :
	if (
		(_OPEN_NODE_ID is int) && (_OPEN_NODE_ID >= 0) &&
		(_OPEN_NODE is Dictionary) &&
		_OPEN_NODE.has("data") && (_OPEN_NODE.data is Dictionary)
	):
		return true
	else:
		return false

func find_listed_macro_index(by_id: int) -> int:
	for idx in range(0, MacroOptions.get_item_count()):
		if MacroOptions.get_item_metadata(idx) == by_id:
			return idx
	return -1

func refresh_macro_list(select_by_res_id:int = NO_MACRO_ID) -> void:
	MacroOptions.clear()
	_CACHED_MACROS_LIST = Main.Mind.clone_dataset_of("scenes", { "macro": true })
	var _current_open_scene_id = Main.Mind.get_current_open_scene_id()
	if _CACHED_MACROS_LIST.size() > 0 :
		var item_index := 0
		for macro_id in _CACHED_MACROS_LIST:
			var the_macro = _CACHED_MACROS_LIST[macro_id]
			var the_macro_ident = MACRO_IDENTITY_FORMAT_STRING.format({
				"uid": macro_id,
				"name": the_macro.name,
			})
			MacroOptions.add_item(the_macro_ident, macro_id)
			MacroOptions.set_item_metadata(item_index, macro_id)
			item_index += 1
		if select_by_res_id >= 0 :
			var macro_item_index = find_listed_macro_index( select_by_res_id )
			MacroOptions.select(macro_item_index)
		elif a_node_is_open() && _OPEN_NODE.data.has("macro") && ( _OPEN_NODE.data.macro in _CACHED_MACROS_LIST ):
				var macro_item_index_from_id = find_listed_macro_index( _OPEN_NODE.data.macro )
				MacroOptions.select( macro_item_index_from_id )
		else: # if there is nothing to select
			MacroOptions.select(0) # just select the first one
			if MacroOptions.get_selected_metadata() == _current_open_scene_id && MacroOptions.get_item_count() > 1:
				MacroOptions.select(1) # ... or the seccond one, if the first is looper
		# to avoid creation of loopers (macro_use of the open macro in itself)
		# hide the open macro from list in case
		if _CACHED_MACROS_LIST.has(_current_open_scene_id):
			var the_looper_idx = find_listed_macro_index(_current_open_scene_id)
			MacroOptions.set_item_disabled(the_looper_idx, true)
	else:
		MacroOptions.add_item(NO_MACRO_TEXT, NO_MACRO_ID)
		MacroOptions.set_item_metadata(0, NO_MACRO_ID)
	pass

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	# ... then update parameters
	var select_macro_id = -1
	if node.has("data") && node.data is Dictionary:
		if node.data.has("macro") && (node.data.macro is int) && (node.data.macro >= 0) :
			select_macro_id = node.data.macro
	refresh_macro_list(select_macro_id)
	pass

func _read_parameters() -> Dictionary:
	var parameters = {
		"macro": ( MacroOptions.get_selected_metadata() if (_CACHED_MACROS_LIST.size() > 0) else NO_MACRO_ID)
	}
	# if there is any change in the target resources ...
	if parameters.macro != _OPEN_NODE.data.macro:
		var _current_open_scene_id = Main.Mind.get_current_open_scene_id()
		if parameters.macro != _current_open_scene_id:
			var _use = { "drop": [], "refer": [], "field": "scenes"}
			if parameters.macro >= 0:
				_use.refer.append(parameters.macro)
			if _OPEN_NODE.data.macro >= 0:
				_use.drop.append(_OPEN_NODE.data.macro)
			# ... attach a `_use` command
			if _use.drop.size() > 0 || _use.refer.size() > 0 :
				parameters._use = _use
		else:
			parameters.macro = _OPEN_NODE.data.macro # reset
			printerr("Caution! You can't run a macro inside the same macro, it makes a unsafe loop. Please read documentations for more information and workarounds.")
	return parameters

func _create_new(new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data

func _translate_internal_ref(data: Dictionary, translation: Dictionary) -> void:
	if translation.ids.has(data.macro):
		data.macro = translation.ids[data.macro]
	pass
