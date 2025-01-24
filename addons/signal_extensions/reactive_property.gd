class_name ReactiveProperty extends RefCounted

var _is_disposed: bool = false
var _value: Variant
signal _value_changed(new_value: Variant)

func _init(initial_value: Variant) -> void:
	_value = initial_value

func _get_value() -> Variant:
	return _value

func _set_value(new_value: Variant) -> void:
	if _is_disposed:
		return

	if _value == new_value:
		return

	_value = new_value
	_value_changed.emit(new_value)

## The current value of the property.
var value: Variant: get = _get_value, set = _set_value

## Subscribe to changes in the property.
func subscribe(on_next: Callable) -> Subscription:
	if _is_disposed:
		return Subscription.empty
	else:
		on_next.call(_value)
		return Subscription.new(_value_changed, on_next)

## Dispose of the property.
func dispose() -> void:
	if _is_disposed:
		return

	_is_disposed = true

	# Disconnect all signals
	var connections := _value_changed.get_connections()
	for c in connections:
		_value_changed.disconnect(c.callable as Callable)

## Add the property to Node or Array.
func add_to(obj: Variant) -> ReactiveProperty:
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

func wait() -> Variant:
	if _is_disposed:
		return null

	return await _value_changed