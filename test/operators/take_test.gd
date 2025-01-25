extends GdUnitTestSuite

@warning_ignore("unused_parameter")
@warning_ignore("unused_variable")
@warning_ignore("return_value_discarded")

var _result_int: int

func test_take() -> void:
	_result_int = 0
	var subject := Subject.new()
	subject.take(2).subscribe(func(i: int) -> void:
		_result_int = i
	)

	subject.on_next(10)
	assert_int(_result_int).is_equal(10)
	subject.on_next(20)
	assert_int(_result_int).is_equal(20)
	subject.on_next(30)
	assert_int(_result_int).is_equal(20)
