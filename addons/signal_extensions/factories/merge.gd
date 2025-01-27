class_name _Merge extends Observable

var _sources: Array[Observable] = []

func _init(sources: Array[Observable]) -> void:
	_sources = sources
