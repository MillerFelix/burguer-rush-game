extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE POLIMENTO DE AMBIENTAÇÃO")
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
	# TESTE 1: JANELAS COMPLETAS NAS EXTREMIDADES (SEM FRESTAS)
	# ---------------------------------------------------------
	print("\n--- Teste 1: Extremidades das Janelas Perfeitamente Integradas ---")
	var win_e1 = main_scene.get_node("Room/WindowEast1")
	var top_frame = win_e1.get_node("FrameTop") as MeshInstance3D
	var top_mesh = top_frame.mesh as BoxMesh

	assert(top_mesh.size.z >= 3.0, "Moldura horizontal da janela deve cobrir todos os 3.0m do vão da parede (atual: %.2fm)" % top_mesh.size.z)
	print("  [PASS] Janelas preenchem 100%% do vão da parede (3.00m) sem qualquer fresta!")

	# ---------------------------------------------------------
	# TESTE 2: TERRA DOS VASOS SÓLIDA E DENTRO DA BORDA
	# ---------------------------------------------------------
	print("\n--- Teste 2: Terra Sólida e Rebaixada Dentro dos Vasos ---")
	var plant = main_scene.get_node("PlantSouthWest")
	var soil = plant.get_node("Model/Soil") as MeshInstance3D
	var pot = plant.get_node("Model/Pot") as MeshInstance3D
	var pot_mesh = pot.mesh as CylinderMesh
	var soil_mesh = soil.mesh as CylinderMesh

	# Topo da terra (0.48 + 0.06 = 0.54m) deve ficar dentro/abaixo do topo do vaso (0.55m)
	var soil_top_y = soil.position.y + soil_mesh.height * 0.5
	var pot_top_y = pot_mesh.height
	assert(soil_top_y < pot_top_y, "Terra deve ficar abaixo da borda do vaso (terra y: %.2fm, vaso y: %.2fm)" % [soil_top_y, pot_top_y])
	assert(soil_mesh.top_radius < pot_mesh.top_radius, "Raio da terra deve caber dentro do vaso")
	assert(plant.has_node("Model/Stem"), "Planta deve possuir caule conectado à terra")
	print("  [PASS] Terra sólida e encaixada com perfeição dentro do vaso!")

	# ---------------------------------------------------------
	# TESTE 3: LIXEIRA TRIPLA ESTILO FAST-FOOD COM BANDEJA SUPERIOR
	# ---------------------------------------------------------
	print("\n--- Teste 3: Estação de Descarte Tripla de Fast-Food ---")
	var waste_station = main_scene.get_node("DiningWasteStation") as TrashBin
	assert(waste_station != null, "Estação de descarte de salão deve existir")
	assert(waste_station.has_node("Model/FlapOrganic"), "Deve possuir compartimento Orgânico")
	assert(waste_station.has_node("Model/FlapRecycle"), "Deve possuir compartimento Reciclável")
	assert(waste_station.has_node("Model/FlapGeneral"), "Deve possuir compartimento Geral")
	assert(waste_station.has_node("Model/TrayTop"), "Deve possuir bandeja/suporte superior")
	print("  [PASS] Estação de descarte tripla moderna com suporte de bandejas validada!")

	# ---------------------------------------------------------
	# TESTE 4: REMOÇÃO TOTAL DOS QUADROS DAS PAREDES
	# ---------------------------------------------------------
	print("\n--- Teste 4: Remoção de Todos os Quadros das Paredes ---")
	assert(main_scene.get_node_or_null("Room/PosterEastBurger") == null, "Pôster de Burger deve ter sido removido")
	assert(main_scene.get_node_or_null("Room/PosterWestShake") == null, "Pôster de Shake deve ter sido removido")
	assert(main_scene.get_node_or_null("Room/PosterEast1") == null, "Pôsteres antigos devem ter sido removidos")
	print("  [PASS] Paredes do salão completamente limpas e desobstruídas!")

	# Limpeza
	main_scene.queue_free()
	clock.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE POLIMENTO DE AMBIENTAÇÃO FORAM APROVADOS!")
	print("============================================================")
	quit(0)
