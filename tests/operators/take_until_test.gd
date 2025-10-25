extends GdUnitTestSuite

@warning_ignore_start("untyped_declaration")

func test_standard() -> void:
	var result := []
	var subject := Subject.new()
	var stop := Subject.new()

	subject \
	.take_until(stop) \
	.subscribe(result.push_back)

	subject.on_next(1)
	subject.on_next(2)
	stop.on_next() # Stop signal
	subject.on_next(3) # Should not be emitted

	assert_array(result, true).contains_exactly([1, 2])


func test_stop_before_any_emission() -> void:
	var result := []
	var subject := Subject.new()
	var stop := Subject.new()

	subject \
	.take_until(stop) \
	.subscribe(result.push_back)

	stop.on_next() # Stop immediately
	subject.on_next(1) # Should not be emitted
	subject.on_next(2) # Should not be emitted

	assert_array(result, true).is_empty()


func test_two_subscribers() -> void:
	var result1 := []
	var result2 := []
	var subject := Subject.new()
	var stop := Subject.new()

	var take_until_sub := subject.take_until(stop)
	take_until_sub.subscribe(result1.push_back)

	subject.on_next(1)
	subject.on_next(2)

	# Second subscriber added after some emissions
	take_until_sub.subscribe(result2.push_back)

	subject.on_next(3)
	stop.on_next()
	subject.on_next(4)

	# Both subscribers should get emissions up to the stop signal
	assert_array(result1, true).contains_exactly([1, 2, 3])
	assert_array(result2, true).contains_exactly([3])


func test_multiple_stop_signals() -> void:
	var result := []
	var subject := Subject.new()
	var stop := Subject.new()

	subject \
	.take_until(stop) \
	.subscribe(result.push_back)

	subject.on_next(1)
	stop.on_next() # First stop signal - completes
	subject.on_next(2) # Should not be emitted
	stop.on_next() # Second stop signal - should be ignored
	subject.on_next(3) # Should not be emitted

	assert_array(result, true).contains_exactly([1])


func test_chained_take_until() -> void:
	var result := []
	var subject := Subject.new()
	var stop1 := Subject.new()
	var stop2 := Subject.new()

	subject \
	.take_until(stop1) \
	.take_until(stop2) \
	.subscribe(result.push_back)

	subject.on_next(1)
	subject.on_next(2)
	stop2.on_next() # stop2 triggers completion
	subject.on_next(3) # Should not be emitted
	stop1.on_next() # Should be ignored (already completed)

	assert_array(result, true).contains_exactly([1, 2])


func test_take_until_with_other_operators() -> void:
	var result := []
	var subject := Subject.new()
	var stop := Subject.new()

	subject \
	.where(func(x): return x > 0) \
	.select(func(x): return x * 2) \
	.take_until(stop) \
	.subscribe(result.push_back)

	subject.on_next(1) # 1 > 0, transform to 2
	subject.on_next(-1) # -1 <= 0, filtered
	subject.on_next(2) # 2 > 0, transform to 4
	stop.on_next() # Stop signal
	subject.on_next(3) # 3 > 0, but after stop

	assert_array(result, true).contains_exactly([2, 4])


func test_empty_observable() -> void:
	var result := []
	var subject := Subject.new()
	var stop := Subject.new()

	subject \
	.take_until(stop) \
	.subscribe(result.push_back)

	stop.on_next() # Stop without any emissions

	assert_array(result, true).is_empty()


func test_disposal() -> void:
	var result := []
	var subject := Subject.new()
	var stop := Subject.new()

	var subscription := subject \
	.take_until(stop) \
	.subscribe(result.push_back)

	subject.on_next(1)
	subscription.dispose()
	subject.on_next(2) # Should not be emitted after dispose
	stop.on_next()

	assert_array(result, true).contains_exactly([1])
