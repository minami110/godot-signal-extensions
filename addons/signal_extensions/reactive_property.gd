class_name ReactiveProperty extends Observable

var _value: Variant
var _check_equality: bool
signal _value_changed(new_value: Variant)

func _init(initial_value: Variant, check_equality := true) -> void:
	_value = initial_value
	_check_equality = check_equality

func _get_value() -> Variant:
	return _value

func _set_value(new_value: Variant) -> void:
	if self.is_blocking_signals():
		return

	if _check_equality and _value == new_value:
		return

	_value = new_value
	_value_changed.emit(new_value)

## The current value of the property.
var value: Variant: get = _get_value, set = _set_value

func _subscribe_core(observer: Callable) -> Disposable:
	if self.is_blocking_signals():
		return Disposable.empty
	else:
		observer.call(_value)
		return Subscription.new(_value_changed, observer)

## Dispose of the property.
func dispose() -> void:
	if self.is_blocking_signals():
		return

	# Disconnect all signals
	var connections := self.get_signal_connection_list(&"_value_changed")
	for c in connections:
		_value_changed.disconnect(c.callable as Callable)

	self.set_block_signals(true)

## Wait for the next value changed.
## Usage:
## [codeblock]
## var value := await rp.wait()
## [/codeblock]
func wait() -> Variant:
	if self.is_blocking_signals():
		return null

	return await _value_changed