@abstract
class_name CustomReactiveProperty
extends ReactiveProperty
## A customizable reactive property base class for advanced use cases.
##
## CustomReactiveProperty provides extension points for custom value transformation
## and update logic. Use this as a base class when you need to:
## - Transform values before storage (via [method _transform_value])
## - Customize update conditions (via [method _should_update])
##
## For simple reactive properties with standard equality checking, use [ReactiveProperty] instead.
##
## Usage:
## [codeblock]
## # Transform values before storage
## class BoundedHP extends CustomReactiveProperty:
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
## class ValidatedHP extends CustomReactiveProperty:
##     func _should_update(old_value, new_value) -> bool:
##         if new_value < 0 or new_value > 100:
##             return false  # Reject out-of-range values
##         return old_value != new_value
## [/codeblock]

func _init(initial_value: Variant = null) -> void:
	_value = _transform_value(initial_value)


func _set_value(new_value: Variant) -> void:
	var transformed_value: Variant = _transform_value(new_value)
	if not _should_update(_value, transformed_value):
		return

	_value = transformed_value

	if not is_blocking_signals():
		_on_next.emit(transformed_value)

#region Protected virtual methods

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
## class BoundedHP extends CustomReactiveProperty:
##     var min_value: float = 0.0
##     var max_value: float = 100.0
##
##     func _transform_value(input_value: Variant) -> Variant:
##         return clampf(input_value, min_value, max_value)
##
## # Normalize strings
## class TrimmedString extends CustomReactiveProperty:
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
## # Always update (disable equality check)
## class AlwaysUpdateRP extends CustomReactiveProperty:
##     func _should_update(old_value, new_value) -> bool:
##         return true
##
## # Reject out-of-range values
## class ValidatedRP extends CustomReactiveProperty:
##     func _should_update(old_value, new_value) -> bool:
##         if new_value < 0 or new_value > 100:
##             return false  # Reject invalid values
##         return old_value != new_value
##
## # Combine transformation and validation
## class BoundedHP extends CustomReactiveProperty:
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

#endregion
