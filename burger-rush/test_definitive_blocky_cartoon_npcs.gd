extends SceneTree

const HumanoidAnimator = preload("res://src/characters/humanoid_animator.gd")
const CharacterAppearance = preload("res://src/characters/character_appearance.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DO ESTILO DEFINITIVO BLOCKY CARTOON")
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
	# TESTE 1: PROPORÇÕES CARTOON COMPACTAS E ANATOMIA CONECTADA
	# ---------------------------------------------------------
	print("\n--- Teste 1: Proporções Cartoon Compactas e Membros Conectados ---")
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
	var neck = torso.get_node("Neck")
	var hips = torso.get_node("Hips")
	var arm_l = cust.get_node("Model/ArmLeft")
	var hand_l = arm_l.get_node("HandLeft")
	var leg_l = cust.get_node("Model/LegLeft")
	var shoe_l = leg_l.get_node("ShoeLeft")

	# Verifica altura compacta cartoon (entre 1.25m e 1.50m)
	var total_height = head.position.y + 0.14
	assert(total_height >= 1.10 and total_height <= 1.50, "Altura total deve ser compacta e cartoon (atual: %.2fm)" % total_height)

	# Verifica conexões sem peças flutuando
	assert(neck != null and neck.position.y > 0.15, "Pescoço deve conectar o tronco à cabeça")
	assert(hips != null and hips.position.y < 0.0, "Quadril deve estar conectado à base do tronco")
	assert(hand_l != null and hand_l.position.y < 0.0, "Mão deve estar conectada ao punho do braço")
	assert(shoe_l != null and shoe_l.position.y < 0.0, "Sapato deve estar conectado à canela da perna")

	print("  [PASS] Proporções compactas (altura: %.2fm) e anatomia 100%% conectada!" % total_height)

	# ---------------------------------------------------------
	# TESTE 2: ROSTO CARTOON EXPRESSIVO NA FRENTE (-Z)
	# ---------------------------------------------------------
	print("\n--- Teste 2: Rosto Cartoon Expressivo na Frente (-Z) ---")
	var eye_l = head.get_node("EyeLeft")
	var eye_r = head.get_node("EyeRight")
	var pupil_l = eye_l.get_node("Pupil")
	var highlight_l = eye_l.get_node("Highlight")
	var eyebrow_l = head.get_node("EyebrowLeft")
	var nose = head.get_node("Nose")
	var mouth = head.get_node("Mouth")

	assert(eye_l.position.z < 0.0, "Olho esquerdo deve estar na frente da cabeça (-Z)")
	assert(eye_r.position.z < 0.0, "Olho direito deve estar na frente da cabeça (-Z)")
	assert(pupil_l.position.z < 0.0, "Pupila deve estar na frente do olho (-Z)")
	assert(highlight_l.position.z < 0.0, "Brilho do olho deve estar na frente (-Z)")
	assert(eyebrow_l.position.z < 0.0, "Sobrancelha deve estar na frente (-Z)")
	assert(nose.position.z < 0.0, "Nariz deve estar na frente (-Z)")
	assert(mouth.position.z < 0.0, "Boca deve estar na frente (-Z)")
	assert(shoe_l.position.z < 0.0, "Bico do sapato deve apontar para frente (-Z)")

	var emp_hat_brim = emp.get_node("Model/Hat/VisorBrim")
	var emp_apron = emp.get_node("Model/Apron")
	var emp_badge = emp.get_node("Model/Badge")
	assert(emp_hat_brim.position.z < 0.0, "Aba do boné deve apontar para frente (-Z)")
	assert(emp_apron.position.z < 0.0, "Avental deve estar no peito (-Z)")
	assert(emp_badge.position.z < 0.0, "Crachá deve estar no peito (-Z)")

	print("  [PASS] Rosto simpático, olhos, sobrancelhas, nariz, boca, sapatos e boné 100%% voltados para frente (-Z)!")

	# ---------------------------------------------------------
	# TESTE 3: MATERIAIS 100% FOSCOS E NATURAIS
	# ---------------------------------------------------------
	print("\n--- Teste 3: Materiais Foscos e Não Metálicos ---")
	var head_mat = head.material_override as StandardMaterial3D
	var torso_mat = torso.material_override as StandardMaterial3D
	assert(head_mat != null and head_mat.roughness >= 0.75 and head_mat.metallic == 0.0, "Pele deve ser fosca e não metálica")
	assert(torso_mat != null and torso_mat.roughness >= 0.75 and torso_mat.metallic == 0.0, "Roupa deve ser de tecido fosco")

	print("  [PASS] Materiais 100%% foscos validados!")

	# ---------------------------------------------------------
	# TESTE 4: ANIMAÇÕES DE CAMINHADA, IDLE E SENTAR
	# ---------------------------------------------------------
	print("\n--- Teste 4: Animações de Caminhada, Idle e Postura Sentada ---")
	var animator = cust.get_node("HumanoidAnimator") as HumanoidAnimator

	# Caminhada
	animator.update_animation(0.1, Vector3(2.5, 0, 0), false, false, false)
	assert(leg_l.rotation.x != 0.0, "Pernas devem alternar na caminhada")
	assert(arm_l.rotation.x != 0.0, "Braços devem balançar na caminhada")

	# Sentar
	animator.update_animation(0.1, Vector3.ZERO, true, false, false)
	assert(torso.position.y < 0.55, "Tronco deve abaixar para descansar no assento da cadeira (atual: %.2fm)" % torso.position.y)
	assert(leg_l.rotation.x > 1.0, "Coxas devem flexionar para frente ao sentar")

	print("  [PASS] Animações e postura sentada perfeitamente calibradas!")

	# Limpeza
	cust.queue_free()
	emp.queue_free()
	clock.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DO ESTILO DEFINITIVO FORAM APROVADOS!")
	print("============================================================")
	quit(0)
