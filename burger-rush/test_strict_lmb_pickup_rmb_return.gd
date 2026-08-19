extends SceneTree

# ================================================================
# TESTE AUTOMATIZADO: SEPARAÇÃO ESTRITA LMB (PEGAR/COLOCAR) & RMB (DEVOLVER)
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
	print("\n=================================================================")
	print("=== TESTE: SEPARAÇÃO ESTRITA LMB (PEGAR/COLOCAR) & RMB (DEVOLVER) ===")
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

	# Geladeira
	var fridge_scene = load("res://src/stations/commercial_refrigerator.tscn")
	var fridge: MeatRefrigerator = fridge_scene.instantiate() as MeatRefrigerator
	root.add_child(fridge)
	fridge._ready()
	fridge.is_open = true
	var beef_slot = fridge.get_node_or_null("BeefSlot")
	var chicken_slot = fridge.get_node_or_null("ChickenSlot")

	# Dispensers
	var onion_disp = IngredientDispenser.new()
	onion_disp.ingredient_id = "onion"
	root.add_child(onion_disp)
	inv.add_stock("onion", 10)

	var tomato_disp = IngredientDispenser.new()
	tomato_disp.ingredient_id = "tomato"
	root.add_child(tomato_disp)
	inv.add_stock("tomato", 10)

	var cheese_disp = IngredientDispenser.new()
	cheese_disp.ingredient_id = "cheese"
	root.add_child(cheese_disp)
	inv.add_stock("cheese", 10)

	# Grelha
	var grill_scene = load("res://src/stations/grill.tscn")
	var grill: Grill = grill_scene.instantiate() as Grill
	root.add_child(grill)
	grill.global_position = Vector3(3.0, 0, -5.0)
	grill._ready()
	grill.is_on = true

	# -------------------------------------------------------------------------
	# TESTE 1: PEGAR 3 CEBOLAS COM CLIQUE ESQUERDO (LMB)
	# -------------------------------------------------------------------------
	print("--- TESTE 1: Pegar 3 Cebolas Consecutivas com Clique Esquerdo (LMB) ---")
	_clear_player(player)

	onion_disp.interact_item(player) # Clique 1
	assert_test(player.quick_slots[0].get("item_id") == "onion", "Clique Esquerdo 1: Cebola no slot 0")
	assert_test(player.quick_slots[1].is_empty(), "Slot 1 vazio")
	assert_test(player.quick_slots[2].is_empty(), "Slot 2 vazio")

	onion_disp.interact_item(player) # Clique 2
	assert_test(player.quick_slots[0].get("item_id") == "onion", "Cebola mantida no slot 0")
	assert_test(player.quick_slots[1].get("item_id") == "onion", "Clique Esquerdo 2: Segunda cebola no slot 1")
	assert_test(player.quick_slots[2].is_empty(), "Slot 2 vazio")

	onion_disp.interact_item(player) # Clique 3
	assert_test(player.quick_slots[0].get("item_id") == "onion", "Primeira cebola mantida no slot 0")
	assert_test(player.quick_slots[1].get("item_id") == "onion", "Segunda cebola mantida no slot 1")
	assert_test(player.quick_slots[2].get("item_id") == "onion", "Clique Esquerdo 3: Terceira cebola no slot 2")
	assert_test(player.has_empty_quick_slot() == false, "Mão cheia de cebolas (3/3)")

	# -------------------------------------------------------------------------
	# TESTE 2: DEVOLVER 1 CEBOLA COM BOTÃO DIREITO (RMB)
	# -------------------------------------------------------------------------
	print("\n--- TESTE 2: Devolver 1 Cebola com Botão Direito (RMB) ---")
	var onion_stock_before = inv.get_stock("onion")
	onion_disp.interact_return(player) # Clique Direito 1

	assert_test(inv.get_stock("onion") == onion_stock_before + 1, "Estoque de cebola restaurado (+1)")
	var onion_count = 0
	for s in player.quick_slots:
		if s.get("item_id") == "onion":
			onion_count += 1
	assert_test(onion_count == 2, "Restam exatamente 2 cebolas nos slots")
	assert_test(player.has_empty_quick_slot() == true, "1 slot foi liberado com sucesso")

	# -------------------------------------------------------------------------
	# TESTE 3: DEVOLVER AS OUTRAS 2 CEBOLAS COM BOTÃO DIREITO (RMB)
	# -------------------------------------------------------------------------
	print("\n--- TESTE 3: Devolver as Outras 2 Cebolas com Botão Direito (RMB) ---")
	onion_disp.interact_return(player) # Clique Direito 2
	onion_disp.interact_return(player) # Clique Direito 3

	assert_test(inv.get_stock("onion") == onion_stock_before + 3, "Todas as 3 cebolas devolvidas ao estoque")
	var remaining_onions = 0
	for s in player.quick_slots:
		if not s.is_empty():
			remaining_onions += 1
	assert_test(remaining_onions == 0, "Todos os slots de ingredientes agora estão vazios")

	# -------------------------------------------------------------------------
	# TESTE 4: PEGAR CARNE APÓS TER CEBOLAS
	# -------------------------------------------------------------------------
	print("\n--- TESTE 4: Pegar Carne com 2 Slots de Cebola Ocupados ---")
	_clear_player(player)
	onion_disp.interact_item(player) # Cebola no slot 0
	onion_disp.interact_item(player) # Cebola no slot 1

	inv.add_stock("patty_beef", 5)
	beef_slot.interact_item(player) # Clique Esquerdo na Carne
	assert_test(player.quick_slots[0].get("item_id") == "onion", "Slot 0 continua com Cebola")
	assert_test(player.quick_slots[1].get("item_id") == "onion", "Slot 1 continua com Cebola")
	assert_test(player.quick_slots[2].get("item_id") == "patty_beef", "Slot 2 agora possui Carne Bovina")

	# -------------------------------------------------------------------------
	# TESTE 5: MISTURAR INGREDIENTES (CEBOLA + TOMATE + CARNE)
	# -------------------------------------------------------------------------
	print("\n--- TESTE 5: Misturar Ingredientes (Cebola + Tomate + Carne) ---")
	_clear_player(player)
	onion_disp.interact_item(player)
	tomato_disp.interact_item(player)
	beef_slot.interact_item(player)

	assert_test(player.quick_slots[0].get("item_id") == "onion", "Slot 0: Cebola")
	assert_test(player.quick_slots[1].get("item_id") == "tomato", "Slot 1: Tomate")
	assert_test(player.quick_slots[2].get("item_id") == "patty_beef", "Slot 2: Carne")

	# -------------------------------------------------------------------------
	# TESTE 6: COLOCAR CARNE NA CHAPA COM CLIQUE ESQUERDO (LMB)
	# -------------------------------------------------------------------------
	print("\n--- TESTE 6: Colocar Carne na Chapa com Clique Esquerdo (LMB) ---")
	player.select_quick_slot(2) # Seleciona a Carne
	var grill_count_before = grill.active_items.size()

	grill.interact_item(player) # Clique Esquerdo na Chapa
	assert_test(grill.active_items.size() == grill_count_before + 1, "Carne colocada na chapa com sucesso")
	assert_test(player.quick_slots[2].is_empty(), "Slot 2 (Carne) liberado após colocação na chapa")
	assert_test(player.quick_slots[0].get("item_id") == "onion", "Cebola intacta no slot 0")
	assert_test(player.quick_slots[1].get("item_id") == "tomato", "Tomate intacto no slot 1")

	# -------------------------------------------------------------------------
	# TESTE 7: ARMAZENAMENTO INCOMPATÍVEL COM BOTÃO DIREITO (RMB)
	# -------------------------------------------------------------------------
	print("\n--- TESTE 7: Tentativa de Devolução em Armazenamento Incompatível ---")
	# Jogador tem Cebola (slot 0) e Tomate (slot 1), mas mira no dispenser de Queijo com RMB
	var cheese_stock_before = inv.get_stock("cheese")
	cheese_disp.interact_return(player) # Clique Direito no Queijo

	assert_test(inv.get_stock("cheese") == cheese_stock_before, "Estoque de Queijo inalterado (rejeitou devolução inválida)")
	assert_test(player.quick_slots[0].get("item_id") == "onion", "Cebola não foi destruída nem movida")
	assert_test(player.quick_slots[1].get("item_id") == "tomato", "Tomate não foi destruído nem movido")

	# -------------------------------------------------------------------------
	# TESTE 8: CLIQUE ESQUERDO NUNCA DEVOLVE AUTOMATICAMENTE
	# -------------------------------------------------------------------------
	print("\n--- TESTE 8: Clique Esquerdo Nunca Devolve ---")
	_clear_player(player)
	onion_disp.interact_item(player) # Pega 1 cebola (slot 0)
	var onion_stock = inv.get_stock("onion")

	# Clica com LMB novamente no dispenser de cebola
	onion_disp.interact_item(player)
	assert_test(inv.get_stock("onion") == onion_stock - 1, "Clique Esquerdo pegou mais 1 cebola (não devolveu)")
	assert_test(player.quick_slots[1].get("item_id") == "onion", "Segunda cebola no slot 1")

	# -------------------------------------------------------------------------
	# TESTE 9: MÃO PRINCIPAL COM OBJETO GRANDE (BANDEJA)
	# -------------------------------------------------------------------------
	print("\n--- TESTE 9: Mão Principal (Bandeja) ---")
	_clear_player(player)
	var tray = load("res://src/items/serving_tray.tscn").instantiate() as ServingTray
	root.add_child(tray)

	player.pick_up(tray) # LMB pega
	assert_test(player.held_item == tray, "Bandeja na mão principal")
	assert_test(player.is_holding_large_item() == true, "Reconhecido como item grande")

	player.drop_item() # LMB coloca
	assert_test(player.held_item == null, "Bandeja solta no mundo")

	print("\n=================================================================")
	print("RESULTADO DO TESTE DE SEPARAÇÃO ESTRITA: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=================================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS 9 TESTES DE SEPARAÇÃO ESTRITA PASSARAM COM 100%! <<<\n")
		quit(0)
	else:
		printerr(">>> FALHA NOS TESTES DE SEPARAÇÃO ESTRITA! <<<\n")
		quit(1)
