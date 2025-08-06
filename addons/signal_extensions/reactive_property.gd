class_name ReactiveProperty extends ReadOnlyReactiveProperty

const Subscription = preload("subscription.gd")

signal _on_next(value: Variant)

var _check_equality: bool

func _to_string() -> String:
	return "%s:<ReactiveProperty#%d>" % [_value, get_instance_id()]

## Create a new reactive property.[br]
## Usage:
## [codeblock]
## var rp1 := ReactiveProperty.new(1)
## var rp2 := ReactiveProperty.new(1, false) # Disable equality check
## [/codeblock]
func _init(initial_value: Variant, check_equality := true) -> void:
	_value = initial_value
	_check_equality = check_equality

func _get_value() -> Variant:
	return _value

func _set_value(new_value: Variant) -> void:
	if _check_equality and _test_equality(_value, new_value):
		return

	_value = new_value

	if not is_blocking_signals():
		_on_next.emit(new_value)


## The current value of the property.
var value: Variant: get = _get_value, set = _set_value

func _subscribe_core(observer: Callable) -> Disposable:
	if is_blocking_signals():
		return Disposable.empty

	assert(observer.is_valid(), "ReactiveProperty.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "ReactiveProperty.subscribe observer must have exactly one argument")

	observer.call(_value)
	return Subscription.new(_on_next, observer)

## Dispose of the property.
func dispose() -> void:
	if is_blocking_signals():
		return

	# Disconnect all signals
	var connections := get_signal_connection_list(&"_on_next")
	for c in connections:
		var callable: Callable = c.callable
		_on_next.disconnect(callable)

	set_block_signals(true)

## Wait for the next value changed.[br]
## [b]Note:[/b] If disposed, it will return null[br]
## Usage:
## [codeblock]
## var value := await rp.wait()
## [/codeblock]
func wait() -> Variant:
	if is_blocking_signals():
		return null

	return await _on_next

static func _test_equality(a: Variant, b: Variant) -> bool:
	if a == null and b == null:
		return true

	if a == null or b == null:
		return false

	if typeof(a) != typeof(b):
		return false

	if a == b:
		return true

	return false

## Adds this [ReactiveProperty] to an object for automatic disposal.[br]
## Supported types:[br]
## - [Node]: The [ReactiveProperty] will be disposed when the node exits the tree.[br]
## - [Array][[Disposable]]: The [ReactiveProperty] will be added to the array.[br]
## [b]Note:[/b] This method is copied from Disposable implementation for compatibility.
func add_to(obj: Variant) -> ReactiveProperty:
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
