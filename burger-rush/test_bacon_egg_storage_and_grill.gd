extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE ARMAZENAMENTO E PREPARO DE BACON E OVO")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
	inv.items["bacon"]["quantity"] = 15
	inv.items["egg"]["quantity"] = 15
	inv.items["bread"]["quantity"] = 20
	inv.items["patty_beef"]["quantity"] = 20
	inv.items["cheese_cheddar"]["quantity"] = 20
	inv.items["cheese_prato"]["quantity"] = 20
	inv.items["lettuce"]["quantity"] = 20
	inv.items["tomato"]["quantity"] = 20
	inv.items["mayo"]["quantity"] = 20

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	# =========================================================================
	# TESTE 1: INSTANCIAÇÃO DA BANCADA DE BACON E OVO NO ARMAZÉM
	# =========================================================================
	print("\n--- Teste 1: Instanciação da Bancada de Armazenamento de Bacon & Ovo ---")
	var station_scene = load("res://src/stations/bacon_egg_station.tscn")
	assert(station_scene != null, "Cena bacon_egg_station.tscn deve carregar com sucesso")
	var station = station_scene.instantiate() as BaconEggStation
	root.add_child(station)
	station._ready()

	assert(station.has_node("Model/TableTop"), "Tampo da mesa deve existir")
	assert(station.has_node("Model/Leg1"), "Pernas da mesa devem existir")
	assert(station.has_node("Model/LowerShelf"), "Prateleira inferior deve existir")
	assert(station.has_node("Model/TableFrontBadge"), "Placa frontal deve existir")
	assert(station.has_node("Model/TableFrontLabel"), "Label da placa frontal deve existir")
	var front_lbl = station.get_node("Model/TableFrontLabel") as Label3D
	assert(front_lbl.text.contains("BACON") and front_lbl.text.contains("OVOS"), "Placa frontal deve identificar Bacon & Ovos")
	print("  [PASS] Estrutura da bancada e identificação visual '🥓 BACON & OVOS 🥚' aprovadas.")

	# =========================================================================
	# TESTE 2: ÁREA DE ARMAZENAMENTO DE BACON (PACOTES EMPILHADOS)
	# =========================================================================
	print("\n--- Teste 2: Embalagens/Pacotes de Bacon na Bancada ---")
	assert(station.has_node("Model/BaconArea/Packs"), "Pacotes de bacon empilhados devem existir")
	assert(station.has_node("Model/BaconArea/Packs/Pack1"), "Pacote de bacon 1 deve existir")
	assert(station.has_node("Model/BaconArea/Packs/Pack1/Tray"), "Bandeja da embalagem de bacon deve existir")
	assert(station.has_node("Model/BaconArea/Packs/Pack1/Film"), "Filme plástico da embalagem deve existir")
	assert(station.has_node("Model/BaconArea/Packs/Pack1/Slice1"), "Fatia de bacon visível dentro da embalagem")
	assert(station.has_node("Model/BaconArea/Label"), "Label de estoque do bacon deve existir")
	print("  [PASS] Pacotes de bacon com embalagem e fatias visíveis organizados na bancada.")

	# =========================================================================
	# TESTE 3: ÁREA DE ARMAZENAMENTO DE OVOS (CESTO COM OVOS INDIVIDUAIS)
	# =========================================================================
	print("\n--- Teste 3: Cesto com Ovos Individuais na Bancada ---")
	assert(station.has_node("Model/EggArea/Basket"), "Estrutura do cesto de ovos deve existir")
	assert(station.has_node("Model/EggArea/Basket/Bottom"), "Fundo do cesto deve existir")
	assert(station.has_node("Model/EggArea/Eggs"), "Contêiner de ovos individuais deve existir")
	assert(station.has_node("Model/EggArea/Eggs/Egg1"), "Ovo individual 1 deve existir")
	assert(station.has_node("Model/EggArea/Eggs/Egg8"), "Ovo individual 8 deve existir no cesto")
	assert(station.has_node("Model/EggArea/Label"), "Label de estoque dos ovos deve existir")
	print("  [PASS] Cesto de ovos com múltiplas unidades individuais 3D visíveis.")

	# =========================================================================
	# TESTE 4: INTERAÇÃO, RETIRADA E DEVOLUÇÃO DE BACON
	# =========================================================================
	print("\n--- Teste 4: Interação de Retirada e Devolução de Bacon ---")
	station.active_item_index = 0 # Bacon
	var initial_bacon_stock = inv.get_stock("bacon")
	assert(initial_bacon_stock == 15, "Estoque inicial de bacon deve ser 15")

	var prompt_bacon = station.get_interaction_prompt(player)
	assert(prompt_bacon.contains("Bacon") and prompt_bacon.contains("15"), "Prompt deve indicar Bacon e estoque 15")

	# Tecla E NÃO deve pegar bacon com mãos vazias
	station.interact(player)
	assert(player.held_item == null, "Tecla E NÃO deve pegar bacon com mãos vazias")
	assert(inv.get_stock("bacon") == 15, "Estoque permanece inalterado com tecla E")

	# Jogador pega a tirinha de bacon com CLIQUE ESQUERDO (interact_item)
	station.interact_item(player)
	assert(player.held_item != null and player.held_item is Bacon, "Jogador deve estar segurando item Bacon")
	assert(player.held_item.state == Bacon.State.RAW, "Bacon retirado do armazém deve estar CRU (RAW)")
	assert(inv.get_stock("bacon") == 14, "Estoque de bacon deve ser reduzido para 14")
	print("  [PASS] Retirada de tirinha de bacon crua com Clique Esquerdo (estoque reduzido de 15 para 14).")

	# Jogador devolve a tirinha de bacon com CLIQUE ESQUERDO (interact_item)
	var prompt_dev_bacon = station.get_interaction_prompt(player)
	assert(prompt_dev_bacon.contains("Devolver"), "Prompt deve indicar devolução quando segurando bacon cru")
	station.interact_item(player)
	assert(player.held_item == null, "Jogador deve ter soltado/devolvido o bacon")
	assert(inv.get_stock("bacon") == 15, "Estoque de bacon deve ter retornado para 15")
	print("  [PASS] Devolução de bacon cru com Clique Esquerdo (estoque restaurado para 15).")

	# =========================================================================
	# TESTE 5: INTERAÇÃO, RETIRADA E DEVOLUÇÃO DE OVO
	# =========================================================================
	print("\n--- Teste 5: Interação de Retirada e Devolução de Ovo ---")
	station.active_item_index = 1 # Ovo
	var initial_egg_stock = inv.get_stock("egg")
	assert(initial_egg_stock == 15, "Estoque inicial de ovos deve ser 15")

	var prompt_egg = station.get_interaction_prompt(player)
	assert(prompt_egg.contains("Ovo") and prompt_egg.contains("15"), "Prompt deve indicar Ovo e estoque 15")

	# Tecla E NÃO deve pegar ovo com mãos vazias
	station.interact(player)
	assert(player.held_item == null, "Tecla E NÃO deve pegar ovo com mãos vazias")
	assert(inv.get_stock("egg") == 15, "Estoque permanece inalterado com tecla E")

	# Jogador pega um ovo do cesto com CLIQUE ESQUERDO (interact_item)
	station.interact_item(player)
	assert(player.held_item != null and player.held_item is Egg, "Jogador deve estar segurando item Egg")
	assert(player.held_item.state == Egg.State.RAW, "Ovo retirado do armazém deve ser ovo cru inteiro (RAW)")
	assert(inv.get_stock("egg") == 14, "Estoque de ovos deve ser reduzido para 14")
	print("  [PASS] Retirada de ovo individual cru com Clique Esquerdo (estoque reduzido de 15 para 14).")

	# Jogador devolve o ovo ao cesto com CLIQUE ESQUERDO (interact_item)
	var prompt_dev_egg = station.get_interaction_prompt(player)
	assert(prompt_dev_egg.contains("Devolver"), "Prompt deve indicar devolução quando segurando ovo cru")
	station.interact_item(player)
	assert(player.held_item == null, "Jogador deve ter soltado/devolvido o ovo")
	assert(inv.get_stock("egg") == 15, "Estoque de ovos deve ter retornado para 15")
	print("  [PASS] Devolução de ovo cru com Clique Esquerdo (estoque restaurado para 15).")

	# =========================================================================
	# TESTE 6: PREPARO E ESTADOS DO BACON NA GRELHA
	# =========================================================================
	print("\n--- Teste 6: Preparo e Ciclo de Estados do Bacon na Grelha ---")
	var grill_scene = load("res://src/stations/grill.tscn")
	assert(grill_scene != null, "Cena grill.tscn deve existir")
	var grill = grill_scene.instantiate() as Grill
	root.add_child(grill)
	grill._ready()

	# Pega um bacon cru
	station.active_item_index = 0
	station.interact_item(player)
	var bacon_item = player.held_item as Bacon
	assert(bacon_item != null and bacon_item.state == Bacon.State.RAW, "Bacon cru em mãos")

	# Coloca na chapa
	var prompt_grill_bacon = grill.get_interaction_prompt(player)
	assert(prompt_grill_bacon.contains("Colocar") and prompt_grill_bacon.contains("Bacon"), "Prompt da chapa para colocar bacon")
	grill.interact(player)
	assert(player.held_item == null, "Bacon colocado na chapa")
	assert(grill.active_items.size() == 1, "Chapa deve conter 1 item")
	assert(bacon_item.state == Bacon.State.COOKING, "Bacon na chapa deve entrar em COOKING")
	print("  [PASS] Bacon colocado na chapa (Estado 1: RAW -> Estado 2: COOKING).")

	# Avança tempo para cozinhar o bacon (~2.3 segundos)
	grill._process(2.3)
	assert(bacon_item.state == Bacon.State.COOKED, "Bacon deve atingir estado COOKED (Pronto)")
	assert(bacon_item.get_ingredient_key() == "bacon", "Bacon pronto deve fornecer chave de ingrediente 'bacon'")
	print("  [PASS] Bacon atinge ponto pronto (Estado 3: COOKED).")

	# Avança tempo para queimar o bacon (~4.5 segundos adicionais)
	grill._process(4.5)
	assert(bacon_item.state == Bacon.State.BURNT, "Bacon deve queimar se deixado tempo demais na chapa")
	assert(bacon_item.get_ingredient_key() == "bacon:burnt", "Bacon queimado deve fornecer chave 'bacon:burnt'")
	print("  [PASS] Bacon queima se passar do tempo (Estado 4: BURNT).")

	# Retira o bacon queimado da chapa
	grill.interact(player)
	assert(player.held_item == bacon_item and bacon_item.state == Bacon.State.BURNT, "Bacon queimado retirado")
	player.take_held_item().queue_free()

	# =========================================================================
	# TESTE 7: PREPARO E CICLO DE ESTADOS DO OVO NA GRELHA
	# =========================================================================
	print("\n--- Teste 7: Preparo e Ciclo de Estados do Ovo na Grelha ---")
	# Pega um ovo cru com Clique Esquerdo
	station.active_item_index = 1
	station.interact_item(player)
	var egg_item = player.held_item as Egg
	assert(egg_item != null and egg_item.state == Egg.State.RAW, "Ovo cru em mãos")

	# Coloca na chapa
	var prompt_grill_egg = grill.get_interaction_prompt(player)
	assert(prompt_grill_egg.contains("Colocar") and prompt_grill_egg.contains("Ovo"), "Prompt da chapa para colocar ovo")
	grill.interact(player)
	assert(player.held_item == null, "Ovo colocado na chapa")
	assert(grill.active_items.size() == 1, "Chapa deve conter 1 item")
	assert(egg_item.state == Egg.State.CRACKED, "Ovo ao tocar a chapa quebra visualmente (CRACKED)")
	print("  [PASS] Ovo colocado na chapa e aberto visualmente (Estado 1: RAW -> Estado 2: CRACKED).")

	# Fritura inicial
	grill._process(0.4)
	assert(egg_item.state == Egg.State.COOKING, "Ovo começa a fritar na chapa (COOKING)")
	print("  [PASS] Ovo fritando com clara mudando de aparência (Estado 3: COOKING).")

	# Ponto ideal de fritura (~2.2 segundos adicionais -> total ~2.6s)
	grill._process(2.2)
	assert(egg_item.state == Egg.State.COOKED, "Ovo atinge o ponto ideal de fritura (COOKED)")
	assert(egg_item.get_ingredient_key() == "egg", "Ovo frito pronto deve fornecer chave de ingrediente 'egg'")
	print("  [PASS] Ovo frito pronto com clara e gema apetitosas (Estado 4: COOKED).")

	# Fase intermediária de ressecamento (~3.0s adicionais)
	grill._process(3.0)
	assert(egg_item.state == Egg.State.DRYING, "Ovo entra na fase intermediária de ressecamento (DRYING)")
	print("  [PASS] Ovo passando do ponto / ressecando bordas (Estado 5: DRYING).")

	# Queimado (~3.0s adicionais)
	grill._process(3.0)
	assert(egg_item.state == Egg.State.BURNT, "Ovo queima e estraga se abandonado na chapa (BURNT)")
	print("  [PASS] Ovo queima completamente (Estado 6: BURNT).")

	# Retira o ovo queimado
	grill.interact(player)
	player.take_held_item().queue_free()

	# =========================================================================
	# TESTE 8: MONTAGEM COMPLETA DE RECEITAS COM BACON E OVO NA PREP TABLE
	# =========================================================================
	print("\n--- Teste 8: Montagem de Sanduíches com Bacon e Ovo Prontos ---")
	var prep_scene = load("res://src/stations/prep_table.tscn")
	assert(prep_scene != null, "Cena prep_table.tscn deve existir")
	var prep = prep_scene.instantiate() as PrepTable
	root.add_child(prep)
	prep._ready()

	# 1. Cria ingredientes para Burger Bacon: Pão + Carne bovina pronta + Queijo prato + Bacon pronto + Maionese
	var b_bun = load("res://src/items/bread.tscn").instantiate()
	var b_meat = load("res://src/items/patty.tscn").instantiate() as Patty
	b_meat.set_state(Patty.State.COOKED)
	var b_cheese = load("res://src/items/cheese.tscn").instantiate()
	b_cheese.item_id = "cheese_prato"
	var b_bacon = load("res://src/items/bacon.tscn").instantiate() as Bacon
	b_bacon.set_state(Bacon.State.COOKED)
	var b_mayo = load("res://src/items/sauce.tscn").instantiate()
	b_mayo.item_id = "mayo"

	prep._place_item(b_bun)
	prep._place_item(b_meat)
	prep._place_item(b_cheese)
	prep._place_item(b_bacon)
	prep._place_item(b_mayo)

	assert(prep.placed_items.size() == 1, "Receita de Burger Bacon deve montar lanche final")
	var finished_bacon_burger = prep.placed_items[0]
	assert(finished_bacon_burger.item_id == "x_bacon" or finished_bacon_burger.item_id == "burger_bacon" or finished_bacon_burger.item_id == "burger", "Burger Bacon criado com sucesso")
	print("  [PASS] Burger Bacon montado perfeitamente utilizando bacon grelhado.")
	prep.placed_items.clear()
	finished_bacon_burger.queue_free()

	# 2. Cria ingredientes para Burger Egg: Pão + Carne bovina pronta + Queijo prato + Alface + Tomate + Ovo frito
	var e_bun = load("res://src/items/bread.tscn").instantiate()
	var e_meat = load("res://src/items/patty.tscn").instantiate() as Patty
	e_meat.set_state(Patty.State.COOKED)
	var e_cheese = load("res://src/items/cheese.tscn").instantiate()
	e_cheese.item_id = "cheese_prato"
	var e_lettuce = load("res://src/items/lettuce.tscn").instantiate()
	var e_tomato = load("res://src/items/tomato.tscn").instantiate()
	var e_egg = load("res://src/items/egg.tscn").instantiate() as Egg
	e_egg.set_state(Egg.State.COOKED)

	prep._place_item(e_bun)
	prep._place_item(e_meat)
	prep._place_item(e_cheese)
	prep._place_item(e_lettuce)
	prep._place_item(e_tomato)
	prep._place_item(e_egg)

	assert(prep.placed_items.size() == 1, "Receita de Burger Egg deve montar lanche final")
	var finished_egg_burger = prep.placed_items[0]
	print("  [PASS] Burger Egg montado perfeitamente utilizando ovo frito pronto.")
	prep.placed_items.clear()
	finished_egg_burger.queue_free()

	# Limpeza
	prep.queue_free()
	grill.queue_free()
	station.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE BACON E OVO FORAM CONCLUÍDOS COM SUCESSO!")
	print("============================================================")
	quit(0)
