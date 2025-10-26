extends Observable

var _source: Observable


func _init(source: Observable) -> void:
	_source = source


func _subscribe_core(observer: Callable) -> Disposable:
	assert(observer.is_valid(), "distinct_until_changed.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "distinct_until_changed.subscribe observer must have exactly one argument")

	var o := _DistinctUntilChangedObserver.new(observer)
	return _source.subscribe(func(value: Variant) -> void: o._on_next_core(value))


class _DistinctUntilChangedObserver extends RefCounted:
	var _observer: Callable
	var _previous_value: Variant
	var _has_value: bool


	func _init(observer: Callable) -> void:
		_observer = observer
		_previous_value = null
		_has_value = false


	func _on_next_core(value: Variant) -> void:
		assert(_observer.is_valid(), "distinct_until_changed.observer (on_next callback) is not valid.")

		# First value is always emitted
		if not _has_value:
			_has_value = true
			_previous_value = value
			# OnNext
			_observer.call(value)
		else:
			# Compare with previous value
			if _previous_value != value:
				_previous_value = value
				# OnNext
				_observer.call(value)
