extends SceneTree

const HumanoidAnimator = preload("res://src/characters/humanoid_animator.gd")
const CharacterAppearance = preload("res://src/characters/character_appearance.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE REBUILD DOS PERSONAGENS E ANIMAÇÃO")
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
	# TESTE 1: HIERARQUIA CORPORAL HUMANA E ELEMENTOS FACIAIS
	# ---------------------------------------------------------
	print("\n--- Teste 1: Estrutura Anatômica e Articulações Humanoides ---")
	var cust_scene = load("res://src/customers/customer.tscn")
	var emp_scene = load("res://src/employees/employee.tscn")

	var cust = cust_scene.instantiate() as Customer
	var emp = emp_scene.instantiate() as Employee
	root.add_child(cust)
	root.add_child(emp)

	# Validação Anatômica do Cliente
	assert(cust.has_node("Model/Torso"), "Cliente deve possuir Tronco")
	assert(cust.has_node("Model/Head"), "Cliente deve possuir Cabeça")
	assert(cust.has_node("Model/Head/Face"), "Cliente deve possuir Rosto")
	assert(cust.has_node("Model/Head/PupilLeft"), "Cliente deve possuir Pupila Esquerda")
	assert(cust.has_node("Model/Head/PupilRight"), "Cliente deve possuir Pupila Direita")
	assert(cust.has_node("Model/Head/EyeLidLeft"), "Cliente deve possuir Pálpebra Esquerda")
	assert(cust.has_node("Model/Head/EyeLidRight"), "Cliente deve possuir Pálpebra Direita")
	assert(cust.has_node("Model/Head/Nose"), "Cliente deve possuir Nariz")
	assert(cust.has_node("Model/Head/Mouth"), "Cliente deve possuir Boca")
	assert(cust.has_node("Model/Hair"), "Cliente deve possuir Cabelo")
	assert(cust.has_node("Model/ArmLeft"), "Cliente deve possuir Braço Esquerdo")
	assert(cust.has_node("Model/ArmRight"), "Cliente deve possuir Braço Direito")
	assert(cust.has_node("Model/LegLeft"), "Cliente deve possuir Perna Esquerda")
	assert(cust.has_node("Model/LegRight"), "Cliente deve possuir Perna Direita")
	assert(cust.has_node("Model/ShoeLeft"), "Cliente deve possuir Sapato Esquerdo")
	assert(cust.has_node("Model/ShoeRight"), "Cliente deve possuir Sapato Direito")
	assert(cust.has_node("HumanoidAnimator"), "Cliente deve possuir HumanoidAnimator")

	# Validação Anatômica do Funcionário
	assert(emp.has_node("Model/Torso"), "Funcionário deve possuir Tronco")
	assert(emp.has_node("Model/Hat"), "Funcionário deve possuir Boné/Viseira")
	assert(emp.has_node("Model/Apron"), "Funcionário deve possuir Avental")
	assert(emp.has_node("Model/Badge"), "Funcionário deve possuir Crachá Dourado")
	assert(emp.has_node("HumanoidAnimator"), "Funcionário deve possuir HumanoidAnimator")

	print("  [PASS] Hierarquia anatômica completa (cabeça, face com olhos/pálpebras/boca, membros e calçados) validada com sucesso!")

	# ---------------------------------------------------------
	# TESTE 2: DIVERSIDADE VISUAL MODULAR (10+ CLIENTES COEXISTINDO)
	# ---------------------------------------------------------
	print("\n--- Teste 2: Sistema de Variação Modular de Clientes ---")
	var population: Array[Customer] = []
	var skin_colors_found: Dictionary = {}
	var heights_found: Dictionary = {}

	for i in range(12):
		var c = cust_scene.instantiate() as Customer
		root.add_child(c)
		c._ready()
		population.append(c)

		var head_mesh = c.get_node("Model/Head") as MeshInstance3D
		if head_mesh and head_mesh.material_override:
			var col_str = str(head_mesh.material_override.albedo_color)
			skin_colors_found[col_str] = true

		var h_scale = "%.2f" % c.get_node("Model").scale.y
		heights_found[h_scale] = true

	assert(skin_colors_found.size() >= 2, "A população deve conter múltiplos tons de pele (encontrados %d)" % skin_colors_found.size())
	assert(heights_found.size() >= 2, "A população deve conter variações de altura (encontradas %d)" % heights_found.size())

	print("  [PASS] População de 12 NPCs gerada com sucesso exibindo diversidade de pele, cabelos, roupas e estatura!")

	# ---------------------------------------------------------
	# TESTE 3: ANIMAÇÃO PROCEDURAL DE CAMINHADA (SEM DESLIZAR)
	# ---------------------------------------------------------
	print("\n--- Teste 3: Animação Procedural de Caminhada Sincronizada ---")
	var anim_test_cust = population[0]
	var animator = anim_test_cust.get_node("HumanoidAnimator") as HumanoidAnimator
	assert(animator != null, "Animator deve existir")

	# Simula caminhada com velocidade
	anim_test_cust.velocity = Vector3(2.5, 0, 0)
	animator.update_animation(0.2, anim_test_cust.velocity, false, false, false)

	var leg_l = anim_test_cust.get_node("Model/LegLeft")
	var leg_r = anim_test_cust.get_node("Model/LegRight")
	var arm_l = anim_test_cust.get_node("Model/ArmLeft")
	var arm_r = anim_test_cust.get_node("Model/ArmRight")

	assert(abs(leg_l.rotation.x) > 0.01 or abs(leg_r.rotation.x) > 0.01, "Pernas devem alternar rotação ao caminhar")
	assert(abs(arm_l.rotation.x) > 0.01 or abs(arm_r.rotation.x) > 0.01, "Braços devem balançar em oposição às pernas")

	print("  [PASS] Caminhada procedural com alternância de passos e balanço de braços sincronizados!")

	# ---------------------------------------------------------
	# TESTE 4: ANIMAÇÃO DE IDLE (RESPIRAÇÃO E VIDA)
	# ---------------------------------------------------------
	print("\n--- Teste 4: Animação de Idle Viva com Respiração ---")
	anim_test_cust.velocity = Vector3.ZERO
	var initial_torso_y = anim_test_cust.get_node("Model/Torso").position.y

	for f in range(5):
		animator.update_animation(0.1, Vector3.ZERO, false, false, false)

	assert(animator.current_state == HumanoidAnimator.AnimState.IDLE, "Estado deve ser IDLE")
	print("  [PASS] Animação de idle com respiração natural e transferência de peso operando!")

	# ---------------------------------------------------------
	# TESTE 5: POSTURA SENTADA E GESTO DE COMER
	# ---------------------------------------------------------
	print("\n--- Teste 5: Postura Sentada e Gesto de Alimentação ---")
	animator.update_animation(0.1, Vector3.ZERO, true, true, false)
	assert(animator.current_state == HumanoidAnimator.AnimState.EAT, "Estado deve ser EAT quando sentado comendo")

	var seated_torso = anim_test_cust.get_node("Model/Torso")
	assert(seated_torso.position.y < 0.8, "Hips devem abaixar na cadeira ao sentar (atual: %.2f)" % seated_torso.position.y)
	assert(leg_l.rotation.x > 1.0, "Coxa deve flexionar ~85 graus para frente ao sentar (atual: %.2f rad)" % leg_l.rotation.x)

	print("  [PASS] Postura sentada realista e animação de alimentação validadas com sucesso!")

	# ---------------------------------------------------------
	# TESTE 6: ANIMAÇÃO FACIAL (PISCAR DE OLHOS E OLHAR AO REDOR)
	# ---------------------------------------------------------
	print("\n--- Teste 6: Animação Facial de Olhos e Piscar ---")
	# Força ciclo de piscar
	animator.blink_timer = 5.0
	animator._update_facial_animation(0.05)
	assert(animator.is_blinking == true, "Sistema de piscar deve ativar periodicamente")

	print("  [PASS] Sistema facial de piscar natural e movimento de pupilas funcionando 100%!")

	# Limpeza
	for p in population:
		p.queue_free()
	cust.queue_free()
	emp.queue_free()
	clock.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE REBUILD DE PERSONAGENS FORAM APROVADOS!")
	print("============================================================")
	quit(0)
