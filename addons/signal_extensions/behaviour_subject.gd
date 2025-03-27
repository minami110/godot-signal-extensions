class_name BehaviourSubject extends Observable
### A variant of Subject that requires an initial value and emits its current value whenever it is subscribed to.

signal _on_next(value: Variant)

var _latest_value: Variant

func _to_string() -> String:
	return "<BehaviourSubject#%d>" % get_instance_id()


func _init(initial_value: Variant) -> void:
	_latest_value = initial_value

### The latest value of the subject (Read-only)
var value: Variant: get = _get_value


###
@warning_ignore("shadowed_variable")
func on_next(value: Variant = null) -> void:
	if is_blocking_signals():
		return

	_latest_value = value
	_on_next.emit(_latest_value)


func _get_value() -> Variant:
	return _latest_value

func _subscribe_core(observer: Callable) -> Disposable:
	if is_blocking_signals():
		return Disposable.empty

	assert(observer.is_valid(), "BehaviourSubject.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "BehaviourSubject.subscribe observer must have exactly one argument")

	observer.call(_latest_value)
	return Subscription.new(_on_next, observer)


## Dispose the subject.
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

## Wait for the next value emitted.[br]
## [b]Note:[/b] If disposed, it will return null[br]
## Usage:
## [codeblock]
## var value := await subject.wait()
## [/codeblock]
func wait() -> Variant:
	if is_blocking_signals():
		return null

	return await _on_next
