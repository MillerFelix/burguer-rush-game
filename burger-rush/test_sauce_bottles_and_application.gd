extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE BISNAGAS DE MOLHO E APLICAÇÃO FÍSICA")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	# =========================================================================
	# TESTE 1: BANCADA DE MOLHOS REORGANIZADA E LIMPA
	# =========================================================================
	print("\n--- Teste 1: Validação da Bancada de Molhos Centralizada e Limpa ---")
	var prep_table_scene = load("res://src/stations/prep_table.tscn")
	assert(prep_table_scene != null, "Cena prep_table.tscn deve existir")
	var sauce_station = prep_table_scene.instantiate() as PrepTable
	root.add_child(sauce_station)
	sauce_station.global_position = Vector3(1.95, 0, -8.35)
	sauce_station._ready()

	assert(not sauce_station.has_node("Model/GNPan1"), "Clutter antigo de salada/tomate removido da bancada")
	assert(not sauce_station.has_node("Model/SauceOrganizerRack"), "Plataforma preta removida: molhos repousam diretamente na madeira")
	assert(sauce_station.has_node("KetchupBottle"), "Bisnaga de Ketchup centralizada presente")
	assert(sauce_station.has_node("MustardBottle"), "Bisnaga de Mostarda centralizada presente")
	assert(sauce_station.has_node("MayoBottle"), "Bisnaga de Maionese centralizada presente")
	assert(sauce_station.has_node("SpecialSauceBottle"), "Bisnaga de Molho Especial centralizada presente")
	print("  [PASS] Bancada de molhos 100% limpa em madeira com 4 bisnagas diretamente sobre ela.")

	# =========================================================================
	# TESTE 2: PEGAR BISNAGA COM CLIQUE ESQUERDO E PROPRIEDADES DE COR/ESTOQUE
	# =========================================================================
	print("\n--- Teste 2: Retirada da Bisnaga com Clique Esquerdo e Dados Visuais ---")
	var ketchup_bottle = sauce_station.get_node("KetchupBottle") as SauceBottle
	assert(ketchup_bottle.current_amount == 100.0, "Bisnaga deve iniciar com 100% de molho")
	assert(ketchup_bottle.sauce_color.r > 0.7 and ketchup_bottle.sauce_color.g < 0.3, "Ketchup deve ter cor vermelha viva")

	var prompt_pick = ketchup_bottle.get_interaction_prompt(player)
	assert(prompt_pick.contains("Pegar") and prompt_pick.contains("Ketchup"), "Prompt deve indicar pegar Ketchup com clique esquerdo")

	player.pick_up(ketchup_bottle)
	assert(player.held_item == ketchup_bottle, "Jogador deve estar segurando a Bisnaga de Ketchup")
	assert(ketchup_bottle.location == Item.ItemLocation.PLAYER_HAND, "Localização atualizada para PLAYER_HAND")
	print("  [PASS] Bisnaga de Ketchup na mão do jogador (100%% restante, cor vermelha).")

	# =========================================================================
	# TESTE 3: INCLINAÇÃO E FLUXO CONTÍNUO AO SEGURAR CLIQUE ESQUERDO
	# =========================================================================
	print("\n--- Teste 3: Inclinação da Bisnaga e Fluxo Contínuo de Molho ---")
	# Inicia o aperto da bisnaga
	ketchup_bottle.start_squeezing()
	assert(ketchup_bottle.is_squeezing, "Bisnaga em estado de aperto/aplicação")

	# Simula 0.5s de aperto
	ketchup_bottle._process(0.5)
	assert(ketchup_bottle.tilt_progress > 0.5, "Bisnaga deve inclinar suavemente para baixo (~45°)")
	assert(ketchup_bottle.current_amount < 100.0, "Molho deve ser consumido gradualmente enquanto espremido")
	print("  [PASS] Bisnaga inclinada suavemente e consumindo molho (restam %.1f%%)." % ketchup_bottle.current_amount)

	# Solta o clique
	ketchup_bottle.stop_squeezing()
	assert(not ketchup_bottle.is_squeezing, "Aperto interrompido imediatamente")
	ketchup_bottle._process(0.5)
	assert(ketchup_bottle.tilt_progress < 0.1, "Bisnaga retorna suavemente à posição normal na mão")
	print("  [PASS] Fluxo interrompido e bisnaga desinclinada com sucesso.")

	# =========================================================================
	# TESTE 4: APLICAÇÃO REAL DE KETCHUP E MOSTARDA EM BURGERASSEMBLY
	# =========================================================================
	print("\n--- Teste 4: Aplicação Física e Reconhecimento de Molho na Montagem ---")
	var island_scene = load("res://src/stations/prep_island.tscn")
	var island = island_scene.instantiate() as PrepIsland
	root.add_child(island)
	island.global_position = Vector3(1.4, 0, -4.55)
	island._ready()

	# Monta base de pão + carne + queijo
	var bread_bot = load("res://src/items/bread_bottom.tscn").instantiate() as Item
	root.add_child(bread_bot)
	var ass_pos = island.global_position + Vector3(0, 0.90, 0)
	bread_bot.global_position = ass_pos
	bread_bot._ensure_assembly()
	var assembly = bread_bot.assembly

	var meat = load("res://src/items/patty.tscn").instantiate() as Item
	meat.set("state", Patty.State.COOKED)
	root.add_child(meat)
	assembly.add_ingredient(meat, ass_pos, 0.0)

	var cheese = load("res://src/items/cheese.tscn").instantiate() as Item
	root.add_child(cheese)
	assembly.add_ingredient(cheese, ass_pos, 0.0)

	# Aplica Ketchup sobre o burger via simulação de fluxo da bisnaga
	assembly.apply_sauce("ketchup", ketchup_bottle.sauce_color, ass_pos + Vector3(0.02, 0, -0.01), 1.8) # ~80%
	assert(assembly.applied_sauces.has("ketchup"), "Montagem deve registrar molho Ketchup")
	assert(assembly.applied_sauces["ketchup"] >= 60.0, "Quantidade aplicada de Ketchup deve atingir nível adequado")
	assert(assembly.sauce_visuals.size() > 0, "Traços visuais de molho gerados sobre o lanche")
	print("  [PASS] Ketchup aplicado no burger (%.1f%% registrado, %d traços visuais)." % [assembly.applied_sauces["ketchup"], assembly.sauce_visuals.size()])

	# Aplica Mostarda
	var mustard_bottle = sauce_station.get_node("MustardBottle") as SauceBottle
	assert(mustard_bottle.sauce_color.r > 0.8 and mustard_bottle.sauce_color.g > 0.6, "Mostarda com tom amarelo vibrante")
	assembly.apply_sauce("mustard", mustard_bottle.sauce_color, ass_pos + Vector3(-0.02, 0, 0.01), 1.8) # ~80%
	assert(assembly.applied_sauces.has("mustard"), "Montagem deve registrar molho Mostarda")
	print("  [PASS] Mostarda aplicada no burger (%.1f%% registrado)." % assembly.applied_sauces["mustard"])

	# =========================================================================
	# TESTE 5: FINALIZAÇÃO DO BURGER CLÁSSICO COM OS MOLHOS APLICADOS
	# =========================================================================
	print("\n--- Teste 5: Fechamento com Pão Superior e Validação de Receita com Molhos ---")
	var lettuce = load("res://src/items/lettuce.tscn").instantiate() as Item
	root.add_child(lettuce)
	assembly.add_ingredient(lettuce, ass_pos, 0.0)

	var tomato = load("res://src/items/tomato.tscn").instantiate() as Item
	root.add_child(tomato)
	assembly.add_ingredient(tomato, ass_pos, 0.0)

	var onion = load("res://src/items/onion.tscn").instantiate() as Item
	root.add_child(onion)
	assembly.add_ingredient(onion, ass_pos, 0.0)

	var bread_top = load("res://src/items/bread_top.tscn").instantiate() as Item
	root.add_child(bread_top)
	assembly.close_burger(bread_top, ass_pos, 0.0)

	assert(assembly.state == BurgerAssembly.State.CLOSED, "Lanche fechado")
	assert(assembly.is_valid_recipe, "Receita deve ser válida")
	assert(assembly.matched_recipe != null and assembly.matched_recipe.id == "burger_classic", "Burger Clássico reconhecido com molhos perfeitos")
	print("  [PASS] Burger Clássico reconhecido com sucesso com Ketchup e Mostarda!")

	# =========================================================================
	# TESTE 6: DROP LIVRE DA BISNAGA E PERSISTÊNCIA DA QUANTIDADE
	# =========================================================================
	print("\n--- Teste 6: Drop Livre da Bisnaga e Persistência do Volume ---")
	var remaining_ketchup = ketchup_bottle.current_amount
	assert(remaining_ketchup < 100.0, "Volume de ketchup foi consumido")

	# Solta a bisnaga na bancada de trabalho
	var drop_pos = island.global_position + Vector3(0.5, 0.90, -0.4)
	var held_bot = player.take_held_item()
	island._place_item_on_surface(held_bot, drop_pos, 0.0)
	assert(ketchup_bottle.location == Item.ItemLocation.WORLD, "Bisnaga repousando na bancada")
	assert(ketchup_bottle.get_parent() == root, "Bisnaga repousando no mundo")

	# Pega novamente
	player.pick_up(ketchup_bottle)
	assert(player.held_item == ketchup_bottle, "Jogador pegou a bisnaga de volta")
	assert(ketchup_bottle.current_amount == remaining_ketchup, "Quantidade restante permanece idêntica após pegar novamente")
	print("  [PASS] Bisnaga solta livremente na bancada e quantidade (%.1f%%) preservada." % ketchup_bottle.current_amount)

	# =========================================================================
	# TESTE 7: BISNAGA VAZIA (0%) BLOQUEIA APLICAÇÃO
	# =========================================================================
	print("\n--- Teste 7: Esgotamento da Bisnaga ao Atingir 0% ---")
	ketchup_bottle.current_amount = 0.0
	assert(ketchup_bottle.is_empty(), "Bisnaga considerada vazia")
	ketchup_bottle.start_squeezing()
	assert(not ketchup_bottle.is_squeezing, "Bisnaga vazia não permite saída de molho")
	print("  [PASS] Bisnaga vazia bloqueia saída de molho com sucesso.")

	# Limpeza
	player.take_held_item()
	ketchup_bottle.queue_free()
	assembly.queue_free()
	island.queue_free()
	sauce_station.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE BISNAGAS E MOLHOS FORAM APROVADOS!")
	print("============================================================")
	quit(0)
