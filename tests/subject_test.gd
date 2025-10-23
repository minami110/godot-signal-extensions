extends GdUnitTestSuite

@warning_ignore("unused_parameter")
@warning_ignore("unused_variable")
@warning_ignore("return_value_discarded")

var _result_int: int


func standard() -> void:
	var result: Array[int] = []

	var subject := Subject.new()
	subject.subscribe(
		func(i: int) -> void:
			result.append(i)
	)

	subject.on_next(10)
	subject.on_next(10)
	subject.dispose()
	subject.on_next(20)
	assert_array(result).contains_exactly([10, 10])


func standard_no_argument() -> void:
	var result: Array[int] = []

	var subject := Subject.new()
	subject.subscribe(
		func() -> void:
			result.append("called")
	)

	subject.on_next(10)
	subject.on_next(20)
	assert_array(result).contains_exactly(["called", "called"])


func test_unit() -> void:
	_result_int = 0
	var subject := Subject.new()
	subject.subscribe(
		func(_u: Unit) -> void:
			_result_int += 1
	)
	assert_int(_result_int).is_equal(0)

	subject.on_next(Unit.default)
	assert_int(_result_int).is_equal(1)


func test_subject_await() -> void:
	_result_int = 0
	var subject := Subject.new()
	subject.subscribe(
		func(i: int) -> void:
			_result_int = i
	)

	subject.on_next.call_deferred(10)
	var result: int = await subject.wait()
	assert_int(result).is_equal(10)

	await get_tree().process_frame


func test_dispose() -> void:
	_result_int = 0

	var subject := Subject.new()
	var d := subject.subscribe(
		func(i: int) -> void:
			_result_int = i
	)
	subject.dispose()
	subject = Subject.new()

	subject.on_next(10)
	assert_int(_result_int).is_equal(0)

	d.dispose()
	d = subject.subscribe(
		func(i: int) -> void:
			_result_int = i
	)
	d.dispose()
	subject.dispose()
	subject.on_next(10)
	assert_int(_result_int).is_equal(0)
