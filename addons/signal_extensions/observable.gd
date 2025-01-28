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

func skip_while(predicate: Callable) -> Observable:
	if self is _SkipWhile:
		var old: Callable = self._predicate
		self._predicate = func(x): return old.call(x) and predicate.call(x)
		return self
	else:
		return _SkipWhile.new(self, predicate)

## Skip the first `count` elements of the observable.
func skip(count: int) -> Observable:
	assert(count > 0, "count must be greater than 0")

	if self is _Skip:
		self._remaining += count
		return self
	else:
		return _Skip.new(self, count)

func take_while(predicate: Callable) -> Observable:
	if self is _TakeWhile:
		var old: Callable = self._predicate
		self._predicate = func(x): return old.call(x) and predicate.call(x)
		return self
	else:
		return _TakeWhile.new(self, predicate)

## Take the first `count` elements of the observable.
func take(count: int) -> Observable:
	assert(count > 0, "count must be greater than 0")

	if self is _Take:
		self._remaining += count
		return self
	else:
		return _Take.new(self, count)

## Filters the observable.
func where(predicate: Callable) -> Observable:
	if self is _Where:
		var old: Callable = self._predicate
		self._predicate = func(x): return old.call(x) and predicate.call(x)
		return self
	else:
		return _Where.new(self, predicate)

#endregion
