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
var employee_scene: PackedScene = preload("res://src/employees/employee.tscn")
var employees: Array[Employee] = []
var next_id: int = 1
var hiring_cost: float = 100.0

var names_pool: Array[String] = ["Carlos", "João", "Pedro", "Ana", "Mariana", "Lucas", "Beatriz", "Gabriel"]

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
	# O funcionário está temporariamente desativado no início da partida.
	# A contratação será feita pelo PC no futuro.
	if auto_spawn_initial_employee:
		call_deferred("_spawn_initial_employee")

func _spawn_initial_employee() -> void:
	if not employees.is_empty():
		return

	var emp = employee_scene.instantiate() as Employee
	emp.employee_id = next_id
	next_id += 1
	emp.employee_name = "Carlos"
	emp.weekly_salary = 250.0
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

func hire_employee(emp_name: String = "", initial_role: Employee.Role = Employee.Role.GENERAL) -> Dictionary:
	var economy = EconomyManager.get_instance()
	if not economy or economy.get_money() < hiring_cost:
		return {"success": false, "message": "Saldo insuficiente para contratação ($%.2f necessário)." % hiring_cost}

	if not economy.spend_money(hiring_cost, "Contratação de Funcionário"):
		return {"success": false, "message": "Falha na transação financeira."}

	var name_str = emp_name if emp_name != "" else get_next_name()
	var emp = employee_scene.instantiate() as Employee
	emp.employee_id = next_id
	next_id += 1
	emp.employee_name = name_str
	emp.role = initial_role
	emp.weekly_salary = 250.0
	emp.rest_position = Vector3(2.4 - (employees.size() * 0.8), 0.0, 7.5)

	var parent_node: Node = get_parent() if get_parent() else (get_tree().current_scene if get_tree() else null)
	if parent_node:
		parent_node.add_child(emp)
		emp.global_position = emp.rest_position

	employees.append(emp)
	employee_hired.emit(emp)
	return {"success": true, "message": "Funcionário %s contratado com sucesso!" % name_str, "employee": emp}

func fire_employee(emp_id: int) -> bool:
	for i in range(employees.size()):
		var emp = employees[i]
		if emp.employee_id == emp_id:
			employees.remove_at(i)
			employee_fired.emit(emp_id)
			if is_instance_valid(emp):
				emp.queue_free()
			return true
	return false

func get_employees() -> Array[Employee]:
	return employees

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
			"salary": emp.weekly_salary,
			"tasks_completed": emp.tasks_completed
		})

	return {
		"total_salaries": total_salaries,
		"employees_summary": summaries
	}
