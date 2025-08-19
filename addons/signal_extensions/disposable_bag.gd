class_name DisposableBag extends Disposable

var _items: Array[Disposable] = []
var _is_disposed: bool = false

func add(item: Disposable) -> void:
    if _is_disposed:
        item.dispose()
        return

    _items.push_back(item)

func clear() -> void:
    for item in _items:
        item.dispose()
    _items.clear()


func dispose() -> void:
    clear()
    _is_disposed = true
