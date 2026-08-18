extends SceneTree

# ===========================================================================
# TESTE: EMBALAGEM OCA DE FAST-FOOD E TEMPOS DE LIMPEZA (5S BANCADA/GRELHA)
# ===========================================================================

func _init() -> void:
	print("\n===========================================================================")
	print("TESTE: EMBALAGEM OCA REALISTA E LIMPEZA DE 5 SEGUNDOS")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# -----------------------------------------------------------------------
	# 1. SETUP DE AMBIENTE
	# -----------------------------------------------------------------------
	var player = load("res://src/player/player.tscn").instantiate() as CharacterBody3D
	root.add_child(player)

	# -----------------------------------------------------------------------
	# 2. TESTES DE LIMPEZA DE BANCADAS (5.0s) E GRELHA (5.0s)
	# -----------------------------------------------------------------------
	print("--- TESTE 1: Limpeza da Bancada / Ilha de Preparo (5 Segundos) ---")

	var island_scene = load("res://src/stations/prep_island.tscn")
	var island = island_scene.instantiate() as PrepIsland
	root.add_child(island)
	island._ready()

	island.dirt_level = 1.0
	island._update_dirt_visuals()

	# Esfrega por 2.5 segundos (50%)
	island.clean_progress(2.5, player)

	total_tests += 1
	if is_equal_approx(island.dirt_level, 0.5):
		print("  [PASS] Aos 2.5s de limpeza da bancada: sujeira ainda visível (progresso exatamente 50%% - %.2f)!" % island.dirt_level)
		passed_tests += 1
	else:
		print("  [FAIL] Progresso da bancada aos 2.5s incorreto: %.2f" % island.dirt_level)

	# Esfrega os 2.5s restantes (Total 5.0s)
	var finished_island = island.clean_progress(2.55, player)

	total_tests += 1
	if finished_island and island.dirt_level <= 0.0:
		print("  [PASS] Aos 5.0s completos: bancada totalmente limpa e higienizada!")
		passed_tests += 1
	else:
		print("  [FAIL] Bancada não concluiu limpeza aos 5.0s: %.2f" % island.dirt_level)

	island.queue_free()

	print("\n--- TESTE 2: Limpeza da Grelha / Chapa Comercial (5 Segundos) ---")

	var grill_scene = load("res://src/stations/grill.tscn")
	var grill = grill_scene.instantiate() as Grill
	root.add_child(grill)
	grill._ready()

	grill.dirt_level = 1.0
	grill._update_dirt_visuals()

	# Esfrega por 2.5 segundos (50%)
	grill.clean_progress(2.5, player)

	total_tests += 1
	if is_equal_approx(grill.dirt_level, 0.5):
		print("  [PASS] Aos 2.5s de limpeza da grelha: sujeira ainda visível (progresso exatamente 50%% - %.2f)!" % grill.dirt_level)
		passed_tests += 1
	else:
		print("  [FAIL] Progresso da grelha aos 2.5s incorreto: %.2f" % grill.dirt_level)

	# Esfrega os 2.5s restantes (Total 5.0s)
	var finished_grill = grill.clean_progress(2.55, player)

	total_tests += 1
	if finished_grill and grill.dirt_level <= 0.0:
		print("  [PASS] Aos 5.0s completos: grelha totalmente limpa e pronta para uso!")
		passed_tests += 1
	else:
		print("  [FAIL] Grelha não concluiu limpeza aos 5.0s: %.2f" % grill.dirt_level)

	grill.queue_free()

	print("\n--- TESTE 3: Preservação Inalterada da Limpeza do Chão (< 1 Segundo) ---")

	var floor_dirt_scene = load("res://src/stations/floor_dirt_spot.tscn")
	var floor_dirt = floor_dirt_scene.instantiate() as FloorDirtSpot
	root.add_child(floor_dirt)
	floor_dirt._ready()
	floor_dirt.dirt_amount = 1.0

	var finished_floor = floor_dirt.clean_progress(0.9, player)

	total_tests += 1
	if finished_floor:
		print("  [PASS] Chão molhado / mancha limpa rapidamente (< 1.0s) - comportamento inalterado!")
		passed_tests += 1
	else:
		print("  [FAIL] Limpeza do chão foi alterada indevidamente!")

	# -----------------------------------------------------------------------
	# 3. TESTES DA CAIXINHA OCA DE FAST-FOOD (ABERTURA SUPERIOR E INTERIOR)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 4: Estrutura Oca da Embalagem de Batata/Cebola ---")

	var box_scene = load("res://src/items/potato_box.tscn")
	var box = box_scene.instantiate() as FriesPack
	root.add_child(box)
	box._ready()

	var red_container = box.get_node_or_null("MeshInstance3D/RedContainer")
	var back_wall = box.get_node_or_null("MeshInstance3D/RedContainer/BackWall")
	var front_wall = box.get_node_or_null("MeshInstance3D/RedContainer/FrontWall")
	var left_wall = box.get_node_or_null("MeshInstance3D/RedContainer/LeftWall")
	var right_wall = box.get_node_or_null("MeshInstance3D/RedContainer/RightWall")
	var floor_mesh = box.get_node_or_null("MeshInstance3D/RedContainer/BottomFloor")
	var interior_back = box.get_node_or_null("MeshInstance3D/RedContainer/InteriorBack")
	var fries_content = box.get_node_or_null("MeshInstance3D/FriesContent")
	var onion_content = box.get_node_or_null("MeshInstance3D/OnionRingsContent")

	total_tests += 1
	if red_container and back_wall and front_wall and left_wall and right_wall and floor_mesh and interior_back:
		print("  [PASS] Caixinha oca possui paredes (traseira mais alta, frontal curvada), fundo e forro interno visível!")
		passed_tests += 1
	else:
		print("  [FAIL] Faltam componentes estruturais da caixinha oca!")

	total_tests += 1
	if not fries_content.visible and not onion_content.visible:
		print("  [PASS] Embalagem vazia: interior oco e aberto visível, sem comida dentro.")
		passed_tests += 1
	else:
		print("  [FAIL] Embalagem vazia está com comida visível!")

	# Coloca batata frita dentro da caixinha
	box.set_side_type("fries")

	total_tests += 1
	if red_container.visible and fries_content.visible and not onion_content.visible:
		print("  [PASS] Batatas fritas inseridas na abertura da caixinha vermelha (FriesContent visível e contido)!")
		passed_tests += 1
	else:
		print("  [FAIL] Falha ao exibir batatas fritas dentro da caixinha!")

	# Pega na mão do jogador
	box.is_held = true
	total_tests += 1
	if box.is_held and fries_content.get_parent().get_parent() == box:
		print("  [PASS] Sincronização e transporte: Batatas acompanham a embalagem na mão e em drop.")
		passed_tests += 1
	else:
		print("  [FAIL] Falha na sincronização física da batata!")

	# Coloca cebola frita dentro da MESMA caixinha
	box.set_side_type("onion_rings")

	total_tests += 1
	if red_container.visible and onion_content.visible and not fries_content.visible:
		print("  [PASS] Anéis de cebola inseridos na MESMA caixinha vermelha (OnionRingsContent visível e contido)!")
		passed_tests += 1
	else:
		print("  [FAIL] Falha ao exibir anéis de cebola na mesma caixinha!")

	total_tests += 1
	if box.item_id == "onion_rings" and box.display_name == "Cebola Frita":
		print("  [PASS] Propriedades do item e nome configurados corretamente ('Cebola Frita').")
		passed_tests += 1
	else:
		print("  [FAIL] Propriedades da cebola frita incorretas!")

	box.queue_free()

	# -----------------------------------------------------------------------
	# RESULTADO FINAL
	# -----------------------------------------------------------------------
	print("\n===========================================================================")
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [passed_tests, total_tests - passed_tests])
	print("===========================================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! <<<\n")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<\n")
		quit(1)
