class_name ReactiveProperty
extends ReadOnlyReactiveProperty
## A reactive property that holds a value and notifies observers when it changes.
##
## ReactiveProperty extends [ReadOnlyReactiveProperty] to provide mutable value storage
## with automatic change notifications. It immediately emits the current value to new
## subscribers and can optionally check for equality before emitting changes.
##
## Usage:
## [codeblock]
## var health := ReactiveProperty.new(100)
## health.subscribe(func(value): print("Health: ", value))
## health.value = 50  # Triggers notification
## [/codeblock]

# Dependencies
const Subscription = preload("subscription.gd")

## Internal signal for value change notifications.
## @deprecated: This is an internal implementation detail and should not be used directly.
signal _on_next(value: Variant)

## Whether to check for equality before emitting changes.
var _check_equality: bool

## The current value of the reactive property.
##
## Setting this property will trigger notifications to all subscribers
## if the new value is different from the current value (when equality checking is enabled).
## Getting this property returns the current stored value.
##
## Usage:
## [codeblock]
## rp.value = 42        # Set new value
## var current = rp.value  # Get current value
## [/codeblock]
var value: Variant:
	get = _get_value, set = _set_value


## Creates a new ReactiveProperty with an initial value.
##
## The reactive property will store the initial value and emit it to new subscribers.
## Optionally, you can disable equality checking to force emission on every value assignment.
##
## Usage:
## [codeblock]
## var health := ReactiveProperty.new(100)      # With equality check
## var score := ReactiveProperty.new(0, false)  # Without equality check
## [/codeblock]
##
## [param initial_value]: The starting value for the property
## [param check_equality]: Whether to check equality before emitting (default: true)
func _init(initial_value: Variant = null, check_equality := true) -> void:
	_value = initial_value
	_check_equality = check_equality


func _to_string() -> String:
	return "%s:<ReactiveProperty#%d>" % [_value, get_instance_id()]


func _validate_property(property: Dictionary) -> void:
	# Do not serialize value and current_value properies
	if property.name == "value" or property.name == "current_value":
		property.usage &= ~(PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE)


## Core subscription implementation for ReactiveProperty.
##
## This method immediately calls the observer with the current value,
## then sets up a subscription for future value changes.
##
## [param observer]: The callback function to register
## [br][b]Returns:[/b] A [Disposable] subscription object
func _subscribe_core(observer: Callable) -> Disposable:
	if is_blocking_signals():
		return Disposable.empty

	assert(observer.is_valid(), "ReactiveProperty.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "ReactiveProperty.subscribe observer must have exactly one argument")

	observer.call(_value)
	return Subscription.new(_on_next, observer)


## Disposes the reactive property and disconnects all subscribers.
##
## This method cleans up all signal connections and marks the property
## as disposed. After disposal, the property will not emit any more changes
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


## Waits for the next value change asynchronously.
##
## This method allows you to await the next change to the property value,
## similar to awaiting a Godot signal. It's useful for reacting to future changes.
##
## Usage:
## [codeblock]
## var new_value := await rp.wait()
## print("Property changed to: ", new_value)
## [/codeblock]
##
## [br][b]Returns:[/b] The next changed value, or null if disposed
## [br][b]Note:[/b] If the property is disposed, this returns null immediately.
func wait() -> Variant:
	if is_blocking_signals():
		return null

	return await _on_next


## Adds this reactive property to a disposal container for automatic cleanup.
##
## This method allows automatic disposal when a [Node] exits the tree
## or when added to an [Array] for batch disposal.
##
## Usage:
## [codeblock]
## rp.add_to(self)  # Dispose when this node exits tree
## rp.add_to(disposal_bag)  # Add to disposal array
## [/codeblock]
##
## [param obj]: A [Node] or [Array] to handle disposal
## [br][b]Returns:[/b] This reactive property for method chaining
func add_to(obj: Variant) -> ReactiveProperty:
	Disposable.add_to_impl(self, obj)
	return self


func _get_value() -> Variant:
	return _value


func _set_value(new_value: Variant) -> void:
	if _check_equality and _test_equality(_value, new_value):
		return

	_value = new_value

	if not is_blocking_signals():
		_on_next.emit(new_value)


## Tests equality between two variants with proper null handling.
##
## This static method provides safe equality comparison that properly
## handles null values and type differences.
##
## [param a]: First value to compare
## [param b]: Second value to compare
## [br][b]Returns:[/b] True if the values are considered equal
static func _test_equality(a: Variant, b: Variant) -> bool:
	if a == null and b == null:
		return true

	if a == null or b == null:
		return false

	if typeof(a) != typeof(b):
		return false

	if a == b:
		return true

	return false
