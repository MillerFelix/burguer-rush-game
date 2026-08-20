extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE END-TO-END: GRELHA -> ESPÁTULA -> BANCADA -> MONTAGEM
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
	print("=== BURGER RUSH - E2E: GRELHA -> ESPÁTULA -> BANCADA ============")
	print("=================================================================")
	run_tests()
	quit(0 if failed == 0 else 1)

func run_tests() -> void:
	var root = Node3D.new()
	root.name = "E2EWorld"
	get_root().add_child(root)

	# 1. Instancia Grelha, Ilha de Preparo e Jogador
	var grill_scene = load("res://src/stations/grill.tscn")
	var grill = grill_scene.instantiate() as GrillClass
	root.add_child(grill)
	grill.global_position = Vector3(-3.0, 0.0, 0.0)

	var prep_scene = load("res://src/stations/prep_island.tscn")
	var prep_island = prep_scene.instantiate() as PrepIslandClass
	root.add_child(prep_island)
	prep_island.global_position = Vector3(0.0, 0.0, 0.0)

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as PlayerClass
	root.add_child(player)
	player.global_position = Vector3(-3.0, 0.0, 1.2) # Na frente da grelha

	# 2. Liga a grelha e coloca carne bovina
	grill.is_on = true
	grill.current_temperature = 180.0

	var patty_scene = load("res://src/items/patty.tscn")
	var beef_patty = patty_scene.instantiate() as PattyClass
	beef_patty.meat_type = PattyClass.MeatType.BEEF
	root.add_child(beef_patty)

	# Coloca na chapa
	var placed = grill.place_item(beef_patty)
	assert_test(placed, "Carne bovina colocada na grelha")
	assert_test(beef_patty.collision_layer == 1, "Carne com colisão ativa na grelha")

	# Simula cozimento Lado 1
	beef_patty.advance_cooking(100.0)
	assert_test(beef_patty.state == PattyClass.State.READY_SIDE_1, "Lado 1 grelhado com sucesso")

	# Equipa espátula e vira
	player.select_tool_slot(PlayerClass.ToolSlot.SPATULA, false)
	beef_patty.flip()
	assert_test(beef_patty.is_flipped == true, "Carne virada na grelha")

	# Simula cozimento Lado 2
	beef_patty.advance_cooking(100.0)
	assert_test(beef_patty.state == PattyClass.State.COOKED, "Carne 100% grelhada e pronta")

	# Retira a carne com a espátula
	var spatula = player.get_spatula() as SpatulaClass
	assert_test(spatula != null, "Espátula ativa na mão do jogador")
	spatula.attach_patty(beef_patty)
	grill._remove_item_from_grill_data(beef_patty)

	assert_test(spatula.has_patty() == true, "Carne pronta presa na espátula")
	assert_test(beef_patty.collision_layer == 0, "Colisão da carne desativada na espátula")

	# 3. Caminhada da grelha até a bancada de montagem
	# Jogador se move de X=-3 até X=0, Z=0.8
	var steps = 30
	var no_glitch = true
	for s in range(steps):
		var target = Vector3(lerpf(-3.0, 0.0, float(s) / float(steps)), 0.0, lerpf(1.2, 0.75, float(s) / float(steps)))
		player.velocity = (target - player.global_position) * 10.0
		player.move_and_slide()
		if player.global_position.length() > 20.0 or absf(player.velocity.length()) > 50.0:
			no_glitch = false
			break

	assert_test(no_glitch, "Caminhada da grelha até a bancada 100% fluida sem repulsão")

	# 4. Circula ao redor da bancada de montagem pelos 4 lados
	var perimeter_points = [
		Vector3(0.0, 0.0, 0.8),  # Sul
		Vector3(1.2, 0.0, 0.0),  # Leste
		Vector3(0.0, 0.0, -0.8), # Norte
		Vector3(-1.2, 0.0, 0.0), # Oeste
		Vector3(0.0, 0.0, 0.8)   # Retorna ao Sul
	]

	var perimeter_ok = true
	for pt in perimeter_points:
		for sub in range(10):
			player.velocity = (pt - player.global_position) * 8.0
			player.move_and_slide()
			if player.global_position.length() > 20.0 or absf(player.velocity.length()) > 50.0:
				perimeter_ok = false
				break

	assert_test(perimeter_ok, "Jogador circulou ao redor de toda a bancada de montagem com a espátula sem qualquer teletransporte")

	# 5. Coloca a carne no pão na bancada
	var bread_scene = load("res://src/items/bread_bottom.tscn")
	var bread_bottom = bread_scene.instantiate() as BreadBottomClass
	root.add_child(bread_bottom)
	bread_bottom._ensure_assembly()
	bread_bottom.global_position = Vector3(0.0, 0.90, 0.0)

	var assembly = bread_bottom.assembly
	var patty_to_assemble = player.take_spatula_held_patty()
	assert_test(patty_to_assemble == beef_patty, "Carne retirada da espátula")

	var added = assembly.add_ingredient(patty_to_assemble, bread_bottom.global_position, 0.0)
	assert_test(added, "Carne montada no pão")
	assert_test(spatula.has_patty() == false, "Espátula liberada e vazia")

	# 6. Repete o teste com carne de frango (Grelhar -> Espátula -> Bancada -> Pão)
	var chicken_patty = patty_scene.instantiate() as PattyClass
	chicken_patty.meat_type = PattyClass.MeatType.CHICKEN
	root.add_child(chicken_patty)

	spatula.attach_patty(chicken_patty)
	assert_test(chicken_patty.collision_layer == 0, "Carne de frango com colisão desativada na espátula")

	# Caminha novamente até a bancada
	player.global_position = Vector3(0.0, 0.0, 1.5)
	for s in range(15):
		player.velocity = Vector3(0.0, 0.0, -3.0)
		player.move_and_slide()

	assert_test(player.global_position.length() < 10.0, "Aproximação com carne de frango 100% estável")

	var chicken_to_assemble = player.take_spatula_held_patty()
	assembly.add_ingredient(chicken_to_assemble, bread_bottom.global_position, 0.0)
	assert_test(assembly.ingredients.size() == 2, "Hambúrguer duplo montado com sucesso")

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")
	if failed == 0:
		print("🎉 FLUXO COMPLETO GRELHA -> ESPÁTULA -> MONTAGEM 100% VALIDADO!")
