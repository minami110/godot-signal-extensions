extends GdUnitTestSuite

signal no_parms
const Subscription = preload("res://addons/signal_extensions/subscription.gd")
const DisposableBag = preload("res://addons/signal_extensions/disposable_bag.gd")

var _result_int: int

func test_add_disposable() -> void:
    _result_int = 0
    var bag := DisposableBag.new()
    var subscription := Subscription.new(no_parms, func() -> void:
        _result_int += 1
    )

    bag.add(subscription)
    no_parms.emit()
    assert_int(_result_int).is_equal(1)

func test_add_multiple_disposables() -> void:
    _result_int = 0
    var bag := DisposableBag.new()

    var sub1 := Subscription.new(no_parms, func() -> void:
        _result_int += 1
    )
    var sub2 := Subscription.new(no_parms, func() -> void:
        _result_int += 2
    )
    var sub3 := Subscription.new(no_parms, func() -> void:
        _result_int += 4
    )

    bag.add(sub1)
    bag.add(sub2)
    bag.add(sub3)

    no_parms.emit()
    assert_int(_result_int).is_equal(7)

func test_clear() -> void:
    _result_int = 0
    var bag := DisposableBag.new()

    var sub1 := Subscription.new(no_parms, func() -> void:
        _result_int += 1
    )
    var sub2 := Subscription.new(no_parms, func() -> void:
        _result_int += 2
    )

    bag.add(sub1)
    bag.add(sub2)

    no_parms.emit()
    assert_int(_result_int).is_equal(3)

    bag.clear()

    no_parms.emit()
    assert_int(_result_int).is_equal(3)

func test_dispose() -> void:
    _result_int = 0
    var bag := DisposableBag.new()

    var subscription := Subscription.new(no_parms, func() -> void:
        _result_int += 1
    )

    bag.add(subscription)
    no_parms.emit()
    assert_int(_result_int).is_equal(1)

    bag.dispose()
    no_parms.emit()
    assert_int(_result_int).is_equal(1)

func test_add_to_disposed_bag() -> void:
    _result_int = 0
    var bag := DisposableBag.new()

    bag.dispose()

    var subscription := Subscription.new(no_parms, func() -> void:
        _result_int += 1
    )

    bag.add(subscription)
    no_parms.emit()
    assert_int(_result_int).is_equal(0)

func test_add_to_disposable_bag() -> void:
    _result_int = 0
    var bag := DisposableBag.new()

    var subscription := Subscription.new(no_parms, func() -> void:
        _result_int += 1
    )

    subscription.add_to(bag)
    no_parms.emit()
    assert_int(_result_int).is_equal(1)

    bag.dispose()
    no_parms.emit()
    assert_int(_result_int).is_equal(1)

func test_disposable_bag_add_to_node() -> void:
    _result_int = 0
    var bag := DisposableBag.new()
    var node := Node.new()

    var subscription := Subscription.new(no_parms, func() -> void:
        _result_int += 1
    )

    bag.add(subscription)

    add_child.call_deferred(node)
    await child_entered_tree

    bag.add_to(node)

    no_parms.emit()
    assert_int(_result_int).is_equal(1)

    node.queue_free()
    await child_exiting_tree

    no_parms.emit()
    assert_int(_result_int).is_equal(1)
    assert_bool(bag._is_disposed).is_true()
