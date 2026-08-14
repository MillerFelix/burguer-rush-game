extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE AJUSTE DA ESTANTE E REFINAMENTO DO PÃO E QUEIJO")
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

	# 1. Teste de Posição da Estante no main.tscn
	print("\n--- Teste 1: Posição da Estante na Parede Divisória ---")
	var main_scene = load("res://src/main.tscn")
	assert(main_scene != null, "Cena main.tscn deve carregar perfeitamente")
	var main = main_scene.instantiate()
	root.add_child(main)

	var rack = main.get_node_or_null("StorageRack")
	assert(rack != null, "StorageRack deve existir em main.tscn")
	# Parede divisória do armazém com o salão fica em z = 0.0, estante deve estar em z ~ -0.55
	assert(abs(rack.position.z - (-0.55)) < 0.1, "Estante deve estar encostada na parede divisória sul (z ≈ -0.55)")
	assert(rack.position.x < -3.0 and rack.position.x > -9.0, "Estante deve estar dentro dos limites da parede do armazém")
	print("  [PASS] Estante de ingredientes posicionada na parede divisória do armazém (z = %.2f, x = %.2f)" % [rack.position.z, rack.position.x])

	# 2. Teste do Pão Brioche Reformulado
	print("\n--- Teste 2: Pão Brioche de Hambúrguer ---")
	var bread_scene = load("res://src/items/bread.tscn")
	assert(bread_scene != null, "Cena bread.tscn deve existir")
	var bread = bread_scene.instantiate()
	root.add_child(bread)
	assert(bread.has_node("MeshInstance3D/TopBun"), "Pão deve possuir Topo Brioche Abaulado (TopBun)")
	assert(bread.has_node("MeshInstance3D/BottomBun"), "Pão deve possuir Base de Pão (BottomBun)")
	assert(bread.has_node("MeshInstance3D/Crumb"), "Pão deve possuir Camada de Miolo Macio (Crumb)")
	assert(bread.has_node("MeshInstance3D/Sesame1"), "Pão deve possuir Sementes de Gergelim (Sesame)")
	assert(bread.display_name.contains("Brioche"), "Nome do pão deve ser Pão Brioche")
	print("  [PASS] Pão Brioche reformulado com sucesso (TopBun, BottomBun, Crumb, Sesame)")

	# 3. Teste da Fatia Quadrada de Queijo Cheddar
	print("\n--- Teste 3: Fatia Quadrada de Queijo Cheddar ---")
	var cheese_scene = load("res://src/items/cheese.tscn")
	assert(cheese_scene != null, "Cena cheese.tscn deve existir")
	var cheese = cheese_scene.instantiate()
	root.add_child(cheese)
	assert(cheese.has_node("MeshInstance3D/MainSlice"), "Queijo deve possuir Fatia Principal Quadrada (MainSlice)")
	assert(cheese.has_node("MeshInstance3D/CornerDrop1"), "Queijo deve possuir cantos caídos modelados (CornerDrop)")
	print("  [PASS] Fatia quadrada de queijo cheddar reformulada com sucesso (MainSlice, CornerDrop)")

	# 4. Teste de Montagem na PrepTable com Pão Brioche e Queijo Cheddar
	print("\n--- Teste 4: Montagem de Cheeseburger com Pão Brioche e Queijo Cheddar ---")
	var prep_scene = load("res://src/stations/prep_table.tscn")
	var prep_table = prep_scene.instantiate() as PrepTable
	root.add_child(prep_table)
	prep_table._ready()

	player.pick_up(bread)
	prep_table.interact(player)

	var patty = load("res://src/items/patty.tscn").instantiate() as Patty
	patty.state = Patty.State.COOKED
	root.add_child(patty)
	player.pick_up(patty)
	prep_table.interact(player)

	player.pick_up(cheese)
	prep_table.interact(player)

	prep_table.interact(player)
	assert(player.held_item != null, "Jogador deve receber o cheeseburger")
	assert(player.held_item.item_id == "cheeseburger", "Cheeseburger finalizado com sucesso")
	print("  [PASS] Cheeseburger montado com Pão Brioche e Queijo Cheddar perfeitamente proporcionados!")

	# Limpeza
	player.take_held_item().queue_free()
	player.queue_free()
	prep_table.queue_free()
	main.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE REFINAMENTO DO PÃO, QUEIJO E ESTANTE APROVADOS!")
	print("============================================================")
	quit(0)
