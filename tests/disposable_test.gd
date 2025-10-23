extends GdUnitTestSuite

var _result_int: int


func test_add_to_array() -> void:
	_result_int = 0
	var bag: Array[Disposable] = []
	var subject := Subject.new()
	subject.subscribe(
		func(_u: Unit) -> void:
			_result_int += 1
	).add_to(bag)

	for sub in bag:
		sub.dispose()

	subject.on_next()
	assert_int(_result_int).is_equal(0)


func test_add_to_node() -> void:
	_result_int = 0
	var node := Node.new()
	var subject := Subject.new()

	add_child.call_deferred(node)
	await child_entered_tree

	subject.subscribe(
		func(_u: Unit) -> void:
			_result_int += 1
	).add_to(node)

	subject.on_next(Unit.default)
	assert_int(_result_int).is_equal(1)

	node.queue_free()
	await child_exiting_tree

	subject.on_next(Unit.default)
	assert_int(_result_int).is_equal(1)
