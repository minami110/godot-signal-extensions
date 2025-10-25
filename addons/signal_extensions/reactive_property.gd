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
## By default, the property only emits changes when the new value differs from the current value.
## You can customize this behavior by overriding [method _should_update] or [method _transform_value].
##
## Usage:
## [codeblock]
## var health := ReactiveProperty.new(100)
##
## # Transform values before storage
## class BoundedHP extends ReactiveProperty:
##     var min_value: float
##     var max_value: float
##
##     func _init(initial: float, min_val: float, max_val: float) -> void:
##         min_value = min_val
##         max_value = max_val
##         super._init(initial)
##
##     func _transform_value(input_value: Variant) -> Variant:
##         return clampf(input_value, min_value, max_value)
##
## # Validate without transformation
## class ValidatedHP extends ReactiveProperty:
##     func _should_update(old_value, new_value) -> bool:
##         if new_value < 0 or new_value > 100:
##             return false  # Reject out-of-range values
##         return old_value != new_value
## [/codeblock]
##
## [param initial_value]: The starting value for the property
func _init(initial_value: Variant = null) -> void:
	_value = _transform_value(initial_value)


func _to_string() -> String:
	return "%s:<ReactiveProperty#%d>" % [_value, get_instance_id()]


func _validate_property(property: Dictionary) -> void:
	# Do not serialize value and current_value properies
	if property.name == "value" or property.name == "current_value":
		property.usage &= ~(PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE)


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


## Transforms a value before it is stored and emitted.
##
## Override this method to implement custom value transformation logic.
## This method is called before [method _should_update], allowing you to
## normalize, clamp, or otherwise modify values before they are stored.
##
## The transformation happens in this order:
## 1. [method _transform_value] converts the input value
## 2. [method _should_update] checks if the transformed value should be stored
## 3. If update is allowed, the transformed value is stored and emitted
##
## Usage:
## [codeblock]
## # Always clamp values to a range
## class BoundedHP extends ReactiveProperty:
##     var min_value: float = 0.0
##     var max_value: float = 100.0
##
##     func _transform_value(input_value: Variant) -> Variant:
##         return clampf(input_value, min_value, max_value)
##
## # Normalize strings
## class TrimmedString extends ReactiveProperty:
##     func _transform_value(input_value: Variant) -> Variant:
##         if input_value is String:
##             return input_value.strip_edges()
##         return input_value
## [/codeblock]
##
## [param input_value]: The input value to transform
## [br][b]Returns:[/b] The transformed value
func _transform_value(input_value: Variant) -> Variant:
	return input_value


## Determines whether the value should be updated.
##
## Override this method to implement custom validation or change detection logic.
## By default, this method returns true only when the new value differs from
## the current value (equality check).
##
## [b]Note:[/b] The [param new_value] parameter is the result of [method _transform_value].
## If you need to modify values before storage, override [method _transform_value] instead.
## Use this method only for validation or update condition logic.
##
## The value update process:
## 1. [method _transform_value] transforms the input value
## 2. [method _should_update] checks if the transformed value should be stored (← This method)
## 3. If this returns true, the transformed value is stored and emitted
##
## Usage:
## [codeblock]
## # Always update (similar to old check_equality=false)
## class AlwaysUpdateRP extends ReactiveProperty:
##     func _should_update(old_value, new_value) -> bool:
##         return true
##
## # Reject out-of-range values
## class ValidatedRP extends ReactiveProperty:
##     func _should_update(old_value, new_value) -> bool:
##         if new_value < 0 or new_value > 100:
##             return false  # Reject invalid values
##         return old_value != new_value
##
## # Combine transformation and validation
## class BoundedHP extends ReactiveProperty:
##     func _transform_value(input_value: Variant) -> Variant:
##         return clampf(input_value, 0.0, 100.0)  # Always clamp
##
##     # _should_update uses default behavior (equality check)
## [/codeblock]
##
## [param old_value]: The current value
## [param new_value]: The transformed value (result of [method _transform_value])
## [br][b]Returns:[/b] True if the value should be updated, false otherwise
func _should_update(old_value: Variant, new_value: Variant) -> bool:
	return not _are_equal(old_value, new_value)


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


func _get_value() -> Variant:
	return _value


func _set_value(new_value: Variant) -> void:
	var transformed_value: Variant = _transform_value(new_value)
	if not _should_update(_value, transformed_value):
		return

	_value = transformed_value

	if not is_blocking_signals():
		_on_next.emit(transformed_value)


## Tests equality between two variants with proper null handling.
##
## This private method provides safe equality comparison that properly
## handles null values and type differences. Used internally by [method _should_update].
##
## [param a]: First value to compare
## [param b]: Second value to compare
## [br][b]Returns:[/b] True if the values are considered equal
static func _are_equal(a: Variant, b: Variant) -> bool:
	if a == null and b == null:
		return true

	if a == null or b == null:
		return false

	if typeof(a) != typeof(b):
		return false

	if a == b:
		return true

	return false
