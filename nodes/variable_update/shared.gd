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
		"set": { "text": "Set Equel", "sign": "=" },
		"add": { "text": "Addition", "sign": "+=" },
		"sub": { "text": "Subtraction", "sign": "-=" },
		"div": { "text": "Division", "sign": "/=" },
		"rem": { "text": "Remainder", "sign": "%=" },
		"mul": { "text": "Multipication", "sign": "*=" },
		"exp": { "text": "Exponentiation", "sign": "^=" },
	},
	"str": {
		"set": { "text": "Set", "sign": "=" },
		"stc": { "text": "Set Capitalized", "sign": "C=" },
		"stl": { "text": "Set Lowercased", "sign": "l=" },
		"stu": { "text": "Set Uppercased", "sign": "U=" },
		"ins": { "text": "End Insertion", "sign": "=+" },
		"inb": { "text": "Begining Insertion", "sign": "+=" },
	},
	"bool": {
		"set": { "text": "Set", "sign": "=" },
		"neg": { "text": "Set Negative", "sign": "=!" },
	},
}

class expression :
	
	const EXPRESSION_TEMPLATE = "{ident} {operator_sign} {parameter}"
	const KEYS_NEEDED_TO_PARSE = ["variable", "operator", "with"]
	const UPDATED_WITH_SELF_INITIAL_RIGHT_SIDE = "Self (Initial Value)"
	
	const STRING_VALUE_FORMATING_TEMPLATE = "`%s`"
	
	var Mind
	
	func _init(mind) -> void:
		Mind = mind
		pass
	
	func parse(data:Dictionary, variable_resource = null):
		var parsed = null
		if data.has_all(KEYS_NEEDED_TO_PARSE) && (data.variable is int) && (data.variable >= 0):
			var expression = { "ident": null, "operator_sign": null, "parameter": null }
			var variable = (variable_resource if (variable_resource is Dictionary) else Mind.lookup_resource(data.variable, "variables"))
			if variable is Dictionary && variable.has_all(["name", "type"]):
				expression.ident = variable.name
				expression.operator_sign = UPDATE_OPERATORS[variable.type][data.operator].sign
				if data.with.size() == 2 :
					match data.with[0] :
						PARAMETER_MODES_ENUM_CODE.value:
							if variable.type == "str":
								expression.parameter = (STRING_VALUE_FORMATING_TEMPLATE % data.with[1])
							else:
								expression.parameter = data.with[1]
						PARAMETER_MODES_ENUM_CODE.variable:
							if data.with[1] == data.variable : # the variable is compared to self (initial value)
								expression.parameter = UPDATED_WITH_SELF_INITIAL_RIGHT_SIDE
							else: # or another variable
								var parameter_var = Mind.lookup_resource(data.with[1], "variables")
								expression.parameter = parameter_var.name
					parsed = EXPRESSION_TEMPLATE.format(expression)
		return parsed
	
	# returns the new value on successful evaluation, otherwise `null`
	func evaluate(data:Dictionary, variables_current:Dictionary):
		var result = null
		if data.has_all(KEYS_NEEDED_TO_PARSE) && (data.variable is int) && (data.variable >= 0):
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
			"set": # Set Equel (=)
				result = right
			"add": # Addition (+=)
				result = (left + right)
			"sub": # Subtraction (-=)
				result = (left - right)
			"div": # Division (/=)
				result = (left / right)
			"rem": # Remainder (%=)
				result = (left % right)
			"mul": # Multipication (*=)
				result = (left * right)
			"exp": # Exponentiation (^=)
				result = pow(left, right)
		return (
			int ( round ( result ) )
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
			"ins": # End Insertion (=+)
				result = ( left + right )
			"inb": # Begining Insertion (+=)
				result = ( right + left )
		return result
		
	func evaluate_bool_update(left:bool, operation:String, right:bool):
		var result = null # updates `left` by ...
		match operation:
			"set": # Set (=)
				result = right
			"neg": # Set Negative (=!)
				result = ( ! right )
		return result
