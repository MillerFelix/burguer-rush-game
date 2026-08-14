extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DA REORGANIZAÇÃO COMPLETA DO ARMAZÉM")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
	inv.items["patty"]["quantity"] = 30
	inv.items["bacon"]["quantity"] = 30
	inv.items["bread"]["quantity"] = 30
	inv.items["cheese"]["quantity"] = 30
	inv.items["tomato"]["quantity"] = 30
	inv.items["lettuce"]["quantity"] = 30
	inv.items["potato_raw"]["quantity"] = 30

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	# 1. Instancia Geladeira Comercial de Carnes
	print("\n--- Teste 1: Geladeira Comercial de Carnes (3 Compartimentos) ---")
	var fridge_scene = load("res://src/stations/commercial_refrigerator.tscn")
	assert(fridge_scene != null, "Cena commercial_refrigerator.tscn deve existir")
	var fridge = fridge_scene.instantiate()
	root.add_child(fridge)
	fridge._ready()

	assert(fridge.compartments.size() == 3, "Geladeira deve ter 3 compartimentos")
	assert(fridge.has_node("Model/ShelfTop"), "Geladeira deve ter Prateleira Superior")
	assert(fridge.has_node("Model/ShelfMid"), "Geladeira deve ter Prateleira Média")
	assert(fridge.has_node("Model/ShelfBot"), "Geladeira deve ter Prateleira Inferior")
	assert(fridge.has_node("Model/DoorLeft") and fridge.has_node("Model/DoorRight"), "Geladeira deve ter portas duplas")

	# Teste de pegar carne bovina
	fridge.active_compartment_index = 0 # Bovina
	fridge.interact(player)
	assert(player.held_item != null and player.held_item is Patty, "Jogador deve pegar carne bovina da geladeira")
	player.take_held_item().queue_free()
	print("  [PASS] Carne bovina retirada da geladeira com sucesso")

	# Teste de pegar bacon
	fridge.active_compartment_index = 2 # Bacon
	fridge.interact(player)
	assert(player.held_item != null and player.held_item.item_id == "bacon", "Jogador deve pegar bacon da geladeira")
	player.take_held_item().queue_free()
	print("  [PASS] Bacon retirado da geladeira com sucesso")

	# 2. Instancia Estante Multiníveis do Armazém
	print("\n--- Teste 2: Estante Multiníveis (Pão, Queijo, Batata, Tomate, Alface) ---")
	var rack_scene = load("res://src/stations/storage_rack.tscn")
	assert(rack_scene != null, "Cena storage_rack.tscn deve existir")
	var rack = rack_scene.instantiate()
	root.add_child(rack)
	rack._ready()

	assert(rack.items_data.size() == 5, "Estante deve suportar 5 ingredientes organizados")
	assert(rack.has_node("Model/ShelfTop"), "Estante deve ter Nível Superior")
	assert(rack.has_node("Model/ShelfMid"), "Estante deve ter Nível Médio")
	assert(rack.has_node("Model/ShelfBot"), "Estante deve ter Nível Inferior")

	var ingredients_to_test = [
		{"idx": 0, "id": "bread", "name": "Pão"},
		{"idx": 1, "id": "cheese", "name": "Queijo"},
		{"idx": 2, "id": "potato_raw", "name": "Batata"},
		{"idx": 3, "id": "tomato", "name": "Tomate"},
		{"idx": 4, "id": "lettuce", "name": "Alface"}
	]

	for item_test in ingredients_to_test:
		rack.active_item_index = item_test["idx"]
		rack.interact(player)
		assert(player.held_item != null, "Jogador deve pegar %s" % item_test["name"])
		assert(player.held_item.item_id == item_test["id"], "ID do item deve ser %s" % item_test["id"])
		print("  [PASS] %s retirado da estante com sucesso" % item_test["name"])
		player.take_held_item().queue_free()

	# 3. Montagem com Ingredientes Básicos Desbloqueados na PrepTable
	print("\n--- Teste 3: Montagem de X-Salada com Ingredientes do Armazém ---")
	var prep_scene = load("res://src/stations/prep_table.tscn")
	var prep_table = prep_scene.instantiate() as PrepTable
	root.add_child(prep_table)
	prep_table._ready()

	# Pão
	var bread = load("res://src/items/bread.tscn").instantiate()
	root.add_child(bread)
	player.pick_up(bread)
	prep_table.interact(player)

	# Carne Cozida
	var patty = load("res://src/items/patty.tscn").instantiate() as Patty
	patty.state = Patty.State.COOKED
	root.add_child(patty)
	player.pick_up(patty)
	prep_table.interact(player)

	# Queijo
	var cheese = load("res://src/items/cheese.tscn").instantiate()
	root.add_child(cheese)
	player.pick_up(cheese)
	prep_table.interact(player)

	# Alface
	var lettuce = load("res://src/items/lettuce.tscn").instantiate()
	root.add_child(lettuce)
	player.pick_up(lettuce)
	prep_table.interact(player)

	# Tomate
	var tomato = load("res://src/items/tomato.tscn").instantiate()
	root.add_child(tomato)
	player.pick_up(tomato)
	prep_table.interact(player)

	# Jogador pega o sanduíche finalizado da mesa
	prep_table.interact(player)
	assert(player.held_item != null, "Jogador deve receber o lanche finalizado")
	assert(player.held_item.item_id == "x_salada", "Lanche finalizado deve ser um X-Salada")
	print("  [PASS] X-Salada montado e finalizado com sucesso com todos os 5 ingredientes básicos!")

	# Limpeza
	player.take_held_item().queue_free()
	player.queue_free()
	fridge.queue_free()
	rack.queue_free()
	prep_table.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE REORGANIZAÇÃO DO ARMAZÉM FORAM APROVADOS!")
	print("============================================================")
	quit(0)
