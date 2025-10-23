extends GdUnitTestSuite

@warning_ignore_start("untyped_declaration")

func test_standard() -> void:
	var result := []
	var subject := Subject.new()
	subject \
	.select(func(x): return x * 2) \
	.subscribe(result.push_back)

	subject.on_next(1)
	subject.on_next(2)
	subject.on_next(3)
	assert_array(result, true).contains_exactly(2, 4, 6)


func test_two_subscribers() -> void:
	var result1 := []
	var result2 := []
	var result3 := []

	var subject := Subject.new()
	var select1 := subject.select(func(x): return x + 1)
	var select2 := select1.select(func(x): return x * 2)

	# two subscribers
	select1.subscribe(result1.push_back)
	select1.subscribe(result2.push_back)

	subject.on_next(1)
	subject.on_next(2)
	assert_array(result1, true).contains_exactly(2, 3)
	assert_array(result2, true).contains_exactly(2, 3)

	select2.subscribe(result3.push_back)
	subject.on_next(3)
	assert_array(result1, true).contains_exactly(2, 3, 4)
	assert_array(result2, true).contains_exactly(2, 3, 4)
	assert_array(result3, true).contains_exactly(8)
