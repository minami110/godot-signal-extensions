extends GdUnitTestSuite

var _list: Array[int]

func test_merge() -> void:
	_list = []
	var s1 := Subject.new()
	var s2 := Subject.new()
	var s3 := Subject.new()

	var d := Observable \
		.merge([s1, s2, s3]) \
		.subscribe(func(x): _list.push_back(x))
	assert_array(_list, true).is_equal([])

	s1.on_next(1)
	s2.on_next(2)
	s3.on_next(3)
	s1.on_next(4)
	s3.on_next(5)

	s2.dispose()
	s1.on_next(6)
	s1.dispose()
	s3.on_next(7)

	d.dispose()
	s3.on_next(8)
	assert_array(_list, true).is_equal([1, 2, 3, 4, 5, 6, 7])
