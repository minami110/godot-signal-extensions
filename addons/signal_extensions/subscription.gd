class_name Subscription extends Disposable


var _signal: Signal = Signal()
var _callable: Callable = Callable()

func _init(sig: Signal, callable: Callable) -> void:
	# Note: Signal().is_null() == true
	if sig.is_null():
		push_error("Signal is null")
		return

	# Already freed signal's owner
	if not is_instance_id_valid(sig.get_object_id()):
		push_error("Signal's owner is already freed")
		return

	# Check connection
	if sig.is_connected(callable):
		push_error("Signal is already connected")
		return

	var success := sig.connect(callable)
	if success != OK:
		push_error("Failed to connect signal")
		return

	_signal = sig
	_callable = callable

func dispose() -> void:
	# Note: Signal().is_null() == true
	if _signal.is_null():
		return

	# Already freed signal's owner
	if not is_instance_id_valid(_signal.get_object_id()):
		_signal = Signal()
		_callable = Callable()
		return

	if _signal.is_connected(_callable):
		_signal.disconnect(_callable)

	_signal = Signal()
	_callable = Callable()
