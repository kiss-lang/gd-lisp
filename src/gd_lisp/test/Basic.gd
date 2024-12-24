extends SceneTree

#(prelude)
# (print <...>) is an alias for this
func _gdprint(v):
	print(v)
	return v

func truthy(v):
	if typeof(v) == TYPE_BOOL:
		return v
	return v != null

func _not(v):
	return !truthy(v)

# (assertEq <expected> <actual>)
func assertEquals(expected, actual):
	assert(typeof(expected) == typeof(actual) && expected == actual, 'Expected {} but it was {}'.format([str(expected), str(actual)], "{}"))

func _n(arr, n):
	if n < 0:
		n = arr.size() + n
	return n

func nth(arr, n):
	return arr[_n(arr, n)]

func setNth(arr, n, val):
	arr[_n(arr, n)] = val

func dictGet(dict, key):
	return dict[key]

const PAIR_OVERLOAD = '___PAIR_OVERLOAD___'
# (dictSet <dict> <key> <val>) or (dictSet <dict> <KVPair_>)
func dictSet(dict, key, val = PAIR_OVERLOAD):
	if val == PAIR_OVERLOAD:
		assert(key is KVPair_, "expected a =>key value pair")
		val = key.value
		key = key.key
	dict[key] = val

class KVPair_:
	var key
	var value

	static func make(key, value):
		var pair = KVPair_.new()
		pair.key = key
		pair.value = value
		return pair
#########################################################################################################################################
	
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
	assert((1 < 2 && 2 < 3))
	#########################
	#(assert (<= 1 1 2 3 3))
	assert((1 <= 1 && 1 <= 2 && 2 <= 3 && 3 <= 3))
	###############################################

	#(assert (= 1 1 1))
	assert((1 == 1 && 1 == 1))
	###########################

	#(assert (>= 3 3 2 1 1))
	assert((3 >= 3 && 3 >= 2 && 2 >= 1 && 1 >= 1))
	###############################################

	#(assert (> 3 2 1))
	assert((3 > 2 && 2 > 1))
	#########################

	#(assertEq 5 (or null 5))
	var _or1 = func():
		var _arg4 = null
		if truthy(_arg4) != false:
			return _arg4
		var _arg5 = 5
		if truthy(_arg5) != false:
			return _arg5
		return _arg5
	var _arg3 = _or1.call()
	assertEquals(5, _arg3)
	############################

	#(assertEq false (and false 5))
	var _and1 = func():
		var _arg9 = false
		if truthy(_arg9) != true:
			return _arg9
		var _arg10 = 5
		if truthy(_arg10) != true:
			return _arg10
		return _arg10
	var _arg8 = _and1.call()
	assertEquals(false, _arg8)
	###############################

	#(assert (not false))
	assert(_not(false))
	#####################

	#(assert !false)
	assert(_not(false))
	####################

	var _then = true
	var _else = false
	#(assert (if true _then _else))
	var _arg11 = null
	if true:
		_arg11 = _then
	else:
		_arg11 = _else
	assert(_arg11)
	###############################
	#(assert !(if !true _then _else))
	var _arg14 = null
	if _not(true):
		_arg14 = _then
	else:
		_arg14 = _else
	var _arg13 = _not(_arg14)
	assert(_arg13)
	#################################

	#(assert (if (and true 5) _then _else))
	var _arg20 = null
	var _and5 = func():
		var _arg24 = true
		if truthy(_arg24) != true:
			return _arg24
		var _arg25 = 5
		if truthy(_arg25) != true:
			return _arg25
		return _arg25
	var _arg23 = _and5.call()
	if truthy(_arg23):
		_arg20 = _then
	else:
		_arg20 = _else
	assert(_arg20)
	#######################################

	var val1 = 0
	var val2 = 0
	#(when true
	#	(set val1 5)
	#	(set val2 6))
	if true:
		val1 = 5
		val2 = 6
	################

	#(unless false
	#	(assertEq 5 val1)
	#	(assertEq 6 val2))
	if _not(false):
		assertEquals(5, val1)
		assertEquals(6, val2)
	#######################

	#(assertEq 5
	#	(cond
	#		(false "error!")
	#		(else 5)))
	var _arg26 = null
	if false:
		_arg26 = "error!"
	else:
		_arg26 = 5
	assertEquals(5, _arg26)
	########################
	#(var arr [1 (+ 1 1) 3 (+ 4 5 6)])
	var arr = [1, (1 + 1), 3, (4 + 5 + 6)]
	#######################################

	assertEquals([1, 2, 3, 15], arr)

	#(assertEq 15 (nth arr -1))
	assertEquals(15, nth(arr, -1))
	###############################

	#(assertEq 15 (nth arr 3))
	assertEquals(15, nth(arr, 3))
	##############################

	#(var start 0)
	var start = 0
	##############

	#(+= start 5)
	start += (0 + 5)
	#################

	#(assertEq 5 start)
	assertEquals(5, start)
	#######################

	#(-= start 2 3)
	start -= (2 + 3)
	#################

	#(assertEq 0 start)
	assertEquals(0, start)
	#######################

	#(set start 1)
	start = 1
	##############

	#(*= start 1000 2)
	start *= (1000 * 2)
	####################

	#(assertEq 2000 start)
	assertEquals(2000, start)
	##########################

	#(/= start 5 100)
	start /= (5 * 100)
	###################

	#(assertEq 4 start)
	assertEquals(4, start)
	#######################

	#(var dict {})
	var dict = {}
	##############

	#(assertEq TYPE_DICTIONARY (typeof dict))
	assertEquals(TYPE_DICTIONARY, typeof(dict))
	############################################

	#(set dict {=>"key" 5 =>"key2" 6})
	var _arg27 = {
		"key": 5,
		"key2": 6
	}
	
	dict = _arg27
	##################################

	#(assertEq 5 (dict.get "key"))
	assertEquals(5, dict.get("key"))
	#################################

	#(assertEq 6 (dict.get "key2"))
	assertEquals(6, dict.get("key2"))
	##################################

	#(var val {(print "thing") (print "thing2") 5})
	_gdprint("thing")
	_gdprint("thing2")
	var val = 5
	###############################################

	#(assertEq 5 val)
	assertEquals(5, val)
	#####################

	#(var arr_comp (for a (range 5) a))
	var _collection0 =[]
	for a in range(5):
		_collection0.append(a)
	var arr_comp = _collection0
	###################################
	#(assertEq [0 1 2 3 4] arr_comp)
	assertEquals([0, 1, 2, 3, 4], arr_comp)
	########################################

	#(var dict_comp {for key ["a" "b" "c"] =>key 5})
	var _collection1 ={}
	for key in ["a", "b", "c"]:
		dictSet(_collection1, KVPair_.make(key, 5))
	var dict_comp = _collection1
	################################################

	#(assertEq {=>"a" 5 =>"b" 5 =>"c" 5} dict_comp)
	var _arg28 = {
		"a": 5,
		"b": 5,
		"c": 5
	}
	assertEquals(_arg28, dict_comp)
	###############################################

	#(var lambd2 ->a (+ a 5))
	var lambd2 = func (a):
		return (a + 5)
	#########################

	#(assertEq 6 (lambd2.call 1))
	assertEquals(6, lambd2.call(1))
	################################

	#(var countDown 100)
	var countDown = 100
	####################

	#(var countUp 0)
	var countUp = 0
	################

	#(while (> countDown 0)
	#	(-= countDown 1)
	#	(+= countUp 1))
	while (countDown > 0):
		countDown -= (0 + 1)
		countUp += (0 + 1)
	#######################

	#(assertEq 0 countDown)
	assertEquals(0, countDown)
	###########################

	#(assertEq 100 countUp)
	assertEquals(100, countUp)
	###########################

	#(var countDownList [5 4 3 2 1 0])
	var countDownList = [5, 4, 3, 2, 1, 0]
	#######################################

	#(while
	#	(let [num (countDownList.front)]
	#		(> num 0))
	#	(assert (> (countDownList.pop_front) 0)))
	var _whileCond0 = func ():
		var _let6 = func(num):
			return (num > 0)
		var _arg30 = _let6.call(countDownList.front())
		truthy(_arg30)
	while _whileCond0.call():
		assert((countDownList.pop_front() > 0))
	################################################


	quit()
#(func global_func [a b c]
#	(return (+ a b c)))
func global_func (a, b, c):
	return (a + b + c)
###########################

