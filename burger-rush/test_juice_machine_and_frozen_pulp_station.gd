extends SceneTree

const JuiceMachine = preload("res://src/stations/juice_machine.gd")
const JuicePulp = preload("res://src/items/juice_pulp.gd")
const PulpStorageTable = preload("res://src/stations/pulp_storage_table.gd")
const DrinkMachine = preload("res://src/stations/drink_machine.gd")
const DrinkCup = preload("res://src/items/drink_cup.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE: MÁQUINA DE SUCOS, GAVETAS E POLPAS")
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

	# -------------------------------------------------------------
	# 1. TESTE DA MÁQUINA DE REFRIGERANTES: BOTÃO POWER E 25 DOSES
	# -------------------------------------------------------------
	print("\n--- 1. Teste da Máquina de Refrigerantes (25 Doses e Botão Power) ---")
	var soda_scene = load("res://src/stations/drink_machine.tscn")
	var soda_machine = soda_scene.instantiate() as DrinkMachine
	world.add_child(soda_machine)
	soda_machine._ready()

	assert(soda_machine.syrup_capacity == 25, "Capacidade padrão deve ser 25 doses")
	assert(soda_machine.syrup_levels[0] == 25.0, "Barril novo inicia com 25 doses")

	# Teste do botão liga/desliga com E
	assert(soda_machine.is_powered, "Inicia ligada")
	soda_machine.toggle_power(player)
	assert(not soda_machine.is_powered, "Desligou com toggle_power")
	soda_machine.toggle_power(player)
	assert(soda_machine.is_powered, "Ligou novamente com toggle_power")

	# Servir uma dose consome 1 dose (25 -> 24)
	var cup_scene = load("res://src/items/drink_cup.tscn")
	var soda_cup = cup_scene.instantiate() as DrinkCup
	world.add_child(soda_cup)
	soda_cup.set_state(DrinkCup.State.EMPTY)
	soda_machine.place_cup_in_slot(0, soda_cup, player)
	soda_machine.toggle_lever(0, player)
	soda_machine._process(1.2)
	assert(soda_cup.state == DrinkCup.State.FILLED, "Copo de Cola servido")
	assert(soda_machine.syrup_levels[0] == 24.0, "Consumiu exatamente 1 dose (25 -> 24)")
	soda_machine.take_cup_from_slot(0, player)
	player.take_held_item().queue_free()
	soda_machine.queue_free()
	print("  [PASS] Máquina de refrigerantes: 25 doses e botão Power funcionando perfeitamente.")

	# -------------------------------------------------------------
	# 2. TESTE DO ARMAZÉM: MESA DE POLPAS COM CESTO PLÁSTICO (30 UNIDADES)
	# -------------------------------------------------------------
	print("\n--- 2. Teste do Armazém: Mesa de Polpas e Cesto Organizador ---")
	var table_scene = load("res://src/stations/pulp_storage_table.tscn")
	var table = table_scene.instantiate() as PulpStorageTable
	world.add_child(table)
	table._ready()

	assert(table.stock_orange == 10, "Estoque inicial de Laranja: 10")
	assert(table.stock_grape == 10, "Estoque inicial de Uva: 10")
	assert(table.stock_strawberry == 10, "Estoque inicial de Morango: 10")
	print("  [PASS] Cesto plástico abastecido com 30 pedras de polpa no total.")

	# Retirar 1 polpa de Morango com clique
	table.set_stock(2, 10)
	# Simula retirada de Morango (idx 2)
	var pulp_m = table.take_pulp(player, 2)
	assert(pulp_m != null and player.held_item == pulp_m, "Polpa de Morango retirada para a mão")
	assert(table.stock_strawberry == 9, "Estoque físico de Morango diminuiu para 9 (10 -> 9)")
	assert(pulp_m.fruit_type == "strawberry" or pulp_m.item_id == "pulp_strawberry", "Item reconhecido como polpa de morango")
	print("  [PASS] Retirada física com clique e decremento de estoque validados.")

	# -------------------------------------------------------------
	# 3. TESTE DA MÁQUINA DE SUCOS: BOTÃO POWER, GAVETAS E PROCESSAMENTO
	# -------------------------------------------------------------
	print("\n--- 3. Teste da Máquina de Sucos: Botão Power, Gavetas e Processamento ---")
	var juice_scene = load("res://src/stations/juice_machine.tscn")
	var juice_machine = juice_scene.instantiate() as JuiceMachine
	world.add_child(juice_machine)
	juice_machine._ready()

	# Teste do botão liga/desliga da máquina de sucos
	assert(juice_machine.is_powered, "Máquina de sucos inicia ligada")
	juice_machine.toggle_power(player)
	assert(not juice_machine.is_powered, "Máquina de sucos desligada via toggle_power")
	juice_machine.toggle_power(player)
	assert(juice_machine.is_powered, "Máquina de sucos ligada novamente")

	assert(juice_machine.juice_doses[2] == 0.0, "Reservatório de Morango inicia vazio (0 doses)")

	# 1. Abrir gaveta de Morango com [E]
	juice_machine.toggle_drawer(2, player)
	assert(juice_machine.is_drawer_open[2], "Gaveta de Morango ABERTA com a tecla E")
	juice_machine._process(0.5)
	assert(juice_machine.drawer_positions[2] > 0.2, "Gaveta deslizou para frente no eixo Z")

	# 2. Inserir pedra de polpa na gaveta
	var held_pulp = player.take_held_item() as JuicePulp
	var ok_insert = juice_machine.insert_pulp_in_drawer(2, held_pulp, player)
	assert(ok_insert, "Pedra de polpa encaixada dentro da gaveta")
	assert(juice_machine.placed_pulps[2] == held_pulp, "Polpa registrada na gaveta")

	# 3. Fechar gaveta com [E] -> inicia processamento
	juice_machine.toggle_drawer(2, player)
	assert(not juice_machine.is_drawer_open[2], "Gaveta de Morango FECHADA com a tecla E")
	assert(juice_machine.placed_pulps[2] == null, "Polpa consumida da gaveta")
	assert(juice_machine.is_processing[2], "Processamento/Moagem de Morango iniciado")

	# 4. Aguardar tempo de processamento e subida do nível
	juice_machine._process(2.0)
	assert(not juice_machine.is_processing[2], "Processamento de Morango concluído")
	juice_machine._process(2.0)
	assert(juice_machine.juice_doses[2] == 5.0, "Nível de Suco de Morango atingiu exatamente 5 doses (+5 doses)")
	print("  [PASS] Ciclo de abastecimento: Gaveta -> Polpa -> Fechar -> Moer -> Nível sobe para 5 doses.")

	# -------------------------------------------------------------
	# 4. TESTE DE SERVIR SUCO DE MORANGO (5 -> 4 DOSES)
	# -------------------------------------------------------------
	print("\n--- 4. Teste de Servir Suco no Copo ---")
	var j_cup = cup_scene.instantiate() as DrinkCup
	world.add_child(j_cup)
	j_cup.set_state(DrinkCup.State.EMPTY)

	juice_machine.place_cup_in_slot(2, j_cup, player)
	juice_machine.toggle_lever(2, player)
	assert(juice_machine.is_lever_down[2], "Alavanca de Morango acionada")

	juice_machine._process(1.2)
	assert(j_cup.state == DrinkCup.State.FILLED, "Copo 100% cheio de Suco de Morango")
	assert(j_cup.get_flavor_display_name() == "Copo de Suco de Morango", "Identificação correta da bebida")
	assert(juice_machine.juice_doses[2] == 4.0, "Doses restantes reduzidas para 4 (5 -> 4)")

	var taken_cup = juice_machine.take_cup_from_slot(2, player)
	assert(taken_cup == j_cup and player.held_item == j_cup, "Copo retirado para a mão do jogador")
	player.take_held_item().queue_free()
	print("  [PASS] Suco servido com sucesso e doses decrementadas de forma correta.")

	# -------------------------------------------------------------
	# 5. TESTE DE INDEPENDÊNCIA DE LARANJA E UVA
	# -------------------------------------------------------------
	print("\n--- 5. Teste de Independência dos Sabores (Laranja e Uva) ---")
	# Abastecer Laranja
	var pulp_o = table.take_pulp(player, 0)
	player.take_held_item()
	juice_machine.toggle_drawer(0, player)
	juice_machine.insert_pulp_in_drawer(0, pulp_o, player)
	juice_machine.toggle_drawer(0, player)
	juice_machine._process(4.0)
	assert(juice_machine.juice_doses[0] == 5.0, "Laranja com 5 doses")
	assert(juice_machine.juice_doses[1] == 0.0, "Uva continua com 0 doses (independência total)")
	assert(juice_machine.juice_doses[2] == 4.0, "Morango permanece inalterado com 4 doses")
	print("  [PASS] Os 3 reservatórios operam com independência física e lógica total.")

	# Limpeza
	table.queue_free()
	juice_machine.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DA MÁQUINA DE SUCOS E POLPAS FORAM APROVADOS!")
	print("============================================================\n")
	quit(0)
