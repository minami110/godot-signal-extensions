@abstract
class_name Observable extends RefCounted

const FromSignal = preload("factories/from_signal.gd")
const Merge = preload("factories/merge.gd")
const Debounce = preload("operators/debounce.gd")
const Select = preload("operators/select.gd")
const Skip = preload("operators/skip.gd")
const SkipWhile = preload("operators/skip_while.gd")
const Take = preload("operators/take.gd")
const TakeWhile = preload("operators/take_while.gd")
const ThrottleLast = preload("operators/throttle_last.gd")
const Where = preload("operators/where.gd")


## protected method for inheriting classes
@abstract
func _subscribe_core(on_next: Callable) -> Disposable

## Subscribes to the [Observable].[br]
## [b]Note:[/b] This method currently supports only the `on_next` callback.
func subscribe(on_next: Callable) -> Disposable:
	assert(on_next.is_valid(), "Subject.subscribe observer is not valid.")
	assert(on_next.get_argument_count() <= 1, "")

	if on_next.get_argument_count() == 1:
		return _subscribe_core(on_next)
	else:
		return _subscribe_core(func(_x: Variant) -> void: on_next.call())


#region Factories

## Creates an [Observable] from a [Signal].
static func from_signal(sig: Signal) -> Observable:
	return FromSignal.new(sig)

## Merges multiple [Observable]s into a single one.
static func merge(sources: Array[Observable]) -> Observable:
	return Merge.new(sources)

#endregion

#region Operators

## Only emit an item from an [Observable] if a particular [param time_sec] has passed without it emitting another item.
func debounce(time_sec: float) -> Observable:
	assert(time_sec > 0.0, "time_sec must be greater than 0.0")

	return Debounce.new(self, time_sec)

## Emit the most recent items emitted by an [Observable] within [param time_sec] intervals.[br]
## Alias for [method Observable.throttle_last]
func sample(time_sec: float) -> Observable:
	return throttle_last(time_sec)

## Transform the items emitted by an [Observable] by applying a [param selector] to each item.
func select(selector: Callable) -> Observable:
	if self is Select:
		var new_source: Observable = self._source
		return Select.new(new_source, func(x: Variant) -> Variant: return selector.call(self._selector.call(x)))
	else:
		return Select.new(self, selector)

## Discard items emitted by an [Observable] until a specified [param predicate] becomes [code]false[/code].
func skip_while(predicate: Callable) -> Observable:
	# Note: no needed combine skip_while and skip_while
	return SkipWhile.new(self, predicate)

## Suppress the first [param count] items by an [Observable].
func skip(count: int) -> Observable:
	assert(count > 0, "count must be greater than 0")

	if self is Skip:
		var new_source: Observable = self._source
		var new_count: int = self._remaining + count
		return Skip.new(new_source, new_count)
	else:
		return Skip.new(self, count)

## Mirror items emitted by an [Observable] until a specified [param predicate] becomes [code]false[/code].
func take_while(predicate: Callable) -> Observable:
	if self is TakeWhile:
		var new_source: Observable = self._source
		return TakeWhile.new(new_source, func(x: Variant) -> bool: return self._predicate.call(x) and predicate.call(x))
	else:
		return TakeWhile.new(self, predicate)

## Emit only the first [param count] items emitted by an [Observable].
func take(count: int) -> Observable:
	assert(count > 0, "count must be greater than 0")

	if self is Take:
		var new_source: Observable = self._source
		var new_count: int = self._remaining + count
		return Take.new(new_source, new_count)
	else:
		return Take.new(self, count)

## Emit the most recent items emitted by an [Observable] within [param time_sec] intervals
func throttle_last(time_sec: float) -> Observable:
	assert(time_sec > 0.0, "time_sec must be greater than 0.0")

	return ThrottleLast.new(self, time_sec)

## Emit only those items from an [Observable] that pass a [param predicate] test.
func where(predicate: Callable) -> Observable:
	if self is Where:
		var new_source: Observable = self._source
		return Where.new(new_source, func(x: Variant) -> bool: return self._predicate.call(x) and predicate.call(x))
	else:
		return Where.new(self, predicate)

#endregion
