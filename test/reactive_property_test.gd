extends GdUnitTestSuite

# warning-ignore-all:unused_parameter
# warning-ignore-all:unused_variable
# warning-ignore-all:return_value_discarded

const __source := 'res://addons/signal_extensions/reactive_property.gd'

var _result_int: int

func test_rp() -> void:
	_result_int = 0
	var rp := ReactiveProperty.new(1)
	rp.subscribe(func(new_value: int) -> void:
		_result_int = new_value
	)
	assert_int(_result_int).is_equal(1)
	rp.value = 2
	assert_int(_result_int).is_equal(2)
	rp.dispose()
	rp.value = 3
	assert_int(_result_int).is_equal(2)

func test_rp_await() -> void:
	_result_int = 0
	var rp := ReactiveProperty.new(1)
	rp.subscribe(func(i: int) -> void:
		_result_int = i
	)

	var callable := func() -> void:
		rp.value = 2
	callable.call_deferred()
	var result: int = await rp.wait_value_changed()
	assert_int(result).is_equal(2)

	await get_tree().process_frame
