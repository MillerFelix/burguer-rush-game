extends SceneTree

const PulpStorageTable = preload("res://src/stations/pulp_storage_table.gd")
const JuiceMachine = preload("res://src/stations/juice_machine.gd")
const JuicePulp = preload("res://src/items/juice_pulp.gd")
const DrinkCup = preload("res://src/items/drink_cup.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE: LÍQUIDO DOS SUCOS NO RESERVATÓRIO")
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

	var table_scene = load("res://src/stations/pulp_storage_table.tscn")
	var table = table_scene.instantiate() as PulpStorageTable
	world.add_child(table)
	table._ready()

	var juice_scene = load("res://src/stations/juice_machine.tscn")
	var juice_machine = juice_scene.instantiate() as JuiceMachine
	world.add_child(juice_machine)
	juice_machine._ready()

	# -------------------------------------------------------------
	# 1. VERIFICAÇÃO INICIAL: RESERVATÓRIOS VAZIOS (SEM LÍQUIDO VISÍVEL)
	# -------------------------------------------------------------
	print("\n--- 1. Verificação de Reservatórios Vazios ---")
	for i in range(3):
		var liquid_mesh = juice_machine.get_node_or_null("Model/Reservoir_%d/Liquid" % i) as MeshInstance3D
		assert(juice_machine.juice_doses[i] == 0.0, "Doses iniciais = 0")
		assert(liquid_mesh != null and not liquid_mesh.visible, "Reservatório %d vazio não mostra líquido" % i)
	print("  [PASS] Reservatórios iniciam vazios e sem líquido visível.")

	# -------------------------------------------------------------
	# 2. TESTE DE POLPA DE LARANJA: 1ª POLPA (0 -> 5 DOSES)
	# -------------------------------------------------------------
	print("\n--- 2. Teste: 1ª Polpa de Laranja (0 -> 5 doses) ---")
	var p_orange1 = table.take_pulp(player, 0)
	var held1 = player.take_held_item() as JuicePulp
	juice_machine.toggle_drawer(0, player)
	juice_machine.insert_pulp_in_drawer(0, held1, player)
	juice_machine.toggle_drawer(0, player)

	# Imediatamente após fechar: ainda está processando e líquido não subiu
	assert(juice_machine.is_processing[0], "Processamento ativo")
	assert(juice_machine.juice_doses[0] == 0.0, "Suco ainda não subiu instantaneamente")

	# Passa o tempo de moagem (1.8s) -> inicia subida do suco
	juice_machine._process(1.9)
	assert(not juice_machine.is_processing[0], "Processamento concluído")
	assert(juice_machine.target_juice_doses[0] == 5.0, "Target definido para 5 doses")

	# Animação suave de subida do líquido de baixo para cima
	juice_machine._process(2.0)
	assert(juice_machine.juice_doses[0] == 5.0, "Estoque atingiu 5 doses")

	var liquid_orange = juice_machine.get_node_or_null("Model/Reservoir_0/Liquid") as MeshInstance3D
	assert(liquid_orange != null and liquid_orange.visible, "Líquido 3D de Laranja está visível no jarro")
	var box_mesh1 = liquid_orange.mesh as BoxMesh
	var height1 = box_mesh1.size.y
	assert(height1 > 0.15 and height1 < 0.20, "Altura do líquido representa 5 doses (~0.17m)")
	print("  [PASS] 1ª Polpa de Laranja: Moagem -> Líquido 3D surge e atinge 5 doses.")

	# -------------------------------------------------------------
	# 3. TESTE DE 2ª POLPA NO MESMO SABOR (5 -> 10 DOSES)
	# -------------------------------------------------------------
	print("\n--- 3. Teste: 2ª Polpa no Mesmo Sabor (5 -> 10 doses sem apagar) ---")
	var p_orange2 = table.take_pulp(player, 0)
	var held2 = player.take_held_item() as JuicePulp
	juice_machine.toggle_drawer(0, player)
	juice_machine.insert_pulp_in_drawer(0, held2, player)
	juice_machine.toggle_drawer(0, player)

	juice_machine._process(1.9) # fim da moagem
	juice_machine._process(2.0) # subida suave
	assert(juice_machine.juice_doses[0] == 10.0, "Estoque aumentou para 10 doses (5 + 5)")

	var box_mesh2 = liquid_orange.mesh as BoxMesh
	var height2 = box_mesh2.size.y
	assert(height2 > height1, "Altura do líquido aumentou proporcionalmente de 5 para 10 doses")
	assert(liquid_orange.visible, "Líquido permanece visível continuamente")
	print("  [PASS] 2ª Polpa: Nível continuou subindo até 10 doses sem apagar o líquido existente.")

	# -------------------------------------------------------------
	# 4. TESTE DE POLPA DE UVA E MORANGO
	# -------------------------------------------------------------
	print("\n--- 4. Teste: Polpas de Uva e Morango ---")
	# Uva
	var p_grape = table.take_pulp(player, 1)
	var held_g = player.take_held_item() as JuicePulp
	juice_machine.toggle_drawer(1, player)
	juice_machine.insert_pulp_in_drawer(1, held_g, player)
	juice_machine.toggle_drawer(1, player)
	juice_machine._process(3.9)

	var liquid_grape = juice_machine.get_node_or_null("Model/Reservoir_1/Liquid") as MeshInstance3D
	assert(juice_machine.juice_doses[1] == 5.0, "Uva com 5 doses")
	assert(liquid_grape != null and liquid_grape.visible, "Líquido roxo de Uva visível")

	# Morango
	var p_straw = table.take_pulp(player, 2)
	var held_s = player.take_held_item() as JuicePulp
	juice_machine.toggle_drawer(2, player)
	juice_machine.insert_pulp_in_drawer(2, held_s, player)
	juice_machine.toggle_drawer(2, player)
	juice_machine._process(3.9)

	var liquid_straw = juice_machine.get_node_or_null("Model/Reservoir_2/Liquid") as MeshInstance3D
	assert(juice_machine.juice_doses[2] == 5.0, "Morango com 5 doses")
	assert(liquid_straw != null and liquid_straw.visible, "Líquido vermelho de Morango visível")
	print("  [PASS] Uva e Morango abastecidos com líquido 3D correspondente.")

	# -------------------------------------------------------------
	# 5. TESTE DE REDUÇÃO SINCRONIZADA AO SERVIR COPO (10 -> 9 DOSES)
	# -------------------------------------------------------------
	print("\n--- 5. Teste: Redução de Nível ao Servir Copo ---")
	var cup_scene = load("res://src/items/drink_cup.tscn")
	var cup = cup_scene.instantiate() as DrinkCup
	world.add_child(cup)
	cup.set_state(DrinkCup.State.EMPTY)
	juice_machine.place_cup_in_slot(0, cup, player)
	juice_machine.toggle_lever(0, player)
	juice_machine._process(1.2)

	assert(cup.state == DrinkCup.State.FILLED, "Copo de Laranja cheio")
	assert(juice_machine.juice_doses[0] == 9.0, "Doses de Laranja reduzidas para 9.0")
	var height3 = (liquid_orange.mesh as BoxMesh).size.y
	assert(height3 < height2, "Nível do líquido no reservatório desceu proporcionalmente (10 -> 9 doses)")
	print("  [PASS] Redução de nível visual e lógico 100% sincronizada ao servir.")

	# Limpeza
	table.queue_free()
	juice_machine.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE LÍQUIDO NO RESERVATÓRIO FORAM APROVADOS!")
	print("============================================================\n")
	quit(0)
