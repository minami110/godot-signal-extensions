class_name ReadOnlyReactiveProperty extends Observable

var _value: Variant


## Get the current value of the property.
## Same as [method ReadOnlyReactiveProperty.value].
var current_value: Variant:
	get:
		return _value
