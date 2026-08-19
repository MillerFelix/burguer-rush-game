extends SceneTree

# ================================================================
# TESTE E2E DEFINITIVO: MONTAGEM, GRELHA, BANDEJA E SLOTS RÁPIDOS
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
	print("=== TESTE E2E DEFINITIVO: MONTAGEM, GRELHA E BANDEJA ===")
	print("=======================================================\n")

	var player_scene = load("res://src/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)

	# 1. Testando Grelha com Slot Rápido
	print("--- 1. Colocar Carne na Grelha a partir do Slot 4 ---")
	var grill_scene = load("res://src/stations/grill.tscn")
	var grill: Grill = grill_scene.instantiate() as Grill
	root.add_child(grill)
	grill.is_on = true

	var raw_patty = load("res://src/items/patty.tscn").instantiate() as Patty
	player.pick_up(raw_patty)
	assert_test(player.quick_slots[0].get("item_id") == "patty_beef", "Carne crua no Slot 4")
	assert_test(player.is_hand_free() == true, "Mão livre antes de interagir com a grelha")

	grill.interact_item(player)
	assert_test(grill.active_items.size() == 1, "Carne colocada na grelha com sucesso")
	assert_test(player.quick_slots[0].is_empty(), "Slot 4 esvaziado após colocar a carne na grelha")
	assert_test(player.held_item == null, "Mão continua livre após colocar carne")

	# Simula o cozimento completo da carne na grelha
	var grill_patty = grill.active_items[0]["item"] as Patty
	grill_patty.state = Patty.State.COOKED
	grill_patty.side_a_cooked = 100.0
	grill_patty.side_b_cooked = 100.0
	grill_patty.is_flipped = true

	# Retira a carne pronta da grelha usando Espátula (Tecla 1)
	player.select_tool_slot(Player.ToolSlot.SPATULA, false)
	grill.interact_item(player)
	assert_test(grill.active_items.is_empty(), "Grelha esvaziada após retirar a carne")
	assert_test(player.quick_slots[0].get("item_id") == "patty_beef", "Carne pronta recolhida para o Slot 4")
	assert_test(player.held_item == null, "Mão principal continua LIVRE com a espátula equipada")

	# 2. Testando Montagem de Burger com Ingredientes dos Slots Rápidos
	print("\n--- 2. Montagem de Burger com Ingredientes dos Slots Rápidos ---")
	player.select_tool_slot(Player.ToolSlot.HANDS, false)

	var cheese = load("res://src/items/cheese.tscn").instantiate()
	var tomato = load("res://src/items/tomato.tscn").instantiate()
	player.pick_up(cheese)
	player.pick_up(tomato)

	assert_test(player.quick_slots[0].get("item_id") == "patty_beef", "Slot 4: Carne Pronta")
	assert_test(player.quick_slots[1].get("item_id") == "cheese", "Slot 5: Queijo")
	assert_test(player.quick_slots[2].get("item_id") == "tomato", "Slot 6: Tomate")
	assert_test(player.held_item == null, "Mão livre com 3 ingredientes nos slots")

	# Instancia a Base do Pão no mundo
	var bread_scene = load("res://src/items/bread_bottom.tscn")
	var base_bun: BreadBottom = bread_scene.instantiate() as BreadBottom
	root.add_child(base_bun)

	# Adiciona Carne (Slot 4)
	player.select_quick_slot(0, false)
	base_bun.interact_item(player)
	assert_test(base_bun.assembly.ingredients.size() == 1, "Carne adicionada ao lanche")
	assert_test(player.quick_slots[0].is_empty(), "Slot 4 esvaziado")

	# Adiciona Queijo (Slot 5)
	player.select_quick_slot(1, false)
	base_bun.interact_item(player)
	assert_test(base_bun.assembly.ingredients.size() == 2, "Queijo adicionado ao lanche")
	assert_test(player.quick_slots[1].is_empty(), "Slot 5 esvaziado")

	# Adiciona Tomate (Slot 6)
	player.select_quick_slot(2, false)
	base_bun.interact_item(player)
	assert_test(base_bun.assembly.ingredients.size() == 3, "Tomate adicionado ao lanche")
	assert_test(player.quick_slots[2].is_empty(), "Slot 6 esvaziado")

	# Pega pão superior (Tampa do Pão) para fechar
	var top_bun = load("res://src/items/bread_top.tscn").instantiate()
	player.pick_up(top_bun)
	assert_test(player.quick_slots[0].get("item_id") == "bread_top", "Tampa do Pão no Slot 4")
	assert_test(player.held_item == null, "Mão continua livre")

	# Fecha o lanche
	player.select_quick_slot(0, false)
	base_bun.interact_item(player)
	assert_test(base_bun.assembly.state == BurgerAssembly.State.CLOSED, "Lanche fechado com sucesso (CLOSED)")
	assert_test(player.quick_slots[0].is_empty(), "Slot 4 esvaziado")

	# 3. Testando Pegar o Burger Montado para a Mão Principal
	print("\n--- 3. Pegar o Burger Montado para a Mão Principal ---")
	base_bun.interact_item(player)
	assert_test(player.held_item == base_bun, "Burger montado pego na Mão Principal")
	assert_test(player.is_holding_large_item() == true, "is_holding_large_item() é true")

	# 4. Testando Coexistência: 3 Ingredientes + Bandeja na Mão
	print("\n--- 4. Coexistência: Bandeja na Mão + 3 Ingredientes nos Slots ---")
	# Solta o burger na mesa/mundo
	player.drop_item()
	assert_test(player.held_item == null, "Mão livre após soltar o burger")

	# Pega 3 novos ingredientes
	var ing1 = load("res://src/items/patty.tscn").instantiate()
	var ing2 = load("res://src/items/lettuce.tscn").instantiate()
	var ing3 = load("res://src/items/onion.tscn").instantiate()
	player.pick_up(ing1)
	player.pick_up(ing2)
	player.pick_up(ing3)

	# Pega uma Bandeja
	var tray = load("res://src/items/serving_tray.tscn").instantiate() as ServingTray
	root.add_child(tray)
	player.pick_up(tray)

	assert_test(player.held_item == tray, "Mão segura a Bandeja")
	assert_test(player.quick_slots[0].get("item_id") == "patty_beef", "Slot 4 contém Carne")
	assert_test(player.quick_slots[1].get("item_id") == "lettuce", "Slot 5 contém Alface")
	assert_test(player.quick_slots[2].get("item_id") == "onion", "Slot 6 contém Cebola")

	# Coloca o burger na bandeja enquanto segura a bandeja
	base_bun.interact_item(player)
	assert_test(tray.carried_items.size() == 1, "Burger adicionado à bandeja segurada")
	assert_test(player.quick_slots[0].get("item_id") == "patty_beef", "Slot 4 continua intacto com Carne")
	assert_test(player.quick_slots[1].get("item_id") == "lettuce", "Slot 5 continua intacto com Alface")
	assert_test(player.quick_slots[2].get("item_id") == "onion", "Slot 6 continua intacto com Cebola")

	# Solta a bandeja
	player.drop_item()
	assert_test(player.held_item == null, "Mão livre após soltar a bandeja")
	assert_test(player.quick_slots[0].get("item_id") == "patty_beef", "Slot 4 100% preservado")
	assert_test(player.quick_slots[1].get("item_id") == "lettuce", "Slot 5 100% preservado")
	assert_test(player.quick_slots[2].get("item_id") == "onion", "Slot 6 100% preservado")

	print("\n=======================================================")
	print("RESULTADO DOS TESTES E2E: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=======================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS TESTES E2E PASSARAM COM SUCESSO! <<<\n")
	else:
		printerr(">>> ALGUNS TESTES E2E FALHARAM! <<<\n")

	quit(0 if passed_tests == total_tests else 1)
