class_name _TakeWhile extends Observable

var _source: Observable
var _predicate: Callable
var _observer: Callable

func _init(source: Observable, predicate: Callable) -> void:
	assert(predicate.get_argument_count() == 1, "take_while.predicate must have exactly one argument")
	_source = source
	_predicate = predicate

func _subscribe_core(observer: Callable) -> Disposable:
	assert(observer.is_valid(), "take_while.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "take_while.subscribe observer must have exactly one argument")

	_observer = observer
	return _source.subscribe(func(value: Variant) -> void: _on_next_core(value))

func _on_next_core(value: Variant) -> void:
	# Already completed
	if not _predicate:
		print("Already Completed")
		return

	assert(_predicate.is_valid(), "take_while.predicate is not valid.")

	if _predicate.call(value):
		# OnNext
		assert(_observer.is_valid(), "take_while.observer (on_next callback) is not valid.")
		_observer.call(value)
	else:
		# OnCompleted
		_observer = Callable()
		_predicate = Callable()
