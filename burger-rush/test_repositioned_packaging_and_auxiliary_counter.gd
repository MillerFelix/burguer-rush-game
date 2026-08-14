extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE POSICIONAMENTO PRECISO DA EMBALAGEM NO CANTO DA COZINHA")
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

	# ---------------------------------------------------------
	# TESTE 1: POSIÇÃO DA BANCADA DE EMBALAGEM NO CANTO DA COZINHA
	# ---------------------------------------------------------
	print("\n--- Teste 1: Validação Geométrica do Canto da Cozinha (Sem Atravessar Paredes) ---")
	var main_scene = load("res://src/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)

	var pack_station = main.get_node_or_null("PackagingStation") as PackagingStation
	assert(pack_station != null, "PackagingStation deve existir em main.tscn")

	# Posição no canto da cozinha
	assert(abs(pack_station.position.x - (-2.5)) < 0.1, "PackagingStation deve estar encostada na parede em x = -2.5")
	assert(abs(pack_station.position.z - (-1.45)) < 0.1, "PackagingStation deve estar no canto sul em z = -1.45")

	# Limites físicos de colisão
	var half_width = 0.35 # Metade da profundidade (X)
	var half_length = 1.1 # Metade do comprimento (Z)
	var min_x = pack_station.position.x - half_width
	var max_x = pack_station.position.x + half_width
	var min_z = pack_station.position.z - half_length
	var max_z = pack_station.position.z + half_length

	# Parede do armazém fica em x <= -2.85
	assert(min_x >= -2.86, "Balcão não deve atravessar a parede do armazém (min_x = %.2f >= -2.85)" % min_x)
	# Balcão do restaurante fica em z >= 0.0 (face interna em z = -0.30)
	assert(max_z <= -0.30, "Balcão não deve invadir o restaurante (max_z = %.2f <= -0.30)" % max_z)
	# Porta de passagem para o armazém fica em z = -3.15 a -4.75
	assert(min_z > -3.15, "Balcão não deve obstruir a passagem do armazém (min_z = %.2f > -3.15)" % min_z)

	print("  [PASS] PackagingStation 100%% dentro da cozinha no canto [Armazém x Restaurante]:")
	print("         X: [%.2f a %.2f] | Z: [%.2f a %.2f] (Encostada na parede e desobstruindo a porta)" % [min_x, max_x, min_z, max_z])

	var aux_counter = main.get_node_or_null("AuxiliaryCounter")
	assert(aux_counter != null, "AuxiliaryCounter deve existir em main.tscn")
	assert(abs(aux_counter.position.x - 3.55) < 0.1, "AuxiliaryCounter deve estar ao lado da pia em x = 3.55")
	assert(aux_counter.placed_item == null, "Bancada auxiliar deve iniciar completamente vazia")
	print("  [PASS] AuxiliaryCounter posicionada ao lado da pia, limpa e vazia (x = %.2f, z = %.2f)" % [aux_counter.position.x, aux_counter.position.z])

	# ---------------------------------------------------------
	# TESTE 2: BANCADA AUXILIAR VAZIA E FUNCIONAL
	# ---------------------------------------------------------
	print("\n--- Teste 2: Funcionalidade da Bancada Auxiliar Vazia ---")
	var test_bread = load("res://src/items/bread_bottom.tscn").instantiate()
	root.add_child(test_bread)
	player.pick_up(test_bread)

	aux_counter.interact(player)
	assert(player.held_item == null, "Jogador deve ter colocado o item na bancada")
	assert(aux_counter.placed_item != null, "Bancada deve conter o item apoiado")

	aux_counter.interact(player)
	assert(player.held_item != null, "Jogador deve ter retirado o item da bancada")
	assert(aux_counter.placed_item == null, "Bancada deve ter ficado vazia novamente")
	player.take_held_item().queue_free()
	print("  [PASS] Bancada Auxiliar testada com sucesso: colocar e retirar itens funcionando!")

	# ---------------------------------------------------------
	# TESTE 3: SEPARAÇÃO E RETIRADA DAS 3 CATEGORIAS DE EMBALAGEM
	# ---------------------------------------------------------
	print("\n--- Teste 3: 3 Categorias de Embalagem (Lanche, Batata, Copos) ---")
	assert(pack_station.items_data.size() >= 3, "Estação deve ter pelo menos 3 categorias")
	assert(pack_station.has_node("Model/BoxStack"), "Estação deve ter pilha visual de caixas de lanche")
	assert(pack_station.has_node("Model/FriesStack"), "Estação deve ter pilha visual de caixas de batata")
	assert(pack_station.has_node("Model/CupDispenser"), "Estação deve ter dispensador visual de copos")

	# 1. Pegar Embalagem de Lanche
	pack_station.active_item_index = 0
	pack_station.interact(player)
	assert(player.held_item != null and player.held_item.item_id == "burger_box", "Jogador deve pegar burger_box")
	player.take_held_item().queue_free()
	print("  [PASS] Embalagem de lanche retirada individualmente")

	# 2. Pegar Embalagem de Batata
	pack_station.active_item_index = 1
	pack_station.interact(player)
	assert(player.held_item != null and player.held_item.item_id == "potato_box", "Jogador deve pegar potato_box")
	player.take_held_item().queue_free()
	print("  [PASS] Embalagem de batata retirada individualmente")

	# 3. Pegar Copo de Bebida
	pack_station.active_item_index = 2
	pack_station.interact(player)
	assert(player.held_item != null and player.held_item is DrinkCup, "Jogador deve pegar DrinkCup")
	var cup = player.take_held_item() as DrinkCup

	cup.set_flavor("soda_cola")
	cup.fill_amount = 1.0
	cup.state = DrinkCup.State.FILLED
	player.pick_up(cup)
	assert(not cup.has_lid(), "Copo não deve ter tampa inicialmente")
	pack_station.interact(player)
	assert(cup.has_lid(), "Copo deve ser selado com tampa e canudo na estação de embalagem")
	print("  [PASS] Copo retirado e selado com sucesso na bancada de embalagens")
	cup.queue_free()

	# Limpeza
	player.queue_free()
	main.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE POSICIONAMENTO DE EMBALAGENS FORAM APROVADOS!")
	print("============================================================")
	quit(0)
