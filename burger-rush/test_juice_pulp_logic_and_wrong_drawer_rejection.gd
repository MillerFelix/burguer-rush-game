extends SceneTree

const PulpStorageTable = preload("res://src/stations/pulp_storage_table.gd")
const JuiceMachine = preload("res://src/stations/juice_machine.gd")
const JuicePulp = preload("res://src/items/juice_pulp.gd")
const DrinkCup = preload("res://src/items/drink_cup.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE: LÓGICA DE POLPAS E REJEIÇÃO DE GAVETA")
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
	player.global_position = Vector3(0.0, 0.0, 1.5)
	player._ready()

	# 1. Instanciar Mesa de Polpas do Armazém
	var table_scene = load("res://src/stations/pulp_storage_table.tscn")
	var table = table_scene.instantiate() as PulpStorageTable
	world.add_child(table)
	table._ready()

	# 2. Instanciar Máquina de Sucos
	var juice_scene = load("res://src/stations/juice_machine.tscn")
	var juice_machine = juice_scene.instantiate() as JuiceMachine
	world.add_child(juice_machine)
	juice_machine._ready()

	# Abrir todas as gavetas para os testes
	juice_machine.toggle_drawer(0, player) # Laranja
	juice_machine.toggle_drawer(1, player) # Uva
	juice_machine.toggle_drawer(2, player) # Morango

	# -------------------------------------------------------------
	# PARTE 1: TESTES OBRIGATÓRIOS DE REJEIÇÃO DE GAVETA ERRADA
	# (O item NÃO pode ser consumido, teleportado ou sair da mão)
	# -------------------------------------------------------------
	print("\n--- 1. Teste de Rejeição Segura: Morango na Gaveta de Laranja ---")
	var pulp_m = table.take_pulp(player, 2) # Morango
	assert(player.held_item == pulp_m, "Jogador segurando polpa de morango")

	# Tentar colocar na gaveta de Laranja (índice 0)
	var ok_wrong1 = juice_machine.insert_pulp_in_drawer(0, pulp_m, player)
	assert(not ok_wrong1, "Gaveta de Laranja deve REJEITAR polpa de Morango")
	assert(player.held_item == pulp_m, "Polpa de Morango CONTINUA intacta na mão do jogador")
	assert(juice_machine.placed_pulps[0] == null, "Gaveta de Laranja permanece vazia")
	print("  [PASS] Morango na Gaveta de Laranja: Rejeitado e mantido na mão.")

	print("\n--- 2. Teste de Rejeição Segura: Laranja na Gaveta de Uva ---")
	player.take_held_item().queue_free() # descarta morango de teste
	var pulp_l = table.take_pulp(player, 0) # Laranja
	assert(player.held_item == pulp_l, "Jogador segurando polpa de laranja")

	# Tentar colocar na gaveta de Uva (índice 1)
	var ok_wrong2 = juice_machine.insert_pulp_in_drawer(1, pulp_l, player)
	assert(not ok_wrong2, "Gaveta de Uva deve REJEITAR polpa de Laranja")
	assert(player.held_item == pulp_l, "Polpa de Laranja CONTINUA intacta na mão do jogador")
	assert(juice_machine.placed_pulps[1] == null, "Gaveta de Uva permanece vazia")
	print("  [PASS] Laranja na Gaveta de Uva: Rejeitado e mantido na mão.")

	print("\n--- 3. Teste de Rejeição Segura: Uva na Gaveta de Morango ---")
	player.take_held_item().queue_free() # descarta laranja de teste
	var pulp_u = table.take_pulp(player, 1) # Uva
	assert(player.held_item == pulp_u, "Jogador segurando polpa de uva")

	# Tentar colocar na gaveta de Morango (índice 2)
	var ok_wrong3 = juice_machine.insert_pulp_in_drawer(2, pulp_u, player)
	assert(not ok_wrong3, "Gaveta de Morango deve REJEITAR polpa de Uva")
	assert(player.held_item == pulp_u, "Polpa de Uva CONTINUA intacta na mão do jogador")
	assert(juice_machine.placed_pulps[2] == null, "Gaveta de Morango permanece vazia")
	print("  [PASS] Uva na Gaveta de Morango: Rejeitado e mantido na mão.")

	player.take_held_item().queue_free()

	# -------------------------------------------------------------
	# PARTE 2: TESTES OBRIGATÓRIOS DE INSERÇÃO CORRETA E PRODUÇÃO DE SUCO
	# -------------------------------------------------------------
	print("\n--- 4. Teste de Inserção Correta e Geração do Suco nos 3 Reservatórios ---")
	var flavors_correct = [
		{ "idx": 0, "name": "Laranja", "icon": "🍊" },
		{ "idx": 1, "name": "Uva", "icon": "🍇" },
		{ "idx": 2, "name": "Morango", "icon": "🍓" }
	]

	for item in flavors_correct:
		var idx = item["idx"]
		var f_name = item["name"]

		# 1. Pegar polpa correspondente
		var p = table.take_pulp(player, idx)
		assert(player.held_item == p, "Polpa de %s na mão" % f_name)

		# 2. Inserir na gaveta correta
		var held = player.take_held_item() as JuicePulp
		var ok = juice_machine.insert_pulp_in_drawer(idx, held, player)
		assert(ok, "Gaveta aceitou polpa correta de %s" % f_name)
		assert(juice_machine.placed_pulps[idx] == held, "Polpa de %s visível dentro da gaveta" % f_name)

		# 3. Fechar gaveta -> iniciar moagem
		juice_machine.toggle_drawer(idx, player)
		assert(not juice_machine.is_drawer_open[idx], "Gaveta de %s fechada" % f_name)
		assert(juice_machine.is_processing[idx], "Processamento de %s iniciado" % f_name)

		# 4. Aguardar moagem (1.8s) e subida suave do suco
		juice_machine._process(2.0)
		assert(not juice_machine.is_processing[idx], "Processamento concluído")
		juice_machine._process(2.0)
		assert(juice_machine.juice_doses[idx] == 5.0, "Estoque de Suco de %s subiu para 5 doses (+5 doses)" % f_name)

		# 5. Verificar líquido visível dentro do reservatório
		var liquid_mesh = juice_machine.get_node_or_null("Model/Reservoir_%d/Liquid" % idx) as MeshInstance3D
		assert(liquid_mesh != null and liquid_mesh.visible, "Líquido 3D de %s VISÍVEL no reservatório" % f_name)

		print("  [PASS] %s: Aceite correto -> Moagem -> Líquido 3D visível e nível em 5 doses." % f_name)

	# Limpeza
	table.queue_free()
	juice_machine.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE VALIDAÇÃO E REJEIÇÃO FORAM 100% APROVADOS!")
	print("============================================================\n")
	quit(0)
