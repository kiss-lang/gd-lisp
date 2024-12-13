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
	#(set test_var (+ 5 6 7))
	var _arg6 = 5
	var _arg7 = 6
	var _arg8 = 7
	
	var _set_val0 = (_arg6 + _arg7 + _arg8)
	test_var = _set_val0
	########################################
	#(set test_var (+ (+ 5 6 7) (- 2 3 4)))
	var _arg10 = 5
	var _arg11 = 6
	var _arg12 = 7
	
	var _arg9 = (_arg10 + _arg11 + _arg12)
	var _arg14 = 2
	var _arg15 = 3
	var _arg16 = 4
	
	var _arg13 = (_arg14 - _arg15 - _arg16)
	
	var _set_val1 = (_arg9 + _arg13)
	test_var = _set_val1
	########################################

	#(assertEq 13 test_var)
	var _arg17 = 13
	var _arg18 = test_var
	assertEquals(_arg17, _arg18)
	#############################

	#(let [a 5 b 6]
	#	(assertEq 5 a)
	#	(assertEq 6 b)
	#	(assertEq 11 (+ a b)))
	var _let0 = func(a, b):
		var _arg19 = 5
		var _arg20 = a
		assertEquals(_arg19, _arg20)
		
		var _arg21 = 6
		var _arg22 = b
		assertEquals(_arg21, _arg22)
		
		var _arg23 = 11
		var _arg25 = a
		var _arg26 = b
		
		var _arg24 = (_arg25 + _arg26)
		assertEquals(_arg23, _arg24)
	var _arg27 = 5
	var _arg28 = 6
	_let0.call(_arg27, _arg28)
	################################
	#(assertEq 5 (let [a 5 b 6] a))
	var _arg29 = 5
	var _let1 = func(a, b):
		return a
	var _arg31 = 5
	var _arg32 = 6
	var _arg30 = _let1.call(_arg31, _arg32)
	assertEquals(_arg29, _arg30)
	########################################


	quit()
