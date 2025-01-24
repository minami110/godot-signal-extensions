extends GdUnitTestSuite

# warning-ignore-all:unused_parameter
# warning-ignore-all:unused_variable
# warning-ignore-all:return_value_discarded

const __source := 'res://addons/signal_extensions/subscription.gd'

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

func test_add_to_array() -> void:
	_result_int = 0
	var subs: Array[Subscription] = []
	var s := Subscription.new(no_parms, func() -> void:
		_result_int += 1
	).add_to(subs)

	for sub in subs:
		sub.dispose()

	no_parms.emit()
	assert_int(_result_int).is_equal(0)
	assert_bool(s._is_disposed).is_true()

func test_add_to_node() -> void:
	_result_int = 0
	var node := Node.new()

	add_child.call_deferred(node)
	await child_entered_tree

	var s := Subscription.new(no_parms, func() -> void:
		_result_int += 1
	).add_to(node)

	no_parms.emit()
	assert_int(_result_int).is_equal(1)

	node.queue_free()
	await child_exiting_tree

	no_parms.emit()
	assert_int(_result_int).is_equal(1)
	assert_bool(s._is_disposed).is_true()