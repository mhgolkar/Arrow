# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Inspector Panel
extends PanelContainer

signal request_mind

onready var Main = get_tree().get_root().get_child(0)

onready var TheTabContainer = get_node(Addressbook.INSPECTOR.TAB_CONTAINER)
onready var Tab = {
	"Scenes": get_node(Addressbook.INSPECTOR.SCENES.itself),
	"Node": get_node(Addressbook.INSPECTOR.NODE.itself),
	"Macros": get_node(Addressbook.INSPECTOR.MACROS.itself),
	"Variables": get_node(Addressbook.INSPECTOR.VARIABLES.itself),
	"Characters": get_node(Addressbook.INSPECTOR.CHARACTERS.itself),\
	"Project": get_node(Addressbook.INSPECTOR.PROJECT.itself),
}

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	# relaying tab mind request signals
		# `relay_request_mind` signals from following nodes will be relayed to the mind
		# by translating them to `request_mind` signal; this way the mind only needs to
		# listen to the inspector panel instead of a lot of child nodes. just cleaner!
	for tab_title in Tab:
		var transmitter_tab_node = Tab[tab_title]
		transmitter_tab_node.connect("relay_request_mind", self, "request_mind_relay", [tab_title, transmitter_tab_node], 0)
	# direct signaling
	TheTabContainer.connect("tab_changed", self, "handle_tab_change")
	TheTabContainer.connect("gui_input", self, "_on_gui_input")
	pass

# called by Mind while opening a project
func initialize_tabs():
	for tab_title in Tab:
		Tab[tab_title].call_deferred("initialize_tab")
	handle_tab_change(-1)
	pass

func request_mind_relay(req:String, args=null, _tab=null, _tab_node=null):
	emit_signal("request_mind", req, args)
	pass

func handle_tab_change(tab_idx:int):
	if tab_idx < 0 :
		tab_idx = TheTabContainer.get_current_tab()
	# when we come from another tab to ...
	var tab_title = TheTabContainer.get_tab_title(tab_idx)
	# it's better to referesh important lists to avoid conflicts,
	# in case the user have changed the dataset or resources' `use`cases.
	if Tab.has(tab_title):
		Tab[tab_title].call_deferred("refresh_tab")
	# any tab specific actions ?
#	match tab_title:
#		"Project":
#			pass
	pass

var _tab_indices_smartly_sorted_by_title = {}
func show_tab_of_title(title:String = ""):
	if title.length() > 0 && Tab.has(title):
		var redetect_indices:bool = false
		if _tab_indices_smartly_sorted_by_title.has(title):
			var tab_idx = _tab_indices_smartly_sorted_by_title[title]
			if TheTabContainer.get_tab_title(tab_idx) == title :
				TheTabContainer.set_current_tab(tab_idx)
			else: # tabs are sure re-sorted by the user
				redetect_indices = true
		else:
			redetect_indices = true
		# When indices are not as expected, we shall make sure that list is sorted right,
		# because tabs may be resorted manually by the user (with no special signal to detect)
		if redetect_indices != false:
			for idx in range(0, TheTabContainer.get_tab_count()):
				var tab_title = TheTabContainer.get_tab_title(idx)
				_tab_indices_smartly_sorted_by_title[tab_title] = idx
			if _tab_indices_smartly_sorted_by_title.has(title):
				show_tab_of_title(title)
	pass

func scroll_tabs_workaround(mouse_event: InputEventMouseButton) -> void:
	var mouse_button = mouse_event.get_button_index()
	if mouse_button == BUTTON_WHEEL_UP || BUTTON_WHEEL_DOWN == mouse_button:
		var tabs_container_rect = TheTabContainer.get_global_rect()
		var mouse_position = mouse_event.get_global_position()
		if tabs_container_rect.has_point(mouse_position):
			var current_tab = TheTabContainer.get_current_tab_control()
			var current_tab_rect = current_tab.get_global_rect()
			var tab_bar_y_limits = [tabs_container_rect.position.y, current_tab_rect.position.y]
			if mouse_position.y >= tab_bar_y_limits[0] && mouse_position.y <= tab_bar_y_limits[1]:
				var direction = (0 if mouse_event.is_pressed() else (1 if mouse_button == BUTTON_WHEEL_UP else (-1)))
				var next_tab_index = TheTabContainer.get_current_tab() + direction
				var caped_next = max(0, min(TheTabContainer.get_tab_count() - 1, next_tab_index))
				TheTabContainer.set_current_tab(caped_next)
				# handle_tab_change() # It'll be called by internal signaling
	pass

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		scroll_tabs_workaround(event)
	pass

# make this panel,
# dragable
	# ... it also makes the panel compete for the parent's top z-index by default
onready var drag_point = get_node(Addressbook.INSPECTOR.drag_point)
onready var dragability = Helpers.Dragable.new(self, drag_point)
# and resizable
onready var resize_pont = get_node(Addressbook.INSPECTOR.resize_point)
onready var resizability = Helpers.Resizable.new(self, resize_pont)
