extends GdUnitTestSuite

signal noparms
signal oneparm(x: float)
signal twoparms(x: float, y: String)
signal threeparms(a: int, b: int, c: int)
signal nineparms(a: int, b: int, c: int, d: int, e: int, f: int, g: int, h: int, i: int)


func test_from_signal_noparm() -> void:
	var result: Array[String] = []
	var d1 := Observable.from_signal(noparms).subscribe(
		func(u: Unit) -> void:
			assert_object(u).is_instanceof(Unit)
			result.append("called")
	)
	noparms.emit()
	assert_array(result).contains_exactly("called")

	d1.dispose()
	noparms.emit()
	assert_array(result).contains_exactly("called")


func test_from_signal_oneparm() -> void:
	var result: Array[int] = []
	var d1 := Observable.from_signal(oneparm).subscribe(result.append)
	oneparm.emit(2)
	assert_array(result).contains_exactly(2)

	d1.dispose()
	oneparm.emit(3)
	assert_array(result).contains_exactly(2)


func test_from_signal_twoparms() -> void:
	var result: Array = []
	var d1 := Observable.from_signal(twoparms).subscribe(result.append_array)
	twoparms.emit(1.0, "ok")
	assert_array(result).contains_exactly(1.0, "ok")

	d1.dispose()
	twoparms.emit(2.0, "ng")
	assert_array(result).contains_exactly(1.0, "ok")


func test_from_signal_threeparms() -> void:
	var result: Array = []
	var d1 := Observable.from_signal(threeparms).subscribe(result.append_array)
	threeparms.emit(1, 2, 3)
	assert_array(result).contains_exactly(1, 2, 3)

	d1.dispose()
	threeparms.emit(4, 5, 6)
	assert_array(result).contains_exactly(1, 2, 3)


func test_from_signal_nineparms() -> void:
	var result: Array = []
	var d1 := Observable.from_signal(nineparms).subscribe(result.append_array)
	nineparms.emit(1, 2, 3, 4, 5, 6, 7, 8, 9)
	assert_array(result).contains_exactly(1, 2, 3, 4, 5, 6, 7, 8, 9)

	d1.dispose()
	nineparms.emit(10, 11, 12, 13, 14, 15, 16, 17, 18)
	assert_array(result).contains_exactly(1, 2, 3, 4, 5, 6, 7, 8, 9)
