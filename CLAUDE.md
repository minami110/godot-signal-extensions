# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview
Godot 4 plugin extending Signal and Callable with reactive programming features (inspired by Cysharp/R3). Simplifies signal management through automatic disposal and observable streams.

## GitHub Repository
- Repository: https://github.com/minami110/godot-signal-extensions
- Main branch: main


## Key Directories
- `addons/signal_extensions`: Main plugin
- `addons/gdUnit4`: Testing framework, **DO NOT EDIT**
- `tests/`: Test files


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

## Code Style Guidelines
- **Use Context7**: Always use the Context7 MCP Server to verify the latest Godot Engine and GDScript syntax, API (functions, classes, signatures) when creating or modifying files.
- **YAGNI**: Do not add features, abstractions, or configuration unless currently required by the codebase or tests.
- **GDScript Style**: Follow Godot 4.5 style guide for formatting, documentation, and type hints (use gdscript-format-skill for details)
- **Resource Management**: Use gdscript-file-manager-skill when moving, renaming, or deleting GDScript files

## PR Guidelines
- target branch: origin/main
- Verify API changes with Context7 before making changes
- Include summary of changes in PR description
