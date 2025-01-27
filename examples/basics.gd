extends Control

var _disposables: Disposable = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%SubscribeButton.pressed.connect(_subscribe)
	%UnsubscribeButton.pressed.connect(_unsubscribe)

func _exit_tree() -> void:
	if _disposables:
		_disposables.dispose()
		print("Unsubscribed (in _exit_tree)")

func _subscribe() -> void:
	if _disposables:
		_update_label("Already subscribed. skip.")
		return

	var d0 := Observable.from_signal(%FooButton.pressed).subscribe(func(_x): _update_label("Foo pressed"))
	var d1 := Observable.from_signal(%BarButton.pressed).subscribe(func(_x): _update_label("Bar pressed"))
	var d2 := Observable.from_signal(%BazButton.pressed).subscribe(func(_x): _update_label("Baz pressed"))

	d0.add_to(self)
	d1.add_to(self)
	d2.add_to(self)
	_update_label("Subscribed.")

func _unsubscribe() -> void:
	if not _disposables:
		_update_label("Already unsubscribed. skip.")
		return

	_disposables.dispose()
	_disposables = null
	_update_label("Unsubscribed.")

func _update_label(text: String) -> void:
	print(text)
	%Label.text = text