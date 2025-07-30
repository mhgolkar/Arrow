# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Top Level App Settings
# Other scripts use this class as a centralized set of configurations
class_name Settings

const ARROW_VERSION = "3.1.0"
const ARROW_WEBSITE = "https://mhgolkar.github.io/Arrow/"

const CURRENT_RELEASE_TAG = "v3.1.0"
const ARROW_RELEASES_ARCHIVE = "https://github.com/mhgolkar/Arrow/releases/"
const LATEST_RELEASE_CHECK_API = "https://api.github.com/repos/mhgolkar/Arrow/releases/latest"

# Sandbox

# This mode (true) won't auto generate files (including `.arrow.config` if there is no one found.)
# This setting is exported by `/root/Main` node and may be changed in the editor. It can also be set using `--sandbox` cli argument.
const RUN_IN_SANDBOX = false

# User Configurations File

# Arrow searches for a user configuration file on startup.
# The file contains UI preferences, app local/working directory (where documents are saved), etc.
const CONFIG_FILE_NAME = ".arrow.config"
const CONFIG_FILES_SUB_PATH_DIR_PRIORITY = ["user://", "res://"]
# The file will be automatically generated in the directory with lowest priority if there is no one found.
# A custom base-directory path for the configuration file also be set using `--config-dir` cli argument:
# $ arrow --config-dir '/home/USER/.config/'
# The work (or project management) directory may also be overridden using `--work-dir` cli argument.
# Note that in `HTML5` exports, only `user://` is writable, so this process will not apply. 

# Main User Interface

const PANELS_OPEN_BY_DEFAULT = ["inspector"]
const BLOCKING_PANELS = ["preferences", "authors", "new_project_prompt", "about", "notification"]
const STATEFUL_PANELS = ["inspector", "console"]

# Helpers::Utils

const EVER_THERE_RES_FILE = "res://icon.svg" # A file that ALWAYS EXISTS in `res://`, to get absolute path there via a workaround.
const DISCOURAGED_FILENAME_CHARACTERS = [" ", ":", "?", "*", "|", "%", "<", ">", "#", "."]
const TIME_STAMP_TEMPLATE = "{year}.{month}.{day} {hour}:{minute}:{second}"
const TIME_STAMP_TEMPLATE_UTC_MARK = " UTC"

# Project Management

const PROJECT_LIST_FILE_NAME = ".arrow.project"
# ...
const PROJECT_FILE_EXTENSION = ".arrow" # CAUTION! change `PATH_DIALOG_PROPERTIES` respectively.
const PROJECT_FILE_NAME_PURGED_WORDS = [] # These words will be automatically replaced in a file name
const PROJECT_FILE_NAME_PURGED_WORDS_REPLACEMENT = "_"
const PROJECT_FILE_RESTRICTED_NAMES = ["projects", "config", ""] # Final filenames can not be any of these
# ...
const PROJECT_FILE_JSON_DEFAULT_IDENT = "\t"
const CSV_EXPORT_SEPARATOR = "\t"
# ...
# Binary save files are deprecated.
# You can open and automatically (re-)save them in textual format; 
# But if you still need to save your projects as binary, set this setting to `true`:
const USE_DEPRECATED_BIN_SAVE = false

# UID Management

const ANONYMOUS_AUTHOR_INFO = "Anonymous Contributor"

# > Native Distributed UID (Arrow-Flake)
# Default UIDs are inspired by Snowflakes, but highly customized,
# to support chapters, authors and an incremental seed with following bit sizes:
# It is highly recommended to keep the default values.
# For more information, read documentation of the `Native` flake ID helper.
const NATIVE_DISTRIBUTED_UID_BIT_SIZES = [10, 6, 37]

# > Snowflake Mode
# Arrow uses a custom (native) distributed UID generation (as recommended default) method.
# You can still force use of time-base (Snowflake) IDs for your new projects if you prefer them.
# Note also that you may remove default nodes created in new projects to avoid possible conflicts.
# This method does not support chapters as well.
const FORCE_SNOWFLAKE_UID_FOR_NEW_PROJECTS = false
const ALWAYS_USE_REALTIME_IDS = true # Only if the Snowflake IDs are forced (above)

# Mind

const SNAPSHOT_VERSION_PREFIX = "v"
const TAKE_INITIAL_SNAPSHOT = true

const MIND_REQUEST_DEBOUNCE_TIME_SEC = 0.25 # second(s)

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
const NODE_FLICK_FADE_TIME_OUT = 1.0 # Seconds
# NOTE: Theme variation affixes are styling keywords used to distinguish different states of graph nodes.
const NODE_THEME_VARIATION_AFFIX_FLICK = "_FLICK"
const NODE_THEME_VARIATION_AFFIX_HIGHLIGHT = {
	CLIPBOARD_MODE.COPY: "_COPY",
	CLIPBOARD_MODE.CUT: "_CUT",
}

const QUICK_INSERT_NODES_ON_SINGLE_CLICK = false
const INVALID_QUICK_CONNECTION = {
	"TO":   ["entry", "frame"],
	"FROM": ["jump", "frame"]
}
const LOCALLY_HANDLED_RESIZABLE_NODES = ["frame"]

# [ Modular Node Type System ]
# Node Types

# Arrow has a modular node type system which allows users to make *and possibly share* their own custom types of narrative plot nodes.
# You can find default node types (such as 'condition', 'content', 'dialog', 'interaction', etc.) in `res://nodes` directory and use them as templates to make your own node type modules.
const NODES_RES_DIR = "res://nodes/"
# Each node type module needs to have following set of components to work properly:
const NODE_TYPE_NODE_FILE_NAME = "node.tscn"
const NODE_TYPE_INSPECTOR_FILE_NAME = "inspector.tscn"
const NODE_TYPE_CONSOLE_FILE_NAME = "console.tscn"
const NODE_TYPE_ICON_FILE_NAME = "icon.svg"
const NODE_TYPE_TRANSLATION_FILES_DIR = "translations" # NOTE: We load every file in this directory, if existent for any of the nodes, as a Translation resource into the TranslationServer.
# ...
# NOTE: If you plan to use a custom node type and export your project with default runtime(s) such as built-in 'html-js', checkout `runtimes` directory as well.
# ...
const GRID_NODE_SLOT = {
	"DEFAULT": {
		"IN": { "TYPE": 0, "COLOR": Color.WHITE },
		"OUT":{ "TYPE": 1, "COLOR": Color.WHITE }
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

const NODE_INITIAL_NAME_TEMPLATE = "{node_id_base36}" # You can also use {node_id}, {prefix} and {type_abbreviation}
const NODE_INITIAL_NAME_PREFIX_FOR_SCENES = "S" # (+ base36 scene-id if node is in a scene)
const NODE_INITIAL_NAME_PREFIX_FOR_MACROS = "M" # (+ base36 macro-id ...)
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
#
# Newly created resource names are direct representation of
# their underlying UIDs and consequently *unique*.
# Although Arrow can handle identical names for different resources,
# it is best practice to use unique names, so to keep following settings as is,
# which force name uniqueness (default,) by adding a postfix to any duplicate name.
#
# Note also that name uniqueness is limited to the scope of each resource type
# and *is case-sensitive*. Scenes and macros share the same scope.
#
# CAUTION!
# All Affixes below shall be at least 1 character.

const FORCE_UNIQUE_NAMES_FOR_VARIABLES = true
const REUSED_VARIABLE_NAMES_AUTO_POSTFIX = "_"
const VARIABLE_NAMES_PREFIX = "var_"

const FORCE_UNIQUE_NAMES_FOR_CHARACTERS = true
const REUSED_CHARACTER_NAMES_AUTO_POSTFIX = "_"
const CHARACTER_NAMES_PREFIX = "char_"

const SCENE_NAME_PREFIX = "scene_"
const MACRO_NAME_PREFIX = "macro_"
const FORCE_UNIQUE_NAMES_FOR_SCENES_AND_MACROS = true
const REUSED_SCENE_OR_MACRO_NAMES_AUTO_POSTFIX = "_"

const FORCE_UNIQUE_NAMES_FOR_NODES = true
const REUSED_NODE_NAMES_AUTO_POSTFIX = "_"

const NONE_UNIQUE_FILENAME_AUTO_POSTFIX = "_"

const RANDOM_PROJECT_NAME_PREFIX = "untitled_"
const RANDOM_PROJECT_NAME_AFFIX_LENGTH = 3

# Following restricted characters are crucial to easy and correct parsing of resources
# such as variables and character tags
const EXPOSURE_SAFE_NAME_RESTRICTED_CHARS = ["{", "}", ".", ":", ";", "`", "'", '"', " ", "\t", "\n", "\r"]
const EXPOSURE_SAFE_NAME_RESTRICTED_CHARS_REPLACEMENT = "_"
const NODE_TYPES_WITH_DIRECT_EXPOSURES = ["tag_edit", "tag_pass"]
const RESOURCE_NAME_EXPOSURE = {
	"variables": { "PATTERN": "{([.]*[^{|}|\\.|:|;|'|\"|`]*)}", "NAME_GROUP_ID": 1 },
	"characters": { "PATTERN": "{([.]*[^{|}|\\.|:|;|'|\"|`]*)\\.([.]*[^{|}|\\.|:|;|'|\"|`]*)}", "NAME_GROUP_ID": 1 },
}

# Minimap

const CLASSIC_MINIMAP_ENABLED = true
const MINIMAP_PANEL_OPACITY_MODULATION_COLOR_HIDE = Color( 1, 1, 1, 0.5 )
const MINIMAP_PANEL_OPACITY_MODULATION_COLOR_SHOW = Color( 1, 1, 1, 1 )
const MINIMAP_DEFAULT_NODE_DRAWING_COLOR = Color( 0.5, 0.5, 0.5, 0.9 )
const MINIMAP_CROSSHAIR_COLOR = Color(0, 0.5, 1, 0.5)
const MINIMAP_CROSSHAIR_COLOR_OUT_OF_BOUND = Color(1, 0.5, 0, 0.5)
const MINIMAP_CROSSHAIR_WIDTH = 2

# Color Palette

const INFO_COLOR = Color.GREEN_YELLOW
const CAUTION_COLOR = Color.YELLOW
const WARNING_COLOR = Color("ff0bb1") # ~ red
const PEACE_COLOR = Color("0fcbf4") # ~ cyan

# Notifications

const NOTIFICATION_COLOR_BAND_DEFAULT_COLOR = INFO_COLOR

# Console

const CONSOLE_MESSAGE_DEFAULT_COLOR = INFO_COLOR
# ... and modulation color for skipped nodes
const CONSOLE_SKIPPED_NODES_SELF_MODULATION_COLOR_ON = Color.DARK_GRAY
const CONSOLE_SKIPPED_NODES_SELF_MODULATION_COLOR_OFF = Color( 1, 1, 1, 1 )

# Editor

const PROJECT_UNSAVE_INDICATION_COLOR = WARNING_COLOR
const PROJECT_SAVE_INDICATION_COLOR = PEACE_COLOR

const PATH_DIALOG_PROPERTIES = {
	"PROJECT_FILE" : {
		"OPEN" : {
			"title": "Select an Arrow Document",
			"file_mode": FileDialog.FileMode.FILE_MODE_OPEN_FILE,
			"access": FileDialog.ACCESS_FILESYSTEM,
			"filters": ["*.arrow;Arrow Document"]
		},
		"SAVE": {
			"title": "Save Document",
			"file_mode": FileDialog.FileMode.FILE_MODE_SAVE_FILE,
			"access": FileDialog.ACCESS_FILESYSTEM,
			"filters": ["*.arrow;Arrow Document"]
		},
		"EXPORT_JSON": {
			"title": "Export as JSON",
			"file_mode": FileDialog.FileMode.FILE_MODE_SAVE_FILE,
			"access": FileDialog.ACCESS_FILESYSTEM,
			"filters": ["*.json;Purged Arrow Export"]
		},
		"EXPORT_HTML": {
			"title": "Export Playable HTML",
			"file_mode": FileDialog.FileMode.FILE_MODE_SAVE_FILE,
			"access": FileDialog.ACCESS_FILESYSTEM,
			"filters": ["*.html;Playable HTML"]
		},
		"EXPORT_CSV": {
			"title": "Export CSV (Translation)",
			"file_mode": FileDialog.FileMode.FILE_MODE_SAVE_FILE,
			"access": FileDialog.ACCESS_FILESYSTEM,
			"filters": ["*.csv;Translation File"]
		}
	},
	"DIRECTORY" : {
		"LOCAL_APP" : {
			"title": "Select App Local Directory",
			"file_mode": FileDialog.FileMode.FILE_MODE_OPEN_DIR,
			"access": FileDialog.ACCESS_FILESYSTEM,
			"filters": []
		}
	}
}

# Clipboard

# Don't need to change these unless you're developing new features.
const CLIPBOARD_MODE = { "EMPTY":0, "COPY":1, "CUT":2 }
const OS_CLIPBOARD_MERGE_MODE = { "REUSE":0, "RECREATE":1 }

# Runtimes

const HTML_JS_RUNTIME_INDEX = 'res://runtimes/html-js/index.html'
const HTML_JS_SINGLE_FILE_TEMPLATE_PATH = 'res://runtimes/html-js.arrow-runtime'

const PURGE_DEVELOPMENT_DATA_FROM_PLAYABLE = true
const DATA_TO_BE_PURGED_FROM_PLAYABLE_METADATA:Array = [
	'offline', 'remote', 'last_save', # 'editor',
	'authors', # 'chapter',
]
const DATA_TO_BE_PURGED_FROM_PLAYABLE_RESOURCES:Dictionary = {
	"nodes": [ 'notes' ]
}
const INLINED_JSON_DEFAULT_IDENT = "\t" # e.g. `\t` (tab) for readability or empty string ("") for compression

# App UI

const THEMES = {
	0: { "name": "Dark",  "resource": preload("res://assets/themes/dark.tres") },
	1: { "name": "Light",  "resource": preload("res://assets/themes/light.tres") },
}

const UI_TRANSLATIONS_DIR = "res://assets/translations"
