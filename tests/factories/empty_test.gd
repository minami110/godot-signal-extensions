extends GdUnitTestSuite

@warning_ignore_start("untyped_declaration")

func test_empty_completes_immediately() -> void:
	var result := []
	Observable.empty().subscribe(result.push_back)
	assert_array(result, true).is_empty()


func test_empty_is_singleton() -> void:
	var empty1 := Observable.empty()
	var empty2 := Observable.empty()
	# Verify same instance is returned (memory efficiency)
	assert_that(empty1).is_same(empty2)


func test_empty_multiple_subscriptions() -> void:
	var result1 := []
	var result2 := []
	var empty := Observable.empty()

	empty.subscribe(result1.push_back)
	empty.subscribe(result2.push_back)

	assert_array(result1, true).is_empty()
	assert_array(result2, true).is_empty()


func test_empty_wait_returns_null() -> void:
	var empty := Observable.empty()
	var result: Variant = await empty.wait()
	assert_that(result).is_null()


func test_empty_with_operators() -> void:
	var result := []
	Observable.empty() \
		.select(func(x): return x * 2) \
		.where(func(x): return x > 0) \
		.subscribe(result.push_back)
	assert_array(result, true).is_empty()
