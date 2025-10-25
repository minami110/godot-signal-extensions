extends Observable
## Singleton Empty Observable that completes immediately without emitting values.
## Based on R3's Observable.Empty implementation.

# Singleton instance for memory efficiency
static var _instance: Empty = null


static func get_instance() -> Empty:
	if _instance == null:
		_instance = Empty.new()
	return _instance


func _subscribe_core(_observer: Callable) -> Disposable:
	# Immediately complete without emitting any values
	return Disposable.empty


## Empty observable never emits, so wait() returns null immediately
func wait() -> Variant:
	return null
