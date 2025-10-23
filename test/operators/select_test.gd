extends GdUnitTestSuite

@warning_ignore_start("untyped_declaration")

func test_standard() -> void:
	var result := []
	var subject := Subject.new()
	subject \
	.select(func(x): return x * 2) \
	.subscribe(func(x): result.push_back(x))

	subject.on_next(1)
	subject.on_next(2)
	subject.on_next(3)
	assert_array(result, true).is_equal([2, 4, 6])


func test_two_subscribers() -> void:
	var result1 := []
	var result2 := []
	var result3 := []

	var subject := Subject.new()
	var select1 := subject.select(func(x): return x + 1)
	var select2 := select1.select(func(x): return x * 2)

	# two subscribers
	select1.subscribe(func(x): result1.push_back(x))
	select1.subscribe(func(x): result2.push_back(x))

	subject.on_next(1)
	subject.on_next(2)
	assert_array(result1, true).is_equal([2, 3])
	assert_array(result2, true).is_equal([2, 3])

	select2.subscribe(func(x): result3.push_back(x))
	subject.on_next(3)
	assert_array(result1, true).is_equal([2, 3, 4])
	assert_array(result2, true).is_equal([2, 3, 4])
	assert_array(result3, true).is_equal([8])
