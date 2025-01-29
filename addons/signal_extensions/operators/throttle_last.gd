class_name _ThrottleLast extends Observable
## ThrottleLast (Sample) operator
## Ref: ReactiveX - Sample operator: https://reactivex.io/documentation/operators/sample.html

var _source: Observable
var _interval: float

func _init(source: Observable, interval: float) -> void:
	_source = source
	_interval = interval

func _subscribe_core(on_next: Callable) -> Disposable:
	assert(on_next.is_valid(), "throttle_last.subscribe on_next is not valid.")
	assert(on_next.get_argument_count() == 1, "throttle_last.subscribe on_next must have exactly one argument")

	var o := _ThrottleLastObserver.new(on_next, _interval)
	return _source.subscribe(func(value: Variant) -> void: o._on_next_core(value))

class _ThrottleLastObserver extends RefCounted:
	var _on_next: Callable
	var _interval: float
	var _scene_tree: SceneTree
	var _last_value: Variant
	var _timer: SceneTreeTimer

	func _init(on_next: Callable, interval: float) -> void:
		_on_next = on_next
		_interval = interval

		_scene_tree = Engine.get_main_loop() as SceneTree
		assert(_scene_tree, "throttle_last Failed to access SceneTree")

	func _on_next_core(value: Variant) -> void:
		# Timer is not running, intialize
		if _last_value == null:
			# Create new timer from scene tree
			# ToDo: expose timer options for user
			_timer = _scene_tree.create_timer(_interval, true, false, false)

			# Bind callback
			_timer.timeout.connect(_on_timeout)

		# Update last value
		_last_value = value

	func _on_timeout() -> void:
		# OnNext with last value
		assert(_on_next.is_valid(), "throttle_last._on_next is not valid.")
		assert(_last_value != null, "throttle_last._last_value is null.")

		_on_next.call(_last_value)

		# Cleanup
		_last_value = null
		_timer = null
