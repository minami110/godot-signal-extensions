extends GdUnitTestSuite


func test_standard() -> void:
	var result := []
	var subject := Subject.new()
	subject \
		.skip_while(func(x): return x <= 2) \
		.subscribe(func(x): result.push_back(x))

	subject.on_next(1)
	subject.on_next(2)
	subject.on_next(3)
	subject.on_next(1)
	subject.on_next(2)
	assert_array(result, true).is_equal([3, 1, 2])
