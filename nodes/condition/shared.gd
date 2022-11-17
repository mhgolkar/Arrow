# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Condition Node Type Shared Class
# (shared functionalities and constants)
class_name ConditionSharedClass

# Note:
# (convention)
# length comparisons can get a str(int) as `with` value or a str(string)
# in the first case the stringified integer will be parsed as the length of the right-hand-side,
# and in the latter case, the `.length()` of the string will be used in the comparison.

const PARAMETER_MODES_ENUM = {
	0: "value",
	1: "variable"
}
const PARAMETER_MODES_ENUM_CODE = {
	"value": 0,
	"variable": 1
}

const COMPARISON_OPERATORS = {
	# CAUTION! this list shall correspond to the `evaluate_...` functions
	"num": {
		"eq": { "text": "is Equal", "sign": "==" },
		"nq": { "text": "is Not Equal", "sign": "!=" },
		"gt": { "text": "is Greater", "sign": ">" },
		"gte": { "text": "is Greater or Equal", "sign": ">=" },
		"ls": { "text": "is Lesser", "sign": "<" },
		"lse": { "text": "is Lesser or Equal", "sign": "<=" },
	},
	"str": {
		"rgx":{ "text": "Matches RegEx Pattern", "sign": "~=" },
		"ct":{ "text": "Contains Substring", "sign": "%~" },
		"cts":{ "text": "Contains Substring (Case-Sensitive)", "sign": "%=" },
		"bgn":{ "text": "Begins with", "sign": "^=" },
		"end":{ "text": "Ends with", "sign": "=^" },
		"eql":{ "text": "Has Equal Length", "sign": "#=" },
		"lng":{ "text": "Is Longer", "sign": "#>" },
		"shr":{ "text": "Is Shorter", "sign": "#<" },
	},
	"bool": {
		"eq": { "text": "Conforms", "sign": "=="},
		"nq": { "text": "Doesn't Conform", "sign": "!="},
	},
}

class Statement :
	
	var Mind
	
	func _init(mind) -> void:
		Mind = mind
		pass
	
	func parse(data:Dictionary, variables_current = null):
		var parsed = null
		if data.has_all(["variable", "operator", "with"]) && (data.variable is int) && (data.variable >= 0):
			var statement = { "lhs": null, "operator": null, "rhs": null }
			var lhs = (variables_current[data.variable] if variables_current != null else Mind.lookup_resource(data.variable,"variables"))
			if lhs is Dictionary && lhs.has_all(["name", "type", "init"]):
				statement.lhs = lhs.name + ((" `" + String(lhs.value if lhs.has("value") else lhs.init) + "`") if variables_current != null else "")
				statement.operator = COMPARISON_OPERATORS[lhs.type][data.operator].sign
				if data.with.size() == 2 :
					match data.with[0]:
						PARAMETER_MODES_ENUM_CODE.value:
							statement.rhs = "`%s`" % data.with[1]
						PARAMETER_MODES_ENUM_CODE.variable:
							if data.with[1] == data.variable : # the variable is compared to self (initial value)
								statement.rhs = "Self (Initial `" + String(lhs.init) + "`)"
							else: # or another variable
								var rhs = (variables_current[data.with[1]] if variables_current != null else Mind.lookup_resource(data.with[1],"variables"))
								if rhs is Dictionary && rhs.has_all(["name", "type", "init"]):
									statement.rhs = (("`" + String(rhs.value if rhs.has("value") else rhs.init) + "` ") if variables_current != null else "") + rhs.name
								else:
									statement.rhs = "[Invalid]"
					parsed = "{lhs} {operator} {rhs}".format(statement)
		return parsed
	
	# returns bool on successful evaluation, otherwise null
	func evaluate(data:Dictionary, variables_current:Dictionary):
		var result = null
		if data.has_all(["variable", "operator", "with"]) && (data.variable is int) && (data.variable >= 0):
			var variable = Mind.lookup_resource(data.variable, "variables")
			if variable is Dictionary && variable.has("type"):
				var type = variable.type
				var operator = data.operator
				if variables_current.has(data.variable):
					var value = variables_current[data.variable].value
					var with_value
					match data.with[0]:
						PARAMETER_MODES_ENUM_CODE.value:
							with_value = data.with[1]
						PARAMETER_MODES_ENUM_CODE.variable:
							var the_second_variable_id = data.with[1]
							if the_second_variable_id == data.variable:
								# compared to itself (self initial value)
								with_value = variables_current[the_second_variable_id].init
							else:
								with_value = variables_current[the_second_variable_id].value
					# now we have whatever we need, just make sure the comparee value is right
					if type == "str" && (with_value is String) == false:
						with_value = String(with_value)
					elif type == "num" && (with_value is int) == false:
						with_value= int(with_value)
					elif type == "bool" && (with_value is bool) == false:
						with_value= bool(with_value)
					# lets evaluate for the type
					result = call(("evaluate_%s_comparison" % type), value, operator, with_value)
		return result
	
	# `evaluate_str_comparison` can give a number as input, but it comes from a textual input
	# also it may compare two real strings (str variables) so we shall
	# detect what user have had in mind:
	func smart_length_parse(string:String) -> int:
		# if string is only a number inputted as string, it will be parsed as length
		# otherwise length of the string is the result
		return (int(string) if ( string == String(int(string)) ) else string.length())
	
	func evaluate_str_comparison(left:String, operation:String, right:String):
		var result = null
		match operation:
			"rgx": # Matches RegEx Pattern
				var regex = RegEx.new()
				if ( regex.compile(right) == OK ):
					# RegEx.search() returns RegExMatch if found, otherwise `null`
					result = ( regex.search(left) != null )
			"ct": # Contains Substring
				result = (left.findn(right) >= 0)
			"cts": # Contains Substring (Case-Sensitive)
				result = (left.find(right) >= 0)
			"eql": # Has Equal Length
				result = (left.length() == smart_length_parse(right))
			"lng": # Is Longer
				result = (left.length() > smart_length_parse(right))
			"shr": # Is Shorter
				result = (left.length() < smart_length_parse(right))
			"bgn": # Begins with
				result = left.begins_with(right)
			"end": # Ends with
				result = left.ends_with(right)
		return result
		
	func evaluate_num_comparison(left:int, operation:String, right:int):
		var result = null
		match operation:
			"eq": # is Equal
				result = ( left == right)
			"nq": # is Not Equal
				result = ( left != right)
			"gt": # is Greater
				result = ( left > right)
			"gte": # is Greater or Equal
				result = ( left >= right)
			"ls": # is Lesser
				result = ( left < right)
			"lse": # is Lesser or Equal
				result = ( left <= right)
		return result
		
	func evaluate_bool_comparison(left:bool, operation:String, right:bool):
		var result = null
		match operation:
			"eq":
				result = (left == right)
			"nq":
				result = (left != right)
		return result
