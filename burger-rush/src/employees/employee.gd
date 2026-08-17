class_name Employee
extends CharacterBody3D

# =============================================================================
# BURGER RUSH - FUNCIONÁRIO NPC AUTÔNOMO DE OPERAÇÃO
#
# Personagem físico que navega pelo restaurante, executa tarefas baseadas em
# prioridade (atendimento de salão, drive-thru, limpeza de mesas e poças, caixa),
# gerencia a bucha física com lavagem na pia industrial, e aguarda na área de descanso.
#
# Sem textos flutuantes sobre a cabeça. Uniforme amarelo com detalhes vermelhos.
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
	IDLE_WAITING,       # Descansando na área reservada / aguardando tarefas
	MOVING_TO_TASK,     # Caminhando até o local da tarefa
	MOVING_TO_SINK,     # Caminhando até a pia para lavar a bucha suja
	WASHING_SPONGE,     # Lavando a bucha na pia industrial
	CLEANING_SURFACE,   # Esfregando e limpando mesa/poça/mancha
	SERVING_CUSTOMER,   # Atendendo cliente na mesa
	SERVING_DRIVETHRU,  # Atendendo janela do Drive-Thru
	OPERATING_CASHIER,  # Operando o caixa
	RETURNING_TO_REST   # Retornando para a área de descanso
}

@export var move_speed: float = 2.8
@export var employee_id: int = 1
@export var employee_name: String = "Funcionário"
@export var role: Role = Role.GENERAL
@export var weekly_salary: float = 250.0

func set_role(new_role: Role) -> void:
	role = new_role

func get_role_name() -> String:
	match role:
		Role.GENERAL:
			return "🛠️ Operacional Geral"
		Role.GRILL:
			return "🍳 Chapa"
		Role.ATTENDANT:
			return "📝 Atendimento"
		Role.CLEANER:
			return "🧹 Limpeza"
		Role.UNASSIGNED:
			return "⚪ Sem Função"
	return "Funcionário"

@onready var animator: HumanoidAnimator = $HumanoidAnimator
@onready var hold_position: Node3D = $HoldPosition
@onready var sponge_visual: Node3D = get_node_or_null("Model/ArmRight/HandRight/EmployeeSponge")
@onready var sponge_dirt_mesh: MeshInstance3D = get_node_or_null("Model/ArmRight/HandRight/EmployeeSponge/SpongeDirtLayer")
@onready var action_audio: AudioStreamPlayer3D = null

var state: State = State.IDLE_WAITING
var current_task: EmployeeTask = null
var target_position: Vector3 = Vector3.ZERO
var rest_position: Vector3 = Vector3(-4.5, 0.0, -3.5)

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

func set_sponge_dirty(dirty: bool) -> void:
	is_sponge_dirty = dirty
	if sponge_dirt_mesh:
		sponge_dirt_mesh.visible = dirty

func _update_sponge_visibility(visible_state: bool) -> void:
	if sponge_visual:
		sponge_visual.visible = visible_state

func _physics_process(delta: float) -> void:
	if animator:
		var is_working = state in [State.WASHING_SPONGE, State.CLEANING_SURFACE, State.SERVING_CUSTOMER, State.OPERATING_CASHIER]
		animator.update_animation(delta, velocity, false, is_working, sponge_visual != null and sponge_visual.visible)

	match state:
		State.IDLE_WAITING:
			search_cooldown -= delta
			if search_cooldown <= 0.0:
				search_cooldown = 0.45
				_check_for_tasks()

		State.MOVING_TO_TASK:
			_handle_movement(delta, _on_reached_task_target)

		State.MOVING_TO_SINK:
			_handle_movement(delta, _on_reached_sink)

		State.RETURNING_TO_REST:
			_handle_movement(delta, _on_reached_rest_area)

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

func _handle_movement(delta: float, on_reached_callback: Callable) -> void:
	var to_target = target_position - global_position
	to_target.y = 0.0

	if to_target.length() <= 0.6:
		velocity = Vector3.ZERO
		on_reached_callback.call()
	else:
		var dir = to_target.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed

		if dir.length_squared() > 0.01:
			var look_target = global_position + Vector3(dir.x, 0.0, dir.z)
			look_at(look_target, Vector3.UP)

		move_and_slide()

## Busca a tarefa mais prioritária no EmployeeTaskManager
func _check_for_tasks() -> void:
	var task_mgr = EmployeeTaskManager.get_instance()
	if not task_mgr and is_inside_tree() and get_tree().root:
		task_mgr = get_tree().root.find_child("EmployeeTaskManager", true, false)

	if not task_mgr:
		return

	var best_task = task_mgr.get_best_available_task(self, not is_sponge_dirty)
	if best_task:
		if task_mgr.claim_task(best_task, self):
			_start_task(best_task)
	else:
		# Se a bucha está suja e não há outras tarefas, vai lavar na pia
		if is_sponge_dirty:
			_head_to_sink_to_wash()
		else:
			# Se não está na área de descanso, caminha até lá
			if global_position.distance_to(rest_position) > 1.2 and state != State.RETURNING_TO_REST:
				target_position = rest_position
				state = State.RETURNING_TO_REST
				_update_sponge_visibility(false)

func _start_task(task: EmployeeTask) -> void:
	current_task = task

	# Se a tarefa exige bucha e ela está suja, desvia primeiro para a pia
	var is_cleaning_task = task.task_type in [
		EmployeeTask.TaskType.CLEAN_TABLE,
		EmployeeTask.TaskType.CLEAN_PUDDLE,
		EmployeeTask.TaskType.CLEAN_FLOOR_SPOT,
		EmployeeTask.TaskType.CLEAN_STATION
	]

	if is_cleaning_task:
		_update_sponge_visibility(true)
		if is_sponge_dirty:
			_head_to_sink_to_wash()
			return

	target_position = task.target_position
	state = State.MOVING_TO_TASK

func _head_to_sink_to_wash() -> void:
	var sink = _get_sink()
	if sink:
		target_position = sink.global_position + Vector3(0.0, 0.0, 0.8) # Posição em frente à pia
		state = State.MOVING_TO_SINK
		_update_sponge_visibility(true)
	else:
		# Se não encontrou a pia, limpa estado
		set_sponge_dirty(false)
		state = State.IDLE_WAITING

func _get_sink() -> CommercialSink:
	if is_inside_tree() and get_tree().root:
		return get_tree().root.find_child("CommercialSink", true, false) as CommercialSink
	return null

func _on_reached_sink() -> void:
	var sink = _get_sink()
	if sink:
		look_at(Vector3(sink.global_position.x, global_position.y, sink.global_position.z), Vector3.UP)
		sink.set_water_flow(true)

	if action_audio:
		action_audio.stream = SoundSynthesizer.get_stream("sink_running_water")
		action_audio.play()

	state = State.WASHING_SPONGE
	task_timer = 0.0

func _finish_washing_sponge() -> void:
	var sink = _get_sink()
	if sink:
		sink.set_water_flow(false)

	if action_audio and action_audio.playing:
		action_audio.stop()

	set_sponge_dirty(false)

	# Se havia uma tarefa reservada esperando, retoma-a
	if current_task and is_instance_valid(current_task.target_node) and not current_task.is_completed:
		target_position = current_task.target_position
		state = State.MOVING_TO_TASK
	else:
		state = State.IDLE_WAITING

func _on_reached_task_target() -> void:
	if not current_task or not is_instance_valid(current_task.target_node):
		state = State.IDLE_WAITING
		return

	# Vira o funcionário na direção do alvo
	var tpos = current_task.target_node.global_position
	look_at(Vector3(tpos.x, global_position.y, tpos.z), Vector3.UP)

	task_timer = 0.0

	match current_task.task_type:
		EmployeeTask.TaskType.CLEAN_TABLE, EmployeeTask.TaskType.CLEAN_PUDDLE, EmployeeTask.TaskType.CLEAN_FLOOR_SPOT, EmployeeTask.TaskType.CLEAN_STATION:
			state = State.CLEANING_SURFACE
			_update_sponge_visibility(true)
			if action_audio:
				action_audio.stream = SoundSynthesizer.get_stream("sponge_scrub_loop")
				action_audio.play()

		EmployeeTask.TaskType.SERVE_CUSTOMER:
			state = State.SERVING_CUSTOMER
			_update_sponge_visibility(false)

		EmployeeTask.TaskType.SERVE_DRIVETHRU:
			state = State.SERVING_DRIVETHRU
			_update_sponge_visibility(false)

		EmployeeTask.TaskType.OPERATE_CASHIER:
			state = State.OPERATING_CASHIER
			_update_sponge_visibility(false)

		_:
			state = State.IDLE_WAITING

func _finish_cleaning_surface() -> void:
	if action_audio and action_audio.playing:
		action_audio.stop()

	if current_task and is_instance_valid(current_task.target_node):
		var target = current_task.target_node

		# 1. Limpeza de Mesa
		if target is RestaurantTable:
			var table = target as RestaurantTable
			table.clean_table(self)

		# 2. Limpeza de Poça d'água
		elif target.is_in_group("floor_puddles") or target.name.begins_with("FloorPuddle"):
			target.queue_free()

		# 3. Limpeza de Mancha no chão
		elif target.is_in_group("floor_dirt_spots") or target.name.begins_with("FloorDirt"):
			target.queue_free()

		# 4. Limpeza de Bancada/Grelha/Fritadeira
		elif target.has_method("clean_station"):
			target.clean_station(self)
		elif target.has_method("clean_grill"):
			target.clean_grill(self)

		tasks_completed += 1
		set_sponge_dirty(true)

		var task_mgr = EmployeeTaskManager.get_instance()
		if task_mgr:
			task_mgr.complete_task(current_task)

	current_task = null
	# Bucha ficou suja -> vai automaticamente à pia lavar
	_head_to_sink_to_wash()

func _finish_serving_customer() -> void:
	if current_task and is_instance_valid(current_task.target_node):
		var table = current_task.target_node as RestaurantTable
		if table:
			table.interact(self) # Anota o pedido do cliente

		tasks_completed += 1
		var task_mgr = EmployeeTaskManager.get_instance()
		if task_mgr:
			task_mgr.complete_task(current_task)

	current_task = null
	state = State.IDLE_WAITING

func _finish_serving_drivethru() -> void:
	if current_task and is_instance_valid(current_task.target_node):
		var station = current_task.target_node
		if station and station.has_method("interact"):
			station.interact(self)

		tasks_completed += 1
		var task_mgr = EmployeeTaskManager.get_instance()
		if task_mgr:
			task_mgr.complete_task(current_task)

	current_task = null
	state = State.IDLE_WAITING

func _finish_operating_cashier() -> void:
	if current_task and is_instance_valid(current_task.target_node):
		var reg = current_task.target_node as CashRegister
		if reg:
			reg.interact(self) # Processa pagamento do cliente da fila

		tasks_completed += 1
		var task_mgr = EmployeeTaskManager.get_instance()
		if task_mgr:
			task_mgr.complete_task(current_task)

	current_task = null
	state = State.IDLE_WAITING

func _on_reached_rest_area() -> void:
	velocity = Vector3.ZERO
	# Vira o funcionário para a frente do restaurante / balcão
	look_at(global_position + Vector3(1.0, 0.0, 0.0), Vector3.UP)
	state = State.IDLE_WAITING
	_update_sponge_visibility(false)
