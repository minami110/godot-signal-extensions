class_name _ThrottleLast extends Observable

var _source: Observable
var _interval: float

func _init(source: Observable, interval: float) -> void:
	_source = source
	_interval = interval

func _subscribe_core(observer: Callable) -> Disposable:
	assert(observer.is_valid(), "select.subscribe observer is not valid.")
	assert(observer.get_argument_count() == 1, "select.subscribe observer must have exactly one argument")

	var o := _ThrottleLastObserver.new(observer, _interval)
	return _source.subscribe(func(value: Variant) -> void: o._on_next_core(value))

class _ThrottleLastObserver extends RefCounted:
	var _observer: Callable
	var _interval: float
	var _scene_tree: SceneTree
	var _last_value: Variant
	var _timer: SceneTreeTimer

	func _init(observer: Callable, interval: float) -> void:
		_observer = observer
		_interval = interval

		_scene_tree = Engine.get_main_loop() as SceneTree
		assert(_scene_tree, "throttlelast Failed to access SceneTree")

	func _on_next_core(value: Variant) -> void:
		# Timer is not running, intialize
		if _last_value == null:
			# Create new timer from scene tree
			# ToDo: expose timer options for user
			_timer = _scene_tree.create_timer(_interval, true, false, false)

			# Bind callback
			_timer.timeout.connect(_on_timeout)
		# Timer is running, update value
		else:
			# Reset time
			_timer.time_left = _interval

		# Update last value
		_last_value = value

	func _on_timeout() -> void:
		# OnNext with last value
		assert(_observer.is_valid(), "throttlelast.observer (on_next callback) is not valid.")
		assert(_last_value != null, "throttlelast._last_value is null.")

		_observer.call(_last_value)

		# Cleanup
		_last_value = null
		_timer = null
