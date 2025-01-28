extends GdUnitTestSuite


func test_standard() -> void:
	var result := []
	var subject := Subject.new()
	subject \
		.take_while(func(x): return x <= 2) \
		.subscribe(func(x): result.push_back(x))

	subject.on_next(1)
	subject.on_next(2)
	subject.on_next(3)
	assert_array(result, true).is_equal([1, 2])


func test_two_subscribers() -> void:
	var result1 := []
	var result2 := []
	var result3 := []

	var subject := Subject.new()
	var take_while1 := subject.take_while(func(x): return x < 4)
	var take_while2 := take_while1.take_while(func(x): return x > 2)

	take_while1.subscribe(func(x): result1.push_back(x))

	subject.on_next(3)
	subject.on_next(4)

	assert_array(result1, true).is_equal([3])

	take_while1.subscribe(func(x): result2.push_back(x))

	subject.on_next(3)
	subject.on_next(1)
	subject.on_next(4)

	assert_array(result1, true).is_equal([3])
	assert_array(result2, true).is_equal([3, 1])

	take_while2.subscribe(func(x): result3.push_back(x))

	subject.on_next(3)
	subject.on_next(1)
	subject.on_next(4)

	assert_array(result1, true).is_equal([3])
	assert_array(result2, true).is_equal([3, 1])
	assert_array(result3, true).is_equal([3])
