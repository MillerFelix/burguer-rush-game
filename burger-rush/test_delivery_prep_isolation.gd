extends SceneTree

const OrderManagerScript = preload("res://src/orders/order_manager.gd")
const GameClockScript = preload("res://src/time/game_clock.gd")

func _init() -> void:
	var clock = GameClockScript.new()
	clock.name = "GameClock"
	root.add_child(clock)
	clock._ready()

	var om = OrderManagerScript.new()
	om.name = "OrderManager"
	root.add_child(om)
	om._ready()

	# 1. State PREPARATION
	clock.set_state(GameClockScript.State.PREPARATION)
	om.active_orders.clear()
	om._delivery_spawn_timer = 0.01
	om._process_delivery_spawning(0.5)
	print("Prep count: ", om.active_orders.size())

	# 2. State OPEN
	clock.set_state(GameClockScript.State.OPEN)
	om._delivery_spawn_timer = 0.01
	print("Before open call, timer=", om._delivery_spawn_timer, " clock_open=", clock.is_restaurant_open(), " clock_inst=", GameClockScript.get_instance().is_restaurant_open())
	om._process_delivery_spawning(0.5)
	print("After open spawn: active_orders=", om.active_orders.size(), " timer=", om._delivery_spawn_timer)

	quit(0)
