extends GdUnitTestSuite

@warning_ignore("unused_parameter")
@warning_ignore("unused_variable")
@warning_ignore("return_value_discarded")

var _result_int: int

func test_skip() -> void:
	_result_int = 0
	var subject := Subject.new()
	var d0 := subject.skip(1).subscribe(func(i: int) -> void:
		_result_int = i
	)

	subject.on_next(10)
	assert_int(_result_int).is_equal(0)
	subject.on_next(20)
	assert_int(_result_int).is_equal(20)
	subject.on_next(30)
	assert_int(_result_int).is_equal(30)
	d0.dispose()
	subject.on_next(40)
	assert_int(_result_int).is_equal(30)


func test_skip2() -> void:
	_result_int = 0
	var subject := Subject.new()
	subject.skip(1).skip(1).subscribe(func(i: int) -> void:
		_result_int = i
	)

	subject.on_next(10)
	assert_int(_result_int).is_equal(0)
	subject.on_next(20)
	assert_int(_result_int).is_equal(0)
	subject.on_next(30)
	assert_int(_result_int).is_equal(30)
	subject.on_next(40)
	assert_int(_result_int).is_equal(40)