# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Generator Node Type Shared Class
# (a set of constants and functions used by different scripts of Generator node type)
class_name GeneratorSharedClass

const METHODS = {
	# CAUTION! this list shall correspond to the `generate_...` functions
	"randi": "Random Integer",
	"ascii": "Random ASCII String",
	"strst": "From Set of Strings",
	"rnbln": "Random Boolean",
}

const VALID_METHODS_FOR_TYPE = {
	"num" : [ "randi" ],
	"str" : [ "ascii", "strst" ],
	"bool": [ "rnbln" ]
}

const STRING_SET_DELIMITER = "|"
const DEFAULT_CHARACTER_POOL = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz123456789"

class generator :
	
	const KEYS_NEEDED_TO_PARSE = ["variable", "method"]
	
	var Mind
	
	# Let's use the Arrow's generator helpers as much as possible
	var Generators = Helpers.Generators
	
	func _init(mind) -> void:
		Mind = mind
		pass
	
	# returns the new value on successful evaluation, otherwise `null`
	func generate(node_data:Dictionary, variables_current:Dictionary):
		var result = null
		if node_data.has_all(KEYS_NEEDED_TO_PARSE) && (node_data.variable is int) && (node_data.variable >= 0):
			var target_var = Mind.lookup_resource(node_data.variable, "variables")
			if target_var is Dictionary && target_var.has("type"):
				if (
					VALID_METHODS_FOR_TYPE.has(target_var.type) &&
					METHODS.has(node_data.method)
				):
					# var target_var_value = variables_current[data.variable_var].value
					result = call(
						("generate_%s" % node_data.method),
						( node_data.arguments if node_data.has("arguments") else null)
					)
		return result
	
	func generate_randi(arguments) -> int:
		var result = null
		if arguments is Array && arguments.size() == 5:
			if (
				arguments[0] is int && arguments[0] >= 0 &&
				arguments[1] is int && arguments[1] >= 1
			):
				result = Generators.advance_random_integer(
					arguments[0], arguments[1], # from, to,
					arguments[2], # negative,
					arguments[3], arguments[4] #  even, odd 
				)
			else:
				print_debug("Unexpected Behavior! Bad range for `randi` generator: ", arguments )
		else:
			print_debug("Unexpected Behavior! Wrong number of arguments for `randi` generator: ", arguments )
		if result == null:
			result = (randi() % 100) + 1 # so returns even on corrupt arguments
		return result

	func generate_ascii(arguments) -> String:
		var result = ""
		if arguments.size() == 2:
			var char_pool = (arguments[0] if (arguments[0] is String && arguments[0].length() > 0) else DEFAULT_CHARACTER_POOL)
			var pool_size = char_pool.length()
			var desired_length = (arguments[1] if arguments[1] is int && arguments[1] > 0 else pool_size)
			while result.length() < desired_length:
				result = ( result + char_pool.substr( (randi() % pool_size), 1) )
		return result

	func generate_strst(stringified_set) -> String:
		var result = ""
		if stringified_set is String && stringified_set.length() > 0:
			var string_set = stringified_set.split(STRING_SET_DELIMITER, false)
			if string_set.size() > 0 :
				result = string_set[ randi() % string_set.size() ]
		return result

	func generate_rnbln(_null) -> bool:
		return Generators.random_boolean()
	
