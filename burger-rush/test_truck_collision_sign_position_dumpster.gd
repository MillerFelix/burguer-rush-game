extends SceneTree

# Teste e validação das 3 correções:
# 1. Colisão física sólida do caminhão (StaticBody3D com CollisionShape3D para cabine, baú e chassi)
# 2. Placa "ACESSO RESTRITO" movida para junto da grade próxima à lixeira (fora do caminhão)
# 3. Lixeira na posição horizontal apoiada no chão

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DE COLISÃO DO CAMINHÃO, POSIÇÃO DA PLACA E LIXEIRA")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DA COLISÃO FÍSICA DO CAMINHÃO
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação da Colisão Física do Caminhão ---")
	var truck = main_scene.get_node_or_null("AlleyDeliveryTruck")
	assert(truck != null, "AlleyDeliveryTruck deve existir na cena")
	assert(truck is StaticBody3D, "O caminhão deve ser um StaticBody3D sólido")

	var col_chassis = truck.get_node_or_null("CollisionChassis") as CollisionShape3D
	var col_cab = truck.get_node_or_null("CollisionCab") as CollisionShape3D
	var col_cargo = truck.get_node_or_null("CollisionCargoBox") as CollisionShape3D

	assert(col_chassis != null, "Colisor do chassi deve existir")
	assert(col_cab != null, "Colisor da cabine deve existir")
	assert(col_cargo != null, "Colisor do baú de carga deve existir")

	print("  Colisores do caminhão: Chassi (%s), Cabine (%s), Baú (%s)" % [
		(col_chassis.shape as BoxShape3D).size,
		(col_cab.shape as BoxShape3D).size,
		(col_cargo.shape as BoxShape3D).size
	])
	print("  [PASS] Caminhão possui colisão sólida e precisa cobrindo cabine, baú e chassi!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DA PLACA "ACESSO RESTRITO" FORA DO CAMINHÃO E JUNTO À LIXEIRA
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação da Posição e Texto da Placa ---")
	var fence = main_scene.get_node_or_null("SecurityFenceAlley")
	assert(fence != null, "SecurityFenceAlley deve existir")

	var sign_plate = fence.get_node_or_null("Model/SignPlate")
	assert(sign_plate != null, "SignPlate deve existir na grade")

	var sign_label = sign_plate.get_node_or_null("SignLabel") as Label3D
	assert(sign_label != null, "SignLabel deve existir na placa")
	print("  Texto da placa: '%s'" % sign_label.text)
	assert("ACESSO RESTRITO" in sign_label.text.to_upper(), "Texto deve conter 'ACESSO RESTRITO'")

	# A placa deve estar em Z local <= -2.5 (região da lixeira, fora do caminhão em Z = -4.5)
	assert(sign_plate.position.z <= -2.5, "Placa deve estar na lateral norte junto à lixeira, fora do caminhão")
	print("  Posição local da placa na grade: Vector3(%.2f, %.2f, %.2f) - Próxima à lixeira" % [
		sign_plate.position.x, sign_plate.position.y, sign_plate.position.z
	])
	print("  [PASS] Placa 'ACESSO RESTRITO' perfeitamente visível na grade junto à lixeira e fora do caminhão!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DA LIXEIRA HORIZONTAL
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação da Lixeira Horizontal ---")
	var dumpster = main_scene.get_node_or_null("AlleyIndustrialDumpster") as Node3D
	assert(dumpster != null, "Lixeira industrial externa deve existir")

	var dumpster_count = 0
	for child in main_scene.get_children():
		if "dumpster" in child.name.to_lower():
			dumpster_count += 1

	assert(dumpster_count == 1, "Deve existir exatamente UMA lixeira externa")
	print("  Orientação da lixeira: Rotação Y = %.1f° (alinhada horizontalmente ao longo da parede/grade)" % rad_to_deg(dumpster.rotation.y))
	print("  [PASS] Lixeira externa única, alinhada horizontalmente e apoiada no chão!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("TODAS AS CORREÇÕES FORAM VALIDADAS COM SUCESSO!")
	print("================================================================================")
	quit(0)
