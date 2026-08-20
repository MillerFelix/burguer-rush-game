extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DE AJUSTES VISUAIS (OLHOS DOS PERSONAGENS & CAIXA)
# ==============================================================================

var passed: int = 0
var failed: int = 0

func assert_test(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("  [PASS] %s" % message)
	else:
		failed += 1
		print("  [FAIL] %s" % message)

func _init() -> void:
	call_deferred("run_all_tests")

func _check_no_box_intersection(mesh_a: MeshInstance3D, mesh_b: MeshInstance3D, root_node: Node3D, name_a: String, name_b: String) -> bool:
	if not mesh_a or not mesh_b or not (mesh_a.mesh is BoxMesh) or not (mesh_b.mesh is BoxMesh):
		return true

	var t_a = root_node.global_transform.affine_inverse() * mesh_a.global_transform
	var t_b = root_node.global_transform.affine_inverse() * mesh_b.global_transform

	var s_a = (mesh_a.mesh as BoxMesh).size
	var s_b = (mesh_b.mesh as BoxMesh).size

	var min_a = t_a.origin - (s_a * 0.5)
	var max_a = t_a.origin + (s_a * 0.5)

	var min_b = t_b.origin - (s_b * 0.5)
	var max_b = t_b.origin + (s_b * 0.5)

	var overlap_x = (min_a.x < max_b.x and max_a.x > min_b.x)
	var overlap_y = (min_a.y < max_b.y and max_a.y > min_b.y)
	var overlap_z = (min_a.z < max_b.z and max_a.z > min_b.z)

	var intersects = (overlap_x and overlap_y and overlap_z)
	if intersects:
		print("    [DEBUG INTERSECTION] %s vs %s: Overlap (X:%s, Y:%s, Z:%s)" % [name_a, name_b, overlap_x, overlap_y, overlap_z])
		print("      %s: min=%s, max=%s" % [name_a, min_a, max_a])
		print("      %s: min=%s, max=%s" % [name_b, min_b, max_b])
	return not intersects

func run_all_tests() -> void:
	print("\n=================================================================")
	print("=== BURGER RUSH - TESTES DE AJUSTES VISUAIS =====================")
	print("=================================================================")

	# -----------------------------------------------------------------
	# TESTE 1: CLIENTES (Customer.tscn) - Geometria de Olhos e Cabelo
	# -----------------------------------------------------------------
	print("\n--- TESTE 1: Olhos e Franja do Cliente (Customer.tscn) ---")
	var customer_scene = load("res://src/customers/customer.tscn")
	var customer = customer_scene.instantiate() as Node3D
	root.add_child(customer)

	var head_cust = customer.get_node_or_null("Model/Head")
	var eye_l_cust = customer.get_node_or_null("Model/Head/EyeLeft") as MeshInstance3D
	var eye_r_cust = customer.get_node_or_null("Model/Head/EyeRight") as MeshInstance3D
	var hair_bang_cust = customer.get_node_or_null("Model/Head/Hair/HairBang") as MeshInstance3D

	assert_test(eye_l_cust != null and eye_r_cust != null, "Olhos do cliente existem no modelo")
	assert_test(hair_bang_cust != null, "Franja de cabelo do cliente existe")

	var no_int_l = _check_no_box_intersection(eye_l_cust, hair_bang_cust, head_cust, "EyeLeft", "HairBang")
	var no_int_r = _check_no_box_intersection(eye_r_cust, hair_bang_cust, head_cust, "EyeRight", "HairBang")
	assert_test(no_int_l, "Olho esquerdo NÃO atravessa nem intersecta a franja de cabelo")
	assert_test(no_int_r, "Olho direito NÃO atravessa nem intersecta a franja de cabelo")

	# -----------------------------------------------------------------
	# TESTE 2: FUNCIONÁRIO (Employee.tscn) - Geometria de Olhos e Boné
	# -----------------------------------------------------------------
	print("\n--- TESTE 2: Olhos e Aba do Boné do Funcionário (Employee.tscn) ---")
	var employee_scene = load("res://src/employees/employee.tscn")
	var employee = employee_scene.instantiate() as Node3D
	root.add_child(employee)

	var head_emp = employee.get_node_or_null("Model/Head")
	var eye_l_emp = employee.get_node_or_null("Model/Head/EyeLeft") as MeshInstance3D
	var eye_r_emp = employee.get_node_or_null("Model/Head/EyeRight") as MeshInstance3D
	var brim_emp = employee.get_node_or_null("Model/Head/Hat/VisorBrim") as MeshInstance3D

	assert_test(eye_l_emp != null and eye_r_emp != null, "Olhos do funcionário existem no modelo")
	assert_test(brim_emp != null, "Aba do boné do funcionário existe")

	var no_int_emp_l = _check_no_box_intersection(eye_l_emp, brim_emp, head_emp, "EyeLeft", "VisorBrim")
	var no_int_emp_r = _check_no_box_intersection(eye_r_emp, brim_emp, head_emp, "EyeRight", "VisorBrim")
	assert_test(no_int_emp_l, "Olho esquerdo do funcionário NÃO intersecta a aba do boné")
	assert_test(no_int_emp_r, "Olho direito do funcionário NÃO intersecta a aba do boné")

	# -----------------------------------------------------------------
	# TESTE 3: PEDESTRE AMBIENTE (AmbientPedestrian.tscn)
	# -----------------------------------------------------------------
	print("\n--- TESTE 3: Olhos e Cabelo do Pedestre (AmbientPedestrian.tscn) ---")
	var ped_scene = load("res://src/environment/ambient_pedestrian.tscn")
	var ped = ped_scene.instantiate() as Node3D
	root.add_child(ped)

	var head_ped = ped.get_node_or_null("Model/Head")
	var eye_l_ped = ped.get_node_or_null("Model/Head/EyeLeft") as MeshInstance3D
	var eye_r_ped = ped.get_node_or_null("Model/Head/EyeRight") as MeshInstance3D
	var hair_bang_ped = ped.get_node_or_null("Model/Head/Hair/HairBang") as MeshInstance3D

	assert_test(eye_l_ped != null and eye_r_ped != null, "Olhos do pedestre existem no modelo")
	assert_test(hair_bang_ped != null, "Franja de cabelo do pedestre existe")

	var no_int_ped_l = _check_no_box_intersection(eye_l_ped, hair_bang_ped, head_ped, "EyeLeft", "HairBang")
	var no_int_ped_r = _check_no_box_intersection(eye_r_ped, hair_bang_ped, head_ped, "EyeRight", "HairBang")
	assert_test(no_int_ped_l, "Olho esquerdo do pedestre NÃO intersecta a franja de cabelo")
	assert_test(no_int_ped_r, "Olho direito do pedestre NÃO intersecta a franja de cabelo")

	# -----------------------------------------------------------------
	# TESTE 4: CAIXA REGISTRADORA - Remoção de Letras Flutuantes
	# -----------------------------------------------------------------
	print("\n--- TESTE 4: Caixa Registradora Sem Texto Flutuante ---")
	var cash_reg_scene = load("res://src/stations/cash_register.tscn")
	var cash_reg = cash_reg_scene.instantiate() as Node3D
	root.add_child(cash_reg)

	var screen_label = cash_reg.get_node_or_null("Model/ScreenLabel")
	assert_test(screen_label == null, "ScreenLabel (texto flutuante com nome do restaurante) foi COMPLETAMENTE REMOVIDO")

	var status_label = cash_reg.get_node_or_null("StatusLabel")
	assert_test(status_label == null, "Nenhum StatusLabel flutuante no caixa")

	# Verifica se placas físicas de bancada continuam existindo
	var physical_sign = cash_reg.get_node_or_null("PhysicalCashSign")
	var physical_sign_kitchen = cash_reg.get_node_or_null("PhysicalCashSignKitchen")
	assert_test(physical_sign != null, "Placa física do balcão para salão preservada")
	assert_test(physical_sign_kitchen != null, "Placa física do balcão para cozinha preservada")

	# Limpeza
	customer.queue_free()
	employee.queue_free()
	ped.queue_free()
	cash_reg.queue_free()

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 AJUSTES VISUAIS DE OLHOS E CAIXA 100% VALIDADOS!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)
