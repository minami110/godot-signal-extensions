extends GdUnitTestSuite

var _list: Array[int]

func test_merge() -> void:
	_list = []
	var s1 := Subject.new()
	var s2 := Subject.new()
	var s3 := Subject.new()

	var d := Observable \
		.merge(s1, s2, s3) \
		.subscribe(func(x: int) -> void: _list.push_back(x))
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


func test_merge_wait1() -> void:
	var s1: Subject = Subject.new()
	var s2: Subject = Subject.new()

	s2.on_next.call_deferred(2)
	s1.on_next.call_deferred(3)

	var merge := Observable.merge(s1, s2)
	var result: Variant = await merge.wait()

	assert_that(result).is_equal(2)


func test_merge_wait2() -> void:
	var s1: Subject = Subject.new()
	var s2: Subject = Subject.new()

	s1.on_next.call_deferred("foo")

	var merge := Observable.merge(
		s1.select(func(_x: Variant) -> int: return 10),
		s2.select(func(_x: Variant) -> int: return 20)
	)
	var result: Variant = await merge.wait()

	assert_that(result).is_equal(10)


func test_merge_empty_sources_error() -> void:
	assert_failure(func() -> void: Observable.merge(), "Observable.merge requires at least one source")


func test_merge_invalid_type_error() -> void:
	var s1 := Subject.new()
	assert_failure(func() -> void: Observable.merge(s1, "not_observable"), "All sources must be Observable instances")


func test_merge_with_array_argument() -> void:
	_list = []
	var s1 := Subject.new()
	var s2 := Subject.new()
	var sources: Array[Observable] = [s1, s2]

	var d := Observable.merge(sources).subscribe(func(x: int) -> void: _list.push_back(x))

	s1.on_next(10)
	s2.on_next(20)
	s1.on_next(30)

	d.dispose()
	assert_array(_list, true).is_equal([10, 20, 30])


func test_merge_array_argument_empty_error() -> void:
	var empty_sources: Array[Observable] = []
	assert_failure(func() -> void: Observable.merge(empty_sources), "Observable.merge requires at least one source")
