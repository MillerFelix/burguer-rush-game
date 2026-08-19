extends SceneTree

# ================================================================
# TESTE AUTOMATIZADO: MÚLTIPLOS SLOTS E DEVOLUÇÃO À GELADEIRA/DISPENSER
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
	print("=== TESTE DE MÚLTIPLOS SLOTS E DEVOLUÇÃO À GELADEIRA ===")
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
	player._ready()

	var fridge_scene = load("res://src/stations/commercial_refrigerator.tscn")
	var fridge: MeatRefrigerator = fridge_scene.instantiate() as MeatRefrigerator
	root.add_child(fridge)
	fridge._ready()
	fridge.is_open = true # Porta aberta para permitir acesso aos slots

	var beef_slot = fridge.get_node_or_null("BeefSlot")
	var chicken_slot = fridge.get_node_or_null("ChickenSlot")

	# -------------------------------------------------------------------------
	# CENÁRIO 1: MÚLTIPLOS SLOTS — PEGAR 3 INGREDIENTES SEM DROPAR NENHUM
	# -------------------------------------------------------------------------
	print("--- CENÁRIO 1: Múltiplos Slots (Pegar 3 Ingredientes) ---")
	_clear_player(player)

	var patty = load("res://src/items/patty.tscn").instantiate() as Patty
	root.add_child(patty)
	player.pick_up(patty)
	assert_test(not player.quick_slots[0].is_empty(), "Ingrediente 1 (Carne) armazenado no slot 0")
	assert_test(player.quick_slots[1].is_empty(), "Slot 1 ainda vazio")
	assert_test(player.quick_slots[2].is_empty(), "Slot 2 ainda vazio")

	var tomato = load("res://src/items/tomato.tscn").instantiate() as Tomato
	root.add_child(tomato)
	player.pick_up(tomato)
	assert_test(not player.quick_slots[0].is_empty(), "Ingrediente 1 (Carne) permanece no slot 0 (NÃO foi dropado)")
	assert_test(not player.quick_slots[1].is_empty(), "Ingrediente 2 (Tomate) armazenado no slot 1")
	assert_test(player.quick_slots[2].is_empty(), "Slot 2 ainda vazio")

	var cheese = load("res://src/items/cheese.tscn").instantiate() as Cheese
	root.add_child(cheese)
	player.pick_up(cheese)
	assert_test(not player.quick_slots[0].is_empty(), "Carne mantida no slot 0")
	assert_test(not player.quick_slots[1].is_empty(), "Tomate mantido no slot 1")
	assert_test(not player.quick_slots[2].is_empty(), "Queijo mantido no slot 2")
	assert_test(player.has_empty_quick_slot() == false, "Todos os 3 slots ocupados")

	# -------------------------------------------------------------------------
	# CENÁRIO 2: SELEÇÃO E TROCA DE SLOTS (4, 5, 6)
	# -------------------------------------------------------------------------
	print("\n--- CENÁRIO 2: Troca entre os 3 Slots Rápidos ---")
	player.select_quick_slot(0)
	assert_test(player.active_quick_slot == 0, "Slot 0 (Carne) selecionado")
	assert_test(player.held_item is Patty, "Carne exibida visualmente na mão")

	player.select_quick_slot(1)
	assert_test(player.active_quick_slot == 1, "Slot 1 (Tomate) selecionado")
	assert_test(player.held_item is Tomato, "Tomate exibido visualmente na mão")

	player.select_quick_slot(2)
	assert_test(player.active_quick_slot == 2, "Slot 2 (Queijo) selecionado")
	assert_test(player.held_item is Cheese, "Queijo exibido visualmente na mão")

	# -------------------------------------------------------------------------
	# CENÁRIO 3: DEVOLVER CARNE BOVINA À GELADEIRA (BEEF SLOT)
	# -------------------------------------------------------------------------
	print("\n--- CENÁRIO 3: Devolver Carne Bovina à Geladeira ---")
	player.select_quick_slot(0) # Seleciona a Carne
	var initial_stock = inv.get_stock("patty_beef")

	assert_test(beef_slot != null, "BeefSlot encontrado na geladeira")
	beef_slot.interact_item(player)

	var final_stock = inv.get_stock("patty_beef")
	assert_test(final_stock == initial_stock + 1, "Estoque de Carne Bovina aumentou em +1 após devolução")
	assert_test(player.quick_slots[0].is_empty(), "Slot 0 (Carne) foi liberado com sucesso")
	assert_test(not player.quick_slots[1].is_empty(), "Slot 1 (Tomate) continua preservado")
	assert_test(not player.quick_slots[2].is_empty(), "Slot 2 (Queijo) continua preservado")

	# -------------------------------------------------------------------------
	# CENÁRIO 4: RETIRAR E DEVOLVER FRANGO (CHICKEN SLOT)
	# -------------------------------------------------------------------------
	print("\n--- CENÁRIO 4: Retirar e Devolver Frango na Geladeira ---")
	var initial_chicken_stock = inv.get_stock("patty_chicken")
	chicken_slot.interact_item(player) # Pega frango no slot 0 que agora está livre
	assert_test(not player.quick_slots[0].is_empty(), "Frango pego e colocado no slot 0 livre")
	assert_test(inv.get_stock("patty_chicken") == initial_chicken_stock - 1, "Estoque consumido (-1)")

	player.select_quick_slot(0)
	chicken_slot.interact_item(player) # Devolve frango
	assert_test(inv.get_stock("patty_chicken") == initial_chicken_stock, "Estoque de Frango restaurado após devolução (+1)")
	assert_test(player.quick_slots[0].is_empty(), "Slot 0 liberado novamente")

	# -------------------------------------------------------------------------
	# CENÁRIO 5: DEVOLVER INGREDIENTE AO DISPENSER
	# -------------------------------------------------------------------------
	print("\n--- CENÁRIO 5: Devolver Ingrediente ao Dispenser ---")
	var disp = IngredientDispenser.new()
	disp.ingredient_id = "tomato"
	root.add_child(disp)

	player.select_quick_slot(1) # Seleciona Tomate
	var initial_tomato_stock = inv.get_stock("tomato")
	disp.interact_item(player)

	assert_test(inv.get_stock("tomato") == initial_tomato_stock + 1, "Estoque de Tomate aumentado (+1) ao devolver no dispenser")
	assert_test(player.quick_slots[1].is_empty(), "Slot 1 (Tomate) liberado")
	assert_test(not player.quick_slots[2].is_empty(), "Slot 2 (Queijo) continua no slot")

	# -------------------------------------------------------------------------
	# CENÁRIO 6: SOLTAR INGREDIENTE RESTANTE EM SUPERFÍCIE NORMAL
	# -------------------------------------------------------------------------
	print("\n--- CENÁRIO 6: Soltar Ingrediente Restante em Superfície ---")
	player.select_quick_slot(2) # Seleciona Queijo
	var island = load("res://src/stations/prep_island.tscn").instantiate()
	root.add_child(island)
	island.global_position = Vector3(1.4, 0, -4.55)

	player.global_position = island.global_position + Vector3(0, 0, 1.0)
	player.drop_item()
	assert_test(player.quick_slots[2].is_empty(), "Slot 2 (Queijo) liberado após o drop")
	assert_test(player.held_item == null, "Mão livre após o drop")

	print("\n=======================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=======================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS TESTES DE MÚLTIPLOS SLOTS E DEVOLUÇÃO PASSARAM COM 100%! <<<\n")
		quit(0)
	else:
		printerr(">>> FALHA NOS TESTES! <<<\n")
		quit(1)
