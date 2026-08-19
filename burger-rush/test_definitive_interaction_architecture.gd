extends SceneTree

# ================================================================
# TESTE AUTOMATIZADO: ARQUITETURA DEFINITIVA DE INTERAÇÃO (A a H)
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
	print("=== INICIANDO TESTE DA ARQUITETURA DEFINITIVA DE INTERAÇÃO ===")
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

	# Instancia Geladeira
	var fridge_scene = load("res://src/stations/commercial_refrigerator.tscn")
	var fridge: MeatRefrigerator = fridge_scene.instantiate() as MeatRefrigerator
	root.add_child(fridge)
	fridge._ready()
	fridge.is_open = true

	var beef_slot = fridge.get_node_or_null("BeefSlot")
	var chicken_slot = fridge.get_node_or_null("ChickenSlot")

	# Instancia Chapa / Grelha
	var grill_scene = load("res://src/stations/grill.tscn")
	var grill: Grill = grill_scene.instantiate() as Grill
	root.add_child(grill)
	grill.global_position = Vector3(3.0, 0, -5.0)
	grill._ready()
	grill.is_on = true

	# -------------------------------------------------------------------------
	# TESTE A & B: TRÊS CARNES CONSECUTIVAS (PEGAR ATÉ LOTAR OS 3 SLOTS)
	# -------------------------------------------------------------------------
	print("--- TESTE A & B: Pegar 3 Carnes Consecutivas da Geladeira ---")
	_clear_player(player)
	inv.add_stock("patty_beef", 10)

	beef_slot.interact_item(player) # Clique 1 -> carne no slot 0
	assert_test(not player.quick_slots[0].is_empty(), "Clique 1: Carne no slot 0")
	assert_test(player.quick_slots[1].is_empty(), "Slot 1 ainda livre")
	assert_test(player.quick_slots[2].is_empty(), "Slot 2 ainda livre")

	beef_slot.interact_item(player) # Clique 2 -> carne no slot 1 (sem devolver a do slot 0!)
	assert_test(not player.quick_slots[0].is_empty(), "Clique 2: Carne permanece no slot 0")
	assert_test(not player.quick_slots[1].is_empty(), "Clique 2: Segunda carne no slot 1")
	assert_test(player.quick_slots[2].is_empty(), "Slot 2 ainda livre")

	beef_slot.interact_item(player) # Clique 3 -> carne no slot 2
	assert_test(not player.quick_slots[0].is_empty(), "Clique 3: Primeira carne mantida no slot 0")
	assert_test(not player.quick_slots[1].is_empty(), "Clique 3: Segunda carne mantida no slot 1")
	assert_test(not player.quick_slots[2].is_empty(), "Clique 3: Terceira carne no slot 2")
	assert_test(player.has_empty_quick_slot() == false, "Todos os 3 slots ocupados com carne")

	# -------------------------------------------------------------------------
	# TESTE C & D: CARNE + TOMATE + QUEIJO
	# -------------------------------------------------------------------------
	print("\n--- TESTE C & D: Carne + Tomate + Queijo (Ingredientes Diferentes) ---")
	_clear_player(player)

	var p1 = load("res://src/items/patty.tscn").instantiate() as Patty
	root.add_child(p1)
	player.pick_up(p1)
	assert_test(player.quick_slots[0].get("item_id") == "patty_beef", "Carne no slot 0")

	var t1 = load("res://src/items/tomato.tscn").instantiate() as Tomato
	root.add_child(t1)
	player.pick_up(t1)
	assert_test(player.quick_slots[0].get("item_id") == "patty_beef", "Carne permanece intacta no slot 0 ao pegar tomate")
	assert_test(player.quick_slots[1].get("item_id") == "tomato", "Tomate armazenado no slot 1")

	var c1 = load("res://src/items/cheese.tscn").instantiate() as Cheese
	root.add_child(c1)
	player.pick_up(c1)
	assert_test(player.quick_slots[0].get("item_id") == "patty_beef", "Carne permanece no slot 0")
	assert_test(player.quick_slots[1].get("item_id") == "tomato", "Tomate permanece no slot 1")
	assert_test(player.quick_slots[2].get("item_id") == "cheese", "Queijo armazenado no slot 2")

	# -------------------------------------------------------------------------
	# TESTE E: CARNE SEGURADA -> COLOCAR NA CHAPA / GRILL
	# -------------------------------------------------------------------------
	print("\n--- TESTE E: Carne Segurada -> Colocar na Chapa ---")
	player.select_quick_slot(0) # Seleciona a Carne
	assert_test(player.held_item is Patty, "Carne na mão do jogador")

	var initial_grill_items = grill.active_items.size()
	grill.interact_item(player)

	assert_test(grill.active_items.size() == initial_grill_items + 1, "Carne colocada na chapa com sucesso")
	assert_test(player.quick_slots[0].is_empty(), "Slot 0 (Carne) liberado após colocar na chapa")
	assert_test(not player.quick_slots[1].is_empty(), "Tomate continua no slot 1")
	assert_test(not player.quick_slots[2].is_empty(), "Queijo continua no slot 2")

	# -------------------------------------------------------------------------
	# TESTE F: MÃO PRINCIPAL (OBJETO GRANDE) VERSUS SLOTS DE INGREDIENTES
	# -------------------------------------------------------------------------
	print("\n--- TESTE F: Mão Principal (Bandeja) e Slots de Ingredientes ---")
	_clear_player(player)

	var tray = load("res://src/items/serving_tray.tscn").instantiate() as ServingTray
	root.add_child(tray)
	player.pick_up(tray)

	assert_test(player.held_item == tray, "Bandeja ocupa a mão principal")
	assert_test(player.is_holding_large_item() == true, "Identificado como objeto grande")
	assert_test(player.quick_slots[0].is_empty(), "Slots rápidos não são poluídos pelo objeto grande")

	player.drop_item()
	assert_test(player.held_item == null, "Bandeja solta da mão principal")

	# -------------------------------------------------------------------------
	# TESTE G: DEVOLUÇÃO À GELADEIRA QUANDO SLOTS ESTÃO CHEIOS
	# -------------------------------------------------------------------------
	print("\n--- TESTE G: Devolver Carne à Geladeira com Slots Cheios ---")
	_clear_player(player)
	var stock_before = inv.get_stock("patty_beef")

	beef_slot.interact_item(player) # Pega carne 1 (slot 0)
	beef_slot.interact_item(player) # Pega carne 2 (slot 1)
	beef_slot.interact_item(player) # Pega carne 3 (slot 2)
	assert_test(inv.get_stock("patty_beef") == stock_before - 3, "3 carnes retiradas da geladeira")
	assert_test(player.has_empty_quick_slot() == false, "Todos os 3 slots ocupados")

	player.select_quick_slot(0) # Seleciona carne do slot 0
	# Com os slots cheios, clicar no compartimento da geladeira devolve a carne selecionada
	beef_slot.interact_item(player)
	assert_test(inv.get_stock("patty_beef") == stock_before - 2, "Estoque restaurado em +1 após devolver carne")
	assert_test(player.quick_slots[0].is_empty(), "Slot 0 liberado após devolução")
	assert_test(player.has_empty_quick_slot() == true, "Jogador agora possui 1 slot livre")

	# -------------------------------------------------------------------------
	# TESTE H: SLOTS CHEIOS (3/3) -> NENHUM OBJETO CAI OU É CORROMPIDO
	# -------------------------------------------------------------------------
	print("\n--- TESTE H: Tentativa de Pickup com Slots Cheios ---")
	_clear_player(player)

	var i1 = load("res://src/items/patty.tscn").instantiate()
	root.add_child(i1)
	player.pick_up(i1)

	var i2 = load("res://src/items/tomato.tscn").instantiate()
	root.add_child(i2)
	player.pick_up(i2)

	var i3 = load("res://src/items/cheese.tscn").instantiate()
	root.add_child(i3)
	player.pick_up(i3)

	assert_test(player.has_empty_quick_slot() == false, "3 slots cheios (100%)")

	var extra_item = load("res://src/items/lettuce.tscn").instantiate()
	root.add_child(extra_item)
	extra_item.global_position = Vector3(0, 0, -2.0)

	player.pick_up(extra_item) # Tenta pegar com slots cheios

	assert_test(player.quick_slots[0].get("item_id") == "patty_beef", "Slot 0 intacto")
	assert_test(player.quick_slots[1].get("item_id") == "tomato", "Slot 1 intacto")
	assert_test(player.quick_slots[2].get("item_id") == "cheese", "Slot 2 intacto")
	assert_test(extra_item.location == Item.ItemLocation.WORLD, "Item extra permaneceu no mundo sem corromper estado")

	print("\n=======================================================")
	print("RESULTADO DO TESTE ARQUITETURAL: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=======================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS CENÁRIOS (A a H) FORAM 100% APROVADOS! <<<\n")
		quit(0)
	else:
		printerr(">>> FALHA NOS TESTES ARQUITETURAIS! <<<\n")
		quit(1)
