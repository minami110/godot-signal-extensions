class_name _Skip extends Observable

var _source: Observable
var _remaining: int

func _init(source: Observable, count: int) -> void:
	assert(count > 0, "skip.count must be greater than 0")
	_source = source
	_remaining = count

func _subscribe_core(observer: Callable) -> Disposable:
	assert(observer.is_valid(), "skip.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "skip.subscribe observer must have exactly one argument")

	var o := _SkipObserver.new(observer, _remaining)
	return _source.subscribe(func(value: Variant) -> void: o._on_next_core(value))

class _SkipObserver extends RefCounted:
	var _observer: Callable
	var _remaining: int

	func _init(observer: Callable, remaining: int) -> void:
		_observer = observer
		_remaining = remaining

	func _on_next_core(value: Variant) -> void:
		if _remaining > 0:
			_remaining -= 1
		else:
			# OnNext
			assert(_observer.is_valid(), "skip.observer (on_next callback) is not valid.")
			_observer.call(value)
