extends GdUnitTestSuite


func test_standard() -> void:
	var result := []
	var subject := Subject.new()
	subject \
		.take(2) \
		.subscribe(func(x): result.push_back(x))

	subject.on_next(10)
	subject.on_next(20)
	subject.on_next(30)
	assert_array(result, true).is_equal([10, 20])

func test_two_subscribers() -> void:
	var result1 := []
	var result2 := []

	var subject := Subject.new()
	var take1 := subject.take(2)
	var take2 := take1.take(3)