extends Node

var game: Control
var runner: SceneTree

func assert_true(condition: bool, msg: String) -> void:
	if runner:
		runner.register_assertion(condition, msg)
	else:
		assert(condition, msg)

func assert_eq(actual, expected, msg: String) -> void:
	var condition = (actual == expected)
	if typeof(actual) == TYPE_FLOAT and typeof(expected) == TYPE_FLOAT:
		condition = abs(actual - expected) < 0.0001
	
	if runner:
		runner.register_assertion(condition, "%s (Actual: %s, Expected: %s)" % [msg, str(actual), str(expected)])
	else:
		assert(condition, "%s (Actual: %s, Expected: %s)" % [msg, str(actual), str(expected)])
