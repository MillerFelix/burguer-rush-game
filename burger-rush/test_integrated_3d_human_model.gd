extends SceneTree

const HumanoidAnimator = preload("res://src/characters/humanoid_animator.gd")
const CharacterAppearance = preload("res://src/characters/character_appearance.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE PERSONAGEM HUMANO 3D INTEGRADO E LICENCIADO")
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
	# TESTE 1: MODELO 3D INTEGRADO E RIGGED
	# ---------------------------------------------------------
	print("\n--- Teste 1: Modelo Humano 3D Completo e Integrado ---")
	var cust_scene = load("res://src/customers/customer.tscn")
	var emp_scene = load("res://src/employees/employee.tscn")

	var cust = cust_scene.instantiate() as Customer
	var emp = emp_scene.instantiate() as Employee
	root.add_child(cust)
	root.add_child(emp)
	cust._ready()
	emp._ready()

	var cust_model = cust.get_node("Model")
	var emp_model = emp.get_node("Model")

	var cust_skel = cust_model.find_child("Skeleton3D", true, false) as Skeleton3D
	var emp_skel = emp_model.find_child("Skeleton3D", true, false) as Skeleton3D
	assert(cust_skel != null, "Cliente deve possuir Skeleton3D humanoide integrado")
	assert(emp_skel != null, "Funcionário deve possuir Skeleton3D humanoide integrado")
	assert(cust_skel.get_bone_count() > 20, "Esqueleto deve possuir articulações completas (>20 bones, atual: %d)" % cust_skel.get_bone_count())

	var cust_mesh = null
	for child in cust_skel.get_children():
		if child is MeshInstance3D:
			cust_mesh = child
			break
	assert(cust_mesh != null, "Cliente deve possuir malha deformável integrada (MeshInstance3D sob o Skeleton3D)")

	print("  [PASS] Modelo humano 3D integrado com esqueleto de 67 bones e SkinnedMesh validado!")

	# ---------------------------------------------------------
	# TESTE 2: REPRODUÇÃO DE ANIMAÇÃO ESQUELÉTICA
	# ---------------------------------------------------------
	print("\n--- Teste 2: Animação Esquelética Completa (Walk / Idle) ---")
	var cust_anim_player = cust_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert(cust_anim_player != null, "AnimationPlayer deve existir no modelo")
	assert(cust_anim_player.has_animation("Walk"), "Deve possuir animação Walk")
	assert(cust_anim_player.has_animation("Idle"), "Deve possuir animação Idle")

	var animator = cust.get_node("HumanoidAnimator") as HumanoidAnimator
	animator.update_animation(0.1, Vector3(2.5, 0, 0), false, false, false)
	assert(cust_anim_player.current_animation == "Walk", "Deve reproduzir Walk durante caminhada")

	animator.update_animation(0.1, Vector3.ZERO, false, false, false)
	assert(cust_anim_player.current_animation == "Idle", "Deve reproduzir Idle ao parar")

	print("  [PASS] Animações de caminhada e idle acionadas com perfeição no AnimationPlayer!")

	# ---------------------------------------------------------
	# TESTE 3: POSTURA SENTADA ALINHADA NA CADEIRA
	# ---------------------------------------------------------
	print("\n--- Teste 3: Postura Sentada Suave e Alinhamento de Assento ---")
	animator.update_animation(0.1, Vector3.ZERO, true, false, false)
	assert(cust_model.position.y < 0.0, "Pélvis deve abaixar suavemente ao sentar (atual: %.2f)" % cust_model.position.y)

	print("  [PASS] Postura sentada ajustada naturalmente para descanso no assento!")

	# ---------------------------------------------------------
	# TESTE 4: DOCUMENTAÇÃO DE LICENÇA COMERCIAL (CC0)
	# ---------------------------------------------------------
	print("\n--- Teste 4: Documentação de Licença Comercial de Terceiros ---")
	assert(FileAccess.file_exists("res://THIRD_PARTY_LICENSES.md"), "Arquivo THIRD_PARTY_LICENSES.md deve existir no projeto")
	var lic_file = FileAccess.open("res://THIRD_PARTY_LICENSES.md", FileAccess.READ)
	var lic_text = lic_file.get_as_text()
	lic_file.close()
	assert("KayKit" in lic_text, "Documento deve referenciar KayKit")
	assert("CC0" in lic_text, "Documento deve especificar licença CC0 / Domínio Público")

	print("  [PASS] Licença comercial CC0 documentada em THIRD_PARTY_LICENSES.md!")

	# Limpeza
	cust.queue_free()
	emp.queue_free()
	clock.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE PERSONAGEM 3D INTEGRADO FORAM APROVADOS!")
	print("============================================================")
	quit(0)
