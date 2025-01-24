class_name Subject extends RefCounted

var _is_disposed: bool = false
signal _signal(new_value: Variant)

func on_next(value: Variant) -> void:
	if _is_disposed:
		return

	_signal.emit(value)

## Subscribe to changes in the property.
func subscribe(on_next: Callable) -> Subscription:
	if _is_disposed:
		return Subscription.empty
	else:
		return Subscription.new(_signal, on_next)

## Dispose of the property.
func dispose() -> void:
	if _is_disposed:
		return

	_is_disposed = true

	# Disconnect all signals
	var connections := _signal.get_connections()
	for c in connections:
		_signal.disconnect(c.callable as Callable)

## Add the property to Node or Array.
func add_to(obj: Variant) -> Subject:
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

func wait_on_next() -> Variant:
	if _is_disposed:
		return null

	return await _signal