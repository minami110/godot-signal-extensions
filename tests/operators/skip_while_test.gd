extends GdUnitTestSuite

@warning_ignore_start("untyped_declaration")

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
	assert_array(result, true).contains_exactly([3, 1, 2])


func test_two_subscribers() -> void:
	var result1 := []
	var result2 := []
	var result3 := []

	var subject := Subject.new()
	var skip_while1 := subject.skip_while(func(x): return x <= 2)
	var skip_while2 := skip_while1.skip_while(func(x): return x >= 4)

	skip_while1.subscribe(func(x): result1.push_back(x))

	subject.on_next(1)
	subject.on_next(3)
	subject.on_next(1)

	assert_array(result1, true).contains_exactly([3, 1])

	skip_while1.subscribe(func(x): result2.push_back(x))

	subject.on_next(1)
	subject.on_next(3)
	subject.on_next(1)

	assert_array(result1, true).contains_exactly([3, 1, 1, 3, 1])
	assert_array(result2, true).contains_exactly([3, 1])

	skip_while2.subscribe(func(x): result3.push_back(x))

	subject.on_next(1)
	subject.on_next(3)

	assert_array(result1, true).contains_exactly([3, 1, 1, 3, 1, 1, 3])
	assert_array(result2, true).contains_exactly([3, 1, 1, 3])
	assert_array(result3, true).contains_exactly([3])
