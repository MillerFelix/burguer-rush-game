class_name Customer
extends CharacterBody3D

const HumanoidAnimator = preload("res://src/characters/humanoid_animator.gd")
const CharacterAppearance = preload("res://src/characters/character_appearance.gd")

enum State {
	ARRIVING,                # Nascendo na calçada externa
	GOING_TO_ENTRANCE,       # Caminhando em direção à entrada principal (z = 9.5)
	ENTERING_RESTAURANT,     # Cruzando fisicamente a porta (z = 9.0 -> 7.8)
	GOING_TO_SEAT,           # No salão, caminhando pelos corredores até a cadeira
	SITTING,                 # Posicionando-se na cadeira e alinhando com a mesa
	SEATED_WAITING_TO_ORDER, # Sentado na cadeira esperando para pedir
	WAITING_FOR_FOOD,        # Pedido feito, aguardando comida
	EATING,                  # Saboreando o lanche
	REQUESTING_BILL,         # Pediu a conta
	PAYING,                  # Realizando pagamento
	LEAVING,                 # Levantando e caminhando de volta para a saída
	FINISHED                 # Saiu do mapa e pronto para ser liberado
}

static var next_customer_id: int = 1

@export var move_speed: float = 2.4
@export var eat_duration: float = 4.0
@export var patience_max: float = 60.0

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

var target_position: Vector3 = Vector3.ZERO
var exit_position: Vector3 = Vector3(0.0, 0, 10.5)
var path_waypoints: Array[Vector3] = []

var patience_remaining: float = 60.0
var total_wait_time: float = 0.0
var eat_timer: float = 0.0

func _ready() -> void:
	customer_id = next_customer_id
	next_customer_id += 1
	patience_remaining = patience_max

	if animator:
		animator.setup($Model)
	CharacterAppearance.apply_random_customer_appearance(self, is_child)
	_update_visual_status()

# Validação física rigorosa de limites internos do restaurante
func is_physically_inside_restaurant() -> bool:
	return position.x >= -8.8 and position.x <= 8.8 and position.z >= -8.8 and position.z <= 8.6

func setup(p_spawn_pos: Vector3, p_exit_pos: Vector3, p_product_id: String = "", p_is_child: bool = false) -> void:
	position = p_spawn_pos
	exit_position = p_exit_pos
	requested_product_id = p_product_id
	is_child = p_is_child
	is_inside_restaurant = false
	state = State.ARRIVING

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

func _build_exit_path() -> void:
	path_waypoints.clear()

	# 1. Sai da cadeira para o corredor da mesa
	var table_z = assigned_table.position.z if assigned_table else position.z
	path_waypoints.append(Vector3(0.0, 0.0, table_z))

	# 2. Corredor até a porta interna
	path_waypoints.append(Vector3(0.0, 0.0, 7.8))

	# 3. Atravessa a porta para a calçada exterior
	path_waypoints.append(Vector3(0.0, 0.0, 9.6))

	# 4. Calçada de saída
	path_waypoints.append(exit_position)

func _physics_process(delta: float) -> void:
	# Atualiza detecção de estar dentro do restaurante
	if position.z <= 8.2 and not is_inside_restaurant:
		is_inside_restaurant = true

	# Atualiza animação corporal procedural
	if animator:
		# REGRA ABSOLUTA: Só senta visualmente se estiver COMPROVADAMENTE dentro do restaurante
		var can_sit_anim = is_inside_restaurant and is_physically_inside_restaurant()
		var is_seated = can_sit_anim and (state in [State.SITTING, State.SEATED_WAITING_TO_ORDER, State.WAITING_FOR_FOOD, State.EATING, State.REQUESTING_BILL, State.PAYING])
		var is_eating = (state == State.EATING)
		animator.update_animation(delta, velocity, is_seated, is_eating, false)

	# Decaimento de paciência apenas enquanto aguarda no restaurante
	if state in [State.SEATED_WAITING_TO_ORDER, State.WAITING_FOR_FOOD, State.REQUESTING_BILL]:
		patience_remaining = maxf(0.0, patience_remaining - delta)
		total_wait_time += delta

	match state:
		State.ARRIVING, State.GOING_TO_ENTRANCE, State.ENTERING_RESTAURANT, State.GOING_TO_SEAT:
			_follow_path_to_destination(delta, true)

		State.SITTING:
			_complete_sitting_transition()

		State.EATING:
			eat_timer += delta
			if eat_timer >= eat_duration:
				state = State.REQUESTING_BILL
				_update_visual_status()
				if assigned_table:
					assigned_table._update_visual_status()

		State.LEAVING:
			_follow_path_to_destination(delta, false)

func _follow_path_to_destination(delta: float, is_entering: bool) -> void:
	if path_waypoints.is_empty():
		if is_entering:
			_try_reach_seat()
		else:
			state = State.FINISHED
			queue_free()
		return

	var current_target = path_waypoints[0]
	var to_target = current_target - position
	to_target.y = 0.0

	# Transição de estados de navegação de entrada
	if is_entering:
		if position.z > 9.0:
			state = State.GOING_TO_ENTRANCE
		elif position.z > 8.0:
			state = State.ENTERING_RESTAURANT
		else:
			state = State.GOING_TO_SEAT

	# Alcance do waypoint atual
	if to_target.length() <= 0.28:
		path_waypoints.remove_at(0)
		if path_waypoints.is_empty():
			if is_entering:
				_try_reach_seat()
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
	# REGRA ABSOLUTA: Verificação de segurança tripla contra sentar fora
	if not assigned_table or not is_physically_inside_restaurant() or position.z > 8.2:
		# Se ainda estiver fora do salão, reconstrói o caminho para a porta e NÃO senta!
		if assigned_table:
			_build_entrance_path(target_position)
		return

	# Chegou fisicamente à cadeira dentro do salão
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

	_update_visual_status()

func interact(player: Node3D = null) -> void:
	match state:
		State.SEATED_WAITING_TO_ORDER:
			place_order(player)
			if assigned_table:
				assigned_table._update_visual_status()

		State.WAITING_FOR_FOOD:
			if assigned_table:
				assigned_table.interact(player)

		State.REQUESTING_BILL:
			present_bill(player)
			if assigned_table:
				assigned_table._update_visual_status()

		State.PAYING:
			pay_and_leave(player)
			if assigned_table:
				assigned_table._update_visual_status()

func place_order(player: Node = null) -> void:
	if state != State.SEATED_WAITING_TO_ORDER:
		return

	var order_mgr = OrderManager.get_instance()
	if not order_mgr and is_inside_tree():
		order_mgr = get_tree().root.find_child("OrderManager", true, false) as OrderManager
	if not order_mgr:
		return

	var tbl_id = assigned_table.table_id if (assigned_table and is_instance_valid(assigned_table)) else 1
	var group_size = assigned_table.seated_customers.size() if (assigned_table and is_instance_valid(assigned_table)) else 1

	if group_size > 1:
		current_order = order_mgr.create_group_order(self, group_size, tbl_id, "DINE_IN")
	else:
		var pid = requested_product_id
		if pid.is_empty():
			current_order = order_mgr.create_group_order(self, 1, tbl_id, "DINE_IN")
		else:
			current_order = order_mgr.create_order(self, pid, 1, tbl_id, "DINE_IN", 1)

	state = State.WAITING_FOR_FOOD
	_update_visual_status()

	# Sincroniza todos os membros da mesa com o mesmo pedido e estado de espera
	if assigned_table and is_instance_valid(assigned_table):
		for c in assigned_table.seated_customers:
			if is_instance_valid(c) and c != self:
				c.current_order = current_order
				c.state = State.WAITING_FOR_FOOD
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
		_update_visual_status()

func present_bill(player: Node = null) -> void:
	if state == State.REQUESTING_BILL:
		state = State.PAYING
		_update_visual_status()

func pay_and_leave(player: Node = null) -> void:
	if state != State.PAYING:
		return

	var economy = EconomyManager.get_instance()
	if economy and current_order:
		economy.add_money(current_order.total_price)
		economy.register_sale(current_order.total_price)

	var prog = ProgressionManager.get_instance()
	if prog:
		prog.register_xp(25)

	if assigned_table:
		assigned_table.release()
		assigned_table = null

	state = State.LEAVING
	_build_exit_path()
	_update_visual_status()

func get_interaction_prompt(player: Node = null) -> String:
	match state:
		State.SEATED_WAITING_TO_ORDER:
			return "E — Atender Cliente (Mesa #%d)" % (assigned_table.table_id if assigned_table else 1)
		State.WAITING_FOR_FOOD:
			return "Aguardando refeição..."
		State.EATING:
			return "Saboreando a refeição..."
		State.REQUESTING_BILL:
			return "E — Entregar Conta"
		State.PAYING:
			return "E — Receber Pagamento"
	return ""

func _get_product_display_name(product_id: String) -> String:
	match product_id:
		"burger_classic": return "Hambúrguer Clássico"
		"burger_cheese": return "Cheeseburger"
		"fries": return "Batata Frita"
		"drink_cola": return "Refrigerante Cola"
		"drink_orange": return "Suco de Laranja"
	return "Lanche"

func _update_visual_status() -> void:
	if not label_3d:
		return

	match state:
		State.ARRIVING, State.GOING_TO_ENTRANCE, State.ENTERING_RESTAURANT, State.GOING_TO_SEAT:
			label_3d.text = "🚶 Entrando..."
			label_3d.modulate = Color(0.9, 0.9, 0.4)
		State.SITTING, State.SEATED_WAITING_TO_ORDER:
			label_3d.text = "🙋 Quer pedir"
			label_3d.modulate = Color(1.0, 0.85, 0.2)
		State.WAITING_FOR_FOOD:
			var pct = int((patience_remaining / patience_max) * 100)
			label_3d.text = "⏳ Esperando (%d%%)" % pct
			label_3d.modulate = Color(0.4, 0.7, 1.0) if pct > 40 else Color(1.0, 0.3, 0.3)
		State.EATING:
			label_3d.text = "😋 Comendo..."
			label_3d.modulate = Color(0.3, 0.9, 0.4)
		State.REQUESTING_BILL:
			label_3d.text = "🧾 Pediu a conta"
			label_3d.modulate = Color(0.95, 0.8, 0.2)
		State.PAYING:
			label_3d.text = "💳 Pagando..."
			label_3d.modulate = Color(0.2, 0.9, 0.6)
		State.LEAVING:
			label_3d.text = "👋 Saindo..."
			label_3d.modulate = Color(0.8, 0.8, 0.8)
