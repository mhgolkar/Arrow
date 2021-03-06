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
			# Arrow has a revision-friendly project structure (i.e. unique & never-reused resource-ids, 'json' exports, etc.)
			# so you can easily use your favorite revisioning system, such as git.
			# `offline` and `remote` properties are reserved for possible vcs integration in the future.
			"offline": true,
			"remote": {},
			"rtl": false, # right-to-left (i18n)
			"last_save": null, # <time objects> { utc: OS.get_time(true), local: OS.get_time(false) }
			"arrow_editor_version": Settings.ARROW_VERSION, # for future version compatibility checks.
		},
		"next_resource_seed": 3, # to have the next available resource UID ready
		"resources": {
			"scenes": {
				0: {
					"name": "Adventure Begins",
					"entry": 1, # the scene's active entry node
					"map": {
						1 : { "offset":[100, 100], "io": [ [1, 0, 2, 0] ] },
						2 : { "offset":[280, 170] },
					}
				},
			},
			"nodes": {
				1: { "type": "entry", "name":"S0N0Ent", "data": { "plaque": "Start" }, "notes": "The initial Entry point" },
				2: { "type": "content", "name":"S0N1Cnt", "data": { "title": "Hello World!", "content": "I'm the very first step to a great adventure.", "clear": true }  },
			},
			"variables": {},
			"characters": {},
		}
	}
	# Project Data Structure
		#
		# Projects are made of resources, each identified with a unique integer id (UID).
		# Resources are of the types:
		#       scenes, macros, nodes, variables & characters.
		# All the resources are sorted by type and UDI under `resources` tree:
		#	{
		#       scenes & macros : { <uid>: { name:string<display-name>, entry:int<entry-node-uid> map:{ <child-node-uid>:int { offset:[x,y], skip:bool'optional, io:[ [<from_uid>int, <from_slot>int, <to_uid>int, <to_slot>int], ...] ], macro:bool'optional }, ... ] }
		#       nodes : { <uid>:int { type:string, name:string<display-name>, skip: bool'optional, data: { <depends-on-node-type> }, notes:string'optional }, ... }
		#       characters : { <uid>:int { name:string<display-name>, color:string<emphasis-color-code> }, ... }
		#       variables : { <uid>:int { type:string<num, str, bool>, name:<display-name>, init:variant<initial-value> }, ...}
		#	}
		# There can be an optional `use` array for each resource, indicating which other resources rely on this one.
		# `ref` property complements `use` by listing all the used resources for any dependent resource.
		# `use` and `ref` are implemented to safeguard continuities during operations such as node removals.
		#
		# Notes:
		#       At least one scene and one entry-node shall exist in every valid project, so the editor/interpreter knows where to start.
		#       UIDs are set by Arrow and shall not be edited (unless you really know what you're doing)
		#       Projects shall be JSON-COMPATIBLE, so data types such as Color or Vector2 must be converted (e.g. Vector2(x,y) <-> [x,y])
		#		Generally, only one side of each graph connection (between nodes on the grid,) needs to keep the `io` data.
		#		Macros are scenes with `macro = true` property, which enjoy special tretments by the editor and runtimes.
}
