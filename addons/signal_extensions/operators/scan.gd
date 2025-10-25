extends Observable

var _source: Observable
var _initial_value: Variant
var _accumulator: Callable


func _init(source: Observable, initial_value: Variant, accumulator: Callable) -> void:
	assert(accumulator.is_valid(), "scan.accumulator is not valid.")
	assert(accumulator.get_argument_count() == 2, "scan.accumulator must have exactly two arguments")

	_source = source
	_initial_value = initial_value
	_accumulator = accumulator


func _subscribe_core(observer: Callable) -> Disposable:
	assert(observer.is_valid(), "scan.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "scan.subscribe observer must have exactly one argument")

	var o := _ScanObserver.new(observer, _initial_value, _accumulator)
	return _source.subscribe(func(value: Variant) -> void: o._on_next_core(value))


class _ScanObserver extends RefCounted:
	var _observer: Callable
	var _accumulator: Callable
	var _current_value: Variant


	func _init(observer: Callable, initial_value: Variant, accumulator: Callable) -> void:
		_observer = observer
		_accumulator = accumulator
		_current_value = initial_value


	func _on_next_core(value: Variant) -> void:
		assert(_accumulator.is_valid(), "scan.accumulator is not valid.")

		# Apply accumulator to compute new value
		_current_value = _accumulator.call(_current_value, value)

		# Emit the accumulated value
		assert(_observer.is_valid(), "scan.observer (on_next callback) is not valid.")
		_observer.call(_current_value)
