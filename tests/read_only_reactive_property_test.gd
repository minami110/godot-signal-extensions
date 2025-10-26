extends GdUnitTestSuite

func test_cast_from_reactive_property() -> void:
	# ReactiveProperty を ReadOnlyReactiveProperty としてキャストできることを確認
	var rp_source := ReactiveProperty.new(42)
	var ro_rp := rp_source as ReadOnlyReactiveProperty

	assert_object(ro_rp).is_not_null()
	assert_object(ro_rp).is_instanceof(ReadOnlyReactiveProperty)
	assert_object(ro_rp).is_instanceof(Observable)


func test_current_value_read() -> void:
	# current_value プロパティから値を読み取れることを確認
	var rp_source := ReactiveProperty.new(100)
	var ro_rp := rp_source as ReadOnlyReactiveProperty

	assert_int(ro_rp.current_value).is_equal(100)

	# ソースの値を変更すると、読み取り専用プロパティ経由でも変更後の値を取得できる
	rp_source.value = 200
	assert_int(ro_rp.current_value).is_equal(200)


func test_subscribe_emits_current_value_immediately() -> void:
	# ReadOnlyReactiveProperty として subscribe すると即座に現在の値が emit されることを確認
	var rp_source := ReactiveProperty.new("initial")
	var ro_rp := rp_source as ReadOnlyReactiveProperty

	var received_values: Array = []
	ro_rp.subscribe(received_values.push_back)

	# subscribe 時に即座に現在の値が emit される
	assert_array(received_values).contains_exactly("initial")


func test_subscribe_receives_updates() -> void:
	# ReadOnlyReactiveProperty として subscribe しても、値の更新を受け取れることを確認
	var rp_source := ReactiveProperty.new(1)
	var ro_rp := rp_source as ReadOnlyReactiveProperty

	var received_values: Array = []
	ro_rp.subscribe(received_values.push_back)

	# ソースの値を変更
	rp_source.value = 2
	rp_source.value = 3

	assert_array(received_values).contains_exactly(1, 2, 3)


func test_multiple_subscribers() -> void:
	# ReadOnlyReactiveProperty に複数の subscriber がある場合の動作確認
	var rp_source := ReactiveProperty.new("A")
	var ro_rp := rp_source as ReadOnlyReactiveProperty

	var subscriber1_values: Array = []
	var subscriber2_values: Array = []

	ro_rp.subscribe(
		func(value: String) -> void:
			subscriber1_values.push_back(value)
	)

	ro_rp.subscribe(
		func(value: String) -> void:
			subscriber2_values.push_back(value)
	)

	# 両方の subscriber に初期値が emit される
	assert_array(subscriber1_values).contains_exactly("A")
	assert_array(subscriber2_values).contains_exactly("A")

	# 値を変更
	rp_source.value = "B"

	# 両方の subscriber が更新を受け取る
	assert_array(subscriber1_values).contains_exactly("A", "B")
	assert_array(subscriber2_values).contains_exactly("A", "B")


func test_various_types() -> void:
	# 様々な型で ReadOnlyReactiveProperty が正しく動作することを確認
	var test_cases := [
		42,
		3.14,
		"Hello",
		Vector2(10, 20),
		null,
	]

	for test_value: Variant in test_cases:
		var rp_source := ReactiveProperty.new(test_value)
		var ro_rp := rp_source as ReadOnlyReactiveProperty

		assert_that(ro_rp.current_value).is_equal(test_value)

		var received_value: Array = [null]
		ro_rp.subscribe(
			func(value: Variant) -> void:
				received_value[0] = value
		)

		assert_that(received_value[0]).is_equal(test_value)


func test_with_operators() -> void:
	# ReadOnlyReactiveProperty でも Observable のオペレーターが使用できることを確認
	var rp_source := ReactiveProperty.new(0)
	var ro_rp := rp_source as ReadOnlyReactiveProperty

	var filtered_values: Array = []

	# where オペレーターを使用
	ro_rp.where(
		func(x: int) -> bool:
			return x > 5
	).subscribe(filtered_values.push_back)

	# 値を変更
	rp_source.value = 3
	rp_source.value = 7
	rp_source.value = 4
	rp_source.value = 10

	# フィルタリングされた値のみが emit される（初期値0は5以下なので無視）
	assert_array(filtered_values).contains_exactly(7, 10)
