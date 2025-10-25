extends Observable
## Factory that creates an Observable emitting a sequence of values synchronously.
##
## This factory method creates a Cold Observable that emits the provided values
## in sequence when subscribed to. Each subscription will re-emit all values.

var _values: Array[Variant] = []


func _init(values: Array) -> void:
	_values.assign(values)


func _subscribe_core(observer: Callable) -> Disposable:
	for value: Variant in _values:
		observer.call(value)
	return Disposable.empty
