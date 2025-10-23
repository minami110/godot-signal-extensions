extends GdUnitTestSuite

func test_unit_default_is_singleton() -> void:
	# Unit.default は常に同じインスタンスであることを確認
	var u1 := Unit.default
	var u2 := Unit.default

	assert_object(u1).is_same(u2)
	assert_int(u1.get_instance_id()).is_equal(u2.get_instance_id())


func test_unit_is_instance_of_unit() -> void:
	# Unit.default が Unit クラスのインスタンスであることを確認
	var u := Unit.default

	assert_object(u).is_instanceof(Unit)
	assert_object(u).is_instanceof(RefCounted)


func test_unit_with_subject() -> void:
	# Unit を Subject で使用した際の動作確認
	var result_count: Array[int] = [0]
	var subject := Subject.new()

	subject.subscribe(
		func(u: Unit) -> void:
			assert_object(u).is_instanceof(Unit)
			assert_object(u).is_same(Unit.default)
			result_count[0] += 1
	)

	subject.on_next(Unit.default)
	assert_int(result_count[0]).is_equal(1)

	subject.on_next(Unit.default)
	assert_int(result_count[0]).is_equal(2)


func test_unit_with_subject_on_next_null() -> void:
	# Subject.on_next() を引数なしで呼ぶと Unit.default が emit されることを確認
	var received_value: Array = []
	var subject := Subject.new()

	subject.subscribe(
		func(value: Variant) -> void:
			received_value.push_back(value)
	)

	# on_next() を引数なしで呼ぶ
	subject.on_next()

	assert_object(received_value[0]).is_instanceof(Unit)
	assert_object(received_value[0]).is_same(Unit.default)


func test_new_unit_instance_is_not_singleton() -> void:
	# 新しく Unit インスタンスを作成した場合、Unit.default とは異なることを確認
	var new_unit := Unit.new()
	var default_unit := Unit.default

	assert_object(new_unit).is_not_same(default_unit)
	assert_int(new_unit.get_instance_id()).is_not_equal(default_unit.get_instance_id())

	# しかし両方とも Unit クラスのインスタンス
	assert_object(new_unit).is_instanceof(Unit)
	assert_object(default_unit).is_instanceof(Unit)
