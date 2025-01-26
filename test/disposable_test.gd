extends GdUnitTestSuite

var _result_int: int

func test_combine() -> void:
	_result_int = 0
	var subject := Subject.new()
	var d1 := subject.subscribe(func(_x: Unit) -> void: _result_int += 1)
	var d2 := subject.subscribe(func(_x: Unit) -> void: _result_int += 1)
	var d3 := subject.subscribe(func(_x: Unit) -> void: _result_int += 1)

	subject.on_next()
	assert_int(_result_int).is_equal(3)

	var disposables := Disposable.combine(d1, d2, d3)
	disposables.dispose()
	subject.on_next()
	assert_int(_result_int).is_equal(3)