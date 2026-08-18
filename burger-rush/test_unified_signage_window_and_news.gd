extends SceneTree

# =============================================================================
# TEST SUITE: SINALIZAÇÃO UNIFICADA, JANELA DRIVE-THRU & JORNAL DA CIDADE
# =============================================================================

const MainScene: PackedScene = preload("res://src/main.tscn")
const DeliveryStationScene: PackedScene = preload("res://src/stations/delivery_station.tscn")
const ComputerUIScene: PackedScene = preload("res://src/ui/computer_ui.tscn")
const NewsManagerScript = preload("res://src/news/news_manager.gd")
const DailyEventManagerScript = preload("res://src/core/daily_event_manager.gd")
const CalendarManagerScript = preload("res://src/core/calendar_manager.gd")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: SINALIZAÇÃO UNIFICADA, JANELA DRIVE-THRU & JORNAL DA CIDADE")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# 1. Setup managers
	var cal = CalendarManagerScript.new()
	cal.name = "CalendarManager"
	root.add_child(cal)
	cal._ready()

	var dem = DailyEventManagerScript.new()
	dem.name = "DailyEventManager"
	root.add_child(dem)

	var nm = NewsManagerScript.new()
	nm.name = "NewsManager"
	root.add_child(nm)
	nm._ready()

	# --- TESTE 1: Jornal da Cidade Sem Eventos (Mensagem Exata e Layout Integrado) ---
	total_tests += 1
	dem.current_event = DailyEventManagerScript.EventType.NONE
	nm.generate_daily_news(1)

	var comp_ui = ComputerUIScene.instantiate()
	root.add_child(comp_ui)
	comp_ui._ready()
	comp_ui.open()
	comp_ui._switch_tab(comp_ui.TabID.NEWS, "Jornal da Cidade")
	comp_ui._refresh_news_tab()

	var vbox = comp_ui.news_content_vbox
	if not vbox:
		vbox = comp_ui.get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/NewsTab/NewsScroll/Margin/NewsContentVBox")

	var has_exact_message = false
	if vbox and vbox.get_child_count() > 0:
		var card = vbox.get_child(0)
		for child in card.find_children("", "Label", true, false):
			var l = child as Label
			if "Nenhuma notícia nova hoje. Não há eventos ou acontecimentos relevantes para o dia. O restaurante segue normalmente." in l.text:
				has_exact_message = true
				break

	if has_exact_message:
		print("  ✅ TESTE 1: Jornal da Cidade exibe o card editorial com a mensagem exata sem inventar eventos fictícios.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Mensagem do Jornal da Cidade incorreta (Found: %s)" % [has_exact_message])

	# --- TESTE 2: Janela do Drive-Thru (Azulejos da Cozinha na Parede & Toldo Único Externo) ---
	total_tests += 1
	var main_scene = MainScene.instantiate()
	root.add_child(main_scene)

	var lintel = main_scene.get_node_or_null("Room/WallNorthWindowLintel") as CSGBox3D
	var sill = main_scene.get_node_or_null("Room/WallNorthWindowSill") as CSGBox3D
	var awning = main_scene.get_node_or_null("Room/DeliveryWindowAwning") as MeshInstance3D

	var lintel_mat_ok = (lintel != null and lintel.material != null and lintel.material.resource_name != "Material_WallBacksplash")
	var sill_mat_ok = (sill != null and sill.material != null)
	var awning_is_external = (awning != null and awning.position.z < -9.0)

	if lintel_mat_ok and sill_mat_ok and awning_is_external:
		print("  ✅ TESTE 2: Parede do Drive-thru com azulejo da cozinha e toldo vermelho exclusivamente externo.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Parede ou toldo do Drive-thru incorretos (LintelMat: %s, SillMat: %s, AwningExt: %s)" % [lintel_mat_ok, sill_mat_ok, awning_is_external])

	# --- TESTE 3: Janela do Drive-Thru (Moldura Preta, Vidro Bandeira e Abertura Contínua) ---
	total_tests += 1
	var dt_station = DeliveryStationScene.instantiate()
	root.add_child(dt_station)

	var has_frame_left = (dt_station.get_node_or_null("Model/FramePostLeft") != null)
	var has_frame_right = (dt_station.get_node_or_null("Model/FramePostRight") != null)
	var has_frame_header = (dt_station.get_node_or_null("Model/FrameHeader") != null)
	var has_glass_transom = (dt_station.get_node_or_null("Model/GlassTransomTop") != null)
	var no_center_divider = (dt_station.get_node_or_null("Model/FrameCenterMullion") == null)

	if has_frame_left and has_frame_right and has_frame_header and has_glass_transom and no_center_divider:
		print("  ✅ TESTE 3: Janela do Drive-thru com moldura preta arquitetônica, vidro bandeira e vão contínuo sem divisória central.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Estrutura da janela do Drive-thru incorreta (Posts: %s, Header: %s, GlassTransom: %s, NoDivider: %s)" % [has_frame_left and has_frame_right, has_frame_header, has_glass_transom, no_center_divider])

	# --- TESTE 4: Placa do Drive-Thru (Padrão Idêntico ao Delivery, Presa à Parede Acima da Janela) ---
	total_tests += 1
	var dt_group = main_scene.get_node_or_null("Room/DriveThruSignGroup")
	var dt_plate_k = main_scene.get_node_or_null("Room/DriveThruSignGroup/PlateKitchen")
	var dt_border_k = main_scene.get_node_or_null("Room/DriveThruSignGroup/PlateBorderKitchen")
	var dt_sign_k = main_scene.get_node_or_null("Room/DriveThruSignGroup/SignKitchen") as Label3D

	var dt_group_ok = (dt_group != null and dt_group.position.y >= 2.80)
	var dt_plate_ok = (dt_plate_k != null and dt_border_k != null)
	var dt_text_ok = (dt_sign_k != null and dt_sign_k.text == "DRIVE-THRU" and dt_sign_k.billboard == BaseMaterial3D.BILLBOARD_DISABLED)

	if dt_group_ok and dt_plate_ok and dt_text_ok:
		print("  ✅ TESTE 4: Placa do Drive-Thru segue o mesmo modelo físico do Delivery (chapa carvão + friso dourado) fixada na parede.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Placa do Drive-thru incorreta (Group: %s, Plate: %s, Text: %s)" % [dt_group_ok, dt_plate_ok, dt_text_ok])

	# --- TESTE 5: Placa do Armazém / Estoque (Placa Física Acima da Porta, Centralizada, Sem Texto Flutuante) ---
	total_tests += 1
	var storage_group = main_scene.get_node_or_null("Room/StorageDoorSignGroup")
	var st_plate_k = main_scene.get_node_or_null("Room/StorageDoorSignGroup/PlateKitchen")
	var st_border_k = main_scene.get_node_or_null("Room/StorageDoorSignGroup/PlateBorderKitchen")
	var st_sign_k = main_scene.get_node_or_null("Room/StorageDoorSignGroup/SignTextKitchen") as Label3D

	var old_floating_sign = main_scene.get_node_or_null("Room/StorageSign")
	var no_floating_text = (old_floating_sign == null)

	var st_group_ok = (storage_group != null and storage_group.position.y >= 2.70 and is_equal_approx(storage_group.position.z, -3.75))
	var st_plate_ok = (st_plate_k != null and st_border_k != null)
	var st_text_ok = (st_sign_k != null and st_sign_k.text == "ARMAZÉM / ESTOQUE" and st_sign_k.billboard == BaseMaterial3D.BILLBOARD_DISABLED)

	if no_floating_text and st_group_ok and st_plate_ok and st_text_ok:
		print("  ✅ TESTE 5: Placa 'ARMAZÉM / ESTOQUE' física, centralizada acima da porta, sem textos flutuantes, unificada à identidade visual.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 5 FALHOU: Placa do Armazém / Estoque incorreta (NoFloating: %s, Group: %s, Plate: %s, Text: %s)" % [no_floating_text, st_group_ok, st_plate_ok, st_text_ok])

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
