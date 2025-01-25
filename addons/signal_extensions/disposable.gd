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

static func combine(
	d0: Disposable,
	d1: Disposable,
	d2: Disposable = Disposable.empty,
	d3: Disposable = Disposable.empty) -> Disposable:

	if d2 is _EmptyDisposable and d3 is _EmptyDisposable:
		return _CombinedDisposable2.new(d0, d1)
	elif d3 is _EmptyDisposable:
		return _CombinedDisposable3.new(d0, d1, d2)
	else:
		return _CombinedDisposable4.new(d0, d1, d2, d3)

class _EmptyDisposable extends Disposable:
	pass

class _CombinedDisposable2 extends Disposable:
	var _d0: Disposable
	var _d1: Disposable

	func _init(d0: Disposable, d1: Disposable) -> void:
		_d0 = d0
		_d1 = d1

	func dispose():
		_d0.dispose()
		_d1.dispose()

class _CombinedDisposable3 extends Disposable:
	var _d0: Disposable
	var _d1: Disposable
	var _d2: Disposable

	func _init(d0: Disposable, d1: Disposable, d2: Disposable) -> void:
		_d0 = d0
		_d1 = d1
		_d2 = d2

	func dispose():
		_d0.dispose()
		_d1.dispose()
		_d2.dispose()

class _CombinedDisposable4 extends Disposable:
	var _d0: Disposable
	var _d1: Disposable
	var _d2: Disposable
	var _d3: Disposable

	func _init(d0: Disposable, d1: Disposable, d2: Disposable, d3: Disposable) -> void:
		_d0 = d0
		_d1 = d1
		_d2 = d2
		_d3 = d3

	func dispose():
		_d0.dispose()
		_d1.dispose()
		_d2.dispose()
		_d3.dispose()