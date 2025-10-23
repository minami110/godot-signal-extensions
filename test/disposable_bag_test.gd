extends GdUnitTestSuite
## DisposableBag のテスト
##
## DisposableBag の核心機能「dispose 時に内部の全 Disposable が破棄される」
## という動作に焦点を当てたテストスイート

# モッククラス: has_method("dispose") を持つが Disposable を継承しないクラス
class MockDisposable:
	var disposed := false


	func dispose() -> void:
		disposed = true


func test_add_and_dispose_subjects() -> void:
	# 複数の Subject を DisposableBag に追加し、
	# bag を dispose すると全ての Subject が dispose されることを確認
	var bag := DisposableBag.new()
	var subject1 := Subject.new()
	var subject2 := Subject.new()
	var subject3 := Subject.new()

	bag.add(subject1, subject2, subject3)

	# dispose 前: 全ての Subject は動作している
	assert_bool(subject1.is_blocking_signals()).is_false()
	assert_bool(subject2.is_blocking_signals()).is_false()
	assert_bool(subject3.is_blocking_signals()).is_false()

	# bag を dispose
	bag.dispose()

	# dispose 後: 全ての Subject が dispose されている
	assert_bool(subject1.is_blocking_signals()).is_true()
	assert_bool(subject2.is_blocking_signals()).is_true()
	assert_bool(subject3.is_blocking_signals()).is_true()


func test_clear_disposes_all_but_bag_remains_usable() -> void:
	# clear() は全てのアイテムを dispose するが、
	# bag 自体は再利用可能（read-only にならない）
	var bag := DisposableBag.new()
	var subject1 := Subject.new()
	var subject2 := Subject.new()

	bag.add(subject1, subject2)

	# clear 前: Subjects は動作している
	assert_bool(subject1.is_blocking_signals()).is_false()
	assert_bool(subject2.is_blocking_signals()).is_false()

	# clear を実行
	bag.clear()

	# clear 後: 全ての Subject が dispose されている
	assert_bool(subject1.is_blocking_signals()).is_true()
	assert_bool(subject2.is_blocking_signals()).is_true()

	# bag は再利用可能
	var subject3 := Subject.new()
	bag.add(subject3)
	assert_bool(subject3.is_blocking_signals()).is_false()

	# bag を dispose すると新しく追加した subject も dispose される
	bag.dispose()
	assert_bool(subject3.is_blocking_signals()).is_true()


func test_add_to_disposed_bag_immediately_disposes() -> void:
	# dispose 済みの bag にアイテムを追加すると、
	# 追加されたアイテムは即座に dispose される
	var bag := DisposableBag.new()

	# bag を dispose
	bag.dispose()

	# dispose 後にアイテムを追加
	var subject := Subject.new()
	assert_bool(subject.is_blocking_signals()).is_false()

	bag.add(subject)

	# 追加したアイテムは即座に dispose されている
	assert_bool(subject.is_blocking_signals()).is_true()


func test_nested_disposable_bags() -> void:
	# DisposableBag を DisposableBag に追加（ネスト構造）
	# 親 bag を dispose すると子 bag も dispose される
	var parent_bag := DisposableBag.new()
	var child_bag := DisposableBag.new()
	var subject := Subject.new()

	# 子 bag に Subject を追加
	child_bag.add(subject)

	# 親 bag に子 bag を追加
	parent_bag.add(child_bag)

	# Subject はまだ動作している
	assert_bool(subject.is_blocking_signals()).is_false()

	# 親 bag を dispose
	parent_bag.dispose()

	# 子 bag が dispose され、その結果 Subject も dispose されている
	assert_bool(child_bag._items.is_read_only()).is_true()
	assert_bool(subject.is_blocking_signals()).is_true()


func test_mock_disposable_with_has_method() -> void:
	# has_method("dispose") を持つが Disposable を継承しないクラス
	# DisposableBag は has_method 契約に基づいて動作する
	var bag := DisposableBag.new()
	var mock1 := MockDisposable.new()
	var mock2 := MockDisposable.new()

	bag.add(mock1)
	bag.add(mock2)

	# dispose 前
	assert_bool(mock1.disposed).is_false()
	assert_bool(mock2.disposed).is_false()

	# bag を dispose
	bag.dispose()

	# モックオブジェクトの dispose メソッドが呼ばれている
	assert_bool(mock1.disposed).is_true()
	assert_bool(mock2.disposed).is_true()


func test_bag_add_to_node_with_auto_free() -> void:
	# DisposableBag を Node に add_to して、
	# Node が free されると bag が dispose されることを確認
	var bag := DisposableBag.new()
	var subject := Subject.new()
	var node: Node = auto_free(Node.new())

	bag.add(subject)

	# Node をツリーに追加
	add_child.call_deferred(node)
	await child_entered_tree

	# bag を Node に関連付け
	bag.add_to(node)

	# Subject はまだ動作している
	assert_bool(subject.is_blocking_signals()).is_false()

	# Node がツリーから削除される
	await child_exiting_tree

	# Node が free されると bag が dispose され、Subject も dispose される
	assert_bool(subject.is_blocking_signals()).is_true()
	assert_bool(bag._items.is_read_only()).is_true()


func test_empty_bag_dispose() -> void:
	# エッジケース: 空の bag を dispose しても問題ないことを確認
	var bag := DisposableBag.new()

	# 何も追加していない
	assert_array(bag._items).is_empty()

	# dispose を実行（エラーが出ないことを確認）
	bag.dispose()

	# bag は dispose されている（read-only）
	assert_bool(bag._items.is_read_only()).is_true()

	# dispose 後にアイテムを追加しようとすると即座に dispose される
	var subject := Subject.new()
	bag.add(subject)
	assert_bool(subject.is_blocking_signals()).is_true()
