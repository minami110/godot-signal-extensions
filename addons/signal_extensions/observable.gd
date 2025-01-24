class_name Observable extends Disposable


func subscribe(observer: Callable) -> Disposable:
	return _subscribe_core(observer)

@warning_ignore("unused_parameter")
func _subscribe_core(observer: Callable) -> Disposable:
	return Disposable.empty
