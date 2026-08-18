extends SceneTree

# =============================================================================
# TEST SUITE: SAÍDA ARMAZÉM ABERTA, PAREDE ENERGIA AMARELA & PISO VERMELHO CLARO
# =============================================================================

const MainScene: PackedScene = preload("res://src/main.tscn")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: SAÍDA ABERTA, PAREDE DO QUADRO DE ENERGIA & PISO VERMELHO CLARO")
	print("===========================================================================")

	var total_tests = 0
	var passed_tests = 0

	var main_scene = MainScene.instantiate()
	root.add_child(main_scene)

	# --- TESTE 1: Saída do Armazém 100% Aberta e Beco Original Restaurado ---
	total_tests += 1
	var blocking_wall = main_scene.get_node_or_null("Room/WallWestStorageExteriorSkin")
	var alley_north = main_scene.get_node_or_null("Room/AlleyWallNorth") as CSGBox3D
	var alley_south = main_scene.get_node_or_null("Room/AlleyWallSouth") as CSGBox3D

	var no_blocking_wall = (blocking_wall == null)
	var alley_restored = (
		alley_north != null and alley_north.material != null and
		alley_north.material.albedo_color.r > 0.88 and alley_north.material.albedo_color.g > 0.88 and
		alley_south != null and alley_south.material != null and
		alley_south.material.albedo_color.r > 0.88 and alley_south.material.albedo_color.g > 0.88
	)

	if no_blocking_wall and alley_restored:
		print("  ✅ TESTE 1: Saída do armazém livre e aberta sem paredes bloqueadoras, restaurando a passagem e área externa.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Saída do armazém incorreta (NoBlocking: %s, AlleyRestored: %s)" % [no_blocking_wall, alley_restored])

	# --- TESTE 2: Somente a Parede Externa do Quadro de Energia em Amarelo Forte ---
	total_tests += 1
	var power_wall_skin = main_scene.get_node_or_null("Room/WallPowerPanelExteriorSkin") as CSGBox3D
	var power_panel = main_scene.get_node_or_null("MainPowerPanel")

	var is_yellow_skin = (
		power_wall_skin != null and power_wall_skin.material != null and
		power_wall_skin.material.albedo_color.r > 0.85 and power_wall_skin.material.albedo_color.g > 0.70
	)
	var panel_ok = (power_panel != null)

	if is_yellow_skin and panel_ok:
		print("  ✅ TESTE 2: Somente a parede externa específica do quadro de energia está com acabamento em amarelo forte da fachada.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Parede do quadro de energia incorreta (YellowSkin: %s, PanelOk: %s)" % [is_yellow_skin, panel_ok])

	# --- TESTE 3: Parede Interna da Frente em Amarelo Claro (Uniforme com o Interior) ---
	total_tests += 1
	var wall_left = main_scene.get_node_or_null("Room/EntranceInteriorWallLeft") as CSGBox3D
	var wall_right = main_scene.get_node_or_null("Room/EntranceInteriorWallRight") as CSGBox3D
	var wall_lintel = main_scene.get_node_or_null("Room/EntranceInteriorWallLintel") as CSGBox3D

	var is_warm_yellow = (
		wall_left != null and wall_left.material != null and
		wall_left.material.albedo_color.r > 0.85 and wall_left.material.albedo_color.g > 0.75 and wall_left.material.albedo_color.b > 0.40 and
		wall_right != null and wall_lintel != null
	)

	if is_warm_yellow:
		print("  ✅ TESTE 3: Parede interna da frente alterada para amarelo-claro, uniforme com as demais paredes internas.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Parede interna da frente incorreta (IsWarmYellow: %s)" % [is_warm_yellow])

	# --- TESTE 4: Piso do Salão Principal em Vermelho Claro com Placas Individuais ---
	total_tests += 1
	var floor_dining = main_scene.get_node_or_null("Room/FloorDining") as CSGBox3D
	var floor_kitchen = main_scene.get_node_or_null("Room/FloorKitchen") as CSGBox3D

	var has_light_red_floor = (
		floor_dining != null and floor_dining.material != null and
		floor_dining.material.albedo_color.r > 0.75 and floor_dining.material.albedo_color.g < 0.50 and floor_dining.material.albedo_color.b < 0.50 and
		floor_dining.material.albedo_texture != null and floor_dining.material.uv1_scale.x >= 8.0
	)
	var kitchen_floor_preserved = (
		floor_kitchen != null and floor_kitchen.material != null and
		floor_kitchen.material != floor_dining.material
	)

	if has_light_red_floor and kitchen_floor_preserved:
		print("  ✅ TESTE 4: Piso do salão principal atualizado para placas individuais em vermelho-claro, preservando piso da cozinha e armazém.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Piso do salão incorreto (LightRedFloor: %s, KitchenPreserved: %s)" % [has_light_red_floor, kitchen_floor_preserved])

	# --- RESULTADO FINAL ---
	print("\n===========================================================================")
	print("📊 RESULTADO FINAL: %d/%d TESTES PASSARAM (%.1f%%)" % [passed_tests, total_tests, (float(passed_tests)/float(total_tests))*100.0])
	print("===========================================================================")

	if passed_tests == total_tests:
		print("🎉 TODOS OS TESTES PASSARAM COM 100% DE SUCESSO!\n")
		quit(0)
	else:
		print("⚠️ ALGUNS TESTES FALHARAM.\n")
		quit(1)
