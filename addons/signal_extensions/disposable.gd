@abstract
class_name Disposable extends RefCounted
## Abstract base class for objects that require cleanup.
##
## The Disposable pattern provides a consistent way to manage resource cleanup
## in reactive programming. All observables, subscriptions, and related objects
## implement this interface to ensure proper disposal of resources.
##
## The class also provides utility methods for automatic disposal when nodes
## exit the tree or for batch disposal using arrays.

## A pre-created empty disposable that does nothing when disposed.
## Useful as a null object to avoid null checks in disposal logic.
static var empty: Disposable = _EmptyDisposable.new()

## Abstract method that must be implemented by all disposable objects.
##
## This method should clean up any resources held by the object,
## such as signal connections, references, or other managed resources.
##
## [b]Note:[/b] After disposal, the object should be in a state where
## it can safely be garbage collected.
@abstract
func dispose() -> void

## Internal implementation for adding disposables to containers.
##
## This static method handles the logic for automatic disposal when nodes
## exit the tree or when adding to disposal arrays. It includes comprehensive
## error checking and handles different target object types.
##
## [param disposable]: The disposable object to manage
## [param obj]: The container object (Node or Array)
static func add_to_impl(disposable: Variant, obj: Variant) -> void:
	if not disposable.has_method("dispose"):
		push_error("disposable object must have dispose() method")
		return

	if obj == null:
		disposable.dispose()
		push_error("Null obj. disposed")
		return

	if obj is Node:
		if not is_instance_valid(obj) or obj.is_queued_for_deletion():
			disposable.dispose()
			push_error("Invalid node. disposed")
			return

		# outside tree
		if not obj.is_inside_tree():
			# Before enter tree
			if not obj.is_node_ready():
				push_warning("add_to does not support before enter tree")
			disposable.dispose()
			push_warning("Node is outside tree. disposed")
			return

		# Note: 4.3 でなぜかこれで呼び出されない, ラムダなら動く
		# obj.tree_exiting.connect(dispose, ConnectFlags.CONNECT_ONE_SHOT)
		obj.tree_exiting.connect(func() -> void: disposable.dispose(), ConnectFlags.CONNECT_ONE_SHOT)
		return

	if obj is DisposableBag:
		obj.add(disposable)
		return

	if obj is Array:
		if obj.is_read_only():
			disposable.dispose()
			push_error("Array is read only. disposed")
			return

		obj.push_back(disposable)
		return

	push_error("Unsupported obj types. Supported types: Node, Array[Disposable]")

## Adds this disposable to a container for automatic cleanup.
##
## This method provides automatic disposal in two scenarios:
## - When added to a [Node]: Disposes when the node exits the scene tree
## - When added to an [Array]: Allows batch disposal of multiple objects
##
## Usage:
## [codeblock]
## var subscription := observable.subscribe(callback)
## subscription.add_to(self)  # Auto-dispose when node exits
## subscription.add_to(disposal_bag)  # Add to batch disposal array
## [/codeblock]
##
## [param obj]: A [Node] for tree-based disposal or [Array] for batch disposal
## [br][b]Returns:[/b] This disposable for method chaining
func add_to(obj: Variant) -> Disposable:
	add_to_impl(self, obj)
	return self

## Internal empty disposable implementation.
##
## This class provides a null object pattern for disposables that
## don't require any cleanup. It's used internally to avoid null checks.
class _EmptyDisposable extends Disposable:
	func dispose() -> void:
		pass

	## Empty implementation that returns self without doing anything.
	##
	## Since empty disposables don't need cleanup, adding them to
	## containers is a no-op operation.
	##
	## [param obj]: Ignored parameter for consistency
	## [br][b]Returns:[/b] This empty disposable
	@warning_ignore("unused_parameter")
	func add_to(obj: Variant) -> Disposable:
		return self
