# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Variable_Update Node Type Shared Class
# (a set of constants and functions used by different scripts of Variable_Update node type)
class_name VariableUpdateSharedClass

const PARAMETER_MODES_ENUM = {
	0: "value",
	1: "variable"
}
const PARAMETER_MODES_ENUM_CODE = {
	"value": 0,
	"variable": 1
}
const UPDATE_OPERATORS = {
	# CAUTION! this list shall correspond to the `evaluate_...` functions
	"num": {
		"set": { "text": "Set Equal", "sign": "=" },
		"add": { "text": "Addition", "sign": "+=" },
		"sub": { "text": "Subtraction", "sign": "-=" },
		"div": { "text": "Division", "sign": "/=" },
		"rem": { "text": "Remainder", "sign": "%=" },
		"mul": { "text": "Multiplication", "sign": "*=" },
		"exp": { "text": "Exponentiation", "sign": "^=" },
		"abs": { "text": "Absolute", "sign": "=||" },
	},
	"str": {
		"set": { "text": "Set", "sign": "=" },
		"stc": { "text": "Set Capitalized", "sign": "C=" },
		"stl": { "text": "Set Lowercased", "sign": "l=" },
		"stu": { "text": "Set Uppercased", "sign": "U=" },
		"ins": { "text": "Insert Right", "sign": "=+" },
		"inb": { "text": "Insert Left", "sign": "+=" },
		"rmc": { "text": "Remove Left", "sign": "-=" },
		"rml": { "text": "Remove Left (Case Insensitive)", "sign": "-~" },
		"rmr": { "text": "Remove Right", "sign": "=-" },
		"rmi": { "text": "Remove Right (Case Insensitive)", "sign": "~-" },
		"rpl": { "text": "Replace", "sign": "=*", "hint": "Use pipe to define arguments (i.e. `find|replace`)." },
		"rpi": { "text": "Replace (Case Insensitive)", "sign": "~*", "hint": "Use pipe to define arguments (i.e. `find|replace`)." },
	},
	"bool": {
		"set": { "text": "Set", "sign": "=" },
		"neg": { "text": "Set Negative", "sign": "=!" },
	},
}

class expression :
	
	var Mind
	
	func _init(mind) -> void:
		Mind = mind
		pass
	
	func parse(data:Dictionary, variables_current = null):
		var parsed = null
		if data.has_all(["variable", "operator", "with"]) && (data.variable is int) && (data.variable >= 0):
			var expression = { "lhs": null, "operator": null, "rhs": null }
			var lhs = (variables_current[data.variable] if variables_current != null else Mind.lookup_resource(data.variable,"variables"))
			if lhs is Dictionary && lhs.has_all(["name", "type", "init"]):
				expression.lhs = lhs.name + ((" `" + String(lhs.value if lhs.has("value") else lhs.init) + "`") if variables_current != null else "")
				expression.operator = UPDATE_OPERATORS[lhs.type][data.operator].sign
				if data.with.size() == 2 :
					match data.with[0] :
						PARAMETER_MODES_ENUM_CODE.value:
							expression.rhs = "`%s`" % data.with[1]
						PARAMETER_MODES_ENUM_CODE.variable:
							if data.with[1] == data.variable : # the variable is compared to self (initial value)
								expression.rhs = "Self (Initial `" + String(lhs.init) + "`)"
							else: # or another variable
								var rhs = (variables_current[data.with[1]] if variables_current != null else Mind.lookup_resource(data.with[1],"variables"))
								if rhs is Dictionary && rhs.has_all(["name", "type", "init"]):
									expression.rhs = (("`" + String(rhs.value if rhs.has("value") else rhs.init) + "` ") if variables_current != null else "") + rhs.name
								else:
									expression.rhs = "[Invalid]"
					parsed = "{lhs} {operator} {rhs}".format(expression)
		return parsed
	
	# returns the new value on successful evaluation, otherwise `null`
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
								# with its own initial value
								with_value = variables_current[the_second_variable_id].init
							else:
								with_value = variables_current[the_second_variable_id].value
					# now we have whatever we need
					# lets evaluate for the type
					result = call(("evaluate_%s_update" % type), value, operator, with_value)
		return result
	
	func evaluate_num_update(left:int, operation:String, right:int):
		var result = null # updates `left` by ...
		match operation:
			"set": # Set Equal (=)
				result = right
			"add": # Addition (+=)
				result = (left + right)
			"sub": # Subtraction (-=)
				result = (left - right)
			"div": # Division (/=)
				if right != 0: # no support for infinity
					result = int( floor(left / right) )
			"rem": # Remainder (%=)
				if right != 0: # no support for NAN
					result = (left % right)
			"mul": # Multiplication (*=)
				result = (left * right)
			"exp": # Exponentiation (^=)
				result = pow(left, right)
			"abs": # Absolute (=||)
				result = abs(right)
		return (
			# rounds to the nearest whole number 2.9 -> 3 not 2
			int ( round ( result ) )
			if result != null
			else null
		)
		
	func evaluate_str_update(left:String, operation:String, right:String):
		var result = null # updates `left` by ...
		match operation:
			"set": # Set (=)
				result = right
			"stc": # Set Capitalized (C=)
				result = right.capitalize()
			"stl": # Set Lowercased (l=)
				result = right.to_lower()
			"stu": # Set Uppercased (u=)
				result = right.to_upper()
			"ins": # Insert Right (=+)
				result = ( left + right )
			"inb": # Insert Left (+=)
				result = ( right + left )
			"rmc": # Remove Left (-=)
				var rem_idx = left.find(right)
				if rem_idx >= 0:
					result = left.substr(0, rem_idx) + left.substr((rem_idx + right.length()), -1)
				else:
					result = left
			"rml": # Remove Left _Case Insensitive_ (-~)
				var rem_idx = left.findn(right)
				if rem_idx >= 0:
					result = left.substr(0, rem_idx) + left.substr((rem_idx + right.length()), -1)
				else:
					result = left
			"rmr": # Remove Right (=-)
				var rem_idx = left.rfind(right)
				if rem_idx >= 0:
					result = left.substr(0, rem_idx) + left.substr((rem_idx + right.length()), -1)
				else:
					result = left
			"rmi": # Remove Right _Case Insensitive_ (~-)
				var rem_idx = left.rfindn(right)
				if rem_idx >= 0:
					result = left.substr(0, rem_idx) + left.substr((rem_idx + right.length()), -1)
				else:
					result = left
			"rpl": # Replace (=*)	
				var replacement = right.split("|")
				if replacement.size() == 1: # consider it a replace with blank (ie. "" ~ remove all)
					replacement.append("")
				result = left.replace(replacement[0], replacement[1])
			"rpi": # Replace _Case Insensitive_ (~*)
				var replacement = right.split("|")
				if replacement.size() == 1: # consider it a replace with blank (ie. "" ~ remove all)
					replacement.append("")
				result = left.replacen(replacement[0], replacement[1])
		return result
		
	func evaluate_bool_update(left:bool, operation:String, right:bool):
		var result = null # updates `left` by ...
		match operation:
			"set": # Set (=)
				result = right
			"neg": # Set Negative (=!)
				result = ( ! right )
		return result
