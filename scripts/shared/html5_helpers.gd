# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Shared helper classes
class_name Html5Helpers

# Classes

# HTML5 Utilities 
class Utils:
	
	static func is_browser() -> bool:
		return OS.get_name() == "HTML5" || OS.has_feature("JavaScript")
	
	static func window() -> JavaScriptObject:
		return JavaScript.get_interface("window")
		
	static func document() -> JavaScriptObject:
		return JavaScript.get_interface("document")
	
	static func alert(msg: String) -> void:
		window().alert(msg)
		pass
	
# HTML5 File Reader Helper
# This allows opening project files with permissioned access to the user's device file-system
class Reader:
	
	var ReaderCallbackRef;
	var FileReader;
	var BrowserCallbackRef;
	var BrowserInput;
	
	var Caller;
	var Callback;
	
	var Browsed;
	
	func _init() -> void:
		if Utils.is_browser():
			ReaderCallbackRef = JavaScript.create_callback(self, "read_file_data")
			FileReader = JavaScript.create_object("FileReader")
			FileReader.onload = ReaderCallbackRef
			BrowserCallbackRef = JavaScript.create_callback(self, "browse_file")
			BrowserInput = Utils.document().createElement("input")
			BrowserInput.type = "file"
			BrowserInput.accept= Settings.PROJECT_FILE_EXTENSION + ",.json"
			BrowserInput.onchange = BrowserCallbackRef
		pass
		
	func read_file_data(args):
		var event = args[0]
		var content = event.target.result;
		Caller.call_deferred(Callback, content, Browsed.name)
		event.preventDefault()
		event.returnValue = ''
		# print_debug("browser read file: ", content)
		pass
	
	func browse_file(args):
		var event = args[0]
		var file = event.target.files[0]
		Browsed = file
		FileReader.readAsText(file,'UTF-8');
		event.preventDefault()
		event.returnValue = ''
		pass
	
	func read_file_then(caller: Reference, method: String):
		if Utils.is_browser():
			Caller = caller
			Callback = method
			BrowserInput.click()
		else:
			printerr("HTML5 FS helpers read in context other than browser!")
		pass
	
