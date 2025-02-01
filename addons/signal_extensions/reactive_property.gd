class_name ReactiveProperty extends Observable

var _value: Variant
var _check_equality: bool
signal _on_next(value: Variant)

func _to_string() -> String:
	return "%s:<ReactiveProperty#%d>" % [_value, get_instance_id()]

## Create a new reactive property.[br]
## Usage:
## [codeblock]
## var rp1 := ReactiveProperty.new(1)
## var rp2 := ReactiveProperty.new(1, false) # Disable equality check
## [/codeblock]
func _init(initial_value: Variant, check_equality := true) -> void:
	if initial_value == null:
		push_error("initial_value should not be null.")
		set_block_signals(true)
		return

	_value = initial_value
	_check_equality = check_equality

func _get_value() -> Variant:
	return _value

func _set_value(new_value: Variant) -> void:
	if _check_equality and _value == new_value:
		return

	_value = new_value

	if not is_blocking_signals():
		_on_next.emit(new_value)

## The current value of the property.
var value: Variant: get = _get_value, set = _set_value

func _subscribe_core(observer: Callable) -> Disposable:
	if is_blocking_signals():
		return Disposable.empty
	else:
		assert(observer.is_valid(), "ReactiveProperty.subscribe observer is not valid.")
		assert(observer.get_argument_count() == 1, "ReactiveProperty.subscribe observer must have exactly one argument")

		observer.call(_value)
		return Subscription.new(_on_next, observer)

## Dispose of the property.
func dispose() -> void:
	if is_blocking_signals():
		return

	# Disconnect all signals
	var connections := get_signal_connection_list(&"_on_next")
	for c in connections:
		_on_next.disconnect(c.callable as Callable)

	set_block_signals(true)

## Wait for the next value changed.[br]
## [b]Note:[/b] If disposed, it will return null[br]
## Usage:
## [codeblock]
## var value := await rp.wait()
## [/codeblock]
func wait() -> Variant:
	if is_blocking_signals():
		return null

	return await _on_next
