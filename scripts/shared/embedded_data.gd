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
					# last_view { <scene-uid>: [x,y, zoom] }, (offset and zoom where user has left, per scene)
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
		"entry": 1, # Resource-UID of the project's main (active) entry node
		"meta": {
			# Native (default) distributed UID metadata:
			# > For larger projects which are divided into multiple documents,
			# > setting different chapter IDs per sub-project guarantees global uniqueness of resource UIDs.
			# > Up to 1024 chapters _represented as the 1st 9 bits in each UID_ can exist.
			"chapter": 0, # (0 - 1024; Order is optional.)
			# > Arrow uses an incremental seed tracker for each author to guarantee resource UID uniqueness
			# > when multiple users work on the same document at the same time.
			"authors": {
				# (Up to 64 authors _represented as the next 6 bits in each UID_ can contribute simultaneously.)
				0: [Settings.ANONYMOUS_AUTHOR_INFO, 3] # [Author info, and incremental seed for the next UID]
			},
			# ...
			# Time-based distributed UID epoch:
			# > This field is unix time (UTC in microseconds) on creation of the project.
			# > If you set it, you'll get 64-bit time-based distributed IDs inspired by Snowflake-IDs.
			# > This method is not recommended; For most of the projects the default method is a better choice.
			# "epoch": <int>,
			# ...
			"last_save": null, # UTC date-time (ISO 8601) string
			"editor": Settings.ARROW_VERSION, # for version compatibility checks.
			# ...
			# Arrow has a vcs-friendly project structure (i.e. unique & never-reused resource-ids, JSON exports, etc.)
			# so you can easily use your favorite revision system, such as Git.
			# `offline` and `remote` properties are reserved for possible editor vcs integration in the future.
			"offline": true,
			"remote": {},
		},
		# ...
		# Local incremental UID tracker (deprecated):
		# > If exists, we move this global seed to the author `0` on chapter `0` for backward compatibility.
		# "next_resource_seed": <int>,
		# ...
		"resources": {
			"scenes": {
				0: {
					"name": Settings.SCENE_NAME_PREFIX + "0",
					"entry": 1, # The scene's active entry node
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
