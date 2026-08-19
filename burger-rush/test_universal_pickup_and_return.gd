extends SceneTree

# ================================================================
# TESTE AUTOMATIZADO UNIVERSAL: PICKUP (LMB) & DEVOLUÇÃO (RMB)
# Para TODOS os objetos e ingredientes do Burger Rush
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
	print("=== TESTE UNIVERSAL: PICKUP (LMB) & DEVOLUÇÃO (RMB) PARA TODOS OS ITENS ===")
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

	# 1. Geladeira de Carnes
	var fridge_scene = load("res://src/stations/commercial_refrigerator.tscn")
	var fridge: MeatRefrigerator = fridge_scene.instantiate() as MeatRefrigerator
	root.add_child(fridge)
	fridge._ready()
	fridge.is_open = true
	var beef_slot = fridge.get_node_or_null("BeefSlot")
	var chicken_slot = fridge.get_node_or_null("ChickenSlot")

	# 2. Geladeira de Hortifrúti e Sacos
	var ing_fridge_scene = load("res://src/stations/ingredient_refrigerator.tscn")
	var ing_fridge: IngredientRefrigerator = ing_fridge_scene.instantiate() as IngredientRefrigerator
	root.add_child(ing_fridge)
	ing_fridge._ready()
	ing_fridge.is_open = true
	var slot_lettuce = ing_fridge.get_node_or_null("LettuceSlot")
	var slot_tomato = ing_fridge.get_node_or_null("TomatoSlot")
	var slot_onion = ing_fridge.get_node_or_null("WhiteOnionSlot")
	var slot_red_onion = ing_fridge.get_node_or_null("RedOnionSlot")
	var slot_pickle = ing_fridge.get_node_or_null("PickleSlot")
	var slot_potato_bag = ing_fridge.get_node_or_null("PotatoSlot")
	var slot_onion_bag = ing_fridge.get_node_or_null("OnionBagSlot")

	# 3. Freezer de Queijos
	var freezer_scene = load("res://src/stations/commercial_chest_freezer.tscn")
	var freezer: CommercialChestFreezer = freezer_scene.instantiate() as CommercialChestFreezer
	root.add_child(freezer)
	freezer._ready()
	freezer.current_state = CommercialChestFreezer.State.OPEN
	var slot_cheddar = freezer.get_node_or_null("CheddarSlot")
	var slot_mozzarella = freezer.get_node_or_null("MozzarellaSlot")
	var slot_prato = freezer.get_node_or_null("PratoSlot")

	# 4. Mesa de Polpas
	var pulp_table_scene = load("res://src/stations/pulp_storage_table.tscn")
	var pulp_table: PulpStorageTable = pulp_table_scene.instantiate() as PulpStorageTable
	root.add_child(pulp_table)
	pulp_table._ready()

	# 5. Bancada de Pães
	var bread_rack_scene = load("res://src/stations/storage_rack.tscn")
	var bread_rack: StorageRack = bread_rack_scene.instantiate() as StorageRack
	root.add_child(bread_rack)
	bread_rack._ready()

	# 6. Bancada de Bacon & Ovos
	var bacon_egg_scene = load("res://src/stations/bacon_egg_station.tscn")
	var bacon_egg: BaconEggStation = bacon_egg_scene.instantiate() as BaconEggStation
	root.add_child(bacon_egg)
	bacon_egg._ready()

	# 7. Prateleira de Óleo
	var oil_rack_scene = load("res://src/stations/oil_rack.tscn")
	var oil_rack: OilRack = oil_rack_scene.instantiate() as OilRack
	root.add_child(oil_rack)
	oil_rack._ready()

	# 8. Pilha de Bandejas
	var tray_stack_scene = load("res://src/stations/serving_tray_stack.tscn")
	var tray_stack: ServingTrayStack = tray_stack_scene.instantiate() as ServingTrayStack
	root.add_child(tray_stack)
	tray_stack._ready()

	# 9. Bancada de Embalagens
	var pack_station_scene = load("res://src/stations/packaging_station.tscn")
	var pack_station: PackagingStation = pack_station_scene.instantiate() as PackagingStation
	root.add_child(pack_station)
	pack_station._ready()

	# -------------------------------------------------------------------------
	# 1. TESTE DE CARNES (BOVINA & FRANGO)
	# -------------------------------------------------------------------------
	print("--- 1. CARNES (Bovina e Frango) ---")
	_clear_player(player)
	inv.add_stock("patty_beef", 10)
	inv.add_stock("patty_chicken", 10)

	var beef_stock = inv.get_stock("patty_beef")
	beef_slot.interact_item(player) # LMB pega carne bovina
	assert_test(player.quick_slots[0].get("item_id") == "patty_beef", "LMB Pegou Carne Bovina no Slot 0")
	assert_test(inv.get_stock("patty_beef") == beef_stock - 1, "Estoque de Carne consumido (-1)")

	beef_slot.interact_return(player) # RMB devolve carne bovina
	assert_test(player.quick_slots[0].is_empty(), "RMB Devolveu Carne Bovina (Slot 0 livre)")
	assert_test(inv.get_stock("patty_beef") == beef_stock, "Estoque de Carne restaurado (+1)")

	var chicken_stock = inv.get_stock("patty_chicken")
	chicken_slot.interact_item(player) # LMB pega frango
	assert_test(player.quick_slots[0].get("item_id") == "patty_chicken", "LMB Pegou Frango no Slot 0")
	chicken_slot.interact_return(player) # RMB devolve frango
	assert_test(player.quick_slots[0].is_empty(), "RMB Devolveu Frango (Slot 0 livre)")
	assert_test(inv.get_stock("patty_chicken") == chicken_stock, "Estoque de Frango restaurado (+1)")

	# -------------------------------------------------------------------------
	# 2. TESTE DE HORTIFRÚTI (ALFACE, TOMATE, CEBOLA, CEBOLA ROXA, PICLES)
	# -------------------------------------------------------------------------
	print("\n--- 2. HORTIFRÚTI (Alface, Tomate, Cebolas, Picles) ---")
	_clear_player(player)
	inv.add_stock("lettuce", 10)
	inv.add_stock("tomato", 10)
	inv.add_stock("onion", 10)
	inv.add_stock("red_onion", 10)
	inv.add_stock("pickle", 10)

	# Pegar 3 vegetais com LMB
	slot_lettuce.interact_item(player)
	slot_tomato.interact_item(player)
	slot_onion.interact_item(player)
	assert_test(player.quick_slots[0].get("item_id") == "lettuce", "LMB Slot 0: Alface")
	assert_test(player.quick_slots[1].get("item_id") == "tomato", "LMB Slot 1: Tomate")
	assert_test(player.quick_slots[2].get("item_id") == "onion", "LMB Slot 2: Cebola")

	# Devolver individualmente com RMB
	var tomato_stock = inv.get_stock("tomato")
	slot_tomato.interact_return(player) # RMB no tomate
	assert_test(player.quick_slots[1].is_empty(), "RMB Devolveu Tomate (Slot 1 livre)")
	assert_test(inv.get_stock("tomato") == tomato_stock + 1, "Estoque de Tomate restaurado (+1)")
	assert_test(player.quick_slots[0].get("item_id") == "lettuce", "Alface intacta no Slot 0")
	assert_test(player.quick_slots[2].get("item_id") == "onion", "Cebola intacta no Slot 2")

	slot_lettuce.interact_return(player)
	assert_test(player.quick_slots[0].is_empty(), "RMB Devolveu Alface")
	slot_onion.interact_return(player)
	assert_test(player.quick_slots[2].is_empty(), "RMB Devolveu Cebola")

	# Cebola Roxa e Picles
	slot_red_onion.interact_item(player)
	slot_pickle.interact_item(player)
	assert_test(player.quick_slots[0].get("item_id") == "red_onion", "LMB Pegou Cebola Roxa")
	assert_test(player.quick_slots[1].get("item_id") == "pickle", "LMB Pegou Picles")
	slot_red_onion.interact_return(player)
	slot_pickle.interact_return(player)
	assert_test(player.quick_slots[0].is_empty() and player.quick_slots[1].is_empty(), "RMB Devolveu Cebola Roxa e Picles")

	# -------------------------------------------------------------------------
	# 3. TESTE DE SACOS (SACO DE BATATA & SACO DE CEBOLA)
	# -------------------------------------------------------------------------
	print("\n--- 3. SACOS (Saco de Batatas e Saco de Cebolas) ---")
	_clear_player(player)
	inv.add_stock("potato_raw", 10)
	inv.add_stock("onion_rings_raw", 10)

	var pot_stock = inv.get_stock("potato_raw")
	slot_potato_bag.interact_item(player) # LMB pega saco/porção de batata
	assert_test(player.quick_slots[0].get("item_id") == "potato_raw", "LMB Pegou Saco/Porção de Batata")
	assert_test(inv.get_stock("potato_raw") == pot_stock - 1, "Estoque de Batatas consumido (-1)")

	slot_potato_bag.interact_return(player) # RMB devolve batata
	assert_test(player.quick_slots[0].is_empty(), "RMB Devolveu Saco de Batata ao armazenamento")
	assert_test(inv.get_stock("potato_raw") == pot_stock, "Estoque de Batatas restaurado (+1)")

	var on_bag_stock = inv.get_stock("onion_rings_raw")
	slot_onion_bag.interact_item(player) # LMB pega saco de cebolas
	assert_test(player.quick_slots[0].get("item_id") == "onion_rings_raw", "LMB Pegou Saco de Cebola para fritura")
	slot_onion_bag.interact_return(player) # RMB devolve saco de cebolas
	assert_test(player.quick_slots[0].is_empty(), "RMB Devolveu Saco de Cebola ao armazenamento")
	assert_test(inv.get_stock("onion_rings_raw") == on_bag_stock, "Estoque de Cebola para Fritura restaurado (+1)")

	# -------------------------------------------------------------------------
	# 4. TESTE DE QUEIJOS (CHEDDAR, MUÇARELA, PRATO)
	# -------------------------------------------------------------------------
	print("\n--- 4. QUEIJOS (Cheddar, Muçarela, Prato) ---")
	_clear_player(player)
	inv.add_stock("cheese_cheddar", 10)
	inv.add_stock("cheese_mozzarella", 10)
	inv.add_stock("cheese_prato", 10)

	slot_cheddar.interact_item(player)
	slot_mozzarella.interact_item(player)
	slot_prato.interact_item(player)
	assert_test(player.quick_slots[0].get("item_id") == "cheese_cheddar", "LMB Slot 0: Queijo Cheddar")
	assert_test(player.quick_slots[1].get("item_id") == "cheese_mozzarella", "LMB Slot 1: Queijo Muçarela")
	assert_test(player.quick_slots[2].get("item_id") == "cheese_prato", "LMB Slot 2: Queijo Prato")

	slot_cheddar.interact_return(player)
	assert_test(player.quick_slots[0].is_empty(), "RMB Devolveu Cheddar")
	slot_mozzarella.interact_return(player)
	assert_test(player.quick_slots[1].is_empty(), "RMB Devolveu Muçarela")
	slot_prato.interact_return(player)
	assert_test(player.quick_slots[2].is_empty(), "RMB Devolveu Prato")

	# -------------------------------------------------------------------------
	# 5. TESTE DE POLPAS (LARANJA, UVA, MORANGO)
	# -------------------------------------------------------------------------
	print("\n--- 5. POLPAS DE SUCO ---")
	_clear_player(player)
	inv.add_stock("pulp_orange", 10)
	inv.add_stock("pulp_grape", 10)

	pulp_table.take_pulp(player, 0) # Laranja
	pulp_table.take_pulp(player, 1) # Uva
	assert_test(player.quick_slots[0].get("item_id") == "pulp_orange", "LMB Slot 0: Polpa de Laranja")
	assert_test(player.quick_slots[1].get("item_id") == "pulp_grape", "LMB Slot 1: Polpa de Uva")

	# Devolve laranja com RMB na mesa
	pulp_table.interact_return(player)
	assert_test(player.quick_slots[0].is_empty(), "RMB Devolveu Polpa de Laranja")
	assert_test(player.quick_slots[1].get("item_id") == "pulp_grape", "Polpa de Uva mantida intacta")

	# -------------------------------------------------------------------------
	# 6. TESTE DE PÃES (TAMPA & BASE)
	# -------------------------------------------------------------------------
	print("\n--- 6. PÃES (Tampa do Pão e Base do Pão) ---")
	_clear_player(player)
	inv.add_stock("bread_top", 10)
	inv.add_stock("bread_bottom", 10)

	bread_rack.active_item_index = 0
	bread_rack.interact_item(player) # LMB Tampa
	bread_rack.active_item_index = 1
	bread_rack.interact_item(player) # LMB Base
	assert_test(player.quick_slots[0].get("item_id") == "bread_top", "LMB Slot 0: Tampa do Pão")
	assert_test(player.quick_slots[1].get("item_id") == "bread_bottom", "LMB Slot 1: Base do Pão")

	bread_rack.active_item_index = 0
	bread_rack.interact_return(player) # RMB Devolve Tampa
	assert_test(player.quick_slots[0].is_empty(), "RMB Devolveu Tampa do Pão")

	bread_rack.active_item_index = 1
	bread_rack.interact_return(player) # RMB Devolve Base
	assert_test(player.quick_slots[1].is_empty(), "RMB Devolveu Base do Pão")

	# -------------------------------------------------------------------------
	# 7. TESTE DE BACON E OVOS
	# -------------------------------------------------------------------------
	print("\n--- 7. BACON E OVOS ---")
	_clear_player(player)
	inv.add_stock("bacon", 10)
	inv.add_stock("egg", 10)

	bacon_egg.active_item_index = 0
	bacon_egg.interact_item(player) # LMB Bacon
	bacon_egg.active_item_index = 1
	bacon_egg.interact_item(player) # LMB Ovo
	assert_test(player.quick_slots[0].get("item_id") == "bacon", "LMB Slot 0: Bacon")
	assert_test(player.quick_slots[1].get("item_id") == "egg", "LMB Slot 1: Ovo")

	bacon_egg.active_item_index = 0
	bacon_egg.interact_return(player) # RMB Bacon
	assert_test(player.quick_slots[0].is_empty(), "RMB Devolveu Bacon")

	bacon_egg.active_item_index = 1
	bacon_egg.interact_return(player) # RMB Ovo
	assert_test(player.quick_slots[1].is_empty(), "RMB Devolveu Ovo")

	# -------------------------------------------------------------------------
	# 8. TESTE DE OBJETOS GRANDES (ÓLEO, BANDEJA, EMBALAGEM)
	# -------------------------------------------------------------------------
	print("\n--- 8. OBJETOS GRANDES (Óleo, Bandejas, Embalagens) ---")
	_clear_player(player)
	inv.add_stock("cooking_oil", 5)

	# Galão de Óleo
	oil_rack.interact_item(player) # LMB pega galão de óleo
	assert_test(player.held_item is CookingOil, "LMB Pegou Galão de Óleo na mão principal")
	oil_rack.interact_return(player) # RMB devolve galão
	assert_test(player.held_item == null, "RMB Devolveu Galão de Óleo à prateleira")

	# Bandeja de Serviço
	var tray_before = tray_stack.current_tray_count
	tray_stack.interact_item(player) # LMB pega bandeja
	assert_test(player.held_item is ServingTray, "LMB Pegou Bandeja na mão principal")
	assert_test(tray_stack.current_tray_count == tray_before - 1, "Pilha diminuiu (-1)")
	tray_stack.interact_return(player) # RMB devolve bandeja
	assert_test(player.held_item == null, "RMB Devolveu Bandeja à pilha")
	assert_test(tray_stack.current_tray_count == tray_before, "Pilha restaurada (+1)")

	# Embalagem (Caixa de Hambúrguer)
	inv.consume_stock("burger_box", 5)
	var box_stock_before = inv.get_stock("burger_box")
	var box_scene = load("res://src/items/burger_box.tscn")
	var b_box = box_scene.instantiate()
	root.add_child(b_box)
	player.pick_up(b_box) # LMB pega embalagem vazia
	assert_test(player.held_item != null, "Segurando Caixa de Hambúrguer")
	pack_station.interact_return(player) # RMB devolve embalagem
	assert_test(player.held_item == null, "RMB Devolveu Embalagem ao estoque")
	assert_test(inv.get_stock("burger_box") == box_stock_before + 1, "Estoque de Embalagem restaurado (+1)")

	# -------------------------------------------------------------------------
	# 9. TESTE DE INCOMPATIBILIDADE E PRESERVAÇÃO
	# -------------------------------------------------------------------------
	print("\n--- 9. INCOMPATIBILIDADE (Rejeição sem perda de itens) ---")
	_clear_player(player)
	inv.add_stock("tomato", 5)
	slot_tomato.interact_item(player) # Pega tomate (slot 0)

	var cheddar_stock = inv.get_stock("cheese_cheddar")
	slot_cheddar.interact_return(player) # Tenta devolver Tomate no Freezer de Queijo
	assert_test(inv.get_stock("cheese_cheddar") == cheddar_stock, "Estoque de Cheddar inalterado (rejeitou tomate)")
	assert_test(player.quick_slots[0].get("item_id") == "tomato", "Tomate intacto no Slot 0 (não foi destruído nem solto)")

	print("\n=================================================================")
	print("RESULTADO DO TESTE UNIVERSAL: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=================================================================\n")

	if passed_tests == total_tests:
		print(">>> SUCESSO ABSOLUTO: TODOS OS OBJETOS DO BURGER RUSH FUNCIONAM COM A REGRA GLOBAL! <<<\n")
		quit(0)
	else:
		printerr(">>> FALHA NOS TESTES UNIVERSAIS! <<<\n")
		quit(1)
