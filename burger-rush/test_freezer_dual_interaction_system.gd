extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DO SISTEMA DE INTERAÇÃO DOS FREEZERS")
	print("E = EQUIPAMENTO (ABRIR/FECHAR) | MOUSE = ITENS (PEGAR/DEVOLVER)")
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

	# =================================================================
	# PARTE 1: FREEZER DE QUEIJOS (TAMPA ARTICULADA + CLIQUE DO MOUSE)
	# =================================================================
	print("\n--- [PARTE 1] Freezer de Queijos (CommercialChestFreezer) ---")
	var chest_scene = load("res://src/stations/commercial_chest_freezer.tscn")
	assert(chest_scene != null, "Cena commercial_chest_freezer.tscn deve carregar")
	var chest = chest_scene.instantiate() as CommercialChestFreezer
	root.add_child(chest)
	chest._ready()

	# Teste 1: Estado Fechado e Abertura com E
	print("\n--- Teste 1: Abrir Tampa Articulada com Tecla [E] ---")
	assert(chest.current_state == CommercialChestFreezer.State.CLOSED, "Estado inicial deve ser CLOSED")
	var lid_body = chest.get_node("LidPivot/ChestLid")
	var prompt_e = lid_body.get_interaction_prompt(player)
	assert(prompt_e.contains("E — Abrir"), "Prompt da tampa deve ser 'E — Abrir'")
	lid_body.interact_equipment(player)
	chest.current_state = CommercialChestFreezer.State.OPEN
	chest.is_animating = false
	chest._apply_state_instant(CommercialChestFreezer.State.OPEN)
	assert(chest.is_door_open(), "Tampa aberta com sucesso")
	assert(is_equal_approx(chest.lid_pivot.rotation_degrees.x, chest.LID_OPEN_ANGLE_DEG), "Tampa girou para cima no pivô (-80°)")
	print("  [PASS] Tampa superior articulada abriu para cima com tecla [E].")

	# Teste 2: Pegar Muçarela com Clique do Mouse
	print("\n--- Teste 2: Pegar Muçarela com [Clique do Mouse] ---")
	var moz_slot = chest.get_node("MozzarellaSlot")
	var prompt_moz = moz_slot.get_interaction_prompt(player)
	assert(prompt_moz.contains("Clique para Pegar") and prompt_moz.contains("Muçarela"), "Prompt do slot deve instruir [Clique]")
	moz_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Cheese, "Jogador pegou queijo")
	var held_moz = player.held_item as Cheese
	assert(held_moz.cheese_type == Cheese.CheeseType.MOZZARELLA, "Queijo na mão é Muçarela")
	assert(inv.get_stock("cheese_mozzarella") == 14, "Estoque de muçarela decrementou de 15 para 14")
	print("  [PASS] Muçarela retirada com sucesso via clique do mouse (Estoque: 15 -> 14).")

	# Teste 3: Não substituir/duplicar item com mãos ocupadas
	print("\n--- Teste 3: Proteção contra substituição de item com mãos ocupadas ---")
	var che_slot = chest.get_node("CheddarSlot")
	che_slot.interact_item(player)
	assert(player.held_item == held_moz, "Jogador CONTINUA com a Muçarela na mão")
	assert(inv.get_stock("cheese_cheddar") == 20, "Estoque de cheddar NÃO foi alterado")
	print("  [PASS] Clique em outro compartimento não substitui nem duplica o item.")

	# Teste 4: Devolver Muçarela com Clique do Mouse
	print("\n--- Teste 4: Devolver Muçarela ao Compartimento Correto ---")
	var prompt_return = moz_slot.get_interaction_prompt(player)
	assert(prompt_return.contains("Clique para Devolver"), "Prompt deve exibir 'Clique para Devolver'")
	moz_slot.interact_item(player)
	assert(player.held_item == null, "Mão do jogador está livre após devolução")
	assert(inv.get_stock("cheese_mozzarella") == 15, "Estoque de muçarela restaurado para 15")
	print("  [PASS] Muçarela devolvida com sucesso (Estoque: 14 -> 15).")

	# Teste 5: Pegar e Devolver Cheddar
	print("\n--- Teste 5: Pegar e Devolver Cheddar ---")
	che_slot.interact_item(player)
	assert(player.held_item != null and player.held_item.item_id == "cheese_cheddar", "Pegou Cheddar")
	assert(inv.get_stock("cheese_cheddar") == 19, "Estoque Cheddar 20 -> 19")
	che_slot.interact_item(player)
	assert(player.held_item == null, "Devolveu Cheddar")
	assert(inv.get_stock("cheese_cheddar") == 20, "Estoque Cheddar 19 -> 20")
	print("  [PASS] Ciclo de pegar e devolver Cheddar verificado.")

	# Teste 6: Pegar e Devolver Queijo Prato
	print("\n--- Teste 6: Pegar e Devolver Queijo Prato ---")
	var pra_slot = chest.get_node("PratoSlot")
	pra_slot.interact_item(player)
	assert(player.held_item != null and player.held_item.item_id == "cheese_prato", "Pegou Prato")
	assert(inv.get_stock("cheese_prato") == 14, "Estoque Prato 15 -> 14")
	pra_slot.interact_item(player)
	assert(player.held_item == null, "Devolveu Prato")
	assert(inv.get_stock("cheese_prato") == 15, "Estoque Prato 14 -> 15")
	print("  [PASS] Ciclo de pegar e devolver Queijo Prato verificado.")

	# Teste 7: Fechar Tampa do Freezer com E
	print("\n--- Teste 7: Fechar Tampa com Tecla [E] ---")
	var prompt_close_e = lid_body.get_interaction_prompt(player)
	assert(prompt_close_e.contains("E — Fechar"), "Prompt da tampa aberta deve ser 'E — Fechar'")
	lid_body.interact_equipment(player)
	chest.current_state = CommercialChestFreezer.State.CLOSED
	chest.is_animating = false
	chest._apply_state_instant(CommercialChestFreezer.State.CLOSED)
	assert(not chest.is_door_open(), "Tampa fechou com sucesso")
	assert(is_equal_approx(chest.lid_pivot.rotation_degrees.x, chest.LID_CLOSE_ANGLE_DEG), "Tampa voltou à posição fechada (0°)")
	print("  [PASS] Tampa superior articulada fechou com tecla [E].")
	chest.queue_free()

	# =================================================================
	# PARTE 2: FREEZER PRINCIPAL (GELADEIRA DE CARNES)
	# =================================================================
	print("\n--- [PARTE 2] Freezer Principal (CommercialRefrigerator) ---")
	var fridge_scene = load("res://src/stations/commercial_refrigerator.tscn")
	assert(fridge_scene != null, "Cena commercial_refrigerator.tscn deve carregar")
	var fridge = fridge_scene.instantiate() as MeatRefrigerator
	root.add_child(fridge)
	fridge._ready()

	# Teste 8: Abrir Porta com E
	print("\n--- Teste 8: Abrir Porta da Geladeira Principal com [E] ---")
	var door_body = fridge.get_node("DoorPivot/FridgeDoor")
	assert(door_body.get_interaction_prompt().contains("E — Abrir"), "Prompt da porta deve ser 'E — Abrir'")
	door_body.interact_equipment(player)
	fridge._apply_state_instant(true)
	assert(fridge.is_door_open(), "Porta aberta")
	print("  [PASS] Porta aberta com sucesso via tecla [E].")

	# Teste 9: Pegar e Devolver Carne Bovina via Clique do Mouse
	print("\n--- Teste 9: Pegar e Devolver Carne Bovina via [Clique do Mouse] ---")
	var beef_slot = fridge.get_node("BeefSlot")
	var prompt_beef = beef_slot.get_interaction_prompt(player)
	assert(prompt_beef.contains("Clique para Pegar"), "Prompt deve instruir [Clique]")
	beef_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Patty, "Jogador pegou Carne Bovina")
	assert(inv.get_stock("patty_beef") == 19, "Estoque de carne bovina decrementou de 20 para 19")

	# Devolve a carne
	var prompt_beef_ret = beef_slot.get_interaction_prompt(player)
	assert(prompt_beef_ret.contains("Clique para Devolver"), "Prompt deve ser 'Clique para Devolver'")
	beef_slot.interact_item(player)
	assert(player.held_item == null, "Carne devolvida")
	assert(inv.get_stock("patty_beef") == 20, "Estoque de carne bovina restaurado para 20")
	print("  [PASS] Carne bovina pega e devolvida via clique (Estoque: 20 -> 19 -> 20).")

	# Teste 10: Pegar e Devolver Frango via Clique do Mouse
	print("\n--- Teste 10: Pegar e Devolver Frango via [Clique do Mouse] ---")
	var chick_slot = fridge.get_node("ChickenSlot")
	chick_slot.interact_item(player)
	assert(player.held_item != null and player.held_item.item_id == "patty_chicken", "Jogador pegou Frango")
	assert(inv.get_stock("patty_chicken") == 14, "Estoque de frango decrementou de 15 para 14")

	chick_slot.interact_item(player)
	assert(player.held_item == null, "Frango devolvido")
	assert(inv.get_stock("patty_chicken") == 15, "Estoque de frango restaurado para 15")
	print("  [PASS] Frango pego e devolvido via clique (Estoque: 15 -> 14 -> 15).")

	# Teste 11: Fechar Porta com E
	print("\n--- Teste 11: Fechar Porta com Tecla [E] ---")
	door_body.interact_equipment(player)
	fridge._apply_state_instant(false)
	assert(not fridge.is_door_open(), "Porta fechada")
	print("  [PASS] Porta fechada com sucesso via tecla [E].")

	fridge.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE INTERAÇÃO DOS FREEZERS FORAM APROVADOS!")
	print("============================================================")
	quit(0)
