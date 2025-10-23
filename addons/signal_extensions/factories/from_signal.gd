extends Observable

const Subscription = preload("../subscription.gd")

signal _on_next(value: Variant)
var _source_signal := Signal()


func _init(sig: Signal) -> void:
	# Check empty signal
	if not sig:
		push_error("Signal is null")
		set_block_signals(true)
		return

	# Check signal's argument count
	var signal_info := sig.get_object().get_signal_list().filter(
		func(info: Dictionary) -> bool:
			return info.name == sig.get_name()
	)
	assert(signal_info.size() == 1)

	var sig_arg_count: int = signal_info[0]["args"].size()
	_source_signal = sig

	if sig_arg_count == 0:
		_source_signal.connect(func() -> void: _on_next.emit(Unit.default))
	elif sig_arg_count == 1:
		_source_signal.connect(func(value: Variant) -> void: _on_next.emit(value))
	else:
		_source_signal.connect(func(...args: Array) -> void: _on_next.emit(args))


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
