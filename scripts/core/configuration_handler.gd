# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Configuration Handler
class_name Configuration

const CONFIG_FILE_NAME = Settings.CONFIG_FILE_NAME
const CONFIG_FILES_SUB_PATH_DIR_PRIORITY = Settings.CONFIG_FILES_SUB_PATH_DIR_PRIORITY

class ConfigHandler :
	
	var Main

	# base directory path to the config file being used
	# Note: it's NOT necessarily the same as `_ALDP` (app local/work directory path)
	# `--config-dir <path>` cli argument overrides this variable
	var _CONFIG_FILE_BASE_DIR = null
	
	func _init(main) -> void:
		Main = main
		# For HTML5 exports, we need to override the configuration base to the only writable path:
		if Html5Helpers.Utils.is_browser():
			_CONFIG_FILE_BASE_DIR = "user://"
		pass
	
	# default configurations
	# CAUTION! this is the CONSTANT default configuration, used in config file generation, resets, etc.
	const DEFAULT = {
		"appearance_theme": 0,
		"language": "en",
		"app_local_dir_path": "user://", # (IMPORTANT: Only `user://` works in `HTML5` exports)
		"window": null,
		"panels": null,
		"history_size": 0,
	}
	# active configurations
	var TEMPORARY = {} # middle/preview state (active but not confirmed yet)
	var CONFIRMED = {} # in-memory state of changes made, confirmed by the user and saved to the config file
	
	func emulate_preference_modification_and_save(field:String, new_value) -> void :
		_on_preference_modified(field, new_value)
		_on_preference_modifications_done(true)
		# we also need to update the fields in the preferences panel, because they're not modified by the user before we get here
		Main.UI.PANELS.preferences.call_deferred("refresh_fields_view", CONFIRMED)
		pass
	
	func _on_preference_modified(field:String, new_value) -> void:
		# check for validity of the modification
		var is_valid_and_ok = true
		var end_user_error:Dictionary = {}
		var error = "Preference Modification Failed! "
		if field in DEFAULT:
			print_debug("Preference Modification > ", field, " : ", new_value)
			# precautions:
			match field:
				"app_local_dir_path":
					# app local dir should end with "/"
					new_value = Helpers.Utils.normalize_dir_path(new_value)
					# ... and 'WR' access shall be granted,
					is_valid_and_ok = Helpers.Utils.is_access_granted_to_dir(new_value, FileAccess.WRITE_READ)
					if is_valid_and_ok == false: # otherwise ...
						error += "Write & Read Access to App Local Directory Denied!"
						# ... we need to reset preferences panel,
						Main.UI.PANELS.preferences.call_deferred("refresh_fields_view", {
							"app_local_dir_path" : CONFIRMED.app_local_dir_path
						})
						# and give user a heads up!
						end_user_error = {
							"heading": "NO_ALD_ACCESS",
							"message": "UNABLE_TO_ACCESS_ALD_MSG",
						}
				"language":
					Main.UI.PANELS.preferences.reset_language(new_value)
		else:
			is_valid_and_ok = false
			printerr("Unexpected Behavior! Modified Preference Field is NOT a VALID CONFIG: ", field)
		# temporarily update UI ...
		if is_valid_and_ok == true:
			TEMPORARY[field] = new_value
			# it'll be reset or saved later `_on_preference_modifications_done`
			Main.UI.update_view_from_configuration({ field: new_value })
		elif end_user_error.has_all(["heading", "message"]):
			Main.Mind.show_error( end_user_error.heading, end_user_error.message, Settings.CAUTION_COLOR )
		else:
			printerr(error)
		pass
		
	func _on_preference_modifications_done(confirmed_by_user:bool) -> void:
		print_debug("Preference Modification ", ("Confirmed." if confirmed_by_user else "Dismissed!"))
		if confirmed_by_user:
			# warning-ignore:return_value_discarded
			save_configurations_and_confirm(TEMPORARY, null, false)
		Main.UI.set_panel_visibility("preferences", false)
		# saved as config file or not, confirmation has happened, so there are actions to be taken anyway:
		# update/reset the view (& theme) changes
		Main.UI.update_view_from_configuration(CONFIRMED)
		if confirmed_by_user == true:
			# with a change in local app dir
			if TEMPORARY.has("app_local_dir_path"):
				# ... (re-)hold the local app/work dir
				Main.call_deferred("dynamically_update_local_app_dir", CONFIRMED.app_local_dir_path)
		# and finally clean up temporary changes
		TEMPORARY = {}
		pass
		
	# looking up for `CONFIG_FILE_NAME` in directories of `CONFIG_FILES_SUB_PATH_DIR_PRIORITY`
	# and loading configurations from it, or making one in the path of least priority
	func load_configurations() -> void:
		var use_customized_path:bool = false
		var generate_config_file:bool = false
		var config_file_path = null
		var loaded_configs_from_file = {}
		# 1. try using a custom path from cli ...
		if _CONFIG_FILE_BASE_DIR != null:
			config_file_path = (_CONFIG_FILE_BASE_DIR + CONFIG_FILE_NAME)
			if FileAccess.file_exists( config_file_path ) :
				use_customized_path = true
			else:
				config_file_path = null
				if Helpers.Utils.is_access_granted_to_dir(_CONFIG_FILE_BASE_DIR, FileAccess.WRITE_READ):
					generate_config_file = true
					use_customized_path = true
				else:
					printerr("Arrow doesn't have access to annotated config path! CLI argument ignored.")
					_CONFIG_FILE_BASE_DIR = null
					use_customized_path = false
		# 2. try default paths
		if use_customized_path == false :
			for priority in range(0, CONFIG_FILES_SUB_PATH_DIR_PRIORITY.size()):
				var possible_config_path_base_dir = CONFIG_FILES_SUB_PATH_DIR_PRIORITY[priority]
				var possible_config_file_path = (possible_config_path_base_dir + CONFIG_FILE_NAME)
				if FileAccess.file_exists( possible_config_file_path ) :
					print_debug("Configuration File Found: ", possible_config_file_path)
					config_file_path = possible_config_file_path
					_CONFIG_FILE_BASE_DIR = possible_config_path_base_dir
					break
		if config_file_path != null && generate_config_file == false:
			var file_handle = FileAccess.open(config_file_path, FileAccess.READ)
			if file_handle != null:
				# DEV:
				# Older versions of Arrow store configs using Godot binary variant serialization,
				# we now go with a textual representation, making manually editing the file easier.
				# loaded_configs_from_file = file_handle.get_var(true)
				var config_var_str = file_handle.get_as_text()
				file_handle.close()
				loaded_configs_from_file = str_to_var(config_var_str)
			else:
				print_debug("Unable to Read `.arrow.config` File! Access Denied! Detected Path: ", config_file_path)
		else:
			print_debug("No `.arrow.config` File is Found! We'll Use Default Preferences ...")
			if Main._SANDBOX != true:
				generate_config_file = true
				print_debug("... and Try to Auto Generate a Config File.")
			else:
				print_debug("... and auto generating config file is Ignored due to Sandbox mode being ON.")
		# finally load from file or use defaults
		print_debug("Loading Configurations...")
		# check if the loaded data seems valid (at least a dictionary not a corrupted file)
		if (loaded_configs_from_file is Dictionary) != true:
			loaded_configs_from_file = {}
			printerr("Invalid Config File Format! The file ignored due to possible corruption: ", config_file_path, " [ Reset to Default Preferences ]")
		# default for unset configs
		for pref in DEFAULT:
			if pref in loaded_configs_from_file:
				CONFIRMED[pref] = loaded_configs_from_file[pref]
			else:
				CONFIRMED[pref] = DEFAULT[pref]
		# generate a file if necessary
		if generate_config_file != false:
			if Main._SANDBOX == false :
				var saved = false
				if config_file_path != null :
					saved = save_configurations_and_confirm(CONFIRMED, config_file_path, true)
				if _CONFIG_FILE_BASE_DIR != null:
					saved = save_configurations_and_confirm(CONFIRMED, _CONFIG_FILE_BASE_DIR, true)
				var least_priority = CONFIG_FILES_SUB_PATH_DIR_PRIORITY.size() - 1
				while saved == false && least_priority >= 0 :
					_CONFIG_FILE_BASE_DIR = CONFIG_FILES_SUB_PATH_DIR_PRIORITY[least_priority]
					saved = save_configurations_and_confirm(CONFIRMED, _CONFIG_FILE_BASE_DIR, true)
					least_priority -= 1
				if saved == false:
					printerr("Unexpected Behavior! It seems that app has no write access to any of `res://` or `user://` directories to save a config file!")
		# finally, a double check and report
		if _CONFIG_FILE_BASE_DIR == null :
			printerr("Unexpected Behavior! We don't have any _CONFIG_FILE_BASE_DIR! ", ("It's not harmful in Sandbox mode but weird anyway!" if Main._SANDBOX else ""))
		elif Main._SANDBOX != true:
			print_debug("Config File Path Currently used: ", _CONFIG_FILE_BASE_DIR)
		pass

	func save_configurations_and_confirm(configuration:Dictionary, custom_base_dir, confirmed_already_updated:bool) -> bool:
		var final_configuration = {}
		# first make sure what we're going to save are valid configuration pairs
		if confirmed_already_updated != true :
			for pref in DEFAULT:
				# ... then fill up with priority
				if pref in configuration:
					final_configuration[pref] = configuration[pref]
				elif pref in CONFIRMED:
					final_configuration[pref] = CONFIRMED[pref]
				else:
					final_configuration[pref] = DEFAULT[pref]
		else:
			final_configuration = CONFIRMED
		# now save it ...
		if Main._SANDBOX != true :
			var the_saving_path_base = Helpers.Utils.safe_base_dir(custom_base_dir)
			if the_saving_path_base == null:
				the_saving_path_base = _CONFIG_FILE_BASE_DIR
			var config_file_path = (the_saving_path_base + CONFIG_FILE_NAME)
			var config_file_handle = FileAccess.open( config_file_path, FileAccess.WRITE )
			if config_file_handle != null:
				# DEV:
				# Older versions of Arrow store configs using Godot binary variant serialization,
				# we now go with a textual representation, making manually editing the file easier.
				# config_file_handle.store_var(final_configuration, true)
				var config_var_str = var_to_str(final_configuration)
				config_file_handle.store_string(config_var_str)
				# ...
				config_file_handle.close()
				# finally if every thing is gone right, update the in-memory state of confirmed configs too
				CONFIRMED = final_configuration
				print_debug("Config File Saved: ", config_file_path)
				return true
			else:
				printerr("Unable to Write `.arrow.config` File! Access Denied! ", config_file_path)
				return false
		else:
			print_debug("CAUTION! App is running in Sandbox mode; Configurations are NOT SAVED.")
			# update confirmed preferences anyway
			CONFIRMED = final_configuration
			return false
