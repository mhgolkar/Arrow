# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Tag-Pass Node Type Shared Class
# (a set of constants and functions used by different scripts of Tag-Pass node type)
class_name TagPassSharedClass

const METHODS_ENUM = {
	"ANY": 0,
	"ALL": 1,
}

const METHODS = {
	METHODS_ENUM.ANY: "Any (OR)",
	METHODS_ENUM.ALL: "All (AND)",
}

const METHODS_HINTS = {
	METHODS_ENUM.ANY: "If at least one of the tags matches, it short-circuits and passes.",
	METHODS_ENUM.ALL: "All tags shall match for the node to pass.",
}

const METHOD_ACCEPTS_KEY_ONCE = [
	METHODS_ENUM.ALL
]

# Tag-Pass follwos the same convention that other character related nodes have.

const DEFAULT_NODE_DATA = {
	"character": -1, # ~ invalid anonymous unset (hardcoded convention)
	"pass": [ METHODS_ENUM.ALL, [ ["", null] ] ], # (it's safe; invalid tags are ignored)
	# Note: Value of `null` means to check for key only; but blank value (``) means normal check for both key and value.
}

# Invalid but may be used in display
const ANONYMOUS_CHARACTER = {
	"name": "Anonymous" ,
	"color": "ffffff", # white
}

static func tag_is_checkable(entity) -> bool:
	return (
		entity is Array && entity.size() >= 1 && # at least a key
		entity[0] is String && entity[0].length() > 0 && # valid key
		(entity.size() == 1 || entity[1] == null || entity[1] is String) # valid value (including unchecked)
	)

static func data_is_valid(data) -> bool:
	return (
		data != null && data is Dictionary &&
		data.has("character") && (data.character is int && data.character >= 0) &&
		data.has("pass") && data.pass is Array && data.pass.size() >= 2 &&
		METHODS.has(data.pass[0]) && data.pass[1] is Array
		# && Invalid tags are dropped/ignored by pass scripts, so we don't need to check deeper
	)
