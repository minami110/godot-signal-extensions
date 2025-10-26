extends GdUnitTestSuite

static var _result_static_array: Array[int] = []


static func update_static_result_array(i: int) -> void:
	_result_static_array.append(i)


func standard() -> void:
	var result: Array[int] = []

	var subject := Subject.new()
	subject.subscribe(result.append)

	subject.on_next(10)
	subject.on_next(10)
	subject.dispose()
	subject.on_next(20)
	assert_array(result).contains_exactly(10, 10)


func standard_no_argument() -> void:
	var result: Array[int] = []

	var subject := Subject.new()
	subject.subscribe(result.append.bind("called"))

	subject.on_next(10)
	subject.on_next(20)
	assert_array(result).contains_exactly("called", "called")


func test_unit() -> void:
	var result: Array[String] = []
	var subject := Subject.new()
	subject.subscribe(result.append.bind("called"))
	assert_array(result).is_empty()

	subject.on_next()
	assert_array(result).contains_exactly("called")


func test_subject_await() -> void:
	var result: Array[int] = []
	var subject := Subject.new()
	subject.subscribe(result.append)

	subject.on_next.call_deferred(10)
	var await_result: int = await subject.wait()
	assert_int(await_result).is_equal(10)

	await get_tree().process_frame


func test_dispose() -> void:
	var result: Array[int] = []

	var subject := Subject.new()
	var d := subject.subscribe(result.append)
	subject.dispose()
	subject = Subject.new()

	subject.on_next(10)
	assert_array(result).is_empty()

	d.dispose()
	d = subject.subscribe(result.append)
	d.dispose()
	subject.dispose()
	subject.on_next(10)
	assert_array(result).is_empty()


func test_static_method_bind() -> void:
	_result_static_array.clear()
	var subject := Subject.new()
	subject.subscribe(update_static_result_array)
	subject.on_next(10)
	assert_array(_result_static_array).contains_exactly(10)
