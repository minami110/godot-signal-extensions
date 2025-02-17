extends GdUnitTestSuite

@warning_ignore("unused_parameter")
@warning_ignore("unused_variable")
@warning_ignore("return_value_discarded")

signal no_parms
var _result_int: int

func test_subscribe_no_params() -> void:
	_result_int = 0
	var sub := Subscription.new(no_parms, func() -> void:
		_result_int += 1
	)
	no_parms.emit()
	assert_int(_result_int).is_equal(1)
	sub.dispose()


func test_unsubscribe() -> void:
	_result_int = 0
	var sub := Subscription.new(no_parms, func() -> void:
		_result_int += 1
	)
	no_parms.emit()
	assert_int(_result_int).is_equal(1)
	sub.dispose()
	no_parms.emit()
	assert_int(_result_int).is_equal(1)
