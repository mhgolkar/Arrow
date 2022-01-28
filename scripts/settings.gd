# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Top Level App Settings
# Other scripts use this class as a centralized set of configurations
class_name Settings

const ARROW_VERSION = "1.5.0"
const ARROW_WEBSITE = "https://github.com/mhgolkar/Arrow"

const CURRENT_RELEASE_TAG = "v1.5.0"
const ARROW_RELEASES_ARCHIVE = "https://github.com/mhgolkar/Arrow/releases/"
const LATEST_RELEASE_CHECK_API = "https://api.github.com/repos/mhgolkar/Arrow/releases/latest"

# Sandbox

# This mode (true) won't auto generate files (including `arrow.config` if there is no one found.)
# This setting is exported by `/root/Main` node and may be changed in the editor. It can also be set using `--sandbox` cli argument.
const RUN_IN_SANDBOX = false

# User Configurations File

# Arrow searchs for a user configuration file on startup.
# The file contains UI preferences, app local/working directory (where projects are saved,) etc.
const CONFIG_FILE_NAME = "config.arrow"
const CONFIG_FILES_SUB_PATH_DIR_PRIORITY = ["user://", "res://"]
# The file will be automatically generated in the directory with lowest priority if there is no one found.
# A custom base-directory path for the configuration file also be set using `--config-dir` cli argument:
# $ arrow --config-dir '/home/user/.config'
# The work (or project management) directory may also be overridden using `--work-dir` cli argument.

# MainUserInterface

const PANELS_OPEN_BY_DEFAULT = ["inspector"]
const BLOCKING_PANELS = ["preferences", "new_project_prompt", "about", "notification"]

# Helpers::Utils

const EVER_THERE_RES_FILE = "res://icon.png" # A file that ALWAYS EXISTS in `res://`, to get absolute path there via a workaround.
const DISCOURAGED_FILENAME_CHARACTERS = [" ", ":", "?", "*", "|", "%", "<", ">", "#", "."]
const TIME_STAMP_TEMPLATE = "{year}.{month}.{day} {hour}:{minute}:{second}"
const TIME_STAMP_TEMPLATE_UTC_MARK = " UTC"

# ProjectManagement

const PROJECT_LIST_FILE_NAME = "projects.arrow"
const USE_JSON_FOR_PROJECT_FILES = null
	# null  : auto-detect and comply with the user preference
	# true  : auto-detect on open, always save as JSON (converts binary in-place)
	# false : works with Godot variants
const PROJECT_FILE_JSON_DEFAULT_IDENT = "\t"
const PROJECT_FILE_EXTENSION = ".arrow-project" # CAUTION! change `PATH_DIALOG_PROPERTIES` respectively.

# Mind

const SNAPSHOT_VERSION_PREFIX = "v"
const TAKE_INITIAL_SNAPSHOT = true

# History

const MAXIMUM_HISTORY_SIZE_PER_NODE = 7
const SKIP_INITIAL_COPY_TRACK_FOR_NODE_TYPE = [
	"condition", "macro_use", "user_input", "variable_update", "generator"
]

# Grid

const GRID_INITIAL_ZOOM = 1.0
const ZOOM_ENHANCEMENT_FACTOR = 0.1
const SKIP_NODE_SELF_MODULATION_COLOR_ON  = Color( 0.75, 0.75, 0.75, 0.75)
const SKIP_NODE_SELF_MODULATION_COLOR_OFF = Color( 1, 1, 1, 1 )
const GRID_GO_TO_AUTO_ADJUSTMENT_FACTOR = Vector2(0.5, 0.5) # it moves view offset
const NODE_HIGHLIGHT_FADE_TIME_OUT = 0.35 # Seconds

const QUICK_INSERT_NODES_ON_SINGLE_CLICK = false
const INVALID_QUICK_CONNECTION = {
	"TO":   ["entry"],
	"FROM": ["jump"]
}

# [ Modular Node Type System ]
# NodeTypes

# Arrow has a modular node type system which allows users to make *and possibly share* their own custom types of narrative plot nodes.
# You can find default node types (such as 'condition', 'content', 'dialog', 'interaction', etc.) in `res://nodes` directory and use them as templates to make your own node type modules.
const NODES_RES_DIR = "res://nodes/"
# Each node type module needs to have following set of components to work properly:
const NODE_TYPE_NODE_FILE_NAME = "node.tscn"
const NODE_TYPE_INSPECTOR_FILE_NAME = "inspector.tscn"
const NODE_TYPE_CONSOLE_FILE_NAME = "console.tscn"
# 	Note: If you plan to use a custom node type and export your project with default runtime(s) such as built-in 'html-js',
# 	... you may also checkout `res://runtimes` and do some developments there as well.
const GRID_NODE_SLOT = {
	"DEFAULT": {
		"IN": { "TYPE": 0, "COLOR": Color.white },
		"OUT":{ "TYPE": 1, "COLOR": Color.white }
	}
}
const GRID_VALID_CONNECTIONS = {
	"DEFAULT": { "from": 0, "to": 1 }
}

# CAUTION! Handle with care:
const RESTRICT_OUT_SLOTS_TO_ONE_CONNECTION = true
#	Two outgoing connections from one node is not normal and may end up in unexpected behavior, or in best scenario playing just one of the connections.
#	`hub` and `randomizer` nodes are designed to manage it, and this setting is to make sure UI code restricts make of abnormal connections.
#	Yet it's all ok for two connection to one incoming, it's just like a hub, so the other side doesn't have a setting to be restricted.

const NODE_INITIAL_NAME_TEMPLATE = "{prefix}N{node_id_base36}{type_abbreviation}" # and/or {node_id} (int)
const NODE_INITIAL_NAME_PREFIX_FOR_SCENES = "S"
const NODE_INITIAL_NAME_PREFIX_FOR_MACROS = "M"
const MINIMUM_TYPE_ABBREVIATION_LENGTH = 3 # used to make name of a node type shorter for use in plot node naming.

# Every new scene (or macro) needs a node as the first one to be run and start a specific narrative plot-line.
# Technically, this starting node can be of any type,
# ... but it's more convenient to use an 'entry', because of the special treatments it gets from the editor. 
const NEW_SCENE_OR_MACRO_REQUIRED_INITIAL_ENTRY_NODE_TYPE = "entry"
const NEW_SCENE_OR_MACRO_REQUIRED_INITIAL_ENTRY_NODE_OFFSET = Vector2(100, 100)

# New node position adjustment to avoid nodes overlap and mask each other when made in batch (i.e. multiple selection and insertion.)
const BATCH_NODE_INSERTION_POSITION_ADJUSTMENT_VECTOR2 = Vector2(30, 30)

# The node type of `macro_use` (and macros in general) enjoy a lot of special treatments,
# including in core and how console handles them.
const NODE_TYPES_RESTRICTED_IN_MACROS = ["macro_use"]

# Variables

# ... are used in nodes of types such as 'condition' and 'var_up', and by the central mind to manage global variables for each project.
# Don't need to change these unless you're developing new features.
const VARIABLE_TYPES = {
	"num": { "default": 0, "name": "Number" },
	"str": { "default": "", "name": "String" },
	"bool":{ "default": false, "name": "Boolean" }
}
const VARIABLE_TYPES_ENUM = {
	0: "num",
	1: "str",
	2: "bool"
}

# Unique Naming
# Arrow can handle using the same name for different nodes or scenes,
# yet it's much more convenient not to share names (so users can find a node easier when linking them via `jump`s.)
# A postfix will be added to the names that are used already.

const FORCE_UNIQUE_NAMES_FOR_VARIABLES = true
const REUSED_VARIABLE_NAMES_AUTO_POSTFIX = "_"

const FORCE_UNIQUE_NAMES_FOR_CHARACTERS = true
const REUSED_CHARACTER_NAMES_AUTO_POSTFIX = "_"

const FORCE_UNIQUE_NAMES_FOR_MACROS = true
const REUSED_MACRO_NAMES_AUTO_POSTFIX = "_"

const FORCE_UNIQUE_NAMES_FOR_SCENES = true
const REUSED_SCENE_NAMES_AUTO_POSTFIX = "_"

const NONE_UNIQUE_FILENAME_AUTO_POSTFIX = "_"

const RANDOM_PROJECT_NAME_PREFIX = "untitled_"
const RANDOM_PROJECT_NAME_AFFIX_LENGTH = 3

# Minimap

const CLASSIC_MINIMAP_ENABLED = true
const MINIMAP_PANEL_OPACITY_MODULATION_COLOR_HIDE = Color( 1, 1, 1, 0.5 )
const MINIMAP_PANEL_OPACITY_MODULATION_COLOR_SHOW = Color( 1, 1, 1, 1 )
const MINIMAP_DEFAULT_NODE_DRAWING_COLOR = Color( 0.5, 0.5, 0.5, 0.9 )
const MINIMAP_CROSSHAIR_COLOR = Color(0, 0.5, 1, 0.5)
const MINIMAP_CROSSHAIR_COLOR_OUT_OF_BOUND = Color(1, 0.5, 0, 0.5)
const MINIMAP_CROSSHAIR_WIDTH = 2

# Color Palette

const INFO_COLOR = Color.greenyellow
const CAUTION_COLOR = Color.yellow
const WARNING_COLOR = Color("ff0bb1") # redish
const PEACE_COLOR = Color("0fcbf4") # cyanish

# Notifications

const NOTIFICATION_COLOR_BAND_DEFAULT_COLOR = INFO_COLOR

# Console

const CONSOLE_MESSAGE_DEFAULT_COLOR = INFO_COLOR
# ... and modulation color for skipped nodes
const CONSOLE_SKIPPED_NODES_SELF_MODULATION_COLOR_ON = Color.darkgray
const CONSOLE_SKIPPED_NODES_SELF_MODULATION_COLOR_OFF = Color( 1, 1, 1, 1 )

# Editor

const PROJECT_UNSAVE_INDICATION_COLOR = WARNING_COLOR
const PROJECT_SAVE_INDICATION_COLOR = PEACE_COLOR

const PATH_DIALOG_PROPERTIES = {
	"PROJECT_FILE" : {
		"OPEN" : {
			"window_title": "Select a Project File",
			"mode": FileDialog.MODE_OPEN_FILE,
			"access": FileDialog.ACCESS_FILESYSTEM,
			"filters": PoolStringArray(["*.arrow-project ; Arrow Project", "*.json ; Exported Arrow Project"])
		},
		"SAVE": {
			"window_title": "Save Project as File",
			"mode": FileDialog.MODE_SAVE_FILE,
			"access": FileDialog.ACCESS_FILESYSTEM,
			"filters": PoolStringArray(["*.arrow-project ; Arrow Project"])
		},
		"EXPORT_JSON": {
			"window_title": "Save Project with JSON Format",
			"mode": FileDialog.MODE_SAVE_FILE,
			"access": FileDialog.ACCESS_FILESYSTEM,
			"filters": PoolStringArray(["*.json ; Exported Arrow Project"])
		},
		"EXPORT_HTML": {
			"window_title": "Export Playable HTML",
			"mode": FileDialog.MODE_SAVE_FILE,
			"access": FileDialog.ACCESS_FILESYSTEM,
			"filters": PoolStringArray(["*.html ; Playable HTML"])
		}
	},
	"DIRECTORY" : {
		"LOCAL_APP" : {
			"window_title": "Select App Local Directory",
			"mode": FileDialog.MODE_OPEN_DIR,
			"access": FileDialog.ACCESS_FILESYSTEM,
			"filters": PoolStringArray([])
		}
	}
}

# Clipboard

# Don't need to change these unless you're developing new features.
const CLIPBOARD_MODE = { "EMPTY":0, "COPY":1, "CUT":2 }

# Runtimes

const HTML_JS_SINGLE_FILE_TEMPLATE_PATH = 'res://runtimes/html-js.arrow-runtime'

const PURGE_DEVELOPMENT_DATA_FROM_PLAYABLES = true
const DATA_TO_BE_PURGED_FROM_PLAYABLE_METADATA:Array = [
	'offline', 'remote', 'last_save', 'arrow_editor_version'
]
const DATA_TO_BE_PURGED_FROM_PLAYABLE_RESOURCES:Dictionary = {
	"nodes": [ 'notes' ]
}

# App UI

const THEMES = {
	0: { "name": "Dark Night",  "resource": preload("res://resources/themes/dark_night.tres") },
	1: { "name": "Godot Default",  "resource": preload("res://resources/themes/godot_default.tres") },
	2: { "name": "Alien",  "resource": preload("res://resources/themes/godot_alien.tres") },
	3: { "name": "Gray",  "resource": preload("res://resources/themes/godot_gray.tres") },
	4: { "name": "Light",  "resource": preload("res://resources/themes/godot_light.tres") }
}

# TODO!
# Internationalization is not yet implemented,
# only preference setting functions is prototyped.

const SUPPORTED_UI_LANGUAGES = {
	0: { "name": "English", "code": "en-US", "locale": "en" }
}

# TODO!
# Scaling UI is not implemented yet.

# The medium scale, which is the center of the range control in the prefs panel
const SCALE_RANGE_CENTER = 1
