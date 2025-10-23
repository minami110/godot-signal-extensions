extends GdUnitTestSuite

func test_add_to_array() -> void:
	var result: Array[String] = []
	var bag: Array[Disposable] = []
	var subject := Subject.new()
	subject.subscribe(result.append.bind("called")).add_to(bag)

	for sub in bag:
		sub.dispose()

	subject.on_next()
	assert_array(result).is_empty()


func test_add_to_node() -> void:
	var result: Array[String] = []
	var node := Node.new()
	var subject := Subject.new()

	add_child.call_deferred(node)
	await child_entered_tree

	subject.subscribe(result.append.bind("called")).add_to(node)

	subject.on_next()
	assert_array(result).contains_exactly(["called"])

	node.queue_free()
	await child_exiting_tree

	subject.on_next()
	assert_array(result).contains_exactly(["called"])
