# (print <...>) is an alias for this
func _gdprint(v):
	print(v)
	return v

func truthy(v):
	return (type_string(typeof(v)) == 'bool' && v != false) && v != null

# (assertEq <expected> <actual>)
func assertEquals(expected, actual):
	assert(expected == actual, 'Expected {} but it was {}'.format([expected, actual], "{}"))