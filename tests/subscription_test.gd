extends GdUnitTestSuite

signal no_parms
const Subscription = preload("uid://deioe3s8pcc8")


func test_subscribe_no_params() -> void:
	var result: Array[String] = []
	var sub := Subscription.new(no_parms, result.append.bind("called"))
	no_parms.emit()
	assert_array(result).contains_exactly("called")
	sub.dispose()


func test_unsubscribe() -> void:
	var result: Array[String] = []
	var sub := Subscription.new(no_parms, result.append.bind("called"))
	no_parms.emit()
	assert_array(result).contains_exactly("called")
	sub.dispose()
	no_parms.emit()
	assert_array(result).contains_exactly("called")
