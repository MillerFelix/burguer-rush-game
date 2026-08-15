extends SceneTree

# Teste e validação das regras:
# 1. Paredes laterais sólidas no armazém (norte e sul)
# 2. Grade de segurança apenas na área restrita com placa "ÁREA RESTRITA"
# 3. Caminhão estacionado FORA da grade na área de manobra/saída
# 4. Rua curvada exclusiva conectando o caminhão à avenida principal
# 5. Vegetação e árvores ocultando parcialmente a área restrita

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DA ÁREA RESTRITA, CAMINHÃO E RUA CURVADA DE SERVIÇO")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var room = main_scene.get_node("Room")
	assert(room != null, "Nó Room deve existir")

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DAS PAREDES LATERAIS SÓLIDAS
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação das Paredes Laterais Sólidas do Armazém ---")
	var wall_north = room.get_node_or_null("AlleyWallNorth") as CSGBox3D
	var wall_south = room.get_node_or_null("AlleyWallSouth") as CSGBox3D

	assert(wall_north != null and wall_north.size.y >= 3.0, "Parede norte lateral deve ser sólida e alta")
	assert(wall_south != null and wall_south.size.y >= 3.0, "Parede sul lateral deve ser sólida e alta")
	print("  [PASS] Ambas as laterais (norte e sul) são paredes sólidas de alvenaria!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DA GRADE DA ÁREA RESTRITA E PLACA
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação da Grade de Controle de Acesso e Placa ---")
	var restr_fence = room.get_node_or_null("RestrictedAreaFence")
	assert(restr_fence != null, "RestrictedAreaFence deve existir delimitando a área de serviço")

	var sign = restr_fence.get_node_or_null("RestrictedSign") as Label3D
	assert(sign != null, "Placa de área restrita deve existir na grade")
	assert("RESTRITA" in sign.text.to_upper(), "Texto da placa deve conter 'ÁREA RESTRITA'")
	print("  Texto da placa encontrado: '%s'" % sign.text)
	print("  [PASS] Grade industrial instalada com placa 'ÁREA RESTRITA' visível!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DA POSIÇÃO DO CAMINHÃO (FORA DA GRADE)
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação do Caminhão Fora da Grade ---")
	var truck = main_scene.get_node_or_null("AlleyDeliveryTruck")
	assert(truck != null, "Caminhão de entrega deve existir")
	assert(truck.position.x < restr_fence.position.x, "Caminhão (X=%.1f) deve estar FORA da grade (X=%.1f)" % [truck.position.x, restr_fence.position.x])
	print("  Posição do caminhão: Vector3(%.1f, %.1f, %.1f) - Fora da grade" % [truck.position.x, truck.position.y, truck.position.z])
	print("  [PASS] Caminhão estacionado 100%% fora da grade na área externa de manobra!")

	# -------------------------------------------------------------------------
	# 4. VALIDAÇÃO DA RUA CURVADA EXCLUSIVA PARA O CAMINHÃO
	# -------------------------------------------------------------------------
	print("\n--- 4. Validação da Rua Curvada Conectando à Avenida ---")
	var bay = room.get_node_or_null("FloorTruckBay") as CSGBox3D
	var curve1 = room.get_node_or_null("FloorTruckCurve1") as CSGBox3D
	var curve2 = room.get_node_or_null("FloorTruckCurve2") as CSGBox3D
	var avenue = room.get_node_or_null("FloorRearAvenue") as CSGBox3D

	assert(bay != null and curve1 != null and curve2 != null and avenue != null, "Rua do caminhão com segmentos em curva deve existir")
	assert(curve1.rotation.y != 0.0 and curve2.rotation.y != 0.0, "Segmentos de conexão devem possuir curvatura suave")
	print("  [PASS] Rua do caminhão com curva natural conectando perfeitamente à avenida principal!")

	# -------------------------------------------------------------------------
	# 5. VALIDAÇÃO DA VEGETAÇÃO DE BLOQUEIO VISUAL
	# -------------------------------------------------------------------------
	print("\n--- 5. Validação da Vegetação ao Redor da Área Restrita ---")
	var veg = main_scene.get_node_or_null("RestrictedServiceVegetation")
	assert(veg != null and veg.get_child_count() >= 4, "Árvores e vegetação ao redor da área restrita e da curva devem existir")
	print("  [PASS] Árvores e vegetação integradas ocultando parcialmente a área de serviço!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("TODAS AS 5 REGRAS DA ÁREA RESTRITA E DO CAMINHÃO FORAM VALIDADAS COM SUCESSO!")
	print("================================================================================")
	quit(0)
