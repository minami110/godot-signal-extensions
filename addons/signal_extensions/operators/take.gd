class_name _Take extends Observable

var _source: Observable
var _remaining: int
var _observer: Callable

func _init(source: Observable, count: int) -> void:
	assert(count > 0, "count must be greater than 0")
	_source = source
	_remaining = count

func _subscribe_core(observer: Callable) -> Disposable:
	_observer = observer
	return _source.subscribe(func(value: Variant) -> void: _on_next_core(value))

func _on_next_core(value: Variant) -> void:
	# Already completed
	if _remaining <= 0:
		return

	# OnNext
	_remaining -= 1
	assert(not _observer.is_valid(), "take.observer (on_next callback) is not valid.")
	_observer.call(value)

	if _remaining == 0:
		# OnCompleted
		_observer = Callable()
