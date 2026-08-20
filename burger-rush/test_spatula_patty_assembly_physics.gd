extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DE FÍSICA E INTERAÇÃO: ESPÁTULA, CARNE E BANCADA
# ==============================================================================

const PlayerClass = preload("res://src/player/player.gd")
const SpatulaClass = preload("res://src/tools/spatula.gd")
const PattyClass = preload("res://src/items/patty.gd")
const GrillClass = preload("res://src/stations/grill.gd")
const PrepIslandClass = preload("res://src/stations/prep_island.gd")
const BreadBottomClass = preload("res://src/items/bread_bottom.gd")
const BurgerAssemblyClass = preload("res://src/recipes/burger_assembly.gd")

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
	print("\n=================================================================")
	print("=== TESTE DE FÍSICA: ESPÁTULA, CARNE E BANCADA DE MONTAGEM ======")
	print("=================================================================")
	run_tests()
	quit(0 if failed == 0 else 1)

func run_tests() -> void:
	var root = Node3D.new()
	root.name = "TestWorld"
	get_root().add_child(root)

	# --------------------------------------------------------------------------
	# TESTE 1: Espátula e Desativação de Colisão da Carne
	# --------------------------------------------------------------------------
	print("\n--- TESTE 1: Fixação da Carne na Espátula e Camadas de Colisão ---")
	var spatula_scene = load("res://src/tools/spatula.tscn")
	var spatula = spatula_scene.instantiate() as SpatulaClass
	root.add_child(spatula)

	var patty_scene = load("res://src/items/patty.tscn")
	var beef_patty = patty_scene.instantiate() as PattyClass
	root.add_child(beef_patty)
	beef_patty.collision_layer = 1
	beef_patty.collision_mask = 1

	# Prende a carne na espátula
	spatula.attach_patty(beef_patty)

	assert_test(spatula.has_patty(), "Carne reconhecida na espátula")
	assert_test(beef_patty.collision_layer == 0, "collision_layer da carne zerado ao prender na espátula")
	assert_test(beef_patty.collision_mask == 0, "collision_mask da carne zerado ao prender na espátula")
	
	var col_shape = beef_patty.get_node_or_null("CollisionShape3D") as CollisionShape3D
	assert_test(col_shape != null and col_shape.disabled == true, "CollisionShape3D da carne desativado na espátula")

	# --------------------------------------------------------------------------
	# TESTE 2: Movimentação do Jogador Próximo da Bancada de Montagem
	# --------------------------------------------------------------------------
	print("\n--- TESTE 2: Aproximação da Bancada de Montagem com Carne na Espátula ---")
	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as PlayerClass
	root.add_child(player)
	player.global_position = Vector3(0, 0, 3)

	# Equipa espátula no jogador
	player.select_tool_slot(PlayerClass.ToolSlot.SPATULA, false)
	var player_spatula = player.get_spatula()
	assert_test(player_spatula != null, "Espátula equipada no jogador")

	# Cria carne e fixa na espátula do jogador
	var chicken_patty = patty_scene.instantiate() as PattyClass
	chicken_patty.meat_type = PattyClass.MeatType.CHICKEN
	root.add_child(chicken_patty)
	player_spatula.attach_patty(chicken_patty)

	assert_test(player.get_spatula_held_patty() == chicken_patty, "Carne de frango fixada na espátula do jogador")
	assert_test(chicken_patty.collision_layer == 0, "collision_layer da carne de frango zerado")

	# Instancia a bancada de montagem (PrepIsland)
	var prep_scene = load("res://src/stations/prep_island.tscn")
	var prep_island = prep_scene.instantiate() as PrepIslandClass
	root.add_child(prep_island)
	prep_island.global_position = Vector3(0, 0, 0)

	# Simula aproximação do jogador em direção à bancada pelos 4 lados
	var initial_y = player.global_position.y
	var test_directions = [
		Vector3(0, 0, -1), # Frente (Sul -> Norte)
		Vector3(0, 0, 1),  # Trás (Norte -> Sul)
		Vector3(1, 0, 0),  # Lado Leste
		Vector3(-1, 0, 0)  # Lado Oeste
	]

	var no_teleport = true
	for dir in test_directions:
		player.global_position = prep_island.global_position + dir * 1.5
		for f in range(20):
			player.velocity = -dir * 3.0 # Move em direção à bancada
			player.move_and_slide()
			
			# Verifica se a velocidade ou posição sofreram anomalia de teletransporte
			if player.global_position.length() > 50.0 or absf(player.velocity.x) > 50.0 or absf(player.velocity.z) > 50.0:
				no_teleport = false
				break

	assert_test(no_teleport, "Jogador não sofreu teletransporte ou aceleração anômala ao colidir com a bancada")

	# --------------------------------------------------------------------------
	# TESTE 3: Depósito da Carne na Bancada / Pão
	# --------------------------------------------------------------------------
	print("\n--- TESTE 3: Depósito da Carne na Bancada e Montagem no Pão ---")
	# Cria base do pão na bancada
	var bread_scene = load("res://src/items/bread_bottom.tscn")
	var bread_bottom = bread_scene.instantiate() as BreadBottomClass
	root.add_child(bread_bottom)
	bread_bottom._ensure_assembly()
	bread_bottom.global_position = Vector3(0, 0.90, 0)

	var assembly = bread_bottom.assembly
	assert_test(assembly != null, "BurgerAssembly presente na base do pão")

	# Posiciona jogador olhando para o pão e deposita a carne
	player.global_position = Vector3(0, 0, 0.8)
	var deposit_patty = player.take_spatula_held_patty()
	assert_test(deposit_patty == chicken_patty, "Carne retirada da espátula para montagem")

	var added = assembly.add_ingredient(deposit_patty, bread_bottom.global_position, 0.0)
	assert_test(added == true, "Carne adicionada ao BurgerAssembly com sucesso")
	assert_test(assembly.ingredients.size() == 1, "Ingrediente registrado no lanche")
	assert_test(deposit_patty.collision_mask == 0, "Ingrediente montado com collision_mask = 0 para prevenir conflito físico")

	# --------------------------------------------------------------------------
	# TESTE 4: Pegar o Lanche Inteiro e Andar pelo Restaurante
	# --------------------------------------------------------------------------
	print("\n--- TESTE 4: Transporte do Lanche Montado sem Conflito Físico ---")
	player.pick_up(bread_bottom)
	assert_test(player.held_item == bread_bottom, "Lanche completo seguro na mão do jogador")
	assert_test(bread_bottom.collision_layer == 0, "Base do pão com collision_layer = 0 na mão")
	assert_test(deposit_patty.collision_layer == 0, "Ingredientes internos com collision_layer = 0 na mão")

	# Move jogador carregando o lanche montado encostando na bancada
	player.global_position = Vector3(0, 0, 1.0)
	for f in range(20):
		player.velocity = Vector3(0, 0, -3.0)
		player.move_and_slide()

	assert_test(player.global_position.length() < 10.0, "Jogador seguro carregando o lanche sem repulsão física")

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")
	if failed == 0:
		print("🎉 CONFLITO DE FÍSICA ESPÁTULA/BANCADA CORRIGIDO COM SUCESSO!")
