class_name _Merge extends Observable

var _sources: Array[Observable] = []
var _observer: Callable

func _init(sources: Array[Observable]) -> void:
	_sources = sources

func _subscribe_core(observer: Callable) -> Disposable:
	_observer = observer

	var merge_disposables := _MergeDisposable.new()
	for item in _sources:
		item.subscribe(func(value: Variant) -> void: _on_next_core(value)) \
			.add_to(merge_disposables._disposables)

	merge_disposables._disposables.make_read_only()
	return merge_disposables

func _on_next_core(value: Variant) -> void:
	_observer.call(value)


class _MergeDisposable extends Disposable:
	var _disposables: Array[Disposable] = []

	func dispose() -> void:
		for disposable in _disposables:
			disposable.dispose()
		_disposables = []
