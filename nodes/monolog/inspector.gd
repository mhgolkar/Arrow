# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Monolog Sub-Inspector
extends Control

@onready var Main = get_tree().get_root().get_child(0)

const ANONYMOUS_CHARACTER = MonologSharedClass.ANONYMOUS_CHARACTER
const DEFAULT_NODE_DATA = MonologSharedClass.DEFAULT_NODE_DATA

const SAVE_UNOPTIMIZED = MonologSharedClass.SAVE_UNOPTIMIZED

const ALLOW_ANONYMOUS_MONOLOGS = true
const ANONYMOUS_UID_CONTROL_VALUE = -254

var _OPEN_NODE_ID
var _OPEN_NODE

var _PROJECT_CHARACTERS_CACHE = {}

const FIELDS_WITH_EXPOSURE = ["monolog"]
const RESOURCE_NAME_EXPOSURE = Settings.RESOURCE_NAME_EXPOSURE

var This = self

@onready var CharactersInspector = Main.Mind.Inspector.Tab.Characters

@onready var Character = $Selector/List
@onready var GlobalFilters = $Selector/Filtered
@onready var Monolog = $Monolog
@onready var BriefLength = $Brief/Length
@onready var BriefPick = $Brief/Pick
@onready var AutoPlay = $AutoPlay
@onready var ClearPage = $ClearPage

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	GlobalFilters.pressed.connect(self.refresh_character_list, CONNECT_DEFERRED)
	BriefPick.pressed.connect(self._pick_the_brief, CONNECT_DEFERRED)
	pass

func _pick_the_brief() -> void:
	Monolog.select(0, 0, Monolog.get_caret_line(), Monolog.get_caret_column())
	BriefLength.set_value( Monolog.get_selected_text().length() )
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

func find_listed_character_index(by_id: int) -> int:
	for idx in range(0, Character.get_item_count()):
		if Character.get_item_metadata(idx) == by_id:
			return idx
	return -1

func refresh_character_list(select_by_res_id:int = -1) -> void:
	Character.clear()
	var item_index := 0
	if ALLOW_ANONYMOUS_MONOLOGS == true:
		# (Our conventional `-1` conflicts with the default behavior of `add_item` method, so we use a `..._CONTROL_VALUE`)
		Character.add_item(ANONYMOUS_CHARACTER.name, ANONYMOUS_UID_CONTROL_VALUE)
		Character.set_item_metadata(item_index, ANONYMOUS_UID_CONTROL_VALUE)
		item_index += 1
	_PROJECT_CHARACTERS_CACHE = Main.Mind.clone_dataset_of("characters")
	var already = null
	if a_node_is_open() && _OPEN_NODE.data.has("character") && _OPEN_NODE.data.character in _PROJECT_CHARACTERS_CACHE :
		already = _OPEN_NODE.data.character
	var global_filters = CharactersInspector.read_listing_instruction()
	var apply_globals = GlobalFilters.is_pressed()
	var listing = {}
	for character_id in _PROJECT_CHARACTERS_CACHE:
		var the_character = _PROJECT_CHARACTERS_CACHE[character_id]
		if character_id == already || apply_globals == false || CharactersInspector.passes_filters(global_filters, character_id, the_character):
			listing[the_character.name] = character_id
	var listing_keys = listing.keys()
	if apply_globals && global_filters.SORT_ALPHABETICAL:
		listing_keys.sort()
	for char_name in listing_keys:
		var id = listing[char_name]
		Character.add_item(char_name if already != id || apply_globals == false else "["+ char_name +"]", id)
		Character.set_item_metadata(item_index, id)
		item_index += 1
	if select_by_res_id >= 0 :
		var character_item_index = find_listed_character_index( select_by_res_id )
		Character.select( character_item_index )
	else:
		if already != null :
			var character_item_index = find_listed_character_index(already)
			Character.select( character_item_index )
	pass
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
	var brief_length = int(data.brief) if data.has("brief") && data.brief != null else DEFAULT_NODE_DATA.brief
	BriefLength.set_deferred("value", brief_length)
	# Auto-play & Clear-page
	AutoPlay.set_deferred("button_pressed", data.auto if data.has("auto") && data.auto is bool else DEFAULT_NODE_DATA.auto)
	ClearPage.set_deferred("button_pressed", data.clear if data.has("clear") && data.clear is bool else DEFAULT_NODE_DATA.clear)
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
	var references_by_uid = find_exposed_resources(parameters, FIELDS_WITH_EXPOSURE, true)
	# and the owner character of the monolog
	if parameters.character >= 0:
		references_by_uid.append(parameters.character)
	# print_debug( "Referenced Resources in %s: " % _OPEN_NODE.name, references_by_uid )
	# drop respective reference if any resource is not needed anymore
	if _OPEN_NODE.has("ref") && _OPEN_NODE.ref is Array:
		for old_reference in _OPEN_NODE.ref:
			if references_by_uid.has( old_reference ) == false:
				use.drop.append( old_reference )
	# and use new ones
	if references_by_uid.size() > 0 :
		var may_exist = (_OPEN_NODE.has("ref") && _OPEN_NODE.ref is Array)
		for newly_exposed in references_by_uid:
			if may_exist == false || _OPEN_NODE.ref.has( newly_exposed ) == false:
				use.refer.append( newly_exposed )
	return use

func _read_parameters() -> Dictionary:
	var parameters = {
		"character": Character.get_selected_metadata(),
		"monolog": Monolog.get_text(),
	}
	# Optionals (to avoid bloat:)
	# > brief
	var brief_length = int( BriefLength.get_value() )
	@warning_ignore("INCOMPATIBLE_TERNARY") 
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

func _create_new(_new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data

func _translate_internal_ref(data: Dictionary, translation: Dictionary) -> void:
	if translation.ids.has(data.character):
		data.character = translation.ids[data.character]
	for resource_set in RESOURCE_NAME_EXPOSURE:
		var _NAME_GROUP_ID = RESOURCE_NAME_EXPOSURE[resource_set].NAME_GROUP_ID
		var _EXPOSURE_PATTERN = RegEx.new()
		_EXPOSURE_PATTERN.compile( RESOURCE_NAME_EXPOSURE[resource_set].PATTERN )
		for field in FIELDS_WITH_EXPOSURE:
			if data.has(field) && data[field] is String:
				var revised = {}
				for matched in _EXPOSURE_PATTERN.search_all( data[field] ):
					var exposure = [matched.get_string(), matched.get_start(), matched.get_end()] 
					var exposed = [matched.get_string(_NAME_GROUP_ID), matched.get_start(_NAME_GROUP_ID), matched.get_end(_NAME_GROUP_ID)]
					if translation.names.has( exposed[0] ):
						var cut = [exposed[1] - exposure[1], exposed[2] - exposure[1]]
						var new_name = translation.names[exposed[0]]
						revised[exposure[0]] = (exposure[0].substr(0, cut[0]) + new_name + exposure[0].substr(cut[1], -1))
				for exposure in revised:
					data[field] = data[field].replace(exposure, revised[exposure])
	pass

static func map_i18n_data(id: int, node: Dictionary) -> Dictionary:
	var base_key = String.num_int64(id) + "-monolog-"
	return {
		base_key + "monolog": node.data.monolog,
	}
