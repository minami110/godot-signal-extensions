class_name Observable extends Disposable


func subscribe(observer: Callable) -> Disposable:
	return _subscribe_core(observer)

func skip(count: int) -> Observable:
	assert(count > 0, "count must be greater than 0")

	if self is _Skip:
		self._remaining += count
		return self
	else:
		return _Skip.new(self, count)

func take(count: int) -> Observable:
	assert(count > 0, "count must be greater than 0")

	if self is _Take:
		self._remaining += count
		return self
	else:
		return _Take.new(self, count)

func where(predicate: Callable) -> Observable:
	if self is _Where:
		var old: Callable = self._predicate
		self._predicate = func(x): return old.call(x) and predicate.call(x)
		return self
	else:
		return _Where.new(self, predicate)

@warning_ignore("unused_parameter")
func _subscribe_core(observer: Callable) -> Disposable:
	return Disposable.empty
