class_name _Where extends Observable

var _source: Observable
var _predicate: Callable
var _observer: Callable

func _init(source: Observable, predicate: Callable) -> void:
	_source = source
	_predicate = predicate

func _subscribe_core(observer: Callable) -> Disposable:
	_observer = observer
	return _source.subscribe(func(value: Variant) -> void: _on_next_core(value))

func _on_next_core(value: Variant) -> void:
	if _predicate.call(value):
		_observer.call(value)
