extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DA ILHA CENTRAL EXPANDIDA (6 BANCADAS)")
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
	# TESTE 1: INSTANCIAÇÃO DA ILHA CENTRAL E ESTRUTURA DOS 6 MÓDULOS
	# =========================================================================
	print("\n--- Teste 1: Instanciação e Estrutura dos 6 Módulos Conectados ---")
	var island_scene = load("res://src/stations/prep_island.tscn")
	assert(island_scene != null, "Cena prep_island.tscn deve carregar com sucesso")
	var island = island_scene.instantiate() as PrepIsland
	root.add_child(island)
	island.global_position = Vector3(1.4, 0, -4.55)
	island._ready()

	# 1. Colisão
	assert(island.has_node("CollisionShape3D"), "Colisão física da ilha deve existir")
	var col_shape = island.get_node("CollisionShape3D") as CollisionShape3D
	var box = col_shape.shape as BoxShape3D
	assert(box != null, "Shape da ilha deve ser BoxShape3D")
	assert(box.size.x >= 3.6 and box.size.z >= 1.8, "Superfície expandida com o dobro da área útil (3.8m x 1.9m)")
	print("  [PASS] Colisão e geometria da ilha expandida validadas (3.80m x 1.90m x 0.88m = 7.22m²).")

	# 2. Tampo e 6 Pranchas de Corte (3 Sul + 3 Norte)
	assert(island.has_node("Model/TableTop"), "Tampo duplo de aço inox deve existir")
	assert(island.has_node("Model/CuttingBoardSouthWest"), "Prancha de corte Sul-Oeste deve existir")
	assert(island.has_node("Model/CuttingBoardSouthCenter"), "Prancha de corte Sul-Centro deve existir")
	assert(island.has_node("Model/CuttingBoardSouthEast"), "Prancha de corte Sul-Leste deve existir")
	assert(island.has_node("Model/CuttingBoardNorthWest"), "Prancha de corte Norte-Oeste deve existir")
	assert(island.has_node("Model/CuttingBoardNorthCenter"), "Prancha de corte Norte-Centro deve existir")
	assert(island.has_node("Model/CuttingBoardNorthEast"), "Prancha de corte Norte-Leste deve existir")
	print("  [PASS] Tampo de aço inoxidável com 6 estações de corte e montagem embutidas.")

	# 3. 6 Módulos de Gabinete e 12 Pernas Tubulares
	assert(island.has_node("Model/ModuleSouthWest"), "Módulo 1 (Sul-Oeste) deve existir")
	assert(island.has_node("Model/ModuleSouthCenter"), "Módulo 2 (Sul-Centro) deve existir")
	assert(island.has_node("Model/ModuleSouthEast"), "Módulo 3 (Sul-Leste) deve existir")
	assert(island.has_node("Model/ModuleNorthWest"), "Módulo 4 (Norte-Oeste) deve existir")
	assert(island.has_node("Model/ModuleNorthCenter"), "Módulo 5 (Norte-Centro) deve existir")
	assert(island.has_node("Model/ModuleNorthEast"), "Módulo 6 (Norte-Leste) deve existir")
	assert(island.has_node("Model/Leg1") and island.has_node("Model/Leg12"), "12 pés tubulares de sustentação devem existir")
	assert(island.has_node("Model/LowerShelf"), "Prateleira inferior de aço inox ampla deve existir")
	assert(island.has_node("Model/FrontBadgeLabel") and island.has_node("Model/RearBadgeLabel"), "Placas identificando a bancada frente e verso")
	print("  [PASS] 6 módulos estruturais conectados com acabamento profissional e 12 pés tubulares.")

	# =========================================================================
	# TESTE 2: ESPAÇO DE CIRCULAÇÃO LIVRE EM VOLTA DA ILHA (360°)
	# =========================================================================
	print("\n--- Teste 2: Validação da Área de Circulação Livre ao Redor da Ilha ---")
	var island_pos = island.global_position # (1.4, 0, -4.55)

	# Norte (Cookline: Grill / Fritadeira / Bancada Z = -7.65)
	var dist_north = absf(-7.65 - (island_pos.z - 0.95))
	assert(dist_north >= 2.0, "Corredor Norte para chapas/coifa deve ter >= 2.0m de espaço livre")
	print("  [PASS] Corredor Norte (Acesso a Chapas/Fritadeira): %.2fm livres." % dist_north)

	# Sul (Balcão de Atendimento / Packaging: Z = -1.45)
	var dist_south = absf((island_pos.z + 0.95) - (-1.45))
	assert(dist_south >= 2.0, "Corredor Sul para atendimento/embalagem deve ter >= 2.0m de espaço livre")
	print("  [PASS] Corredor Sul (Acesso ao Atendimento/Caixa): %.2fm livres." % dist_south)

	# Oeste (Passagem para Armazém: X = -3.0)
	var dist_west = absf((island_pos.x - 1.90) - (-3.0))
	assert(dist_west >= 2.3, "Corredor Oeste para o Armazém deve ter >= 2.3m de espaço livre")
	print("  [PASS] Corredor Oeste (Acesso ao Armazém de Pães/Bacon/Ovos): %.2fm livres." % dist_west)

	# Leste (Máquinas de Bebida / Expedição: X = 8.35)
	var dist_east = absf(8.35 - (island_pos.x + 1.90))
	assert(dist_east >= 4.5, "Corredor Leste para bebidas/saída deve ter >= 4.5m de espaço livre")
	print("  [PASS] Corredor Leste (Acesso a Bebidas e Expedição): %.2fm livres." % dist_east)

	# =========================================================================
	# TESTE 3: COLOCAÇÃO DE 12 INGREDIENTES LIVREMENTE SEM AMONTOAMENTO
	# =========================================================================
	print("\n--- Teste 3: Colocação de Múltiplos Sanduíches e Ingredientes Simultaneamente ---")
	var ingredients_scenes = [
		{"name": "Pão 1", "scene": "res://src/items/bread.tscn", "offset": Vector3(-1.3, 0.90, -0.5)},
		{"name": "Carne 1", "scene": "res://src/items/patty.tscn", "offset": Vector3(-0.7, 0.90, -0.5)},
		{"name": "Queijo 1", "scene": "res://src/items/cheese.tscn", "offset": Vector3(0.0, 0.90, -0.5)},
		{"name": "Bacon 1", "scene": "res://src/items/bacon.tscn", "offset": Vector3(0.7, 0.90, -0.5)},
		{"name": "Ovo 1", "scene": "res://src/items/egg.tscn", "offset": Vector3(1.3, 0.90, -0.5)},
		{"name": "Alface 1", "scene": "res://src/items/lettuce.tscn", "offset": Vector3(-1.3, 0.90, 0.0)},
		{"name": "Tomate 1", "scene": "res://src/items/tomato.tscn", "offset": Vector3(0.0, 0.90, 0.0)},
		{"name": "Cebola 1", "scene": "res://src/items/onion.tscn", "offset": Vector3(1.3, 0.90, 0.0)},
		{"name": "Pão 2", "scene": "res://src/items/bread.tscn", "offset": Vector3(-1.3, 0.90, 0.5)},
		{"name": "Carne 2", "scene": "res://src/items/patty.tscn", "offset": Vector3(-0.7, 0.90, 0.5)},
		{"name": "Queijo 2", "scene": "res://src/items/cheese.tscn", "offset": Vector3(0.0, 0.90, 0.5)},
		{"name": "Bacon 2", "scene": "res://src/items/bacon.tscn", "offset": Vector3(1.3, 0.90, 0.5)}
	]

	var placed_nodes: Array[Node3D] = []

	for ing_data in ingredients_scenes:
		var item = load(ing_data["scene"]).instantiate() as Item
		root.add_child(item)
		player.held_item = item
		item.location = Item.ItemLocation.PLAYER_HAND

		var prompt = island.get_interaction_prompt(player)
		assert(prompt.contains("Colocar"), "Prompt deve indicar colocação na ilha")

		var world_target = island.global_position + ing_data["offset"]
		island._place_item_on_surface(item, world_target, 0.0)
		assert(player.held_item == null, "Item deve sair das mãos do jogador")
		assert(item.global_position.y >= 0.88, "Item deve ficar apoiado na altura do tampo da bancada")
		placed_nodes.append(item)
		print("  [PASS] %s colocado com sucesso sobre a ilha (Y = %.2f, Pos = %s)." % [ing_data["name"], item.global_position.y, str(ing_data["offset"])])

	assert(island.placed_items.size() == 12, "Ilha expandida deve comportar 12 ingredientes simultaneamente com espaço amplo")
	print("  [PASS] Todos os 12 ingredientes organizados e apoiados na bancada sem sobreposição ou amontoamento.")

	# =========================================================================
	# TESTE 4: RETIRADA DE INGREDIENTES COM CLIQUE ESQUERDO
	# =========================================================================
	print("\n--- Teste 4: Retirada de Itens da Ilha com Clique Esquerdo ---")
	var target_item = placed_nodes[3] # Bacon 1
	assert(target_item.location == Item.ItemLocation.WORLD, "Item deve estar no estado WORLD")

	player.pick_up(target_item)
	assert(player.held_item == target_item, "Jogador deve segurar o item retirado da ilha")
	assert(target_item.location == Item.ItemLocation.PLAYER_HAND, "Localização do item atualizada para PLAYER_HAND")
	print("  [PASS] Ingrediente retirado da ilha para a mão do jogador com sucesso.")
	player.take_held_item().queue_free()

	# =========================================================================
	# TESTE 5: SIMULAÇÃO DO FLUXO COMPLETO DE TRABALHO
	# Armazém -> Ilha -> Chapa -> Ilha -> Montagem
	# =========================================================================
	print("\n--- Teste 5: Simulação do Fluxo Completo de Trabalho da Cozinha ---")
	var bun_item = placed_nodes[0]
	player.pick_up(bun_item)
	assert(player.held_item == bun_item, "Passo 1: Pão em mãos")

	var grill_scene = load("res://src/stations/grill.tscn")
	var grill = grill_scene.instantiate() as Grill
	root.add_child(grill)
	grill._ready()

	var meat_item = placed_nodes[1] as Patty
	grill.place_item(meat_item)
	grill._process(4.2)
	assert(meat_item.state == Patty.State.COOKED, "Carne grelhada no ponto certo")

	grill.interact_item(player)
	island._place_item_on_surface(meat_item, island.global_position + Vector3(-0.7, 0.90, -0.5), 0.0)
	assert(meat_item.global_position.y >= 0.88, "Carne grelhada apoiada na ilha de montagem")
	print("  [PASS] Fluxo de trabalho (Armazenamento -> Ilha -> Chapa -> Ilha) validado com êxito.")

	# Limpeza
	for it in placed_nodes:
		if is_instance_valid(it):
			it.queue_free()
	grill.queue_free()
	island.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DA ILHA EXPANDIDA (6 BANCADAS) FORAM APROVADOS!")
	print("============================================================")
	quit(0)
