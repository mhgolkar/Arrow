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

# make this panel,
# dragable
	# ... it also makes the panel compete for the parent's top z-index by default
onready var drag_point = get_node(Addressbook.INSPECTOR.drag_point)
onready var dragability = Helpers.Dragable.new(self, drag_point)
# and resizable
onready var resize_pont = get_node(Addressbook.INSPECTOR.resize_point)
onready var resizability = Helpers.Resizable.new(self, resize_pont)
