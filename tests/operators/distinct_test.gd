extends GdUnitTestSuite

@warning_ignore_start("untyped_declaration")

func test_standard() -> void:
	var result := []
	Observable.of(1, 2, 2, 3, 1, 2, 3, 3) \
	.distinct() \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly([1, 2, 3])


func test_all_values_unique() -> void:
	var result := []
	Observable.of(1, 2, 3, 4) \
	.distinct() \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly([1, 2, 3, 4])


func test_all_values_duplicate() -> void:
	var result := []
	Observable.of(1, 1, 1, 1) \
	.distinct() \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly([1])


func test_order_maintained() -> void:
	var result := []
	Observable.of(3, 1, 2, 1, 3, 2) \
	.distinct() \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly([3, 1, 2])


func test_two_subscribers() -> void:
	var result1 := []
	var result2 := []
	var result3 := []

	var subject := Subject.new()
	var distinct1 := subject.distinct()
	var distinct2 := distinct1.distinct()

	# two subscribers to the same distinct operator
	distinct1.subscribe(result1.push_back)
	distinct1.subscribe(result2.push_back)

	subject.on_next(1)
	subject.on_next(1) # Duplicate, won't emit
	subject.on_next(2)
	assert_array(result1, true).contains_exactly(1, 2)
	assert_array(result2, true).contains_exactly(1, 2)

	# subscribe distinct2 after some values have been emitted
	distinct2.subscribe(result3.push_back)

	subject.on_next(2) # Already seen by distinct1, won't emit through distinct1
	subject.on_next(3) # First time, will emit through distinct1
	assert_array(result1, true).contains_exactly([1, 2, 3])
	assert_array(result2, true).contains_exactly([1, 2, 3])

	# distinct2 sees distinct1's values after subscribing (2 from on_next(2), 3 from on_next(3))
	assert_array(result3).contains_exactly(2, 3)
