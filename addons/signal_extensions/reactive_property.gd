class_name ReactiveProperty extends Observable

var _is_disposed: bool = false
var _value: Variant
signal _value_changed(new_value: Variant)

func _init(initial_value: Variant) -> void:
	_value = initial_value

func _get_value() -> Variant:
	return _value

func _set_value(new_value: Variant) -> void:
	if _is_disposed:
		return

	if _value == new_value:
		return

	_value = new_value
	_value_changed.emit(new_value)

## The current value of the property.
var value: Variant: get = _get_value, set = _set_value

## Subscribe to changes in the property.
func _subscribe_core(observer: Callable) -> Disposable:
	if _is_disposed:
		return Disposable.empty
	else:
		observer.call(_value)
		return Subscription.new(_value_changed, observer)

## Dispose of the property.
func dispose() -> void:
	if _is_disposed:
		return

	_is_disposed = true

	# Disconnect all signals
	var connections := _value_changed.get_connections()
	for c in connections:
		_value_changed.disconnect(c.callable as Callable)

func wait() -> Variant:
	if _is_disposed:
		return null

	return await _value_changed