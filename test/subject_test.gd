extends GdUnitTestSuite

# warning-ignore-all:unused_parameter
# warning-ignore-all:unused_variable
# warning-ignore-all:return_value_discarded

const __source := 'res://addons/signal_extensions/subject.gd'

var _result_int: int

func test_subject() -> void:
	_result_int = 0
	var subject := Subject.new()
	subject.subscribe(func(i: int) -> void:
		_result_int = i
	)
	assert_int(_result_int).is_equal(0)

	subject.on_next(10)
	assert_int(_result_int).is_equal(10)

	subject.dispose()
	subject.on_next(20)
	assert_int(_result_int).is_equal(10)

func test_unit() -> void:
	_result_int = 0
	var subject := Subject.new()
	subject.subscribe(func(_u: Unit) -> void:
		_result_int += 1
	)
	assert_int(_result_int).is_equal(0)

	subject.on_next(Unit.default)
	assert_int(_result_int).is_equal(1)