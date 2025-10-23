extends GdUnitTestSuite

@warning_ignore_start("untyped_declaration")

func test_standard() -> void:
	var result := []
	var subject := Subject.new()
	var d1 := subject \
	.skip(1) \
	.subscribe(func(x): result.push_back(x))

	subject.on_next(10)
	subject.on_next(20)
	subject.on_next(30)
	d1.dispose()
	subject.on_next(40)
	assert_array(result, true).contains_exactly([20, 30])


func test_two_subscribers() -> void:
	var result1 := []
	var result2 := []
	var result3 := []

	var subject := Subject.new()
	var skip1 := subject.skip(1)
	var skip2 := skip1.skip(1)

	# two subscribers
	skip1.subscribe(func(x): result1.push_back(x))

	subject.on_next(1)
	subject.on_next(2)

	assert_array(result1, true).contains_exactly([2])
	assert_array(result2, true).is_empty()
	assert_array(result3, true).is_empty()

	skip1.subscribe(func(x): result2.push_back(x))

	subject.on_next(3)
	subject.on_next(4)

	assert_array(result1, true).contains_exactly([2, 3, 4])
	assert_array(result2, true).contains_exactly([4])
	assert_array(result3, true).is_empty()

	skip2.subscribe(func(x): result3.push_back(x))

	subject.on_next(5)
	subject.on_next(6)
	subject.on_next(7)

	assert_array(result1, true).contains_exactly([2, 3, 4, 5, 6, 7])
	assert_array(result2, true).contains_exactly([4, 5, 6, 7])
	assert_array(result3, true).contains_exactly([7])
