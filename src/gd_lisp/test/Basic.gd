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
	#(assertEq
	#	5
	#	5)
	assertEquals(5, 5)
	###################
	#(var test_var 5)
	var test_var = 5
	#################
	#(assertEq 5 test_var)
	assertEquals(5, test_var)
	##########################
	#(set test_var (+ 5 6 7))
	test_var = (5 + 6 + 7)
	#########################
	#(set test_var (+ (+ 5 6 7) (- 2 3 4)))
	test_var = ((5 + 6 + 7) + (2 - 3 - 4))
	#######################################

	#(assertEq 13 test_var)
	assertEquals(13, test_var)
	###########################

	#(let [a 5 b 6]
	#	(assertEq 5 a)
	#	(assertEq 6 b)
	#	(assertEq 11 (+ a b)))
	var _let0 = func(a, b):
		assertEquals(5, a)
		assertEquals(6, b)
		assertEquals(11, (a + b))
	_let0.call(5, 6)
	###########################
	#(assertEq 5 (let [a 5 b 6] a))
	var _let2 = func(a, b):
		return a
	var _arg0 = _let2.call(5, 6)
	assertEquals(5, _arg0)
	###############################
	#(var lambd (func [a] (return (+ a 5))))
	var lambd = func (a):
		return (a + 5)
	########################################

	#(assertEq 10 (lambd.call 5))
	assertEquals(10, lambd.call(5))
	################################

	#(assertEq 6 (global_func 1 2 3))
	assertEquals(6, global_func(1, 2, 3))
	######################################

	#(assert (< 1 2 3))
	assert((1<2 && 2<3))
	#####################
	#(assert (<= 1 1 2 3 3))
	assert((1<=1 && 1<=2 && 2<=3 && 3<=3))
	#######################################

	#(assert (= 1 1 1))
	assert((1==1 && 1==1))
	#######################

	#(assert (>= 3 3 2 1 1))
	assert((3>=3 && 3>=2 && 2>=1 && 1>=1))
	#######################################

	#(assert (> 3 2 1))
	assert((3>2 && 2>1))
	#####################



	quit()
#(func global_func [a b c]
#	(return (+ a b c)))
func global_func (a, b, c):
	return (a + b + c)
###########################

