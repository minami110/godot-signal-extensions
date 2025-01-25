class_name _Skip extends Observable

var _source: Observable
var _remaining: int
var _observer: Callable

func _init(source: Observable, count: int) -> void:
	_source = source
	_remaining = count

func _subscribe_core(observer: Callable) -> Disposable:
	_observer = observer
	return _source.subscribe(func(value: Variant) -> void: _on_next_core(value))

func _on_next_core(value: Variant) -> void:
	if _remaining > 0:
		_remaining -= 1
	else:
		_observer.call(value)
