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
	var _arg0 = 6
	var _arg1 = 6
	assertEquals(_arg0, _arg1)
	###########################
	#(assertEq
	#	5
	#	5)
	var _arg2 = 5
	var _arg3 = 5
	assertEquals(_arg2, _arg3)
	###########################
	#(var test_var 5)
	var test_var = 5
	#################
	#(assertEq 5 test_var)
	var _arg4 = 5
	var _arg5 = test_var
	assertEquals(_arg4, _arg5)
	###########################
	quit()
