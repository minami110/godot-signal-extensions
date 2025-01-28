class_name Observable extends Disposable


## Subscribes to the observable.
func subscribe(observer: Callable) -> Disposable:
	return _subscribe_core(observer)

@warning_ignore("unused_parameter")
func _subscribe_core(observer: Callable) -> Disposable:
	return Disposable.empty

#region Factories

## Creates an observable from a signal.
static func from_signal(sig: Signal) -> Observable:
	return _FromSignal.new(sig)

## Merges multiple observables into a single observable.
static func merge(sources: Array[Observable]) -> Observable:
	return _Merge.new(sources)

#endregion

#region Operators

func select(selector: Callable) -> Observable:
	if self is _Select:
		return _Select.new(self._source, func(x): return selector.call(self._selector.call(x)))
	else:
		return _Select.new(self, selector)

func skip_while(predicate: Callable) -> Observable:
	# Note: no needed combine skip_while and skip_while
	return _SkipWhile.new(self, predicate)

## Skip the first `count` elements of the observable.
func skip(count: int) -> Observable:
	assert(count > 0, "count must be greater than 0")

	if self is _Skip:
		return _Skip.new(self._source, self._remaining + count)
	else:
		return _Skip.new(self, count)

func take_while(predicate: Callable) -> Observable:
	if self is _TakeWhile:
		return _TakeWhile.new(self._source, func(x): return self._predicate.call(x) or predicate.call(x))
	else:
		return _TakeWhile.new(self, predicate)

## Take the first `count` elements of the observable.
func take(count: int) -> Observable:
	assert(count > 0, "count must be greater than 0")

	if self is _Take:
		return _Take.new(self._source, self._remaining + count)
	else:
		return _Take.new(self, count)

## Filters the observable.
func where(predicate: Callable) -> Observable:
	if self is _Where:
		return _Where.new(self._source, func(x): return self._predicate.call(x) and predicate.call(x))
	else:
		return _Where.new(self, predicate)

#endregion
