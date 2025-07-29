# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# New Release Check
extends Button

# reference to `Main` (root)
@onready var Main = get_tree().get_root().get_child(0)

var NewVersionNotification = self
var Checker

func _ready() -> void:
	Checker = HTTPRequest.new()
	self.add_child(Checker)
	Checker.request_completed.connect(self._new_version_check_request_completed)
	Checker.request( Settings.LATEST_RELEASE_CHECK_API )
	pass

func _new_version_check_request_completed(_result, response_code, _headers, body) -> void:
	if response_code == 200 :
		var release_data = Helpers.Utils.parse_json( body.get_string_from_utf8() )
		if release_data.has('tag_name'):
			notify_new_release( release_data )
	else:
		print_debug("New Version Check Failed! Response Code: ", response_code)
	Checker.queue_free()
	pass

func notify_new_release( data ) -> void:
	print_debug("New Version Check Successful. Latest Version Tag: ", data.tag_name)
	if data.tag_name != Settings.CURRENT_RELEASE_TAG:
		NewVersionNotification.set_text( tr("NEW_VERSION_RELEASE_MSG") % data.tag_name )
		NewVersionNotification.pressed.connect(OS.shell_open.bind(Settings.ARROW_RELEASES_ARCHIVE))
		NewVersionNotification.set_visible( true )
	pass
