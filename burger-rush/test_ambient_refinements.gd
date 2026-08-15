extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE REFINAMENTO DE AMBIENTAÇÃO")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var clock = GameClock.new()
	root.add_child(clock)
	clock._enter_tree()
	clock.open_restaurant()

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	# ---------------------------------------------------------
	# TESTE 1: REMOÇÃO DA PLANTA ANTIGA E MANUTENÇÃO DAS NOVAS
	# ---------------------------------------------------------
	print("\n--- Teste 1: Remoção da Planta Antiga e Manutenção das Novas ---")
	var old_plant1 = main_scene.get_node_or_null("Room/PottedPlantDiner")
	var old_plant2 = main_scene.get_node_or_null("Room/PottedPlantDiner2")
	assert(old_plant1 == null and old_plant2 == null, "Plantas antigas devem ter sido completamente removidas")

	var plant_sw = main_scene.get_node_or_null("PlantSouthWest")
	var plant_se = main_scene.get_node_or_null("PlantSouthEast")
	assert(plant_sw != null and plant_se != null, "Novas plantas de cerâmica devem permanecer no salão")
	print("  [PASS] Plantas antigas removidas e plantas novas preservadas!")

	# ---------------------------------------------------------
	# TESTE 2: LIXEIRA DE CLIENTES PRÓXIMA À ENTRADA
	# ---------------------------------------------------------
	print("\n--- Teste 2: Lixeira / Estação de Descarte dos Clientes ---")
	var waste_station = main_scene.get_node_or_null("DiningWasteStation") as TrashBin
	assert(waste_station != null, "Lixeira de clientes do salão deve existir")
	assert(waste_station.position.z >= 7.0, "Lixeira deve ficar próxima da entrada (z >= 7.0m, atual: %.2f)" % waste_station.position.z)
	assert(absf(waste_station.position.x) > 4.0, "Lixeira não deve bloquear a porta central (|x| > 4.0m, atual: %.2f)" % absf(waste_station.position.x))
	print("  [PASS] Lixeira de clientes posicionada com sucesso sem bloquear circulação!")

	# ---------------------------------------------------------
	# TESTE 3: CORREÇÃO DE ORIENTAÇÃO DA JANELA
	# ---------------------------------------------------------
	print("\n--- Teste 3: Alinhamento Horizontal das Janelas com as Paredes ---")
	var win_e1 = main_scene.get_node("Room/WindowEast1") as Node3D
	var win_w1 = main_scene.get_node("Room/WindowWest1") as Node3D

	# Verifica se a rotação é neutra (alinhada paralelamente à parede no eixo Z)
	assert(absf(win_e1.rotation.y) < 0.01, "Janela Leste 1 deve estar alinhada horizontalmente com a parede (rot Y = 0)")
	assert(absf(win_w1.rotation.y) < 0.01, "Janela Oeste 1 deve estar alinhada horizontalmente com a parede (rot Y = 0)")

	var frame_v = win_e1.get_node("FrameLeft") as MeshInstance3D
	var glass = win_e1.get_node("GlassPane") as MeshInstance3D
	assert(frame_v != null and glass != null, "Elementos da janela preservados e corretamente posicionados")
	print("  [PASS] Janelas perfeitamente alinhadas e embutidas nas paredes laterais!")

	# ---------------------------------------------------------
	# TESTE 4: EXPANSÃO DE VEGETAÇÃO E HORIZONTE EXTERNO
	# ---------------------------------------------------------
	print("\n--- Teste 4: Expansão da Vegetação Externa para Bloqueio de Void ---")
	var lawn_w = main_scene.get_node("Room/LawnWestOuter") as CSGBox3D
	var lawn_e = main_scene.get_node("Room/LawnEastOuter") as CSGBox3D
	var lawn_n = main_scene.get_node("Room/LawnNorthDeep") as CSGBox3D
	var lawn_s = main_scene.get_node("Room/LawnSouthDeep") as CSGBox3D

	assert(lawn_w.size.x >= 30.0 and lawn_e.size.x >= 30.0, "Gramados laterais devem cobrir mais de 30m de profundidade")
	assert(lawn_n.size.x >= 80.0 and lawn_s.size.x >= 80.0, "Gramados norte e sul devem cobrir mais de 80m de largura")

	var tree_count = 0
	for child in main_scene.get_children():
		if "Tree" in child.name:
			tree_count += 1
	assert(tree_count >= 12, "Deve haver barreira densa de árvores (encontradas: %d)" % tree_count)
	print("  [PASS] Vegetação externa expandida (%d árvores e gramados profundos cobrindo o horizonte)!" % tree_count)

	# Limpeza
	main_scene.queue_free()
	clock.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE REFINAMENTO DE AMBIENTAÇÃO FORAM APROVADOS!")
	print("============================================================")
	quit(0)
