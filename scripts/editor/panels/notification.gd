# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Notification Popup
extends ColorRect

onready var Main = get_tree().get_root().get_child(0)

var Utils = Helpers.Utils

onready var Heading = get_node(Addressbook.NOTIFICATION.HEADING)
onready var Message = get_node(Addressbook.NOTIFICATION.MESSAGE)
onready var Colorband = get_node(Addressbook.NOTIFICATION.COLORBAND)
onready var DismissButton = get_node(Addressbook.NOTIFICATION.DISMISS_BUTTON)
onready var CustomButtonsHolder = get_node(Addressbook.NOTIFICATION.CUSTOM_BUTTONS_HOLDER)

const NOTIFICATION_COLOR_BAND_DEFAULT_COLOR = Settings.NOTIFICATION_COLOR_BAND_DEFAULT_COLOR

const REQUIRED_CUSTOM_ACTION_KEYS = ["label", "callee", "method"]

var CUSTOM_BUTTONS_PROPERTIES = {
	"size_flags_horizontal": SIZE_SHRINK_END,
	"size_flags_vertical": SIZE_SHRINK_END,
}

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	DismissButton.connect("pressed", self, "close_this_notification", [], CONNECT_DEFERRED)
	pass

func close_this_notification() -> void:
	clear_up_notification()
	Main.UI.call_deferred("set_panel_visibility", "notification", false)
	pass

func clear_up_notification() -> void:
	# remove all custom buttons made
	for node in CustomButtonsHolder.get_children():
		if node is Button:
			if is_instance_valid(node):
				node.free()
	pass

func check_and_append_custom_button(action:Dictionary) -> bool:
	if action.has_all(REQUIRED_CUSTOM_ACTION_KEYS):
		if (
			(action.label is String) && action.label.length() > 0 &&
			(action.callee is Object) && action.callee &&
			((action.method is String) && action.method.length() > 0 && action.callee.has_method( action.method ))
		):
			var extra_args = ( action.arguments if (action.has("arguments") && (action.arguments is Array)) else [] )
			var custom_button = Button.new()
			custom_button.set_text(action.label)
			for property in CUSTOM_BUTTONS_PROPERTIES:
				custom_button.set(property, CUSTOM_BUTTONS_PROPERTIES[property])
			custom_button.connect("pressed", self, "call_and_close", [action.callee, action.method, extra_args], CONNECT_DEFERRED )
			CustomButtonsHolder.add_child(custom_button)
			return true
	return false

func call_and_close(callee:Object, method:String, extra_args:Array) -> void:
	callee.callv(method, extra_args)
	close_this_notification()
	pass

# `show_notification` accepts a list of `actions` as parameter with following format:
# 		array<actions>[ { label:string<button_label>, callee:node, method:string<method_to_call> arguments:array'optional[] } ,... ]
# then makes `label`ed buttons which will call the `method` on `callee` node/object if pressed by the user,
# with the `arguments` passed to the `method` if provided.
# there will also be a default `Dismiss` button which closes the notification with no furthur action.
func show_notification(heading:String, rich_text_message:String, actions:Array = [], color:Color = NOTIFICATION_COLOR_BAND_DEFAULT_COLOR, hide_dismiss_button:bool = false) -> void:
	clear_up_notification()
	# set up fields
	if heading.length() > 0 && rich_text_message.length() > 0 :
		# update heading
		Heading.set_text(heading)
		# message supports BBCode ...
		Message.clear() # clean up and try to set bbcode first
		if Message.append_bbcode(rich_text_message) != OK: # if unsuccessful
			# set as normal text
			Message.set_text(rich_text_message)
		# in case of custom actions (buttons) ...
		var has_custom_buttons:bool = false
		if actions.size() > 0 :
			for action in actions:
				if (
					check_and_append_custom_button(action) == true
					# ... any button is successfully appended after check
				):
					# ... make custom buttons holder visible
					has_custom_buttons = true
		CustomButtonsHolder.set_visible(has_custom_buttons)
		# force the `Dismiss` button to be shown by default or when there is no custom button
		DismissButton.set_visible( (! has_custom_buttons) || (! hide_dismiss_button) )
		# set the color
		Colorband.set_deferred("color", color)
		# finally, show the panel,
		Main.UI.call_deferred("set_panel_visibility", "notification", true)
		# ... and try to steal focus
		DismissButton.grab_focus()
	else:
		printerr("Wrong Call! show_notification is called with no heading or no message.")
	pass
