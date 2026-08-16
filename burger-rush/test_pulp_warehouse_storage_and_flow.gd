extends SceneTree

const PulpStorageTable = preload("res://src/stations/pulp_storage_table.gd")
const JuiceMachine = preload("res://src/stations/juice_machine.gd")
const JuicePulp = preload("res://src/items/juice_pulp.gd")
const DrinkCup = preload("res://src/items/drink_cup.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE: ESTOQUE DE POLPAS NO ARMAZÉM E FLUXO")
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
	# 1. TESTE DA MESA DE POLPAS NO ARMAZÉM (30 BLOCOS FÍSICOS)
	# -------------------------------------------------------------
	print("\n--- 1. Verificação do Cesto de Armazenamento Aberto com 30 Pedras ---")
	var table_scene = load("res://src/stations/pulp_storage_table.tscn")
	var table = table_scene.instantiate() as PulpStorageTable
	world.add_child(table)
	table._ready()

	assert(table.stock_orange == 10, "Estoque inicial de Laranja deve ser 10")
	assert(table.stock_grape == 10, "Estoque inicial de Uva deve ser 10")
	assert(table.stock_strawberry == 10, "Estoque inicial de Morango deve ser 10")

	# Verifica se todos os 30 nós 3D estão visíveis
	for i in range(3):
		for slot in range(10):
			var node = table.get_node_or_null("Model/Crate/Pulp_%d_%d" % [i, slot])
			assert(node != null and node.visible, "Pedra física [%d, %d] deve estar visível no cesto" % [i, slot])

	var crate_label = table.get_node_or_null("Model/Crate/CrateBadge/CrateLabel")
	assert(crate_label != null and crate_label.text == "POLPA DE FRUTAS", "Caixa deve ser identificada apenas como POLPA DE FRUTAS")
	print("  [PASS] Cesto contém exatamente 30 pedras físicas 3D e identificação 'POLPA DE FRUTAS'.")

	# -------------------------------------------------------------
	# 2. TESTE DA REGRA DE INTERAÇÃO (CLIQUE ESQUERDO PEGA, 'E' NÃO PEGA)
	# -------------------------------------------------------------
	print("\n--- 2. Teste da Regra de Interação (Clique Esquerdo vs Tecla E) ---")
	# Pressionar E não deve pegar o item
	table.interact(player)
	assert(player.held_item == null, "Pressionar E NÃO deve retirar a pedra da mesa (E = máquinas/portas/gavetas)")
	assert(table.stock_orange == 10, "Estoque permanece 10 ao pressionar E")

	# -------------------------------------------------------------
	# 3. TESTE DE TRANSPORTE DOS 3 SABORES ATÉ A MÁQUINA DE SUCOS
	# -------------------------------------------------------------
	print("\n--- 3. Teste de Transporte e Processamento dos 3 Sabores ---")
	var juice_scene = load("res://src/stations/juice_machine.tscn")
	var juice_machine = juice_scene.instantiate() as JuiceMachine
	world.add_child(juice_machine)
	juice_machine._ready()

	# Teste do botão liga/desliga da máquina de sucos
	assert(juice_machine.is_powered, "Máquina de sucos deve iniciar ligada")
	juice_machine.toggle_power(player)
	assert(not juice_machine.is_powered, "Máquina de sucos desliga com toggle_power")
	juice_machine.toggle_power(player)
	assert(juice_machine.is_powered, "Máquina de sucos liga novamente com toggle_power")

	var flavors_to_test = [
		{"idx": 0, "name": "Laranja", "expected_stock_after": 9, "id": "juice_orange"},
		{"idx": 1, "name": "Uva", "expected_stock_after": 9, "id": "juice_grape"},
		{"idx": 2, "name": "Morango", "expected_stock_after": 9, "id": "juice_strawberry"}
	]

	var cup_scene = load("res://src/items/drink_cup.tscn")

	for item_info in flavors_to_test:
		var f_idx = item_info["idx"]
		var f_name = item_info["name"]
		print("  -> Testando ciclo de %s..." % f_name)

		# 1. Pegar pedra com Clique Esquerdo
		var pulp = table.take_pulp(player, f_idx)
		assert(pulp != null and player.held_item == pulp, "Pedra de %s retirada com sucesso" % f_name)
		assert(table.get_stock(f_idx) == item_info["expected_stock_after"], "Estoque reduzido: 10 -> 9")

		# Verifica que a 10ª pedra sumiu visualmente do cesto (restam 9 visíveis)
		var top_block = table.get_node_or_null("Model/Crate/Pulp_%d_9" % f_idx)
		assert(top_block != null and not top_block.visible, "Bloco 9 ocultado no cesto")

		# Tentativa de pegar outra com mãos ocupadas deve ser bloqueada
		var duplicate_attempt = table.take_pulp(player, f_idx)
		assert(duplicate_attempt == null, "Não permite duplicar itens com mãos ocupadas")

		# 2. Levar até a Máquina de Sucos: Abrir gaveta com [E]
		juice_machine.toggle_drawer(f_idx, player)
		assert(juice_machine.is_drawer_open[f_idx], "Gaveta de %s aberta com [E]" % f_name)

		# 3. Colocar a pedra na gaveta com Clique Esquerdo
		var held_pulp = player.take_held_item() as JuicePulp
		var ok_insert = juice_machine.insert_pulp_in_drawer(f_idx, held_pulp, player)
		assert(ok_insert, "Pedra de %s encaixada na gaveta" % f_name)

		# 4. Fechar a gaveta com [E]
		juice_machine.toggle_drawer(f_idx, player)
		assert(not juice_machine.is_drawer_open[f_idx], "Gaveta de %s fechada com [E]" % f_name)
		assert(juice_machine.is_processing[f_idx], "Processamento/Moagem de %s iniciado" % f_name)

		# 5. Máquina processa e nível de suco sobe para 5 doses
		juice_machine._process(4.0)
		assert(not juice_machine.is_processing[f_idx], "Processamento concluído")
		assert(juice_machine.juice_doses[f_idx] == 5.0, "Nível de Suco de %s subiu para 5 doses" % f_name)

		# 6. Servir no Copo
		var cup = cup_scene.instantiate() as DrinkCup
		world.add_child(cup)
		cup.set_state(DrinkCup.State.EMPTY)
		juice_machine.place_cup_in_slot(f_idx, cup, player)
		juice_machine.toggle_lever(f_idx, player)
		juice_machine._process(1.2)

		assert(cup.state == DrinkCup.State.FILLED, "Copo de %s servido e 100%% cheio" % f_name)
		assert(juice_machine.juice_doses[f_idx] == 4.0, "Doses restantes reduzidas: 5 -> 4")
		juice_machine.take_cup_from_slot(f_idx, player)
		player.take_held_item().queue_free()

		print("     [OK] Ciclo de %s 100%% aprovado (Estoque 10->9, Moagem -> +5 doses, Servir -> 4 doses)" % f_name)

	# -------------------------------------------------------------
	# 4. TESTE DE PERSISTÊNCIA VISUAL DO ESTOQUE
	# -------------------------------------------------------------
	print("\n--- 4. Teste de Visualização Física do Estoque Restante ---")
	assert(table.stock_orange == 9, "Restam 9 laranjas")
	assert(table.stock_grape == 9, "Restam 9 uvas")
	assert(table.stock_strawberry == 9, "Restam 9 morangos")
	print("  [PASS] Contabilidade física precisa: 27 pedras restantes no cesto.")

	# Limpeza
	table.queue_free()
	juice_machine.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE ESTOQUE E FLUXO DE POLPAS FORAM APROVADOS!")
	print("============================================================\n")
	quit(0)
