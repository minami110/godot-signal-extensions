class_name _SkipWhile extends Observable

var _source: Observable
var _predicate: Callable
var _observer: Callable

func _init(source: Observable, predicate: Callable) -> void:
	assert(predicate.is_valid(), "skip_while.predicate is not valid.")
	assert(predicate.get_argument_count() == 1, "skip_while.predicate must have exactly one argument")

	_source = source
	_predicate = predicate

func _subscribe_core(observer: Callable) -> Disposable:
	assert(observer.is_valid(), "skip_while.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "skip_while.subscribe observer must have exactly one argument")

	_observer = observer
	return _source.subscribe(func(value: Variant) -> void: _on_next_core(value))

func _on_next_core(value: Variant) -> void:
	# Already opened
	if not _predicate:
		# OnNext
		assert(_observer.is_valid(), "skip_while.observer (on_next callback) is not valid.")
		_observer.call(value)
		return

	# check open
	assert(_predicate.is_valid(), "skip_while.predicate is not valid.")
	if not _predicate.call(value):
		# Set empty callable this will skip the predicate check
		_predicate = Callable()

		# OnNext
		assert(_observer.is_valid(), "skip_while.observer (on_next callback) is not valid.")
		_observer.call(value)
