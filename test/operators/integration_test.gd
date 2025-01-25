extends GdUnitTestSuite

@warning_ignore("unused_parameter")
@warning_ignore("unused_variable")
@warning_ignore("return_value_discarded")

var _result_int: int

func test_take_skip() -> void:
	_result_int = 0
	var subject := Subject.new()
	var d := subject.take(3).skip(1).subscribe(func(i: int) -> void:
		_result_int = i
	)

	subject.on_next(10)
	assert_int(_result_int).is_equal(0)
	subject.on_next(20)
	assert_int(_result_int).is_equal(20)
	d.dispose()
	subject.on_next(30)
	assert_int(_result_int).is_equal(20)

func test_skip_take() -> void:
	_result_int = 0
	var rp := ReactiveProperty.new(10)
	var d := rp.skip(2).take(2).subscribe(func(i: int) -> void:
		_result_int = i
	)
	assert_int(_result_int).is_equal(0)

	rp.value = 20
	assert_int(_result_int).is_equal(0)
	rp.value = 30
	assert_int(_result_int).is_equal(30)
	d.dispose()
	rp.value = 40
	assert_int(_result_int).is_equal(30)

func test_where_skip() -> void:
	_result_int = 0
	var subject := Subject.new()
	var d := subject.where(func(i: int) -> bool:
		return i > 10
	).skip(1).subscribe(func(i: int) -> void:
		_result_int = i
	)

	subject.on_next(10)
	assert_int(_result_int).is_equal(0)
	subject.on_next(20)
	assert_int(_result_int).is_equal(0)
	subject.on_next(10)
	assert_int(_result_int).is_equal(0)
	subject.on_next(20)
	assert_int(_result_int).is_equal(20)
	d.dispose()
	subject.on_next(30)
	assert_int(_result_int).is_equal(20)