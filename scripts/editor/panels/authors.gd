# Game Narrative Design Tool
# Mor. H. Golkar

# About Panel
extends PanelContainer

signal request_mind

onready var Main = get_tree().get_root().get_child(0)

onready var CloseButton = get_node(Addressbook.AUTHORS.CLOSE_BUTTON)
onready var AuthorsList = get_node(Addressbook.AUTHORS.LIST)
onready var AuthorsIDSpinBox = get_node(Addressbook.AUTHORS.ID_SPINBOX)
onready var AuthorsInfoEdit = get_node(Addressbook.AUTHORS.INFO_EDIT)
onready var AuthorActiveCheckbox = get_node(Addressbook.AUTHORS.ACTIVE_CHECKBOX)
onready var AuthorEditRemove = get_node(Addressbook.AUTHORS.EDIT_REMOVE)
onready var AuthorEditSave = get_node(Addressbook.AUTHORS.EDIT_SAVE)

const ACTIVE_AUTHOR_MARKER = "[✓] "

func _ready() -> void:
	AuthorsIDSpinBox.set_deferred("max_value", Flake.MAX_POSSIBLE_AUTHOR_ID - 1)
	register_connections()
	pass

func register_connections() -> void:
	CloseButton.connect("pressed", self, "_toggle", [], CONNECT_DEFERRED)
	AuthorsList.connect("item_selected", self, "_on_item_selected", [], CONNECT_DEFERRED)
	AuthorsIDSpinBox.connect("value_changed", self, "_on_edit_id_value_changed", [], CONNECT_DEFERRED)
	AuthorEditSave.connect("pressed", self, "_on_save_author", [], CONNECT_DEFERRED)
	AuthorEditRemove.connect("pressed", self, "_on_remove_author", [], CONNECT_DEFERRED)
	pass

func _toggle() -> void:
	Main.call_deferred("toggle_authors")
	pass

var _AUTHORS_CACHE: Dictionary;
var _ACTIVE_AUTHOR: int;

func reset_authors(list:Dictionary, active_one:int, auto_select:bool = false) -> void:
	AuthorsList.clear()
	print_debug("authors listed: ", list)
	var all_ids = list.keys()
	if all_ids.has(active_one) == false:
		active_one = 0
	for index in range(0, all_ids.size()):
		var author_id = all_ids[index]
		if (author_id is int) && author_id < Flake.MAX_POSSIBLE_AUTHOR_ID:
			if list[author_id] is String:
				var author_info = list[author_id]
				var author_item = (
					(ACTIVE_AUTHOR_MARKER if author_id == active_one else "") +
					String(author_id) + ": " + author_info
				)
				AuthorsList.call_deferred("add_item", author_item)
				AuthorsList.call_deferred("set_item_metadata", index, author_id)
				if auto_select && author_id == active_one:
					AuthorsList.call_deferred("select", index, true)
					self.call_deferred("_on_item_selected", index)
	_AUTHORS_CACHE = list
	_ACTIVE_AUTHOR = active_one
	pass

func reset_author_editor(author_id:int = -1) -> bool:
	var existent = _AUTHORS_CACHE.has(author_id)
	var is_active = (_ACTIVE_AUTHOR == author_id)
	var only_one = (_AUTHORS_CACHE.size() <= 1)
	AuthorsIDSpinBox.set_value(author_id)
	AuthorActiveCheckbox.set_pressed(is_active)
	AuthorsInfoEdit.set_text(_AUTHORS_CACHE[author_id] if existent else "")
	AuthorEditRemove.set_disabled( existent == false || only_one )
	AuthorActiveCheckbox.set_disabled( (only_one && existent) || is_active )
	return false

func _on_item_selected(index:int) -> void:
	var author_id = AuthorsList.get_item_metadata(index)
	reset_author_editor(author_id)
	pass

func _on_edit_id_value_changed(value:float) -> void:
	reset_author_editor( int(value) )
	pass

func _on_save_author() -> void:
	var author_id = int( AuthorsIDSpinBox.get_value() )
	var author_info = AuthorsInfoEdit.get_text()
	var is_active = AuthorActiveCheckbox.is_pressed()
	request_update_author(author_id, author_info, is_active)
	pass

func _on_remove_author() -> void:
	var author_id = int( AuthorsIDSpinBox.get_value() )
	request_remove_author(author_id)
	pass

func request_update_author(id:int, info: String, active:bool) -> void:
	emit_signal("request_mind", "update_author", {
		"id": id,
		"info": info,
		"active": active,
	})
	pass
	
func request_remove_author(id:int) -> void:
	emit_signal("request_mind", "remove_author", id)
	pass
