extends GdUnitTestSuite

@warning_ignore_start("untyped_declaration")

func test_standard() -> void:
	var result := []
	Observable.of(1, 2, 3).subscribe(result.push_back)
	assert_array(result, true).contains_exactly(1, 2, 3)


func test_single_value() -> void:
	var result := []
	Observable.of(42).subscribe(result.push_back)
	assert_array(result, true).contains_exactly(42)


func test_mixed_types() -> void:
	var result := []
	Observable.of(1, "hello", 3.14, true).subscribe(result.push_back)
	assert_array(result, true).contains_exactly(1, "hello", 3.14, true)


func test_empty_observable() -> void:
	var result := []
	Observable.of().subscribe(result.push_back)
	assert_array(result, true).is_empty()


func test_with_select() -> void:
	var result := []
	Observable.of(1, 2, 3) \
	.select(func(x): return x * 2) \
	.subscribe(result.push_back)
	assert_array(result, true).contains_exactly(2, 4, 6)


func test_with_where() -> void:
	var result := []
	Observable.of(1, 2, 3, 4, 5) \
	.where(func(x): return x > 2) \
	.subscribe(result.push_back)
	assert_array(result, true).contains_exactly(3, 4, 5)


func test_with_take() -> void:
	var result := []
	Observable.of(1, 2, 3, 4, 5) \
	.take(3) \
	.subscribe(result.push_back)
	assert_array(result, true).contains_exactly(1, 2, 3)


func test_with_skip() -> void:
	var result := []
	Observable.of(1, 2, 3, 4, 5) \
	.skip(2) \
	.subscribe(result.push_back)
	assert_array(result, true).contains_exactly(3, 4, 5)


func test_multiple_subscribers() -> void:
	var result1 := []
	var result2 := []

	var observable := Observable.of(1, 2, 3)
	observable.subscribe(result1.push_back)
	observable.subscribe(result2.push_back)

	assert_array(result1, true).contains_exactly(1, 2, 3)
	assert_array(result2, true).contains_exactly(1, 2, 3)


func test_with_scan() -> void:
	var result := []
	Observable.of(1, 2, 3, 4) \
	.scan(0, func(acc, x): return acc + x) \
	.subscribe(result.push_back)
	assert_array(result, true).contains_exactly(1, 3, 6, 10)


func test_chain_multiple_operators() -> void:
	var result := []
	Observable.of(1, 2, 3, 4, 5) \
	.where(func(x): return x > 1) \
	.select(func(x): return x * 2) \
	.take(2) \
	.subscribe(result.push_back)
	assert_array(result, true).contains_exactly(4, 6)
