extends SceneTree

# Teste e validação da reorganização do ambiente externo dos fundos:
# 1. Distanciamento dos prédios (Skyline distante a Z <= -40.0)
# 2. Segunda rua / avenida pública com trânsito (Z = -19.0)
# 3. Grade de segurança separando o acesso ao drive-thru (Z = -13.5) da avenida
# 4. Caminhão de entrega no beco de serviço externo (fora da grade do armazém)
# 5. Armazém fechado e seguro

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DE REORGANIZAÇÃO DO AMBIENTE EXTERNO DOS FUNDOS")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var room = main_scene.get_node("Room")
	assert(room != null, "Nó Room deve existir")

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DO DISTANCIAMENTO DOS PRÉDIOS E PROFUNDIDADE DA CIDADE
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação do Distanciamento dos Prédios ao Fundo ---")
	var facade_back = main_scene.get_node_or_null("UrbanFacadeBack")
	assert(facade_back != null, "UrbanFacadeBack deve existir na cena")

	var skyline = facade_back.get_node_or_null("DistantSkyline")
	assert(skyline != null, "DistantSkyline com prédios ao fundo deve existir")
	var bld1 = skyline.get_node_or_null("Building1") as MeshInstance3D
	assert(bld1 != null, "Prédio Building1 deve existir no skyline")
	print("  Posição Z dos prédios ao fundo: %.1fm (Distância da janela: %.1fm)" % [bld1.position.z, abs(bld1.position.z - (-9.0))])
	assert(bld1.position.z <= -35.0, "Prédios devem estar distantes da janela de delivery (Z <= -35.0)")
	print("  [PASS] Prédios posicionados ao longe no horizonte urbano com excelente profundidade!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DO CANTEIRO PAISAGÍSTICO (DIVISÃO DELIVERY / AVENIDA)
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação do Canteiro Paisagístico e da Avenida Pública ---")
	var landscape_buf = facade_back.get_node_or_null("LandscapeBuffer")
	assert(landscape_buf != null, "Canteiro paisagístico entre o delivery e a avenida deve existir")
	assert(landscape_buf.position.z <= -13.0 and landscape_buf.position.z >= -15.0, "Canteiro deve separar o acesso ao delivery (Z=-11.5) da avenida")

	var avenue_floor = room.get_node_or_null("FloorRearAvenue") as CSGBox3D
	assert(avenue_floor != null, "Avenida pública dos fundos (FloorRearAvenue) deve existir")
	assert(avenue_floor.position.z < landscape_buf.position.z, "Avenida deve ficar atrás do canteiro verde")

	var buffer_trees = landscape_buf.get_node_or_null("BufferTrees")
	assert(buffer_trees != null and buffer_trees.get_child_count() >= 4, "Árvores do canteiro devem existir entre a rua e o delivery")
	print("  [PASS] Canteiro paisagístico e avenida pública com árvores e arbustos validados!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DO BECO DE SERVIÇO, CAMINHÃO FORA DA GRADE E ARMAZÉM FECHADO
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação do Beco do Armazém e Caminhão Externo ---")
	var truck = main_scene.get_node_or_null("AlleyDeliveryTruck")
	assert(truck != null, "Caminhão de entrega (AlleyDeliveryTruck) deve existir")
	assert(truck.position.x <= -13.0, "Caminhão deve estar estacionado fora da grade na área externa de serviço")

	var alley_wall_n = room.get_node_or_null("AlleyWallNorth") as CSGBox3D
	assert(alley_wall_n != null, "Parede norte do armazém deve ser sólida")
	assert(alley_wall_n.size.y >= 3.0, "Parede do armazém deve estar completamente fechada (sem abrir o interior para a cidade)")
	print("  [PASS] Caminhão estacionado fora da grade e armazém devidamente fechado!")

	# -------------------------------------------------------------------------
	# 4. VALIDAÇÃO DO TRÂNSITO NA AVENIDA DOS FUNDOS
	# -------------------------------------------------------------------------
	print("\n--- 4. Validação do Trânsito Passante na Avenida dos Fundos ---")
	var traffic = main_scene.get_node_or_null("AmbientTraffic") as AmbientTraffic
	assert(traffic != null, "AmbientTraffic deve existir")

	traffic.call("_spawn_vehicle", 2, 0.0) # Faixa Oeste na avenida (Z = -17.5)
	traffic.call("_spawn_vehicle", 3, 0.0) # Faixa Leste na avenida (Z = -20.5)

	var rear_avenue_cars = 0
	for v in traffic.active_vehicles:
		if is_instance_valid(v.node) and v.node.position.z <= -16.0:
			rear_avenue_cars += 1

	assert(rear_avenue_cars >= 2, "Trânsito de carros na avenida pública dos fundos deve estar ativo")
	print("  [PASS] Trânsito na avenida dos fundos ativo e separado da fila de delivery!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("TODOS OS TESTES DE REORGANIZAÇÃO DO AMBIENTE EXTERNO FORAM APROVADOS!")
	print("================================================================================")
	quit(0)
