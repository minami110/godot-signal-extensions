@abstract
class_name Observable
extends RefCounted
## Base abstract class for reactive programming in Godot.
##
## This class extends GDScript's [Signal] and [Callable] classes, influenced by [url=https://github.com/Cysharp/R3]Cysharp/R3[/url].
## The main purpose is to make it easier to unsubscribe from Godot signals and provides
## reactive stream operators for functional reactive programming.
##
## All observables implement the [Disposable] pattern for automatic cleanup.
## Use [method add_to] to automatically dispose when a [Node] exits the tree.

# Factory and operator imports
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


## Core subscription method for inheriting classes.
##
## This is an abstract method that must be implemented by all derived classes.
## It handles the actual subscription logic and returns a [Disposable] for cleanup.
##
## [param on_next]: The callback function to be invoked when values are emitted
## [br][b]Returns:[/b] A [Disposable] that can be used to unsubscribe
@abstract
func _subscribe_core(on_next: Callable) -> Disposable


## Subscribes to the [Observable] with a callback function.
##
## This method allows you to register a callback that will be invoked whenever
## the observable emits a value. The callback can accept either 0 or 1 parameters.
##
## Usage:
## [codeblock]
## var subscription := observable.subscribe(func(value): print(value))
## var subscription2 := observable.subscribe(func(): print("No value"))
## [/codeblock]
##
## [param on_next]: The callback function to be invoked on each emitted value
## [br][b]Returns:[/b] A [Disposable] that can be used to unsubscribe
## [br][b]Note:[/b] This method currently supports only the [code]on_next[/code] callback.
func subscribe(on_next: Callable) -> Disposable:
	assert(on_next.is_valid(), "Subject.subscribe observer is not valid.")
	assert(on_next.get_argument_count() <= 1, "")

	if on_next.get_argument_count() == 1:
		return _subscribe_core(on_next)
	else:
		return _subscribe_core(func(_x: Variant) -> void: on_next.call())


## Creates an [Observable] from a Godot [Signal].
##
## This factory method converts a standard Godot signal into an observable stream.
## It supports signals with 0 or 1 arguments. Signals with 0 arguments are
## converted to emit [member Unit.default].
##
## Usage:
## [codeblock]
## var button_observable := Observable.from_signal($Button.pressed)
## button_observable.subscribe(func(): print("Button pressed!"))
## [/codeblock]
##
## [param sig]: The Godot signal to convert to an observable
## [br][b]Returns:[/b] An [Observable] that emits when the signal is emitted
static func from_signal(sig: Signal) -> Observable:
	return FromSignal.new(sig)


## Merges multiple [Observable]s into a single observable stream.
##
## This factory method combines emissions from multiple observable sources
## into one observable. Values are emitted in the order they occur from any source.
##
## Usage:
## [codeblock]
## var s1 := Subject.new()
## var s2 := Subject.new()
## var merged := Observable.merge(s1, s2)
## merged.subscribe(func(x): print(x))
## [/codeblock]
##
## [param sources]: Variadic arguments of observables to merge
## [br][b]Returns:[/b] An [Observable] that emits values from all source observables
static func merge(...sources: Array) -> Observable:
	if sources.size() == 0:
		push_error("Observable.merge requires at least one source")
		return null

	if sources.size() == 1 and sources[0] is Array:
		var array_arg: Array = sources[0]
		if array_arg.size() == 0:
			push_error("Observable.merge requires at least one source")
			return null

		for source: Variant in array_arg:
			if not (source is Observable):
				push_error("All sources must be Observable instances")
				return null

		return Merge.new(array_arg)

	for source: Variant in sources:
		if not (source is Observable):
			push_error("All sources must be Observable instances")
			return null

	return Merge.new(sources)


## Only emit an item if a particular time span has passed without it emitting another item.
##
## This operator delays emissions and only emits the most recent item
## after the specified time period has elapsed without new emissions.
## Useful for handling rapid successive events like user input.
##
## Usage:
## [codeblock]
## subject.debounce(0.5).subscribe(func(x): print(x))
## [/codeblock]
##
## [param time_sec]: Time in seconds to wait after the last emission
## [br][b]Returns:[/b] An [Observable] that emits debounced values
func debounce(time_sec: float) -> Observable:
	assert(time_sec > 0.0, "time_sec must be greater than 0.0")

	return Debounce.new(self, time_sec)


## Emit the most recent items within periodic time intervals.
##
## This is an alias for [method throttle_last]. It samples the observable
## at regular intervals and emits the most recent value from each interval.
##
## [param time_sec]: Time interval in seconds for sampling
## [br][b]Returns:[/b] An [Observable] that emits sampled values
func sample(time_sec: float) -> Observable:
	return throttle_last(time_sec)


## Transform items by applying a function to each emitted value.
##
## This operator applies a transformation function to each value emitted
## by the source observable. Also known as "map" in other reactive libraries.
##
## Usage:
## [codeblock]
## subject.select(func(x): return x * 2).subscribe(func(x): print(x))
## [/codeblock]
##
## [param selector]: Function to transform each emitted value
## [br][b]Returns:[/b] An [Observable] that emits transformed values
func select(selector: Callable) -> Observable:
	if self is Select:
		var new_source: Observable = self._source
		return Select.new(new_source, func(x: Variant) -> Variant: return selector.call(self._selector.call(x)))
	else:
		return Select.new(self, selector)


## Suppress the first N items emitted by the observable.
##
## This operator ignores the first specified number of emissions
## and only starts emitting values after that count is reached.
##
## Usage:
## [codeblock]
## subject.skip(2).subscribe(func(x): print(x))
## [/codeblock]
##
## [param count]: Number of items to skip from the beginning
## [br][b]Returns:[/b] An [Observable] that skips the first N emissions
func skip(count: int) -> Observable:
	assert(count > 0, "count must be greater than 0")

	if self is Skip:
		var new_source: Observable = self._source
		var new_count: int = self._remaining + count
		return Skip.new(new_source, new_count)
	else:
		return Skip.new(self, count)


## Discard items until a predicate function returns false.
##
## This operator skips emissions while the predicate condition is true,
## then starts emitting all subsequent values regardless of the predicate.
##
## Usage:
## [codeblock]
## subject.skip_while(func(x): return x < 5).subscribe(func(x): print(x))
## [/codeblock]
##
## [param predicate]: Function that returns boolean to test each value
## [br][b]Returns:[/b] An [Observable] that skips values while predicate is true
func skip_while(predicate: Callable) -> Observable:
	# Note: no needed combine skip_while and skip_while
	return SkipWhile.new(self, predicate)


## Emit only the first N items, then complete.
##
## This operator emits only the first specified number of values
## from the source observable, then automatically disposes.
##
## Usage:
## [codeblock]
## subject.take(3).subscribe(func(x): print(x))
## [/codeblock]
##
## [param count]: Maximum number of items to emit
## [br][b]Returns:[/b] An [Observable] that emits at most N values
func take(count: int) -> Observable:
	assert(count > 0, "count must be greater than 0")

	if self is Take:
		var new_source: Observable = self._source
		var new_count: int = self._remaining + count
		return Take.new(new_source, new_count)
	else:
		return Take.new(self, count)


## Mirror items while a predicate function returns true.
##
## This operator emits values as long as the predicate condition is true.
## Once the predicate returns false, the observable completes.
##
## Usage:
## [codeblock]
## subject.take_while(func(x): return x < 10).subscribe(func(x): print(x))
## [/codeblock]
##
## [param predicate]: Function that returns boolean to test each value
## [br][b]Returns:[/b] An [Observable] that emits while predicate is true
func take_while(predicate: Callable) -> Observable:
	if self is TakeWhile:
		var new_source: Observable = self._source
		return TakeWhile.new(new_source, func(x: Variant) -> bool: return self._predicate.call(x) and predicate.call(x))
	else:
		return TakeWhile.new(self, predicate)


## Emit the most recent items within periodic time intervals.
##
## This operator samples the observable at regular time intervals
## and emits the most recently emitted value from each interval.
## Also available as [method sample].
##
## Usage:
## [codeblock]
## subject.throttle_last(0.1).subscribe(func(x): print(x))
## [/codeblock]
##
## [param time_sec]: Time interval in seconds for throttling
## [br][b]Returns:[/b] An [Observable] that emits throttled values
func throttle_last(time_sec: float) -> Observable:
	assert(time_sec > 0.0, "time_sec must be greater than 0.0")

	return ThrottleLast.new(self, time_sec)


## Emit only values that pass a predicate test.
##
## This operator filters the emitted values, only allowing through
## those that satisfy the given predicate condition. Also known as "filter".
##
## Usage:
## [codeblock]
## subject.where(func(x): return x > 0).subscribe(func(x): print(x))
## [/codeblock]
##
## [param predicate]: Function that returns boolean to test each value
## [br][b]Returns:[/b] An [Observable] that emits only filtered values
func where(predicate: Callable) -> Observable:
	if self is Where:
		var new_source: Observable = self._source
		return Where.new(new_source, func(x: Variant) -> bool: return self._predicate.call(x) and predicate.call(x))
	else:
		return Where.new(self, predicate)
