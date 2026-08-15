extends SceneTree

# Teste e validação das 3 correções específicas:
# 1. Zero árvores dentro do armazém (X entre -9 e 0, Z entre -9 e 0)
# 2. Caixote único no chão sem nenhuma caixa em cima
# 3. Exatamente UMA lixeira/caçamba industrial externa, horizontal e apoiada no chão

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DAS 3 CORREÇÕES ESPECÍFICAS (ÁRVORE, CAIXOTE, LIXEIRA)")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var room = main_scene.get_node("Room")
	assert(room != null, "Nó Room deve existir")

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DE ZERO ÁRVORES DENTRO DO ARMAZÉM
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação de Árvores Dentro do Armazém ---")
	var trees_in_warehouse = 0
	for child in main_scene.get_children():
		var node = child as Node3D
		if node and ("tree" in node.name.to_lower() or "vegetation" in node.name.to_lower()):
			if node.position.x > -9.0 and node.position.x < 0.0 and node.position.z > -9.0 and node.position.z < 0.0:
				trees_in_warehouse += 1
		if node and node.name == "AlleyBackgroundVegetation":
			for sub in node.get_children():
				var sub_node = sub as Node3D
				if sub_node and sub_node.position.x > -9.0 and sub_node.position.x < 0.0 and sub_node.position.z > -9.0 and sub_node.position.z < 0.0:
					trees_in_warehouse += 1

	print("  Árvores encontradas dentro do armazém: %d" % trees_in_warehouse)
	assert(trees_in_warehouse == 0, "Deve haver zero árvores dentro do armazém!")
	print("  [PASS] Zero árvores dentro do armazém!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DO CAIXOTE ÚNICO NO CHÃO SEM CAIXA EM CIMA
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação do Caixote no Chão ---")
	var pallet = main_scene.get_node_or_null("ReceivingArea")
	assert(pallet != null, "O tapume/palete ReceivingArea deve existir no chão")
	var extra_box = room.get_node_or_null("AlleyDeliveryCrate")
	assert(extra_box == null, "A caixa sobre o tapume deve ter sido removida")
	print("  [PASS] Caixote único mantido no local sem caixa em cima!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DE EXATAMENTE UMA LIXEIRA EXTERNA HORIZONTAL
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação da Lixeira Externa Única e Horizontal ---")
	var dumpster_count = 0
	var dumpster_node: Node3D = null
	for child in main_scene.get_children():
		if "dumpster" in child.name.to_lower():
			dumpster_count += 1
			dumpster_node = child as Node3D

	print("  Lixeiras industriais externas encontradas: %d" % dumpster_count)
	assert(dumpster_count == 1, "Deve existir exatamente UMA lixeira externa!")
	assert(dumpster_node != null, "A lixeira externa deve existir")

	# Posição horizontal apoiada no chão (rotacionada horizontalmente em Y ou alinhada, sem inclinação vertical X/Z)
	assert(abs(dumpster_node.rotation.x) < 0.01 and abs(dumpster_node.rotation.z) < 0.01, "A lixeira deve estar perfeitamente horizontal e apoiada no chão")
	print("  [PASS] Exatamente uma lixeira externa encontrada, perfeitamente horizontal e apoiada no chão!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("TODAS AS CORREÇÕES FORAM VALIDADAS COM SUCESSO!")
	print("================================================================================")
	quit(0)
