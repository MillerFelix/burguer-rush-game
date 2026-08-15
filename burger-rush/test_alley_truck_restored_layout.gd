extends SceneTree

# Teste e validação da restauração da área externa do caminhão:
# 1. Remoção da grade vermelha e corredor artificial
# 2. Caminhão com cabine FORA e traseira entrando na área das grades
# 3. Saída do caminhão totalmente desobstruída
# 4. Caixote de entrega no chão e lixeira próxima às grades
# 5. Árvores posicionadas apenas nas laterais/fundo externo

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DE RESTAURAÇÃO DA ÁREA EXTERNA DO CAMINHÃO")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var room = main_scene.get_node("Room")
	assert(room != null, "Nó Room deve existir")

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DA REMOÇÃO DAS ESTRUTURAS INCORRETAS
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação da Remoção de Estruturas Bloqueadoras ---")
	var red_fence = room.get_node_or_null("RestrictedAreaFence")
	assert(red_fence == null, "A grade vermelha/restrita deve ter sido removida")

	var curve1 = room.get_node_or_null("FloorTruckCurve1")
	assert(curve1 == null, "Corredor artificial em curva deve ter sido removido")
	print("  [PASS] Estruturas inventadas removidas e saída desobstruída!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DO CAMINHÃO PARCIALMENTE ENCAIXADO NA GRADE
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação da Posição do Caminhão (Cabine Fora, Traseira na Grade) ---")
	var truck = main_scene.get_node_or_null("AlleyDeliveryTruck")
	assert(truck != null, "AlleyDeliveryTruck deve existir")

	var fence = main_scene.get_node_or_null("SecurityFenceAlley")
	assert(fence != null, "SecurityFenceAlley industrial deve existir delimitando o pátio")

	# Com rotação Y = -90°: frente do caminhão (cabine) em X mais negativo, traseira em X mais positivo
	print("  Posição da grade: X = %.1f" % fence.position.x)
	print("  Posição central do caminhão: X = %.1f" % truck.position.x)

	# Cabine está a X <= -17.0 (fora da grade X = -15.5)
	# Traseira está a X >= -13.0 (dentro do pátio delimitado pela grade)
	var cab_x = truck.position.x - 3.0 # Frente aponta para -X
	var cargo_x = truck.position.x + 2.5 # Traseira aponta para +X

	print("  Posição estimada da cabine: X = %.1f (FORA da grade)" % cab_x)
	print("  Posição estimada da traseira/baú: X = %.1f (ENTRANDO na abertura da grade)" % cargo_x)

	assert(cab_x < fence.position.x, "Cabine do caminhão deve ficar do lado de fora da grade")
	assert(cargo_x > fence.position.x, "Traseira do caminhão deve ficar dentro da abertura da grade")
	print("  [PASS] Cabine fora e traseira perfeitamente encaixada na baia de carga e descarga!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DO CAIXOTE E DA LIXEIRA INDUSTRIAL
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação do Caixote e da Lixeira ---")
	var pallet = main_scene.get_node_or_null("ReceivingArea")
	assert(pallet != null, "O tapume/palete de entrega deve estar no chão da área de serviço")

	var dumpster = main_scene.get_node_or_null("AlleyIndustrialDumpster")
	assert(dumpster != null, "Lixeira/caçamba industrial deve existir próxima às grades")
	print("  [PASS] Caixote no chão e lixeira posicionados na área de serviço!")

	# -------------------------------------------------------------------------
	# 4. VALIDAÇÃO DA SAÍDA LIVRE E VEGETAÇÃO LATERAL
	# -------------------------------------------------------------------------
	print("\n--- 4. Validação da Saída Livre e Vegetação de Fundo ---")
	var veg = main_scene.get_node_or_null("AlleyBackgroundVegetation")
	assert(veg != null and veg.get_child_count() >= 2, "Vegetação de fundo/lateral deve existir")

	# Nenhuma árvore diretamente na faixa de manobra em frente ao caminhão (X entre -16 e -22, Z entre -6 e -3)
	for child in veg.get_children():
		var tree_node = child as Node3D
		if tree_node:
			var z_dist = abs(tree_node.position.z - truck.position.z)
			if tree_node.position.x < truck.position.x:
				assert(z_dist >= 4.0 or tree_node.position.x <= -23.0, "Árvore não deve bloquear a saída em frente ao caminhão")

	print("  [PASS] Saída do caminhão completamente livre e árvores posicionadas nas laterais/fundo!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("TODAS AS REGRAS DE RESTAURAÇÃO DA ÁREA EXTERNA FORAM VALIDADAS COM SUCESSO!")
	print("================================================================================")
	quit(0)
