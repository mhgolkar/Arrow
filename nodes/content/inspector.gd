# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Content Node Type Inspector
extends ScrollContainer

onready var Main = get_tree().get_root().get_child(0)

const DEFAULT_NODE_DATA = ContentSharedClass.DEFAULT_NODE_DATA

const SAVE_UNOPTIMIZED = ContentSharedClass.SAVE_UNOPTIMIZED

var _OPEN_NODE_ID
var _OPEN_NODE

const RESOURCE_NAME_EXPOSURE = {
	"variables": { "PATTERN": "{([.]*[^{|}]*)}", "NAME_GROUP_ID": 1 },
	"characters": { "PATTERN": "{([.]*[^{|}]*)\\.([.]*[^{|}]*)}", "NAME_GROUP_ID": 1 },
}

var This = self

onready var Title = get_node("./Content/Title")
onready var BriefLength = get_node("./Content/Brief/Length")
onready var BriefPick = get_node("./Content/Brief/Pick")
onready var Content = get_node("./Content/Content")
onready var AutoPlay = get_node("./Content/AutoPlay")
onready var ClearPage = get_node("./Content/ClearPage")

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	BriefPick.connect("pressed", self, "_pick_the_breif", [], CONNECT_DEFERRED)
	pass

func _pick_the_breif() -> void:
	Content.select(0, 0, Content.cursor_get_line(), Content.cursor_get_column())
	BriefLength.set_value( Content.get_selection_text().length() )
	pass

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	# ... then update parameters, and set defaults if node doesn't provide the right data
	if node.has("data") && node.data is Dictionary:
		# Title
		var title = node.data.title if node.data.has("title") && node.data.title is String else null
		Title.set_deferred("text", (title if title is String else DEFAULT_NODE_DATA.title))
		# Content
		var brief_length = null;
		var merged_content: String = "";
		# 1. Legacy Brief
		# > Deprecated textual brief field is merged with the normal text content
		# > to preserve data while updating the structure:
		if node.data.has("brief") && node.data.brief is String && node.data.brief.length() > 0 :
			merged_content += (node.data.brief + "\n")
			brief_length = node.data.brief.length()
		# 2. Normal Content
		if node.data.has("content") && node.data.content is String && node.data.content.length() > 0 :
			merged_content += node.data.content
		# ...
		if merged_content.length() > 0 :
			Content.set_deferred("text", merged_content)
		else:
			Content.set_deferred("text", DEFAULT_NODE_DATA.content)
		# Brief length
		# (with priority of the legacy brief length)
		if brief_length == null:
			if node.data.has("brief"):
				brief_length = int(node.data.brief)
			else:
				brief_length = DEFAULT_NODE_DATA.brief
		BriefLength.set_deferred("value", brief_length)
		# Auto-play
		if node.data.has("auto") && node.data.auto is bool :
			AutoPlay.set_deferred("pressed", node.data.auto)
		else:
			AutoPlay.set_deferred("pressed", DEFAULT_NODE_DATA.auto)
		# Clear (print on a clear console)
		if node.data.has("clear") && node.data.clear is bool :
			ClearPage.set_deferred("pressed", node.data.clear)
		else:
			ClearPage.set_deferred("pressed", DEFAULT_NODE_DATA.clear)
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
	var exposed_resources_by_uid = find_exposed_resources(parameters, ["title", "content"], true)
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
	var parameters = {} # all are optional fields (avoiding bloat:)
	# > title
	var title = Title.get_text()
	parameters["title"] = title if SAVE_UNOPTIMIZED || title != DEFAULT_NODE_DATA.title else null # ~ null = remove
	# > content
	var content = Content.get_text()
	parameters["content"] = content if SAVE_UNOPTIMIZED || content != DEFAULT_NODE_DATA.content else null
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
	# and references used in this content node
	var _use = create_use_command(parameters)
	if _use.drop.size() > 0 || _use.refer.size() > 0:
		parameters._use = _use
		# print_debug( "Changes will be: drop ", use.drop, " refer ", use.refer )
	# ...
	return parameters

func _create_new(new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data
