class_name _FromSignal extends Observable

signal _wrapped_signal(value: Variant)
var _is_disposed: bool = false
var _source_signal := Signal()
var _source_signal_arg_count: int

func _init(sig: Signal) -> void:
	# Check empty signal
	assert(not sig.is_null())

	# Check signal's argument count
	var signal_info := sig.get_object().get_signal_list().filter(func(info):
		return info.name == sig.get_name()
	)
	assert(signal_info.size() == 1)
	var sig_arg_count: int = signal_info[0]["args"].size()

	# Only 0 or 1 argument is allowed
	assert(sig_arg_count <= 1)
	_source_signal_arg_count = sig_arg_count
	_source_signal = sig

	# When the signal has no argument, wrap it with a signal that emits Unit
	if _source_signal_arg_count == 0:
		_source_signal.connect(func(): _wrapped_signal.emit(Unit.default))
	else:
		_source_signal.connect(func(x: Variant): _wrapped_signal.emit(x))

func _subscribe_core(observer: Callable) -> Disposable:
	if _is_disposed or _source_signal.is_null():
		return Disposable.empty
	else:
		return Subscription.new(_wrapped_signal, observer)

func dispose() -> void:
	if _is_disposed:
		return

	_is_disposed = true
	if _source_signal.is_null():
		return

	# Disconnect all signals
	var connections := _wrapped_signal.get_connections()
	for c in connections:
		_wrapped_signal.disconnect(c.callable as Callable)

	# Disconnect this instance callable from the source signal
	if is_instance_id_valid(_source_signal.get_object_id()):
		for c in _source_signal.get_connections():
			var callable: Callable = c.callable
			if get_instance_id() == callable.get_object_id():
				_source_signal.disconnect(callable)

	_source_signal = Signal()

func wait() -> Variant:
	if _is_disposed:
		return null

	return await _wrapped_signal