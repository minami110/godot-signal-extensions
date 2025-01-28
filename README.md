# Signal Extensions for Godot 4
This plugin extends GDScript's [Signal](https://docs.godotengine.org/en/stable/classes/class_signal.html) and [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html) classes, influenced by [Cysharp/R3](https://github.com/Cysharp/R3).<br>
The main purpose of this plugin is to make it easier to unsubscribe from Godot signals. However, it is not intended to fully replicate R3.<br>
Additionally, several simple operators are implemented.

## Installation
### from Asset Library
You can install the plugin by searching for "[Signal Extensions](https://godotengine.org/asset-library/asset/3661)" in the AssetLib tab within the editor.

### from GitHub
Download the latest .zip file from the [Releases](https://github.com/minami110/godot-signal-extensions/releases) page of this repository.<br>
After extracting it, copy the `addons/signal_extensions/` directory into the `addons/` folder of your project.<br>
Launch the editor and enable "Signal Extensions" from `Project Settings > Plugins`.

## Sample Code
```gdscript
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

func _update_label(value: float) -> void:
	print("Health: %s" % value)

func take_damage(damage: float) -> void:
	# Update reactive property value
	health.value -= damage
```

This is a sample code of a simple player class that can be written using this plugin.<br>
It implements the minimum functionality of `Subject` and `ReactiveProperty`, and allows the use of several basic operators.<br>
Unsubscribing and stopping the stream can be done via the `dispose()` method, and in the case of classes inheriting from [Node](https://docs.godotengine.org/en/stable/classes/class_node.html), you can reduce the amount of code by using the `add_to()` method.

## Subject and Reactive Property
### Subject
```gdscript
var subject := Subject.new()
var subscription := subject.subscribe(func(_x): print("Hello, World!"))

# On next (emit)
subject.on_next(Unit.default)

# Unsubscribe
subscription.dispose()
subject.on_next() # no arg == Unit.default

# Dispose subject
subject.dispose()
```
```console
Hello, world!
```

Only the `on_next()` is implemented.<br>
Unsubscribing from both the source and the subscriber can be done using `dispose()`.

### ReactiveProperty
```gdscript
var health := ReactiveProperty.new(100.0)

# Gets the value
print(health.value)

# Subscribe to health changes
health.subscribe(func(x): print(x))

# Update health
health.value = 50.0

# Dispose
health.dispose()
```
```console
100
100
50
```

### Await Subjects and ReactivePropety

```gdscript
var r1: int = await subject.wait()
var r2: float = await rp.wait()
```

`Subject` and `ReactiveProperty` behave the same as GDScript’s Signal await when the `wait()` function is called.

### Disposable
```gdscript
extends Node

@onready var _subject := Subject.new()

func _ready() -> void:
    # Will dispose subject when node exiting
    _subject.add_to(self)

    # Will dispose subscription when node exiting
    _subject.subscribe(func(x): print(x)).add_to(self)
```

If the class being used inherits from the [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) class, calling `add_to(self)` will associate the dispose method with the [tree_exiting](https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-signal-tree-exiting) signal.

```gdscript
var bag: Array[Disposable] = []
subject.add_to(bag)
subject.subscribe(func(x): print(x)).add_to(bag)

for d in bag:
    d.dispose()
```

The argument for `add_to()` can also accept an `Array[Disposable]`.

## Other observables (factory methods)
### from_signal
```gdscript
Observable \
	.from_signal($Button.pressed)\
	.subscribe(func(_x): print("pressed"))
```

This converts Godot signals to `Observable` ones. It only supports signals with 0 or 1 arguments. If the signal has 0 arguments, it is converted to `Unit`.

### merge
```gdscript
var s1 := Subject.new()
var s2 := Subject.new()
var s3 := Subject.new()

Observable \
	.merge([s1, s2, s3]) \
	.subscribe(func(x): arr.push_back(x))

s1.on_next("foo")
s2.on_next("bar")
s3.on_next("baz")
```
```
["foo", "bar", "baz"]
```

## Operators
### select
```gdscript
subject.select(func(x): return x * 2).subscribe(func(x): arr.push_back(x))

subject.on_next(1)
subject.on_next(2)
```
```
[2, 4]
```

### skip
```gdscript
subject.skip(2).subscribe(func(x): arr.push_back(x))

subject.on_next(1)
subject.on_next(2)
subject.on_next(3)
subject.on_next(1)
```
```
[3, 1]
```

### skip_while
```gdscript
subject.skip_while(funx(x): return x <= 1).subscribe(func(x): arr.push_back(x))

subject.on_next(1)
subject.on_next(2)
subject.on_next(1)
```
```
[2, 1]
```

### take
```gdscript
subject.take(2).subscribe(func(x): arr.push_back(x))

subject.on_next(1)
subject.on_next(2)
subject.on_next(3)
```
```
[1, 2]
```

### take_while
```gdscript
subject.take_while(func(x): return x <= 1).subscribe(func(x): arr.push_back(x))

subject.on_next(1)
subject.on_next(2)
subject.on_next(1)
```
```
[1]
```

### throttle_last
```gdscript
subject.throttle_last(0.1).subscribe(func(x): arr.push_back(x))

subject.on_next(1)
await get_tree().create_timer(0.05).timeout
subject.on_next(2)
await get_tree().create_timer(0.11).timeout
```
```
[2]
```

### where
```gdscript
subject.where(func(x): return x >= 2).subscribe(func(x): arr.push_back(x))

subject.on_next(1)
subject.on_next(2)
subject.on_next(3)
```
```
[2, 3]
```