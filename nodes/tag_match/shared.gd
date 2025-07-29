# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Tag-Match Node Shared Class
class_name TagMatchSharedClass

# IMPORTANT!
# Optional node properties (those with default values commonly used,)
# can be left from the saved project files, optimizing them for size.
# This is a tricky process and may depend on the version of Arrow, runtime and project file format.
# It's advised to be used on versions with universally trusted defaults (i.e. most of recent stable releases.)
const SAVE_UNOPTIMIZED = false

const DEFAULT_NODE_DATA = {
	"character": -1, # ~ anonymous or unset (hardcoded convention)
	"tag_key": "", # tag keys can not be blank
	"patterns": [""],
	# -- optional(s) --
	# > Compare using RegEx. Hint: To optimize, set it for majority.
	"regex": false, # (It's `false` because simple text comparison is faster, safer and more common.)
}

# Invalid, used in display
const INVALID_CHARACTER = {
	"name": "TAG_MATCH_INVALID_CHAR_NAME", # Translated ~ "Invalid Character"
	"color": "00000000", # 00-Alpha
}

# Returns index of the matching pattern or -1.
# There will naturally be no matching, for keys that does not exist,
# patterns that are not String, or any other unexpected value
static func find_matching(tags: Dictionary, tag_key: String, patterns: Array, use_regex: bool) -> int:
	if tags.has(tag_key) && tags[tag_key] is String:
		var tag_value = tags[tag_key]
		for index in range(0, patterns.size()):
			var pattern = patterns[index]
			if pattern is String:
				if use_regex:
					var regex = RegEx.new()
					if ( regex.compile(pattern) == OK ):
						# RegEx.search() returns RegExMatch if found, otherwise `null`
						if regex.search(tag_value) != null:
							return index
				else:
					if tag_value == pattern:
						return index
	return -1
