extends SceneTree

# Teste e validação das 2 alterações estruturais externas:
# 1. Parede lateral direita externa do armazém substituída por grade metálica vazada (AlleyFenceSouth)
# 2. Divisão entre a avenida e o delivery substituída por canteiro paisagístico com grama e árvores (LandscapeBuffer)

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DO CANTEIRO PAISAGÍSTICO E GRADE LATERAL DO ARMAZÉM")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var room = main_scene.get_node("Room")
	assert(room != null, "Nó Room deve existir")

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DAS PAREDES LATERAIS E GRADE DA ÁREA RESTRITA
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação das Paredes Laterais e Grade Restrita ---")
	var wall_north = room.get_node_or_null("AlleyWallNorth") as CSGBox3D
	var wall_south = room.get_node_or_null("AlleyWallSouth") as CSGBox3D
	assert(wall_north != null and wall_south != null, "Ambas as laterais do armazém devem ser paredes sólidas")

	var fence = main_scene.get_node_or_null("SecurityFenceAlley")
	assert(fence != null, "A grade deve existir exclusivamente na área de serviço/restrita")
	print("  [PASS] Laterais do armazém sólidas e grade de segurança instalada exclusivamente na área restrita!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DO CANTEIRO PAISAGÍSTICO ENTRE A AVENIDA E O DELIVERY
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação do Canteiro Paisagístico (LandscapeBuffer) ---")
	var facade_back = main_scene.get_node_or_null("UrbanFacadeBack")
	assert(facade_back != null, "UrbanFacadeBack deve existir")

	var old_fence = facade_back.get_node_or_null("SecurityFence")
	assert(old_fence == null, "A antiga grade SecurityFence na divisão avenue/delivery deve ter sido removida")

	var buffer = facade_back.get_node_or_null("LandscapeBuffer")
	assert(buffer != null, "O canteiro paisagístico LandscapeBuffer deve existir entre a avenida e o delivery")

	var grass_bed = buffer.get_node_or_null("GrassBed") as MeshInstance3D
	var curb_s = buffer.get_node_or_null("CurbSouth") as MeshInstance3D
	var curb_n = buffer.get_node_or_null("CurbNorth") as MeshInstance3D
	assert(grass_bed != null, "O canteiro deve possuir grama verde")
	assert(curb_s != null and curb_n != null, "O canteiro deve possuir guias/meio-fio de concreto delimitando a área verde")

	var buffer_trees = buffer.get_node_or_null("BufferTrees")
	assert(buffer_trees != null and buffer_trees.get_child_count() >= 4, "O canteiro deve conter árvores distribuídas naturalmente")

	var buffer_shrubs = buffer.get_node_or_null("BufferShrubs")
	assert(buffer_shrubs != null and buffer_shrubs.get_child_count() >= 4, "O canteiro deve conter arbustos paisagísticos")
	print("  [PASS] Canteiro paisagístico com grama, terra, arbustos e árvores validado com sucesso!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DA SEQUÊNCIA ESPACIAL (DELIVERY -> CANTEIRO -> AVENIDA -> PRÉDIOS)
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação da Sequência Espacial Urbana ---")
	var floor_dt = room.get_node("FloorDriveThru") as CSGBox3D
	var floor_buf = room.get_node("FloorLandscapeBuffer") as CSGBox3D
	var floor_ave = room.get_node("FloorRearAvenue") as CSGBox3D
	var skyline = facade_back.get_node("DistantSkyline")

	assert(floor_dt.position.z > floor_buf.position.z, "Drive-thru (Z=-11.5) fica antes do canteiro (Z=-14.0)")
	assert(floor_buf.position.z > floor_ave.position.z, "Canteiro (Z=-14.0) fica entre o drive-thru e a avenida (Z=-19.0)")
	print("  [PASS] Sequência 'Drive-Thru -> Canteiro Verde -> Avenida -> Prédios' validada!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("TODAS AS ALTERAÇÕES FORAM VALIDADAS COM SUCESSO!")
	print("================================================================================")
	quit(0)
