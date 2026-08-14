class_name Customer
extends CharacterBody3D

enum State {
	ENTERING,
	LOOKING_FOR_TABLE,
	WALKING_TO_TABLE,
	SEATED_WAITING_TO_ORDER,
	WAITING_FOR_FOOD,
	EATING,
	REQUESTING_BILL,
	PAYING,
	LEAVING,
	FINISHED
}

static var next_customer_id: int = 1

@export var move_speed: float = 2.5
@export var eat_duration: float = 4.0
@export var patience_max: float = 60.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var label_3d: Label3D = $Label3D

var customer_id: int = 1
var state: State = State.ENTERING
var current_order: Order = null
var requested_product_id: String = ""
var assigned_table: RestaurantTable = null

var target_position: Vector3 = Vector3.ZERO
var exit_position: Vector3 = Vector3(8.0, 0, 5.0)

var patience_remaining: float = 60.0
var total_wait_time: float = 0.0
var eat_timer: float = 0.0
var search_table_timer: float = 0.0
var walk_timeout_timer: float = 0.0

func _ready() -> void:
	customer_id = next_customer_id
	next_customer_id += 1
	patience_remaining = patience_max
	_update_visual_status()

func setup(p_spawn_pos: Vector3, p_exit_pos: Vector3, p_product_id: String = "") -> void:
	global_position = p_spawn_pos
	exit_position = p_exit_pos
	requested_product_id = p_product_id
	state = State.LOOKING_FOR_TABLE
	_update_visual_status()

func _physics_process(delta: float) -> void:
	# Decaimento de paciência durante esperas
	if state in [State.SEATED_WAITING_TO_ORDER, State.WAITING_FOR_FOOD, State.REQUESTING_BILL]:
		patience_remaining = maxf(0.0, patience_remaining - delta)
		total_wait_time += delta

	match state:
		State.LOOKING_FOR_TABLE:
			search_table_timer += delta
			if search_table_timer >= 0.3:
				search_table_timer = 0.0
				_find_table_and_walk()

		State.WALKING_TO_TABLE:
			walk_timeout_timer += delta
			var to_target = target_position - global_position
			to_target.y = 0.0

			if to_target.length() <= 0.45 or walk_timeout_timer >= 4.0:
				velocity = Vector3.ZERO
				global_position = target_position
				state = State.SEATED_WAITING_TO_ORDER
				walk_timeout_timer = 0.0
				_update_visual_status()
				if assigned_table:
					assigned_table._update_visual_status()
			else:
				var move_dir = to_target.normalized()
				velocity.x = move_dir.x * move_speed
				velocity.z = move_dir.z * move_speed
				move_and_slide()

		State.EATING:
			eat_timer += delta
			if eat_timer >= eat_duration:
				state = State.REQUESTING_BILL
				_update_visual_status()
				if assigned_table:
					assigned_table._update_visual_status()

		State.LEAVING:
			var to_exit = exit_position - global_position
			to_exit.y = 0.0
			if to_exit.length() > 0.4:
				var move_dir = to_exit.normalized()
				velocity.x = move_dir.x * move_speed
				velocity.z = move_dir.z * move_speed
				move_and_slide()
			else:
				state = State.FINISHED
				queue_free()

func _find_table_and_walk() -> void:
	var table_mgr = TableManager.get_instance()
	if not table_mgr:
		return

	var table = table_mgr.get_available_table()
	if table:
		assigned_table = table
		target_position = table.occupy(self)
		state = State.WALKING_TO_TABLE
		walk_timeout_timer = 0.0
		_update_visual_status()

func get_interaction_prompt(player: Node = null) -> String:
	match state:
		State.SEATED_WAITING_TO_ORDER:
			var t_id = assigned_table.table_id if assigned_table else 1
			return "E — Atender Mesa #%d" % t_id
		State.WAITING_FOR_FOOD:
			var t_id = assigned_table.table_id if assigned_table else 1
			var name_str = current_order.items[0].get("product_name", "Pedido") if current_order and not current_order.items.is_empty() else "Pedido"
			return "Mesa #%d: Aguardando %s" % [t_id, name_str]
		State.REQUESTING_BILL:
			var total = current_order.total_price if current_order else 0.0
			var t_id = assigned_table.table_id if assigned_table else 1
			return "E — Entregar Conta (Mesa #%d - $%.2f)" % [t_id, total]
		_:
			return ""

func interact(player: Node3D) -> void:
	match state:
		State.SEATED_WAITING_TO_ORDER:
			take_order_from_player()
		State.REQUESTING_BILL:
			pay_and_leave()

func take_order_from_player() -> void:
	if state != State.SEATED_WAITING_TO_ORDER:
		return

	var order_mgr = OrderManager.get_instance()
	if not order_mgr:
		return

	var t_id = assigned_table.table_id if assigned_table else 1
	current_order = order_mgr.create_order(self, requested_product_id, 1, t_id, "DINE_IN")
	state = State.WAITING_FOR_FOOD
	_update_visual_status()
	if assigned_table:
		assigned_table._update_visual_status()

func serve_food() -> void:
	if state == State.WAITING_FOR_FOOD:
		state = State.EATING
		eat_timer = 0.0
		_update_visual_status()

func pay_and_leave() -> void:
	if state != State.REQUESTING_BILL:
		return

	state = State.PAYING
	_update_visual_status()

	var economy = EconomyManager.get_instance()
	var order_mgr = OrderManager.get_instance()
	var rep_mgr = ReputationManager.get_instance()

	# 1. Pagamento ÚNICO e Seguro da Conta
	if current_order:
		if economy:
			var prod_name = current_order.items[0].get("product_name", "Lanche") if not current_order.items.is_empty() else "Lanche"
			var t_id = assigned_table.table_id if assigned_table else 1
			economy.add_money(current_order.total_price, "Mesa #%d: %s" % [t_id, prod_name])

		if order_mgr:
			order_mgr.complete_order(current_order)

		# 2. Gera Avaliação Detalhada e Realista do Cliente
		var review = _generate_review()
		if rep_mgr:
			rep_mgr.add_review(review)

	# 3. Libera a mesa e gera prato sujo/restos
	if assigned_table:
		assigned_table.release()
		assigned_table = null

	# 4. Inicia caminhada de saída
	state = State.LEAVING
	_update_visual_status()

func _generate_review() -> CustomerReview:
	var review = CustomerReview.new()
	review.customer_id = customer_id
	var clock = GameClock.get_instance()
	review.day = clock.day_number if clock else 1
	review.time_string = clock.get_formatted_time() if clock else "12:00"

	# Tempo de Espera
	var wait_ratio = patience_remaining / maxf(1.0, patience_max)
	if wait_ratio >= 0.65:
		review.service_stars = 5.0
	elif wait_ratio >= 0.35:
		review.service_stars = 4.0
	else:
		review.service_stars = 2.5

	# Qualidade da comida
	var total_q = 0
	var count_q = 0
	if assigned_table:
		for it in assigned_table.served_items:
			if is_instance_valid(it) and it.get("quality") != null:
				total_q += it.get("quality")
				count_q += 1
	var avg_item_quality = float(total_q) / float(maxi(1, count_q)) if count_q > 0 else 2.5
	if avg_item_quality >= 3.0:
		review.food_stars = 5.0
	elif avg_item_quality >= 2.0:
		review.food_stars = 4.5
	else:
		review.food_stars = 3.8

	# Limpeza
	review.cleanliness_stars = 5.0

	# Média
	review.stars = (review.service_stars + review.food_stars + review.cleanliness_stars) / 3.0

	# Comentário
	if avg_item_quality >= 3.0 and review.stars >= 4.5:
		review.comment = "Incrível! Os ingredientes são de primeira qualidade e o lanche estava excepcional!"
	elif review.stars >= 4.7:
		review.comment = "Comida maravilhosa e atendimento muito rápido! Voltarei sempre."
	elif review.stars >= 4.0:
		review.comment = "Muito bom! O lanche estava quentinho e saboroso."
	elif review.stars >= 3.0:
		review.comment = "Comida boa, mas o atendimento demorou um pouco."
	else:
		review.comment = "Demora excessiva para receber o pedido."

	if current_order and not current_order.items.is_empty():
		var names = []
		for item in current_order.items:
			names.append(item.get("product_name", "Lanche"))
		review.order_summary = ", ".join(names)

	return review

func _get_patience_mood_icon() -> String:
	var ratio = patience_remaining / maxf(1.0, patience_max)
	if ratio >= 0.7:
		return "🟢 😐"
	elif ratio >= 0.4:
		return "🟡 😕"
	else:
		return "🔴 😠"

func _update_visual_status() -> void:
	if not label_3d:
		return

	match state:
		State.LOOKING_FOR_TABLE:
			label_3d.text = "🚶 Procurando Mesa..."
			label_3d.modulate = Color(0.9, 0.9, 0.9, 1)
		State.WALKING_TO_TABLE:
			var t_id = assigned_table.table_id if assigned_table else 1
			label_3d.text = "🚶 Indo para Mesa #%d" % t_id
			label_3d.modulate = Color(1.0, 0.85, 0.2, 1)
		State.SEATED_WAITING_TO_ORDER:
			var t_id = assigned_table.table_id if assigned_table else 1
			label_3d.text = "📝 [E] Atender Mesa #%d\n%s" % [t_id, _get_patience_mood_icon()]
			label_3d.modulate = Color(1.0, 0.85, 0.2, 1)
		State.WAITING_FOR_FOOD:
			var prod_name = "Pedido"
			if current_order and not current_order.items.is_empty():
				prod_name = current_order.items[0].get("product_name", "Pedido")
			label_3d.text = "⏳ Aguarda: %s\n%s" % [prod_name, _get_patience_mood_icon()]
			label_3d.modulate = Color(0.4, 0.8, 1.0, 1)
		State.EATING:
			label_3d.text = "😋 Comendo..."
			label_3d.modulate = Color(0.3, 1.0, 0.4, 1)
		State.REQUESTING_BILL:
			var total = current_order.total_price if current_order else 0.0
			label_3d.text = "💳 [E] Conta ($%.2f)\n%s" % [total, _get_patience_mood_icon()]
			label_3d.modulate = Color(1.0, 0.5, 0.2, 1)
		State.PAYING:
			label_3d.text = "💵 Pago! Obrigado!"
			label_3d.modulate = Color(0.4, 1.0, 0.5, 1)
		State.LEAVING:
			label_3d.text = "👋 Saindo..."
			label_3d.modulate = Color(0.7, 0.7, 0.7, 1)
		_:
			label_3d.text = ""
