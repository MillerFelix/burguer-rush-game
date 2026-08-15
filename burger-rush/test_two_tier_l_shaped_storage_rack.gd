extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DA ESTANTE EM L (2 NÍVEIS CONFORTÁVEIS)")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
	inv.items["bread_bottom"]["quantity"] = 30
	inv.items["bread_top"]["quantity"] = 30
	inv.items["cheese"]["quantity"] = 30
	inv.items["potato_raw"]["quantity"] = 30
	inv.items["tomato"]["quantity"] = 30
	inv.items["lettuce"]["quantity"] = 30

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	# ---------------------------------------------------------
	# TESTE 1: VALIDAÇÃO DE 2 NÍVEIS E ALTURA CONFORTÁVEL
	# ---------------------------------------------------------
	print("\n--- Teste 1: Validação de 2 Níveis de Altura Confortável (< 1.0m) ---")
	var rack_scene = load("res://src/stations/storage_rack.tscn")
	var rack = rack_scene.instantiate() as StorageRack
	root.add_child(rack)
	rack._ready()

	assert(rack.has_node("Model/ShelfTop"), "Estante deve ter Nível Superior")
	assert(rack.has_node("Model/ShelfBot"), "Estante deve ter Nível Inferior")
	assert(not rack.has_node("Model/ShelfMid"), "Terceiro nível deve ser COMPLETAMENTE REMOVIDO")

	var top_shelf = rack.get_node("Model/ShelfTop") as MeshInstance3D
	var bot_shelf = rack.get_node("Model/ShelfBot") as MeshInstance3D

	assert(top_shelf.position.y <= 0.95, "Nível superior deve estar em altura confortável <= 0.95m (y = %.2fm)" % top_shelf.position.y)
	assert(bot_shelf.position.y <= 0.50, "Nível inferior deve estar acessível <= 0.50m (y = %.2fm)" % bot_shelf.position.y)

	print("  [PASS] Estante possui exatamente 2 níveis: Superior (y = %.2fm) e Inferior (y = %.2fm)" % [
		top_shelf.position.y, bot_shelf.position.y
	])

	# ---------------------------------------------------------
	# TESTE 2: FORMATO EM L VIRADO PARA A PAREDE DO RECEBIMENTO (OESTE)
	# ---------------------------------------------------------
	print("\n--- Teste 2: Formato em L Virado para a Parede do Recebimento (Oeste) ---")
	var main_scene = load("res://src/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)

	var main_rack = main.get_node_or_null("StorageRack") as StorageRack
	assert(main_rack != null, "StorageRack deve existir em main.tscn")

	assert(main_rack.has_node("Model/ShelfWingTop") and main_rack.has_node("Model/ShelfWingBot"), "Asa do L deve ter 2 níveis")

	# Calcula coordenadas no espaço de mundo do L
	var wing_top = main_rack.get_node("Model/ShelfWingTop") as MeshInstance3D
	var wing_world_pos = main_rack.transform * wing_top.position

	# A asa do L deve estar no lado Oeste (x <= -7.5) virada para a parede do recebimento (x = -9.0)
	assert(wing_world_pos.x <= -7.5, "Asa do L deve estar no lado Oeste do recebimento (world x = %.2f <= -7.5)" % wing_world_pos.x)
	# A asa deve estender-se para o Norte em direção à porta de recebimento (z <= -1.0)
	assert(wing_world_pos.z <= -1.0, "Asa do L deve estender-se para o norte (world z = %.2f <= -1.0)" % wing_world_pos.z)
	# A estante inteira deve estar dentro do armazém (x in [-9.0, -3.0], z in [-9.0, 0.0])
	assert(main_rack.position.x > -9.0 and main_rack.position.x < -3.0, "Estante deve estar dentro do armazém em X")
	assert(main_rack.position.z < 0.0 and main_rack.position.z > -9.0, "Estante deve estar dentro do armazém em Z")

	print("  [PASS] L virado corretamente para a parede Oeste do Recebimento (world x = %.2f, z = %.2f)" % [
		wing_world_pos.x, wing_world_pos.z
	])

	# ---------------------------------------------------------
	# TESTE 3: INTERAÇÃO E RETIRADA DE TODOS OS INGREDIENTES DOS 2 NÍVEIS
	# ---------------------------------------------------------
	print("\n--- Teste 3: Retirada de Todos os Ingredientes nos 2 Níveis ---")
	var ingredients_to_test = [
		{"idx": 0, "id": "bread_bottom", "name": "Base do Pão", "tier": "Superior"},
		{"idx": 1, "id": "bread_top", "name": "Tampa do Pão", "tier": "Superior"},
		{"idx": 2, "id": "cheese", "name": "Queijo Cheddar", "tier": "Superior"},
		{"idx": 6, "id": "potato_raw", "name": "Batata Crua", "tier": "Inferior"},
		{"idx": 7, "id": "tomato", "name": "Tomate Fresco", "tier": "Inferior"},
		{"idx": 8, "id": "lettuce", "name": "Alface Crocante", "tier": "Inferior"}
	]

	for itm_t in ingredients_to_test:
		main_rack.active_item_index = itm_t["idx"]
		main_rack.interact(player)
		assert(player.held_item != null, "Jogador deve conseguir pegar %s" % itm_t["name"])
		assert(player.held_item.item_id == itm_t["id"], "ID deve ser %s" % itm_t["id"])
		print("  [PASS] %s (%s) retirado da estante com sucesso!" % [itm_t["name"], itm_t["tier"]])
		player.take_held_item().queue_free()

	# Limpeza
	player.queue_free()
	rack.queue_free()
	main.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DA ESTANTE EM L (2 NÍVEIS) FORAM APROVADOS!")
	print("============================================================")
	quit(0)
