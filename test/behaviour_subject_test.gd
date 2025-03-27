extends GdUnitTestSuite

@warning_ignore("unused_parameter")
@warning_ignore("unused_variable")
@warning_ignore("return_value_discarded")


func standard() -> void:
	var result: Array[int] = []

	var subject := BehaviourSubject.new(5)
	subject.subscribe(func(i: int) -> void:
		result.append(i)
	)

	subject.on_next(10)
	subject.on_next(10)
	subject.dispose()
	subject.on_next(20)
	assert_array(result).is_equal([5, 10, 10])
