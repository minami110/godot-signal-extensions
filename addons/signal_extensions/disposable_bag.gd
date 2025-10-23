class_name DisposableBag
extends Disposable

var _items: Array[Object] = []


func add(...items: Array) -> void:
	for item: Object in items:
		if item.has_method(&"dispose") == false:
			push_error("Item does not have a dispose() method.")
			continue

		# Already bag disposed
		if _items.is_read_only():
			item.dispose()
			continue

		_items.push_back(item)


func clear() -> void:
	if _items.is_read_only():
		return

	for item in _items:
		item.dispose()
	_items.clear()


func dispose() -> void:
	clear()
	_items.make_read_only()
