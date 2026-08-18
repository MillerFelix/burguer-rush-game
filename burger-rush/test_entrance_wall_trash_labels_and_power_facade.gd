extends SceneTree

# =============================================================================
# TEST SUITE: PAREDE ENTRADA, LIXEIRAS SEM TEXTO FLUTUANTE & FACHADA QUADRO ENERGIA
# =============================================================================

const MainScene: PackedScene = preload("res://src/main.tscn")
const DiningWasteStationScene: PackedScene = preload("res://src/environment/dining_waste_station.tscn")
const IndustrialDumpsterScene: PackedScene = preload("res://src/stations/industrial_dumpster.tscn")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: ENTRADA VERMELHO-CLARO, LIXEIRAS LIMPAS & FACHADA QUADRO ENERGIA")
	print("===========================================================================")

	var total_tests = 0
	var passed_tests = 0

	var main_scene = MainScene.instantiate()
	root.add_child(main_scene)

	# --- TESTE 1: Parede Interna da Entrada em Vermelho Claro Texturizado ---
	total_tests += 1
	var wall_left = main_scene.get_node_or_null("Room/EntranceInteriorWallLeft") as CSGBox3D
	var wall_right = main_scene.get_node_or_null("Room/EntranceInteriorWallRight") as CSGBox3D
	var wall_lintel = main_scene.get_node_or_null("Room/EntranceInteriorWallLintel") as CSGBox3D
	var ac_unit = main_scene.get_node_or_null("AirConditioner")

	var is_reddish = (wall_left != null and wall_left.material != null and wall_left.material.albedo_color.r > 0.75 and wall_left.material.albedo_color.g < 0.50 and wall_left.material.albedo_color.b < 0.50)
	var has_ac = (ac_unit != null)
	var all_panels_ok = (wall_left != null and wall_right != null and wall_lintel != null)

	if is_reddish and has_ac and all_panels_ok:
		print("  ✅ TESTE 1: Parede interna da entrada alterada para vermelho-claro texturizado, preservando porta e ar-condicionado.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Parede interna da entrada incorreta (IsReddish: %s, HasAC: %s, Panels: %s)" % [is_reddish, has_ac, all_panels_ok])

	# --- TESTE 2: Lixeiras Internas (Sem Texto Flutuante e com Inscrições Físicas) ---
	total_tests += 1
	var waste_station = DiningWasteStationScene.instantiate()
	root.add_child(waste_station)

	var has_floating_label = (waste_station.get_node_or_null("StatusLabel") != null)
	var label_org = waste_station.get_node_or_null("Model/LabelOrganic") as Label3D
	var label_rec = waste_station.get_node_or_null("Model/LabelRecycle") as Label3D
	var label_rej = waste_station.get_node_or_null("Model/LabelGeneral") as Label3D

	var labels_exist = (label_org != null and label_rec != null and label_rej != null)
	var texts_correct = (labels_exist and label_org.text == "ORGÂNICO" and label_rec.text == "RECICLÁVEL" and label_rej.text == "REJEITOS")
	var no_billboard = (labels_exist and label_org.billboard == BaseMaterial3D.BILLBOARD_DISABLED and label_rec.billboard == BaseMaterial3D.BILLBOARD_DISABLED and label_rej.billboard == BaseMaterial3D.BILLBOARD_DISABLED)

	if not has_floating_label and texts_correct and no_billboard:
		print("  ✅ TESTE 2: Lixeira interna de 3 compartimentos sem texto flutuante, com inscrições físicas integradas (ORGÂNICO, RECICLÁVEL, REJEITOS).")
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Lixeira interna incorreta (HasFloating: %s, TextsCorrect: %s, NoBillboard: %s)" % [has_floating_label, texts_correct, no_billboard])

	# --- TESTE 3: Lixeira Industrial Externa (Sem Texto Flutuante e Inscrição LIXEIRA) ---
	total_tests += 1
	var dumpster = IndustrialDumpsterScene.instantiate()
	root.add_child(dumpster)

	var d_has_floating = (dumpster.get_node_or_null("StatusLabel") != null)
	var d_plate_text = dumpster.get_node_or_null("Model/DumpsterPlateText") as Label3D

	var d_text_ok = (d_plate_text != null and d_plate_text.text == "LIXEIRA" and d_plate_text.billboard == BaseMaterial3D.BILLBOARD_DISABLED)

	if not d_has_floating and d_text_ok:
		print("  ✅ TESTE 3: Lixeira industrial externa sem texto flutuante, com inscrição física 'LIXEIRA' integrada ao contêiner.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Lixeira industrial incorreta (HasFloating: %s, TextOk: %s)" % [d_has_floating, d_text_ok])

	# --- TESTE 4: Parede Externa do Armazém e Quadro de Energia (Amarelo + Beirais Vermelhos) ---
	total_tests += 1
	var west_skin = main_scene.get_node_or_null("Room/WallWestStorageExteriorSkin") as CSGBox3D
	var west_eaves = main_scene.get_node_or_null("Room/RoofFasciaDockWest") as MeshInstance3D
	var power_panel = main_scene.get_node_or_null("MainPowerPanel")

	var west_is_yellow = (west_skin != null and west_skin.material != null and west_skin.material.albedo_color.r > 0.85 and west_skin.material.albedo_color.g > 0.70)
	var west_has_red_eaves = (west_eaves != null and west_eaves.mesh != null and west_eaves.mesh.material != null and west_eaves.mesh.material.albedo_color.r > 0.70)
	var power_panel_ok = (power_panel != null)

	if west_is_yellow and west_has_red_eaves and power_panel_ok:
		print("  ✅ TESTE 4: Parede externa do armazém onde fica o quadro de energia padronizada em amarelo com beiral vermelho.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Parede externa do armazém incorreta (Yellow: %s, RedEaves: %s, PowerPanel: %s)" % [west_is_yellow, west_has_red_eaves, power_panel_ok])

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
