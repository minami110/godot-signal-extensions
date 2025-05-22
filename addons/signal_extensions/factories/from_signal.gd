class_name _FromSignal extends Observable

signal _on_next(value: Variant)
var _source_signal := Signal()

func _init(sig: Signal) -> void:
	# Check empty signal
	if not sig:
		push_error("Signal is null")
		set_block_signals(true)
		return

	# Check signal's argument count
	var signal_info := sig.get_object().get_signal_list().filter(func(info: Dictionary) -> bool:
		return info.name == sig.get_name()
	)
	assert(signal_info.size() == 1)

	var sig_arg_count: int = signal_info[0]["args"].size()
	_source_signal = sig

	if sig_arg_count == 0:
		_source_signal.connect(func() -> void: _on_next.emit(Unit.default))
	elif sig_arg_count == 1:
		_source_signal.connect(func(value: Variant) -> void: _on_next.emit(value))
	elif sig_arg_count == 2:
		_source_signal.connect(func(value1: Variant, value2: Variant) -> void: _on_next.emit([value1, value2]))
	elif sig_arg_count == 3:
		_source_signal.connect(func(value1: Variant, value2: Variant, value3: Variant) -> void: _on_next.emit([value1, value2, value3]))
	elif sig_arg_count == 4:
		_source_signal.connect(func(value1: Variant, value2: Variant, value3: Variant, value4: Variant) -> void: _on_next.emit([value1, value2, value3, value4]))
	elif sig_arg_count == 5:
		_source_signal.connect(func(value1: Variant, value2: Variant, value3: Variant, value4: Variant, value5: Variant) -> void: _on_next.emit([value1, value2, value3, value4, value5]))
	elif sig_arg_count == 6:
		_source_signal.connect(func(value1: Variant, value2: Variant, value3: Variant, value4: Variant, value5: Variant, value6: Variant) -> void: _on_next.emit([value1, value2, value3, value4, value5, value6]))
	elif sig_arg_count == 7:
		_source_signal.connect(func(value1: Variant, value2: Variant, value3: Variant, value4: Variant, value5: Variant, value6: Variant, value7: Variant) -> void: _on_next.emit([value1, value2, value3, value4, value5, value6, value7]))
	elif sig_arg_count == 8:
		_source_signal.connect(func(value1: Variant, value2: Variant, value3: Variant, value4: Variant, value5: Variant, value6: Variant, value7: Variant, value8: Variant) -> void: _on_next.emit([value1, value2, value3, value4, value5, value6, value7, value8]))
	else:
		set_block_signals(true)
		assert(false, "Signal has too many arguments. Max 8 arguments are supported.")


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
		var callable: Callable = c.callable
		_on_next.disconnect(callable)

	# Disconnect this instance callable from the source signal
	if is_instance_id_valid(_source_signal.get_object_id()):
		for c: Dictionary in _source_signal.get_connections():
			var callable: Callable = c.callable
			if get_instance_id() == callable.get_object_id():
				_source_signal.disconnect(callable)

	_source_signal = Signal()
	set_block_signals(true)
