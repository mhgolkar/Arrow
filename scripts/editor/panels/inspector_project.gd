# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Inspector :: Project Tab
extends Control

signal relay_request_mind()

@onready var Main = get_tree().get_root().get_child(0)

@onready var ProjectListing = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Listing
@onready var ProjectProperties = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Properties

@onready var Filter = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Listing/Filters/Input
@onready var FilterReverse = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Listing/Filters/Reverse
@onready var SortAlphabetical = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Listing/Filters/Alphabetical
@onready var ProjectsList = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Listing/VSplit/Items
@onready var SelectedProjectDescription = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Listing/VSplit/Description
@onready var NewProjectMenu = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Listing/Actions/New
@onready var RemoveProject = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Listing/Actions/Remove
@onready var OpenProject = $/root/Main/FloatingTools/Control/Inspector/Sections/Tabs/Project/Listing/Actions/Open

@onready var _CURRENT_SUB_VIEW = ProjectListing

# relays
# these are parts that send `relay_request_mind` signal to this tab,
# and the tab will relay their requests to inspector panel to be relayed to the central mind
@onready var REQUESTING_RELAY_PARTS = [ NewProjectMenu, ProjectProperties ]

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	for part in REQUESTING_RELAY_PARTS:
		part.relay_request_mind.connect(self.request_mind_relay.bind(part), CONNECT_DEFERRED)
	RemoveProject.pressed.connect(self.request_removing_project, CONNECT_DEFERRED)
	OpenProject.pressed.connect(self.request_opening_project, CONNECT_DEFERRED)
	ProjectsList.item_selected.connect(self._on_local_projects_list_item_selected, CONNECT_DEFERRED)
	ProjectsList.item_activated.connect(self.request_opening_project, CONNECT_DEFERRED)
	ProjectsList.empty_clicked.connect(self._on_local_projects_list_empty_clicked, CONNECT_DEFERRED)
	Filter.text_changed.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	FilterReverse.toggled.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	SortAlphabetical.toggled.connect(self._on_listing_instruction_change, CONNECT_DEFERRED)
	pass

func initialize_tab() -> void:
	refresh_tab()
	pass

func refresh_tab() -> void:
	refresh_local_project_list_tools()
	pass

func request_mind_relay(req:String, args=null, _the_part=null):
	self.relay_request_mind.emit(req, args)
	pass

func _on_listing_instruction_change(_x = null) -> void:
	Main.Mind.load_projects_list()
	pass

func _on_local_projects_list_item_selected(_selected=null) -> void:
	refresh_local_project_list_tools()
	pass

func _on_local_projects_list_empty_clicked(_x = null, _y = null) -> void:
	ProjectsList.deselect_all()
	refresh_local_project_list_tools()
	pass

func refresh_local_project_list_tools() -> void:
	refresh_project_description()
	refresh_local_project_list_tools_buttons()
	pass

func refresh_project_description() -> void:
	SelectedProjectDescription.set_visible(false)
	var selected = ProjectsList.get_selected_items()
	if selected.size() >= 1:
		var project_id = ProjectsList.get_item_metadata(selected[0])
		var description = Main.Mind.ProMan.get_project_description(project_id)
		if description is String && description.length() > 0:
			SelectedProjectDescription.set_deferred("text", description)
			SelectedProjectDescription.set_deferred("visible", true)
	pass

func refresh_local_project_list_tools_buttons() -> void:
	var local_project_is_selected = ( ProjectsList.get_selected_items().size() > 0 )
	RemoveProject.set_disabled( ! local_project_is_selected )
	OpenProject.set_disabled( ! local_project_is_selected )
	pass

func read_listing_instruction() -> Dictionary:
	return {
		"FILTER": Filter.get_text(),
		"FILTER_REVERSE": FilterReverse.is_pressed(),
		"SORT_ALPHABETICAL": SortAlphabetical.is_pressed(),
	}

# <list>{ <project_uid>:int { title:string<project_title>, filename:string<filename-without-extension>}, ... }
func list_local_projects(list:Dictionary, clean_existing:bool = false) -> void:
	# print_debug("Projects Listed: ", list)
	var _LISTING = read_listing_instruction()
	if clean_existing:
		ProjectsList.clear()
	var last_index = (ProjectsList.get_item_count() - 1)
	for project_id in list:
		var project_title = list[project_id].title
		if Helpers.Utils.filter_pass(project_title, _LISTING.FILTER, _LISTING.FILTER_REVERSE):
			ProjectsList.call_deferred("add_item", project_title)
			last_index += 1 # now that we have added an item, index of the last item is changed
			ProjectsList.call_deferred("set_item_metadata", last_index, project_id)
	if _LISTING.SORT_ALPHABETICAL:
		ProjectsList.call_deferred("sort_items_by_text")
	pass

func request_removing_project() -> void:
	var selected = ProjectsList.get_selected_items()
	if selected.size() >= 1:
		var project_id = ProjectsList.get_item_metadata(selected[0])
		request_mind_relay("remove_local_project", project_id)
	pass

func request_opening_project(selected_idx:int = -1) -> void:
	var selected = ([selected_idx] if selected_idx >= 0 else ProjectsList.get_selected_items())
	if selected.size() >= 1:
		var project_id = ProjectsList.get_item_metadata(selected[0])
		request_mind_relay("open_local_project", project_id)
	pass

func switch_sub_view(the_view) -> void:
	# hide the older one
	_CURRENT_SUB_VIEW.set_deferred("visible", false)
	# set which one is the next
	match the_view:
		"project_list_modes":
			_CURRENT_SUB_VIEW = ProjectListing
		"local_project_properties":
			_CURRENT_SUB_VIEW = ProjectProperties
	# make new one visible
	_CURRENT_SUB_VIEW.set_deferred("visible", true)
	pass

func clean_snapshots_view() -> void:
	ProjectProperties.call_deferred("clean_snapshots_view")
	pass

func reset_to_project_lists() -> void:
	switch_sub_view("project_list_modes")
	pass

func open_properties_editor(project_title:String, project_meta:Dictionary, project_is_local) -> void:
	if (project_is_local is bool) == false: # Option<T>
		project_is_local = (project_meta.has("offline") == true && project_meta.offline == true) || (project_meta.has("remote") == false)
	# we may add other checks later, this is why the function seems a little weird!
	if project_is_local :
		ProjectProperties.call_deferred("refresh_fields", project_title, project_meta)
		switch_sub_view("local_project_properties")
	pass

func list_snapshot(snapshot_details:Dictionary, is_local:bool) -> void:
	if is_local:
		ProjectProperties.list_snapshot(snapshot_details)
	pass

func unlist_snapshot(snapshot_index:int, is_local:bool) -> void:
	if is_local:
		ProjectProperties.unlist_snapshot_by_idx(snapshot_index)
	pass

func reset_last_save(last_save, is_local:bool) -> void:
	if is_local:
		ProjectProperties.reset_last_save(last_save)
	pass
