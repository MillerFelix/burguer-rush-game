class_name Employee
extends CharacterBody3D

const HumanoidAnimator = preload("res://src/characters/humanoid_animator.gd")
const CharacterAppearance = preload("res://src/characters/character_appearance.gd")
const CashRegister = preload("res://src/stations/cash_register.gd")

enum Role {
	UNASSIGNED,
	GRILL,
	ATTENDANT,
	CLEANER
}

enum State {
	IDLE,
	WALKING,
	WORKING,
	WAITING,
	OFF_DUTY
}

@export var move_speed: float = 3.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var label_3d: Label3D = $Label3D
@onready var hold_position: Node3D = $HoldPosition
@onready var animator: HumanoidAnimator = $HumanoidAnimator

var employee_id: int = 1
var employee_name: String = "Funcionário"
var role: Role = Role.UNASSIGNED
var state: State = State.OFF_DUTY
var weekly_salary: float = 250.0
var tasks_completed_this_week: int = 0

var target_position: Vector3 = Vector3.ZERO
var current_target_node: Node3D = null
var current_task: EmployeeTask = null
var held_item: Node3D = null

var work_timer: float = 0.0
var search_task_timer: float = 0.0

func _ready() -> void:
	if animator:
		animator.setup($Model)
	CharacterAppearance.apply_employee_appearance(self, employee_name)
	_update_visual_label()

func set_role(new_role: Role) -> void:
	role = new_role
	current_task = null
	state = State.IDLE
	_update_visual_label()

func get_role_name() -> String:
	match role:
		Role.GRILL:
			return "🍳 Chapa"
		Role.ATTENDANT:
			return "📝 Atendimento"
		Role.CLEANER:
			return "🧹 Limpeza"
		Role.UNASSIGNED:
			return "⚪ Sem Função"
	return "Indefinido"

func pick_up(item: Node3D) -> void:
	if held_item != null:
		return
	held_item = item
	var prev_parent = item.get_parent()
	if prev_parent:
		prev_parent.remove_child(item)

	if hold_position:
		hold_position.add_child(item)
		item.position = Vector3.ZERO
		item.rotation = Vector3.ZERO
	if item.has_method("on_picked_up"):
		item.on_picked_up()

func take_held_item() -> Node3D:
	if not held_item:
		return null
	var it = held_item
	held_item = null
	if hold_position and it.get_parent() == hold_position:
		hold_position.remove_child(it)
	return it

func _physics_process(delta: float) -> void:
	if animator:
		animator.update_animation(delta, velocity, false, false, held_item != null)

	var clock = GameClock.get_instance()
	if clock and clock.state != GameClock.State.OPEN:
		state = State.OFF_DUTY
		_update_visual_label()
		return

	if state == State.OFF_DUTY:
		state = State.IDLE

	match state:
		State.IDLE:
			search_task_timer += delta
			if search_task_timer >= 0.4:
				search_task_timer = 0.0
				_find_and_assign_task()

		State.WALKING:
			var to_target = target_position - global_position
			to_target.y = 0.0

			if to_target.length() <= 0.5:
				velocity = Vector3.ZERO
				state = State.WORKING
				work_timer = 0.0
				_update_visual_label()
			else:
				var dir = to_target.normalized()
				velocity.x = dir.x * move_speed
				velocity.z = dir.z * move_speed
				if dir.length_squared() > 0.01:
					look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)
				move_and_slide()

		State.WORKING:
			work_timer += delta
			_execute_work(delta)

func _find_and_assign_task() -> void:
	if role == Role.UNASSIGNED:
		return

	var main_scene: Node = get_parent()
	if not main_scene:
		main_scene = get_tree().current_scene if get_tree() else null
	if not main_scene:
		return

	match role:
		Role.CLEANER:
			var table_mgr = TableManager.get_instance()
			var tables = table_mgr.tables if table_mgr else []
			if tables.is_empty():
				tables = [main_scene.get_node_or_null("Table1"), main_scene.get_node_or_null("Table2"), main_scene.get_node_or_null("Table3")]

			for table_node in tables:
				var t = table_node as RestaurantTable
				if t and is_instance_valid(t) and t.table_state == RestaurantTable.TableState.DIRTY:
					current_target_node = t
					target_position = t.global_position + Vector3(0, 0, 0.8)
					state = State.WALKING
					_update_visual_label()
					return

		Role.ATTENDANT:
			var table_mgr = TableManager.get_instance()
			var tables = table_mgr.tables if table_mgr else []
			if tables.is_empty():
				tables = [main_scene.get_node_or_null("Table1"), main_scene.get_node_or_null("Table2"), main_scene.get_node_or_null("Table3")]

			for table_node in tables:
				var t = table_node as RestaurantTable
				if t and is_instance_valid(t) and t.seated_customer and is_instance_valid(t.seated_customer):
					var c = t.seated_customer
					if c.state == Customer.State.SEATED_WAITING_TO_ORDER:
						current_target_node = t
						target_position = t.global_position + Vector3(0, 0, 0.8)
						state = State.WALKING
						_update_visual_label()
						return

			var register = main_scene.get_node_or_null("CashRegister") as CashRegister
			if register and register.can_checkout():
				current_target_node = register
				target_position = register.global_position + Vector3(0, 0, -0.6)
				state = State.WALKING
				_update_visual_label()
				return

		Role.GRILL:
			var grill = main_scene.get_node_or_null("Grill") as Grill
			var prep = main_scene.get_node_or_null("PrepTable") as PrepTable
			var patty_disp = main_scene.get_node_or_null("PattyDispenser") as IngredientDispenser

			if grill and is_instance_valid(grill):
				if grill.current_patty != null and grill.current_patty.state == Patty.State.COOKED:
					current_target_node = grill
					target_position = grill.global_position + Vector3(0, 0, 0.8)
					state = State.WALKING
					_update_visual_label()
					return
				elif grill.current_patty == null and held_item != null:
					current_target_node = grill
					target_position = grill.global_position + Vector3(0, 0, 0.8)
					state = State.WALKING
					_update_visual_label()
					return
				elif grill.current_patty == null and held_item == null and patty_disp:
					current_target_node = patty_disp
					target_position = patty_disp.global_position + Vector3(0, 0, 0.8)
					state = State.WALKING
					_update_visual_label()
					return

func _execute_work(delta: float) -> void:
	if not current_target_node or not is_instance_valid(current_target_node):
		state = State.IDLE
		_update_visual_label()
		return

	match role:
		Role.CLEANER:
			var table = current_target_node as RestaurantTable
			if table and table.table_state == RestaurantTable.TableState.DIRTY:
				if work_timer >= 1.2:
					table.clean_table(self)
					tasks_completed_this_week += 1
					state = State.IDLE
					current_target_node = null
					_update_visual_label()
			else:
				state = State.IDLE
				current_target_node = null

		Role.ATTENDANT:
			if current_target_node is RestaurantTable:
				var table = current_target_node as RestaurantTable
				if table and table.seated_customer and is_instance_valid(table.seated_customer):
					var c = table.seated_customer
					if c.state == Customer.State.SEATED_WAITING_TO_ORDER:
						if work_timer >= 0.8:
							table.interact(self) # Anota o pedido
							tasks_completed_this_week += 1
							state = State.IDLE
							current_target_node = null
							_update_visual_label()
					else:
						state = State.IDLE
						current_target_node = null
				else:
					state = State.IDLE
					current_target_node = null
			elif current_target_node is CashRegister:
				var register = current_target_node as CashRegister
				if register and register.can_checkout():
					if work_timer >= 0.8:
						register.interact(self) # Processa pagamento no caixa
						tasks_completed_this_week += 1
						state = State.IDLE
						current_target_node = null
						_update_visual_label()
				else:
					state = State.IDLE
					current_target_node = null
			else:
				state = State.IDLE
				current_target_node = null

		Role.GRILL:
			var main_scene: Node = get_parent() if get_parent() else (get_tree().current_scene if get_tree() else null)
			var grill = main_scene.get_node_or_null("Grill") as Grill if main_scene else null
			var prep = main_scene.get_node_or_null("PrepTable") as PrepTable if main_scene else null

			# Se pegou carne no dispenser, leva até a chapa
			if current_target_node is IngredientDispenser and held_item != null and grill:
				current_target_node = grill
				target_position = grill.global_position + Vector3(0, 0, 0.8)
				state = State.WALKING
				_update_visual_label()
				return
			elif current_target_node is IngredientDispenser and held_item == null:
				var disp = current_target_node as IngredientDispenser
				disp.interact(self)
				state = State.IDLE
				return

			# Se está na chapa com carne na mão, coloca na chapa
			if current_target_node == grill and held_item != null:
				grill.interact(self)
				state = State.IDLE
				current_target_node = null
				return

			# Se está na chapa retirando carne pronta, leva para a bancada
			if current_target_node == grill and held_item == null:
				if grill.current_patty != null and grill.current_patty.state == Patty.State.COOKED:
					grill.interact(self)
					if prep:
						current_target_node = prep
						target_position = prep.global_position + Vector3(0, 0, 0.8)
						state = State.WALKING
						_update_visual_label()
						return
				state = State.IDLE
				current_target_node = null
				return

			# Se está na bancada com carne pronta, coloca na bancada
			if current_target_node == prep and held_item != null:
				prep.interact(self)
				tasks_completed_this_week += 1
				state = State.IDLE
				current_target_node = null
				_update_visual_label()
				return

func _update_visual_label() -> void:
	if not label_3d:
		return

	var role_str = get_role_name()
	var state_str = "Livre"
	match state:
		State.IDLE:
			state_str = "🟢 Aguardando Tarefa"
		State.WALKING:
			state_str = "🚶 Deslocando-se"
		State.WORKING:
			state_str = "⏳ Trabalhando..."
		State.OFF_DUTY:
			state_str = "💤 Fora de Turno"

	label_3d.text = "👤 %s\n%s\n%s" % [employee_name, role_str, state_str]
