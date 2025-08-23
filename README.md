# Signal Extensions for Godot 4
[![Godot 4.5](https://img.shields.io/badge/Godot-4.5-478cbf?logo=godot-engine&logoColor=white)](https://godotengine.org)
[![gdunit4-tests](https://github.com/minami110/godot-signal-extensions/actions/workflows/gdunit4-tests.yml/badge.svg)](https://github.com/minami110/godot-signal-extensions/actions/workflows/gdunit4-tests.yml)


This plugin extends GDScript's [Signal](https://docs.godotengine.org/en/stable/classes/class_signal.html) and [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html) classes, influenced by [Cysharp/R3](https://github.com/Cysharp/R3).<br>
The main purpose of this plugin is to make it easier to unsubscribe from Godot signals. However, it is not intended to fully replicate R3.<br>
Additionally, several simple operators are implemented.

## Installation
### from Asset Library
You can install the plugin by searching for "[Signal Extensions](https://godotengine.org/asset-library/asset/3661)" in the AssetLib tab within the editor.

### from GitHub
Download the latest .zip file from the [Releases](https://github.com/minami110/godot-signal-extensions/releases) page of this repository.<br>
After extracting it, copy the `addons/signal_extensions/` directory into the `addons/` folder of your project.

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

## Core Classes

All classes inherit from the base `Observable` class and implement the `Disposable` pattern for automatic cleanup:

```
Observable (abstract)
├── Subject
├── BehaviourSubject
├── ReadOnlyReactiveProperty (abstract)
│   └── ReactiveProperty
└── Operator classes (Select, Where, Take, etc.)
```

### Unit

Unit is a special type used to represent the absence of a meaningful value, particularly for signals that don't carry data.

```gdscript
# Unit is used for signals without arguments
var subject := Subject.new()
subject.on_next(Unit.default)  # Explicit Unit
subject.on_next()              # Same as above - Unit.default is used automatically
```

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

```gdscript
var subject := Subject.new()
var subscription := subject.subscribe(func(): print("Hello, World!")) # No argument
subject.on_next(Unit.default)
```

You can also omit the argument if it's not needed. When you don't need the emitted value, use a parameter-less function to ignore the stream values.

```gdscript
# Practical examples of ignoring stream values
button_clicks.subscribe(func(): print("Button was clicked!"))

var click_count = 0
button_clicks.subscribe(func(): click_count += 1)
```

### BehaviourSubject
```gdscript
var status := BehaviourSubject.new("idle")

# Subscribe - immediately gets current value
status.subscribe(func(x): print("Status: " + x))

# Update status
status.on_next("loading")
status.on_next("complete")

# New subscriber gets the latest value immediately
status.subscribe(func(x): print("New subscriber: " + x))

# Dispose
status.dispose()
```
```console
Status: idle
Status: loading
Status: complete
New subscriber: complete
```

BehaviourSubject is a variant of Subject that requires an initial value and emits its current value whenever it is subscribed to.


### ReadOnlyReactiveProperty

ReadOnlyReactiveProperty is the base class for ReactiveProperty that provides safe external access by hiding write operations. This allows you to manage values internally while exposing only read and subscription capabilities to external consumers.

```gdscript
class_name PlayerHealth extends Node

# Private: Can only be modified internally
var _health: ReactiveProperty = ReactiveProperty.new(100)

# Public: Exposed as read-only to external consumers
var health: ReadOnlyReactiveProperty:
	get:
		return _health

func take_damage(damage: int) -> void:
	# Internal code can modify the value
	_health.value -= damage

func _ready() -> void:
	# External code can only subscribe and read
	health.subscribe(func(hp): print("Health: ", hp))
	print("Current health: ", health.current_value)
```

Similarly, you can cast Subject or BehaviourSubject to Observable to hide emit methods like `on_next()` and safely expose only subscription functionality:

```gdscript
class_name EventManager extends Node

# Private: Internal event emission
var _button_pressed: Subject = Subject.new()

# Public: Only subscription exposed externally
var button_pressed: Observable:
	get:
		return _button_pressed

func _on_button_clicked() -> void:
	# Internal code can emit events
	_button_pressed.on_next()
```

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

### ConfigFile Serialization

ReactiveProperty and BehaviourSubject support Godot's [ConfigFile](https://docs.godotengine.org/en/4.4/classes/class_configfile.html) serialization for persistent storage. Their internal values are automatically serialized, allowing you to save and load reactive observables in configuration files.

```gdscript
# Saving ReactiveProperty and BehaviourSubject to ConfigFile
var health := ReactiveProperty.new(100)
var status := BehaviourSubject.new("idle")

var config := ConfigFile.new()
config.set_value("player", "health", health)
config.set_value("player", "status", status)
config.save("user://player_data.cfg")

# Loading from ConfigFile
var config := ConfigFile.new()
config.load("user://player_data.cfg")

var loaded_health: ReactiveProperty = config.get_value("player", "health")
var loaded_status: BehaviourSubject = config.get_value("player", "status")

# Subscribe to loaded observables
loaded_health.subscribe(func(value): print("Loaded health: ", value))
loaded_status.subscribe(func(value): print("Loaded status: ", value))
```
```console
100
idle
```

**Note:** Subscriptions and internal state are not preserved during serialization - only the current values (`_value` for ReactiveProperty and `_latest_value` for BehaviourSubject) are saved and restored.

## Disposable Pattern
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
var bag: Array = []
subject.add_to(bag)
subject.subscribe(func(x): print(x)).add_to(bag)

for d in bag:
	d.dispose()
```

The argument for `add_to()` can also accept an `Array`. For more convenient management of multiple disposables, consider using `DisposableBag` (see below).

## DisposableBag

DisposableBag is a convenient container class for managing multiple Disposable objects. It automatically disposes all contained items when the bag itself is disposed.

```gdscript
extends Node

@onready var _subject1 := Subject.new()
@onready var _subject2 := Subject.new()
@onready var _bag := DisposableBag.new()

func _ready() -> void:
	# Add disposables to the bag
	_bag.add(_subject1)
	_bag.add(_subject2)
	_bag.add(_subject1.subscribe(func(x): print("Subject1: ", x)))
	_bag.add(_subject2.subscribe(func(x): print("Subject2: ", x)))

	# The bag itself can be auto-disposed when node exits
	_bag.add_to(self)

	# Test emissions
	_subject1.on_next("Hello")
	_subject2.on_next("World")

	# Manual cleanup options:
	# _bag.clear()    # Disposes all items but bag can still be used
	# _bag.dispose()  # Disposes all items and makes bag unusable
```
```console
Subject1: Hello
Subject2: World
```

DisposableBag provides several advantages over manual Array management:
- **Automatic disposal**: All items are disposed when the bag is disposed
- **Type safety**: Only accepts Disposable objects
- **Convenience methods**: `clear()` for manual cleanup, `add()` for easy addition
- **Self-disposal**: The bag itself inherits from Disposable and can use `add_to()`

## Awaiting Observables

All core Observable classes support awaiting the next value emission using the `wait()` method, similar to Godot's built-in signal await functionality.

```gdscript
# Basic await usage
var next_value = await subject.wait()
var health_change = await health.wait()
```

### Class-specific Behavior

**Subject**: Waits for the next `on_next()` call.
```gdscript
var subject := Subject.new()
subject.on_next("first")

# This waits for the next emission
var result = await subject.wait()  # Will wait
subject.on_next("second")         # result becomes "second"
```

**BehaviourSubject**: Waits for the next emission, not the current value.
```gdscript
var status := BehaviourSubject.new("idle")
# To get current value: status.value
# To wait for next change: await status.wait()
```

**ReactiveProperty**: Waits for the next value change.
```gdscript
var health := ReactiveProperty.new(100)
health.value = 90  # This change occurs immediately

# Wait for the next change
var new_health = await health.wait()
```

**merge**: Waits for the first emission from any of the source observables.
```gdscript
var s1 := Subject.new()
var s2 := Subject.new()
var merged := Observable.merge(s1, s2)

# Will resolve with whichever emits first
var first_result = await merged.wait()
s2.on_next("second wins")  # first_result becomes "second wins"
s1.on_next("first")        # This won't affect the await result
```


### Important Notes

- `wait()` returns `null` if the observable is disposed
- Operator chains (like `.select().where()`) don't support direct await - subscribe instead
- For immediate values, use `.value` property on BehaviourSubject/ReactiveProperty
- `merge().wait()` resolves with the first emission from any source and automatically disposes subscriptions to other sources


## Factory Methods
### from_signal
```gdscript
Observable \
	.from_signal($Button.pressed) \
	.subscribe(func(_x): print("pressed"))
```

Converts Godot signals into reactive Observable streams. Now supports unlimited arguments using Godot 4.5+ variadic arguments. If the signal has 0 arguments, it is converted to `Unit`. For signals with 2 or more arguments, the values are converted into an Array.

```gdscript
# Multi-argument signal example
signal player_moved(position: Vector2, velocity: Vector2)

Observable \
	.from_signal(player_moved) \
	.subscribe(func(args: Array):
		var pos = args[0] as Vector2
		var vel = args[1] as Vector2
		print("Player at ", pos, " moving at ", vel))
```

### merge
Merge multiple observables into a single observable stream. Now uses variadic arguments for more intuitive syntax.
```gdscript
var s1 := Subject.new()
var s2 := Subject.new()
var s3 := Subject.new()

Observable \
	.merge(s1, s2, s3) \
	.subscribe(func(x): arr.push_back(x))

s1.on_next("foo")
s2.on_next("bar")
s3.on_next("baz")
```
```console
["foo", "bar", "baz"]
```

Combines multiple Observable streams into a single stream that emits values as they arrive from any source.

## Operators
### debounce
```gdscript
subject.debounce(0.1).subscribe(func(x): arr.push_back(x))

subject.on_next(1)
subject.on_next(2)
await get_tree().create_timer(0.05).timeout
subject.on_next(3)
await get_tree().create_timer(0.05).timeout
subject.on_next(4)
await get_tree().create_timer(0.1).timeout
```
```console
[4]
```

Emits a value only after a specified duration has passed without another emission. Useful for handling rapid user input events.

### select
```gdscript
subject \
	.select(func(x): return x * 2) \
	.subscribe(func(x): arr.push_back(x))

subject.on_next(1)
subject.on_next(2)
```
```console
[2, 4]
```

Transforms each emitted value by applying a function. Also known as "map" in other reactive programming libraries.

### skip
```gdscript
subject.skip(2).subscribe(func(x): arr.push_back(x))

subject.on_next(1)
subject.on_next(2)
subject.on_next(3)
subject.on_next(1)
```
```console
[3, 1]
```

Ignores the first N emissions and only starts emitting values after that count is reached.

### skip_while
```gdscript
subject \
	.skip_while(func(x): return x <= 1) \
	.subscribe(func(x): arr.push_back(x))

subject.on_next(1)
subject.on_next(2)
subject.on_next(1)
```
```console
[2, 1]
```

Skips values while the predicate function returns true, then emits all subsequent values regardless of the condition.

### take
```gdscript
subject.take(2).subscribe(func(x): arr.push_back(x))

subject.on_next(1)
subject.on_next(2)
subject.on_next(3)
```
```console
[1, 2]
```

Emits only the first N values from the source observable, then automatically completes the subscription.

### take_while
```gdscript
subject \
	.take_while(func(x): return x <= 1) \
	.subscribe(func(x): arr.push_back(x))

subject.on_next(1)
subject.on_next(2)
subject.on_next(1)
```
```console
[1]
```

Emits values as long as the predicate function returns true. Once the condition becomes false, the observable completes.

### throttle_last / sample
```gdscript
subject.throttle_last(0.1).subscribe(func(x): arr.push_back(x))
# sample() is an alias for throttle_last()
# subject.sample(0.1).subscribe(func(x): arr.push_back(x))

subject.on_next(1)
subject.on_next(2)
await get_tree().create_timer(0.05).timeout
subject.on_next(3)
await get_tree().create_timer(0.05).timeout
subject.on_next(4)
await get_tree().create_timer(0.1).timeout
```
```console
[3, 4]
```

Both `throttle_last()` and `sample()` are aliases for the same functionality - emitting the most recent items within periodic time intervals.

### where
```gdscript
subject \
	.where(func(x): return x >= 2) \
	.subscribe(func(x): arr.push_back(x))

subject.on_next(1)
subject.on_next(2)
subject.on_next(3)
```
```console
[2, 3]
```

Filters emitted values, allowing only those that satisfy the predicate condition to pass through. Also known as "filter" in other reactive libraries.
