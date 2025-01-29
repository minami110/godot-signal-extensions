class_name Observable extends Disposable


## Subscribes to the [Observable].[br]
## [b]Note:[/b] This method currently supports only the `on_next` callback.
func subscribe(on_next: Callable) -> Disposable:
	return _subscribe_core(on_next)

## protected method for inheriting classes
@warning_ignore("unused_parameter")
func _subscribe_core(on_next: Callable) -> Disposable:
	return Disposable.empty

#region Factories

## Creates an [Observable] from a [Signal].
static func from_signal(sig: Signal) -> Observable:
	return _FromSignal.new(sig)

## Merges multiple [Observable]s into a single one.
static func merge(sources: Array[Observable]) -> Observable:
	return _Merge.new(sources)

#endregion

#region Operators

## Only emit an item from an [Observable] if a particular [param time_sec] has passed without it emitting another item.
func debounce(time_sec: float) -> Observable:
	assert(time_sec > 0.0, "time_sec must be greater than 0.0")

	return _Debounce.new(self, time_sec)

## Emit the most recent items emitted by an [Observable] within [param time_sec] intervals.[br]
## Alias for [method Observable.throttle_last]
func sample(time_sec: float) -> Observable:
	return throttle_last(time_sec)

## Transform the items emitted by an [Observable] by applying a [param selector] to each item.
func select(selector: Callable) -> Observable:
	if self is _Select:
		return _Select.new(self._source, func(x): return selector.call(self._selector.call(x)))
	else:
		return _Select.new(self, selector)

## Discard items emitted by an [Observable] until a specified [param predicate] becomes [code]false[/code].
func skip_while(predicate: Callable) -> Observable:
	# Note: no needed combine skip_while and skip_while
	return _SkipWhile.new(self, predicate)

## Suppress the first [param count] items by an [Observable].
func skip(count: int) -> Observable:
	assert(count > 0, "count must be greater than 0")

	if self is _Skip:
		return _Skip.new(self._source, self._remaining + count)
	else:
		return _Skip.new(self, count)

## Mirror items emitted by an [Observable] until a specified [param predicate] becomes [code]false[/code].
func take_while(predicate: Callable) -> Observable:
	if self is _TakeWhile:
		return _TakeWhile.new(self._source, func(x): return self._predicate.call(x) and predicate.call(x))
	else:
		return _TakeWhile.new(self, predicate)

## Emit only the first [param count] items emitted by an [Observable].
func take(count: int) -> Observable:
	assert(count > 0, "count must be greater than 0")

	if self is _Take:
		return _Take.new(self._source, self._remaining + count)
	else:
		return _Take.new(self, count)

## Emit the most recent items emitted by an [Observable] within [param time_sec] intervals
func throttle_last(time_sec: float) -> Observable:
	assert(time_sec > 0.0, "time_sec must be greater than 0.0")

	return _ThrottleLast.new(self, time_sec)

## Emit only those items from an [Observable] that pass a [param predicate] test.
func where(predicate: Callable) -> Observable:
	if self is _Where:
		return _Where.new(self._source, func(x): return self._predicate.call(x) and predicate.call(x))
	else:
		return _Where.new(self, predicate)

#endregion
