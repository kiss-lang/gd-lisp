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