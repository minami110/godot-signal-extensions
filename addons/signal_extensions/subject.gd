class_name Subject extends Observable

signal _on_next(new_value: Variant)

func on_next(value: Variant = null) -> void:
	if self.is_blocking_signals():
		return

	if value == null:
		_on_next.emit(Unit.default)
	else:
		_on_next.emit(value)

func _subscribe_core(observer: Callable) -> Disposable:
	if self.is_blocking_signals():
		return Disposable.empty
	else:
		return Subscription.new(_on_next, observer)

## Dispose the subject.
func dispose() -> void:
	if self.is_blocking_signals():
		return

	# Disconnect all signals
	var connections := self.get_signal_connection_list(&"_on_next")
	for c in connections:
		_on_next.disconnect(c.callable as Callable)

	self.set_block_signals(true)

## Wait for the next value emitted.[br]
## Usage:
## [codeblock]
## var value := await subject.wait()
## [/codeblock]
func wait() -> Variant:
	if self.is_blocking_signals():
		return null

	return await _on_next