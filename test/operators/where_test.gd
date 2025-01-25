extends GdUnitTestSuite

@warning_ignore("unused_parameter")
@warning_ignore("unused_variable")
@warning_ignore("return_value_discarded")

var _result_int: int

func test_where() -> void:
	_result_int = 0
	var subject := Subject.new()
	var d := subject.where(func(x): return x >= 20).subscribe(func(i): _result_int = i)

	subject.on_next(10)
	assert_int(_result_int).is_equal(0)
	subject.on_next(20)
	assert_int(_result_int).is_equal(20)
	subject.on_next(30)
	assert_int(_result_int).is_equal(30)
	subject.on_next(10)
	assert_int(_result_int).is_equal(30)
	d.dispose()
	subject.on_next(40)
	assert_int(_result_int).is_equal(30)

func test_where_merge() -> void:
	_result_int = 0
	var subject := Subject.new()
	var d := subject.where(func(x): return x > 20).where(func(x): return x < 30).subscribe(func(i): _result_int = i)

	subject.on_next(10)
	assert_int(_result_int).is_equal(0)
	subject.on_next(20)
	assert_int(_result_int).is_equal(0)
	subject.on_next(25)
	assert_int(_result_int).is_equal(25)
	subject.on_next(30)
	assert_int(_result_int).is_equal(25)
	d.dispose()
	subject.on_next(40)
	assert_int(_result_int).is_equal(25)
