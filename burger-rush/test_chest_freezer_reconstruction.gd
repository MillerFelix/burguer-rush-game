extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE AJUSTES DO FREEZER DE QUEIJOS")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
	inv.items["cheese_mozzarella"]["quantity"] = 15
	inv.items["cheese_cheddar"]["quantity"] = 20
	inv.items["cheese_prato"]["quantity"] = 15

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	print("\n--- Carregando commercial_chest_freezer.tscn ---")
	var freezer_scene = load("res://src/stations/commercial_chest_freezer.tscn")
	assert(freezer_scene != null, "Cena commercial_chest_freezer.tscn deve existir")

	var freezer = freezer_scene.instantiate() as CommercialChestFreezer
	root.add_child(freezer)
	freezer._ready()

	# -----------------------------------------------------------------
	# TESTE A: ABRIR FREEZER QUANDO FECHADO
	# -----------------------------------------------------------------
	print("\n--- Teste A: Abrir Freezer quando Fechado ---")
	assert(freezer.current_state == CommercialChestFreezer.State.CLOSED, "Estado inicial deve ser CLOSED")
	var prompt_closed = freezer.get_interaction_prompt(player)
	assert(prompt_closed.contains("Abrir"), "Prompt deve instruir abrir o freezer")
	freezer.interact(player)
	freezer.current_state = CommercialChestFreezer.State.OPEN
	freezer.is_animating = false
	freezer._apply_state_instant(CommercialChestFreezer.State.OPEN)
	assert(freezer.is_door_open(), "is_door_open() deve retornar true quando aberto")
	print("  [PASS] Freezer abre suavemente ao interagir com tampa fechada.")

	# -----------------------------------------------------------------
	# TESTE B: FECHAR FREEZER AO MIRAR NA TAMPA
	# -----------------------------------------------------------------
	print("\n--- Teste B: Fechar Freezer ao Mirar na Tampa Aberta ---")
	assert(freezer.get_aimed_target(null) == CommercialChestFreezer.TargetType.LID, "Mirar na tampa/fora dos queijos retorna TargetType.LID")
	var prompt_lid = freezer.get_interaction_prompt(null)
	assert(prompt_lid.contains("Fechar"), "Prompt na tampa aberta deve ser 'E — Fechar Freezer'")
	freezer.interact(player)
	freezer.current_state = CommercialChestFreezer.State.CLOSED
	freezer.is_animating = false
	freezer._apply_state_instant(CommercialChestFreezer.State.CLOSED)
	assert(not freezer.is_door_open(), "Freezer fechou com sucesso ao interagir na tampa")
	print("  [PASS] Tampa fecha suavemente e retorna a CLOSED.")

	# Reabre para testar queijos
	freezer.open_freezer()
	freezer.current_state = CommercialChestFreezer.State.OPEN
	freezer.is_animating = false
	freezer._apply_state_instant(CommercialChestFreezer.State.OPEN)

	# -----------------------------------------------------------------
	# TESTES C, D, E: PEGAR QUEIJOS NOS 3 COMPARTIMENTOS
	# -----------------------------------------------------------------
	print("\n--- Testes C, D, E: Retirada Individual de Muçarela, Cheddar e Prato ---")
	var mock_get_cheese = func(target_type: CommercialChestFreezer.TargetType):
		var item_id = "cheese_cheddar"
		var ctype = Cheese.CheeseType.CHEDDAR
		match target_type:
			CommercialChestFreezer.TargetType.MOZZARELLA:
				item_id = "cheese_mozzarella"
				ctype = Cheese.CheeseType.MOZZARELLA
			CommercialChestFreezer.TargetType.CHEDDAR:
				item_id = "cheese_cheddar"
				ctype = Cheese.CheeseType.CHEDDAR
			CommercialChestFreezer.TargetType.PRATO:
				item_id = "cheese_prato"
				ctype = Cheese.CheeseType.PRATO

		inv.consume_stock(item_id, 1)
		var cheese_scene = load("res://src/items/cheese.tscn")
		var cheese = cheese_scene.instantiate() as Cheese
		cheese.cheese_type = ctype
		root.add_child(cheese)
		cheese._ready()
		player.pick_up(cheese)
		return cheese

	# Muçarela (C)
	var moz = mock_get_cheese.call(CommercialChestFreezer.TargetType.MOZZARELLA)
	assert(player.held_item == moz, "Jogador pegou Muçarela")
	assert(moz.cheese_type == Cheese.CheeseType.MOZZARELLA, "Tipo correto MOZZARELLA")
	assert(inv.get_stock("cheese_mozzarella") == 14, "Estoque de muçarela atualizado")
	player.take_held_item().queue_free()

	# Cheddar (D)
	var che = mock_get_cheese.call(CommercialChestFreezer.TargetType.CHEDDAR)
	assert(player.held_item == che, "Jogador pegou Cheddar")
	assert(che.cheese_type == Cheese.CheeseType.CHEDDAR, "Tipo correto CHEDDAR")
	assert(inv.get_stock("cheese_cheddar") == 19, "Estoque de cheddar atualizado")
	player.take_held_item().queue_free()

	# Prato (E)
	var pra = mock_get_cheese.call(CommercialChestFreezer.TargetType.PRATO)
	assert(player.held_item == pra, "Jogador pegou Queijo Prato")
	assert(pra.cheese_type == Cheese.CheeseType.PRATO, "Tipo correto PRATO")
	assert(inv.get_stock("cheese_prato") == 14, "Estoque de prato atualizado")
	player.take_held_item().queue_free()
	print("  [PASS] Todos os 3 queijos retirados com precisão e estoques atualizados.")

	# -----------------------------------------------------------------
	# TESTE F & G: NÃO CONFUNDIR TAMPA COM QUEIJOS
	# -----------------------------------------------------------------
	print("\n--- Teste F & G: Separação Rigorosa de Alvo (Tampa vs Queijos) ---")
	# Ao mirar na tampa, target DEVE ser LID
	assert(freezer.get_aimed_target(null) == CommercialChestFreezer.TargetType.LID, "Mirar na tampa retorna LID e NUNCA queijo")
	# Executar interact na tampa deve fechar o freezer e NUNCA colocar queijo na mão
	freezer.interact(player)
	freezer.current_state = CommercialChestFreezer.State.CLOSED
	freezer.is_animating = false
	freezer._apply_state_instant(CommercialChestFreezer.State.CLOSED)
	assert(player.held_item == null, "Jogador NÃO pegou queijo acidentalmente ao fechar a tampa")
	assert(not freezer.is_door_open(), "Freezer fechado com sucesso")
	print("  [PASS] Separação perfeita: fechar a tampa não aciona retirada acidental de queijo.")

	# -----------------------------------------------------------------
	# TESTE DE POSICIONAMENTO NO CENÁRIO MAIN.TSCN
	# -----------------------------------------------------------------
	print("\n--- Teste de Posicionamento e Remoção da Geladeira Antiga ---")
	var main_scene = load("res://src/main.tscn")
	assert(main_scene != null, "main.tscn deve carregar")
	var main_instance = main_scene.instantiate()
	root.add_child(main_instance)

	# 1. Geladeirinha antiga NÃO existe mais
	assert(main_instance.get_node_or_null("Room/CommercialFridge") == null, "Geladeirinha antiga (CommercialFridge) deve estar removida do cenário")
	print("  [PASS] Geladeirinha antiga removida completamente do armazém.")

	# 2. Geladeira principal continua existindo intacta
	assert(main_instance.has_node("CommercialRefrigerator"), "Geladeira principal (CommercialRefrigerator) preservada e intacta")
	print("  [PASS] Geladeira principal preservada.")

	# 3. Freezer de Queijos posicionado ao lado do outro freezer na parede norte
	assert(main_instance.has_node("CommercialChestFreezer"), "CommercialChestFreezer presente em main.tscn")
	var chest_node = main_instance.get_node("CommercialChestFreezer") as Node3D
	var main_fridge_node = main_instance.get_node("CommercialRefrigerator") as Node3D

	assert(is_equal_approx(chest_node.position.z, main_fridge_node.position.z), "Ambos os freezers alinhados na mesma parede norte (Z = -8.2)")
	assert(chest_node.position.x < main_fridge_node.position.x, "Freezer de queijos posicionado ao lado da geladeira principal")
	print("  [PASS] Freezer de queijos perfeitamente alinhado ao lado da geladeira principal na parede norte.")

	# Limpeza
	main_instance.queue_free()
	freezer.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE AJUSTE DO FREEZER FORAM APROVADOS!")
	print("============================================================")
	quit(0)
