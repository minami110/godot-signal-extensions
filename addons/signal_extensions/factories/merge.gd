extends Observable

var _sources: Array[Observable] = []
var _observer: Callable


func _init(sources: Array[Observable]) -> void:
	assert(sources.size() > 0, "Sources array cannot be empty")
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


func wait() -> Variant:
	return await _MergePromise.any(_sources)


class _MergeDisposable extends Disposable:
	var _disposables: Array[Disposable] = []


	func dispose() -> void:
		for disposable in _disposables:
			disposable.dispose()
		_disposables = []


class _MergePromise extends RefCounted:
	signal _any_signal_emitted(v: Variant)


	static func any(sources: Array[Observable]) -> Variant:
		assert(sources.size() > 0, "Empty sources")
		return await _MergePromise.new()._any_async(sources)


	func _any_async(sources: Array[Observable]) -> Variant:
		var bag: Array[Disposable] = []

		for source in sources:
			source.subscribe(
				func(x: Variant) -> void:
					_any_signal_emitted.emit(x)
			).add_to(bag)

		var result: Variant = await _any_signal_emitted
		for d in bag:
			d.dispose()
		bag.clear()

		return result
