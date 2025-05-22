extends GdUnitTestSuite

var _result_int: int
signal noparms
signal oneparm(x: float)
signal twoparms(x: float, y: String)

func test_from_signal_noparm() -> void:
	_result_int = 0
	var d1 := Observable.from_signal(noparms).subscribe(func(u: Unit) -> void:
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
	var d1 := Observable.from_signal(oneparm).subscribe(func(x: int) -> void:
		_result_int += x
	)
	oneparm.emit(2)
	assert_int(_result_int).is_equal(2)

	d1.dispose()
	oneparm.emit(3)
	assert_int(_result_int).is_equal(2)

func test_from_signal_twoparms() -> void:
	@warning_ignore("untyped_declaration")
	await assert_error(func(): Observable.from_signal(twoparms).subscribe(func(_x): pass )) \
		.is_push_error("signal should have 0 or 1 argument. twoparms has 2 arguments")
