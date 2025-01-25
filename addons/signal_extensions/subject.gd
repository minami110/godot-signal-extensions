class_name Subject extends Observable

var _is_disposed: bool = false
signal _signal(new_value: Variant)

func on_next(value: Variant) -> void:
	if _is_disposed:
		return

	_signal.emit(value)

## Subscribe to changes in the property.
func _subscribe_core(observer: Callable) -> Disposable:
	if _is_disposed:
		return Disposable.empty
	else:
		return Subscription.new(_signal, observer)

## Dispose of the property.
func dispose() -> void:
	if _is_disposed:
		return

	_is_disposed = true

	# Disconnect all signals
	var connections := _signal.get_connections()
	for c in connections:
		_signal.disconnect(c.callable as Callable)

func wait() -> Variant:
	if _is_disposed:
		return null

	return await _signal