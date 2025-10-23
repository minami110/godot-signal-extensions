@abstract
class_name ReadOnlyReactiveProperty
extends Observable

# インスタンス変数
var _value: Variant

# プロパティ（getter/setter）
## Get the current value of the property.
## Same as [method ReadOnlyReactiveProperty.value].
var current_value: Variant:
	get:
		return _value
