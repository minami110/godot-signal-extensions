extends GdUnitTestSuite

signal no_parms
var _result_int: int

func test_add_to_array() -> void:
	_result_int = 0
	var bag: Array[Disposable] = []
	Subscription.new(no_parms, func() -> void:
		_result_int += 1
	).add_to(bag)

	for sub in bag:
		sub.dispose()

	no_parms.emit()
	assert_int(_result_int).is_equal(0)

func test_add_to_node() -> void:
	_result_int = 0
	var node := Node.new()

	add_child.call_deferred(node)
	await child_entered_tree

	Subscription.new(no_parms, func() -> void:
		_result_int += 1
	).add_to(node)

	no_parms.emit()
	assert_int(_result_int).is_equal(1)

	node.queue_free()
	await child_exiting_tree

	no_parms.emit()
	assert_int(_result_int).is_equal(1)


# func test_combine() -> void:
# 	_result_int = 0
# 	var subject := Subject.new()
# 	var d1 := subject.subscribe(func(_x: Unit) -> void: _result_int += 1)
# 	var d2 := subject.subscribe(func(_x: Unit) -> void: _result_int += 1)
# 	var d3 := subject.subscribe(func(_x: Unit) -> void: _result_int += 1)

# 	subject.on_next()
# 	assert_int(_result_int).is_equal(3)

# 	var disposables := Disposable.combine(d1, d2, d3)
# 	disposables.dispose()
# 	subject.on_next()
# 	assert_int(_result_int).is_equal(3)