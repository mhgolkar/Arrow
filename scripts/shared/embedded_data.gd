# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Embedded Data
class_name Embedded

const Text = {
	
	"Welcome_Message" : "Welcome, dear Arrow-%s adventurer." % Settings.ARROW_VERSION,

	"Legal_Notes": """
		Arrow is a free and open-source game narrative design tool, developed on top of Godot game engine.
		You own 100%% of what you create with Arrow, no strings attached.
		Please check our website for more information: %s
	""" % Settings.ARROW_WEBSITE,
	
	"Manual": """
		Arrow {ver}

		[ CLI Arguments ]
		
		--manual	Shows this brief manual.
				Check our website {www} for more detailed instructions and tutorials.
				
		--config-dir	Tells Arrow to search for `{cfn}` file in the directory path that follows it.
				Absolute paths and relative `res://` or `user://` paths are valid.
				$ arrow --config-dir '/home/user/.config'
				NOTE: Will create a default config file if it doesn't exist, but won't create the directory.
				
		--work-dir	Tells Arrow to use the directory path that follows it for project management.
				Absolute paths and relative `res://` or `user://` paths are valid.
				$ arrow --work-dir '/home/user/my_arrow_adventures'
				NOTE: Won't create directory if it doesn't exist.
				
		--sandbox	App Runs in sandbox mode with default configurations.
					No `arrow.config` file will be generated automatically if there is no one found.
	"""
}

const Data = {
	
	# Initial content of a new Project List File
	"Blank_Project_List": {
		"projects": {
			# <UID>:int (order of import or creation)
				# {
					# title:string,
					# filename:string (filename or path relative to the app local directory),
					# last_view_offset { <scene-uid>:[x,y] }, (offset of the graph editor (grid) where user has left the scene or macro.)
					# last_open_scene:int<uid>
					# active_author: 0
				# }
		},
		"next_project_seed": 0, # next integer to be used as a listed project UID
		"arrow_editor_version": Settings.ARROW_VERSION
	},
	
	# Blank (New) Project:
	"Untitled_Project": {
		"title": "Untitled Adventure",
		"entry": 1, # resource-id of the project's main (active) entry node
		"meta": {
			# Native distributed incremental (default) UID metas:
			# > For larger projects which are devided into multiple documents,
			# > setting different chapter IDs per sub-project guarantees global uniqueness of resource UIDs.
			# > Up to 512 chapters _represented as 1st 9-bit in each UID_ can exist.
			"chapter": 0, # (0 - 512; Order is optional.)
			# > Arrow uses an incremental seed tracker for each author to guarantee resource UID uniqueness
			# > when multiple users work on the same document simultaneously.
			"authors": {
				# (Up to 64 authors _represented as 2nd 6-bit in each UID_ can work on the same document.)
				0: [Settings.ANONYMOUS_AUTHOR_INFO, 3] # [Author info, and incremental seed for the next UID]
			},
			# ...
			# Time-based distributed UID epoch:
			# > This field is unix time (in microseconds) on creation of the project.
			# > If you set it, you'll get 64-bit timebased distributed IDs inspired by Snowflake-IDs.
			# > This method is not recommended; For most of the projects the default method is a better choice.
			# "epoch": null,
			# ...
			"last_save": null, # `local` and `utc` date-time (ISO 8601) strings
			"arrow_editor_version": Settings.ARROW_VERSION, # for future version compatibility checks.
			# ...
			# Arrow has a vcs-friendly project structure (i.e. unique & never-reused resource-ids, 'json' exports, etc.)
			# so you can easily use your favorite revisioning system, such as git.
			# `offline` and `remote` properties are reserved for possible editor vcs integration in the future.
			"offline": true,
			"remote": {},
		},
		# ...
		# Local incremental (legacy) UID tracker:
		# "next_resource_seed": 3, # if exists in a project, nodes will be identified by an incremental serial.
		# ...
		"resources": {
			"scenes": {
				0: {
					"name": Settings.SCENE_NAME_PREFIX + "0",
					"entry": 1, # the scene's active entry node
					"map": {
						1 : { "offset":[100, 100], "io": [ [1, 0, 2, 0] ] },
						2 : { "offset":[280, 170] },
					}
				},
			},
			"nodes": {
				1: {
					"type": "entry",
					"name": "1",
					"data": { "plaque": "Start" }
				},
				2: {
					"type": "content",
					"name": "2",
					"data": { "title": "Hello World!", "content": "Let's begin our adventure." } 
				},
			},
			"variables": {},
			"characters": {},
		}
	}
}
