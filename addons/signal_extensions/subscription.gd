class_name Subscription extends RefCounted

static var empty := _Empty.new()

var _is_disposed: bool = false
var _signal: Signal
var _callable: Callable

func _init(sig: Signal, callable: Callable) -> void:
	if sig.is_null():
		push_error("Signal is null")
		_is_disposed = true
		return

	if sig.is_connected(callable):
		push_error("Signal is already connected")
		_is_disposed = true
		return

	var success := sig.connect(callable)
	if success != OK:
		push_error("Failed to connect signal")
		_is_disposed = true
		return

	_signal = sig
	_callable = callable

func dispose() -> void:
	if _is_disposed:
		return
	if _signal != null and not _signal.is_null() and _signal.is_connected(_callable):
		_signal.disconnect(_callable)
	_is_disposed = true
	_signal = Signal()
	_callable = Callable()

## Add the property to Node or Array.
func add_to(obj: Variant) -> Subscription:
	if obj is Node:
		if obj == null or not is_instance_valid(obj):
			self.dispose()
			push_error("Invalid node. disposed")
			return self

		if not obj.is_inside_tree():
			# Before enter tree
			if not obj.is_node_ready():
				push_warning("add_to does not support before enter tree")
			self.dispose()
			push_warning("Node is outside tree. disposed")
			return self

		obj.tree_exiting.connect(dispose)
		return self

	elif obj is Array:
		obj.push_back(self)
		return self
	else:
		push_error("Invalid obj types")
		return self

class _Empty extends Subscription:
	func _init() -> void:
		pass

	func dispose() -> void:
		pass

	func add_to(obj: Variant) -> Subscription:
		return Subscription.empty