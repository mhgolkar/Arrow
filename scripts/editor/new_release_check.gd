# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# New Release Check
extends Button

# reference to `Main` (root)
onready var Main = get_tree().get_root().get_child(0)

var NewVersionNotification = self
var Checker

const NEW_VERSION_MESSAGE = "Arrow %s is Available"

func _ready() -> void:
	Checker = HTTPRequest.new()
	self.add_child(Checker)
	Checker.connect("request_completed", self, "_new_version_check_request_completed")
	Checker.request( Settings.LATEST_RELEASE_CHECK_API )
	pass

func _new_version_check_request_completed(result, response_code, headers, body) -> void:
	if response_code == 200 :
		var parsed_body = JSON.parse( body.get_string_from_utf8() )
		if parsed_body.error == OK:
			var release_data = parsed_body.get_result()
			if release_data.has('tag_name'):
				notify_new_release( release_data )
	else:
		print_debug("New Version Check Failed! Response Code: ", response_code)
	Checker.queue_free()
	pass

func notify_new_release( data ) -> void:
	print_debug("New Version Check Successful. Latest Version Tag: ", data.tag_name)
	if data.tag_name != Settings.CURRENT_RELEASE_TAG:
		NewVersionNotification.set_text( NEW_VERSION_MESSAGE % data.tag_name )
		NewVersionNotification.connect("pressed", OS, "shell_open", [ Settings.ARROW_RELEASES_ARCHIVE ])
		NewVersionNotification.set_visible( true )
	pass
