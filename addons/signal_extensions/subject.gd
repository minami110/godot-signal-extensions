class_name Subject extends Observable

signal _on_next(value: Variant)

func _to_string() -> String:
	return "<Subject#%d>" % get_instance_id()

## Notifies all subscribed callables with the value.[br]
## If the [param value] is not provided, it will emit [member Unit.default].[br]
## [b]Note:[/b] If disposed, it will not emit any value.
func on_next(value: Variant = null) -> void:
	if is_blocking_signals():
		return

	if value == null:
		_on_next.emit(Unit.default)
	else:
		_on_next.emit(value)

func _subscribe_core(observer: Callable) -> Disposable:
	if is_blocking_signals():
		return Disposable.empty
	else:
		assert(observer.is_valid(), "Subject.subscribe observer is not valid.")
		assert(observer.get_argument_count() == 1, "Subject.subscribe observer must have exactly one argument")

		return Subscription.new(_on_next, observer)

## Dispose the subject.
func dispose() -> void:
	if is_blocking_signals():
		return

	# Disconnect all signals
	var connections := get_signal_connection_list(&"_on_next")
	for c in connections:
		_on_next.disconnect(c.callable as Callable)

	set_block_signals(true)

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
