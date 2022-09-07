# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Dialog Node Shared Class
class_name DialogSharedClass

const DEFAULT_NODE_DATA = {
	"character": -1, # ~ anonymous or unset (hardcoded convention)
	"lines": ["Hey there!"],
	# -- optional(s) --
	# > Manual playability. Hint: To optimize, set it for majority.
	"playable": false, # (It's `false` for mostly NPC talk.)
}

const ANONYMOUS_CHARACTER = {
	"name": "Anonymous" ,
	"color": "ffffff", # white
}
