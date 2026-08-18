extends SceneTree

# =============================================================================
# TEST SUITE: DELIVERY SYSTEM, ORDERS TAB & COURIER FLOW
# =============================================================================

const DeliveryWindowStationScript = preload("res://src/stations/delivery_window_station.gd")
const DeliveryMotorcycleCourierScript = preload("res://src/customers/delivery_motorcycle_courier.gd")
const ComputerUIScript = preload("res://src/ui/computer_ui.gd")

func _init() -> void:
	print("\n=======================================================")
	print("🧪 INICIANDO TESTES: SISTEMA DE DELIVERY, PEDIDOS & MOTOBOY")
	print("=======================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# 1. SETUP SINGLETONS & MANAGERS
	var om = OrderManager.new()
	om.name = "OrderManager"
	root.add_child(om)
	OrderManager.instance = om

	var econ = EconomyManager.new()
	econ.name = "EconomyManager"
	root.add_child(econ)
	EconomyManager.instance = econ
	econ.current_money = 500.0

	var fin = FinanceManager.new()
	fin.name = "FinanceManager"
	root.add_child(fin)
	FinanceManager.instance = fin

	var clock = GameClock.new()
	clock.name = "GameClock"
	root.add_child(clock)

	var comp_scene: PackedScene = load("res://src/ui/computer_ui.tscn")
	var comp_ui = comp_scene.instantiate()
	root.add_child(comp_ui)

	# --- TESTE 1: Criação de Pedido de Delivery no OrderManager ---
	total_tests += 1
	var delivery_order = om.create_delivery_order()
	if delivery_order != null and delivery_order.source_type == "DELIVERY" and delivery_order.delivery_stage == "NEW_RECEIVED" and delivery_order.is_accepted == false:
		print("  ✅ TESTE 1: Pedido de Delivery criado com estado NEW_RECEIVED e pendente de aceite.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Estado incorreto do pedido de delivery.")

	# --- TESTE 2: Formatação de Origem e Tempo de Espera ---
	total_tests += 1
	delivery_order.wait_time = 125.0 # 2m 05s
	if delivery_order.get_source_display_name() == "🛵 Delivery" and delivery_order.get_formatted_wait_time() == "02:05":
		print("  ✅ TESTE 2: Formatação de origem e tempo de espera corretos.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Formatação de tempo de espera ou display name incorreta.")

	# --- TESTE 3: Aceite do Pedido de Delivery no PC ---
	total_tests += 1
	var accept_ok = om.accept_delivery_order(delivery_order.id)
	if accept_ok and delivery_order.is_accepted and delivery_order.delivery_stage == "PREPARING" and delivery_order.state == Order.State.IN_PROGRESS:
		print("  ✅ TESTE 3: Pedido aceito com sucesso -> Avançou para PREPARING / IN_PROGRESS.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Falha ao aceitar pedido de delivery.")

	# --- TESTE 4: Validação de Saco de Delivery (Correto vs Vazio vs Incorreto) ---
	total_tests += 1
	var bag_script = load("res://src/items/delivery_bag.gd")
	var correct_bag = bag_script.new()
	for it in delivery_order.items:
		var p_id = it.get("product_id", "")
		var qty = it.get("quantity", 1)
		for _q in range(qty):
			var item_dict = {
				"id": p_id,
				"recipe_id": p_id,
				"display_name": it.get("product_name", p_id)
			}
			correct_bag.add_item_data(item_dict)

	var validation_result = delivery_order.matches_delivery_bag(correct_bag)
	if validation_result.get("matches", false) == true:
		print("  ✅ TESTE 4: Saco com itens perfeitos validado com sucesso!")
		passed_tests += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Validação do saco correto retornou falso: %s" % validation_result.get("reason"))

	# --- TESTE 5: Validação de Saco Incompleto / Vazio ---
	total_tests += 1
	var empty_bag = bag_script.new()
	var empty_val = delivery_order.matches_delivery_bag(empty_bag)
	if empty_val.get("matches", false) == false:
		print("  ✅ TESTE 5: Saco vazio rejeitado corretamente.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 5 FALHOU: Saco vazio aceito indevidamente.")

	# --- TESTE 6: Nova Janela de Delivery na Cozinha (Colocação do Saco) ---
	total_tests += 1
	var window_station_scene: PackedScene = load("res://src/stations/delivery_window_station.tscn")
	var window_station = window_station_scene.instantiate()
	root.add_child(window_station)

	window_station._place_bag_on_station(correct_bag)
	if window_station.placed_bag == correct_bag and delivery_order.delivery_stage == "WAITING_COURIER" and delivery_order.state == Order.State.READY and delivery_order.get_state_string() == "Aguardando Retirada":
		print("  ✅ TESTE 6: Saco posicionado na Janela de Delivery -> Status: Aguardando Retirada.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 6 FALHOU: Falha ao colocar saco na janela de delivery.")

	# --- TESTE 7: Motoboy Externo com Moto Coleta o Saco pela Janela ---
	total_tests += 1
	var courier_scene: PackedScene = load("res://src/customers/delivery_motorcycle_courier.tscn")
	var courier = courier_scene.instantiate()
	root.add_child(courier)
	courier.target_window_station = window_station

	courier._perform_pickup()
	if window_station.placed_bag == null and courier.held_bag == correct_bag and delivery_order.delivery_stage == "IN_DELIVERY":
		print("  ✅ TESTE 7: Motoboy com moto coletou o saco pela janela -> Pedido em EM ENTREGA.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 7 FALHOU: Motoboy não coletou a sacola pela janela corretamente.")

	# --- TESTE 8: Finalização de Entrega Correta & Receita Financeira ---
	total_tests += 1
	var initial_money = econ.get_money()
	var expected_order_price = delivery_order.total_price

	courier._finalize_delivery()
	var final_money = econ.get_money()
	var delivery_revenue = fin.daily_revenue.get("delivery", 0.0)

	if is_equal_approx(final_money, initial_money + expected_order_price) and is_equal_approx(delivery_revenue, expected_order_price):
		print("  ✅ TESTE 8: Entrega correta confirmada! Dinheiro +R$ %.2f, canal Delivery registrado." % expected_order_price)
		passed_tests += 1
	else:
		print("  ❌ TESTE 8 FALHOU: Pagamento ou receita no canal de delivery não conferem.")

	# --- TESTE 9: Histórico do Dia Registrado com Sucesso ---
	total_tests += 1
	var history = om.get_order_history()
	if not history.is_empty() and history[0].get("id") == delivery_order.id and history[0].get("is_paid") == true and history[0].get("status") == "Concluído — Pago":
		print("  ✅ TESTE 9: Histórico do dia gravou o pedido finalizado com status Concluído — Pago.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 9 FALHOU: Histórico do dia incorreto.")

	# --- TESTE 10: Fluxo Completo de Pedido Incorreto (Sacola Errada na Janela -> Motoboy Busca -> Recusado R$ 0,00) ---
	total_tests += 1
	var wrong_delivery_order = om.create_delivery_order()
	om.accept_delivery_order(wrong_delivery_order.id)

	var wrong_bag = bag_script.new()
	wrong_bag.add_item_data({"id": "wrong_burger_xxx", "display_name": "Item Desconhecido"})

	# Coloca a sacola errada fisicamente na janela
	window_station._place_bag_on_station(wrong_bag)

	var wrong_courier = courier_scene.instantiate()
	root.add_child(wrong_courier)
	wrong_courier.target_window_station = window_station

	# Motoboy coleta a sacola errada sem travar
	wrong_courier._perform_pickup()
	var courier_held_wrong = (wrong_courier.held_bag == wrong_bag)

	var initial_wrong_money = econ.get_money()
	wrong_courier._finalize_delivery()
	var final_wrong_money = econ.get_money()

	if courier_held_wrong and is_equal_approx(initial_wrong_money, final_wrong_money) and wrong_delivery_order.is_wrong_delivery == true and wrong_delivery_order.is_paid == false and wrong_delivery_order.payment_amount == 0.0:
		print("  ✅ TESTE 10: Sacola errada na janela -> Motoboy coletou e finalizou -> Recusado R$ 0,00 e registrado como PEDIDO INCORRETO.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 10 FALHOU: Tratamento de pedido incorreto na janela com falha.")

	# --- TESTE 11: Aba Pedidos & Delivery no PC (Filtros e Renderização) ---
	total_tests += 1
	comp_ui.open()
	comp_ui._switch_tab(ComputerUI.TabID.ORDERS, "Pedidos & Delivery")

	var ord_t = comp_ui.orders_tab
	var is_visible = ord_t and ord_t.visible
	if is_visible:
		print("  ✅ TESTE 11: Aba Pedidos & Delivery aberta e visível no PC.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 11 FALHOU: Aba Pedidos & Delivery não visível.")

	# --- TESTE 12: Filtros de Pedidos (Todos, Salão, Drive-Thru, Delivery) ---
	total_tests += 1
	comp_ui._set_orders_filter("DELIVERY")
	var filter_deliv_ok = (comp_ui.current_orders_filter == "DELIVERY")

	comp_ui._set_orders_filter("ALL")
	var filter_all_ok = (comp_ui.current_orders_filter == "ALL")

	if filter_deliv_ok and filter_all_ok:
		print("  ✅ TESTE 12: Filtros de pedidos operando com sucesso.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 12 FALHOU: Filtros de pedidos com erro.")

	# --- TESTE 13: Estatísticas de Delivery no Topo (KPIs) ---
	total_tests += 1
	var stats = om.get_delivery_summary_stats()
	if stats.has("new") and stats.has("preparing") and stats.has("waiting_courier") and stats.has("in_delivery") and stats.has("completed") and stats.has("wrong"):
		print("  ✅ TESTE 13: KPIs de Delivery calculados corretamente (Completos: %d, Incorretos: %d)." % [stats["completed"], stats["wrong"]])
		passed_tests += 1
	else:
		print("  ❌ TESTE 13 FALHOU: Estrutura de estatísticas de delivery incompleta.")

	# --- TESTE 14: Botão de Aceitar Pedido no PC ---
	total_tests += 1
	var new_order = om.create_delivery_order()
	comp_ui._refresh_orders_tab()
	comp_ui._on_accept_delivery_clicked(new_order.id, om)
	if new_order.is_accepted and new_order.delivery_stage == "PREPARING":
		print("  ✅ TESTE 14: Botão de aceite no PC atualizou o pedido com sucesso para PREPARING.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 14 FALHOU: Botão de aceite no PC não atualizou o pedido.")

	print("\n=======================================================")
	print("📊 RESULTADO FINAL: %d/%d TESTES PASSARAM (%.1f%%)" % [passed_tests, total_tests, (float(passed_tests)/float(total_tests))*100.0])
	print("=======================================================\n")

	if passed_tests == total_tests:
		print("🎉 TODOS OS TESTES PASSARAM COM SUCESSO!")
	else:
		print("⚠️ ALGUNS TESTES FALHARAM.")

	quit(0 if passed_tests == total_tests else 1)
