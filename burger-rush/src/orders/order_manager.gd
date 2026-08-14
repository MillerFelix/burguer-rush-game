class_name OrderManager
extends Node

signal order_created(order: Order)
signal order_updated(order: Order)
signal order_completed(order: Order)
signal order_cancelled(order: Order)

static var instance: OrderManager = null

var active_orders: Array[Order] = []
var next_order_id: int = 1

var daily_completed_orders: int = 0
var daily_cancelled_orders: int = 0
var daily_total_wait_time: float = 0.0

func _enter_tree() -> void:
	instance = self

func _process(delta: float) -> void:
	for order in active_orders:
		if order.state == Order.State.WAITING or order.state == Order.State.IN_PROGRESS:
			order.wait_time += delta

static func get_instance() -> OrderManager:
	return instance

func create_order(customer: Node, product_id: String = "", quantity: int = 1, table_id: int = 0, source_type: String = "DINE_IN") -> Order:
	var order = Order.new()
	order.id = next_order_id
	next_order_id += 1
	order.customer_ref = customer
	order.table_id = table_id
	order.source_type = source_type
	order.created_time = Time.get_ticks_msec() / 1000.0

	if product_id == "":
		product_id = _pick_random_available_product()

	var recipe = RecipeDatabase.get_recipe_by_id(product_id)
	if recipe and recipe.category == "combo" and not recipe.combo_items.is_empty():
		# Se for combo, adiciona cada item componente
		var combo_price_per_item = recipe.base_price / float(recipe.combo_items.size())
		for sub_id in recipe.combo_items:
			var sub_info = _get_product_info(sub_id)
			order.add_item(
				sub_id,
				sub_info.get("name", sub_id.capitalize()),
				quantity,
				combo_price_per_item
			)
	else:
		var product_info = _get_product_info(product_id)
		order.add_item(
			product_id,
			product_info.get("name", product_id.capitalize()),
			quantity,
			product_info.get("price", 10.0)
		)

	order.state = Order.State.WAITING
	active_orders.append(order)
	order_created.emit(order)
	return order

func get_active_orders() -> Array[Order]:
	return active_orders

func find_order_by_id(id: int) -> Order:
	for order in active_orders:
		if order.id == id:
			return order
	return null

func find_order_matching_product(product_id: String) -> Order:
	for order in active_orders:
		if (order.state == Order.State.WAITING or order.state == Order.State.IN_PROGRESS) and order.has_pending_product(product_id):
			return order
	return null

func complete_order(order: Order) -> void:
	if not active_orders.has(order):
		return
	order.state = Order.State.COMPLETED
	active_orders.erase(order)
	daily_completed_orders += 1
	daily_total_wait_time += order.wait_time
	order_completed.emit(order)

func cancel_order(order: Order) -> void:
	if not active_orders.has(order):
		return
	order.state = Order.State.CANCELLED
	active_orders.erase(order)
	daily_cancelled_orders += 1
	order_cancelled.emit(order)

func get_avg_wait_time() -> float:
	if daily_completed_orders == 0:
		return 0.0
	return daily_total_wait_time / float(daily_completed_orders)

func start_new_day() -> void:
	active_orders.clear()
	daily_completed_orders = 0
	daily_cancelled_orders = 0
	daily_total_wait_time = 0.0

func clear_all() -> void:
	active_orders.clear()
	next_order_id = 1
	start_new_day()

func _pick_random_available_product() -> String:
	var unlocked_recipes = RecipeDatabase.get_unlocked_menu_recipes()
	if unlocked_recipes.is_empty():
		return "burger"

	var chosen = unlocked_recipes[randi() % unlocked_recipes.size()]
	return chosen.id

func _get_product_info(product_id: String) -> Dictionary:
	var recipe = RecipeDatabase.get_recipe_by_id(product_id)
	if recipe:
		return {
			"name": recipe.display_name,
			"price": recipe.base_price
		}

	match product_id:
		"burger":
			return {"name": "Hambúrguer", "price": 15.0}
		"cheeseburger":
			return {"name": "Cheeseburger", "price": 18.0}
		"x_salada":
			return {"name": "X-Salada", "price": 22.0}
		"x_bacon":
			return {"name": "X-Bacon", "price": 25.0}
		"fries":
			return {"name": "Batata Frita", "price": 8.0}
		"soda_cola":
			return {"name": "Refrigerante Cola", "price": 6.0}
		"soda_guarana":
			return {"name": "Refrigerante Guaraná", "price": 6.0}
		"soda_sprite":
			return {"name": "Refrigerante Limão", "price": 6.0}
		"soda":
			return {"name": "Refrigerante", "price": 6.0}
		_:
			return {"name": product_id.capitalize(), "price": 10.0}
