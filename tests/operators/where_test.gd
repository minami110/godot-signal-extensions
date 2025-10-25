extends GdUnitTestSuite

@warning_ignore_start("untyped_declaration")

func test_standard() -> void:
	var result := []
	Observable.of(10, 20, 30, 10) \
	.where(func(x): return x >= 20) \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly([20, 30])


func test_merge_behaviour() -> void:
	var result := []
	Observable.of(10, 20, 25, 30) \
	.where(func(x): return x > 20) \
	.where(func(x): return x < 30) \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly([25])


func test_two_subscribers() -> void:
	var result1 := []
	var result2 := []
	var result3 := []

	var subject := Subject.new()
	var where1 := subject.where(func(x): return x >= 2)
	var where2 := where1.where(func(x): return x >= 3)

	# two subscribers
	where1.subscribe(result1.push_back)
	where1.subscribe(result2.push_back)

	subject.on_next(1)
	subject.on_next(2)
	assert_array(result1, true).contains_exactly([2])
	assert_array(result2, true).contains_exactly([2])

	where2.subscribe(result3.push_back)
	subject.on_next(2)
	subject.on_next(3)
	assert_array(result1, true).contains_exactly([2, 2, 3])
	assert_array(result2, true).contains_exactly([2, 2, 3])
	assert_array(result3, true).contains_exactly([3])
