extends Observable
## Factory that creates an Observable emitting a sequence of integers.
##
## This factory method creates a Cold Observable that emits integers
## from start to start + count - 1 (inclusive).

var _start: int = 0
var _count: int = 0


func _init(start: int, count: int) -> void:
	_start = start
	_count = count


func _subscribe_core(observer: Callable) -> Disposable:
	for i in range(_start, _start + _count):
		observer.call(i)
	return Disposable.empty
