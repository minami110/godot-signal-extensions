class_name _FromSignal extends Observable

signal _on_next(value: Variant)
var _source_signal := Signal()
var _source_signal_arg_count: int

func _init(sig: Signal) -> void:
	# Check empty signal
	if not sig:
		push_error("Signal is null")
		set_block_signals(true)
		return

	# Check signal's argument count
	var signal_info := sig.get_object().get_signal_list().filter(func(info):
		return info.name == sig.get_name()
	)
	assert(signal_info.size() == 1)
	var sig_arg_count: int = signal_info[0]["args"].size()

	# Only 0 or 1 argument is allowed
	if sig_arg_count >= 2:
		push_error("signal should have 0 or 1 argument. %s has %d arguments" % [sig.get_name(), sig_arg_count])
		set_block_signals(true)
		return

	_source_signal_arg_count = sig_arg_count
	_source_signal = sig

	# When the signal has no argument, wrap it with a signal that emits Unit
	if _source_signal_arg_count == 0:
		_source_signal.connect(func() -> void: _on_next.emit(Unit.default))
	else:
		_source_signal.connect(func(x: Variant) -> void: _on_next.emit(x))

func _subscribe_core(observer: Callable) -> Disposable:
	if not _source_signal:
		return Disposable.empty
	else:
		return Subscription.new(_on_next, observer)

func dispose() -> void:
	if not _source_signal:
		return

	# Disconnect all signals
	var connections := get_signal_connection_list(&"_on_next")
	for c in connections:
		_on_next.disconnect(c.callable as Callable)

	# Disconnect this instance callable from the source signal
	if is_instance_id_valid(_source_signal.get_object_id()):
		for c in _source_signal.get_connections():
			var callable: Callable = c.callable
			if get_instance_id() == callable.get_object_id():
				_source_signal.disconnect(callable)

	_source_signal = Signal()
	set_block_signals(true)
