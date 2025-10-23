extends GdUnitTestSuite

@warning_ignore_start("untyped_declaration")

func test_standard() -> void:
	var result := []
	var subject := Subject.new()
	subject \
	.take(2) \
	.subscribe(result.push_back)

	subject.on_next(10)
	subject.on_next(20)
	subject.on_next(30)
	assert_array(result, true).contains_exactly([10, 20])


func test_two_subscribers() -> void:
	var result1 := []
	var result2 := []
	var result3 := []

	var subject := Subject.new()
	var take1 := subject.take(1)
	var take2 := take1.take(1)

	take1.subscribe(result1.push_back)
	take1.subscribe(result2.push_back)

	subject.on_next(1)
	subject.on_next(2)
	assert_array(result1, true).contains_exactly([1])
	assert_array(result2, true).contains_exactly([1])

	take2.subscribe(result3.push_back)

	subject.on_next(1)
	subject.on_next(2)
	subject.on_next(3)

	assert_array(result1, true).contains_exactly([1])
	assert_array(result2, true).contains_exactly([1])
	assert_array(result3, true).contains_exactly([1, 2])
