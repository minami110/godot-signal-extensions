# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

Godot 4 plugin extending Signal and Callable with reactive programming features (inspired by Cysharp/R3). Simplifies signal management through automatic disposal and observable streams.

## Development Environment

### Requirements
- **Godot Version**: 4.5.1
- **GDScript Version**: 2.0+

### Plugins
- **Signal Extensions** (`addons/signal_extensions/plugin.cfg`) - Main plugin
- **GDUnit4** (`addons/gdUnit4/plugin.cfg`) - Testing framework

### Project Configuration
Strict type checking enabled:
```gdscript
gdscript/warnings/untyped_declaration=1
gdscript/warnings/unsafe_cast=1
gdscript/warnings/unsafe_call_argument=1
```

## Development Commands

### Testing
**Use the `gdscript-test-skill` skill for all test operations:**
```bash
/gdscript-test-skill
```

### File Operations
```bash
/gdscript-file-manager-skill  # Move, rename, delete GDScript files
```

### Code Validation
```bash
/gdscript-validate-skill  # Validate GDScript changes
```

## Code Architecture

### Core Classes
```
Disposable → Observable (Subject, BehaviourSubject, ReactiveProperty, Operators)
          → Subscription, DisposableBag, ReadOnlyReactiveProperty
```

### Plugin Location
`addons/signal_extensions/` - Core classes, factories/, operators/

## Key Features

### Observable Types
- **Subject**: Manual emission hot observable
- **BehaviourSubject**: Subject with current value
- **ReactiveProperty**: Two-way bindable property

### Operators
- **Transformation**: select, where
- **Limiting**: take, skip, take_while, skip_while
- **Time-based**: debounce, throttle_last
- **Combining**: merge

### Disposal Patterns
```gdscript
# Manual disposal
subscription.dispose()

# Automatic disposal (recommended)
observable.subscribe(callback).add_to(self)
```

## Best Practices

**Type Safety**: Explicit types everywhere (params, returns, vars) - warnings are errors

**Memory**: Always dispose subscriptions - prefer `.add_to(node)` for automatic cleanup

**Testing**: Files end with `_test.gd`, extend `GdUnitTestSuite`, use GDUnit4 assertions

**Style**: Method chaining for operators, lambdas for simple transformations
