extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE ESTABILIDADE DO SISTEMA DE PICKUP")
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
	player.global_position = Vector3(2.0, 0.0, -3.0)
	player._ready()

	var initial_player_pos = player.global_position

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

	print("\n--- Testando Pickup e Drop de Todos os Itens sem Teleporte ---")
	for itm_info in item_scenes:
		var scene = load(itm_info["path"])
		assert(scene != null, "Cena %s deve existir" % itm_info["path"])
		var itm = scene.instantiate() as Item
		world.add_child(itm)
		itm.global_position = Vector3(2.5, 0.9, -3.0)

		# 1. Pegar item
		player.pick_up(itm)
		assert(player.held_item == itm, "Jogador deve estar segurando %s" % itm_info["name"])
		assert(player.global_position.is_equal_approx(initial_player_pos), "Posição do jogador NUNCA deve mudar no pickup de %s" % itm_info["name"])
		assert(itm.collision_layer == 0 and itm.collision_mask == 0, "Colisões do item devem estar zeradas na mão para não colidir com o jogador")

		# Se for bisnaga, testa aperto e simulação de processo
		if itm is SauceBottle:
			itm.start_squeezing()
			itm._process(0.2)
			assert(player.global_position.is_equal_approx(initial_player_pos), "Posição do jogador preservada durante aperto da bisnaga")
			itm.stop_squeezing()

		# 2. Soltar item
		player.drop_item()
		assert(player.held_item == null, "Mãos livres após soltar %s" % itm_info["name"])
		assert(player.global_position.is_equal_approx(initial_player_pos), "Posição do jogador NUNCA deve mudar no drop de %s" % itm_info["name"])
		assert(itm.collision_layer == 1 and itm.collision_mask == 1, "Colisões do item restauradas após drop")

		itm.queue_free()
		print("  [PASS] %s: Pickup, retenção na mão e Drop 100%% estáveis sem teleportes." % itm_info["name"])

	# Limpeza
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE PICKUP E ESTABILIDADE FORAM APROVADOS!")
	print("============================================================")
	quit(0)
