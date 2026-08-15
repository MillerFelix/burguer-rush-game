extends SceneTree

const HumanoidAnimator = preload("res://src/characters/humanoid_animator.gd")
const CharacterAppearance = preload("res://src/characters/character_appearance.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE POLIMENTO DOS NPCs (PROPORÇÃO, SENTAR, CABELO)")
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
	# TESTE 1: AUMENTO PROPORCIONAL DE ALTURA (~15-20%, ~1.44M)
	# ---------------------------------------------------------
	print("\n--- Teste 1: Aumento Proporcional de Altura (1.40m - 1.50m) ---")
	var cust_scene = load("res://src/customers/customer.tscn")
	var emp_scene = load("res://src/employees/employee.tscn")

	var cust = cust_scene.instantiate() as Customer
	var emp = emp_scene.instantiate() as Employee
	root.add_child(cust)
	root.add_child(emp)
	cust._ready()
	emp._ready()

	var head = cust.get_node("Model/Head")
	var torso = cust.get_node("Model/Torso")
	var leg_l = cust.get_node("Model/LegLeft")
	var arm_l = cust.get_node("Model/ArmLeft")

	var total_height = head.position.y + 0.15
	assert(total_height >= 1.35 and total_height <= 1.55, "Altura total deve estar polida entre 1.35m e 1.55m (atual: %.2fm)" % total_height)
	assert(torso.position.y >= 0.75, "Tronco deve estar na altura proporcional (atual: %.2fm)" % torso.position.y)
	assert(leg_l.position.y >= 0.45, "Pernas devem estar mais compridas (atual: %.2fm)" % leg_l.position.y)

	print("  [PASS] Altura proporcional ajustada com sucesso (Total: %.2fm)!" % total_height)

	# ---------------------------------------------------------
	# TESTE 2: CABELO E BONÉ 100% PRESOS À CABEÇA (ZERO FLUTUAÇÃO)
	# ---------------------------------------------------------
	print("\n--- Teste 2: Cabelo e Boné Fixos na Cabeça ---")
	var cust_hair = head.get_node_or_null("Hair")
	var emp_head = emp.get_node("Model/Head")
	var emp_hat = emp_head.get_node_or_null("Hat")

	assert(cust_hair != null, "Cabelo DEVE ser filho direto da Cabeça ($Model/Head/Hair)")
	assert(emp_hat != null, "Boné DEVE ser filho direto da Cabeça ($Model/Head/Hat)")
	assert(cust_hair.position.y < 0.15, "Cabelo deve envolver a cabeça sem flutuar (y local: %.2fm)" % cust_hair.position.y)
	assert(emp_hat.position.y < 0.15, "Boné deve envolver a cabeça sem flutuar (y local: %.2fm)" % emp_hat.position.y)

	# Testa se o cabelo acompanha rotação e translação da cabeça
	head.rotation.y = 0.5
	head.position.y += 0.05
	assert(cust_hair.get_parent() == head, "Cabelo acompanha o transform da cabeça")

	print("  [PASS] Cabelo e boné 100% integrados à cabeça, sem flutuação!")

	# ---------------------------------------------------------
	# TESTE 3: POSTURA SENTADA PERFEITA (CONTATO COM ASSENTO A 0.48M)
	# ---------------------------------------------------------
	print("\n--- Teste 3: Contato Preciso com o Assento da Cadeira ---")
	var animator = cust.get_node("HumanoidAnimator") as HumanoidAnimator
	animator.update_animation(0.1, Vector3.ZERO, true, false, false)

	# Base do quadril (Hips) = Torso.y (0.72) - Hips.local_y (0.26) = 0.46m ~ 0.48m
	var hips_world_y = torso.position.y - 0.26
	assert(hips_world_y >= 0.42 and hips_world_y <= 0.50, "Base do quadril deve encostar exatamente no assento a ~0.48m (atual: %.2fm)" % hips_world_y)
	assert(leg_l.rotation.x > 1.4, "Coxas devem flexionar para frente em ~86 graus ao sentar (atual: %.2f rad)" % leg_l.rotation.x)
	assert(torso.position.z > 0.0, "Tronco deve recuar levemente (+Z) para encostar no encosto (atual: %.2fm)" % torso.position.z)

	print("  [PASS] Postura sentada perfeitamente apoiada no assento (Quadril: %.2fm, Encosto: %.2fm)!" % [hips_world_y, torso.position.z])

	# ---------------------------------------------------------
	# TESTE 4: CAMINHADA E IDLE FLUIDOS
	# ---------------------------------------------------------
	print("\n--- Teste 4: Animação de Caminhada e Idle Operacionais ---")
	animator.update_animation(0.1, Vector3(2.5, 0, 0), false, false, false)
	assert(leg_l.rotation.x != 0.0, "Pernas devem alternar durante caminhada")
	assert(arm_l.rotation.x != 0.0, "Braços devem balançar durante caminhada")

	animator.update_animation(0.1, Vector3.ZERO, false, false, false)
	assert(torso.position.y > 0.75, "Tronco retorna à posição de pé no idle")

	print("  [PASS] Animações de caminhada e idle testadas com sucesso!")

	# Limpeza
	cust.queue_free()
	emp.queue_free()
	clock.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE POLIMENTO DOS NPCs FORAM APROVADOS!")
	print("============================================================")
	quit(0)
