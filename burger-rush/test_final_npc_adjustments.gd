extends SceneTree

const HumanoidAnimator = preload("res://src/characters/humanoid_animator.gd")
const CharacterAppearance = preload("res://src/characters/character_appearance.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE AJUSTE FINAL DOS NPCs")
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
	# TESTE 1: ALTURA DO NPC NA ESCALA DO JOGADOR (~1.65M - 1.75M)
	# ---------------------------------------------------------
	print("\n--- Teste 1: Altura dos NPCs em Escala Real do Jogador ---")
	var cust_scene = load("res://src/customers/customer.tscn")
	var emp_scene = load("res://src/employees/employee.tscn")
	var player_scene = load("res://src/player/player.tscn")

	var cust = cust_scene.instantiate() as Customer
	var emp = emp_scene.instantiate() as Employee
	var player = player_scene.instantiate() as CharacterBody3D
	root.add_child(cust)
	root.add_child(emp)
	root.add_child(player)
	cust._ready()
	emp._ready()
	player._ready()

	var cust_head = cust.get_node("Model/Head")
	var player_cam = player.get_node("Head")

	var cust_top_y = cust_head.position.y + 0.17 # Topo da cabeça: 1.48 + 0.17 = 1.65m
	var player_eye_y = player_cam.position.y     # Câmera do jogador: 1.60m

	print("  Topo da cabeça do NPC: %.2fm" % cust_top_y)
	print("  Altura dos olhos do Jogador: %.2fm" % player_eye_y)

	assert(cust_top_y >= 1.55 and cust_top_y <= 1.75, "NPC deve estar na mesma faixa de altura do jogador (atual: %.2fm)" % cust_top_y)
	assert(absf(cust_top_y - player_eye_y) <= 0.15, "Diferença entre o topo do NPC e os olhos do jogador deve ser pequena (<=0.15m, atual: %.2fm)" % absf(cust_top_y - player_eye_y))

	print("  [PASS] Altura dos NPCs igualada com sucesso à escala visual do Jogador!")

	# ---------------------------------------------------------
	# TESTE 2: ROSTO EXPRESSIVO E OLHOS CLARAMENTE VISÍVEIS
	# ---------------------------------------------------------
	print("\n--- Teste 2: Rosto Expressivo, Olhos Abertos e Nitidez à Distância ---")
	var eye_l = cust_head.get_node("EyeLeft") as MeshInstance3D
	var pupil_l = eye_l.get_node("Pupil") as MeshInstance3D
	var highlight_l = eye_l.get_node("Highlight") as MeshInstance3D
	var eyebrow_l = cust_head.get_node("EyebrowLeft") as MeshInstance3D
	var hair_bang = cust_head.get_node("Hair/HairBang") as MeshInstance3D
	var nose = cust_head.get_node("Nose") as MeshInstance3D
	var mouth = cust_head.get_node("Mouth") as MeshInstance3D

	# Verifica dimensões nítidas dos olhos (abertos e grandes o suficiente para leitura à distância)
	var eye_mesh = eye_l.mesh as BoxMesh
	assert(eye_mesh.size.x >= 0.06 and eye_mesh.size.y >= 0.07, "Olhos devem ser grandes e nítidos (atual: %.3f x %.3f)" % [eye_mesh.size.x, eye_mesh.size.y])

	# Verifica se a franja do cabelo não cobre os olhos
	var hair = cust_head.get_node("Hair") as MeshInstance3D
	var bang_head_y = hair.position.y + hair_bang.position.y
	assert(bang_head_y > eye_l.position.y, "Franja do cabelo não deve cobrir os olhos (franja y: %.2f, olho y: %.2f)" % [bang_head_y, eye_l.position.y])

	# Verifica presença de pupilas, brilho e sobrancelhas voltados para frente (-Z)
	assert(eye_l.position.z < 0.0 and pupil_l.position.z < 0.0 and highlight_l.position.z < 0.0, "Olhos e brilho voltados para frente")
	assert(eyebrow_l.position.z < 0.0, "Sobrancelhas voltadas para frente")
	assert(nose.position.z < 0.0, "Nariz voltado para frente")
	assert(mouth.position.z < 0.0, "Boca voltada para frente")

	print("  [PASS] Rosto nítido, olhos abertos e expressivos, sem sobreposição de cabelo!")

	# ---------------------------------------------------------
	# TESTE 3: CADEIRA PROPORCIONAL E CONTATO PRECISO DO ASSENTO
	# ---------------------------------------------------------
	print("\n--- Teste 3: Sentar com Contato no Assento da Cadeira ---")
	var table_scene = load("res://src/stations/restaurant_table.tscn")
	var table = table_scene.instantiate() as RestaurantTable
	root.add_child(table)
	table._ready()

	var seat_pos = table.occupy(cust)
	cust.global_position = seat_pos

	var animator = cust.get_node("HumanoidAnimator") as HumanoidAnimator
	animator.update_animation(0.1, Vector3.ZERO, true, false, false)

	var cust_torso = cust.get_node("Model/Torso")
	var cust_leg = cust.get_node("Model/LegLeft")
	var hips_bottom_y = cust_torso.position.y - 0.31 - 0.07 # = 0.47m

	assert(hips_bottom_y >= 0.44 and hips_bottom_y <= 0.50, "Quadril deve apoiar no assento da cadeira a ~0.48m (atual: %.2fm)" % hips_bottom_y)
	assert(cust_leg.rotation.x > 1.45, "Coxas devem dobrar 88 graus para frente apoiadas no assento (atual: %.2f rad)" % cust_leg.rotation.x)
	assert(cust_torso.position.z > 0.05, "Corpo deve recuar confortavelmente contra o encosto")

	print("  [PASS] Quadril 100%% apoiado no assento (y=%.2fm), encosto suportado e pernas alinhadas!" % hips_bottom_y)

	# Limpeza
	table.queue_free()
	player.queue_free()
	cust.queue_free()
	emp.queue_free()
	clock.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE AJUSTE FINAL DOS NPCs FORAM APROVADOS!")
	print("============================================================")
	quit(0)
