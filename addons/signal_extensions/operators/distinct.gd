extends Observable

var _source: Observable


func _init(source: Observable) -> void:
	_source = source


func _subscribe_core(observer: Callable) -> Disposable:
	assert(observer.is_valid(), "distinct.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "distinct.subscribe observer must have exactly one argument")

	var o := _DistinctObserver.new(observer)
	return _source.subscribe(func(value: Variant) -> void: o._on_next_core(value))


class _DistinctObserver extends RefCounted:
	var _observer: Callable
	var _seen_values: Array[Variant]


	func _init(observer: Callable) -> void:
		_observer = observer
		_seen_values = []


	func _on_next_core(value: Variant) -> void:
		assert(_observer.is_valid(), "distinct.observer (on_next callback) is not valid.")

		# Check if value has been seen before
		if value not in _seen_values:
			# Add value to seen array
			_seen_values.append(value)

			# OnNext
			_observer.call(value)
