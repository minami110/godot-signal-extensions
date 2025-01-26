# Signal Extensions for Godot 4
This plugin extends GDScript's [Signal](https://docs.godotengine.org/en/stable/classes/class_signal.html) and [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html) classes, influenced by [Cysharp/R3](https://github.com/Cysharp/R3).<br>
The main purpose of this plugin is to make it easier to unsubscribe from Godot signals. However, it is not intended to fully replicate R3.<br>
Additionally, several simple operators are implemented.

## Installation
### Asset Library
You can install the plugin by searching for "Signal Extensions" in the AssetLib tab within the editor.

### GitHub
Download the latest .zip file from the [Releases](https://github.com/minami110/godot-signal-extensions/releases) page of this repository.<br>
After extracting it, copy the `addons/signal_extensions/` directory into the `addons/` folder of your project.<br>
Launch the editor and enable "Signal Extensions" from `Project Settings > Plugins`.

## Basic usages

## Subject and ReactiveProperty
```gdscript
var subject := Subject.new()
var subscription := subject.subscribe(func(_x): print("Hello, World!"))

# On next (emit)
subject.on_next(Unit.default)

# Unsubscribe
subscription.dispose()
subject.on_next(Unit.default)

# Dispose subject
subject.dispose()
```
```console
Hello, world!
```

```gdscript
var health := ReactiveProperty.new(100.0)

# Subscribe to health changes
health.subscribe(func(x: float): print(x))

# Update health
health.value = 50.0

# Dispose
health.dispose()
```
```console
100
50
```

Only the `on_next()` (value setter) is implemented.<br>
Unsubscribing from both the source and the subscriber can be done using `dispose()`.


```gdscript
var r1: int = await subject.wait()
var r2: float = await rp.wait()
```

Additionally, both classes behave the same as GDScript’s Signal await when the `wait()` function is called.

## Disposable
```gdscript
extends Node

@onready var _subject := Subject.new()

func _ready() -> void:
    # Will dispose subject when node exiting
    _subject.add_to(self)

    # Will dispose subscription when node exiting
    _subject.subscribe(func(_unit: Unit): pass ).add_to(self)
```

If the class being used inherits from the [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) class, calling `add_to(self)` will associate the dispose method with the [tree_exiting](https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-signal-tree-exiting) signal.

```gdscript
var bag: Array[Disposable] = []
subject.add_to(bag)
subject.subscribe(func(_unit: Unit): pass ).add_to(bag)

for d in bag:
    d.dispose()
```

The argument for `add_to()` can also accept an `Array[Disposable]`.

```gdscript
var d1 := rp.subscribe(func(x): print(x))
var d2 := rp.subscribe(func(x): print(x))

var disposable := Disposable.combine(d1, d2)
disposable.dispose()
```

By using the `Disposable.combine()`, it is possible to combine multiple Disposable objects.

## Operators
### Skip
```gdscript
subject.skip(2).subscribe(func(x): print(x))

subject.on_next(1)
subject.on_next(2)
subject.on_next(3)
```
```console
3
```

### Take
```gdscript
subject.take(2).subscribe(func(x): print(x))

subject.on_next(1)
subject.on_next(2)
subject.on_next(3)
```
```console
1
2
```

### Where
```gdscript
subject.where(func(x): return x >= 2).subscribe(func(x): print(x))

subject.on_next(1)
subject.on_next(2)
subject.on_next(3)
```
```console
2
3
```