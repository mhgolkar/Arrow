# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Tag-Edit Node Type Shared Class
# (a set of constants and functions used by different scripts of Tag-Edit node type)
class_name TagEditSharedClass

const METHODS_ENUM = {
	"INSET": 0,
	"RESET": 1,
	"OVERSET": 2,
	"OUTSET": 3,
	"UNSET": 4,
}

const METHODS = {
	# All the method names are expected to be translated
	METHODS_ENUM.INSET: "TAG_EDIT_METHOD_INSET",
	METHODS_ENUM.RESET: "TAG_EDIT_METHOD_RESET",
	METHODS_ENUM.OVERSET: "TAG_EDIT_METHOD_OVERSET",
	METHODS_ENUM.OUTSET: "TAG_EDIT_METHOD_OUTSET",
	METHODS_ENUM.UNSET: "TAG_EDIT_METHOD_UNSET",
}

const METHODS_HINTS = {
	# All the hints are expected to be translated
	METHODS_ENUM.INSET: "TAG_EDIT_METHOD_HINT_INSET",
	METHODS_ENUM.RESET: "TAG_EDIT_METHOD_HINT_RESET",
	METHODS_ENUM.OVERSET: "TAG_EDIT_METHOD_HINT_OVERSET",
	METHODS_ENUM.OUTSET: "TAG_EDIT_METHOD_HINT_OUTSET",
	METHODS_ENUM.UNSET: "TAG_EDIT_METHOD_HINT_UNSET",
}

const METHOD_NEEDS_NO_VALUE = [
	METHODS_ENUM.UNSET
]

# Tag-Edit follows the same convention that other character related nodes have.

const DEFAULT_NODE_DATA = {
	"character": -1, # ~ invalid anonymous unset (hardcoded convention)
	"edit": [METHODS_ENUM.RESET, "", ""], # Invalid (key length must be > 0) but safe (no such key is allowed to exist)
}

# Invalid but may be used in display
const ANONYMOUS_CHARACTER = {
	"name": "Anonymous" ,
	"color": "ffffff", # white
}

static func data_is_valid(data) -> bool:
	return (
		data != null && data is Dictionary &&
		data.has("character") && (data.character is int && data.character >= 0) &&
		data.has("edit") && data.edit is Array && data.edit.size() >= 3 &&
		METHODS.has(data.edit[0]) && data.edit[1] is String && data.edit[1].length() > 0 && data.edit[2] is String
	)
