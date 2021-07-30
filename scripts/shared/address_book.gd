# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# UI Adress Book
# All the UI nodes and resources paths are listed from the `/root`.
# Other scripts use this file as an address-book to find/get other nodes in the scene tree.
class_name Addressbook

# CAUTION! handle with care: `main_ui_management.gd` and other scripts
# use lowercase panel names in their logic.
const PANELS = {
	"inspector": "/root/Main/FloatToolsLayer/Container/Inspector",
	"preferences": "/root/Main/BlockingLayer/Container/Preferences",
	"new_project_prompt":  "/root/Main/BlockingLayer/Container/NewProjectPrompt",
	"console": "/root/Main/FloatToolsLayer/Container/Console",
	"about": "/root/Main/BlockingLayer/Container/AboutApp",
	"notification": "/root/Main/BlockingLayer/Container/Notification",
}

const BLOCKING_OVERLAY = "/root/Main/BlockingLayer/Container/BlockingOverlay"

const THEME_ADJUSTMENT_LAYERS = [
	"/root/Main",
	"/root/Main/BlockingLayer/Container",
	"/root/Main/FloatToolsLayer/Container"
]

const EDITOR = {
	"itself": "/root/Main/Editor",
	# Top
	"APP_MENU": "/root/Main/Editor/Top/Toolbar/AppControls/AppMenu",
	"PROJECT_TITLE": "/root/Main/Editor/Top/Toolbar/ProjectTitle",
	#	Reserved for possible vcs integration in the future:
	#		"AUTO_LOCAL_SAVE_SWITCH": "/root/Main/Editor/Top/Toolbar/AutoLocalSaveSwitch",
	#		"PROJECT_SAVE_STATUS": "/root/Main/Editor/Top/Toolbar/ProjectSaveStatus",
	"PLAY": {
		"FROM_SELECTED_NODE": "/root/Main/Editor/Top/Toolbar/PlayModes/HBoxContainer/PlayFromSelectedNode",
		"FROM_SCENE_ENTRY": "/root/Main/Editor/Top/Toolbar/PlayModes/HBoxContainer/PlayFromSceneEntry",
		"FROM_PROJECT_ENTRY": "/root/Main/Editor/Top/Toolbar/PlayModes/HBoxContainer/PlayFromProjectEntry",
		"FROM_LEFT_CONSOLE": "/root/Main/Editor/Top/Toolbar/PlayModes/HBoxContainer/PlayFromLeftConsole",
	},
	"QUICK_TOOLS": {
		"SAVE": "/root/Main/Editor/Top/Toolbar/EditQuickTools/HBoxContainer/SaveProject",
		"SAVE_INDICATOR": "/root/Main/Editor/Top/Toolbar/EditQuickTools/HBoxContainer/SaveProject/SaveIndicator",
	},
	# Bottom
	"OPEN_SCENE_TITLE": "/root/Main/Editor/Bottom/BreadCrumb/OpenSceneTitle",
	"QUICK_PREFERENCES_MENU_BUTTON": "/root/Main/Editor/Bottom/QuickSwitches/HBoxContainer/QuickPreferences",
	"INSPECTOR_VIEW_TOGGLE": "/root/Main/Editor/Bottom/QuickSwitches/HBoxContainer/InspectorViewToggle",
}

const PATH_DIALOGUE = "/root/Main/BlockingLayer/Container/PathDialog"

# Preferences Panel

const PREF_PANEL_ACTION_BUTTONS = {
	"dismiss": "/root/Main/BlockingLayer/Container/Preferences/VBoxContainer/HBoxContainer/PreferencesDismiss",
	"confirm": "/root/Main/BlockingLayer/Container/Preferences/VBoxContainer/HBoxContainer/PreferencesConfirm",
}
const PREF_PANEL_FIELDS = {
	# CAUTION! handle with care: same lowercase strings (as the keys here,) are used in signaling and saving modified preferences,
	"ui_scale": "/root/Main/BlockingLayer/Container/Preferences/VBoxContainer/PanelContainer/VBoxContainer/PreferencesUI/VBoxContainer/UIScaleSlider",
	"appearance_theme": "/root/Main/BlockingLayer/Container/Preferences/VBoxContainer/PanelContainer/VBoxContainer/PreferencesAppearance/VBoxContainer/PreferencesThemeOptions",
	#	"appearance_borderless": "/root/Main/BlockingLayer/Container/Preferences/VBoxContainer/PanelContainer/VBoxContainer/PreferencesAppearance/VBoxContainer/PreferencesBorderless",
	"language": "/root/Main/BlockingLayer/Container/Preferences/VBoxContainer/PanelContainer/VBoxContainer/PreferencesLanguage/VBoxContainer/PreferencesLanguageOptions",
	"app_local_dir_path": "/root/Main/BlockingLayer/Container/Preferences/VBoxContainer/PanelContainer/VBoxContainer/PreferencesData/VBoxContainer/HBoxContainer/PreferencesAppDirPath",
	"app_local_dir_browse": "/root/Main/BlockingLayer/Container/Preferences/VBoxContainer/PanelContainer/VBoxContainer/PreferencesData/VBoxContainer/HBoxContainer/PreferencesAppDirPathBrowse",
	"app_local_dir_reset_menu": "/root/Main/BlockingLayer/Container/Preferences/VBoxContainer/PanelContainer/VBoxContainer/PreferencesData/VBoxContainer/HBoxContainer/PreferencesAppDirPathResetMenu",
	"textual_save_data": "/root/Main/BlockingLayer/Container/Preferences/VBoxContainer/PanelContainer/VBoxContainer/PreferencesData/VBoxContainer/TextualSaveData"
}

const ABOUT_PANEL = {
	"itself": "/root/Main/BlockingLayer/Container/AboutApp",
	"VERSION_CODE": "/root/Main/BlockingLayer/Container/AboutApp/VBoxContainer/HBoxContainer/Information/VBoxContainer/Version",
	"OK_BUTTON": "/root/Main/BlockingLayer/Container/AboutApp/VBoxContainer/HBoxContainer/Information/VBoxContainer/Buttons/OK",
	"LINKS": {
		"SOURCE": "/root/Main/BlockingLayer/Container/AboutApp/VBoxContainer/HBoxContainer/Information/VBoxContainer/InfoLinks/VBoxContainer/Source",
		"DOCS": "/root/Main/BlockingLayer/Container/AboutApp/VBoxContainer/HBoxContainer/Information/VBoxContainer/InfoLinks/VBoxContainer/Docs",
		"GODOT": "/root/Main/BlockingLayer/Container/AboutApp/VBoxContainer/HBoxContainer/Information/VBoxContainer/Made/Godot",
	}
}

const NOTIFICATION = {
	"itself": "/root/Main/BlockingLayer/Container/Notification",
	"COLORBAND": "/root/Main/BlockingLayer/Container/Notification/NotificationPanel/HBoxContainer/Colorband",
	"HEADING": "/root/Main/BlockingLayer/Container/Notification/NotificationPanel/HBoxContainer/PanelContainer/VBoxContainer/Heading",
	"MESSAGE": "/root/Main/BlockingLayer/Container/Notification/NotificationPanel/HBoxContainer/PanelContainer/VBoxContainer/Message",
	"DISMISS_BUTTON": "/root/Main/BlockingLayer/Container/Notification/NotificationPanel/HBoxContainer/PanelContainer/VBoxContainer/Buttons/Dismiss",
	"CUSTOM_BUTTONS_HOLDER": "/root/Main/BlockingLayer/Container/Notification/NotificationPanel/HBoxContainer/PanelContainer/VBoxContainer/Buttons/Custom",
}

const INSPECTOR = {
	"itself": "/root/Main/FloatToolsLayer/Container/Inspector",
	"drag_point": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/Titlebar/DragPoint",
	"resize_point": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/Titlebar/ResizePoint",
	"TAB_CONTAINER": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer",
	# Tabs ...
	"PROJECT": {
		"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project",
		"PROJECT_LIST_MODES":{
			"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/ProjectListModes",
			"LOCAL_MODE": {
				"LISTED_PROJECTS_LIST": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/ProjectListModes/LocalMode/LocalProjects/VSplitContainer/ScrollContainer/ListedProjects",
				"SELECTED_PROJECT_DESCRIPTION": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/ProjectListModes/LocalMode/LocalProjects/VSplitContainer/ProjectDescription",
				"TOOLS": {
					"NEW_MENU_BUTTON" : "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/ProjectListModes/LocalMode/LocalProjects/LocalProjectsActions/NewLocalProjectMenu",
					"REMOVE_LOCAL_PROJECT_BUTTON" : "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/ProjectListModes/LocalMode/LocalProjects/LocalProjectsActions/RemoveLocalProject",
					"OPEN_LOCAL_PROJECT_BUTTON" : "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/ProjectListModes/LocalMode/LocalProjects/LocalProjectsActions/OpenLocalProject",
				}
			},
		},
		"LOCAL_PROJECT_PROPERTIES": {
			"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/LocalProjectProperties",
			"TITLE_CONFIGURATION": {
				"TITLE_EDIT": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/LocalProjectProperties/LocalProjectConfigTitle/Title",
				"SET_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/LocalProjectProperties/LocalProjectConfigTitle/Set"
			},
			"RTL_CONFIGURATION_CHECKBOX": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/LocalProjectProperties/HBoxContainer/LocalProjectConfigRTL",
			"CLOSE": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/LocalProjectProperties/HBoxContainer/LocalProjectClose",
			"MORE_TOOLS_MENU_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/LocalProjectProperties/HBoxContainer/LocalProjectMoreTools",
			"VERSIONING": {
				"LAST_SAVE": {
					"TIME_STAMP": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/LocalProjectProperties/DraftManagement/VBoxContainer/LastSave/Timestamp",
					"REVERT_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/LocalProjectProperties/DraftManagement/VBoxContainer/LastSave/Revert",
				},
				"SNAPSHOTS_LIST": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/LocalProjectProperties/DraftManagement/VBoxContainer/ScrollContainer/SnapshotsList",
				"SNAPSHOT_TOOLS": {
					"RESTORE_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/LocalProjectProperties/DraftManagement/VBoxContainer/SnapshotTools/Restore",
					"TAKE_NEW_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/LocalProjectProperties/DraftManagement/VBoxContainer/SnapshotTools/Take",
					"PREVIEW_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/LocalProjectProperties/DraftManagement/VBoxContainer/SnapshotTools/Preview",
					"REMOVE_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Project/LocalProjectProperties/DraftManagement/VBoxContainer/SnapshotTools/Remove",
				}
			}
		}
	},
	"NODE": {
		"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Node",
		"SUB_INSPECTOR_BLOCKER_MESSAGE": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Node/SubInspectorBlockMessage",
		"PROPERTIES": {
			"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Node/Properties",
			"NODE_TYPE_LABEL": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Node/Properties/NodeTypeLabel",
			"NODE_UID_EDIT": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Node/Properties/NodeUID/Edit",
			"NODE_IS_SKIPPED_CHECK": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Node/Properties/NodeState/NodeIsSkipped",
			"NODE_REFERRERS_MENU_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Node/Properties/NodeState/NodeReferrers",
			"SUB_INSPECTOR_HOLDER": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Node/Properties/VSplitContainer/SubInspectorHolder",
			"NODE_NOTES_EDIT": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Node/Properties/VSplitContainer/NodeNotes/Edit",
			"FOCUS_NODE_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Node/Properties/NodeState/ShowFocusNode",
			"NODE_TOOLS": {
				"RESET_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Node/Properties/NodeTools/HBoxContainer/ResetNodeParams",
				"HISTORY_BACK": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Node/Properties/NodeTools/HBoxContainer/NodeHistoryBack",
				"HISTORY_FORE": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Node/Properties/NodeTools/HBoxContainer/NodeHistoryFore",
				"UPDATE_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Node/Properties/NodeTools/HBoxContainer/UpdateNode",
			},
		},
	},
	"SCENES":{
		"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Scenes",
		"SCENES_LIST": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Scenes/VBoxContainer/VSplitContainer/ScrollContainer/ScenesList",
		"SCENE_ENTRY_NOTES": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Scenes/VBoxContainer/VSplitContainer/SceneEntryNote",
		"TOOLS":{
			"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Scenes/VBoxContainer/SceneActions",
			"NEW_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Scenes/VBoxContainer/SceneActions/HBoxContainer/NewScene",
			"REMOVE_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Scenes/VBoxContainer/SceneActions/HBoxContainer/RemoveScene",
			"EDIT_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Scenes/VBoxContainer/SceneActions/HBoxContainer/OpenSceneToEdit",
		},
		"EDIT":{
			"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Scenes/VBoxContainer/OpenSceneConfigs",
			"NAME_EDIT": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Scenes/VBoxContainer/OpenSceneConfigs/VBoxContainer/SceneName/Edit",
			"UPDATE_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Scenes/VBoxContainer/OpenSceneConfigs/VBoxContainer/SceneName/Set",
		},
	},
	"MACROS":{
		"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Macros",
		"MACROS_LIST": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Macros/VBoxContainer/VSplitContainer/ScrollContainer/MacrosList",
		"MACRO_ENTRY_NOTE": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Macros/VBoxContainer/VSplitContainer/MacroEntryNote",
		"EDIT":{
			"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Macros/VBoxContainer/OpenMacroConfigs",
			"NAME_EDIT": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Macros/VBoxContainer/OpenMacroConfigs/VBoxContainer/MacroName/Edit",
			"UPDATE_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Macros/VBoxContainer/OpenMacroConfigs/VBoxContainer/MacroName/Set",
			"CLOSE_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Macros/VBoxContainer/OpenMacroConfigs/VBoxContainer/CloseMacro",
		},
		"TOOLS":{
			"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Macros/VBoxContainer/MacroTools",
			"NEW_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Macros/VBoxContainer/MacroTools/HBoxContainer/NewMacro",
			"REMOVE_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Macros/VBoxContainer/MacroTools/HBoxContainer/RemoveMacro",
			"EDIT_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Macros/VBoxContainer/MacroTools/HBoxContainer/OpenMacroToEdit",
		},
		"MACRO_INSTANCES":{
			"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Macros/VBoxContainer/MacroInstances",
			"INDICATION": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Macros/VBoxContainer/MacroInstances/MacroInstancesPagination/Indication",
			"GO_TO_MENU_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Macros/VBoxContainer/MacroInstances/MacroInstancesPagination/GoToInstance",
		}
	},
	"VARIABLES": {
		"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Variables",
		"TYPE_SELECT": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Variables/VBoxContainer/PanelContainer/HBoxContainer/TypeSelect",
		"NEW_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Variables/VBoxContainer/PanelContainer/HBoxContainer/NewButton",
		"VARIABLES_LIST": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Variables/VBoxContainer/ScrollContainer/VariablesList",
		"VARIABLE_EDITOR":{
			"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Variables/VBoxContainer/VariableEditor",
			"VARIABLE_USAGES":{
				"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Variables/VBoxContainer/VariableEditor/VBoxContainer/VariableUsages",
				"INDICATION": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Variables/VBoxContainer/VariableEditor/VBoxContainer/VariableUsages/VariableUsagesPagination/Indication",
				"GO_TO_MENU_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Variables/VBoxContainer/VariableEditor/VBoxContainer/VariableUsages/VariableUsagesPagination/GoToUsage",
			},
			"NAME_EDIT": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Variables/VBoxContainer/VariableEditor/VBoxContainer/HBoxContainer/VariablesNameEdit",
			"INITIAL_VALUE_EDITS":{
				"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Variables/VBoxContainer/VariableEditor/VBoxContainer/VariableInitial/VariableInitialValue",
				"str": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Variables/VBoxContainer/VariableEditor/VBoxContainer/VariableInitial/VariableInitialValue/String",
				"num": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Variables/VBoxContainer/VariableEditor/VBoxContainer/VariableInitial/VariableInitialValue/Number",
				"bool": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Variables/VBoxContainer/VariableEditor/VBoxContainer/VariableInitial/VariableInitialValue/Boolean",
			},
			"SAVE_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Variables/VBoxContainer/VariableEditor/VBoxContainer/HBoxContainer2/SaveVariable",
			"REMOVE_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Variables/VBoxContainer/VariableEditor/VBoxContainer/HBoxContainer2/RemoveVariable",
		},
	},
	"CHARACTERS":{
		"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Characters",
		"CHARACTERS_LIST": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Characters/VBoxContainer/ScrollContainer/CharactersList",
		"NEW_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Characters/VBoxContainer/CharacterCreate/HBoxContainer/NewCharacter",
		"REMOVE_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Characters/VBoxContainer/CharacterCreate/HBoxContainer/RemoveCharacter",
		"CHARACTER_EDITOR": {
			"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Characters/VBoxContainer/CharacterEditor",
			"COLOR_PICKER_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Characters/VBoxContainer/CharacterEditor/VBoxContainer/HBoxContainer/CharacterColor",
			"NAME_EDIT": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Characters/VBoxContainer/CharacterEditor/VBoxContainer/HBoxContainer/CharacterNameEdit",
			"SAVE_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Characters/VBoxContainer/CharacterEditor/VBoxContainer/HBoxContainer/SaveCharacter",
		},
		"CHARACTER_APPEARANCE":{
			"itself": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Characters/VBoxContainer/CharacterEditor/VBoxContainer/CharacterAppearance",
			"INDICATION": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Characters/VBoxContainer/CharacterEditor/VBoxContainer/CharacterAppearance/CharacterAppearancePagination/Indication",
			"GO_TO_MENU_BUTTON": "/root/Main/FloatToolsLayer/Container/Inspector/VBoxContainer/TabContainer/Characters/VBoxContainer/CharacterEditor/VBoxContainer/CharacterAppearance/CharacterAppearancePagination/GoToAppearance",
		}
	}
}

const GRID = "/root/Main/Editor/Center/GridGraphEdit"

const GRID_CONTEXT_MENU = {
	"itself": "/root/Main/FloatToolsLayer/Container/GridContextMenu",
	"NODE_INSERT_LIST": "/root/Main/FloatToolsLayer/Container/GridContextMenu/VBoxContainer/NodeInsert/VBoxContainer/ScrollContainer/NodeInsertList",
	"NODE_INSERT_FILTER_FORM": "/root/Main/FloatToolsLayer/Container/GridContextMenu/VBoxContainer/NodeInsert/VBoxContainer/HBoxContainer/",
	"NODE_INSERT_FILTER_INPUT": "/root/Main/FloatToolsLayer/Container/GridContextMenu/VBoxContainer/NodeInsert/VBoxContainer/HBoxContainer/NodeInsertFilterInput",
	"INSERT_BUTTON": "/root/Main/FloatToolsLayer/Container/GridContextMenu/VBoxContainer/NodeInsert/VBoxContainer/HBoxContainer/Insert",
	"EDIT_TOOLS_BOX": "/root/Main/FloatToolsLayer/Container/GridContextMenu/VBoxContainer/EditTools",
	"CLEAN_CLIPBOARD_BUTTON": "/root/Main/FloatToolsLayer/Container/GridContextMenu/VBoxContainer/EditTools/CleanClipboard",
	"COPY_BUTTON": "/root/Main/FloatToolsLayer/Container/GridContextMenu/VBoxContainer/EditTools/Copy",
	"CUT_BUTTON": "/root/Main/FloatToolsLayer/Container/GridContextMenu/VBoxContainer/EditTools/Cut",
	"PASTE_BUTTON": "/root/Main/FloatToolsLayer/Container/GridContextMenu/VBoxContainer/EditTools/Paste",
	"REMOVE_BUTTON": "/root/Main/FloatToolsLayer/Container/GridContextMenu/VBoxContainer/EditTools/Remove",
}

const MINIMAP = "/root/Main/Editor/Center/MinimapBox/Minimap"

const QUERY = {
	"itself": "/root/Main/Editor/Bottom/QueryPanel",
	"QUERY_INPUT": "/root/Main/Editor/Bottom/QueryPanel/HBoxContainer/QueryInput",
	"SEARCH_BUTTON": "/root/Main/Editor/Bottom/QueryPanel/HBoxContainer/Search",
	"HOW_OPTIONS": "/root/Main/Editor/Bottom/QueryPanel/HBoxContainer/How",
	"PROJECT_WIDE": "/root/Main/Editor/Bottom/QueryPanel/HBoxContainer/ProjectWide",
	"PREVIOUS_BUTTON": "/root/Main/Editor/Bottom/QueryPanel/HBoxContainer/PreviousMatch",
	"MATCHES_OPTION_BUTTON": "/root/Main/Editor/Bottom/QueryPanel/HBoxContainer/Matches",
	"NEXT_BUTTON": "/root/Main/Editor/Bottom/QueryPanel/HBoxContainer/NextMatch",
}

const NEW_PROJECT_PROMPT_PANEL = {
	"itself": "/root/Main/BlockingLayer/Container/NewProjectPrompt",
	"FIELDS":{
		"TITLE": "/root/Main/BlockingLayer/Container/NewProjectPrompt/VBoxContainer/TitleContainer/ProjectTitle",
		"FILENAME": "/root/Main/BlockingLayer/Container/NewProjectPrompt/VBoxContainer/FilenameContainer/FileName",
		"FINAL_PATH": "/root/Main/BlockingLayer/Container/NewProjectPrompt/VBoxContainer/FinalPathContainer/FinalPath"
	},
	"RENAME_WARN": "/root/Main/BlockingLayer/Container/NewProjectPrompt/VBoxContainer/ProjectRenameWarn",
	"CREATE_BUTTON": "/root/Main/BlockingLayer/Container/NewProjectPrompt/VBoxContainer/Buttons/Create",
	"DISMISS_BUTTON": "/root/Main/BlockingLayer/Container/NewProjectPrompt/VBoxContainer/Buttons/Dismiss"
}

const CONSOLE = {
	"itself": "/root/Main/FloatToolsLayer/Container/Console",
	"drag_point": "/root/Main/FloatToolsLayer/Container/Console/VBoxContainer/Titlebar/DragPoint",
	"resize_point": "/root/Main/FloatToolsLayer/Container/Console/VBoxContainer/Titlebar/ResizePoint",
	"TERMINAL_SCROLL_CONTAINER": "/root/Main/FloatToolsLayer/Container/Console/VBoxContainer/PanelContainer/VBoxContainer/PanelContainer/ScrollContainer",
	"TERMINAL": "/root/Main/FloatToolsLayer/Container/Console/VBoxContainer/PanelContainer/VBoxContainer/PanelContainer/ScrollContainer/ConsoleTerminal",
	"CLOSE": "/root/Main/FloatToolsLayer/Container/Console/VBoxContainer/Toolbar/Close",
	"CLEAR": "/root/Main/FloatToolsLayer/Container/Console/VBoxContainer/Toolbar/Clear",
	"BACK": "/root/Main/FloatToolsLayer/Container/Console/VBoxContainer/Toolbar/PlayStepBack",
	"SETTINGS": "/root/Main/FloatToolsLayer/Container/Console/VBoxContainer/Toolbar/ConsoleSettings",
	"VARIABLE_INSPECTOR": {
		"itself": "/root/Main/FloatToolsLayer/Container/Console/VBoxContainer/PanelContainer/VBoxContainer/VariableCurrentValueInspector",
		"VARIABLE_SELECT": "/root/Main/FloatToolsLayer/Container/Console/VBoxContainer/PanelContainer/VBoxContainer/VariableCurrentValueInspector/VBoxContainer/Variables",
		"VALUE_EDITS": {
			"itself": "/root/Main/FloatToolsLayer/Container/Console/VBoxContainer/PanelContainer/VBoxContainer/VariableCurrentValueInspector/VBoxContainer/HBoxContainer",
			"str": "/root/Main/FloatToolsLayer/Container/Console/VBoxContainer/PanelContainer/VBoxContainer/VariableCurrentValueInspector/VBoxContainer/HBoxContainer/CurrentValue/String",
			"num": "/root/Main/FloatToolsLayer/Container/Console/VBoxContainer/PanelContainer/VBoxContainer/VariableCurrentValueInspector/VBoxContainer/HBoxContainer/CurrentValue/Number",
			"bool": "/root/Main/FloatToolsLayer/Container/Console/VBoxContainer/PanelContainer/VBoxContainer/VariableCurrentValueInspector/VBoxContainer/HBoxContainer/CurrentValue/Boolean",
		},
		"UPDATE_BUTTON": "/root/Main/FloatToolsLayer/Container/Console/VBoxContainer/PanelContainer/VBoxContainer/VariableCurrentValueInspector/VBoxContainer/HBoxContainer/UpdateCurrentValue",
	},
}
