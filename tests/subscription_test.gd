extends GdUnitTestSuite

signal no_parms
const Subscription = preload("res://addons/signal_extensions/subscription.gd")
var _result_int: int


func test_subscribe_no_params() -> void:
	_result_int = 0
	var sub := Subscription.new(
		no_parms,
		func() -> void:
			_result_int += 1
	)
	no_parms.emit()
	assert_int(_result_int).is_equal(1)
	sub.dispose()


func test_unsubscribe() -> void:
	_result_int = 0
	var sub := Subscription.new(
		no_parms,
		func() -> void:
			_result_int += 1
	)
	no_parms.emit()
	assert_int(_result_int).is_equal(1)
	sub.dispose()
	no_parms.emit()
	assert_int(_result_int).is_equal(1)
