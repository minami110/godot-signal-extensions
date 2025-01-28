class_name _ThrottleLast extends Observable

var _source: Observable
var _interval: float

func _init(source: Observable, interval: float) -> void:
	_source = source
	_interval = interval


func _subscribe_core(observer: Callable) -> Disposable:
	assert(observer.is_valid(), "select.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "select.subscribe observer must have exactly one argument")

	return _source.subscribe(func(value: Variant) -> void: _on_next_core(observer, value))

func _on_next_core(next: Callable, value: Variant) -> void:
	pass
