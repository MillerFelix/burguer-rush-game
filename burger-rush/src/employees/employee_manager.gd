class_name EmployeeManager
extends Node

# =============================================================================
# BURGER RUSH - GERENCIADOR DE FUNCIONÁRIOS
#
# Controla os funcionários ativos no restaurante, instancia o funcionário operacional
# inicial e prepara a infraestrutura para futura contratação e folha salarial via PC.
# =============================================================================

signal employee_hired(employee: Employee)
signal employee_fired(employee_id: int)

static var instance = null

const Employee = preload("res://src/employees/employee.gd")
var employee_scene: PackedScene = null
var employees: Array[Employee] = []
var next_id: int = 1

@export var max_employees: int = 1
@export var hiring_cost: float = 150.0
@export var daily_salary: float = 50.0

var names_pool: Array[String] = ["Carlos", "João", "Pedro", "Ana", "Mariana", "Lucas", "Beatriz", "Gabriel"]

func _init() -> void:
	instance = self

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

static func get_instance():
	if instance and is_instance_valid(instance):
		return instance
	return null

@export var auto_spawn_initial_employee: bool = false

func _ready() -> void:
	if not employee_scene:
		employee_scene = load("res://src/employees/employee.tscn")
	# O funcionário está desabilitado no início da partida.
	# A contratação é realizada exclusivamente via PC pelo jogador.
	if auto_spawn_initial_employee:
		call_deferred("_spawn_initial_employee")

func _spawn_initial_employee() -> void:
	if not employees.is_empty():
		return

	var emp = employee_scene.instantiate() as Employee
	emp.employee_id = next_id
	next_id += 1
	emp.employee_name = "Carlos"
	emp.weekly_salary = daily_salary * 7.0
	emp.daily_salary = daily_salary
	emp.hired_day = 1
	emp.rest_position = Vector3(2.4, 0.0, 7.5)

	var parent_node: Node = get_parent() if get_parent() else (get_tree().current_scene if get_tree() else null)
	if parent_node:
		parent_node.add_child(emp)
		emp.global_position = emp.rest_position

	employees.append(emp)
	employee_hired.emit(emp)

func get_next_name() -> String:
	var idx = (next_id - 1) % names_pool.size()
	return names_pool[idx]

## Retorna se o restaurante já possui o funcionário contratado
func has_hired_employee() -> bool:
	return not employees.is_empty()

## Retorna a instância do funcionário contratado (único)
func get_hired_employee() -> Employee:
	if not employees.is_empty() and is_instance_valid(employees[0]):
		return employees[0]
	return null

func hire_employee(emp_name: String = "", initial_role: Employee.Role = Employee.Role.GENERAL) -> Dictionary:
	if employees.size() >= max_employees:
		return {
			"success": false,
			"message": "O restaurante já possui o limite máximo de 1 funcionário contratado."
		}

	var economy = EconomyManager.get_instance()
	if not economy and is_inside_tree() and get_tree() and get_tree().root:
		economy = get_tree().root.find_child("EconomyManager", true, false)

	if not economy or economy.get_money() < hiring_cost:
		return {
			"success": false,
			"message": "Saldo insuficiente para contratação (R$ %.2f necessário)." % hiring_cost
		}

	if not economy.spend_money(hiring_cost, "Contratação de Funcionário"):
		return {
			"success": false,
			"message": "Falha na transação financeira ao descontar taxa de contratação."
		}

	var current_day = 1
	var clock = null
	if is_inside_tree() and get_tree() and get_tree().root:
		clock = get_tree().root.find_child("GameClock", true, false)
	if clock:
		current_day = clock.day_number

	var name_str = emp_name if emp_name != "" else get_next_name()
	var emp = employee_scene.instantiate() as Employee
	emp.employee_id = next_id
	next_id += 1
	emp.employee_name = name_str
	emp.role = initial_role
	emp.daily_salary = daily_salary
	emp.weekly_salary = daily_salary * 7.0
	emp.hired_day = current_day
	emp.rest_position = Vector3(2.4, 0.0, 7.5)

	var parent_node: Node = get_parent() if get_parent() else (get_tree().current_scene if (get_tree() and get_tree().current_scene) else null)
	if not parent_node and is_inside_tree() and get_tree() and get_tree().root:
		parent_node = get_tree().root
	if not parent_node:
		var main_loop = Engine.get_main_loop() as SceneTree
		if main_loop and main_loop.root:
			parent_node = main_loop.root

	if parent_node:
		parent_node.add_child(emp)
		# Faz o funcionário chegar de fora (calçada externa) caminhando até seu posto
		if emp.is_inside_tree():
			emp.global_position = Vector3(2.4, 0.0, 13.5)
		else:
			emp.position = Vector3(2.4, 0.0, 13.5)
		emp.state = Employee.State.RETURNING_TO_REST
		emp.target_position = emp.rest_position
		if emp.has_method("_build_path_to"):
			emp.waypoints = emp._build_path_to(emp.rest_position)

	employees.append(emp)
	employee_hired.emit(emp)

	# Atualiza o FinanceManager se estiver presente na árvore
	var fin = FinanceManager.get_instance()
	if not fin and is_inside_tree() and get_tree() and get_tree().root:
		fin = get_tree().root.find_child("FinanceManager", true, false)
	if fin and fin.has_method("_ensure_daily_bills"):
		fin._ensure_daily_bills()

	return {
		"success": true,
		"message": "Funcionário %s contratado com sucesso!" % name_str,
		"employee": emp
	}

func fire_employee(emp_id: int) -> bool:
	for i in range(employees.size()):
		var emp = employees[i]
		if emp.employee_id == emp_id:
			employees.remove_at(i)
			employee_fired.emit(emp_id)
			if is_instance_valid(emp):
				emp.queue_free()

			var fin = FinanceManager.get_instance()
			if not fin and is_inside_tree() and get_tree() and get_tree().root:
				fin = get_tree().root.find_child("FinanceManager", true, false)
			if fin and fin.has_method("_ensure_daily_bills"):
				fin._ensure_daily_bills()

			return true
	return false

func get_employees() -> Array[Employee]:
	return employees

func calculate_daily_salaries_cost() -> float:
	return float(employees.size()) * daily_salary

func calculate_total_weekly_salaries() -> float:
	var total: float = 0.0
	for emp in employees:
		total += emp.weekly_salary
	return total

func process_weekly_payroll() -> Dictionary:
	var total_salaries = calculate_total_weekly_salaries()
	var summaries: Array[Dictionary] = []

	var economy = EconomyManager.get_instance()
	if economy and total_salaries > 0.0:
		economy.spend_money(total_salaries, "Folha Salarial Semanal (%d funcionários)" % employees.size())

	for emp in employees:
		summaries.append({
			"id": emp.employee_id,
			"name": emp.employee_name,
			"salary": emp.daily_salary,
			"tasks_completed": emp.tasks_completed
		})

	return {
		"total_salaries": total_salaries,
		"employees_summary": summaries
	}
