class_name Disposable extends RefCounted

static var empty = _EmptyDisposable.new()

func dispose() -> void:
	pass

func add_to(obj: Variant) -> Disposable:
	if obj == null:
		self.dispose()
		push_error("Null obj. disposed")
		return self

	if obj is Node:
		if not is_instance_valid(obj) or obj.is_queued_for_deletion():
			self.dispose()
			push_error("Invalid node. disposed")
			return self

		# outside tree
		if not obj.is_inside_tree():
			# Before enter tree
			if not obj.is_node_ready():
				push_warning("add_to does not support before enter tree")
			self.dispose()
			push_warning("Node is outside tree. disposed")
			return self

		# Note: 4.3 でなぜかこれで呼び出されない, ラムダなら動く
		# obj.tree_exiting.connect(dispose, ConnectFlags.CONNECT_ONE_SHOT)
		obj.tree_exiting.connect(func(): dispose(), ConnectFlags.CONNECT_ONE_SHOT)
		return self

	if obj is Array[Disposable]:
		if obj.is_read_only():
			self.dispose()
			push_error("Array is read only. disposed")
			return self

		obj.push_back(self)
		return self

	push_error("Unsupported obj types. Supported types: Node, Array[Disposable]")
	return self

class _EmptyDisposable extends Disposable:
	func dispose() -> void:
		pass

	@warning_ignore("unused_parameter")
	func add_to(obj: Variant) -> Disposable:
		return self
