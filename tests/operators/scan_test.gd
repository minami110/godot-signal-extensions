extends GdUnitTestSuite

@warning_ignore_start("untyped_declaration")

func test_standard() -> void:
	var result := []

	Observable.of(1, 2, 3) \
	.scan(0, func(acc, x): return acc + x) \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly([1, 3, 6])


func test_with_seed() -> void:
	var result := []

	Observable.of(1, 2, 3) \
	.scan(10, func(acc, x): return acc + x) \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly([11, 13, 16])


func test_counter() -> void:
	var result := []

	Observable.of("a", "b", "c", "d") \
	.scan(0, func(acc, _val): return acc + 1) \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly([1, 2, 3, 4])


func test_string_concat() -> void:
	var result := []

	Observable.of("a", "b", "c") \
	.scan("", func(acc, x): return acc + x) \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly(["a", "ab", "abc"])


func test_with_complex_objects() -> void:
	var result := []

	Observable.of(["name", "John"], ["age", 30], ["city", "NYC"]) \
	.scan(
		{ },
		func(acc, x):
			var new_dict = acc.duplicate()
			new_dict[x[0]] = x[1]
			return new_dict
	) \
	.subscribe(result.push_back)

	assert_dict(result[0]).is_equal({ "name": "John" })
	assert_dict(result[1]).is_equal({ "name": "John", "age": 30 })
	assert_dict(result[2]).is_equal({ "name": "John", "age": 30, "city": "NYC" })


func test_single_emission() -> void:
	var result := []

	Observable.of(2) \
	.scan(5, func(acc, x): return acc * x) \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly([10])


func test_empty_observable() -> void:
	var result := []

	Observable.of() \
	.scan(0, func(acc, x): return acc + x) \
	.subscribe(result.push_back)

	assert_array(result, true).is_empty()


func test_with_other_operators() -> void:
	var result := []

	Observable.of(1, -1, 2, -2, 3) \
	.where(func(x): return x > 0) \
	.scan(0, func(acc, x): return acc + x) \
	.select(func(x): return x * 2) \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly([2, 6, 12])


func test_two_subscribers() -> void:
	var result1 := []
	var result2 := []
	var subject1 := Subject.new()
	var subject2 := Subject.new()

	# Create two independent scan observables from different sources
	subject1.scan(0, func(acc, x): return acc + x).subscribe(result1.push_back)
	subject2.scan(0, func(acc, x): return acc + x).subscribe(result2.push_back)

	subject1.on_next(1)
	subject1.on_next(2)

	subject2.on_next(5)
	subject2.on_next(3)

	assert_array(result1, true).contains_exactly([1, 3])
	assert_array(result2, true).contains_exactly([5, 8])


func test_multiplication() -> void:
	var result := []

	Observable.of(2, 3, 4) \
	.scan(1, func(acc, x): return acc * x) \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly([2, 6, 24])
