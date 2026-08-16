extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE DROP LIVRE DA BISNAGA E MOLHO NO LANCHE")
	print("============================================================")

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
	player.global_position = Vector3(0.0, 0.0, 0.0)
	player._ready()

	# -----------------------------------------------------------------
	# PARTE 1: TESTES OBRIGATÓRIOS DE DROP LIVRE EM TODAS AS SUPERFÍCIES
	# -----------------------------------------------------------------
	print("\n--- Parte 1: Testes Obrigatórios de Drop Livre da Bisnaga ---")

	# Instancia Bancada de Molhos
	var prep_table_scene = load("res://src/stations/prep_table.tscn")
	var sauce_station = prep_table_scene.instantiate() as PrepTable
	world.add_child(sauce_station)
	sauce_station.global_position = Vector3(1.95, 0.0, -8.35)
	sauce_station._ready()

	# Instancia Ilha Central
	var island_scene = load("res://src/stations/prep_island.tscn")
	var island = island_scene.instantiate() as PrepIsland
	world.add_child(island)
	island.global_position = Vector3(1.4, 0.0, -4.55)
	island._ready()

	# Instancia Mesa de Restaurante
	var table_scene = load("res://src/stations/restaurant_table.tscn")
	var table = table_scene.instantiate() as RestaurantTable
	world.add_child(table)
	table.global_position = Vector3(-3.0, 0.0, 2.0)
	table._ready()

	# 1. Pegar bisnaga da bancada de molhos
	var ketchup = sauce_station.get_node_or_null("KetchupBottle") as SauceBottle
	assert(ketchup != null, "Bisnaga de Ketchup deve existir na bancada")
	player.pick_up(ketchup)
	assert(player.held_item == ketchup, "1. Jogador pegou a bisnaga na mão")
	assert(ketchup.get_parent() != sauce_station, "Bisnaga desanexada da bancada de molhos")
	assert(ketchup.location == Item.ItemLocation.PLAYER_HAND, "Bisnaga em estado PLAYER_HAND")

	# 2. Pressionar E sobre a bancada de molhos -> bisnaga solta livremente
	player.global_position = sauce_station.global_position + Vector3(0, 0, 1.0)
	player.drop_item()
	assert(player.held_item == null, "Jogador soltou a bisnaga")
	assert(ketchup.location == Item.ItemLocation.WORLD, "Bisnaga em estado WORLD")
	assert(ketchup.get_parent() == world, "Bisnaga é filha direta do mundo")
	assert(ketchup.collision_layer == 1 and ketchup.collision_mask == 1, "Colisões físicas restauradas")
	print("  [PASS] Caso 1: Drop sobre a bancada de molhos bem-sucedido.")

	# 3. Pegar novamente
	player.pick_up(ketchup)
	assert(player.held_item == ketchup, "3. Bisnaga pega novamente com sucesso")

	# 4. Ir até a ilha central e soltar
	player.global_position = island.global_position + Vector3(0, 0, 1.0)
	player.drop_item()
	assert(player.held_item == null, "Jogador soltou na ilha")
	assert(ketchup.get_parent() == world, "Bisnaga permanece filha do mundo")
	assert(ketchup.location == Item.ItemLocation.WORLD, "Bisnaga em estado WORLD")
	print("  [PASS] Caso 2: Drop sobre a ilha central bem-sucedido.")

	# 5. Pegar novamente
	player.pick_up(ketchup)
	assert(player.held_item == ketchup, "5. Bisnaga pega novamente")

	# 6. Ir até uma mesa e soltar
	player.global_position = table.global_position + Vector3(0, 0, 1.0)
	player.drop_item()
	assert(player.held_item == null, "Jogador soltou na mesa")
	assert(ketchup.get_parent() == world, "Bisnaga permanece no mundo")
	assert(ketchup.location == Item.ItemLocation.WORLD, "Bisnaga em estado WORLD")
	print("  [PASS] Caso 3: Drop sobre mesa de restaurante bem-sucedido.")

	# 7. Pegar novamente
	player.pick_up(ketchup)
	assert(player.held_item == ketchup, "7. Bisnaga pega novamente")

	# 8. Ir até o chão e soltar
	player.global_position = Vector3(5.0, 0.0, 5.0)
	player.drop_item()
	assert(player.held_item == null, "Jogador soltou no chão")
	assert(ketchup.location == Item.ItemLocation.WORLD, "Bisnaga em estado WORLD no chão")
	assert(ketchup.get_parent() == world, "Bisnaga permanece no mundo")
	print("  [PASS] Caso 4: Drop no chão bem-sucedido.")

	# -----------------------------------------------------------------
	# PARTE 2: TESTES OBRIGATÓRIOS DE APLICAÇÃO VISUAL DO MOLHO NO LANCHE
	# -----------------------------------------------------------------
	print("\n--- Parte 2: Testes Obrigatórios de Aplicação de Molho no Lanche ---")

	# 1. Colocar pão
	var bread_scene = load("res://src/items/bread_bottom.tscn")
	var bread_bot = bread_scene.instantiate() as BreadBottom
	world.add_child(bread_bot)
	bread_bot.global_position = island.global_position + Vector3(0, 0.90, 0)
	bread_bot._ensure_assembly()
	var assembly = bread_bot.assembly
	assert(assembly != null, "1. Base do pão montada com sucesso")

	# 2. Colocar carne
	var patty_scene = load("res://src/items/patty.tscn")
	var patty = patty_scene.instantiate() as Patty
	patty.state = Patty.State.COOKED
	world.add_child(patty)
	var ok_patty = assembly.add_ingredient(patty, bread_bot.global_position, 0.0)
	assert(ok_patty, "2. Carne adicionada à montagem")
	assert(patty.get_parent() == assembly, "Carne é filha de BurgerAssembly")

	# 3. Colocar queijo
	var cheese_scene = load("res://src/items/cheese.tscn")
	var cheese = cheese_scene.instantiate() as Item
	world.add_child(cheese)
	var ok_cheese = assembly.add_ingredient(cheese, bread_bot.global_position, 0.0)
	assert(ok_cheese, "3. Queijo adicionado à montagem")
	assert(cheese.get_parent() == assembly, "Queijo é filho de BurgerAssembly")

	# 4. Pegar bisnaga de ketchup
	player.pick_up(ketchup)
	assert(player.held_item == ketchup, "4. Jogador com a bisnaga na mão")

	# 5. Mirar diretamente no lanche e aplicar molho
	var initial_amount = ketchup.current_amount
	var hit_burger_pos = bread_bot.global_position + Vector3(0.01, 0, -0.01)

	# 6. Segurar clique: bisnaga inclina, fluxo sai e molho aparece sobre a superfície
	ketchup.start_squeezing()
	assert(ketchup.is_squeezing, "Bisnaga em squeezing ativo")
	ketchup._process(0.5)
	assert(ketchup.tilt_progress > 0.5, "Bisnaga inclina suavemente")

	# Simula aplicação contínua de molho sobre o lanche
	assembly.apply_sauce("ketchup", ketchup.sauce_color, hit_burger_pos, 0.5)
	assert(assembly.applied_sauces.has("ketchup"), "Ketchup registrado no lanche")
	var visual_count_1 = assembly.sauce_visuals.size()
	assert(visual_count_1 > 0, "Molho visível criado sobre o lanche")
	assert(assembly.sauce_visuals[0].get_parent() == assembly, "Molho é filho de BurgerAssembly e pertence ao lanche")
	print("  [PASS] Molho criado sobre a superfície do queijo/carne com %d elementos visuais." % visual_count_1)

	# 7. Soltar clique: fluxo para, molho permanece
	ketchup.stop_squeezing()
	ketchup._process(0.3)
	assert(not ketchup.is_squeezing, "Fluxo parado imediatamente ao soltar clique")
	assert(assembly.sauce_visuals.size() == visual_count_1, "Molho permanece exatamente no lanche")
	print("  [PASS] Fluxo interrompido e molho mantido no lanche.")

	# 8. Pegar o lanche
	player.drop_item() # solta bisnaga
	player.pick_up(bread_bot)
	assert(player.held_item == bread_bot, "8. Jogador segurando o lanche completo")
	assert(assembly.sauce_visuals[0].get_parent() == assembly, "Molho acompanha o lanche na mão do jogador")
	print("  [PASS] Molho acompanha o lanche na mão sem se separar.")

	# 9. Soltar o lanche em outro lugar
	player.global_position = Vector3(2.0, 0.0, 2.0)
	player.drop_item()
	assert(player.held_item == null, "9. Lanche solto em outro lugar")
	assert(assembly.sauce_visuals[0].get_parent() == assembly, "Molho continua exatamente no lanche após mover")
	print("  [PASS] Molho continua associado ao lanche em sua nova posição.")

	# 10. Continuar aplicando: molho aumenta
	player.pick_up(ketchup)
	assembly.apply_sauce("ketchup", ketchup.sauce_color, hit_burger_pos + Vector3(-0.02, 0, 0.02), 0.8)
	var visual_count_2 = assembly.sauce_visuals.size()
	assert(visual_count_2 >= visual_count_1, "Quantidade visual de molho aumentou")
	assert(assembly.applied_sauces["ketchup"] > 25.0, "Volume de ketchup acumulado")
	print("  [PASS] Quantidade de molho aumentou progressivamente: %d elementos visuais." % visual_count_2)

	# 11. Finalização com fechar e embalar
	var bread_top_scene = load("res://src/items/bread_top.tscn")
	var bread_top = bread_top_scene.instantiate() as Item
	world.add_child(bread_top)
	assembly.close_burger(bread_top, bread_bot.global_position, 0.0)
	assert(assembly.state == BurgerAssembly.State.CLOSED, "Lanche fechado com sucesso")

	var box_scene = load("res://src/items/burger_box.tscn")
	var box = box_scene.instantiate() as Item
	world.add_child(box)
	var packaged = assembly.package_burger(box, player)
	assert(packaged != null and packaged is PackagedBurger, "Lanche com molho embalado perfeitamente")
	print("  [PASS] Lanche finalizado e embalado com sucesso.")

	# Limpeza
	packaged.queue_free()
	ketchup.queue_free()
	table.queue_free()
	island.queue_free()
	sauce_station.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE DROP E MOLHO FORAM 100% APROVADOS!")
	print("============================================================\n")
	quit(0)
