extends SceneTree

const AmbientTraffic = preload("res://src/environment/ambient_traffic.gd")
const AmbientPedestrians = preload("res://src/environment/ambient_pedestrians.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE VIDA E AMBIENTAÇÃO EXTERNA")
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
	# TESTE 1: BARREIRA INVISÍVEL NA SAÍDA FRONTAL
	# ---------------------------------------------------------
	print("\n--- Teste 1: Barreira Invisível na Saída Frontal ---")
	var barrier = main_scene.get_node_or_null("Room/InvisibleExitBarrier") as StaticBody3D
	assert(barrier != null, "Barreira invisível de saída deve existir sob Room")
	assert(barrier.collision_layer == 1, "Barreira deve colidir na camada 1 (jogador)")
	assert(barrier.position.z >= 9.0 and barrier.position.z <= 9.5, "Barreira deve estar na saída frontal (z ~ 9.25m)")

	var col = barrier.get_node("CollisionShape3D") as CollisionShape3D
	var shape = col.shape as BoxShape3D
	assert(shape.size.x >= 15.0 and shape.size.y >= 3.0, "Barreira deve bloquear toda a largura da fachada frontal")
	assert(barrier.get_child_count() == 1, "Barreira não deve conter MeshInstances visíveis (100% invisível)")
	print("  [PASS] Barreira invisível instalada com sucesso na saída frontal!")

	# ---------------------------------------------------------
	# TESTE 2: REMOÇÃO DA PLANTA PRÓXIMA À LIXEIRA (SW)
	# ---------------------------------------------------------
	print("\n--- Teste 2: Remoção da Planta no Canto da Lixeira ---")
	assert(main_scene.get_node_or_null("PlantSouthWest") == null, "PlantSouthWest deve ter sido removida")
	assert(main_scene.get_node_or_null("PlantSouthEast") != null, "PlantSouthEast deve permanecer")
	assert(main_scene.get_node_or_null("PlantNorthWest") != null, "PlantNorthWest deve permanecer")
	assert(main_scene.get_node_or_null("PlantNorthEast") != null, "PlantNorthEast deve permanecer")
	assert(main_scene.get_node_or_null("DiningWasteStation") != null, "Estação de descarte deve permanecer")
	print("  [PASS] Planta sobreposta removida, lixeira e demais plantas preservadas!")

	# ---------------------------------------------------------
	# TESTE 3: RUA URBANA E FACHADAS DO OUTRO LADO DA RUA
	# ---------------------------------------------------------
	print("\n--- Teste 3: Rua Urbana, Calçadas e Casas/Comércio ---")
	var street = main_scene.get_node("Room/FloorStreet") as CSGBox3D
	var sidewalk_front = main_scene.get_node("Room/FloorSidewalk") as CSGBox3D
	var sidewalk_across = main_scene.get_node("Room/FloorSidewalkAcross") as CSGBox3D
	var facade = main_scene.get_node_or_null("UrbanFacade")

	assert(street.size.x >= 80.0, "Rua deve se estender por toda a largura urbana")
	assert(sidewalk_front != null and sidewalk_across != null, "Calçadas de ambos os lados da rua devem existir")
	assert(facade != null, "Fachada urbana de casas e comércio deve existir")
	assert(facade.has_node("House1") and facade.has_node("Shop2") and facade.has_node("House3"), "Fachada deve possuir variedade arquitetônica")
	print("  [PASS] Rua, calçadas e fileira de casas e comércio instalados com sucesso!")

	# ---------------------------------------------------------
	# TESTE 4: TRÂNSITO E CARROS PASSANDO NA RUA
	# ---------------------------------------------------------
	print("\n--- Teste 4: Sistema de Tráfego de Carros Ambientais ---")
	var traffic = main_scene.get_node_or_null("AmbientTraffic") as AmbientTraffic
	assert(traffic != null, "Nó de tráfego ambiental deve existir")
	traffic._ready()
	assert(traffic.active_vehicles.size() > 0, "Carros devem estar ativos na via")

	# Simula 0.5s de tráfego
	var initial_x = traffic.active_vehicles[0].node.position.x
	traffic._process(0.5)
	var new_x = traffic.active_vehicles[0].node.position.x
	assert(initial_x != new_x, "Carros devem se mover ao longo da rua")
	print("  [PASS] Carros se movem fluidamente na rua com spawn/despawn!")

	# ---------------------------------------------------------
	# TESTE 5: PEDESTRES CAMINHANDO NA CALÇADA
	# ---------------------------------------------------------
	print("\n--- Teste 5: Pedestres Ambientais na Calçada ---")
	var pedestrians = main_scene.get_node_or_null("AmbientPedestrians") as AmbientPedestrians
	assert(pedestrians != null, "Nó de pedestres ambientais deve existir")
	pedestrians._ready()
	assert(pedestrians.active_peds.size() > 0, "Pedestres devem estar ativos na calçada")

	# Simula 0.5s de caminhada
	var initial_ped_x = pedestrians.active_peds[0].node.position.x
	pedestrians._process(0.5)
	var new_ped_x = pedestrians.active_peds[0].node.position.x
	assert(initial_ped_x != new_ped_x, "Pedestres devem caminhar pela calçada")
	print("  [PASS] Pedestres caminham de forma independente na calçada sem interferir no restaurante!")

	# Limpeza
	main_scene.queue_free()
	clock.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE AMBIENTAÇÃO EXTERNA FORAM APROVADOS!")
	print("============================================================")
	quit(0)
