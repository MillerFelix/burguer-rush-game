class_name Customer
extends CharacterBody3D

const HumanoidAnimator = preload("res://src/characters/humanoid_animator.gd")
const CharacterAppearance = preload("res://src/characters/character_appearance.gd")
const CashRegister = preload("res://src/stations/cash_register.gd")
const CustomerMood = preload("res://src/customers/customer_mood.gd")
const CustomerExperience = preload("res://src/customers/customer_experience.gd")
const CustomerReview = preload("res://src/customers/customer_review.gd")
const ReputationManager = preload("res://src/customers/reputation_manager.gd")

enum State {
	ARRIVING,                  # Nascendo na calçada externa
	GOING_TO_ENTRANCE,         # Caminhando em direção à entrada principal (z = 9.5)
	ENTERING_RESTAURANT,       # Cruzando fisicamente a porta (z = 9.0 -> 7.8)
	GOING_TO_SEAT,             # No salão, caminhando pelos corredores até a cadeira
	SITTING,                   # Posicionando-se na cadeira e alinhando com a mesa
	SEATED_WAITING_TO_ORDER,   # Sentado na cadeira esperando atendimento com a mão levantada
	WAITING_FOR_FOOD,          # Pedido feito, mão abaixada, aguardando comida
	EATING,                    # Saboreando a refeição
	GOING_TO_QUEUE,            # Levantou da mesa e está caminhando até a fila do caixa
	IN_QUEUE,                  # Na fila do caixa aguardando pagamento
	PAYING,                    # Realizando pagamento no caixa
	WAITING_FOR_GROUP_PAYMENT, # Acompanhante aguardando o responsável pagar a conta da mesa
	LEAVING,                   # Caminhando de volta para a saída
	FINISHED                   # Saiu do mapa e pronto para ser liberado
}

enum Archetype {
	REGULAR,    # Cliente padrão: tolerância equilibrada e saudável
	IMPATIENT,  # Apressado: menor tolerância, mas ainda jogável
	PATIENT,    # Tranquilo: alta tolerância, paciência prolongada
	CRITIC,     # Crítico Gastronômico: sensível a qualidade e higiene
	CHILD,      # Criança: quer comida rápida, alegria ao comer
	ELDER,      # Idoso: paciente, valoriza limpeza e tranquilidade
	VIP         # VIP: altas expectativas de rapidez e serviço
}

static var next_customer_id: int = 1

@export var move_speed: float = 2.4
@export var eat_duration: float = 4.0
@export var patience_max: float = 80.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var label_3d: Label3D = $Label3D
@onready var animator: HumanoidAnimator = $HumanoidAnimator

var customer_id: int = 1
var state: State = State.ARRIVING
var current_order: Order = null
var requested_product_id: String = ""
var assigned_table: RestaurantTable = null
var assigned_table_id: int = 0
var assigned_seat_index: int = 1
var is_child: bool = false
var is_inside_restaurant: bool = false

var archetype: Archetype = Archetype.REGULAR
var archetype_name: String = "Padrão"
var tolerance_order_wait: float = 80.0
var tolerance_food_wait: float = 120.0
var tolerance_checkout_wait: float = 80.0

# Sistemas de Humor e Experiência
var mood = null
var experience = null
var has_submitted_review: bool = false

var group_members: Array[Customer] = []
var designated_payer: Customer = null
var is_group_payer: bool = false

var target_position: Vector3 = Vector3.ZERO
var exit_position: Vector3 = Vector3(0.0, 0, 10.5)
var path_waypoints: Array[Vector3] = []

var patience_remaining: float = 80.0
var total_wait_time: float = 0.0
var eat_timer: float = 0.0

func _init() -> void:
	if mood == null:
		mood = CustomerMood.new(100.0, 1.0)
	if experience == null:
		experience = CustomerExperience.new(customer_id, archetype_name, 100.0)

func _enter_tree() -> void:
	add_to_group("customers")

func _ready() -> void:
	customer_id = next_customer_id
	next_customer_id += 1

	_setup_archetype()

	if mood == null:
		mood = CustomerMood.new(100.0, _get_decay_multiplier_for_archetype())
	else:
		mood.decay_multiplier = _get_decay_multiplier_for_archetype()

	if experience == null:
		experience = CustomerExperience.new(customer_id, archetype_name, mood.current_mood)
	else:
		experience.customer_id = customer_id
		experience.customer_type = archetype_name

	patience_remaining = patience_max

	if animator:
		animator.setup($Model)
	CharacterAppearance.apply_random_customer_appearance(self, is_child)
	_update_visual_status()

func _setup_archetype() -> void:
	if is_child:
		archetype = Archetype.CHILD
		archetype_name = "Criança"
		patience_max = 65.0
		tolerance_order_wait = 65.0
		tolerance_food_wait = 80.0
		tolerance_checkout_wait = 60.0
		return

	var rand_val = randf()
	if rand_val < 0.20:
		archetype = Archetype.IMPATIENT
		archetype_name = "Apressado"
		patience_max = 55.0
		tolerance_order_wait = 55.0
		tolerance_food_wait = 85.0
		tolerance_checkout_wait = 55.0
	elif rand_val < 0.40:
		archetype = Archetype.PATIENT
		archetype_name = "Tranquilo"
		patience_max = 120.0
		tolerance_order_wait = 140.0
		tolerance_food_wait = 180.0
		tolerance_checkout_wait = 120.0
	elif rand_val < 0.50:
		archetype = Archetype.CRITIC
		archetype_name = "Crítico Gastronômico"
		patience_max = 70.0
		tolerance_order_wait = 70.0
		tolerance_food_wait = 100.0
		tolerance_checkout_wait = 70.0
	elif rand_val < 0.65:
		archetype = Archetype.ELDER
		archetype_name = "Idoso"
		patience_max = 110.0
		tolerance_order_wait = 110.0
		tolerance_food_wait = 150.0
		tolerance_checkout_wait = 90.0
	elif rand_val < 0.75:
		archetype = Archetype.VIP
		archetype_name = "VIP"
		patience_max = 60.0
		tolerance_order_wait = 60.0
		tolerance_food_wait = 95.0
		tolerance_checkout_wait = 65.0
	else:
		archetype = Archetype.REGULAR
		archetype_name = "Padrão"
		patience_max = 80.0
		tolerance_order_wait = 80.0
		tolerance_food_wait = 120.0
		tolerance_checkout_wait = 80.0

func _get_decay_multiplier_for_archetype() -> float:
	match archetype:
		Archetype.IMPATIENT:
			return 1.3
		Archetype.PATIENT:
			return 0.6
		Archetype.CRITIC:
			return 1.15
		Archetype.CHILD:
			return 1.2
		Archetype.ELDER:
			return 0.7
		Archetype.VIP:
			return 1.1
		_:
			return 1.0

# Validação física de limites internos do restaurante
func is_physically_inside_restaurant() -> bool:
	return position.x >= -8.8 and position.x <= 8.8 and position.z >= -8.8 and position.z <= 8.6

func setup(p_spawn_pos: Vector3, p_exit_pos: Vector3, p_product_id: String = "", p_is_child: bool = false) -> void:
	position = p_spawn_pos
	exit_position = p_exit_pos
	requested_product_id = p_product_id
	is_child = p_is_child
	is_inside_restaurant = false
	state = State.ARRIVING

	_setup_archetype()
	mood = CustomerMood.new(100.0, _get_decay_multiplier_for_archetype())
	experience = CustomerExperience.new(customer_id, archetype_name, mood.current_mood)

	CharacterAppearance.apply_random_customer_appearance(self, is_child)
	_update_visual_status()

func assign_seat(table: RestaurantTable, seat_pos: Vector3, seat_idx: int = 1) -> void:
	assigned_table = table
	assigned_table_id = table.table_id if table else 0
	assigned_seat_index = seat_idx
	target_position = seat_pos
	_build_entrance_path(seat_pos)
	state = State.GOING_TO_ENTRANCE
	_update_visual_status()

func _build_entrance_path(seat_pos: Vector3) -> void:
	path_waypoints.clear()
	# 1. Ponto exterior em frente à porta principal
	path_waypoints.append(Vector3(0.0, 0.0, 9.6))
	# 2. Ponto interior após atravessar a soleira da porta (z = 7.8)
	path_waypoints.append(Vector3(0.0, 0.0, 7.8))
	# 3. Corredor central até o alinhamento Z da mesa
	var table_z = assigned_table.position.z if assigned_table else seat_pos.z
	path_waypoints.append(Vector3(0.0, 0.0, table_z))
	# 4. Deslocamento lateral até o assento individual da cadeira
	path_waypoints.append(seat_pos)

func _build_queue_path(queue_slot: Vector3) -> void:
	path_waypoints.clear()
	var curr_z = position.z
	path_waypoints.append(Vector3(0.0, 0.0, curr_z))
	var entry_z = maxf(queue_slot.z, 5.0)
	path_waypoints.append(Vector3(0.0, 0.0, entry_z))
	path_waypoints.append(Vector3(queue_slot.x, 0.0, entry_z))
	path_waypoints.append(queue_slot)

func _build_exit_path() -> void:
	path_waypoints.clear()
	path_waypoints.append(Vector3(0.0, 0.0, position.z))
	path_waypoints.append(Vector3(0.0, 0.0, 7.8))
	path_waypoints.append(Vector3(0.0, 0.0, 9.6))
	path_waypoints.append(exit_position)

func _physics_process(delta: float) -> void:
	if position.z <= 8.2 and not is_inside_restaurant:
		is_inside_restaurant = true

	if animator:
		var can_sit_anim = is_inside_restaurant and is_physically_inside_restaurant()
		var is_seated = can_sit_anim and (state in [State.SITTING, State.SEATED_WAITING_TO_ORDER, State.WAITING_FOR_FOOD, State.EATING])
		var is_eating = (state == State.EATING)
		var is_raising_hand = (state == State.SEATED_WAITING_TO_ORDER)
		animator.update_animation(delta, velocity, is_seated, is_eating, false, is_raising_hand)

	if experience:
		experience.total_time_in_restaurant += delta

	# Processamento de Humor Progressivo e Tolerância por Etapa
	match state:
		State.ARRIVING, State.GOING_TO_ENTRANCE, State.ENTERING_RESTAURANT, State.GOING_TO_SEAT:
			_follow_path_to_destination(delta, true)

		State.SITTING:
			_complete_sitting_transition()

		State.SEATED_WAITING_TO_ORDER:
			total_wait_time += delta
			if experience:
				experience.wait_time_to_order += delta
			if mood:
				mood.decay_progressively(experience.wait_time_to_order, tolerance_order_wait, delta)
				patience_remaining = (mood.current_mood / 100.0) * patience_max

				# Limite de tolerância atingido -> Abandono
				if mood.is_exhausted() or (experience and experience.wait_time_to_order >= tolerance_order_wait):
					abandon_restaurant("Demora no atendimento da mesa")
					return
			_update_visual_status()

		State.WAITING_FOR_FOOD:
			total_wait_time += delta
			if experience:
				experience.wait_time_for_food += delta
			if mood:
				mood.decay_progressively(experience.wait_time_for_food, tolerance_food_wait, delta)
				patience_remaining = (mood.current_mood / 100.0) * patience_max

				# Limite de tolerância atingido -> Abandono
				if mood.is_exhausted() or (experience and experience.wait_time_for_food >= tolerance_food_wait):
					abandon_restaurant("Demora na entrega da refeição")
					return
			_update_visual_status()

		State.EATING:
			eat_timer += delta
			if mood:
				mood.boost(delta * 8.0) # Saborear a refeição melhora o humor
			if eat_timer >= eat_duration:
				_head_to_checkout_queue()

		State.GOING_TO_QUEUE:
			if experience:
				experience.wait_time_checkout += delta
			_follow_path_to_destination(delta, false)

		State.IN_QUEUE, State.PAYING:
			if experience:
				experience.wait_time_checkout += delta
			if mood:
				mood.decay_progressively(experience.wait_time_checkout, tolerance_checkout_wait, delta * 0.5)
			if is_inside_tree():
				look_at(Vector3(1.8, position.y, 0.0), Vector3.UP)
			_update_visual_status()

		State.WAITING_FOR_GROUP_PAYMENT:
			if experience:
				experience.wait_time_checkout += delta
			_update_visual_status()

		State.LEAVING:
			_follow_path_to_destination(delta, false)

func _follow_path_to_destination(delta: float, is_entering: bool) -> void:
	if path_waypoints.is_empty():
		if is_entering:
			_try_reach_seat()
		elif state == State.GOING_TO_QUEUE:
			_reach_queue_slot()
		else:
			state = State.FINISHED
			queue_free()
		return

	var current_target = path_waypoints[0]
	var to_target = current_target - position
	to_target.y = 0.0

	if is_entering:
		if position.z > 9.0:
			state = State.GOING_TO_ENTRANCE
		elif position.z > 8.0:
			state = State.ENTERING_RESTAURANT
		else:
			state = State.GOING_TO_SEAT

	if to_target.length() <= 0.28:
		path_waypoints.remove_at(0)
		if path_waypoints.is_empty():
			if is_entering:
				_try_reach_seat()
			elif state == State.GOING_TO_QUEUE:
				_reach_queue_slot()
			else:
				state = State.FINISHED
				queue_free()
			return
		current_target = path_waypoints[0]
		to_target = current_target - position
		to_target.y = 0.0

	var move_dir = to_target.normalized()
	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed

	if is_inside_tree():
		if move_dir.length_squared() > 0.01:
			look_at(position + Vector3(move_dir.x, 0, move_dir.z), Vector3.UP)
		move_and_slide()
	else:
		position += Vector3(move_dir.x, 0, move_dir.z) * move_speed * delta

func _try_reach_seat() -> void:
	if not assigned_table or not is_physically_inside_restaurant() or position.z > 8.2:
		if assigned_table:
			_build_entrance_path(target_position)
		return

	velocity = Vector3.ZERO
	position = target_position
	state = State.SITTING
	_complete_sitting_transition()

func _complete_sitting_transition() -> void:
	velocity = Vector3.ZERO
	position = target_position
	state = State.SEATED_WAITING_TO_ORDER

	if assigned_table:
		if is_inside_tree():
			var center = assigned_table.position
			look_at(Vector3(center.x, position.y, center.z), Vector3.UP)
		assigned_table.on_customer_seated(self)

		# Avalia limpeza da mesa no momento em que senta
		if experience:
			if assigned_table.table_state == RestaurantTable.TableState.DIRTY:
				experience.table_cleanliness = 0.2
				if mood:
					mood.decay(20.0)
			else:
				experience.table_cleanliness = 1.0

	_update_visual_status()

func _head_to_checkout_queue() -> void:
	if assigned_table and is_instance_valid(assigned_table):
		var table = assigned_table
		var all_members: Array[Customer] = []
		for m in table.seated_customers:
			if is_instance_valid(m):
				all_members.append(m)

		# 1. Desocupa a mesa imediatamente
		table.release()
		assigned_table = null

		if all_members.size() > 1:
			var payer: Customer = null
			for m in all_members:
				if is_instance_valid(m) and not m.is_child:
					payer = m
					break
			if payer == null and not all_members.is_empty():
				payer = all_members[0]

			for m in all_members:
				if is_instance_valid(m):
					m.assigned_table = null
					m.group_members = all_members
					m.designated_payer = payer
					if m == payer:
						m.is_group_payer = true
						m._send_to_cashier_queue()
					else:
						m.is_group_payer = false
						m._send_to_wait_group_payment(payer)
			return

	is_group_payer = true
	group_members = [self]
	_send_to_cashier_queue()

func _send_to_cashier_queue() -> void:
	state = State.GOING_TO_QUEUE

	var reg = CashRegister.instance
	if not reg and is_inside_tree() and get_tree() and get_tree().root:
		reg = get_tree().root.find_child("CashRegister", true, false)
	if not reg and get_parent():
		reg = get_parent().get_node_or_null("CashRegister")

	if reg and reg.has_method("join_queue"):
		target_position = reg.join_queue(self)
		_build_queue_path(target_position)
	else:
		state = State.LEAVING
		_build_exit_path()

	_update_visual_status()

func _send_to_wait_group_payment(payer: Customer) -> void:
	state = State.WAITING_FOR_GROUP_PAYMENT
	var lobby_offset_x = 0.5 + (randf() * 1.5)
	var lobby_offset_z = 6.8 + (randf() * 1.2)
	target_position = Vector3(lobby_offset_x, 0.0, lobby_offset_z)
	path_waypoints.clear()
	path_waypoints.append(target_position)
	_update_visual_status()

func _reach_queue_slot() -> void:
	velocity = Vector3.ZERO
	position = target_position
	if state == State.GOING_TO_QUEUE:
		state = State.IN_QUEUE
		if is_inside_tree():
			look_at(Vector3(1.8, position.y, 0.0), Vector3.UP)
	_update_visual_status()

func update_queue_slot(new_slot_pos: Vector3, is_first: bool) -> void:
	target_position = new_slot_pos
	if (position - new_slot_pos).length() > 0.2:
		path_waypoints.clear()
		path_waypoints.append(new_slot_pos)
		state = State.GOING_TO_QUEUE
	else:
		velocity = Vector3.ZERO
		position = new_slot_pos
		state = State.IN_QUEUE
	_update_visual_status()

func on_payment_completed() -> void:
	if mood:
		mood.boost(15.0)
	_submit_review()

	state = State.LEAVING
	_build_exit_path()
	_update_visual_status()

	if is_group_payer and not group_members.is_empty():
		for companion in group_members:
			if is_instance_valid(companion) and companion != self:
				companion._submit_review()
				companion.state = State.LEAVING
				companion._build_exit_path()
				companion._update_visual_status()

func abandon_restaurant(reason: String) -> void:
	if state == State.LEAVING or state == State.FINISHED:
		return

	if experience:
		experience.abandoned = true
		experience.abandon_reason = reason
		experience.final_mood = mood.current_mood if mood else 0.0

	# Libera a mesa imediatamente
	if assigned_table and is_instance_valid(assigned_table):
		assigned_table.release()
		assigned_table = null

	# Cancela o pedido no OrderManager se ainda não consumido
	if current_order and current_order.state != Order.State.COMPLETED:
		current_order.state = Order.State.CANCELLED
		var order_mgr = _get_order_manager()
		if order_mgr:
			order_mgr.active_orders.erase(current_order)
			if order_mgr.has_signal("order_cancelled"):
				order_mgr.order_cancelled.emit(current_order)

	_submit_review()

	# Se for membro de grupo, acompanhantes também abandonam
	if not group_members.is_empty():
		for companion in group_members:
			if is_instance_valid(companion) and companion != self and companion.state != State.LEAVING:
				if companion.experience:
					companion.experience.abandoned = true
					companion.experience.abandon_reason = reason
					companion.experience.final_mood = companion.mood.current_mood if companion.mood else 0.0
				companion._submit_review()
				companion.state = State.LEAVING
				companion._build_exit_path()
				companion._update_visual_status()

	state = State.LEAVING
	_build_exit_path()
	_update_visual_status()

func _submit_review() -> void:
	if has_submitted_review or not experience:
		return
	has_submitted_review = true

	if mood:
		experience.final_mood = mood.current_mood

	var clock_day = 1
	var clock_time = "12:00"
	var clock = _get_clock()
	if clock:
		clock_day = clock.get("day_number") if clock.get("day_number") != null else 1
		clock_time = clock.get_formatted_time() if clock.has_method("get_formatted_time") else "12:00"

	var review = experience.generate_review(clock_day, clock_time)
	var rep_mgr = ReputationManager.instance
	if not rep_mgr:
		var curr = self.get_parent()
		while curr:
			if curr.has_node("ReputationManager"):
				rep_mgr = curr.get_node("ReputationManager")
				break
			curr = curr.get_parent()
	if not rep_mgr and is_inside_tree() and get_tree() and get_tree().root:
		rep_mgr = get_tree().root.find_child("ReputationManager", true, false)

	if rep_mgr:
		rep_mgr.add_review(review)

func _get_clock() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.find_child("GameClock", true, false)
	return null

func _get_order_manager() -> OrderManager:
	var order_mgr = OrderManager.instance
	if not order_mgr and is_inside_tree() and get_tree() and get_tree().root:
		order_mgr = get_tree().root.find_child("OrderManager", true, false)
	return order_mgr

func interact(player: Node3D = null) -> void:
	match state:
		State.SEATED_WAITING_TO_ORDER:
			place_order(player)
			if assigned_table:
				assigned_table._update_visual_status()

		State.WAITING_FOR_FOOD:
			if assigned_table:
				assigned_table.interact(player)

		State.IN_QUEUE, State.PAYING:
			var reg = CashRegister.get_instance()
			if not reg and is_inside_tree():
				reg = get_tree().root.find_child("CashRegister", true, false) as CashRegister
			if reg:
				reg.process_checkout(player)

func place_order(player: Node = null) -> void:
	if state != State.SEATED_WAITING_TO_ORDER:
		return

	var order_mgr = _get_order_manager()
	var tbl_id = assigned_table.table_id if (assigned_table and is_instance_valid(assigned_table)) else 1
	var group_size = assigned_table.seated_customers.size() if (assigned_table and is_instance_valid(assigned_table)) else 1

	if order_mgr:
		if group_size > 1:
			current_order = order_mgr.create_group_order(self, group_size, tbl_id, "DINE_IN")
		else:
			var pid = requested_product_id
			if pid.is_empty():
				current_order = order_mgr.create_group_order(self, 1, tbl_id, "DINE_IN")
			else:
				current_order = order_mgr.create_order(self, pid, 1, tbl_id, "DINE_IN", 1)
	elif current_order == null:
		current_order = Order.new()
		current_order.id = customer_id
		current_order.table_id = tbl_id
		current_order.total_price = 18.0

	# Registrou o pedido -> mão abaixa e humor ganha um boost positivo
	if mood:
		mood.boost(15.0)

	state = State.WAITING_FOR_FOOD
	_update_visual_status()

	if assigned_table and is_instance_valid(assigned_table):
		for c in assigned_table.seated_customers:
			if is_instance_valid(c) and c != self:
				c.current_order = current_order
				c.state = State.WAITING_FOR_FOOD
				if c.mood:
					c.mood.boost(15.0)
				c._update_visual_status()
		assigned_table._update_visual_status()

	var economy = EconomyManager.get_instance()
	if not economy and is_inside_tree():
		economy = get_tree().root.find_child("EconomyManager", true, false) as EconomyManager
	if economy and economy.has_method("record_customer_served"):
		economy.record_customer_served()

	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_feedback"):
			var desc = (" (%d pessoas)" % group_size) if group_size > 1 else ""
			hud.show_feedback("📝 Pedido anotado da Mesa #%d%s!" % [tbl_id, desc])

func receive_food() -> void:
	if state == State.WAITING_FOR_FOOD:
		state = State.EATING
		eat_timer = 0.0

		if mood:
			mood.boost(30.0) # Alimento recebido recupera bastante satisfação

		if experience and current_order:
			var items_str: Array[String] = []
			for it in current_order.items:
				items_str.append("%dx %s" % [it.get("quantity", 1), it.get("product_name", "Lanche")])
			experience.order_summary = ", ".join(items_str)
			experience.food_quality = 1.0
			experience.order_correct = true

		_update_visual_status()

func get_interaction_prompt(player: Node = null) -> String:
	match state:
		State.SEATED_WAITING_TO_ORDER:
			return "E — Atender Cliente (Mesa #%d)" % (assigned_table.table_id if assigned_table else 1)
		State.WAITING_FOR_FOOD:
			return "Aguardando refeição..."
		State.EATING:
			return "Saboreando a refeição..."
		State.IN_QUEUE, State.PAYING:
			var price = current_order.total_price if current_order else 15.0
			return "E — Receber Pagamento (R$ %.2f)" % price
	return ""

func _update_visual_status() -> void:
	if not label_3d:
		return

	var emoji = mood.get_emoji() if mood else "🙂"
	var mood_color = mood.get_color() if mood else Color(1, 1, 1)

	match state:
		State.ARRIVING, State.GOING_TO_ENTRANCE, State.ENTERING_RESTAURANT, State.GOING_TO_SEAT:
			label_3d.text = "%s 🚶 Entrando..." % emoji
			label_3d.modulate = Color(0.9, 0.9, 0.4)

		State.SITTING, State.SEATED_WAITING_TO_ORDER:
			var pct = int(mood.current_mood) if mood else 100
			if pct <= 25:
				label_3d.text = "%s ⚠️ Quase Desistindo! (%d%%)" % [emoji, pct]
				label_3d.modulate = Color(1.0, 0.25, 0.25)
			else:
				label_3d.text = "%s 🙋 Aguardando Atendimento (%d%%)" % [emoji, pct]
				label_3d.modulate = mood_color

		State.WAITING_FOR_FOOD:
			var pct = int(mood.current_mood) if mood else 100
			if pct <= 25:
				label_3d.text = "%s ⚠️ Com Fome / Atrasado! (%d%%)" % [emoji, pct]
				label_3d.modulate = Color(1.0, 0.25, 0.25)
			else:
				label_3d.text = "%s ⏳ Aguardando Refeição (%d%%)" % [emoji, pct]
				label_3d.modulate = mood_color

		State.EATING:
			label_3d.text = "😋 🍔 Saboreando Refeição..."
			label_3d.modulate = Color(0.3, 0.9, 0.4)

		State.GOING_TO_QUEUE:
			label_3d.text = "%s 🚶 Indo para a fila" % emoji
			label_3d.modulate = Color(0.9, 0.8, 0.3)

		State.IN_QUEUE, State.PAYING:
			var price = current_order.total_price if current_order else 15.0
			label_3d.text = "%s 💳 Na fila do Caixa (R$ %.2f)" % [emoji, price]
			label_3d.modulate = Color(0.2, 0.9, 0.6)

		State.WAITING_FOR_GROUP_PAYMENT:
			label_3d.text = "%s ⏳ Aguardando Família" % emoji
			label_3d.modulate = Color(0.9, 0.8, 0.4)

		State.LEAVING:
			if experience and experience.abandoned:
				label_3d.text = "😡 🚶 Desistiu e foi embora!"
				label_3d.modulate = Color(1.0, 0.2, 0.2)
			else:
				label_3d.text = "%s 👋 Volte sempre!" % emoji
				label_3d.modulate = Color(0.85, 0.85, 0.85)
