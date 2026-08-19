extends SceneTree

var passed_tests: int = 0
var total_tests: int = 0

func assert_test(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		print("  [FAIL] %s" % test_name)

func _init() -> void:
	print("\n=================================================================")
	print("=== TESTE DE RETIRADA INDIVIDUAL DE ITENS DA BANDEJA (LMB) ===")
	print("=================================================================\n")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	# Cria a bandeja de serviço no mundo
	var tray_scene = load("res://src/items/serving_tray.tscn")
	var tray: ServingTray = tray_scene.instantiate() as ServingTray
	root.add_child(tray)
	tray._ready()
	tray.location = Item.ItemLocation.WORLD

	var burger_box_scene = load("res://src/items/burger_box.tscn")
	var fries_box_scene = load("res://src/items/potato_box.tscn")
	var cup_scene = load("res://src/items/drink_cup.tscn")

	# Monta a bandeja com: Hambúrguer + Batata + Copo
	var burger = burger_box_scene.instantiate()
	var fries = fries_box_scene.instantiate()
	var cup = cup_scene.instantiate()

	root.add_child(burger)
	root.add_child(fries)
	root.add_child(cup)

	tray.add_product(burger)
	tray.add_product(fries)
	tray.add_product(cup)

	assert_test(tray.carried_items.size() == 3, "Bandeja montada com 3 itens (Hambúrguer, Batata, Copo)")
	assert_test(burger.location == Item.ItemLocation.TRAY, "Hambúrguer com location = TRAY")
	assert_test(fries.location == Item.ItemLocation.TRAY, "Batata com location = TRAY")
	assert_test(cup.location == Item.ItemLocation.TRAY, "Copo com location = TRAY")

	# =========================================================================
	# TESTE 1: Mirar no Copo -> LMB -> Copo na mão
	# =========================================================================
	print("\n--- TESTE 1: Mirar no Copo -> LMB ---")
	_clear_player(player)

	assert_test(cup.get_parent() == tray.tray_slot, "Copo está dentro da bandeja")
	player.pick_up(cup)

	assert_test(player.held_item == cup, "LMB retirou o Copo diretamente para a mão do jogador")
	assert_test(tray.carried_items.size() == 2, "Bandeja continua no lugar com 2 itens restantes")
	assert_test(tray.carried_items.has(burger) == true, "Hambúrguer continua na bandeja")
	assert_test(tray.carried_items.has(fries) == true, "Batata continua na bandeja")
	assert_test(tray.carried_items.has(cup) == false, "Copo não faz mais parte da bandeja")
	assert_test(tray.location == Item.ItemLocation.WORLD, "Bandeja preservou sua posição no mundo")

	# =========================================================================
	# TESTE 2: Mirar na Batata -> LMB -> Batata na mão
	# =========================================================================
	print("\n--- TESTE 2: Mirar na Batata -> LMB ---")
	_clear_player(player)

	assert_test(fries.get_parent() == tray.tray_slot, "Batata está dentro da bandeja")
	player.pick_up(fries)

	assert_test(player.held_item == fries, "LMB retirou a Batata diretamente para a mão do jogador")
	assert_test(tray.carried_items.size() == 1, "Bandeja continua no lugar com 1 item restante")
	assert_test(tray.carried_items.has(burger) == true, "Hambúrguer continua na bandeja")
	assert_test(tray.carried_items.has(fries) == false, "Batata não faz mais parte da bandeja")

	# =========================================================================
	# TESTE 3: Mirar no Hambúrguer -> LMB -> Hambúrguer na mão
	# =========================================================================
	print("\n--- TESTE 3: Mirar no Hambúrguer -> LMB ---")
	_clear_player(player)

	assert_test(burger.get_parent() == tray.tray_slot, "Hambúrguer está dentro da bandeja")
	player.pick_up(burger)

	assert_test(player.held_item == burger, "LMB retirou o Hambúrguer diretamente para a mão do jogador")
	assert_test(tray.carried_items.size() == 0, "Bandeja agora está vazia")
	assert_test(tray.is_clean() == true, "Estado da bandeja restaurado para CLEAN")
	assert_test(tray.location == Item.ItemLocation.WORLD, "Bandeja vazia permanece no balcão")

	# =========================================================================
	# TESTE 4: Com os 3 itens dentro -> Tecla E pega a bandeja inteira
	# =========================================================================
	print("\n--- TESTE 4: Tecla E pega a bandeja inteira com os 3 itens ---")
	_clear_player(player)

	# Remonta os 3 itens na bandeja
	tray.add_product(burger)
	tray.add_product(fries)
	tray.add_product(cup)

	assert_test(tray.carried_items.size() == 3, "Bandeja remontada com os 3 itens")

	# Pressiona E na bandeja
	tray.interact(player)

	assert_test(player.held_item == tray, "Tecla E pegou a bandeja inteira para a mão principal")
	assert_test(tray.carried_items.size() == 3, "Todos os 3 produtos continuam perfeitamente preservados na bandeja")
	assert_test(tray.carried_items[0] == burger, "Hambúrguer preservado")
	assert_test(tray.carried_items[1] == fries, "Batata preservada")
	assert_test(tray.carried_items[2] == cup, "Copo preservado")

	# =========================================================================
	# TESTE 5: Com um item na mão -> RMB na bandeja coloca de volta
	# =========================================================================
	print("\n--- TESTE 5: Item na mão + RMB na bandeja -> Coloca na bandeja ---")
	player.held_item = null
	tray.location = Item.ItemLocation.WORLD

	var extra_cup = cup_scene.instantiate()
	root.add_child(extra_cup)
	player.pick_up(extra_cup)

	assert_test(player.held_item == extra_cup, "Jogador segurando um novo copo")

	# RMB na bandeja
	var taken_item = player.take_held_item()
	tray.add_product(taken_item)

	assert_test(player.held_item == null, "Mão liberada após colocar o copo com RMB")
	assert_test(tray.carried_items.size() == 4, "Bandeja agora contém 4 produtos")
	assert_test(tray.carried_items[3] == extra_cup, "Novo copo adicionado com sucesso ao conteúdo da bandeja")

	print("\n=================================================================")
	print("RESULTADO FINAL: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=================================================================\n")

	if passed_tests == total_tests:
		print(">>> SUCESSO TOTAL: TODAS AS REGRAS E TESTES OBRIGATÓRIOS VALIDADOS COM 100%! <<<\n")
		quit(0)
	else:
		print(">>> FALHA NOS TESTES! <<<\n")
		quit(1)

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
