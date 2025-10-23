extends GdUnitTestSuite

var _result_int: int
signal noparms
signal oneparm(x: float)
signal twoparms(x: float, y: String)
signal threeparms(a: int, b: int, c: int)
signal nineparms(a: int, b: int, c: int, d: int, e: int, f: int, g: int, h: int, i: int)


func test_from_signal_noparm() -> void:
	_result_int = 0
	var d1 := Observable.from_signal(noparms).subscribe(
		func(u: Unit) -> void:
			assert_object(u).is_instanceof(Unit)
			_result_int += 1
	)
	noparms.emit()
	assert_int(_result_int).is_equal(1)

	d1.dispose()
	noparms.emit()
	assert_int(_result_int).is_equal(1)


func test_from_signal_oneparm() -> void:
	_result_int = 0
	var d1 := Observable.from_signal(oneparm).subscribe(
		func(x: int) -> void:
			_result_int += x
	)
	oneparm.emit(2)
	assert_int(_result_int).is_equal(2)

	d1.dispose()
	oneparm.emit(3)
	assert_int(_result_int).is_equal(2)


func test_from_signal_twoparms() -> void:
	var result: Array = []
	var d1 := Observable.from_signal(twoparms).subscribe(
		func(arr: Array) -> void:
			result.append_array(arr)
	)
	twoparms.emit(1.0, "ok")
	assert_array(result).is_equal([1.0, "ok"])

	d1.dispose()
	twoparms.emit(2.0, "ng")
	assert_array(result).is_equal([1.0, "ok"])


func test_from_signal_threeparms() -> void:
	var result: Array = []
	var d1 := Observable.from_signal(threeparms).subscribe(
		func(arr: Array) -> void:
			result.append_array(arr)
	)
	threeparms.emit(1, 2, 3)
	assert_array(result).is_equal([1, 2, 3])

	d1.dispose()
	threeparms.emit(4, 5, 6)
	assert_array(result).is_equal([1, 2, 3])


func test_from_signal_nineparms() -> void:
	var result: Array = []
	var d1 := Observable.from_signal(nineparms).subscribe(
		func(arr: Array) -> void:
			result.append_array(arr)
	)
	nineparms.emit(1, 2, 3, 4, 5, 6, 7, 8, 9)
	assert_array(result).is_equal([1, 2, 3, 4, 5, 6, 7, 8, 9])

	d1.dispose()
	nineparms.emit(10, 11, 12, 13, 14, 15, 16, 17, 18)
	assert_array(result).is_equal([1, 2, 3, 4, 5, 6, 7, 8, 9])
