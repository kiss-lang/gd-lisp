#(prelude)
func _gdprint(v):
    print(v)
    return v
#################

func gdfunc():
	#(return (let [a 5 b 6] (print (+ a b)) (print (- a))))
	func _let0(a, b):
		_gdprint((a + b))
		return _gdprint((0 - a))
	return _let0(5, 6)	
	#######################################################