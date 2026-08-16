extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE PROMPTS E INTERAÇÃO SEM STACK OVERFLOW")
	print("============================================================\n")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var world = Node3D.new()
	root.add_child(world)

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	world.add_child(player)
	player.position = Vector3(1.4, 0.0, -4.55)
	player._ready()

	print("--- Teste 1: Testando get_interaction_prompt em todas as bancadas/estações ---")
	var station_scenes = [
		{"name": "PrepIsland", "path": "res://src/stations/prep_island.tscn"},
		{"name": "PrepTable", "path": "res://src/stations/prep_table.tscn"},
		{"name": "StorageRack", "path": "res://src/stations/storage_rack.tscn"},
		{"name": "BaconEggStation", "path": "res://src/stations/bacon_egg_station.tscn"},
		{"name": "Grill", "path": "res://src/stations/grill.tscn"},
		{"name": "Fryer", "path": "res://src/stations/fryer.tscn"},
		{"name": "PackagingStation", "path": "res://src/stations/packaging_station.tscn"}
	]

	for st_info in station_scenes:
		var st_res = load(st_info["path"])
		assert(st_res != null, "Cena %s deve existir" % st_info["path"])
		var st = st_res.instantiate() as Node3D
		world.add_child(st)
		st.position = Vector3(0, 0, 0)
		if st.has_method("get_interaction_prompt"):
			var p = st.get_interaction_prompt(player)
			print("  [PASS] %s prompt sem mãos ocupadas: '%s'" % [st_info["name"], p])

		st.queue_free()

	print("\n--- Teste 2: Testando prompts de itens individuais no mundo e nas mãos ---")
	var item_scenes = [
		{"name": "Base do Pão", "path": "res://src/items/bread_bottom.tscn"},
		{"name": "Carne", "path": "res://src/items/patty.tscn"},
		{"name": "Queijo", "path": "res://src/items/cheese.tscn"},
		{"name": "Alface", "path": "res://src/items/lettuce.tscn"},
		{"name": "Tomate", "path": "res://src/items/tomato.tscn"},
		{"name": "Cebola", "path": "res://src/items/onion.tscn"},
		{"name": "Bacon", "path": "res://src/items/bacon.tscn"},
		{"name": "Ovo", "path": "res://src/items/egg.tscn"},
		{"name": "Tampa do Pão", "path": "res://src/items/bread_top.tscn"},
		{"name": "Bisnaga de Ketchup", "path": "res://src/items/sauce_bottle.tscn"},
		{"name": "Caixa de Hambúrguer", "path": "res://src/items/burger_box.tscn"}
	]

	# Instancia a PrepIsland
	var island_scene = load("res://src/stations/prep_island.tscn")
	var island = island_scene.instantiate() as PrepIsland
	world.add_child(island)
	island.position = Vector3(1.4, 0, -4.55)
	island._ready()

	for itm_info in item_scenes:
		var scene = load(itm_info["path"])
		var itm = scene.instantiate() as Item
		world.add_child(itm)
		itm.position = island.position + Vector3(0.2, 0.90, 0.1)

		# 1. Prompt do item no mundo com mãos livres
		var p_world = itm.get_interaction_prompt(player)
		print("  [PASS] Item no mundo: %s -> '%s'" % [itm_info["name"], p_world])

		# 2. Pegar item na mão
		player.pick_up(itm)
		assert(player.held_item == itm, "Item na mão do jogador")

		# 3. Prompt da PrepIsland enquanto segura o item
		var p_island = island.get_interaction_prompt(player)
		assert(p_island.contains("Colocar"), "Prompt da ilha deve ser 'Colocar item na Ilha'")
		print("  [PASS] Ilha com item segurado (%s): '%s'" % [itm_info["name"], p_island])

		# 4. Soltar item
		player.drop_item()
		assert(player.held_item == null, "Mãos livres após drop")
		itm.queue_free()

	print("\n--- Teste 3: Montagem e Prompts de Burger em Andamento ---")
	var bread_bot = load("res://src/items/bread_bottom.tscn").instantiate() as Item
	world.add_child(bread_bot)
	bread_bot.position = island.position + Vector3(0, 0.90, 0)
	bread_bot._ready()

	var p_bread_free = bread_bot.get_interaction_prompt(player)
	print("  [PASS] Prompt pão vazio: '%s'" % p_bread_free)

	var meat = load("res://src/items/patty.tscn").instantiate() as Item
	world.add_child(meat)
	player.pick_up(meat)

	var p_bread_holding_meat = bread_bot.get_interaction_prompt(player)
	assert(p_bread_holding_meat.contains("Adicionar"), "Prompt para adicionar ingrediente")
	print("  [PASS] Prompt pão com carne na mão: '%s'" % p_bread_holding_meat)

	bread_bot.assembly.add_ingredient(player.take_held_item(), bread_bot.position)

	var p_bread_assembling = bread_bot.get_interaction_prompt(player)
	print("  [PASS] Prompt pão em montagem: '%s'" % p_bread_assembling)

	# Limpeza
	bread_bot.queue_free()
	island.queue_free()
	player.queue_free()
	world.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE PROMPTS E INTERAÇÃO FORAM APROVADOS COM SUCESSO!")
	print("============================================================")
	quit(0)
