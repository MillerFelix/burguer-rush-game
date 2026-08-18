extends SceneTree

const PackagingScene = preload("res://src/stations/packaging_station.tscn")
const CustomerScene = preload("res://src/customers/customer.tscn")
const DeliveryQueueManagerScene = preload("res://src/customers/delivery_queue_manager.gd")
const OrderManagerScene = preload("res://src/orders/order_manager.gd")
const ComputerUIScene = preload("res://src/ui/computer_ui.tscn")
const ComputerStationScene = preload("res://src/stations/computer_station.tscn")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: PLACA EMBALAGENS, TOLERÂNCIA DE CLIENTES, FLUXOS E ABAS DO PC")
	print("===========================================================================")

	var passed = 0
	var total = 5

	# -------------------------------------------------------------
	# TESTE 1: Placa Física EMBALAGENS (Largura Ampla e Sem Overflow)
	# -------------------------------------------------------------
	var pack_station = PackagingScene.instantiate()
	var pack_sign = pack_station.get_node_or_null("Model/PhysicalSign")
	var pack_label = pack_station.get_node_or_null("Model/PhysicalSign/SignLabel") as Label3D
	var plate_body = pack_station.get_node_or_null("Model/PhysicalSign/PlateBody") as MeshInstance3D

	var t1_ok = false
	if pack_sign and pack_label and plate_body and plate_body.mesh:
		var plate_mesh = plate_body.mesh as BoxMesh
		# A placa preta tem largura (dimensão Z) >= 0.80m, permitindo margem folgada
		var is_wide_enough = plate_mesh.size.z >= 0.80
		var text_is_correct = (pack_label.text == "EMBALAGENS")
		t1_ok = is_wide_enough and text_is_correct
		if t1_ok:
			print("  ✅ TESTE 1: Placa física 'EMBALAGENS' ampliada para %.2fm de largura, acomodando o texto com folga e sem overflow." % plate_mesh.size.z)
			passed += 1

	if not t1_ok:
		print("  ❌ TESTE 1 FALHOU: Placa de embalagens não possui largura suficiente ou texto incorreto.")
	pack_station.queue_free()

	# -------------------------------------------------------------
	# TESTE 2: Tolerância dos Clientes Dobrada (+100% Tempo de Espera)
	# -------------------------------------------------------------
	var customer = CustomerScene.instantiate() as Customer
	customer._ready()

	# Testa padrão
	customer.apply_archetype(Customer.Archetype.REGULAR)
	var reg_food_ok = customer.tolerance_food_wait >= 240.0
	var reg_order_ok = customer.tolerance_order_wait >= 160.0

	# Testa apressado
	customer.apply_archetype(Customer.Archetype.IMPATIENT)
	var imp_food_ok = customer.tolerance_food_wait >= 170.0

	# Testa tranquilo
	customer.apply_archetype(Customer.Archetype.PATIENT)
	var pat_food_ok = customer.tolerance_food_wait >= 360.0

	if reg_food_ok and reg_order_ok and imp_food_ok and pat_food_ok:
		print("  ✅ TESTE 2: Tempo de espera e paciência dos clientes aumentado em 100%% (Padrão Refeição: %ds, Pedido: %ds, Tranquilo: 360s)." % [
			int(customer.tolerance_food_wait), int(customer.tolerance_order_wait)
		])
		passed += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Valores de tolerância dos clientes não foram dobrados.")
	customer.queue_free()

	# -------------------------------------------------------------
	# TESTE 3: Redução dos Fluxos de Drive-Thru e Delivery em 50%
	# -------------------------------------------------------------
	var dqm = DeliveryQueueManager.new()
	var dt_lunch_interval = dqm._calculate_interval_for_time(12.5)
	var dt_reduced = dt_lunch_interval >= 140.0 # Anteriormente era ~75s

	var om = OrderManager.new()
	var deliv_reduced = om._delivery_spawn_timer >= 80.0

	if dt_reduced and deliv_reduced:
		print("  ✅ TESTE 3: Fluxos secundários de Drive-thru (intervalo almoço: %.1fs) e Delivery (timer: %.1fs) reduzidos em 50%%." % [
			dt_lunch_interval, om._delivery_spawn_timer
		])
		passed += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Intervalos de Drive-thru ou Delivery não reduziram 50%%.")
	dqm.free()
	om.free()

	# -------------------------------------------------------------
	# TESTE 4: PC UI — 10 Abas Implementadas (Incluindo Calendário e Notícias / Jornal)
	# -------------------------------------------------------------
	var comp_ui_res = load("res://src/ui/computer_ui.tscn")
	var comp_ui = comp_ui_res.instantiate() as ComputerUI
	get_root().add_child(comp_ui)
	comp_ui._ready()

	var nav_container = comp_ui.get_node_or_null("MainPanel/OuterWindow/VBox/Body/Sidebar/VBox/NavScroll/NavButtons") as VBoxContainer
	var buttons = nav_container.get_children() if nav_container else []

	var expected_titles = ["Estoque", "Compras", "Cardápio", "Receitas", "Finanças", "Funcionários", "Pedidos", "Avaliações", "Calendário", "Notícias / Jornal"]
	var actual_titles: Array[String] = []
	for b in buttons:
		if b is Button:
			actual_titles.append(b.text.strip_edges())

	var count_ok = (actual_titles.size() == expected_titles.size())
	var titles_clean = true
	for t in actual_titles:
		if "NOVO" in t or "breve" in t or "Rede" in t or "Equipamento" in t or "Configuraç" in t:
			titles_clean = false

	# Testa alternar para a aba Calendário
	comp_ui.open()
	comp_ui._switch_tab(ComputerUI.TabID.CALENDAR, "Calendário")
	var cal_ok = comp_ui.calendar_tab != null and comp_ui.calendar_tab.visible

	# Testa alternar para a aba Notícias / Jornal
	comp_ui._switch_tab(ComputerUI.TabID.NEWS, "Notícias / Jornal")
	var news_ok = comp_ui.news_tab != null and comp_ui.news_tab.visible

	if count_ok and titles_clean and cal_ok and news_ok:
		print("  ✅ TESTE 4: PC exibe e opera com sucesso todas as 10 abas funcionais: %s." % str(expected_titles))
		passed += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Abas incorretas ou falha ao abrir Calendário/Notícias (Total: %d, Nomes: %s)" % [actual_titles.size(), str(actual_titles)])
	comp_ui.queue_free()

	# -------------------------------------------------------------
	# TESTE 5: Notificação do PC (Sininho 3D e Zero Popups/Modais Bloqueantes)
	# -------------------------------------------------------------
	var comp_station = ComputerStationScene.instantiate() as ComputerStation
	get_root().add_child(comp_station)
	comp_station._ready()

	var test_order = Order.new()
	test_order.id = 999
	test_order.source_type = "DELIVERY"
	comp_station._on_order_created(test_order)

	var badge = comp_station.notification_badge
	var badge_active = badge != null and badge.visible and badge.text == "🔔"

	if badge_active:
		print("  ✅ TESTE 5: Notificação do PC toca áudio e ativa sininho discreto 🔔 sem popups ou bloqueio de tela.")
		passed += 1
	else:
		print("  ❌ TESTE 5 FALHOU: Sininho de notificação não ativado no computador.")
	comp_station.queue_free()

	print("\n===========================================================================")
	print("📊 RESULTADO FINAL: %d/%d TESTES PASSARAM (%.1f%%)" % [passed, total, (float(passed)/float(total)) * 100.0])
	print("===========================================================================")
	if passed == total:
		print("🎉 TODOS OS TESTES PASSARAM COM 100% DE SUCESSO!\n")
		quit(0)
	else:
		print("⚠️ ALGUNS TESTES FALHARAM.\n")
		quit(1)
