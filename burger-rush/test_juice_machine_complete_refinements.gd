extends SceneTree

const PulpStorageTable = preload("res://src/stations/pulp_storage_table.gd")
const JuiceMachine = preload("res://src/stations/juice_machine.gd")
const JuicePulp = preload("res://src/items/juice_pulp.gd")
const DrinkCup = preload("res://src/items/drink_cup.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE: GAVETAS, RESERVATÓRIOS E ÁREA DO COPO")
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

	# -------------------------------------------------------------
	# TESTE COMPLETO DOS 3 SABORES (GAVETA -> PROCESSAMENTO -> LÍQUIDO NO RESERVATÓRIO)
	# -------------------------------------------------------------
	var flavors_test = [
		{ "idx": 0, "name": "Laranja", "icon": "🍊", "drink_id": "juice_orange" },
		{ "idx": 1, "name": "Uva", "icon": "🍇", "drink_id": "juice_grape" },
		{ "idx": 2, "name": "Morango", "icon": "🍓", "drink_id": "juice_strawberry" }
	]

	var cup_scene = load("res://src/items/drink_cup.tscn")

	for item_test in flavors_test:
		var idx = item_test["idx"]
		var f_name = item_test["name"]
		var icon = item_test["icon"]
		print("\n--- Testando Ciclo Completo de %s (%s) ---" % [f_name, icon])

		# 1. Pegar pedra de polpa com clique esquerdo
		var pulp = table.take_pulp(player, idx)
		assert(pulp != null and player.held_item == pulp, "Pedra de polpa de %s obtida" % f_name)

		# 2. Abrir gaveta com E
		juice_machine.toggle_drawer(idx, player)
		assert(juice_machine.is_drawer_open[idx], "Gaveta de %s aberta com E" % f_name)
		juice_machine._process(0.5)
		assert(juice_machine.drawer_positions[idx] > 0.25, "Gaveta deslizou para frente")

		# 3. Colocar a pedra dentro da gaveta com clique
		var held_pulp = player.take_held_item() as JuicePulp
		var ok_insert = juice_machine.insert_pulp_in_drawer(idx, held_pulp, player)
		assert(ok_insert, "Polpa encaixada dentro da gaveta")

		# 4. Verificar que ela está fisicamente visível dentro da gaveta aberta
		var holder = juice_machine.get_node_or_null("Model/Drawer_%d/PulpHolder" % idx)
		assert(holder != null and holder.get_child_count() > 0, "Polpa está dentro do compartimento interno da gaveta")
		assert(held_pulp.visible, "Polpa visível enquanto a gaveta está aberta")

		# 5. Fechar a gaveta com E
		juice_machine.toggle_drawer(idx, player)
		assert(not juice_machine.is_drawer_open[idx], "Gaveta de %s fechada com E" % f_name)
		assert(juice_machine.is_processing[idx], "Processamento/moagem iniciado")

		# 6. Aguardar processamento (1.8s) e subida suave do suco
		juice_machine._process(2.0)
		assert(not juice_machine.is_processing[idx], "Processamento concluído")
		juice_machine._process(2.0)
		assert(juice_machine.juice_doses[idx] == 5.0, "Nível de Suco de %s aumentou para 5 doses" % f_name)

		# 7. Verificar líquido visível e desenhado no reservatório de acrílico
		var liquid_node = juice_machine.get_node_or_null("Model/Reservoir_%d/Liquid" % idx) as MeshInstance3D
		assert(liquid_node != null and liquid_node.visible, "Líquido de %s visível dentro do reservatório" % f_name)
		var fruit_emblem = juice_machine.get_node_or_null("Model/Reservoir_%d/FruitEmblem" % idx) as Label3D
		assert(fruit_emblem != null and fruit_emblem.text == icon, "Desenho da fruta %s visível no reservatório" % icon)

		# 8. Pegar copo vazio e colocar na base destacada
		var cup = cup_scene.instantiate() as DrinkCup
		world.add_child(cup)
		cup.set_state(DrinkCup.State.EMPTY)
		var ok_place = juice_machine.place_cup_in_slot(idx, cup, player)
		assert(ok_place, "Copo apoiado na base sob a torneira de %s" % f_name)

		# 9. Acionar a torneira com E -> encher -> copo cheio
		juice_machine.toggle_lever(idx, player)
		assert(juice_machine.is_lever_down[idx], "Alavanca acionada")
		juice_machine._process(1.2)
		assert(cup.state == DrinkCup.State.FILLED, "Copo 100% cheio")
		assert(juice_machine.juice_doses[idx] == 4.0, "Doses consumidas: 5 -> 4")

		# 10. Retirar copo com clique
		var taken_cup = juice_machine.take_cup_from_slot(idx, player)
		assert(taken_cup == cup and player.held_item == cup, "Copo retirado para a mão do jogador")
		player.take_held_item().queue_free()

		print("  [PASS] Ciclo de %s 100%% concluído com sucesso!" % f_name)

	# Limpeza
	table.queue_free()
	juice_machine.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE GAVETA, RESERVATÓRIO E COPO FORAM APROVADOS!")
	print("============================================================\n")
	quit(0)
