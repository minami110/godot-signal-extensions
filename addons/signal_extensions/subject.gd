class_name Subject
extends Observable
## A basic implementation of the Observer pattern for reactive programming.
##
## Subject acts as both an observable and an observer. It can emit values
## to multiple subscribers and allows manual control over when values are emitted.
## Unlike [ReactiveProperty], it does not hold a current value.
##
## Usage:
## [codeblock]
## var subject := Subject.new()
## var subscription := subject.subscribe(func(x): print(x))
## subject.on_next("Hello World")
## subscription.dispose() # Unsubscribe
## [/codeblock]

# Dependencies
const Subscription = preload("subscription.gd")

## Internal signal for value emission.
## @deprecated: This is an internal implementation detail and should not be used directly.
signal _on_next(value: Variant)


# Built-in overrides
func _to_string() -> String:
	return "<Subject#%d>" % get_instance_id()


## Core subscription implementation for Subject.
##
## This method handles the subscription logic by connecting the observer
## to the internal signal. Returns a subscription object for cleanup.
##
## [param observer]: The callback function to register
## [br][b]Returns:[/b] A [Disposable] subscription object
func _subscribe_core(observer: Callable) -> Disposable:
	if is_blocking_signals():
		return Disposable.empty

	assert(observer.is_valid(), "Subject.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "Subject.subscribe observer must have exactly one argument")
	return Subscription.new(_on_next, observer)


## Emits a value to all subscribed observers.
##
## This method notifies all subscribed observers with the provided value.
## If no value is provided, it will emit [member Unit.default] instead.
##
## Usage:
## [codeblock]
## subject.on_next(42)          # Emit the number 42
## subject.on_next("hello")     # Emit a string
## subject.on_next()            # Emit Unit.default
## [/codeblock]
##
## [param value]: The value to emit to subscribers (optional)
## [br][b]Note:[/b] If the subject is disposed, no value will be emitted.
func on_next(value: Variant = null) -> void:
	if is_blocking_signals():
		return

	if value == null:
		_on_next.emit(Unit.default)
	else:
		_on_next.emit(value)


## Disposes the subject and disconnects all subscribers.
##
## This method cleans up all signal connections and marks the subject
## as disposed. After disposal, the subject will not emit any more values
## and [method wait] will return null immediately.
##
## [b]Note:[/b] This operation is irreversible.
func dispose() -> void:
	if is_blocking_signals():
		return

	# Disconnect all signals
	var connections := get_signal_connection_list(&"_on_next")
	for c in connections:
		var callable: Callable = c.callable
		_on_next.disconnect(callable)

	set_block_signals(true)


## Waits for the next value to be emitted asynchronously.
##
## This method allows you to await the next emission from the subject,
## similar to awaiting a Godot signal. It's useful for one-time value retrieval.
##
## Usage:
## [codeblock]
## var next_value := await subject.wait()
## print("Received: ", next_value)
## [/codeblock]
##
## [br][b]Returns:[/b] The next emitted value, or null if disposed
## [br][b]Note:[/b] If the subject is disposed, this returns null immediately.
func wait() -> Variant:
	if is_blocking_signals():
		return null

	return await _on_next


## Adds this subject to a disposal container for automatic cleanup.
##
## This method allows automatic disposal when a [Node] exits the tree
## or when added to an [Array] for batch disposal.
##
## Usage:
## [codeblock]
## subject.add_to(self)  # Dispose when this node exits tree
## subject.add_to(disposal_bag)  # Add to disposal array
## [/codeblock]
##
## [param obj]: A [Node] or [Array] to handle disposal
## [br][b]Returns:[/b] This subject for method chaining
func add_to(obj: Variant) -> Subject:
	Disposable.add_to_impl(self, obj)
	return self
