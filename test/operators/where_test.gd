extends GdUnitTestSuite


func test_standard() -> void:
	var result := []
	var subject := Subject.new()
	var d := subject \
		.where(func(x): return x >= 20) \
		.subscribe(func(i): result.push_back(i))

	subject.on_next(10)
	subject.on_next(20)
	subject.on_next(30)
	subject.on_next(10)
	d.dispose()
	subject.on_next(40)

	assert_array(result, true).is_equal([20, 30])

func test_merge_behaviour() -> void:
	var result := []
	var subject := Subject.new()
	var d := subject \
		.where(func(x): return x > 20) \
		.where(func(x): return x < 30) \
		.subscribe(func(i): result.push_back(i))

	subject.on_next(10)
	subject.on_next(20)
	subject.on_next(25)
	subject.on_next(30)
	d.dispose()
	subject.on_next(25)
	assert_array(result, true).is_equal([25])

func test_two_subscribers() -> void:
	var result1 := []
	var result2 := []

	var subject := Subject.new()
	var where1 := subject.where(func(x): return x >= 30)
	var _where2 := where1.where(func(x): return x < 30)

	# two subscribers
	where1.subscribe(func(x): result1.push_back(x))
	where1.subscribe(func(x): result2.push_back(x))

	subject.on_next(29)
	subject.on_next(30)
	assert_array(result1, true).is_equal([30])
	assert_array(result2, true).is_equal([30])