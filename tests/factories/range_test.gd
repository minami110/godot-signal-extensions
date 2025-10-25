extends GdUnitTestSuite

@warning_ignore_start("untyped_declaration")

func test_standard() -> void:
	var result := []
	Observable.range(1, 5).subscribe(result.push_back)
	assert_array(result, true).contains_exactly(1, 2, 3, 4, 5)


func test_range_from_zero() -> void:
	var result := []
	Observable.range(0, 3).subscribe(result.push_back)
	assert_array(result, true).contains_exactly(0, 1, 2)


func test_range_negative_start() -> void:
	var result := []
	Observable.range(-2, 4).subscribe(result.push_back)
	assert_array(result, true).contains_exactly(-2, -1, 0, 1)


func test_range_single_value() -> void:
	var result := []
	Observable.range(10, 1).subscribe(result.push_back)
	assert_array(result, true).contains_exactly(10)


func test_range_zero_count() -> void:
	var result := []
	Observable.range(5, 0).subscribe(result.push_back)
	assert_array(result, true).is_empty()


func test_range_with_select() -> void:
	var result := []
	Observable.range(1, 5) \
	.select(func(x): return x * 2) \
	.subscribe(result.push_back)
	assert_array(result, true).contains_exactly(2, 4, 6, 8, 10)


func test_range_with_where() -> void:
	var result := []
	Observable.range(1, 10) \
	.where(func(x): return x % 2 == 0) \
	.subscribe(result.push_back)
	assert_array(result, true).contains_exactly(2, 4, 6, 8, 10)


func test_range_with_take() -> void:
	var result := []
	Observable.range(1, 10) \
	.take(3) \
	.subscribe(result.push_back)
	assert_array(result, true).contains_exactly(1, 2, 3)


func test_range_with_skip() -> void:
	var result := []
	Observable.range(1, 5) \
	.skip(2) \
	.subscribe(result.push_back)
	assert_array(result, true).contains_exactly(3, 4, 5)


func test_range_with_scan() -> void:
	var result := []
	Observable.range(1, 4) \
	.scan(0, func(acc, x): return acc + x) \
	.subscribe(result.push_back)
	assert_array(result, true).contains_exactly(1, 3, 6, 10)


func test_multiple_subscribers() -> void:
	var result1 := []
	var result2 := []

	var observable := Observable.range(5, 3)
	observable.subscribe(result1.push_back)
	observable.subscribe(result2.push_back)

	assert_array(result1, true).contains_exactly(5, 6, 7)
	assert_array(result2, true).contains_exactly(5, 6, 7)


func test_chain_multiple_operators() -> void:
	var result := []
	Observable.range(1, 10) \
	.where(func(x): return x > 3) \
	.select(func(x): return x * 2) \
	.take(2) \
	.subscribe(result.push_back)
	assert_array(result, true).contains_exactly(8, 10)
