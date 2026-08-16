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

func _ready() -> void:
	instance = self

func _process(delta: float) -> void:
	for order in active_orders:
		if order.state == Order.State.WAITING or order.state == Order.State.IN_PROGRESS:
			order.wait_time += delta

static func get_instance() -> OrderManager:
	return instance

func create_group_order(customer: Node, group_size: int, table_id: int = 0, source_type: String = "DINE_IN") -> Order:
	var order = Order.new()
	order.id = next_order_id
	next_order_id += 1
	order.customer_ref = customer
	order.table_id = table_id
	order.group_size = max(1, group_size)
	order.source_type = source_type
	order.created_time = Time.get_ticks_msec() / 1000.0

	# Pega os burgers do cardápio atualizado
	var burger_recipe_ids = [
		"burger_classic", "burger_double", "burger_cheddar", "burger_bacon",
		"burger_salad", "burger_onion", "burger_chicken", "burger_supreme",
		"burger_cheese", "burger_vegan", "burger_egg"
	]
	var available_burgers: Array[Dictionary] = []
	for bid in burger_recipe_ids:
		var r = RecipeDatabase.get_recipe_by_id(bid)
		if r and r.is_unlocked:
			available_burgers.append({"id": r.id, "name": r.display_name, "price": r.base_price})
	if available_burgers.is_empty():
		available_burgers = [{"id": "burger_classic", "name": "Burger Clássico", "price": 22.90}]

	var available_drinks = [
		{"id": "soda_cola", "name": "Refrigerante Cola", "price": 6.0},
		{"id": "soda_cola_zero", "name": "Refrigerante Zero", "price": 6.0},
		{"id": "soda_lime", "name": "Refrigerante Soda", "price": 6.0},
		{"id": "soda_citrus", "name": "Refrigerante Citrus", "price": 6.0}
	]

	# 1. Cada pessoa do grupo consome 1 Hambúrguer e 1 Bebida
	for _p in range(order.group_size):
		var b = available_burgers[randi() % available_burgers.size()]
		order.add_item(b.id, b.name, 1, b.price)

		var d = available_drinks[randi() % available_drinks.size()]
		order.add_item(d.id, d.name, 1, d.price)

	# 2. Acompanhamento (Batata Frita) proporcional e com variação realista
	var fries_count = 0
	if order.group_size == 1:
		if randf() < 0.4:
			fries_count = 1
	elif order.group_size == 2:
		fries_count = 1 if randf() < 0.8 else 2
	elif order.group_size == 3:
		fries_count = 1 if randf() < 0.5 else 2
	elif order.group_size >= 4:
		fries_count = 2 if randf() < 0.7 else 3

	if fries_count > 0:
		order.add_item("fries", "Batata Frita", fries_count, 8.0)

	order.state = Order.State.WAITING
	active_orders.append(order)
	order_created.emit(order)
	return order

func create_order(customer: Node, product_id: String = "", quantity: int = 1, table_id: int = 0, source_type: String = "DINE_IN", group_size: int = 1) -> Order:
	if group_size > 1 or product_id == "":
		return create_group_order(customer, group_size, table_id, source_type)

	var order = Order.new()
	order.id = next_order_id
	next_order_id += 1
	order.customer_ref = customer
	order.table_id = table_id
	order.group_size = 1
	order.source_type = source_type
	order.created_time = Time.get_ticks_msec() / 1000.0

	var recipe = RecipeDatabase.get_recipe_by_id(product_id)
	if recipe and recipe.category == "combo" and not recipe.combo_items.is_empty():
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

func has_pending_orders() -> bool:
	for order in active_orders:
		if order and is_instance_valid(order) and (order.state == Order.State.RECEIVED or order.state == Order.State.WAITING or order.state == Order.State.IN_PROGRESS):
			if not order.is_all_delivered():
				return true
	return false

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
		# Acompanhamentos e Bebidas (fallback caso não estejam no RecipeDatabase)
		"fries":
			return {"name": "Batata Frita", "price": 8.0}
		"soda_cola", "drink_cola":
			return {"name": "Refrigerante Cola", "price": 6.0}
		"soda_guarana":
			return {"name": "Refrigerante Guaraná", "price": 6.0}
		"soda_sprite":
			return {"name": "Refrigerante Limão", "price": 6.0}
		"soda_grape":
			return {"name": "Refrigerante Uva", "price": 6.0}
		"soda_cola_zero":
			return {"name": "Cola Zero", "price": 6.0}
		"soda", "drink_orange":
			return {"name": "Refrigerante", "price": 6.0}
		"juice_orange":
			return {"name": "Suco de Laranja", "price": 7.0}
		"juice_grape":
			return {"name": "Suco de Uva", "price": 7.0}
		"juice_passion":
			return {"name": "Suco de Maracujá", "price": 7.0}
		_:
			return {"name": product_id.capitalize(), "price": 10.0}
