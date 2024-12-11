#(prelude)
func _gdprint(v):
    print(v)
    return v
#################
func gdfunc():
	#(let [a 5 b 6] (print (+ a b)))
	func _let0(a, b):
		return _gdprint(a + b)	
	################################
																								
