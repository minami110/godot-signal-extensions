extends Observable

var _source: Observable
var _other: Observable


func _init(source: Observable, other: Observable) -> void:
	assert(source != null, "take_until.source is not valid.")
	assert(other != null, "take_until.other is not valid.")

	_source = source
	_other = other


func _subscribe_core(observer: Callable) -> Disposable:
	assert(observer.is_valid(), "take_until.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "take_until.subscribe observer must have exactly one argument")

	var o := _TakeUntilObserver.new(observer)

	# Subscribe to the source observable
	var source_subscription := _source.subscribe(func(value: Variant) -> void: o._on_source_next(value))

	# Subscribe to the other observable to detect stop signal
	var other_subscription := _other.subscribe(func(_value: Variant) -> void: o._on_other_next())

	# Return a disposable that disposes both subscriptions
	return _TakeUntilDisposable.new(source_subscription, other_subscription)


class _TakeUntilObserver extends RefCounted:
	var _observer: Callable
	var _is_completed: bool = false


	func _init(observer: Callable) -> void:
		_observer = observer


	func _on_source_next(value: Variant) -> void:
		# Ignore if already completed
		if _is_completed:
			return

		assert(_observer.is_valid(), "take_until.observer (on_next callback) is not valid.")
		_observer.call(value)


	func _on_other_next() -> void:
		# Mark as completed when other observable emits
		_is_completed = true


class _TakeUntilDisposable extends Disposable:
	var _source_subscription: Disposable
	var _other_subscription: Disposable


	func _init(source_subscription: Disposable, other_subscription: Disposable) -> void:
		_source_subscription = source_subscription
		_other_subscription = other_subscription


	func dispose() -> void:
		if _source_subscription:
			_source_subscription.dispose()
		if _other_subscription:
			_other_subscription.dispose()
		_source_subscription = null
		_other_subscription = null
