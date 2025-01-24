class_name Subscription extends Disposable


var _signal: Signal
var _callable: Callable

func _init(sig: Signal, callable: Callable) -> void:
	if sig.is_null():
		push_error("Signal is null")
		return

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
	if not _signal:
		return

	if _signal != null and not _signal.is_null() and _signal.is_connected(_callable):
		_signal.disconnect(_callable)

	_signal = Signal()
	_callable = Callable()
