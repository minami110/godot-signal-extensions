extends GdUnitTestSuite
## Observable 基底クラスの共通機能テスト
##
## Observable は抽象クラスのため、Subject などの具象クラスを使用してテストする

# テスト用のシグナル
signal test_signal
signal test_signal_with_arg(value: int)

# =============================================================================
# subscribe() メソッドのテスト
# =============================================================================


func test_subscribe_with_one_argument_callback() -> void:
	# 1引数のコールバックで subscribe できることを確認
	var received_values: Array = []
	var subject := Subject.new()

	subject.subscribe(received_values.push_back)

	subject.on_next(10)
	subject.on_next(20)

	assert_array(received_values).contains_exactly([10, 20])


func test_subscribe_with_zero_argument_callback() -> void:
	# 0引数のコールバックで subscribe できることを確認
	var call_count: Array[int] = [0]
	var subject := Subject.new()

	subject.subscribe(
		func() -> void:
			call_count[0] += 1
	)

	subject.on_next(10)
	subject.on_next(20)

	assert_int(call_count[0]).is_equal(2)

# =============================================================================
# オペレーター最適化のテスト
# =============================================================================


func test_select_chaining_optimization() -> void:
	# select を連続して呼び出すと最適化されることを確認
	var subject := Subject.new()
	var result: Array[int] = [0]

	# select を2回連続で呼び出す
	var observable := subject.select(
		func(x: int) -> int:
			return x * 2
	).select(
		func(x: int) -> int:
			return x + 10
	)

	# 最適化により、Select オブジェクトのソースは元の subject になる
	assert_object(observable).is_instanceof(Observable)

	observable.subscribe(
		func(value: int) -> void:
			result[0] = value
	)

	subject.on_next(5)
	# 5 * 2 = 10, 10 + 10 = 20
	assert_int(result[0]).is_equal(20)


func test_where_chaining_optimization() -> void:
	# where を連続して呼び出すと最適化されることを確認
	var subject := Subject.new()
	var filtered_values: Array = []

	# where を2回連続で呼び出す
	var observable := subject.where(
		func(x: int) -> bool:
			return x > 5
	).where(
		func(x: int) -> bool:
			return x < 15
	)

	observable.subscribe(filtered_values.push_back)

	subject.on_next(3)
	subject.on_next(7)
	subject.on_next(10)
	subject.on_next(20)

	# 5 < x < 15 の値のみが emit される
	assert_array(filtered_values).contains_exactly([7, 10])


func test_take_while_chaining_optimization() -> void:
	# take_while を連続して呼び出すと最適化されることを確認
	var subject := Subject.new()
	var taken_values: Array = []

	# take_while を2回連続で呼び出す
	var observable := subject.take_while(
		func(x: int) -> bool:
			return x < 20
	).take_while(
		func(x: int) -> bool:
			return x < 15
	)

	observable.subscribe(taken_values.push_back)

	subject.on_next(5)
	subject.on_next(10)
	subject.on_next(12)
	subject.on_next(18) # 15 < 18 なのでここで停止
	subject.on_next(25)

	# 両方の条件を満たす値のみが emit される
	assert_array(taken_values).contains_exactly([5, 10, 12])


func test_skip_chaining_optimization() -> void:
	# skip を連続して呼び出すと最適化されることを確認
	var subject := Subject.new()
	var skipped_values: Array = []

	# skip を2回連続で呼び出す (skip(2) + skip(1) = skip(3))
	var observable := subject.skip(2).skip(1)

	observable.subscribe(skipped_values.push_back)

	subject.on_next(1)
	subject.on_next(2)
	subject.on_next(3)
	subject.on_next(4)
	subject.on_next(5)

	# 最初の3つがスキップされる
	assert_array(skipped_values).contains_exactly([4, 5])


func test_take_chaining_optimization() -> void:
	# take を連続して呼び出すと最適化されることを確認
	var result: Array = []

	# take を2回連続で呼び出す (take(3) + take(2) = take(5))
	# 注意: take の最適化は加算される
	Observable.range(1, 6).take(3).take(2).subscribe(result.push_back)

	# take(3+2=5) なので最初の5つが emit される
	assert_array(result).contains_exactly([1, 2, 3, 4, 5])


func test_sample_is_alias_for_throttle_last() -> void:
	# sample() が throttle_last() のエイリアスであることを確認
	var subject := Subject.new()

	var sample_observable := subject.sample(0.1)
	var throttle_observable := subject.throttle_last(0.1)

	# 両方とも同じ型のオブジェクトを返す
	assert_object(sample_observable).is_not_null()
	assert_object(throttle_observable).is_not_null()

# =============================================================================
# ファクトリーメソッドのテスト
# =============================================================================


func test_from_signal_with_no_args() -> void:
	# 引数なしの Signal から Observable を作成
	var received_values: Array = []

	var observable := Observable.from_signal(test_signal)
	observable.subscribe(received_values.push_back)

	test_signal.emit()
	test_signal.emit()

	# Unit.default が2回 emit される
	assert_int(received_values.size()).is_equal(2)
	assert_object(received_values[0]).is_instanceof(Unit)
	assert_object(received_values[1]).is_instanceof(Unit)


func test_from_signal_with_one_arg() -> void:
	# 1引数の Signal から Observable を作成
	var received_values: Array = []

	var observable := Observable.from_signal(test_signal_with_arg)
	observable.subscribe(received_values.push_back)

	test_signal_with_arg.emit(42)
	test_signal_with_arg.emit(100)

	assert_array(received_values).contains_exactly([42, 100])


func test_merge_with_multiple_observables() -> void:
	# 複数の Observable をマージ
	var subject1 := Subject.new()
	var subject2 := Subject.new()
	var subject3 := Subject.new()

	var merged_values: Array = []
	var merged := Observable.merge(subject1, subject2, subject3)

	merged.subscribe(merged_values.push_back)

	subject1.on_next(1)
	subject2.on_next(2)
	subject3.on_next(3)
	subject1.on_next(4)

	assert_array(merged_values).contains_exactly([1, 2, 3, 4])


func test_merge_with_array() -> void:
	# 配列形式で Observable をマージ
	var subject1 := Subject.new()
	var subject2 := Subject.new()

	var merged_values: Array = []
	var merged := Observable.merge([subject1, subject2])

	merged.subscribe(merged_values.push_back)

	subject1.on_next(10)
	subject2.on_next(20)

	assert_array(merged_values).contains_exactly([10, 20])

# =============================================================================
# オペレーターのメソッドチェーンテスト
# =============================================================================


func test_complex_operator_chain() -> void:
	# 複数のオペレーターを組み合わせた複雑なチェーン
	var subject := Subject.new()
	var result_values: Array = []

	subject.where(
		func(x: int) -> bool:
			return x > 0
	).select(
		func(x: int) -> int:
			return x * 2
	).skip(1).take(3).subscribe(result_values.push_back)

	subject.on_next(-5) # where でフィルタリング
	subject.on_next(1) # 2 になるが skip でスキップ
	subject.on_next(2) # 4
	subject.on_next(3) # 6
	subject.on_next(4) # 8
	subject.on_next(5) # 10 だが take(3) で終了

	assert_array(result_values).contains_exactly([4, 6, 8])


func test_take_skip() -> void:
	var result: Array[int] = []
	var subject := Subject.new()
	var d := subject.take(3).skip(1).subscribe(result.append)

	subject.on_next(10)
	assert_array(result).is_empty()
	subject.on_next(20)
	assert_array(result).contains_exactly([20])
	d.dispose()
	subject.on_next(30)
	assert_array(result).contains_exactly([20])


func test_skip_take() -> void:
	var result: Array[int] = []
	var rp := ReactiveProperty.new(10)
	var d := rp.skip(2).take(2).subscribe(result.append)
	assert_array(result).is_empty()

	rp.value = 20
	assert_array(result).is_empty()
	rp.value = 30
	assert_array(result).contains_exactly([30])
	d.dispose()
	rp.value = 40
	assert_array(result).contains_exactly([30])


func test_where_skip() -> void:
	var result: Array[int] = []
	var subject := Subject.new()
	var d := subject.where(
		func(i: int) -> bool:
			return i > 10
	).skip(1).subscribe(result.append)

	subject.on_next(10)
	assert_array(result).is_empty()
	subject.on_next(20)
	assert_array(result).is_empty()
	subject.on_next(10)
	assert_array(result).is_empty()
	subject.on_next(20)
	assert_array(result).contains_exactly([20])
	d.dispose()
	subject.on_next(30)
	assert_array(result).contains_exactly([20])
