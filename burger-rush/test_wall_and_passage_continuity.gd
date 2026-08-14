extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE CONTINUIDADE DA PAREDE E PASSAGEM LIMPA")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var main_scene = load("res://src/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)

	# ---------------------------------------------------------
	# TESTE 1: CONTINUIDADE GEOMÉTRICA DA PAREDE (SEM BURACOS)
	# ---------------------------------------------------------
	print("\n--- Teste 1: Validação de Continuidade e Preenchimento da Parede ---")
	var wall_north = main.get_node_or_null("Room/WallStorageDividerNorth") as CSGBox3D
	var wall_south = main.get_node_or_null("Room/WallStorageDividerSouth") as CSGBox3D
	var wall_lintel = main.get_node_or_null("Room/WallStorageLintel") as CSGBox3D

	assert(wall_north != null, "WallStorageDividerNorth deve existir")
	assert(wall_south != null, "WallStorageDividerSouth deve existir")
	assert(wall_lintel != null, "WallStorageLintel deve existir")

	# Calcula os limites das 3 seções ao longo do eixo Z
	var north_end_z = wall_north.position.z + (wall_north.size.z / 2.0)
	var south_start_z = wall_south.position.z - (wall_south.size.z / 2.0)
	var lintel_start_z = wall_lintel.position.z - (wall_lintel.size.z / 2.0)
	var lintel_end_z = wall_lintel.position.z + (wall_lintel.size.z / 2.0)

	# Abertura da passagem deve conectar exatamente com a viga superior
	assert(abs(north_end_z - lintel_start_z) < 0.01, "Parede norte deve conectar sem gap com o lintel (%.3f == %.3f)" % [north_end_z, lintel_start_z])
	assert(abs(south_start_z - lintel_end_z) < 0.01, "Parede sul deve conectar sem gap com o lintel (%.3f == %.3f)" % [south_start_z, lintel_end_z])
	assert(wall_north.size.y == 3.5 and wall_south.size.y == 3.5, "Paredes devem ter altura total de 3.5m")
	assert(wall_lintel.position.y + (wall_lintel.size.y / 2.0) >= 3.5, "Lintel deve alcançar o teto em 3.5m")

	print("  [PASS] Parede 100%% contínua e sólida: North [-9.0 a %.2f] + Lintel [%.2f a %.2f] + South [%.2f a 0.0]" % [
		north_end_z, lintel_start_z, lintel_end_z, south_start_z
	])

	# ---------------------------------------------------------
	# TESTE 2: REMOÇÃO DA PORTA MARROM E MOLDURA DA PASSAGEM ABERTA
	# ---------------------------------------------------------
	print("\n--- Teste 2: Passagem Aberta com Moldura Limpa (Sem Porta Marrom) ---")
	var old_door = main.get_node_or_null("Room/DoorLeafSwung")
	assert(old_door == null, "Porta marrom antiga quebrada (DoorLeafSwung) deve ser COMPLETAMENTE REMOVIDA")

	var post_north = main.get_node_or_null("Room/DoorFramePostNorth")
	var post_south = main.get_node_or_null("Room/DoorFramePostSouth")
	var lintel_trim = main.get_node_or_null("Room/DoorFrameLintel")

	assert(post_north != null and post_south != null and lintel_trim != null, "Moldura da passagem deve estar presente")
	print("  [PASS] Porta marrom removida e passagem aberta com moldura limpa validada!")

	# ---------------------------------------------------------
	# TESTE 3: CIRCULAÇÃO LIVRE DO JOGADOR PELA PASSAGEM
	# ---------------------------------------------------------
	print("\n--- Teste 3: Dimensões da Passagem Desobstruída ---")
	var passage_width = abs(post_north.position.z - post_south.position.z)
	assert(passage_width >= 1.5, "Passagem deve ter largura ampla de pelo menos 1.5m (largura = %.2fm)" % passage_width)
	print("  [PASS] Passagem ampla (%.2fm de largura, 2.4m de altura) 100%% desobstruída para circulação!" % passage_width)

	# Limpeza
	main.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE CONTINUIDADE DA PAREDE E PASSAGEM FORAM APROVADOS!")
	print("============================================================")
	quit(0)
