class_name Subject extends Observable

const Subscription = preload("subscription.gd")

signal _on_next(value: Variant)

func _to_string() -> String:
	return "<Subject#%d>" % get_instance_id()

## Notifies all subscribed callables with the value.[br]
## If the [param value] is not provided, it will emit [member Unit.default].[br]
## [b]Note:[/b] If disposed, it will not emit any value.
func on_next(value: Variant = null) -> void:
	if is_blocking_signals():
		return

	if value == null:
		_on_next.emit(Unit.default)
	else:
		_on_next.emit(value)

func _subscribe_core(observer: Callable) -> Disposable:
	if is_blocking_signals():
		return Disposable.empty

	assert(observer.is_valid(), "Subject.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "Subject.subscribe observer must have exactly one argument")
	return Subscription.new(_on_next, observer)

## Dispose the subject.
func dispose() -> void:
	if is_blocking_signals():
		return

	# Disconnect all signals
	var connections := get_signal_connection_list(&"_on_next")
	for c in connections:
		var callable: Callable = c.callable
		_on_next.disconnect(callable)

	set_block_signals(true)

## Wait for the next value emitted.[br]
## [b]Note:[/b] If disposed, it will return null[br]
## Usage:
## [codeblock]
## var value := await subject.wait()
## [/codeblock]
func wait() -> Variant:
	if is_blocking_signals():
		return null

	return await _on_next

## Adds this [Subject] to an object for automatic disposal.[br]
## Supported types:[br]
## - [Node]: The [Subject] will be disposed when the node exits the tree.[br]
## - [Array][[Disposable]]: The [Subject] will be added to the array.[br]
## [b]Note:[/b] This method is copied from Disposable implementation for compatibility.
func add_to(obj: Variant) -> Subject:
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
		obj.tree_exiting.connect(func() -> void: dispose(), ConnectFlags.CONNECT_ONE_SHOT)
		return self

	if obj is Array:
		if obj.is_read_only():
			self.dispose()
			push_error("Array is read only. disposed")
			return self

		obj.push_back(self)
		return self

	push_error("Unsupported obj types. Supported types: Node, Array[Disposable]")
	return self
