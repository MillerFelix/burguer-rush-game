class_name OrderManager
extends Node

const MenuPricingManager = preload("res://src/recipes/menu_pricing_manager.gd")
const FinanceManager = preload("res://src/economy/finance_manager.gd")
const EconomyManager = preload("res://src/economy/economy_manager.gd")
const ReputationManager = preload("res://src/customers/reputation_manager.gd")
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

signal order_created(order: Order)
signal order_updated(order: Order)
signal order_completed(order: Order)
signal order_cancelled(order: Order)
signal delivery_order_arrived(order: Order)

static var instance: OrderManager = null

var active_orders: Array[Order] = []
var daily_order_history: Array[Dictionary] = []
var next_order_id: int = 1

var daily_completed_orders: int = 0
var daily_cancelled_orders: int = 0
var daily_total_wait_time: float = 0.0

@export var delivery_spawn_enabled: bool = true
var daily_scheduled_deliveries: Array[float] = []
var daily_deliveries_spawned: int = 0
var last_checked_delivery_day: int = -1

func _enter_tree() -> void:
	instance = self

static func get_instance() -> OrderManager:
	if instance and is_instance_valid(instance):
		return instance
	var ml = Engine.get_main_loop()
	if ml and ml is SceneTree:
		var tree = ml as SceneTree
		if tree.root:
			var found = tree.root.find_child("OrderManager", true, false) as OrderManager
			if found:
				instance = found
				return instance
	return null

func _ready() -> void:
	instance = self
	_init_day_delivery_demand()

func _init_day_delivery_demand() -> void:
	var clock = GameClock.get_instance()
	if not clock and is_inside_tree() and get_tree() and get_tree().root:
		clock = get_tree().root.find_child("GameClock", true, false)
	var day_num: int = int(clock.get("day_number")) if (clock and clock.get("day_number") != null) else 1
	last_checked_delivery_day = day_num
	daily_scheduled_deliveries.clear()
	daily_deliveries_spawned = 0

	# Delivery é um canal secundário/raro: 0 a 3 pedidos por dia no máximo
	var rand_val = randf()
	var total_deliveries_today = 0

	if rand_val < 0.25:
		total_deliveries_today = 0 # 25% dos dias: Nenhum delivery
	elif rand_val < 0.70:
		total_deliveries_today = 1 # 45% dos dias: 1 delivery ocasional
	elif rand_val < 0.92:
		total_deliveries_today = 2 # 22% dos dias: 2 deliveries
	else:
		total_deliveries_today = 3 # 8% dos dias: 3 deliveries (pico raro)

	if total_deliveries_today > 0:
		var possible_windows = [
			randf_range(11.8, 13.8), # Almoço
			randf_range(15.0, 17.5), # Tarde
			randf_range(18.2, 20.8)  # Jantar
		]
		possible_windows.shuffle()

		for i in range(min(total_deliveries_today, possible_windows.size())):
			daily_scheduled_deliveries.append(possible_windows[i])

		daily_scheduled_deliveries.sort()

func _process_delivery_spawning(_delta: float) -> void:
	var clock = GameClock.get_instance()
	if not clock and is_inside_tree() and get_tree() and get_tree().root:
		clock = get_tree().root.find_child("GameClock", true, false)

	if not clock:
		return
	if clock.has_method("is_restaurant_open"):
		if not clock.is_restaurant_open():
			return
	elif clock.get("state") != null and clock.state != 1:
		return

	if clock.get("day_number") != last_checked_delivery_day:
		_init_day_delivery_demand()

	# Não acumula mais que 2 deliveries pendentes de aceite simultâneos
	var pending_count = 0
	for o in active_orders:
		if o.source_type == "DELIVERY" and o.delivery_stage == "NEW_RECEIVED":
			pending_count += 1
	if pending_count >= 2:
		return

	var current_hour_f = clock.current_hour + (clock.current_minute / 60.0)

	if daily_deliveries_spawned < daily_scheduled_deliveries.size():
		var next_time = daily_scheduled_deliveries[daily_deliveries_spawned]
		if current_hour_f >= next_time:
			daily_deliveries_spawned += 1
			create_delivery_order()

## Cria um novo pedido de Delivery recebido pelo aplicativo
func create_delivery_order(custom_items: Array = []) -> Order:
	var order = Order.new()
	order.id = next_order_id
	next_order_id += 1
	order.source_type = "DELIVERY"
	order.delivery_stage = "NEW_RECEIVED"
	order.is_accepted = false
	order.created_time = Time.get_ticks_msec() / 1000.0

	var clock = GameClock.get_instance()
	if not clock and is_inside_tree() and get_tree() and get_tree().root:
		clock = get_tree().root.find_child("GameClock", true, false)
	if clock and clock.has_method("get_formatted_time"):
		order.created_clock_time = clock.get_formatted_time()
	else:
		order.created_clock_time = "12:00"

	if not custom_items.is_empty():
		for it in custom_items:
			order.add_item(it.get("product_id", ""), it.get("product_name", ""), it.get("quantity", 1), it.get("unit_price", 10.0))
	else:
		# DISTRIBUIÇÃO CONTROLADA DE TAMANHO DE PEDIDO:
		# 60% Pequeno, 30% Médio, 10% Grande (Raro)
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
			{"id": "soda_citrus", "name": "Refrigerante Citrus", "price": 6.0},
			{"id": "juice_orange", "name": "Suco de Laranja", "price": 7.50},
			{"id": "juice_grape", "name": "Suco de Uva", "price": 7.50},
			{"id": "juice_strawberry", "name": "Suco de Morango", "price": 7.50}
		]

		var rand_size = randf()

		if rand_size < 0.60:
			# PEDIDO PEQUENO (60%): 1 Burger (50%) ou 1 Burger + 1 Bebida (50%)
			var b = available_burgers[randi() % available_burgers.size()]
			var b_price = MenuPricingManager.get_selling_price(b.id)
			order.add_item(b.id, b.name, 1, b_price)

			if randf() < 0.50:
				var d = available_drinks[randi() % available_drinks.size()]
				var d_price = MenuPricingManager.get_selling_price(d.id)
				order.add_item(d.id, d.name, 1, d_price)

		elif rand_size < 0.90:
			# PEDIDO MÉDIO (30%): 1 Combo = 1 Burger + 1 Batata/Cebola + 1 Bebida
			var b = available_burgers[randi() % available_burgers.size()]
			var b_price = MenuPricingManager.get_selling_price(b.id)
			order.add_item(b.id, b.name, 1, b_price)

			if randf() < 0.75:
				var f_price = MenuPricingManager.get_selling_price("fries")
				order.add_item("fries", "Batata Frita", 1, f_price)
			else:
				var o_price = MenuPricingManager.get_selling_price("onion_rings")
				order.add_item("onion_rings", "Cebola Frita", 1, o_price)

			var d = available_drinks[randi() % available_drinks.size()]
			var d_price = MenuPricingManager.get_selling_price(d.id)
			order.add_item(d.id, d.name, 1, d_price)

		else:
			# PEDIDO GRANDE (10% - RARO): 2 Burgers + 1 Acomp + 1-2 Bebidas
			var b1 = available_burgers[randi() % available_burgers.size()]
			order.add_item(b1.id, b1.name, 1, MenuPricingManager.get_selling_price(b1.id))

			var b2 = available_burgers[randi() % available_burgers.size()]
			order.add_item(b2.id, b2.name, 1, MenuPricingManager.get_selling_price(b2.id))

			var f_price = MenuPricingManager.get_selling_price("fries")
			order.add_item("fries", "Batata Frita", 1, f_price)

			var d1 = available_drinks[randi() % available_drinks.size()]
			order.add_item(d1.id, d1.name, 1, MenuPricingManager.get_selling_price(d1.id))

			if randf() < 0.60:
				var d2 = available_drinks[randi() % available_drinks.size()]
				order.add_item(d2.id, d2.name, 1, MenuPricingManager.get_selling_price(d2.id))

	order.state = Order.State.RECEIVED
	active_orders.append(order)
	order_created.emit(order)
	delivery_order_arrived.emit(order)
	return order

## Aceita um pedido de delivery pelo PC
func accept_delivery_order(order_id: int) -> bool:
	var order = find_order_by_id(order_id)
	if not order or order.source_type != "DELIVERY":
		return false

	if order.delivery_stage == "NEW_RECEIVED":
		order.is_accepted = true
		order.delivery_stage = "PREPARING"
		order.state = Order.State.IN_PROGRESS
		order_updated.emit(order)
		return true
	return false

## Encerra um pedido de delivery que não foi aceito pelo restaurante dentro do prazo
func expire_unaccepted_delivery_order(order: Order) -> void:
	if not order or order.source_type != "DELIVERY":
		return

	order.delivery_stage = "NOT_ACCEPTED"
	order.state = Order.State.NOT_ACCEPTED
	order.is_paid = false
	order.payment_amount = 0.0
	order.result_status_text = "Não aceito no prazo"

	var clock = GameClock.get_instance()
	if not clock and is_inside_tree() and get_tree() and get_tree().root:
		clock = get_tree().root.find_child("GameClock", true, false)
	var time_str = clock.get_formatted_time() if (clock and clock.has_method("get_formatted_time")) else "12:00"

	record_order_to_history(order, "Não aceito no prazo", false, 0.0, false, time_str)
	active_orders.erase(order)
	daily_cancelled_orders += 1
	order_updated.emit(order)

## Marca o pedido como pronto e aguardando motoboy (quando o saco é colocado no balcão)
func mark_delivery_ready_for_pickup(order: Order, _bag: Node = null) -> void:
	if not order or order.source_type != "DELIVERY":
		return
	order.delivery_stage = "WAITING_COURIER"
	order.state = Order.State.READY
	order_updated.emit(order)

## Processa a entrega pelo motoboy (validação de itens, pagamento e registro contábil)
func process_delivery_handover(order: Order, bag: Node = null) -> Dictionary:
	if not order:
		return {"success": false, "message": "Pedido inválido"}

	var clock = GameClock.get_instance()
	if not clock and is_inside_tree() and get_tree() and get_tree().root:
		clock = get_tree().root.find_child("GameClock", true, false)
	var time_str = clock.get_formatted_time() if (clock and clock.has_method("get_formatted_time")) else "12:00"

	var validation = order.matches_delivery_bag(bag)
	var is_correct = validation.get("matches", false)

	if is_correct:
		# Pedido correto: Pagamento integral e receita no canal delivery
		order.delivery_stage = "COMPLETED_PAID"
		order.state = Order.State.COMPLETED
		order.is_paid = true
		order.payment_amount = order.total_price
		order.result_status_text = "Concluído — Pago"

		var fin = FinanceManager.get_instance()
		if not fin and is_inside_tree() and get_tree() and get_tree().root:
			fin = get_tree().root.find_child("FinanceManager", true, false)
		if fin and fin.has_method("register_channel_sale"):
			fin.register_channel_sale("delivery", order.total_price, "Venda Delivery (Pedido #%03d)" % order.id)
		else:
			var econ = EconomyManager.get_instance()
			if not econ and is_inside_tree() and get_tree() and get_tree().root:
				econ = get_tree().root.find_child("EconomyManager", true, false)
			if econ:
				econ.add_money(order.total_price, "Venda Delivery (Pedido #%03d)" % order.id)

		var rep = ReputationManager.get_instance()
		if not rep and is_inside_tree() and get_tree() and get_tree().root:
			rep = get_tree().root.find_child("ReputationManager", true, false)
		if rep:
			var day_val = clock.day_number if clock else 1
			rep.submit_delivery_review(order, true, order.prep_elapsed_time, maxf(0.0, order.elapsed_time - order.prep_elapsed_time), day_val, time_str)

		_play_payment_sound()
		record_order_to_history(order, "Concluído — Pago", true, order.total_price, false, time_str)
		complete_order(order)
		return {"success": true, "is_correct": true, "message": "Pedido Delivery #%03d entregue com sucesso! +R$ %.2f" % [order.id, order.total_price]}
	else:
		# Pedido incorreto: Não pago, 0 de receita
		order.delivery_stage = "COMPLETED_WRONG"
		order.state = Order.State.COMPLETED
		order.is_paid = false
		order.payment_amount = 0.0
		order.is_wrong_delivery = true
		order.result_status_text = "Concluído — Pedido Incorreto / Não Pago"

		var rep = ReputationManager.get_instance()
		if not rep and is_inside_tree() and get_tree() and get_tree().root:
			rep = get_tree().root.find_child("ReputationManager", true, false)
		if rep:
			var day_val = clock.day_number if clock else 1
			rep.submit_delivery_review(order, false, order.prep_elapsed_time, maxf(0.0, order.elapsed_time - order.prep_elapsed_time), day_val, time_str)

		record_order_to_history(order, "Concluído — Pedido incorreto / Não pago", false, 0.0, true, time_str)
		complete_order(order)
		return {"success": true, "is_correct": false, "message": "PEDIDO ENTREGUE INCORRETAMENTE (#%03d) — %s" % [order.id, validation.get("reason", "Itens incorretos")]}

## Registra o pedido no histórico diário persistente
func record_order_to_history(order: Order, status_text: String, is_paid: bool, payment_amount: float, is_wrong: bool = false, completed_time: String = "") -> void:
	if not order:
		return

	var clock = GameClock.get_instance()
	if not clock and is_inside_tree() and get_tree() and get_tree().root:
		clock = get_tree().root.find_child("GameClock", true, false)
	var day_num = clock.day_number if clock else 1
	var c_time = completed_time if completed_time != "" else (clock.get_formatted_time() if (clock and clock.has_method("get_formatted_time")) else "12:00")

	# Clona os itens do pedido
	var items_copy: Array[Dictionary] = []
	for it in order.items:
		items_copy.append(it.duplicate(true))

	var history_entry = {
		"id": order.id,
		"source_type": order.source_type,
		"source_name": order.get_source_display_name(),
		"items": items_copy,
		"total_price": order.total_price,
		"is_paid": is_paid,
		"payment_amount": payment_amount,
		"status": status_text,
		"is_wrong": is_wrong,
		"created_clock_time": order.created_clock_time,
		"completed_clock_time": c_time,
		"wait_time": order.wait_time,
		"day": day_num
	}

	daily_order_history.append(history_entry)

func get_order_history() -> Array[Dictionary]:
	return daily_order_history

## Retorna estatísticas de delivery para a visão geral
func get_delivery_summary_stats() -> Dictionary:
	var stats = {
		"new": 0,
		"preparing": 0,
		"ready": 0,
		"waiting_courier": 0,
		"in_delivery": 0,
		"completed": 0,
		"wrong": 0
	}

	for order in active_orders:
		if order.source_type == "DELIVERY":
			match order.delivery_stage:
				"NEW_RECEIVED":
					stats["new"] += 1
				"PREPARING":
					stats["preparing"] += 1
				"WAITING_COURIER":
					stats["waiting_courier"] += 1
				"IN_DELIVERY":
					stats["in_delivery"] += 1

	for h in daily_order_history:
		if str(h.get("source_type", "")).to_upper() == "DELIVERY":
			if h.get("is_wrong", false):
				stats["wrong"] += 1
			else:
				stats["completed"] += 1

	return stats

func create_group_order(customer: Node, group_size: int, table_id: int = 0, source_type: String = "DINE_IN") -> Order:
	var order = Order.new()
	order.id = next_order_id
	next_order_id += 1
	order.customer_ref = customer
	order.table_id = table_id
	order.group_size = max(1, group_size)
	order.source_type = source_type
	order.created_time = Time.get_ticks_msec() / 1000.0

	var clock = GameClock.get_instance()
	if not clock and is_inside_tree() and get_tree() and get_tree().root:
		clock = get_tree().root.find_child("GameClock", true, false)
	if clock and clock.has_method("get_formatted_time"):
		order.created_clock_time = clock.get_formatted_time()

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
		{"id": "soda_citrus", "name": "Refrigerante Citrus", "price": 6.0},
		{"id": "juice_orange", "name": "Suco de Laranja", "price": 7.50},
		{"id": "juice_grape", "name": "Suco de Uva", "price": 7.50},
		{"id": "juice_strawberry", "name": "Suco de Morango", "price": 7.50}
	]

	# 1. Alocação de Hambúrgueres e Bebidas com distribuição balanceada
	var bev_mult = 1.0
	if is_inside_tree() and get_tree() and get_tree().root:
		var dem = get_tree().root.find_child("DailyEventManager", true, false)
		if dem and dem.has_method("get_beverage_demand_multiplier"):
			bev_mult = dem.get_beverage_demand_multiplier()

	if order.group_size == 1:
		# Pedido Solo: 60% Pequeno, 30% Médio, 10% Grande
		var rand_solo = randf()
		var b = available_burgers[randi() % available_burgers.size()]
		order.add_item(b.id, b.name, 1, MenuPricingManager.get_selling_price(b.id))

		if rand_solo < 0.60:
			# Pequeno: 50% só lanche, 50% lanche + bebida
			if randf() < 0.50 or bev_mult >= 1.5:
				var d = available_drinks[randi() % available_drinks.size()]
				order.add_item(d.id, d.name, 1, MenuPricingManager.get_selling_price(d.id))
		elif rand_solo < 0.90:
			# Médio: Combo (Lanche + Bebida + Acompanhamento)
			var d = available_drinks[randi() % available_drinks.size()]
			order.add_item(d.id, d.name, 1, MenuPricingManager.get_selling_price(d.id))
			if randf() < 0.70:
				order.add_item("fries", "Batata Frita", 1, MenuPricingManager.get_selling_price("fries"))
			else:
				order.add_item("onion_rings", "Cebola Frita", 1, MenuPricingManager.get_selling_price("onion_rings"))
		else:
			# Grande (Raro): Lanche + Bebida + 2 Acompanhamentos
			var d = available_drinks[randi() % available_drinks.size()]
			order.add_item(d.id, d.name, 1, MenuPricingManager.get_selling_price(d.id))
			order.add_item("fries", "Batata Frita", 1, MenuPricingManager.get_selling_price("fries"))
			order.add_item("onion_rings", "Cebola Frita", 1, MenuPricingManager.get_selling_price("onion_rings"))

	else:
		# Pedido de Grupo (2, 3 ou 4 pessoas)
		for _p in range(order.group_size):
			var b = available_burgers[randi() % available_burgers.size()]
			order.add_item(b.id, b.name, 1, MenuPricingManager.get_selling_price(b.id))

			if randf() < 0.85 or bev_mult >= 1.5:
				var d = available_drinks[randi() % available_drinks.size()]
				order.add_item(d.id, d.name, 1, MenuPricingManager.get_selling_price(d.id))

		# Acompanhamentos proporcionais ao grupo
		var sides_count = 0
		if order.group_size == 2:
			sides_count = 1 if randf() < 0.40 else 0 # 40% das duplas pedem 1 batata para dividir
		elif order.group_size == 3:
			sides_count = 1 if randf() < 0.70 else 2
		elif order.group_size >= 4:
			sides_count = 2

		for _s in range(sides_count):
			if randf() < 0.65:
				order.add_item("fries", "Batata Frita", 1, MenuPricingManager.get_selling_price("fries"))
			else:
				order.add_item("onion_rings", "Cebola Frita", 1, MenuPricingManager.get_selling_price("onion_rings"))

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

	var clock = GameClock.get_instance()
	if not clock and is_inside_tree() and get_tree() and get_tree().root:
		clock = get_tree().root.find_child("GameClock", true, false)
	if clock and clock.has_method("get_formatted_time"):
		order.created_clock_time = clock.get_formatted_time()

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

func get_filtered_active_orders(filter_type: String) -> Array[Order]:
	if filter_type == "ALL" or filter_type == "":
		return active_orders

	var filtered: Array[Order] = []
	for o in active_orders:
		match filter_type.to_upper():
			"RESTAURANT", "DINE_IN":
				if o.source_type == "DINE_IN":
					filtered.append(o)
			"DRIVE_THRU", "DRIVETHRU":
				if o.source_type == "DRIVE_THRU":
					filtered.append(o)
			"DELIVERY":
				if o.source_type == "DELIVERY":
					filtered.append(o)
	return filtered

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
	if not order:
		return
	order.state = Order.State.COMPLETED
	if active_orders.has(order):
		active_orders.erase(order)
		daily_completed_orders += 1
		daily_total_wait_time += order.wait_time

		# Se ainda não foi gravado no histórico (ex: DINE_IN ou DRIVE_THRU), grava agora
		var already_in_history = false
		for h in daily_order_history:
			if h.get("id") == order.id:
				already_in_history = true
				break
		if not already_in_history:
			record_order_to_history(order, "Concluído — Pago", true, order.total_price, false)

	order_completed.emit(order)

func cancel_order(order: Order) -> void:
	if not order:
		return
	order.state = Order.State.CANCELLED
	if active_orders.has(order):
		active_orders.erase(order)
		daily_cancelled_orders += 1

		var already_in_history = false
		for h in daily_order_history:
			if h.get("id") == order.id:
				already_in_history = true
				break
		if not already_in_history:
			record_order_to_history(order, "Cancelado", false, 0.0, true)

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
	daily_order_history.clear()
	daily_completed_orders = 0
	daily_cancelled_orders = 0
	daily_total_wait_time = 0.0

func get_daily_history() -> Array[Dictionary]:
	return daily_order_history

func clear_all() -> void:
	active_orders.clear()
	daily_order_history.clear()
	next_order_id = 1
	start_new_day()

func _pick_random_available_product() -> String:
	var unlocked_recipes = RecipeDatabase.get_unlocked_menu_recipes()
	if unlocked_recipes.is_empty():
		return "burger"

	var chosen = unlocked_recipes[randi() % unlocked_recipes.size()]
	return chosen.id

func _get_product_info(product_id: String) -> Dictionary:
	var current_price = MenuPricingManager.get_selling_price(product_id)
	var recipe = RecipeDatabase.get_recipe_by_id(product_id)
	if recipe:
		return {
			"name": recipe.display_name,
			"price": current_price
		}

	match product_id:
		"fries":
			return {"name": "Batata Frita", "price": current_price}
		"onion_rings":
			return {"name": "Cebola Frita", "price": current_price}
		"soda_cola", "drink_cola":
			return {"name": "Refrigerante Cola", "price": current_price}
		"soda_guarana":
			return {"name": "Refrigerante Guaraná", "price": current_price}
		"soda_sprite":
			return {"name": "Refrigerante Limão", "price": current_price}
		"soda_grape":
			return {"name": "Refrigerante Uva", "price": current_price}
		"soda_cola_zero":
			return {"name": "Cola Zero", "price": current_price}
		"soda", "drink_orange":
			return {"name": "Refrigerante", "price": current_price}
		"juice_orange":
			return {"name": "Suco de Laranja", "price": current_price}
		"juice_grape":
			return {"name": "Suco de Uva", "price": current_price}
		"juice_strawberry":
			return {"name": "Suco de Morango", "price": current_price}
		"juice_passion":
			return {"name": "Suco de Maracujá", "price": current_price}
		_:
			return {"name": product_id.capitalize(), "price": current_price}

func _play_payment_sound() -> void:
	if not is_inside_tree():
		return
	var audio = AudioStreamPlayer.new()
	audio.name = "DeliveryPaymentAudioPlayer"
	audio.volume_db = -3.0
	audio.stream = SoundSynthesizer.get_stream("payment_success_cash")
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)

