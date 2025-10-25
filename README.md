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

var health := ReactiveProperty.new(100.0)

func _ready() -> void:
	# Subscribe reactive property
	var d1 := health.subscribe(_update_label)

	# Subscribe reactive property with operator
	var d2 := health \
		.where(func(x): return x <= 0.0) \
		.take(1) \
		.subscribe(func(_x): print("Dead"))

	# Dispose when this Node exiting tree
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
│       └── CustomReactiveProperty (abstract)
└── Operator classes (Select, Where, Take, etc.)
```

## Core Concepts

### Subject

Subject is a basic implementation of the observer pattern that allows you to manually emit values to multiple subscribers.

```gdscript
var subject := Subject.new()
var subscription := subject.subscribe(func(_x): print("Hello, World!"))

# Emit values
subject.on_next(Unit.default)  # Explicit Unit
subject.on_next()              # Same as above - Unit.default is used automatically
subject.on_next("data")        # Emit actual data

# Unsubscribe
subscription.dispose()

# Dispose subject
subject.dispose()
```
```console
Hello, World!
Hello, World!
Hello, World!
```

**Unit Type**: Unit is a special type used to represent the absence of a meaningful value, particularly for signals that don't carry data. When you call `on_next()` without arguments, `Unit.default` is automatically used.

Only the `on_next()` method is implemented.<br>
Unsubscribing from both the source and the subscriber can be done using `dispose()`.

#### Ignoring Stream Values

You can also omit the argument if it's not needed. When you don't need the emitted value, use a parameter-less function to ignore the stream values:

```gdscript
var subject := Subject.new()
var subscription := subject.subscribe(func(): print("Hello, World!")) # No argument
subject.on_next(Unit.default)
```

### BehaviourSubject

BehaviourSubject is a variant of Subject that requires an initial value and emits its current value whenever it is subscribed to.

```gdscript
var status := BehaviourSubject.new("idle")

# Subscribe - immediately gets current value
status.subscribe(func(x): print("Status: ", x))

# Update status
status.on_next("loading")
status.on_next("complete")

# New subscriber gets the latest value immediately
status.subscribe(func(x): print("New subscriber: ", x))

# Dispose
status.dispose()
```
```console
Status: idle
Status: loading
Status: complete
New subscriber: complete
```

### ReactiveProperty

ReactiveProperty is a two-way bindable property that notifies subscribers when its value changes. Unlike Subject or BehaviourSubject, you interact with it through its `value` property rather than calling `on_next()`.

```gdscript
var health := ReactiveProperty.new(100.0)

# Get the current value
print(health.value)

# Subscribe to value changes
health.subscribe(func(x): print(x))

# Update the value (triggers notifications)
health.value = 50.0

# Dispose
health.dispose()
```
```console
100
100
50
```

**Key Features:**
- **Direct value access**: Read and write via `.value` property
- **Automatic notifications**: Subscribers are notified on value changes
- **Initial value emission**: New subscribers immediately receive the current value
- **Equality check**: By default, only emits when the new value differs from the old value

**For advanced use cases** requiring value transformation or custom update logic, use [CustomReactiveProperty](#customizing-reactiveproperty-behavior) instead.

## Disposable Pattern

All Observable classes and subscriptions implement the Disposable pattern for automatic cleanup. This is essential for preventing memory leaks and managing resource lifecycles properly.

### Automatic Disposal with add_to()

If the class being used inherits from the [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) class, calling `add_to(self)` will associate the dispose method with the [tree_exiting](https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-signal-tree-exiting) signal:

```gdscript
extends Node

@onready var _subject := Subject.new()

func _ready() -> void:
	# Will dispose subject when node exiting
	_subject.add_to(self)

	# Will dispose subscription when node exiting
	_subject.subscribe(print).add_to(self)
```

### Using Arrays for Manual Management

The argument for `add_to()` can also accept an `Array` for manual disposal management:

```gdscript
var bag: Array = []
subject.add_to(bag)
subject.subscribe(print).add_to(bag)

for d in bag:
	d.dispose()
```

For more convenient management of multiple disposables, consider using `DisposableBag` (see below).

### DisposableBag

DisposableBag is a convenient container class for managing multiple Disposable objects. It automatically disposes all contained items when the bag itself is disposed.

```gdscript
extends Node

@onready var _subject1 := Subject.new()
@onready var _subject2 := Subject.new()
@onready var _bag := DisposableBag.new()

func _ready() -> void:
	# Add observable to the bag
	_bag.add(_subject1, _subject2)

	# Add subscription to the bag
	_subject1.subscribe(print).add_to(_bag)
	_bag.add(_subject2.subscribe(print)) # same above

	# The bag can be auto-disposed when Node exiting
	_bag.add_to(self)

	# Manual cleanup options:
	_bag.clear()   # Disposes all items but bag can still be used
	_bag.dispose() # Disposes all items and makes bag unusabl
```

DisposableBag provides several advantages over manual Array management:
- **Automatic disposal**: All items are disposed when the bag is disposed
- **Flexibility**: Accepts any object with a `dispose()` method
- **Convenience methods**: `clear()` for manual cleanup, `add()` for easy addition
- **Self-disposal**: The bag itself inherits from Disposable and can use `add_to()`

## Read-Only Pattern

Sometimes you want to expose observables to external code while preventing them from emitting new values. This is where the read-only pattern comes in - it allows you to maintain internal control over event emission while providing a safe subscription interface.

### Exposing Subject/BehaviourSubject as Observable

You can cast Subject or BehaviourSubject to Observable to hide emit methods like `on_next()` and safely expose only subscription functionality to external consumers:

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

This pattern allows you to manage event emission internally while providing a clean, read-only interface for external subscribers.

### Exposing ReactiveProperty as ReadOnlyReactiveProperty

ReadOnlyReactiveProperty is the base class for ReactiveProperty that provides safe external access by hiding write operations. This allows you to manage values internally while exposing only read and subscription capabilities to external consumers:

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

This pattern is particularly useful for game objects that need to expose their state to other systems while maintaining strict control over how that state can be modified.

## Factory Methods

### of
```gdscript
Observable.of(1, 2, 3).subscribe(print)
```
```console
1
2
3
```

Creates an Observable that emits a sequence of values provided as arguments. The values are emitted synchronously when subscribed. This is useful for creating simple test data or converting known values into an observable stream.

### range
```gdscript
Observable.range(1, 3).subscribe(print)
```
```console
1
2
3
```

Creates an Observable that emits a sequence of integers within a specified range. The first parameter is the start value, and the second is the count of values to emit.

### from_signal
```gdscript
Observable \
	.from_signal($Button.pressed) \
	.subscribe(print)
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

Observable.merge(s1, s2, s3).subscribe(arr.push_back)

s1.on_next("foo")
s2.on_next("bar")
s3.on_next("baz")
```
```console
["foo", "bar", "baz"]
```

Combines multiple Observable streams into a single stream that emits values as they arrive from any source.

## Operators

Operators allow you to transform, filter, and control the flow of observable streams. Chain multiple operators together to create complex data processing pipelines.

### Transformation Operators

#### select / map
```gdscript
subject \
	.select(func(x): return x * 2) \
	.subscribe(arr.push_back)

subject.on_next(1)
subject.on_next(2)
```
```console
[2, 4]
```

Transforms each emitted value by applying a function. Also known as "map" in other reactive programming libraries. `map()` is an alias for `select()`.

#### scan
```gdscript
subject \
	.scan(0, func(acc, x): return acc + x) \
	.subscribe(arr.push_back)

subject.on_next(1)
subject.on_next(2)
subject.on_next(3)
```
```console
[1, 3, 6]
```

Accumulates values using an accumulator function starting with the provided initial value. Emits the accumulated result for each emission. Useful for calculating running totals, cumulative counters, or building up complex aggregated values.

### Filtering Operators

#### where / filter
```gdscript
subject \
	.where(func(x): return x >= 2) \
	.subscribe(arr.push_back)

subject.on_next(1)
subject.on_next(2)
subject.on_next(3)
```
```console
[2, 3]
```

Filters emitted values, allowing only those that satisfy the predicate condition to pass through. Also known as "filter" in other reactive libraries. `filter()` is an alias for `where()`.

### Limiting Operators

#### take
```gdscript
subject.take(2).subscribe(arr.push_back)

subject.on_next(1)
subject.on_next(2)
subject.on_next(3)
```
```console
[1, 2]
```

Emits only the first N values from the source observable, then automatically completes the subscription.

#### skip
```gdscript
subject.skip(2).subscribe(arr.push_back)

subject.on_next(1)
subject.on_next(2)
subject.on_next(3)
subject.on_next(1)
```
```console
[3, 1]
```

Ignores the first N emissions and only starts emitting values after that count is reached.

#### take_while
```gdscript
subject \
	.take_while(func(x): return x <= 1) \
	.subscribe(arr.push_back)

subject.on_next(1)
subject.on_next(2)
subject.on_next(1)
```
```console
[1]
```

Emits values as long as the predicate function returns true. Once the condition becomes false, the observable completes.

#### take_until
```gdscript
var source := Subject.new()
var stop := Subject.new()

source \
	.take_until(stop) \
	.subscribe(arr.push_back)

source.on_next(1)
source.on_next(2)
stop.on_next()  # Stop signal
source.on_next(3)
```
```console
[1, 2]
```

Emits values until another observable emits. Once the provided observable emits any value, the source subscription completes. This is useful for combining multiple observables to control when a stream should stop.

#### skip_while
```gdscript
subject \
	.skip_while(func(x): return x <= 1) \
	.subscribe(arr.push_back)

subject.on_next(1)
subject.on_next(2)
subject.on_next(1)
```
```console
[2, 1]
```

Skips values while the predicate function returns true, then emits all subsequent values regardless of the condition.

### Time-based Operators

#### debounce
```gdscript
subject.debounce(0.1).subscribe(arr.push_back)

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

#### throttle_last / sample
```gdscript
subject.throttle_last(0.1).subscribe(arr.push_back)
# sample() is an alias for throttle_last()
# subject.sample(0.1).subscribe(arr.push_back)

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

## Advanced Features

### Customizing ReactiveProperty Behavior

For advanced use cases requiring value transformation or custom update logic, use **CustomReactiveProperty** instead of ReactiveProperty. CustomReactiveProperty is an abstract base class that provides two virtual methods you can override:

- **`_transform_value(input_value: Variant) -> Variant`**: Transforms values before they are stored and emitted. Useful for normalizing, clamping, or formatting input values.
- **`_should_update(old_value: Variant, new_value: Variant) -> bool`**: Determines whether a value change should trigger an update. The default implementation performs equality checking.

The value update process follows this order:
1. `_transform_value()` converts the input value
2. `_should_update()` checks if the transformed value should be stored
3. If approved, the transformed value is stored and emitted to subscribers

#### Example: Clamping Values with _transform_value()

Use `_transform_value()` to automatically correct values to a valid range:

```gdscript
class_name ClampedHP extends CustomReactiveProperty

var min_value: float
var max_value: float

func _init(initial: float, min_val: float, max_val: float) -> void:
	min_value = min_val
	max_value = max_val
	super._init(initial)

func _transform_value(input_value: Variant) -> Variant:
	return clampf(input_value, min_value, max_value)
```

Usage example:
```gdscript
var health := ClampedHP.new(50.0, 0.0, 100.0)
health.subscribe(func(value): print("Health: ", value))

health.value = 75.0   # Within range - emits 75.0
health.value = 150.0  # Clamped to max - emits 100.0
health.value = -10.0  # Clamped to min - emits 0.0
health.value = -5.0   # Clamped to 0.0 again - no emission (same value)
```
```console
Health: 50.0
Health: 75.0
Health: 100.0
Health: 0.0
```

#### Example: Disabling Equality Check with _should_update()

Use `_should_update()` to control when updates should occur. This example always updates, even when values are equal:

```gdscript
class_name AlwaysUpdateRP extends CustomReactiveProperty

func _should_update(_old_value: Variant, _new_value: Variant) -> bool:
	return true  # Always update, regardless of equality
```

Usage example:
```gdscript
var counter := AlwaysUpdateRP.new(1)
counter.subscribe(func(value): print("Value: ", value))

counter.value = 1  # Emits even though value is the same
counter.value = 2  # Emits
counter.value = 2  # Emits even though value is the same
```
```console
Value: 1
Value: 1
Value: 2
Value: 2
```

**Note:** You can override both methods in the same class to combine transformation and custom update logic.

### Awaiting Observables

All core Observable classes support awaiting the next value emission using the `wait()` method, similar to Godot's built-in signal await functionality.

```gdscript
# Basic await usage
var next_value = await subject.wait()
var health_change = await health.wait()
```

#### Class-specific Behavior

**Subject**: Waits for the next `on_next()` call.
```gdscript
var subject := Subject.new()

# This waits for the next emission
var result: String = await subject.wait()  # Will wait
```

**BehaviourSubject**: Waits for the next emission, not the current value.
```gdscript
var status := BehaviourSubject.new("idle")
var result: String = await status.wait() # To wait for next change:
```

**ReactiveProperty**: Waits for the next value change.
```gdscript
var health := ReactiveProperty.new(100)
health.value = 90  # This change occurs immediately

# Wait for the next change
var new_health: int = await health.wait()
```

**merge**: Waits for the first emission from any of the source observables.
```gdscript
var s1 := Subject.new()
var s2 := Subject.new()

# Will resolve with whichever emits first
var first_result: String = await Observable.merge(s1, s2).wait()

s2.on_next("second wins") # first_result becomes "second wins"
s1.on_next("first")       # This won't affect the await result
```

#### Important Notes

- `wait()` returns `null` if the observable is disposed
- Operator chains (like `.select().where()`) don't support direct await - subscribe instead
- For immediate values, use `.value` property on BehaviourSubject/ReactiveProperty
- `merge().wait()` resolves with the first emission from any source and automatically disposes subscriptions to other sources

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
Loaded health: 100
Loaded status: idle
```

**Note:** Subscriptions and internal state are not preserved during serialization - only the current values (`_value` for ReactiveProperty and `_latest_value` for BehaviourSubject) are saved and restored.
