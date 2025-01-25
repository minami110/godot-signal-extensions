# Signal Extensions for Godot 4
## Installation
- Copy `/addons/signal_extensions/` directory to the `/addons/` directory in your project
- Enable `SignalExtensions` plugin in `Project Settings > Plugins`

## Subject
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

- You can use `add_to` method for dispose if your script extends Node class:

```gdscript
extends Node

@onready var _subject := Subject.new()

func _ready() -> void:
    # Will dispose subject when node exiting
    _subject.add_to(self)

    # Will dispose subscription when node exiting
    _subject.subscribe(func(_unit: Unit): pass ).add_to(self)
```

- Also `add_to` supported for `Array` class:

```gdscript
var bag := []
subject.add_to(bag)
subject.subscribe(func(_unit: Unit): pass ).add_to(bag)

for d in bag:
    d.dispose()
```

- Subject is awaitable like Signal:

```gdscript
var result: int = await subject.wait()
```

## Reactive Property
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

- ReactiveProperty also has `add_to` and `wait` methods.

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