# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Inspector :: Project Tab
extends Tabs

signal relay_request_mind

onready var Main = get_tree().get_root().get_child(0)

onready var ProjectListModes = get_node(Addressbook.INSPECTOR.PROJECT.PROJECT_LIST_MODES.itself)
onready var LocalProjectProperties = get_node(Addressbook.INSPECTOR.PROJECT.LOCAL_PROJECT_PROPERTIES.itself)

onready var LocalProjectsList = get_node(Addressbook.INSPECTOR.PROJECT.PROJECT_LIST_MODES.LOCAL_MODE.LISTED_PROJECTS_LIST)
onready var SelectedProjectDescription = get_node(Addressbook.INSPECTOR.PROJECT.PROJECT_LIST_MODES.LOCAL_MODE.SELECTED_PROJECT_DESCRIPTION)
onready var NewLocalProjectMenu = get_node(Addressbook.INSPECTOR.PROJECT.PROJECT_LIST_MODES.LOCAL_MODE.TOOLS.NEW_MENU_BUTTON)
onready var RemoveLocalProject = get_node(Addressbook.INSPECTOR.PROJECT.PROJECT_LIST_MODES.LOCAL_MODE.TOOLS.REMOVE_LOCAL_PROJECT_BUTTON)
onready var OpenLocalProject = get_node(Addressbook.INSPECTOR.PROJECT.PROJECT_LIST_MODES.LOCAL_MODE.TOOLS.OPEN_LOCAL_PROJECT_BUTTON)

onready var _CURRENT_SUB_VIEW = ProjectListModes

# relays
# these are parts that send `relay_request_mind` signal to this tab,
# and the tab will relay their requests to inspector panel to be relayed to the central mind
onready var REQUESTING_RELAY_PARTS = [ NewLocalProjectMenu, LocalProjectProperties ]

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	for part in REQUESTING_RELAY_PARTS:
		part.connect("relay_request_mind", self, "request_mind_relay", [part], CONNECT_DEFERRED)
	RemoveLocalProject.connect("pressed", self, "request_removing_project", [], CONNECT_DEFERRED)
	OpenLocalProject.connect("pressed", self, "request_opening_project", [], CONNECT_DEFERRED)
	LocalProjectsList.connect("item_selected", self, "_on_local_projects_list_item_selected", [], CONNECT_DEFERRED)
	LocalProjectsList.connect("item_activated", self, "request_opening_project", [], CONNECT_DEFERRED)
	LocalProjectsList.connect("nothing_selected", self, "_on_local_projects_list_nothing_selected", [], CONNECT_DEFERRED)
	pass

func initialize_tab() -> void:
	refresh_tab()
	pass

func refresh_tab() -> void:
	refresh_local_project_list_tools()
	pass

func request_mind_relay(req:String, args=null, _the_part=null):
	emit_signal("relay_request_mind", req, args)
	pass

func _on_local_projects_list_item_selected(_selected=null) -> void:
	refresh_local_project_list_tools()
	pass

func _on_local_projects_list_nothing_selected() -> void:
	LocalProjectsList.unselect_all()
	refresh_local_project_list_tools()
	pass

func refresh_local_project_list_tools() -> void:
	refresh_project_description()
	refresh_local_project_list_tools_buttons()
	pass

func refresh_project_description() -> void:
	SelectedProjectDescription.set_visible(false)
	var selected = LocalProjectsList.get_selected_items()
	if selected.size() >= 1:
		var project_id = LocalProjectsList.get_item_metadata(selected[0])
		var description = Main.Mind.ProMan.get_project_description(project_id)
		if description is String && description.length() > 0:
			SelectedProjectDescription.clear()
			if SelectedProjectDescription.append_bbcode(description) != OK:
				SelectedProjectDescription.set_text(description)
			SelectedProjectDescription.set_deferred("visible", true)
	pass

func refresh_local_project_list_tools_buttons() -> void:
	var local_project_is_selected = ( LocalProjectsList.get_selected_items().size() > 0 )
	RemoveLocalProject.set_disabled( ! local_project_is_selected )
	OpenLocalProject.set_disabled( ! local_project_is_selected )
	pass

# <list>{ <project_uid>:int { title:string<project_title>, filename:string<filename-without-extension>}, ... }
func list_local_projects(list:Dictionary, clean_existings:bool = false) -> void:
	print_debug("Projects Listed: ", list)
	if clean_existings:
		LocalProjectsList.clear()
	var last_index = (LocalProjectsList.get_item_count() - 1)
	for project_id in list:
		LocalProjectsList.call_deferred("add_item", list[project_id].title)
		last_index += 1 # now that we have added an item, index of the last item is changed
		LocalProjectsList.call_deferred("set_item_metadata", last_index, project_id)
	pass

func request_removing_project() -> void:
	var selected = LocalProjectsList.get_selected_items()
	if selected.size() >= 1:
		var project_id = LocalProjectsList.get_item_metadata(selected[0])
		request_mind_relay("remove_local_project", project_id)
	pass

func request_opening_project(selected_idx:int = -1) -> void:
	var selected = ([selected_idx] if selected_idx >= 0 else LocalProjectsList.get_selected_items())
	if selected.size() >= 1:
		var project_id = LocalProjectsList.get_item_metadata(selected[0])
		request_mind_relay("open_local_project", project_id)
	pass

func switch_sub_view(the_view) -> void:
	# hide the older one
	_CURRENT_SUB_VIEW.set_deferred("visible", false)
	# set which one is the next
	match the_view:
		"project_list_modes":
			_CURRENT_SUB_VIEW = ProjectListModes
		"local_project_properties":
			_CURRENT_SUB_VIEW = LocalProjectProperties
	# make new one visible
	_CURRENT_SUB_VIEW.set_deferred("visible", true)
	pass

func clean_snapshots_view() -> void:
	LocalProjectProperties.call_deferred("clean_snapshots_view")
	pass

func reset_to_project_lists() -> void:
	switch_sub_view("project_list_modes")
	pass

func open_properties_editor(project_title:String, project_meta:Dictionary, project_is_local) -> void:
	if (project_is_local is bool) == false: # Option<T>
		project_is_local = (project_meta.has("offline") == true && project_meta.offline == true) || (project_meta.has("remote") == false)
	# we may add other checks and subchecks later, this is why the function seems a little weird!
	if project_is_local :
		LocalProjectProperties.call_deferred("refresh_fields", project_title, project_meta)
		switch_sub_view("local_project_properties")
	pass

func list_snapshot(snapshot_details:Dictionary, is_local:bool) -> void:
	if is_local:
		LocalProjectProperties.list_snapshot(snapshot_details)
	pass

func unlist_snapshot(snapshot_index:int, is_local:bool) -> void:
	if is_local:
		LocalProjectProperties.unlist_snapshot_by_idx(snapshot_index)
	pass
