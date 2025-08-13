# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4 plugin called "Signal Extensions" that extends GDScript's Signal and Callable classes. The plugin provides reactive programming features inspired by Cysharp/R3, focusing on making it easier to unsubscribe from Godot signals and providing observable stream operators.

## Development Commands

### Testing
- **Run all tests**: Use GDUnit4 testing framework
  - Tests are located in `test/` directory
  - Project is configured to use GDUnit4 plugin (enabled in project.godot)
  - CI runs tests with: `res://test/` path
  - Tests extend `GdUnitTestSuite` class

### Linting and Code Quality
- The project has strict GDScript warnings enabled:
  - `untyped_declaration=1`
  - `unsafe_cast=1` 
  - `unsafe_call_argument=1`
  - Addon warnings are not excluded (`exclude_addons=false`)

## Code Architecture

### Core Classes Hierarchy
```
Disposable (base class)
├── Observable (abstract)
│   ├── Subject
│   ├── BehaviourSubject 
│   ├── ReactiveProperty
│   └── Operator classes (_Select, _Where, _Take, etc.)
├── Subscription
└── ReadOnlyReactiveProperty
```

### Plugin Structure
- **Main plugin files**: `addons/signal_extensions/`
  - Core classes: `observable.gd`, `subject.gd`, `reactive_property.gd`, etc.
  - **Factories**: `factories/` - contains `from_signal.gd`, `merge.gd`
  - **Operators**: `operators/` - contains stream operators like `debounce.gd`, `select.gd`, `where.gd`, etc.
  - Plugin configuration: `plugin.cfg`

### Key Design Patterns
- **Abstract base classes**: `Observable` is abstract with `_subscribe_core()` method
- **Method chaining**: Operators return new Observable instances for chaining
- **Disposable pattern**: All observables implement disposal for cleanup
- **Factory methods**: Static methods on `Observable` class for creating observables
- **Operator optimization**: Some operators like `select` can be combined to avoid nesting

### Testing Structure
- Tests mirror the source structure in `test/` directory
- Integration tests in `integration_test.gd` test operator combinations
- Each operator and core class has corresponding test file
- Tests use GDUnit4 assertions (`assert_int()`, etc.)

### Key Features
- **Observable streams**: Subject, BehaviourSubject, ReactiveProperty
- **Signal conversion**: `Observable.from_signal()` converts Godot signals
- **Stream operators**: debounce, select, where, take, skip, throttle_last, etc.
- **Automatic disposal**: `add_to(Node)` connects disposal to `tree_exiting` signal
- **Await support**: `wait()` method allows awaiting observables like signals

## Development Notes

- Project targets Godot 4.3+ (currently configured for 4.5)
- Uses GL Compatibility rendering method
- Plugin version is managed in `plugin.cfg`
- CI runs on Ubuntu 22.04 with Godot 4.4.1
- Repository uses conventional Git workflow with `main` branch