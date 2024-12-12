extends SceneTree

#(prelude)
# (print <...>) is an alias for this
func _gdprint(v):
	print(v)
	return v

# (assertEq <expected> <actual>)
func assertEquals(expected, actual):
	assert(expected == actual, 'Expected {} but it was {}'.format([expected, actual], "{}"))
#########################################################################################
	
func _initialize():
	#(assertEq 6 6)
	assertEquals(6, 6)
	###################
	quit()
