# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Monolog Node Type Inspector
extends ScrollContainer

onready var Main = get_tree().get_root().get_child(0)

const ANONYMOUS_CHARACTER = MonologSharedClass.ANONYMOUS_CHARACTER
const DEFAULT_NODE_DATA = MonologSharedClass.DEFAULT_NODE_DATA

const SAVE_UNOPTIMIZED = MonologSharedClass.SAVE_UNOPTIMIZED

const ALLOW_ANONYMOUS_MONOLOGS = true
const ANONYMOUS_UID_CONTROL_VALUE = (-254)

var _OPEN_NODE_ID
var _OPEN_NODE

var _PROJECT_CHARACTERS_CACHE = {}

const RESOURCE_NAME_EXPOSURE = {
	"variables": { "PATTERN": "{([.]*[^{|}]*)}", "NAME_GROUP_ID": 1 },
	"characters": { "PATTERN": "{([.]*[^{|}]*)\\.([.]*[^{|}]*)}", "NAME_GROUP_ID": 1 },
}

var This = self

onready var Character = get_node("./Rows/Character/Selection")
onready var Monolog = get_node("./Rows/Monolog")
onready var BriefLength = get_node("./Rows/Brief/Length")
onready var BriefPick = get_node("./Rows/Brief/Pick")
onready var AutoPlay = get_node("./Rows/AutoPlay")
onready var ClearPage = get_node("./Rows/ClearPage")

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	BriefPick.connect("pressed", self, "_pick_the_breif", [], CONNECT_DEFERRED)
	pass

func _pick_the_breif() -> void:
	Monolog.select(0, 0, Monolog.cursor_get_line(), Monolog.cursor_get_column())
	BriefLength.set_value( Monolog.get_selection_text().length() )
	pass
	
func a_node_is_open() -> bool :
	if (
		(_OPEN_NODE_ID is int) && (_OPEN_NODE_ID >= 0) &&
		(_OPEN_NODE is Dictionary) &&
		_OPEN_NODE.has("data") && (_OPEN_NODE.data is Dictionary)
	):
		return true
	else:
		return false

func refresh_character_list(select_by_res_id:int = -1) -> void:
	Character.clear()
	if ALLOW_ANONYMOUS_MONOLOGS == true:
		# (Our conventional `-1` conflicts with the default behavior of `add_item` method, so we use a `..._CONTROLL_VALUE`)
		Character.add_item(ANONYMOUS_CHARACTER.name, ANONYMOUS_UID_CONTROL_VALUE)
	_PROJECT_CHARACTERS_CACHE = Main.Mind.clone_dataset_of("characters")
	for character_id in _PROJECT_CHARACTERS_CACHE:
		var the_character = _PROJECT_CHARACTERS_CACHE[character_id]
		Character.add_item(the_character.name, character_id)
	if select_by_res_id >= 0 :
		var character_item_index = Character.get_item_index( select_by_res_id )
		Character.select(character_item_index )
	else:
		if a_node_is_open() && _OPEN_NODE.data.has("character") && ( _OPEN_NODE.data.character in _PROJECT_CHARACTERS_CACHE ):
			var character_item_index_from_id = Character.get_item_index( _OPEN_NODE.data.character )
			Character.select( character_item_index_from_id )
	pass

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	refresh_character_list() # also selects the node's character
	# ... then update parameters, and set defaults if node doesn't provide the right data
	var data = node.data if node.has("data") && node.data is Dictionary else {}
	# Monolog
	var monolog = data.monolog if data.has("monolog") && data.monolog is String else DEFAULT_NODE_DATA.monolog
	Monolog.set_deferred("text", monolog)
	# Brief-length
	var brief_length = int(data.brief) if data.has("brief") else DEFAULT_NODE_DATA.brief
	BriefLength.set_deferred("value", brief_length)
	# Auto-play & Clear-page
	AutoPlay.set_deferred("pressed", data.auto if data.has("auto") && data.auto is bool else DEFAULT_NODE_DATA.auto)
	ClearPage.set_deferred("pressed", data.clear if data.has("clear") && data.clear is bool else DEFAULT_NODE_DATA.clear)
	pass

func find_exposed_resources(parameters:Dictionary, fields:Array, return_ids:bool = true) -> Array:
	var exposed_resources = []
	for resource_set in RESOURCE_NAME_EXPOSURE:
		var _CACHE = Main.Mind.clone_dataset_of(resource_set)
		var _CACHE_NAME_TO_ID = {}
		if _CACHE.size() > 0 : 
			for resource_id in _CACHE:
				_CACHE_NAME_TO_ID[ _CACHE[resource_id].name ] = resource_id
		# ...
		var _NAME_GROUP_ID = RESOURCE_NAME_EXPOSURE[resource_set].NAME_GROUP_ID
		var _EXPOSURE_PATTERN = RegEx.new()
		_EXPOSURE_PATTERN.compile( RESOURCE_NAME_EXPOSURE[resource_set].PATTERN )
		# ...
		for field in fields:
			if parameters[field] is String:
				for regex_match in _EXPOSURE_PATTERN.search_all( parameters[field] ):
					var possible_exposure = regex_match.get_string(_NAME_GROUP_ID)
					# print_debug("Possible Resource Exposure: ", possible_exposure)
					if _CACHE_NAME_TO_ID.has( possible_exposure ):
						var exposed = _CACHE_NAME_TO_ID[possible_exposure] if return_ids else possible_exposure
						if exposed_resources.has(exposed) == false:
							exposed_resources.append(exposed)
	return exposed_resources

func create_use_command(parameters:Dictionary) -> Dictionary:
	var use = { "drop": [], "refer": [] }
	# reference for any exposed variable or character ?
	var exposed_resources_by_uid = find_exposed_resources(parameters, ["monolog"], true)
	# print_debug( "Exposed Resources in %s: " % _OPEN_NODE.name, exposed_resources_by_uid )
	# remove the reference if any resource is not exposed anymore
	if _OPEN_NODE.has("ref") && _OPEN_NODE.ref is Array:
		for currently_referred_resource in _OPEN_NODE.ref:
			if exposed_resources_by_uid.has( currently_referred_resource ) == false:
				use.drop.append( currently_referred_resource )
	# and add new ones
	if exposed_resources_by_uid.size() > 0 :
		var may_exist = (_OPEN_NODE.has("ref") && _OPEN_NODE.ref is Array)
		for newly_exposed in exposed_resources_by_uid:
			if may_exist == false || _OPEN_NODE.ref.has( newly_exposed ) == false:
				use.refer.append( newly_exposed )
	return use

func _read_parameters() -> Dictionary:
	var parameters = {
		"character": Character.get_selected_id(),
		"monolog": Monolog.get_text(),
	}
	# Optionals (to avoid bloat:)
	# > brief
	var brief_length = int( BriefLength.get_value() )
	parameters["brief"] = brief_length if SAVE_UNOPTIMIZED || brief_length != DEFAULT_NODE_DATA.brief else null
	# > auto-play
	var auto = AutoPlay.is_pressed()
	parameters["auto"] = auto if SAVE_UNOPTIMIZED || auto != DEFAULT_NODE_DATA.auto else null
	# > clear page before print
	var clear = ClearPage.is_pressed()
	parameters["clear"] = clear if SAVE_UNOPTIMIZED || clear != DEFAULT_NODE_DATA.clear else null
	# ...
	# NOTE:
	# To avoid conflict with `add_item` default `-1` behavior, we used ANONYMOUS_UID_CONTROL_VALUE instead.
	# Here we adjust it to our conventional `-1` for unset/anonymous:
	if parameters.character == ANONYMOUS_UID_CONTROL_VALUE:
		parameters.character = -1
	# ...
	# and references used in this monolog node
	var _use = create_use_command(parameters)
	if _use.drop.size() > 0 || _use.refer.size() > 0:
		parameters._use = _use
		# print_debug( "Changes will be: drop ", use.drop, " refer ", use.refer )
	# ...
	return parameters

func _create_new(new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data
