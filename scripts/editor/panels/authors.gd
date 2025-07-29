# Game Narrative Design Tool
# Mor. H. Golkar

# Authors Panel
extends Control

signal request_mind()

@onready var Main = get_tree().get_root().get_child(0)

@onready var CloseButton = $/root/Main/Overlays/Control/Authors/Margin/Sections/Toolbar/Close
@onready var AuthorsList = $/root/Main/Overlays/Control/Authors/Margin/Sections/Management/Parts/Contributors/Tools/List
@onready var AuthorsIdSpinBox = $/root/Main/Overlays/Control/Authors/Margin/Sections/Management/Parts/Contributors/Tools/Editor/Author/Data/Identity/Unique/Uid
@onready var AuthorsInfoEdit = $/root/Main/Overlays/Control/Authors/Margin/Sections/Management/Parts/Contributors/Tools/Editor/Author/Data/Identity/Information/Input
@onready var AuthorActiveCheckbox = $/root/Main/Overlays/Control/Authors/Margin/Sections/Management/Parts/Contributors/Tools/Editor/Author/Data/Identity/Unique/Active
@onready var AuthorEditRemove = $/root/Main/Overlays/Control/Authors/Margin/Sections/Management/Parts/Contributors/Tools/Editor/Author/Actions/Remove
@onready var AuthorEditSave = $/root/Main/Overlays/Control/Authors/Margin/Sections/Management/Parts/Contributors/Tools/Editor/Author/Actions/Apply
@onready var ChapterPanel = $/root/Main/Overlays/Control/Authors/Margin/Sections/Management/Parts/Chapter
@onready var ChapterIdSpinBox = $/root/Main/Overlays/Control/Authors/Margin/Sections/Management/Parts/Chapter/Editor/Id
@onready var UpdateChapter = $/root/Main/Overlays/Control/Authors/Margin/Sections/Management/Parts/Chapter/Editor/Update

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	CloseButton.pressed.connect(self._toggle, CONNECT_DEFERRED)
	AuthorsList.item_selected.connect(self._on_item_selected, CONNECT_DEFERRED)
	AuthorsIdSpinBox.value_changed.connect(self._on_edit_id_value_changed, CONNECT_DEFERRED)
	AuthorEditSave.pressed.connect(self._on_save_author, CONNECT_DEFERRED)
	AuthorEditRemove.pressed.connect(self._on_remove_author, CONNECT_DEFERRED)
	UpdateChapter.pressed.connect(self._on_update_chapter, CONNECT_DEFERRED)
	pass

func _toggle() -> void:
	Main.call_deferred("toggle_authors")
	if _PROJECT_META.size() > 0:
		reset_authors(_PROJECT_META, _ACTIVE_AUTHOR, true)
	pass

var _PROJECT_META: Dictionary;
var _AUTHORS_LIST: Dictionary;
var _ACTIVE_AUTHOR: int;

func reset_authors(project_meta:Dictionary, active_one = null, auto_select:bool = false) -> void:
	AuthorsList.clear()
	print_debug("authors listed: ", project_meta.authors)
	var is_snow_flaker = (project_meta.has("epoch") && project_meta.epoch is int && project_meta.epoch > 0)
	var author_id_limit = (Flake.Snow.AUTHOR_ID_EXCLUSIVE_LIMIT if is_snow_flaker else Flake.Native.AUTHOR_ID_EXCLUSIVE_LIMIT);
	var all_ids = project_meta.authors.keys()
	if (active_one is int) == false || all_ids.has(active_one) == false:
		active_one = all_ids[0]
	for index in range(0, all_ids.size()):
		var author_id = all_ids[index]
		if (author_id is int) && author_id < author_id_limit:
			if project_meta.authors[author_id] is Array && project_meta.authors[author_id].size() >= 2:
				var author_info = project_meta.authors[author_id][0]
				var author_seed = project_meta.authors[author_id][1]
				var author_item = (
					(tr("ACTIVE_AUTHOR_MARKER") if author_id == active_one else "") +
					String.num_int64(author_id) + ": " + author_info + " (" + String.num_int64(author_seed) + ")"
				)
				AuthorsList.call_deferred("add_item", author_item)
				AuthorsList.call_deferred("set_item_metadata", index, author_id)
				if auto_select && author_id == active_one:
					AuthorsList.call_deferred("select", index, true)
					self.call_deferred("_on_item_selected", index)
		else:
			printerr("invalid author! with out of bound ID: ", author_id)
	# ...
	if project_meta.has("chapter"):
		ChapterIdSpinBox.set_deferred("value", int(project_meta.chapter))
	# ...
	_PROJECT_META = project_meta
	_AUTHORS_LIST = project_meta.authors
	_ACTIVE_AUTHOR = active_one
	# ...
	AuthorsIdSpinBox.set_deferred("max_value", author_id_limit - 1)
	ChapterIdSpinBox.set_deferred("max_value", Flake.Native.CHAPTER_ID_EXCLUSIVE_LIMIT - 1)
	ChapterPanel.set_deferred("visible", is_snow_flaker != true)
	pass

func reset_author_editor(author_id:int = -1) -> bool:
	var existent = _AUTHORS_LIST.has(author_id)
	var is_active = (_ACTIVE_AUTHOR == author_id)
	var only_one = (_AUTHORS_LIST.size() <= 1)
	var positive_seed = (existent && _AUTHORS_LIST[author_id][1] > 0)
	AuthorsIdSpinBox.set_value(author_id)
	AuthorActiveCheckbox.set_pressed(is_active)
	AuthorsInfoEdit.set_text(_AUTHORS_LIST[author_id][0] if existent else "")
	AuthorEditRemove.set_disabled( existent == false || only_one || positive_seed )
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
	var author_id = int( AuthorsIdSpinBox.get_value() )
	var author_info = AuthorsInfoEdit.get_text()
	var is_active = AuthorActiveCheckbox.is_pressed()
	request_update_author(author_id, author_info, is_active)
	pass

func _on_remove_author() -> void:
	var author_id = int( AuthorsIdSpinBox.get_value() )
	request_remove_author(author_id)
	pass
	
func _on_update_chapter() -> void:
	var chapter_id = int( ChapterIdSpinBox.get_value() )
	if chapter_id < Flake.Native.CHAPTER_ID_EXCLUSIVE_LIMIT:
		request_update_chapter(chapter_id)
	else:
		printerr("Chapter ID out of bound! i.e. < ", Flake.Native.CHAPTER_ID_EXCLUSIVE_LIMIT)
	pass

func request_update_author(id:int, info: String, active:bool) -> void:
	self.request_mind.emit("update_author", {
		"id": id,
		"info": info,
		"active": active,
	})
	pass
	
func request_remove_author(id:int) -> void:
	self.request_mind.emit("remove_author", id)
	pass

func request_update_chapter(id:int) -> void:
	self.request_mind.emit("update_chapter", id)
	pass
