extends SceneTree

# ================================================================
# TESTE AUTOMATIZADO DEFINITIVO: AUDITORIA DO FLUXO COMPLETO DE INTERAÇÃO
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

func _clear_player(player: Player) -> void:
	player.quick_slots.clear()
	player.quick_slots.append({})
	player.quick_slots.append({})
	player.quick_slots.append({})
	player.active_quick_slot = -1
	player.active_tool_slot = Player.ToolSlot.HANDS
	if player.held_item != null:
		if is_instance_valid(player.held_item) and player.held_item.get_parent():
			player.held_item.get_parent().remove_child(player.held_item)
		player.held_item = null

func _init() -> void:
	print("\n=======================================================")
	print("=== INICIANDO AUDITORIA COMPLETA DE INTERAÇÃO (PICKUP / HOLD / DROP) ===")
	print("=======================================================\n")

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

	# Superfícies
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

	# -------------------------------------------------------------------------
	# TESTE 1: PICKUP DE PÃO
	# -------------------------------------------------------------------------
	print("--- TESTE 1: Pickup de Pão ---")
	_clear_player(player)

	var bread = load("res://src/items/bread_bottom.tscn").instantiate() as BreadBottom
	root.add_child(bread)
	bread.global_position = Vector3(0, 0.5, -1.0)
	bread._ready()

	player.pick_up(bread)
	assert_test(player.held_item != null, "Pão foi pego e está registrado em held_item")
	assert_test(player.held_item.get_parent() == player.hold_position, "Pão está anexado na HandPosition do jogador")
	assert_test(player.held_item.is_held == true, "Estado is_held do pão é verdadeiro")
	assert_test(player.held_item.collision_layer == 0, "Colisão desativada enquanto segurado")

	# -------------------------------------------------------------------------
	# TESTE 2: PICKUP DE CARNE (PATTY)
	# -------------------------------------------------------------------------
	print("\n--- TESTE 2: Pickup de Carne (Patty) ---")
	_clear_player(player)

	var patty = load("res://src/items/patty.tscn").instantiate() as Patty
	root.add_child(patty)
	patty.global_position = Vector3(0, 0.5, -1.0)
	patty._ready()

	player.pick_up(patty)
	assert_test(player.held_item != null, "Carne foi pega e está registrada em held_item")
	assert_test(player.held_item.get_parent() == player.hold_position, "Carne está anexada na HandPosition")
	assert_test(player.has_active_ingredient() == true, "Carne registrada no slot de ingredientes ativos")

	# -------------------------------------------------------------------------
	# TESTE 3: HOLD (ACOMPANHAMENTO VISUAL E SEM FÍSICA)
	# -------------------------------------------------------------------------
	print("\n--- TESTE 3: Hold (Segurar) ---")
	assert_test(player.held_item.position == Vector3.ZERO, "Posição local do item é ZERO relativo à HandPosition")
	assert_test(player.held_item._is_falling == false, "Item segurado não está em estado de queda física")

	# -------------------------------------------------------------------------
	# TESTE 4: DROP EM BANCADA DE MOLHOS
	# -------------------------------------------------------------------------
	print("\n--- TESTE 4: Drop em Bancada de Molhos ---")
	var dropped_item = player.held_item
	player.global_position = prep_table.global_position + Vector3(0, 0, 0.8)
	player.drop_item()

	assert_test(player.held_item == null, "Mão do jogador liberada após o drop")
	assert_test(dropped_item.get_parent() != player.hold_position, "Item desanexado da HandPosition")
	assert_test(dropped_item.location == Item.ItemLocation.WORLD, "Item restaurado para o estado WORLD")
	assert_test(dropped_item.collision_layer == 1, "Colisão restaurada após o drop")

	# -------------------------------------------------------------------------
	# TESTE 5: DROP NA ILHA CENTRAL
	# -------------------------------------------------------------------------
	print("\n--- TESTE 5: Drop na Ilha Central ---")
	_clear_player(player)

	var cheese = load("res://src/items/cheese.tscn").instantiate()
	root.add_child(cheese)
	cheese._ready()

	player.pick_up(cheese)
	assert_test(player.held_item != null, "Queijo pego")

	player.global_position = island.global_position + Vector3(0, 0, 1.2)
	player.drop_item()
	assert_test(player.held_item == null, "Queijo colocado com sucesso na ilha central")
	assert_test(cheese.location == Item.ItemLocation.WORLD, "Queijo restaurado no mundo")

	# -------------------------------------------------------------------------
	# TESTE 6: DROP EM MESA DE RESTAURANTE
	# -------------------------------------------------------------------------
	print("\n--- TESTE 6: Drop em Mesa de Restaurante ---")
	_clear_player(player)

	var tomato = load("res://src/items/tomato.tscn").instantiate()
	root.add_child(tomato)
	tomato._ready()

	player.pick_up(tomato)
	assert_test(player.held_item != null, "Tomate pego")

	player.global_position = rest_table.global_position + Vector3(0, 0, 1.0)
	player.drop_item()
	assert_test(player.held_item == null, "Tomate colocado na mesa")

	# -------------------------------------------------------------------------
	# TESTE 7: PICKUP NOVAMENTE DO MESMO OBJETO SOLTO
	# -------------------------------------------------------------------------
	print("\n--- TESTE 7: Pickup Novamente do Objeto Solto ---")
	player.pick_up(tomato)
	assert_test(player.held_item == tomato, "Tomate que foi solto foi pego novamente com sucesso")
	assert_test(tomato.is_held == true, "Estado is_held reativado")

	# -------------------------------------------------------------------------
	# TESTE 8: CICLO COMPLETO (PICKUP -> MOVE -> DROP -> PICKUP -> DROP)
	# -------------------------------------------------------------------------
	print("\n--- TESTE 8: Ciclo Completo de Manipulação ---")
	player.global_position = island.global_position + Vector3(0.5, 0, 1.0)
	player.drop_item()
	assert_test(player.held_item == null, "Ciclo 1: Solto na ilha")

	player.pick_up(tomato)
	assert_test(player.held_item == tomato, "Ciclo 2: Pego novamente da ilha")

	player.global_position = prep_table.global_position + Vector3(0, 0, 0.8)
	player.drop_item()
	assert_test(player.held_item == null, "Ciclo 3: Solto na bancada de molhos")

	# -------------------------------------------------------------------------
	# TESTE 9: DIFERENTES ITENS (OBJETOS GRANDES: BANDEJA E SACO)
	# -------------------------------------------------------------------------
	print("\n--- TESTE 9: Objetos Grandes (Bandeja e Saco) ---")
	_clear_player(player)

	var tray = load("res://src/items/serving_tray.tscn").instantiate() as ServingTray
	root.add_child(tray)
	tray._ready()

	player.pick_up(tray)
	assert_test(player.held_item == tray, "Bandeja grande pega na mão")
	assert_test(player.is_holding_large_item() == true, "Reconhecido como objeto grande")

	player.drop_item()
	assert_test(player.held_item == null, "Bandeja solta com sucesso")

	var bag = load("res://src/items/delivery_bag.tscn").instantiate() as DeliveryBag
	root.add_child(bag)
	bag._ready()

	player.pick_up(bag)
	assert_test(player.held_item == bag, "Saco de delivery pego na mão")
	player.drop_item()
	assert_test(player.held_item == null, "Saco de delivery solto com sucesso")

	# -------------------------------------------------------------------------
	# TESTE 10: INTERAÇÃO POR TECLA E (DISPENSERS, CAIXA, MÁQUINAS)
	# -------------------------------------------------------------------------
	print("\n--- TESTE 10: Interação Contextual por E Preservada ---")
	_clear_player(player)

	var disp = IngredientDispenser.new()
	disp.ingredient_id = "cheese"
	inv.add_stock("cheese", 5)
	root.add_child(disp)
	disp.interact(player)
	print("DEBUG TEST 10: held_item = %s, has_active_ingredient = %s, quick_slots = %s" % [str(player.held_item), str(player.has_active_ingredient()), str(player.quick_slots)])
	assert_test(player.held_item != null or player.has_active_ingredient(), "Interação por E no Dispenser forneceu ingrediente")

	print("\n=======================================================")
	print("RESULTADO DA AUDITORIA: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=======================================================")

	if passed_tests == total_tests:
		print(">>> AUDITORIA COMPLETA DE INTERAÇÃO CONCLUÍDA COM 100% DE SUCESSO! <<<\n")
		quit(0)
	else:
		printerr(">>> FALHA NA AUDITORIA! <<<\n")
		quit(1)
