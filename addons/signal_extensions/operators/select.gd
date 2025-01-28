class_name _Select extends Observable

var _source: Observable
var _selector: Callable

func _init(source: Observable, selector: Callable) -> void:
	assert(selector.is_valid(), "select.selector is not valid.")
	assert(selector.get_argument_count() == 1, "select.selector must have exactly one argument")

	_source = source
	_selector = selector


func _subscribe_core(observer: Callable) -> Disposable:
	assert(observer.is_valid(), "select.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "select.subscribe observer must have exactly one argument")

	return _source.subscribe(func(value: Variant) -> void: _on_next_core(observer, _selector, value))

static func _on_next_core(next: Callable, selector: Callable, value: Variant) -> void:
	assert(selector.is_valid(), "select.selector is not valid.")
	assert(next.is_valid(), "select.observer (next callback) is not valid.")

	# OnNext
	next.call(selector.call(value))
