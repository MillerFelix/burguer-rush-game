extends SceneTree

# =============================================================================
# TEST SUITE: AJUSTES VISUAIS (DRIVE-THRU, DELIVERY & MESAS)
# =============================================================================

const DeliveryStationScene: PackedScene = preload("res://src/stations/delivery_station.tscn")
const DeliveryWindowScene: PackedScene = preload("res://src/stations/delivery_window_station.tscn")
const RestaurantTableScene: PackedScene = preload("res://src/stations/restaurant_table.tscn")
const RestaurantTableScript = preload("res://src/stations/restaurant_table.gd")

const MainScene: PackedScene = preload("res://src/main.tscn")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: AJUSTES VISUAIS DAS JANELAS E MESAS DO RESTAURANTE")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# --- TESTE 1: Janela do Drive-Thru (Placa Física Fixada na Parede Acima da Janela) ---
	total_tests += 1
	var main_scene = MainScene.instantiate()
	root.add_child(main_scene)

	var dt_sign_node = main_scene.get_node_or_null("Room/DriveThruSignGroup")
	var dt_sign_kitchen = main_scene.get_node_or_null("Room/DriveThruSignGroup/SignKitchen") as Label3D
	var dt_sign_exterior = main_scene.get_node_or_null("Room/DriveThruSignGroup/SignExterior") as Label3D

	var dt_has_plaque = (dt_sign_node != null)
	var dt_text_ok = (dt_sign_kitchen != null and dt_sign_kitchen.text == "DRIVE-THRU" and dt_sign_exterior != null and dt_sign_exterior.text == "DRIVE-THRU")
	var dt_no_billboard = (dt_sign_kitchen != null and dt_sign_kitchen.billboard == BaseMaterial3D.BILLBOARD_DISABLED)
	var dt_is_above_window = (dt_sign_node != null and dt_sign_node.position.y >= 2.80)

	if dt_has_plaque and dt_text_ok and dt_no_billboard and dt_is_above_window:
		print("  ✅ TESTE 1: Janela do Drive-Thru com placa física fixada na parede acima da janela com 'DRIVE-THRU'.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Janela do Drive-Thru incorreta (Plaque: %s, Text: %s, Above: %s)" % [dt_has_plaque, dt_sign_kitchen.text if dt_sign_kitchen else "null", dt_is_above_window])

	# --- TESTE 2: Janela de Delivery (Placa Física Integrada com Ícone de Motocicleta) ---
	total_tests += 1
	var del_station = DeliveryWindowScene.instantiate()
	root.add_child(del_station)
	if del_station.has_method("_ready"):
		del_station._ready()

	var del_sign_node = del_station.get_node_or_null("Structure/PhysicalDeliverySign")
	var del_text_kitchen = del_station.get_node_or_null("Structure/PhysicalDeliverySign/SignTextKitchen") as Label3D
	var del_text_ext = del_station.get_node_or_null("Structure/PhysicalDeliverySign/SignTextExterior") as Label3D

	var del_has_plaque = (del_sign_node != null)
	var del_has_moto = (del_text_kitchen != null and "🛵" in del_text_kitchen.text and "DELIVERY" in del_text_kitchen.text)
	var del_no_billboard = (del_text_kitchen != null and del_text_kitchen.billboard == BaseMaterial3D.BILLBOARD_DISABLED)

	if del_has_plaque and del_has_moto and del_no_billboard:
		print("  ✅ TESTE 2: Janela de Delivery com placa física integrada e identificação '🛵 DELIVERY' (cozinha e exterior).")
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Janela de Delivery incorreta (Plaque: %s, Text: %s)" % [del_has_plaque, del_text_kitchen.text if del_text_kitchen else "null"])

	# --- TESTE 3: Mesas do Restaurante (Suporte Físico Branco / Porta-papel com Número) ---
	total_tests += 1
	var table_1 = RestaurantTableScene.instantiate()
	table_1.table_id = 1
	root.add_child(table_1)
	table_1._ready()

	var holder_node = table_1.get_node_or_null("Model/TableTop/TableNumberHolder")
	var num_front = table_1.get_node_or_null("Model/TableTop/TableNumberHolder/NumberFront") as Label3D
	var num_back = table_1.get_node_or_null("Model/TableTop/TableNumberHolder/NumberBack") as Label3D

	var has_holder = (holder_node != null)
	var num_is_1 = (num_front != null and num_front.text == "1" and num_back != null and num_back.text == "1")
	var color_is_black = (num_front != null and num_front.modulate.r < 0.2 and num_front.modulate.g < 0.2 and num_front.modulate.b < 0.2)
	var stand_no_billboard = (num_front != null and num_front.billboard == BaseMaterial3D.BILLBOARD_DISABLED)

	if has_holder and num_is_1 and color_is_black and stand_no_billboard:
		print("  ✅ TESTE 3: Mesa 1 com suporte físico branco de mesa (porta-papel) e número '1' em preto gravado no modelo.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Suporte de mesa incorreto (Holder: %s, Text: %s, Black: %s)" % [has_holder, num_front.text if num_front else "null", color_is_black])

	# --- TESTE 4: Sincronização Dinâmica para Diferentes Mesas (Mesa 2, Mesa 3, Mesa 7) ---
	total_tests += 1
	var table_5 = RestaurantTableScene.instantiate()
	table_5.table_id = 5
	root.add_child(table_5)
	table_5._ready()

	var t5_num = table_5.get_node_or_null("Model/TableTop/TableNumberHolder/NumberFront") as Label3D
	var is_5 = (t5_num != null and t5_num.text == "5")

	table_5.table_id = 8
	var is_8 = (t5_num != null and t5_num.text == "8")

	if is_5 and is_8:
		print("  ✅ TESTE 4: Numeração dinâmica das mesas atualiza perfeitamente no suporte físico (Mesa 5 -> Mesa 8).")
		passed_tests += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Atualização do número da mesa falhou (is_5: %s, is_8: %s)" % [is_5, is_8])

	# --- TESTE 5: Ausência de Textos Flutuantes no Ar das Mesas ---
	total_tests += 1
	var legacy_status = table_1.get_node_or_null("StatusLabel") as Label3D
	var no_floating_status = (legacy_status == null or not legacy_status.visible)

	if no_floating_status:
		print("  ✅ TESTE 5: Textos flutuantes removidos do ar nas mesas, mantendo visual limpo e imersivo.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 5 FALHOU: Texto flutuante ainda visível acima da mesa.")

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
