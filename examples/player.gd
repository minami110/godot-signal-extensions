extends Node2D

@onready var health := ReactiveProperty.new(100.0)

func _ready() -> void:
	# Subscribe reactive property
	var d1 := health.subscribe(_update_label)

	# Subscribe reactive property with operator
	var d2 := health \
		.where(func(x): return x <= 0.0) \
		.take(1) \
		.subscribe(func(_x): print("Dead"))

	# Dispose when this node exiting tree
	for d in [health, d1, d2]:
		d.add_to(self)

	var s1 := Subject.new()
	var s2 := Subject.new()
	var s3 := Subject.new()
	Observable.merge([s1, s2, s3]).subscribe(func(x): print(x))
	s1.on_next("foo")
	s2.on_next("bar")
	s3.on_next("baz")

func _update_label(value: float) -> void:
	print("Health: %s" % value)

func take_damage(damage: float) -> void:
	# Update reactive property value
	health.value -= damage

	Observable.from_signal($Button.pressed).subscribe(func(_x: Unit): print("pressed"))
