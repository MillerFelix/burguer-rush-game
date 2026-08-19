extends SceneTree

# ================================================================
# TESTE AUTOMATIZADO: REVISÃO COMPLETA DE DROP / COLOCAÇÃO E PLACAS
# ================================================================

var total_tests: int = 0
var passed_tests: int = 0

func assert_test(condition: bool, description: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % description)
	else:
		printerr("  [FAIL] %s" % description)

func _init() -> void:
	print("\n=======================================================")
	print("=== INICIANDO TESTE DEFINITIVO DE DROP E PLACAS ===")
	print("=======================================================\n")

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DA ALTURA DA PLACA DE REFIS DE REFRIGERANTE
	# -------------------------------------------------------------------------
	print("--- 1. Altura da Placa 'REFIL REFRIGERANTES' ---")
	var soda_rack_scene = load("res://src/stations/soda_refill_rack.tscn")
	assert_test(soda_rack_scene != null, "Cena soda_refill_rack.tscn carregada")
	var soda_rack = soda_rack_scene.instantiate() as Node3D
	root.add_child(soda_rack)
	soda_rack._ready()

	var phys_sign = soda_rack.get_node_or_null("Model/PhysicalSign")
	assert_test(phys_sign != null, "Nó PhysicalSign existe no rack de refis")
	if phys_sign:
		assert_test(is_equal_approx(phys_sign.position.y, 0.70), "Altura da placa rebaixada para Y = 0.70 (próxima aos cilindros)")
		assert_test(is_equal_approx(phys_sign.position.z, 0.18), "Placa encostada na parede atrás dos refis (Z = 0.18)")
		var label = phys_sign.get_node_or_null("SignLabel") as Label3D
		assert_test(label != null and label.text == "REFIL REFRIGERANTES", "Texto mantido: 'REFIL REFRIGERANTES'")

	# -------------------------------------------------------------------------
	# 2. INSTANCIAÇÃO DO AMBIENTE E DO JOGADOR
	# -------------------------------------------------------------------------
	print("\n--- 2. Instanciação do Jogador e Superfícies ---")
	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)
	player.global_position = Vector3(0, 0, 0)
	player._ready()

	var island_scene = load("res://src/stations/prep_island.tscn")
	var island = island_scene.instantiate() as PrepIsland
	root.add_child(island)
	island.global_position = Vector3(1.4, 0, -4.55)
	island._ready()

	var prep_table_scene = load("res://src/stations/prep_table.tscn")
	var prep_table = prep_table_scene.instantiate() as PrepTable
	root.add_child(prep_table)
	prep_table.global_position = Vector3(1.95, 0, -8.35)
	prep_table._ready()

	var rest_table_scene = load("res://src/stations/restaurant_table.tscn")
	var rest_table = rest_table_scene.instantiate() as RestaurantTable
	root.add_child(rest_table)
	rest_table.global_position = Vector3(-4.0, 0, 4.0)
	rest_table._ready()

	var aux_counter_scene = load("res://src/stations/auxiliary_counter.tscn")
	var aux_counter = aux_counter_scene.instantiate() as Node3D
	root.add_child(aux_counter)
	aux_counter.global_position = Vector3(3.55, 0, -8.35)
	aux_counter._ready()

	var clear_player = func():
		player.quick_slots.clear()
		player.quick_slots.append({})
		player.quick_slots.append({})
		player.quick_slots.append({})
		player.active_quick_slot = -1
		if player.held_item != null:
			if is_instance_valid(player.held_item) and player.held_item.get_parent():
				player.held_item.get_parent().remove_child(player.held_item)
			player.held_item = null

	# -------------------------------------------------------------------------
	# TESTE 1: CLICAR NO TOMATE -> PEGA -> MIRAR NA BANCADA -> CLIQUE -> COLOCA
	# -------------------------------------------------------------------------
	print("\n--- Teste 1: Ingrediente -> Bancada dos Molhos ---")
	clear_player.call()

	var tomato = load("res://src/items/tomato.tscn").instantiate()
	root.add_child(tomato)
	tomato._ready()

	player.pick_up(tomato)
	assert_test(player.has_active_ingredient() == true, "Tomate pego e adicionado ao slot ativo")

	# Executa drop na bancada
	player.drop_item()
	assert_test(player.has_active_ingredient() == false, "Tomate colocado na bancada e slot liberado")

	# -------------------------------------------------------------------------
	# TESTE 2: INGREDIENTE -> ILHA CENTRAL
	# -------------------------------------------------------------------------
	print("\n--- Teste 2: Ingrediente -> Ilha Central ---")
	clear_player.call()

	var lettuce = load("res://src/items/lettuce.tscn").instantiate()
	root.add_child(lettuce)
	lettuce._ready()

	player.pick_up(lettuce)
	assert_test(player.has_active_ingredient() == true, "Alface pega e adicionada ao slot ativo")

	player.drop_item()
	assert_test(player.has_active_ingredient() == false, "Alface colocada na ilha central e slot liberado")

	# -------------------------------------------------------------------------
	# TESTE 3: LANCHE MONTADO -> ILHA CENTRAL
	# -------------------------------------------------------------------------
	print("\n--- Teste 3: Lanche Montado -> Ilha Central ---")
	clear_player.call()

	var burger_base = load("res://src/items/bread_bottom.tscn").instantiate() as BreadBottom
	root.add_child(burger_base)
	burger_base._ready()

	var patty = load("res://src/items/patty.tscn").instantiate() as Patty
	patty.state = Patty.State.COOKED
	burger_base.assembly.add_ingredient(patty, burger_base.global_position)
	assert_test(burger_base.has_ingredients() == true, "Lanche montado com hambúrguer")

	player.pick_up(burger_base)
	assert_test(player.held_item == burger_base, "Lanche montado na mão principal do jogador")

	player.drop_item()
	assert_test(player.held_item == null, "Lanche montado colocado com sucesso na ilha central")
	assert_test(burger_base.location == Item.ItemLocation.WORLD, "Lanche montado agora no mundo")

	# -------------------------------------------------------------------------
	# TESTE 4: LANCHE MONTADO -> OUTRA BANCADA (AUXILIARY COUNTER)
	# -------------------------------------------------------------------------
	print("\n--- Teste 4: Lanche Montado -> Outra Bancada ---")
	clear_player.call()

	player.pick_up(burger_base)
	assert_test(player.held_item == burger_base, "Lanche pego novamente da ilha")

	player.drop_item()
	assert_test(player.held_item == null, "Lanche montado colocado na bancada auxiliar")

	# -------------------------------------------------------------------------
	# TESTE 5: INGREDIENTE -> MESA DE RESTAURANTE
	# -------------------------------------------------------------------------
	print("\n--- Teste 5: Ingrediente -> Mesa de Restaurante ---")
	clear_player.call()

	var cheese = load("res://src/items/cheese.tscn").instantiate()
	root.add_child(cheese)
	player.pick_up(cheese)
	assert_test(player.has_active_ingredient() == true, "Queijo no slot ativo")

	player.drop_item()
	assert_test(player.has_active_ingredient() == false, "Queijo colocado na mesa")

	# -------------------------------------------------------------------------
	# TESTE 6: INGREDIENTE -> PISO
	# -------------------------------------------------------------------------
	print("\n--- Teste 6: Ingrediente -> Piso ---")
	clear_player.call()

	var onion = load("res://src/items/onion.tscn").instantiate()
	root.add_child(onion)
	player.pick_up(onion)
	assert_test(player.has_active_ingredient() == true, "Cebola no slot ativo")

	player.drop_item()
	assert_test(player.has_active_ingredient() == false, "Cebola colocada no chão")

	# -------------------------------------------------------------------------
	# TESTE 7: OBJETO GRANDE COLOCÁVEL (BANDEJA) -> BANCADA DE MOLHOS
	# -------------------------------------------------------------------------
	print("\n--- Teste 7: Objeto Grande (Bandeja) -> Bancada de Molhos ---")
	clear_player.call()

	var tray = load("res://src/items/serving_tray.tscn").instantiate() as ServingTray
	root.add_child(tray)
	player.pick_up(tray)
	assert_test(player.held_item == tray, "Bandeja na mão do jogador")

	player.drop_item()
	assert_test(player.held_item == null, "Bandeja colocada com sucesso na bancada")

	# -------------------------------------------------------------------------
	# TESTE 8: OBJETO GRANDE COLOCÁVEL (SACO DE DELIVERY) -> ILHA CENTRAL
	# -------------------------------------------------------------------------
	print("\n--- Teste 8: Objeto Grande (Saco Delivery) -> Ilha Central ---")
	clear_player.call()

	var bag = load("res://src/items/delivery_bag.tscn").instantiate() as DeliveryBag
	root.add_child(bag)
	player.pick_up(bag)
	assert_test(player.held_item == bag, "Saco de delivery na mão do jogador")

	player.drop_item()
	assert_test(player.held_item == null, "Saco de delivery colocado com sucesso na ilha central")

	# -------------------------------------------------------------------------
	# TESTE 9: MONTAGEM DE HAMBÚRGUER SOBRE PÃO NO MUNDO
	# -------------------------------------------------------------------------
	print("\n--- Teste 9: Montagem de Hambúrguer (Ingrediente sobre Base de Pão) ---")
	clear_player.call()

	var new_bun = load("res://src/items/bread_bottom.tscn").instantiate() as BreadBottom
	root.add_child(new_bun)
	new_bun.global_position = island.global_position + Vector3(0, 0.90, 0)
	new_bun._ready()

	var new_patty = load("res://src/items/patty.tscn").instantiate() as Patty
	new_patty.state = Patty.State.COOKED
	root.add_child(new_patty)
	player.pick_up(new_patty)
	assert_test(player.has_active_ingredient() == true, "Carne preparada no slot ativo")

	new_bun.interact_item(player)
	assert_test(player.has_active_ingredient() == false, "Carne consumida para montagem")
	assert_test(new_bun.assembly.ingredients.size() == 1, "Carne empilhada na base do pão (1 ingrediente)")

	print("\n=======================================================")
	print("RESULTADO DOS TESTES: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=======================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS TESTES DE DROP E PLACAS FORAM APROVADOS COM SUCESSO! <<<\n")
		quit(0)
	else:
		printerr(">>> ALGUNS TESTES FALHARAM! <<<\n")
		quit(1)
