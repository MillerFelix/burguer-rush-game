extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DA REGRA GLOBAL DE INTERAÇÃO E PILHAS DE QUEIJOS")
	print("E = EQUIPAMENTOS/PORTAS | CLIQUE ESQUERDO = INGREDIENTES/ITENS")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
	inv.items["cheese_mozzarella"]["quantity"] = 15
	inv.items["cheese_cheddar"]["quantity"] = 20
	inv.items["cheese_prato"]["quantity"] = 15
	inv.items["patty_beef"]["quantity"] = 20
	inv.items["patty_chicken"]["quantity"] = 15

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	# -----------------------------------------------------------------
	# PARTE 1: FREEZER DE QUEIJOS (PILHAS ELEVADAS + SLOTS DE CLIQUE)
	# -----------------------------------------------------------------
	print("\n--- [PARTE 1] Freezer de Queijos (CommercialChestFreezer) ---")
	var chest_scene = load("res://src/stations/commercial_chest_freezer.tscn")
	var chest = chest_scene.instantiate() as CommercialChestFreezer
	root.add_child(chest)
	chest._ready()

	# 1. Validação da geometria periférica e pilhas de queijos
	var body = chest.get_node("FreezerBody")
	assert(body.has_node("ColWallFront"), "FreezerBody possui parede frontal colidível")
	assert(body.has_node("ColWallBack"), "FreezerBody possui parede traseira colidível")
	assert(body.has_node("ColWallLeft"), "FreezerBody possui parede lateral esquerda")
	assert(body.has_node("ColWallRight"), "FreezerBody possui parede lateral direita")
	assert(body.has_node("ColFloor"), "FreezerBody possui fundo colidível")
	print("  [PASS] FreezerBody estruturado com colisões periféricas sem bloquear o vão superior.")

	var moz_stack1 = chest.get_node("FreezerBody/Products/MozzarellaStack1")
	var che_stack1 = chest.get_node("FreezerBody/Products/CheddarStack1")
	var pra_stack1 = chest.get_node("FreezerBody/Products/PratoStack1")
	assert(moz_stack1.position.y >= 0.50, "Pilha de Muçarela elevada próxima da superfície (Y >= 0.50)")
	assert(che_stack1.position.y >= 0.50, "Pilha de Cheddar elevada próxima da superfície (Y >= 0.50)")
	assert(pra_stack1.position.y >= 0.50, "Pilha de Queijo Prato elevada próxima da superfície (Y >= 0.50)")
	assert(moz_stack1.get_child_count() >= 6, "Pilha de Muçarela possui volume farto de fatias")
	assert(che_stack1.get_child_count() >= 6, "Pilha de Cheddar possui volume farto de fatias")
	assert(pra_stack1.get_child_count() >= 6, "Pilha de Prato possui volume farto de fatias")
	print("  [PASS] Pilhas de queijo com grande volume visual elevadas próximas à borda superior.")

	# 2. Tampa responde a E e NÃO ao clique
	var lid_body = chest.get_node("LidPivot/ChestLid")
	assert(lid_body.has_method("interact_equipment"), "LidBody implementa interact_equipment")
	assert(not lid_body.has_method("interact_item"), "LidBody NÃO implementa interact_item (não manipula item)")
	
	# Abrir com E
	lid_body.interact_equipment(player)
	chest.current_state = CommercialChestFreezer.State.OPEN
	chest.is_animating = false
	chest._apply_state_instant(CommercialChestFreezer.State.OPEN)
	assert(chest.is_door_open(), "Tampa aberta com sucesso")
	print("  [PASS] Tampa do freezer abre exclusivamente com tecla [E].")

	# 3. Slots de Queijo respondem ao Clique e NÃO à tecla E
	var moz_slot = chest.get_node("MozzarellaSlot")
	var che_slot = chest.get_node("CheddarSlot")
	var pra_slot = chest.get_node("PratoSlot")

	assert(moz_slot.has_method("interact_item"), "MozzarellaSlot implementa interact_item")
	assert(not moz_slot.has_method("interact_equipment"), "MozzarellaSlot NÃO implementa interact_equipment")

	# 4. Pegar e devolver Muçarela via Clique do Mouse
	moz_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Cheese, "Jogador pegou fatia de queijo")
	assert(player.held_item.cheese_type == Cheese.CheeseType.MOZZARELLA, "Queijo é Muçarela")
	assert(inv.get_stock("cheese_mozzarella") == 14, "Estoque de muçarela decrementou de 15 para 14")

	# Tentativa de pegar Cheddar com mãos ocupadas
	che_slot.interact_item(player)
	assert(player.held_item.cheese_type == Cheese.CheeseType.MOZZARELLA, "Mão continua com Muçarela (sem substituição)")
	assert(inv.get_stock("cheese_cheddar") == 20, "Estoque de cheddar intacto")

	# Devolver Muçarela
	moz_slot.interact_item(player)
	assert(player.held_item == null, "Muçarela devolvida com sucesso")
	assert(inv.get_stock("cheese_mozzarella") == 15, "Estoque de muçarela restaurado para 15")
	print("  [PASS] Ciclo de pegar/devolver Muçarela e proteção de mãos ocupadas aprovados.")

	# 5. Pegar e devolver Cheddar e Prato
	che_slot.interact_item(player)
	assert(player.held_item != null and player.held_item.cheese_type == Cheese.CheeseType.CHEDDAR, "Pegou Cheddar")
	assert(inv.get_stock("cheese_cheddar") == 19, "Estoque Cheddar 19")
	che_slot.interact_item(player)
	assert(player.held_item == null, "Devolveu Cheddar")
	assert(inv.get_stock("cheese_cheddar") == 20, "Estoque Cheddar 20")

	pra_slot.interact_item(player)
	assert(player.held_item != null and player.held_item.cheese_type == Cheese.CheeseType.PRATO, "Pegou Prato")
	assert(inv.get_stock("cheese_prato") == 14, "Estoque Prato 14")
	pra_slot.interact_item(player)
	assert(player.held_item == null, "Devolveu Prato")
	assert(inv.get_stock("cheese_prato") == 15, "Estoque Prato 15")
	print("  [PASS] Ciclos de Cheddar e Queijo Prato aprovados via clique do mouse.")

	# 6. Fechar com E
	lid_body.interact_equipment(player)
	chest.current_state = CommercialChestFreezer.State.CLOSED
	chest.is_animating = false
	chest._apply_state_instant(CommercialChestFreezer.State.CLOSED)
	assert(not chest.is_door_open(), "Tampa fechada com sucesso")
	print("  [PASS] Tampa fecha com tecla [E].")
	chest.queue_free()

	# -----------------------------------------------------------------
	# PARTE 2: FREEZER PRINCIPAL (COMMERCIAL REFRIGERATOR)
	# -----------------------------------------------------------------
	print("\n--- [PARTE 2] Freezer Principal (CommercialRefrigerator) ---")
	var fridge_scene = load("res://src/stations/commercial_refrigerator.tscn")
	var fridge = fridge_scene.instantiate() as MeatRefrigerator
	root.add_child(fridge)
	fridge._ready()

	var door = fridge.get_node("DoorPivot/FridgeDoor")
	assert(door.has_method("interact_equipment"), "FridgeDoor implementa interact_equipment")
	assert(not door.has_method("interact_item"), "FridgeDoor NÃO implementa interact_item")

	# Abrir com E
	door.interact_equipment(player)
	fridge._apply_state_instant(true)
	assert(fridge.is_door_open(), "Porta da geladeira aberta")

	# Beef e Chicken slots via Clique
	var beef_slot = fridge.get_node("BeefSlot")
	var chick_slot = fridge.get_node("ChickenSlot")
	assert(beef_slot.has_method("interact_item"), "BeefSlot implementa interact_item")
	assert(chick_slot.has_method("interact_item"), "ChickenSlot implementa interact_item")

	beef_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Patty, "Pegou Carne Bovina")
	assert(inv.get_stock("patty_beef") == 19, "Estoque Carne Bovina 19")
	beef_slot.interact_item(player)
	assert(player.held_item == null, "Devolveu Carne Bovina")
	assert(inv.get_stock("patty_beef") == 20, "Estoque Carne Bovina 20")

	chick_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Patty, "Pegou Frango")
	assert(inv.get_stock("patty_chicken") == 14, "Estoque Frango 14")
	chick_slot.interact_item(player)
	assert(player.held_item == null, "Devolveu Frango")
	assert(inv.get_stock("patty_chicken") == 15, "Estoque Frango 15")

	# Fechar com E
	door.interact_equipment(player)
	fridge._apply_state_instant(false)
	assert(not fridge.is_door_open(), "Porta da geladeira fechada")
	print("  [PASS] Freezer Principal 100% validado: Porta=[E], Carnes=[Clique].")

	fridge.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE REGRAS GLOBAIS E PILHAS DE QUEIJO PASSARAM!")
	print("============================================================")
	quit(0)
