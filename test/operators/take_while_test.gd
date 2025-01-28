extends GdUnitTestSuite


func test_standard() -> void:
	var result := []
	var subject := Subject.new()
	subject \
		.take_while(func(x): return x <= 2) \
		.subscribe(func(x): result.push_back(x))

	var c := func(x, _y): return x <= 2
	print(c.get_argument_count())
	print(c.is_custom())
	print(c.is_valid())

	subject.on_next(1)
	subject.on_next(2)
	subject.on_next(3)
	assert_array(result, true).is_equal([1, 2])
