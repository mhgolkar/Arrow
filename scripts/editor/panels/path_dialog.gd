# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Path Dialog
# Acts as a general purpose file/dir path prompt. Check out `Settings::PATH_DIALOG_PROPERTIES`.
extends FileDialog

onready var Main = get_tree().get_root().get_child(0)
onready var BlockingOverlay = get_node(Addressbook.BLOCKING_OVERLAY)

var _DIALOG_BLOCKED_VIEW_PER_SE:bool = false 

var _CURRENT_CALLBACK_HOST:Object
var _CURRENT_CALLBACK_IDENT:String
var _CURRENT_EXTRA_ARGUMENTS:Array

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	self.connect("dir_selected", self, "_on_dir_selected", [], CONNECT_DEFERRED)
	self.connect("file_selected", self, "_on_file_selected", [], CONNECT_DEFERRED)
	self.connect("files_selected", self, "_on_files_selected", [], CONNECT_DEFERRED)
	self.connect("popup_hide", self, "_on_hide", [], CONNECT_DEFERRED)
	self.connect("visibility_changed", self, "_on_hide", [], CONNECT_DEFERRED)
	pass
	
func refresh_prompt_for(callback_host:Object, callback_ident:String, extra_arguments:Array = [], dialog_options:Dictionary = {}, show:bool = true) -> void:
	_CURRENT_CALLBACK_HOST = callback_host
	_CURRENT_CALLBACK_IDENT = callback_ident
	_CURRENT_EXTRA_ARGUMENTS = extra_arguments.duplicate(true)
	for option in dialog_options:
		if option in self:
			self.set(option, dialog_options[option])
	if show:
		self.call_deferred("set_exclusive", true) # do not close by clicking outside the panel
		self.call_deferred("popup") # `show` and refresh
		if BlockingOverlay.is_visible() == false:
			_DIALOG_BLOCKED_VIEW_PER_SE = true
			BlockingOverlay.set_visible(true)
	pass

func callback_with_path(path_string_or_pool_string_array) -> void:
	_CURRENT_EXTRA_ARGUMENTS.push_front(path_string_or_pool_string_array)
	_CURRENT_CALLBACK_HOST.callv(_CURRENT_CALLBACK_IDENT, _CURRENT_EXTRA_ARGUMENTS)
	pass

func _on_file_selected(path:String) -> void:
	callback_with_path(path)
	pass

func _on_dir_selected(path:String) -> void:
	callback_with_path(path)
	pass

func _on_files_selected(paths:PoolStringArray) -> void:
	callback_with_path(paths)
	pass

func _on_hide() -> void:
	if self.is_visible() == false && _DIALOG_BLOCKED_VIEW_PER_SE == true:
		_DIALOG_BLOCKED_VIEW_PER_SE = false
		BlockingOverlay.set_visible(false)
	pass
