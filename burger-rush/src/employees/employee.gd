class_name Employee
extends CharacterBody3D

# =============================================================================
# BURGER RUSH - FUNCIONÁRIO NPC AUTÔNOMO DE OPERAÇÃO
#
# Personagem físico com IA autônoma e ciclo de execução contínuo:
# 1. Ponto de espera padrão no salão de atendimento, próximo à entrada principal.
# 2. Navegação multi-zona com corredores físicos reais e passagens:
#    - Salão (mesas, entrada, atendimento)
#    - Cozinha (cookline, pia, drive-thru, balcão)
#    - Armazém (porta interna da cozinha, estoque)
#    - Área Externa / Doca (porta do armazém para o beco/recebimento)
# 3. Busca contínua periódica de tarefas com priorização estrita:
#    - Prioridade 1: Atendimento de mesas (clientes esperando pedido)
#    - Prioridade 2: Atendimento de Drive-Thru (veículos na janela)
#    - Prioridade 3: Limpeza de mesas sujas
#    - Prioridade 4: Limpeza de poças e manchas no chão
#    - Prioridade 5: Limpeza de bancadas / estações
#    - Prioridade 6: Cobrança e checkout no caixa
# 4. Reserva exclusiva e prevenção de conflitos.
# 5. Sistema de recuperação de travamento (stuck recovery).
# 6. Bucha física com camada de sujeira e ciclo de lavagem na pia.
# =============================================================================

const HumanoidAnimator = preload("res://src/characters/humanoid_animator.gd")
const CharacterAppearance = preload("res://src/characters/character_appearance.gd")
const EmployeeTask = preload("res://src/employees/employee_task.gd")
const EmployeeTaskManager = preload("res://src/employees/employee_task_manager.gd")
const RestaurantTable = preload("res://src/stations/restaurant_table.gd")
const CommercialSink = preload("res://src/stations/commercial_sink.gd")
const CashRegister = preload("res://src/stations/cash_register.gd")
const Customer = preload("res://src/customers/customer.gd")
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

enum Role {
	UNASSIGNED,
	GENERAL,
	GRILL,
	ATTENDANT,
	CLEANER
}

enum State {
	IDLE_WAITING,       # Aguardando no salão próximo à entrada / verificando tarefas
	MOVING_TO_TASK,     # Caminhando até o local da tarefa
	MOVING_TO_SINK,     # Caminhando até a pia para lavar a bucha suja
	WASHING_SPONGE,     # Lavando a bucha na pia industrial
	CLEANING_SURFACE,   # Esfregando e limpando mesa/poça/mancha/bancada
	SERVING_CUSTOMER,   # Atendendo cliente na mesa
	SERVING_DRIVETHRU,  # Atendendo janela do Drive-Thru
	OPERATING_CASHIER,  # Operando o caixa
	RETURNING_TO_REST   # Retornando para o ponto de espera no salão
}

enum Zone {
	HALL,      # Salão principal (Z >= 0.2)
	KITCHEN,   # Cozinha (Z < 0.2 e X > -3.0)
	STORAGE,   # Armazém / Estoque interno (Z < 0.2 e X em [-9.0, -3.0])
	EXTERIOR   # Beco externo / Doca de recebimento (X < -9.0)
}

@export var move_speed: float = 3.2
@export var employee_id: int = 1
@export var employee_name: String = "Carlos"
@export var role: Role = Role.GENERAL
@export var weekly_salary: float = 250.0
@export var daily_salary: float = 50.0
@export var hired_day: int = 1

func set_role(new_role: Role) -> void:
	role = new_role

func get_role_name() -> String:
	match role:
		Role.GENERAL:
			return "🛠️ Atendente & Auxiliar Geral"
		Role.GRILL:
			return "🍳 Chapa"
		Role.ATTENDANT:
			return "📝 Atendimento"
		Role.CLEANER:
			return "🧹 Limpeza"
		Role.UNASSIGNED:
			return "⚪ Sem Função"
	return "Funcionário"

## Retorna a descrição exata do status atual do funcionário
func get_current_status_text() -> String:
	match state:
		State.IDLE_WAITING, State.RETURNING_TO_REST:
			return "Aguardando tarefa"
		State.MOVING_TO_SINK, State.WASHING_SPONGE:
			return "Lavando a bucha"
		State.CLEANING_SURFACE:
			if current_task and is_instance_valid(current_task.target_node):
				var tgt = current_task.target_node
				if tgt is RestaurantTable:
					return "Limpando mesa"
				elif tgt.is_in_group("floor_puddles") or tgt.is_in_group("floor_dirt_spots") or tgt.name.begins_with("Floor"):
					return "Limpando chão"
				else:
					return "Limpando bancada"
			return "Limpando superfície"
		State.SERVING_CUSTOMER:
			return "Atendendo cliente"
		State.SERVING_DRIVETHRU:
			return "Atendendo drive-thru"
		State.OPERATING_CASHIER:
			return "Trabalhando no caixa"
		State.MOVING_TO_TASK:
			if current_task:
				match current_task.task_type:
					EmployeeTask.TaskType.CLEAN_TABLE:
						return "Limpando mesa"
					EmployeeTask.TaskType.CLEAN_PUDDLE, EmployeeTask.TaskType.CLEAN_FLOOR_SPOT:
						return "Limpando chão"
					EmployeeTask.TaskType.CLEAN_STATION:
						return "Limpando bancada"
					EmployeeTask.TaskType.SERVE_CUSTOMER:
						return "Atendendo cliente"
					EmployeeTask.TaskType.SERVE_DRIVETHRU:
						return "Atendendo drive-thru"
					EmployeeTask.TaskType.OPERATE_CASHIER:
						return "Trabalhando no caixa"
					EmployeeTask.TaskType.RESTOCK:
						return "Guardando mercadorias"
			return "Aguardando tarefa"
	return "Aguardando tarefa"

## Retorna a tarefa atual em formato de destaque
func get_current_task_text() -> String:
	match state:
		State.IDLE_WAITING:
			return "Aguardando tarefa"
		State.RETURNING_TO_REST:
			return "Retornando ao posto de atendimento"
		State.MOVING_TO_SINK:
			return "Indo à pia para higienizar a bucha"
		State.WASHING_SPONGE:
			return "Lavando a bucha na pia industrial"
		State.CLEANING_SURFACE:
			if current_task and is_instance_valid(current_task.target_node):
				var tgt = current_task.target_node
				if tgt is RestaurantTable:
					return "Limpando e higienizando a Mesa #%d" % tgt.table_id
				elif tgt.is_in_group("floor_puddles") or tgt.name.begins_with("FloorPuddle"):
					return "Secando poça de água no chão"
				elif tgt.is_in_group("floor_dirt_spots") or tgt.name.begins_with("FloorDirt"):
					return "Limpando mancha de sujeira no piso"
				elif tgt.has_method("clean_grill"):
					return "Limpando e raspando a chapa"
				else:
					return "Limpando bancada de preparo"
			return "Higienizando superfície"
		State.SERVING_CUSTOMER:
			if current_task and is_instance_valid(current_task.target_node) and current_task.target_node is RestaurantTable:
				return "Anotando pedido dos clientes na Mesa #%d" % current_task.target_node.table_id
			return "Atendendo clientes no salão"
		State.SERVING_DRIVETHRU:
			return "Atendendo veículo na janela do Drive-Thru"
		State.OPERATING_CASHIER:
			return "Processando pagamento no caixa"
		State.MOVING_TO_TASK:
			if current_task:
				match current_task.task_type:
					EmployeeTask.TaskType.CLEAN_TABLE:
						if is_instance_valid(current_task.target_node) and current_task.target_node is RestaurantTable:
							return "Indo limpar a Mesa #%d" % current_task.target_node.table_id
						return "Indo limpar mesa"
					EmployeeTask.TaskType.CLEAN_PUDDLE, EmployeeTask.TaskType.CLEAN_FLOOR_SPOT:
						return "Indo limpar sujeira no chão"
					EmployeeTask.TaskType.CLEAN_STATION:
						return "Indo higienizar equipamento/bancada"
					EmployeeTask.TaskType.SERVE_CUSTOMER:
						return "Indo atender cliente no salão"
					EmployeeTask.TaskType.SERVE_DRIVETHRU:
						return "Indo atender veículo no Drive-Thru"
					EmployeeTask.TaskType.OPERATE_CASHIER:
						return "Indo atender fila do caixa"
					EmployeeTask.TaskType.RESTOCK:
						return "Guardando caixa de mercadorias no estoque"
			return "Aguardando tarefa"
	return "Aguardando tarefa"

## Retorna o estado resumido de trabalho: Trabalhando vs Aguardando
func get_work_state_text() -> String:
	if state in [State.MOVING_TO_TASK, State.MOVING_TO_SINK, State.WASHING_SPONGE, State.CLEANING_SURFACE, State.SERVING_CUSTOMER, State.SERVING_DRIVETHRU, State.OPERATING_CASHIER]:
		return "Trabalhando"
	return "Aguardando"

@onready var animator: HumanoidAnimator = $HumanoidAnimator
@onready var hold_position: Node3D = $HoldPosition
@onready var sponge_visual: Node3D = get_node_or_null("Model/ArmRight/HandRight/EmployeeSponge")
@onready var sponge_dirt_mesh: MeshInstance3D = get_node_or_null("Model/ArmRight/HandRight/EmployeeSponge/SpongeDirtLayer")
@onready var action_audio: AudioStreamPlayer3D = null

var state: State = State.IDLE_WAITING
var current_task: EmployeeTask = null
var target_position: Vector3 = Vector3.ZERO
var rest_position: Vector3 = Vector3(2.4, 0.0, 7.5) # Salão, próximo à porta principal

var waypoints: Array[Vector3] = []
var _stuck_timer: float = 0.0
var _last_stuck_pos: Vector3 = Vector3.ZERO
var _stuck_retries: int = 0
var _using_alt_route: bool = false

var is_sponge_dirty: bool = false
var task_timer: float = 0.0
var search_cooldown: float = 0.0
var tasks_completed: int = 0

func _ready() -> void:
	if animator:
		animator.setup($Model)
	CharacterAppearance.apply_employee_appearance(self, employee_name)

	# Cria player de áudio dedicado para ações do funcionário
	if not action_audio:
		action_audio = AudioStreamPlayer3D.new()
		action_audio.name = "EmployeeActionAudio"
		action_audio.unit_size = 2.5
		action_audio.max_distance = 16.0
		add_child(action_audio)

	set_sponge_dirty(false)
	_update_sponge_visibility(false)
	print("[EMPLOYEE] %s pronto para o expediente no salão do Burger Rush!" % employee_name)

func set_sponge_dirty(dirty: bool) -> void:
	is_sponge_dirty = dirty
	if sponge_dirt_mesh:
		sponge_dirt_mesh.visible = dirty

func _update_sponge_visibility(visible_state: bool) -> void:
	if sponge_visual:
		sponge_visual.visible = visible_state

func _physics_process(delta: float) -> void:
	if animator:
		var is_working = state in [State.WASHING_SPONGE, State.CLEANING_SURFACE, State.SERVING_CUSTOMER, State.SERVING_DRIVETHRU, State.OPERATING_CASHIER]
		animator.update_animation(delta, velocity, false, is_working, sponge_visual != null and sponge_visual.visible)

	match state:
		State.IDLE_WAITING:
			search_cooldown -= delta
			if search_cooldown <= 0.0:
				search_cooldown = 0.35
				_check_for_tasks()

		State.RETURNING_TO_REST:
			# Durante o retorno, verifica periodicamente se novas tarefas surgiram
			search_cooldown -= delta
			if search_cooldown <= 0.0:
				search_cooldown = 0.40
				var task_mgr = _get_task_manager()
				if task_mgr:
					var best = task_mgr.get_best_available_task(self, not is_sponge_dirty)
					if best:
						if task_mgr.claim_task(best, self):
							_start_task(best)
							return
			_handle_movement(delta, _on_reached_rest_area)

		State.MOVING_TO_TASK:
			_handle_movement(delta, _on_reached_task_target)

		State.MOVING_TO_SINK:
			_handle_movement(delta, _on_reached_sink)

		State.WASHING_SPONGE:
			task_timer += delta
			if task_timer >= 1.2:
				_finish_washing_sponge()

		State.CLEANING_SURFACE:
			task_timer += delta
			if task_timer >= 1.3:
				_finish_cleaning_surface()

		State.SERVING_CUSTOMER:
			task_timer += delta
			if task_timer >= 0.8:
				_finish_serving_customer()

		State.SERVING_DRIVETHRU:
			task_timer += delta
			if task_timer >= 0.8:
				_finish_serving_drivethru()

		State.OPERATING_CASHIER:
			task_timer += delta
			if task_timer >= 0.9:
				_finish_operating_cashier()

## Identifica em qual zona do restaurante uma coordenada se encontra
func get_zone_of_pos(pos: Vector3) -> Zone:
	if pos.x < -9.0:
		return Zone.EXTERIOR
	elif pos.z >= 0.2:
		return Zone.HALL
	elif pos.x <= -3.0:
		return Zone.STORAGE
	else:
		return Zone.KITCHEN

## Constrói caminho em malha de waypoints respeitando todas as paredes, balcão e portas
func _build_path_to(dest: Vector3, _use_alt: bool = false) -> Array[Vector3]:
	var path: Array[Vector3] = []
	var start = global_position if is_inside_tree() else position
	var from_zone = get_zone_of_pos(start)
	var to_zone = get_zone_of_pos(dest)

	# 1. Movimentação dentro da mesma zona
	if from_zone == to_zone:
		match from_zone:
			Zone.HALL:
				# No salão: navega pelos corredores longitudinais e transversais
				if absf(start.x - dest.x) > 2.2:
					path.append(Vector3(start.x, 0.0, 1.5))
					path.append(Vector3(dest.x, 0.0, 1.5))
				path.append(dest)
			Zone.KITCHEN:
				if (start.z < -5.5 and dest.z > -5.0) or (start.z > -5.0 and dest.z < -5.5) or absf(start.x - dest.x) > 3.0:
					path.append(Vector3(start.x, 0.0, -3.2))
					path.append(Vector3(dest.x, 0.0, -3.2))
				path.append(dest)
			Zone.STORAGE:
				path.append(Vector3(dest.x, 0.0, -3.5))
				path.append(dest)
			Zone.EXTERIOR:
				path.append(dest)
		return path

	# 2. Transições entre zonas diferentes (Navegação estruturada por nós)
	var current_z = from_zone

	# Fila de transição de zonas
	var zone_steps: Array[Zone] = []
	if from_zone == Zone.HALL:
		if to_zone == Zone.KITCHEN: zone_steps = [Zone.KITCHEN]
		elif to_zone == Zone.STORAGE: zone_steps = [Zone.KITCHEN, Zone.STORAGE]
		elif to_zone == Zone.EXTERIOR: zone_steps = [Zone.KITCHEN, Zone.STORAGE, Zone.EXTERIOR]
	elif from_zone == Zone.KITCHEN:
		if to_zone == Zone.HALL: zone_steps = [Zone.HALL]
		elif to_zone == Zone.STORAGE: zone_steps = [Zone.STORAGE]
		elif to_zone == Zone.EXTERIOR: zone_steps = [Zone.STORAGE, Zone.EXTERIOR]
	elif from_zone == Zone.STORAGE:
		if to_zone == Zone.KITCHEN: zone_steps = [Zone.KITCHEN]
		elif to_zone == Zone.HALL: zone_steps = [Zone.KITCHEN, Zone.HALL]
		elif to_zone == Zone.EXTERIOR: zone_steps = [Zone.EXTERIOR]
	elif from_zone == Zone.EXTERIOR:
		if to_zone == Zone.STORAGE: zone_steps = [Zone.STORAGE]
		elif to_zone == Zone.KITCHEN: zone_steps = [Zone.STORAGE, Zone.KITCHEN]
		elif to_zone == Zone.HALL: zone_steps = [Zone.STORAGE, Zone.KITCHEN, Zone.HALL]

	var cur_pos = start
	for next_z in zone_steps:
		# Transição HALL -> KITCHEN (pela Passagem Leste do balcão X = 4.8)
		if current_z == Zone.HALL and next_z == Zone.KITCHEN:
			if cur_pos.z > 2.2:
				path.append(Vector3(cur_pos.x, 0.0, 1.5))
			path.append(Vector3(4.8, 0.0, 1.5))
			path.append(Vector3(4.8, 0.0, -3.2))
			cur_pos = Vector3(4.8, 0.0, -3.2)

		# Transição KITCHEN -> HALL (pela Passagem Leste do balcão X = 4.8)
		elif current_z == Zone.KITCHEN and next_z == Zone.HALL:
			if absf(cur_pos.z - (-3.2)) > 0.6:
				path.append(Vector3(cur_pos.x, 0.0, -3.2))
			path.append(Vector3(4.8, 0.0, -3.2))
			path.append(Vector3(4.8, 0.0, 1.5))
			if dest.z > 2.2:
				if absf(dest.x) < 2.0:
					path.append(Vector3(0.0, 0.0, 1.5))
					path.append(Vector3(0.0, 0.0, dest.z))
				elif dest.x < -3.0:
					path.append(Vector3(-4.2, 0.0, 1.5))
					path.append(Vector3(-4.2, 0.0, dest.z))
				elif dest.x > 3.0:
					path.append(Vector3(4.2, 0.0, 1.5))
					path.append(Vector3(4.2, 0.0, dest.z))
			cur_pos = Vector3(4.8, 0.0, 1.5)

		# Transição KITCHEN -> STORAGE (pela porta interna da cozinha X = -3.0, Z = -3.75)
		elif current_z == Zone.KITCHEN and next_z == Zone.STORAGE:
			if absf(cur_pos.z - (-3.2)) > 0.6:
				path.append(Vector3(cur_pos.x, 0.0, -3.2))
			path.append(Vector3(-2.5, 0.0, -3.5))
			path.append(Vector3(-4.5, 0.0, -3.5))
			cur_pos = Vector3(-4.5, 0.0, -3.5)

		# Transição STORAGE -> KITCHEN (pela porta interna da cozinha X = -3.0, Z = -3.75)
		elif current_z == Zone.STORAGE and next_z == Zone.KITCHEN:
			path.append(Vector3(-4.5, 0.0, -3.5))
			path.append(Vector3(-2.5, 0.0, -3.5))
			path.append(Vector3(-2.5, 0.0, -3.2))
			cur_pos = Vector3(-2.5, 0.0, -3.2)

		# Transição STORAGE -> EXTERIOR (pela porta oeste da doca X = -9.0, Z = -3.5)
		elif current_z == Zone.STORAGE and next_z == Zone.EXTERIOR:
			path.append(Vector3(-8.2, 0.0, -3.5))
			path.append(Vector3(-10.5, 0.0, -3.5))
			cur_pos = Vector3(-10.5, 0.0, -3.5)

		# Transição EXTERIOR -> STORAGE (pela porta oeste da doca X = -9.0, Z = -3.5)
		elif current_z == Zone.EXTERIOR and next_z == Zone.STORAGE:
			path.append(Vector3(-10.5, 0.0, -3.5))
			path.append(Vector3(-8.2, 0.0, -3.5))
			path.append(Vector3(-5.5, 0.0, -3.5))
			cur_pos = Vector3(-5.5, 0.0, -3.5)

		current_z = next_z

	# Destino final ajustado dentro da zona alvo
	if to_zone == Zone.KITCHEN and dest.z < -5.5:
		path.append(Vector3(dest.x, 0.0, -3.2))
	path.append(dest)

	return path

func _handle_movement(delta: float, on_reached_callback: Callable) -> void:
	if waypoints.is_empty():
		waypoints = _build_path_to(target_position, _using_alt_route)
		if waypoints.is_empty():
			waypoints.append(target_position)

	var next_wp = waypoints[0]
	var to_wp = next_wp - global_position
	to_wp.y = 0.0

	var is_final = (waypoints.size() == 1)
	var threshold = 0.55 if is_final else 0.45

	if to_wp.length() <= threshold:
		waypoints.remove_at(0)
		if waypoints.is_empty():
			velocity = Vector3.ZERO
			_stuck_timer = 0.0
			_stuck_retries = 0
			_using_alt_route = false
			on_reached_callback.call()
			return
		next_wp = waypoints[0]
		to_wp = next_wp - global_position
		to_wp.y = 0.0

	# Sistema de detecção e recuperação de travamento (stuck recovery)
	if global_position.distance_to(_last_stuck_pos) < 0.035:
		_stuck_timer += delta
		if _stuck_timer > 0.40:
			_stuck_timer = 0.0
			_stuck_retries += 1

			if _stuck_retries == 1:
				print("[EMPLOYEE] %s: Caminho bloqueado — recalculando..." % employee_name)
				_using_alt_route = not _using_alt_route
				waypoints = _build_path_to(target_position, _using_alt_route)
				print("[EMPLOYEE] %s: Rota alternativa encontrada" % employee_name)
			elif _stuck_retries == 2:
				if waypoints.size() > 1:
					waypoints.remove_at(0)
				else:
					velocity = Vector3.ZERO
					waypoints.clear()
					_stuck_retries = 0
					_using_alt_route = false
					on_reached_callback.call()
					return
			else:
				print("[EMPLOYEE] %s: Destino inacessível após múltiplas tentativas. Liberando tarefa." % employee_name)
				if current_task:
					var task_mgr = _get_task_manager()
					if task_mgr:
						task_mgr.release_task(current_task)
					current_task = null
				_stuck_retries = 0
				_using_alt_route = false
				state = State.IDLE_WAITING
				return
	else:
		_stuck_timer = 0.0
		_last_stuck_pos = global_position

	var dir = to_wp.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed

	if dir.length_squared() > 0.01:
		var look_target = global_position + Vector3(dir.x, 0.0, dir.z)
		look_at(look_target, Vector3.UP)

	move_and_slide()

func _get_task_manager() -> EmployeeTaskManager:
	var mgr = EmployeeTaskManager.get_instance()
	if not mgr and is_inside_tree() and get_tree().root:
		mgr = get_tree().root.find_child("EmployeeTaskManager", true, false)
	return mgr

## Busca a tarefa mais prioritária no EmployeeTaskManager
func _check_for_tasks() -> void:
	var task_mgr = _get_task_manager()
	if not task_mgr:
		return

	# Se já possui uma tarefa ativa em andamento, mantém o foco nela
	if current_task != null and not current_task.is_completed:
		return

	# Se a bucha está suja, a prioridade é ir à pia lavar
	if is_sponge_dirty:
		_head_to_sink_to_wash()
		return

	var best_task = task_mgr.get_best_available_task(self, true)
	if best_task:
		if task_mgr.claim_task(best_task, self):
			_start_task(best_task)
	else:
		# Se não está no ponto de espera do salão, caminha até lá
		if global_position.distance_to(rest_position) > 1.2 and state != State.RETURNING_TO_REST:
			target_position = rest_position
			_using_alt_route = false
			waypoints = _build_path_to(target_position)
			state = State.RETURNING_TO_REST
			_update_sponge_visibility(false)

func _start_task(task: EmployeeTask) -> void:
	current_task = task
	_stuck_retries = 0
	_using_alt_route = false

	var target = task.target_node
	if target is RestaurantTable:
		var tbl = target as RestaurantTable
		print("[EMPLOYEE] %s: Indo para Mesa #%d" % [employee_name, tbl.table_id])
	elif task.task_type == EmployeeTask.TaskType.SERVE_DRIVETHRU:
		print("[EMPLOYEE] %s: Indo para janela do Drive-Thru" % employee_name)
	else:
		print("[EMPLOYEE] %s: Indo para local da tarefa" % employee_name)

	print("[EMPLOYEE] %s: Caminho encontrado" % employee_name)

	var is_cleaning_task = task.task_type in [
		EmployeeTask.TaskType.CLEAN_TABLE,
		EmployeeTask.TaskType.CLEAN_PUDDLE,
		EmployeeTask.TaskType.CLEAN_FLOOR_SPOT,
		EmployeeTask.TaskType.CLEAN_STATION
	]

	if is_cleaning_task:
		_update_sponge_visibility(true)
		if is_sponge_dirty:
			print("[EMPLOYEE] %s: Bucha suja detectada antes da limpeza! Redirecionando para a pia..." % employee_name)
			_head_to_sink_to_wash()
			return

	target_position = task.target_position
	waypoints = _build_path_to(target_position)
	state = State.MOVING_TO_TASK

func _head_to_sink_to_wash() -> void:
	var sink = _get_sink()
	if sink:
		target_position = sink.global_position + Vector3(0.0, 0.0, 0.9)
		_using_alt_route = false
		waypoints = _build_path_to(target_position)
		state = State.MOVING_TO_SINK
		_update_sponge_visibility(true)
		print("[EMPLOYEE] %s: Caminhando até a pia industrial para lavar a bucha..." % employee_name)
	else:
		set_sponge_dirty(false)
		state = State.IDLE_WAITING

func _get_sink() -> CommercialSink:
	if is_inside_tree() and get_tree().root:
		return get_tree().root.find_child("CommercialSink", true, false) as CommercialSink
	return null

func _on_reached_sink() -> void:
	var sink = _get_sink()
	if sink:
		var look_target = Vector3(sink.global_position.x, global_position.y, sink.global_position.z)
		if global_position.distance_squared_to(look_target) > 0.01:
			look_at(look_target, Vector3.UP)
		sink.set_water_flow(true)

	if action_audio:
		action_audio.stream = SoundSynthesizer.get_stream("sink_running_water")
		action_audio.play()

	state = State.WASHING_SPONGE
	task_timer = 0.0
	print("[EMPLOYEE] %s: Lavando a bucha com água corrente na pia..." % employee_name)

func _finish_washing_sponge() -> void:
	var sink = _get_sink()
	if sink:
		sink.set_water_flow(false)

	if action_audio and action_audio.playing:
		action_audio.stop()

	set_sponge_dirty(false)
	print("[EMPLOYEE] %s: Bucha 100%% limpa e higienizada!" % employee_name)

	# Se havia uma tarefa reservada aguardando, retoma-a imediatamente
	if current_task and is_instance_valid(current_task.target_node) and not current_task.is_completed:
		target_position = current_task.target_position
		_using_alt_route = false
		waypoints = _build_path_to(target_position)
		state = State.MOVING_TO_TASK
	else:
		state = State.IDLE_WAITING
		_check_for_tasks()

func _on_reached_task_target() -> void:
	if not current_task or not is_instance_valid(current_task.target_node):
		state = State.IDLE_WAITING
		_check_for_tasks()
		return

	var target = current_task.target_node
	var tpos = target.global_position
	var look_target = Vector3(tpos.x, global_position.y, tpos.z)
	if global_position.distance_squared_to(look_target) > 0.01:
		look_at(look_target, Vector3.UP)

	if target is RestaurantTable:
		var tbl = target as RestaurantTable
		print("[EMPLOYEE] %s: Funcionário chegou à Mesa #%d" % [employee_name, tbl.table_id])
	elif current_task.task_type == EmployeeTask.TaskType.SERVE_DRIVETHRU:
		print("[EMPLOYEE] %s: Funcionário chegou ao Drive-Thru" % employee_name)

	task_timer = 0.0

	match current_task.task_type:
		EmployeeTask.TaskType.CLEAN_TABLE, EmployeeTask.TaskType.CLEAN_PUDDLE, EmployeeTask.TaskType.CLEAN_FLOOR_SPOT, EmployeeTask.TaskType.CLEAN_STATION:
			state = State.CLEANING_SURFACE
			_update_sponge_visibility(true)
			if action_audio:
				action_audio.stream = SoundSynthesizer.get_stream("sponge_scrub_loop")
				action_audio.play()
			print("[EMPLOYEE] %s: Esfregando e higienizando superfície..." % employee_name)

		EmployeeTask.TaskType.SERVE_CUSTOMER:
			state = State.SERVING_CUSTOMER
			_update_sponge_visibility(false)
			print("[EMPLOYEE] %s: Anotando pedido do cliente na mesa..." % employee_name)

		EmployeeTask.TaskType.SERVE_DRIVETHRU:
			state = State.SERVING_DRIVETHRU
			_update_sponge_visibility(false)
			print("[EMPLOYEE] %s: Atendendo veículo na janela do Drive-Thru..." % employee_name)

		EmployeeTask.TaskType.OPERATE_CASHIER:
			state = State.OPERATING_CASHIER
			_update_sponge_visibility(false)
			print("[EMPLOYEE] %s: Processando pagamento no caixa..." % employee_name)

		_:
			state = State.IDLE_WAITING
			_check_for_tasks()

func _finish_cleaning_surface() -> void:
	if action_audio and action_audio.playing:
		action_audio.stop()

	if current_task and is_instance_valid(current_task.target_node):
		var target = current_task.target_node

		# 1. Limpeza de Mesa
		if target is RestaurantTable:
			var table = target as RestaurantTable
			table.clean_table(self)
			print("[EMPLOYEE] %s: Mesa #%d limpa e liberada com sucesso!" % [employee_name, table.table_id])

		# 2. Limpeza de Poça d'água
		elif target.is_in_group("floor_puddles") or target.name.begins_with("FloorPuddle"):
			target.queue_free()
			print("[EMPLOYEE] %s: Poça d'água seca e removida do chão!" % employee_name)

		# 3. Limpeza de Mancha no chão
		elif target.is_in_group("floor_dirt_spots") or target.name.begins_with("FloorDirt"):
			target.queue_free()
			print("[EMPLOYEE] %s: Mancha no chão removida e higienizada!" % employee_name)

		# 4. Limpeza de Bancada/Grelha/Fritadeira
		elif target.has_method("clean_station"):
			target.clean_station(self)
			print("[EMPLOYEE] %s: Bancada/Estação higienizada!" % employee_name)
		elif target.has_method("clean_grill"):
			target.clean_grill(self)
			print("[EMPLOYEE] %s: Grelha higienizada!" % employee_name)

		tasks_completed += 1
		set_sponge_dirty(true)

		var task_mgr = _get_task_manager()
		if task_mgr:
			task_mgr.complete_task(current_task)

	current_task = null
	print("[EMPLOYEE] %s: Bucha ficou suja! Indo imediatamente à pia lavar..." % employee_name)
	_head_to_sink_to_wash()

func _finish_serving_customer() -> void:
	if current_task and is_instance_valid(current_task.target_node):
		var table = current_task.target_node as RestaurantTable
		if table:
			table.interact(self) # Anota o pedido do cliente

		tasks_completed += 1
		var task_mgr = _get_task_manager()
		if task_mgr:
			task_mgr.complete_task(current_task)
		print("[EMPLOYEE] %s: Atendimento de mesa finalizado com sucesso!" % employee_name)

	current_task = null
	state = State.IDLE_WAITING
	_check_for_tasks()

func _finish_serving_drivethru() -> void:
	if current_task and is_instance_valid(current_task.target_node):
		var station = current_task.target_node
		if station and station.has_method("interact"):
			station.interact(self)

		tasks_completed += 1
		var task_mgr = _get_task_manager()
		if task_mgr:
			task_mgr.complete_task(current_task)
		print("[EMPLOYEE] %s: Atendimento Drive-Thru concluído com sucesso!" % employee_name)

	current_task = null
	state = State.IDLE_WAITING
	_check_for_tasks()

func _finish_operating_cashier() -> void:
	if current_task and is_instance_valid(current_task.target_node):
		var reg = current_task.target_node as CashRegister
		if reg:
			reg.interact(self) # Processa pagamento do cliente da fila

		tasks_completed += 1
		var task_mgr = _get_task_manager()
		if task_mgr:
			task_mgr.complete_task(current_task)
		print("[EMPLOYEE] %s: Checkout de cliente finalizado no caixa!" % employee_name)

	current_task = null
	state = State.IDLE_WAITING
	_check_for_tasks()

func _on_reached_rest_area() -> void:
	velocity = Vector3.ZERO
	# Vira o funcionário para o centro do salão / mesas (direção Norte -Z)
	var look_target = global_position + Vector3(0.0, 0.0, -1.0)
	look_at(look_target, Vector3.UP)
	state = State.IDLE_WAITING
	_update_sponge_visibility(false)
	print("[EMPLOYEE] %s: Aguardando no ponto de espera do salão." % employee_name)
