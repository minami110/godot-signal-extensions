class_name BehaviourSubject extends Observable
## A variant of Subject that requires an initial value and emits its current value whenever it is subscribed to.
##
## BehaviourSubject maintains the latest emitted value and immediately provides it to new subscribers.
## This is useful when you need to ensure that observers always receive the most recent state,
## even if they subscribe after the value was emitted.
##
## Usage:
## [codeblock]
## var status := BehaviourSubject.new("idle")
## status.subscribe(func(value): print("Status: ", value))  # Immediately prints "idle"
## status.on_next("loading")  # All subscribers receive "loading"
## [/codeblock]

const Subscription = preload("subscription.gd")

signal _on_next(value: Variant)

var _latest_value: Variant

## The latest value held by the subject (read-only).
##
## This property provides access to the current value without subscribing.
## It's useful for getting the current state synchronously.
##
## Usage:
## [codeblock]
## var current_status = status_subject.value
## print("Current status: ", current_status)
## [/codeblock]
var value: Variant: get = _get_value

## Creates a new BehaviourSubject with an initial value.
##
## The initial value will be stored and emitted to any new subscribers.
## Unlike [Subject], BehaviourSubject requires an initial value.
##
## [param initial_value]: The value to store and emit to new subscribers
func _init(initial_value: Variant = null) -> void:
	_latest_value = initial_value

func _to_string() -> String:
	return "<BehaviourSubject#%d>" % get_instance_id()

func _validate_property(property: Dictionary) -> void:
	# Do not serialize value and current_value properies
	if property.name == "value":
		property.usage &= ~(PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE)


## Core subscription implementation for BehaviourSubject.
##
## This method immediately calls the observer with the current value,
## then sets up a subscription for future value changes. This ensures
## that new subscribers always receive the latest state.
##
## [param observer]: The callback function to register
## [br][b]Returns:[/b] A [Disposable] subscription object
func _subscribe_core(observer: Callable) -> Disposable:
	if is_blocking_signals():
		return Disposable.empty

	assert(observer.is_valid(), "BehaviourSubject.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "BehaviourSubject.subscribe observer must have exactly one argument")

	observer.call(_latest_value)
	return Subscription.new(_on_next, observer)


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
func add_to(obj: Variant) -> BehaviourSubject:
	Disposable.add_to_impl(self, obj)
	return self

## Disposes the subject and disconnects all subscribers.
##
## This method cleans up all signal connections, clears the stored value,
## and marks the subject as disposed. After disposal, the subject will not
## emit any more values and [method wait] will return null immediately.
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
	_latest_value = null

## Emits a new value to all subscribers and updates the stored value.
##
## This method updates the internal value storage and notifies all
## current subscribers. New subscribers will receive this value when they subscribe.
##
## Usage:
## [codeblock]
## subject.on_next("new_status")  # Updates value and notifies subscribers
## [/codeblock]
##
## [param value]: The new value to store and emit
## [br][b]Note:[/b] If the subject is disposed, no value will be emitted.
@warning_ignore("shadowed_variable")
func on_next(value: Variant = null) -> void:
	if is_blocking_signals():
		return

	_latest_value = value
	_on_next.emit(_latest_value)

## Waits for the next value to be emitted asynchronously.
##
## This method allows you to await the next emission from the subject,
## similar to awaiting a Godot signal. Note that this waits for the NEXT
## emission, not the current value (use [member value] for that).
##
## Usage:
## [codeblock]
## var next_value := await subject.wait()
## print("Next value: ", next_value)
## [/codeblock]
##
## [br][b]Returns:[/b] The next emitted value, or null if disposed
## [br][b]Note:[/b] If the subject is disposed, this returns null immediately.
func wait() -> Variant:
	if is_blocking_signals():
		return null

	return await _on_next

# Private implementation methods
func _get_value() -> Variant:
	return _latest_value
