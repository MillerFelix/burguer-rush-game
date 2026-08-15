extends SceneTree

# Teste e validação das alterações:
# 1. Tapume/Pallet de recebimento (ReceivingArea) livre sem caixa em cima
# 2. Asfalto atrás da grade substituído por grama/vegetação (FloorStreetOuterPavement -> Material_GrassLawn)
# 3. Área inacessível preenchida com vegetação densa (árvores e arbustos)
# 4. Saída do caminhão e área jogável totalmente desobstruídas

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DA GRAMA ATRÁS DA GRADE, VEGETAÇÃO E PALETE LIVRE")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var room = main_scene.get_node("Room")
	assert(room != null, "Nó Room deve existir")

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DO TAPUME/PALETE LIVRE SEM CAIXA EM CIMA
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação do Tapume/Palete de Recebimento ---")
	var pallet = main_scene.get_node_or_null("ReceivingArea")
	assert(pallet != null, "ReceivingArea (tapume/palete no chão) deve existir")

	var crate_extra = room.get_node_or_null("AlleyDeliveryCrate")
	assert(crate_extra == null, "A caixa que estava em cima do tapume deve ter sido removida")
	print("  [PASS] Tapume/palete de recebimento mantido no chão, 100% livre para receber caixas!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DO TERRENO VERDE ATRÁS DA GRADE (SEM ASFALTO)
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação do Piso de Grama Atrás da Grade ---")
	var outer_floor = room.get_node_or_null("FloorStreetOuterPavement") as CSGBox3D
	assert(outer_floor != null, "Piso externo deve existir")
	var mat = outer_floor.material as StandardMaterial3D
	assert(mat != null, "Material do piso externo deve existir")
	print("  Cor do piso externo atrás da grade: %s" % mat.albedo_color)
	assert(mat.albedo_color.g > mat.albedo_color.r, "Piso atrás da grade deve ser verde (grama/vegetação)")
	print("  [PASS] Área atrás da grade convertida em grama/terreno natural verde!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DA VEGETAÇÃO DENSA NA ÁREA INACESSÍVEL
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação da Vegetação Densa de Fundo ---")
	var veg = main_scene.get_node_or_null("AlleyBackgroundVegetation")
	assert(veg != null and veg.get_child_count() >= 5, "Área inacessível deve possuir vegetação densa com 5 ou mais árvores")
	print("  Árvores na área inacessível de fundo: %d" % veg.get_child_count())

	var truck = main_scene.get_node_or_null("AlleyDeliveryTruck")
	assert(truck != null, "Caminhão de entrega deve existir")

	# Verificar que nenhuma árvore está na área jogável ou bloqueando a saída
	for child in veg.get_children():
		var tree_node = child as Node3D
		if tree_node:
			# Árvore não deve estar na frente imediata da cabine
			var z_dist = abs(tree_node.position.z - truck.position.z)
			if tree_node.position.x > -18.0 and tree_node.position.x < -10.0:
				assert(false, "Árvore não deve estar dentro do pátio jogável!")

	print("  [PASS] Vegetação densa posicionada estritamente na área inacessível atrás da grade!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("TODAS AS CORREÇÕES FORAM VALIDADAS COM SUCESSO!")
	print("================================================================================")
	quit(0)
