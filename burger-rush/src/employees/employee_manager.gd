class_name EmployeeManager
extends Node

signal employee_hired(employee: Employee)
signal employee_fired(employee_id: int)
signal role_changed(employee: Employee, new_role: Employee.Role)

static var instance: EmployeeManager = null

var employee_scene: PackedScene = preload("res://src/employees/employee.tscn")
var employees: Array[Employee] = []
var next_id: int = 1
var hiring_cost: float = 100.0

var names_pool: Array[String] = ["João", "Carlos", "Pedro", "Ana", "Mariana", "Lucas", "Beatriz", "Gabriel"]

func _enter_tree() -> void:
	instance = self

static func get_instance() -> EmployeeManager:
	return instance

func get_next_name() -> String:
	var idx = (next_id - 1) % names_pool.size()
	return names_pool[idx]

func hire_employee(emp_name: String = "", initial_role: Employee.Role = Employee.Role.UNASSIGNED) -> Dictionary:
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

	var parent_node: Node = null
	if get_tree() and get_tree().current_scene:
		parent_node = get_tree().current_scene
	elif get_parent():
		parent_node = get_parent()
	elif get_tree() and get_tree().root.get_child_count() > 0:
		parent_node = get_tree().root.get_child(0)

	if parent_node:
		parent_node.add_child(emp)
		emp.global_position = Vector3(-4.0 + (employees.size() * 1.0), 0.1, -1.0)

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

func set_employee_role(emp_id: int, new_role: Employee.Role) -> bool:
	for emp in employees:
		if emp.employee_id == emp_id:
			emp.set_role(new_role)
			role_changed.emit(emp, new_role)
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
			"role": emp.get_role_name(),
			"salary": emp.weekly_salary,
			"tasks_completed": emp.tasks_completed_this_week
		})
		# Reseta estatísticas da semana
		emp.tasks_completed_this_week = 0

	return {
		"total_salaries": total_salaries,
		"employees_summary": summaries
	}
