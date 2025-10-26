extends GdUnitTestSuite

@warning_ignore_start("untyped_declaration")

func test_standard() -> void:
	var result := []
	Observable.of(1, 1, 1, 2, 2, 2, 1, 1, 3, 3) \
	.distinct_until_changed() \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly(1, 2, 1, 3)


func test_first_value_always_emitted() -> void:
	var result := []
	Observable.of(1, 1, 1) \
	.distinct_until_changed() \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly(1)


func test_non_consecutive_duplicates_pass() -> void:
	var result := []
	Observable.of(1, 2, 1, 2, 1) \
	.distinct_until_changed() \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly(1, 2, 1, 2, 1)


func test_single_value() -> void:
	var result := []
	Observable.of(42) \
	.distinct_until_changed() \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly(42)


func test_two_subscribers() -> void:
	var result1 := []
	var result2 := []
	var result3 := []

	var subject := Subject.new()
	var distinct1 := subject.distinct_until_changed()
	var distinct2 := distinct1.distinct_until_changed()

	# two subscribers to the same distinct_until_changed operator
	distinct1.subscribe(result1.push_back)
	distinct1.subscribe(result2.push_back)

	subject.on_next(1)
	subject.on_next(1) # Same as previous, won't emit
	subject.on_next(2)
	assert_array(result1, true).contains_exactly(1, 2)
	assert_array(result2, true).contains_exactly(1, 2)

	# subscribe distinct2 after some values have been emitted
	distinct2.subscribe(result3.push_back)
	subject.on_next(2) # Same as previous, won't emit
	subject.on_next(1) # Different from previous, will emit

	assert_array(result1).contains_exactly(1, 2, 1)
	assert_array(result2).contains_exactly(1, 2, 1)
	assert_array(result3).contains_exactly(2, 1)
