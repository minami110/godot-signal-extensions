class_name Unit extends RefCounted

static var default := Unit.new()

func _init() -> void:
	pass

func _to_string() -> String:
	return "<Unit#%d>" % get_instance_id()
