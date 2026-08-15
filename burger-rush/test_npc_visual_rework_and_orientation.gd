extends SceneTree

const HumanoidAnimator = preload("res://src/characters/humanoid_animator.gd")
const CharacterAppearance = preload("res://src/characters/character_appearance.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE REWORK VISUAL PROFUNDO E ORIENTAÇÃO DOS NPCs")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var clock = GameClock.new()
	root.add_child(clock)
	clock._enter_tree()
	clock.open_restaurant()

	# ---------------------------------------------------------
	# TESTE 1: CORREÇÃO CRÍTICA DO ROSTO E ORIENTAÇÃO FRONTAL (-Z)
	# ---------------------------------------------------------
	print("\n--- Teste 1: Orientação Frontal do Rosto, Olhos e Sapatos (-Z) ---")
	var cust_scene = load("res://src/customers/customer.tscn")
	var emp_scene = load("res://src/employees/employee.tscn")

	var cust = cust_scene.instantiate() as Customer
	var emp = emp_scene.instantiate() as Employee
	root.add_child(cust)
	root.add_child(emp)
	cust._ready()
	emp._ready()

	var head = cust.get_node("Model/Head")
	var face = head.get_node("Face")
	var pupil_l = head.get_node("PupilLeft")
	var pupil_r = head.get_node("PupilRight")
	var nose = head.get_node("Nose")
	var mouth = head.get_node("Mouth")
	var shoe_l = cust.get_node("Model/ShoeLeft")

	# Todos os elementos faciais e sapatos DEVEM estar voltados para a frente (-Z)
	assert(face.position.z < 0.0, "Rosto deve estar na frente da cabeça (z < 0, atual: %.3f)" % face.position.z)
	assert(pupil_l.position.z < 0.0, "Pupila esquerda deve estar na frente (z < 0, atual: %.3f)" % pupil_l.position.z)
	assert(pupil_r.position.z < 0.0, "Pupila direita deve estar na frente (z < 0, atual: %.3f)" % pupil_r.position.z)
	assert(nose.position.z < 0.0, "Nariz deve estar na frente (z < 0, atual: %.3f)" % nose.position.z)
	assert(mouth.position.z < 0.0, "Boca deve estar na frente (z < 0, atual: %.3f)" % mouth.position.z)
	assert(shoe_l.position.z < 0.0, "Sapatos devem apontar para a frente (z < 0, atual: %.3f)" % shoe_l.position.z)

	var emp_apron = emp.get_node("Model/Apron")
	var emp_badge = emp.get_node("Model/Badge")
	assert(emp_apron.position.z < 0.0, "Avental do funcionário deve estar no peito/frente (z < 0, atual: %.3f)" % emp_apron.position.z)
	assert(emp_badge.position.z < 0.0, "Crachá do funcionário deve estar na frente (z < 0, atual: %.3f)" % emp_badge.position.z)

	print("  [PASS] Rosto, pupilas, nariz, boca, sapatos, avental e crachá 100% alinhados para a frente (-Z)!")

	# ---------------------------------------------------------
	# TESTE 2: FORMAS ARREDONDADAS ORGÂNICAS (ZERO MINECRAFT BOXES)
	# ---------------------------------------------------------
	print("\n--- Teste 2: Geometria Arredondada e Silhueta Humanoide ---")
	var head_mesh = cust.get_node("Model/Head") as MeshInstance3D
	var torso_mesh = cust.get_node("Model/Torso") as MeshInstance3D
	var arm_mesh = cust.get_node("Model/ArmLeft") as MeshInstance3D
	var leg_mesh = cust.get_node("Model/LegLeft") as MeshInstance3D
	var hand_mesh = cust.get_node("Model/ArmLeft/HandLeft") as MeshInstance3D
	var shoe_mesh = cust.get_node("Model/ShoeLeft") as MeshInstance3D

	assert(head_mesh.mesh is SphereMesh or head_mesh.mesh is CapsuleMesh, "Cabeça deve ser arredondada (SphereMesh/CapsuleMesh)")
	assert(torso_mesh.mesh is CapsuleMesh or torso_mesh.mesh is CylinderMesh, "Tronco deve ser arredondado (CapsuleMesh)")
	assert(arm_mesh.mesh is CapsuleMesh or arm_mesh.mesh is CylinderMesh, "Braço deve ser arredondado (CapsuleMesh)")
	assert(leg_mesh.mesh is CapsuleMesh or leg_mesh.mesh is CylinderMesh, "Perna deve ser arredondada (CapsuleMesh)")
	assert(hand_mesh.mesh is SphereMesh or hand_mesh.mesh is CapsuleMesh, "Mão deve ser arredondada (SphereMesh)")
	assert(shoe_mesh.mesh is CapsuleMesh or shoe_mesh.mesh is CylinderMesh, "Sapato deve ser arredondado (CapsuleMesh)")

	print("  [PASS] Geometria 100% orgânica e arredondada (cabeça oval, tronco, braços, pernas, mãos e sapatos suaves)!")

	# ---------------------------------------------------------
	# TESTE 3: MATERIAIS FOSCOS E NATURAIS (SEM PLÁSTICO / BRILHO)
	# ---------------------------------------------------------
	print("\n--- Teste 3: Materiais Naturais e Tecidos Foscos ---")
	var torso_mat = torso_mesh.material_override as StandardMaterial3D
	var head_mat = head_mesh.material_override as StandardMaterial3D

	assert(torso_mat != null and torso_mat.roughness >= 0.75, "Roupa deve ter tecido fosco com roughness >= 0.75")
	assert(torso_mat.metallic == 0.0, "Roupa não deve ser metálica")
	assert(head_mat != null and head_mat.roughness >= 0.70, "Pele deve ser fosca e natural")
	assert(head_mat.metallic == 0.0, "Pele não deve ser metálica")

	print("  [PASS] Materiais 100% foscos e naturais validados com sucesso!")

	# ---------------------------------------------------------
	# TESTE 4: POSTURA SENTADA REALISTA ALINHADA PARA A FRENTE
	# ---------------------------------------------------------
	print("\n--- Teste 4: Postura Sentada com Pernas Projetadas para Frente (-Z) ---")
	var animator = cust.get_node("HumanoidAnimator") as HumanoidAnimator
	animator.update_animation(0.1, Vector3.ZERO, true, false, false)

	var seated_torso = cust.get_node("Model/Torso")
	var seated_leg = cust.get_node("Model/LegLeft")
	assert(seated_torso.position.y < 0.7, "Hips devem abaixar na cadeira ao sentar (atual: %.2f)" % seated_torso.position.y)
	assert(seated_leg.position.z < 0.0, "Coxas devem estar projetadas para frente (-Z) ao sentar (atual: %.2f)" % seated_leg.position.z)
	assert(seated_leg.rotation.x > 1.0, "Coxas devem flexionar para frente em rotação X positiva (atual: %.2f rad)" % seated_leg.rotation.x)

	print("  [PASS] Postura sentada perfeitamente alinhada com assento e pernas para frente!")

	# Limpeza
	cust.queue_free()
	emp.queue_free()
	clock.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE REWORK VISUAL PROFUNDO FORAM APROVADOS!")
	print("============================================================")
	quit(0)
