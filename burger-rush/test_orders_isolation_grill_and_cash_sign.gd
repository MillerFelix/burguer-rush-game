extends SceneTree

# =============================================================================
# TEST SUITE: ISOLAMENTO ESTRUTURAL DE PEDIDOS, CHAPA SUJA E PLACA DO CAIXA
# =============================================================================

const MainScene: PackedScene = preload("res://src/main.tscn")
const CashRegisterScene: PackedScene = preload("res://src/stations/cash_register.tscn")
const GrillScene: PackedScene = preload("res://src/stations/grill.tscn")
const PattyScene: PackedScene = preload("res://src/items/patty.tscn")
const PlayerScene: PackedScene = preload("res://src/player/player.tscn")
const Order = preload("res://src/orders/order.gd")
const OrderManager = preload("res://src/orders/order_manager.gd")
const DeliveryCarScene: PackedScene = preload("res://src/environment/delivery_car.tscn")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: ISOLAMENTO DE PEDIDOS, CHAPA SUJA & PLACA DO CAIXA")
	print("===========================================================================")

	var total_tests = 0
	var passed_tests = 0

	var main_scene = MainScene.instantiate()
	root.add_child(main_scene)

	var order_mgr = OrderManager.get_instance()
	if not order_mgr:
		order_mgr = main_scene.get_node_or_null("OrderManager")
	if not order_mgr:
		order_mgr = OrderManager.new()
		order_mgr.name = "OrderManager"
		main_scene.add_child(order_mgr)

	# --- TESTE 1: Caixa Registradora Sem Letras Flutuantes e Com Placa Física CAIXA ---
	total_tests += 1
	var cash_reg = main_scene.get_node_or_null("CashRegister")
	if not cash_reg:
		cash_reg = CashRegisterScene.instantiate()
		main_scene.add_child(cash_reg)

	var has_floating_label = (cash_reg.get_node_or_null("StatusLabel") != null)
	var physical_sign = cash_reg.get_node_or_null("PhysicalCashSign")
	var sign_label = physical_sign.get_node_or_null("SignLabel") as Label3D if physical_sign else null

	var sign_ok = (not has_floating_label and physical_sign != null and sign_label != null and sign_label.text.contains("CAIXA"))

	if sign_ok:
		print("  ✅ TESTE 1: Letras flutuantes removidas da registradora; placa física 'CAIXA' instalada com acabamento padronizado.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Placa ou textos do caixa inválidos (Floating: %s, PhysicalSign: %s, Text: '%s')" % [has_floating_label, physical_sign != null, sign_label.text if sign_label else ""])

	# --- TESTE 2: Chapa Suja Rejeita Ingrediente Sem Perder/Destruir o Item ---
	total_tests += 1
	var grill = main_scene.get_node_or_null("Grill") as Grill
	if not grill:
		grill = GrillScene.instantiate() as Grill
		main_scene.add_child(grill)

	var player = PlayerScene.instantiate()
	main_scene.add_child(player)

	var patty = PattyScene.instantiate()
	main_scene.add_child(patty)
	player.pick_up(patty)

	# Força chapa suja
	grill.dirt_level = 1.0
	var is_grill_dirty = grill.is_dirty()

	# Jogador tenta colocar o hambúrguer na chapa suja
	grill.interact_item(player)

	var item_not_lost = (player.held_item == patty and is_instance_valid(patty))
	var grill_remains_empty = grill.active_items.is_empty()

	# Agora limpa a chapa e coloca
	grill.clean_station()
	grill.interact_item(player)

	var item_placed_on_clean = (player.held_item == null and grill.active_items.size() == 1)

	if is_grill_dirty and item_not_lost and grill_remains_empty and item_placed_on_clean:
		print("  ✅ TESTE 2: Chapa suja rejeitou o hambúrguer mantendo-o íntegro na mão do jogador; colocação normal após limpeza.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Falha no fluxo de chapa suja (Dirty: %s, Held: %s, EmptyWhileDirty: %s, PlacedWhenClean: %s)" % [is_grill_dirty, item_not_lost, grill_remains_empty, item_placed_on_clean])

	# --- TESTE 3: Cenário Crítico — Finalização do Drive-Thru Não Afeta Pedidos de Delivery ---
	total_tests += 1
	order_mgr.active_orders.clear()
	order_mgr.daily_order_history.clear()

	# 1. Cria 1 pedido de Drive-Thru
	var car = DeliveryCarScene.instantiate()
	main_scene.add_child(car)
	var drive_thru_order = car.take_order(player)

	# 2. Cria 2 pedidos de Delivery aguardando aceitação
	var delivery_1 = order_mgr.create_delivery_order()
	var delivery_2 = order_mgr.create_delivery_order()

	var initial_active_count = order_mgr.active_orders.size() # Deve ser 3

	# 3. Finaliza corretamente o Drive-Thru
	order_mgr.complete_order(drive_thru_order)

	# 4. Verifica se os 2 pedidos de Delivery CONTINUAM ativos e intocados
	var deliv1_still_active = order_mgr.active_orders.has(delivery_1) and delivery_1.state == Order.State.RECEIVED and not delivery_1.is_accepted
	var deliv2_still_active = order_mgr.active_orders.has(delivery_2) and delivery_2.state == Order.State.RECEIVED and not delivery_2.is_accepted
	var dt_order_removed = not order_mgr.active_orders.has(drive_thru_order)

	# 5. Aceita um dos pedidos de delivery normalmente
	var accept_deliv1_ok = order_mgr.accept_delivery_order(delivery_1.id)

	if initial_active_count == 3 and deliv1_still_active and deliv2_still_active and dt_order_removed and accept_deliv1_ok:
		print("  ✅ TESTE 3: Conclusão do Drive-Thru não afetou os pedidos de Delivery; ambos continuaram ativos e aceitáveis.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Intercorrência entre Drive-thru e Delivery (Count: %d, D1: %s, D2: %s, DTRemoved: %s, AcceptD1: %s)" % [initial_active_count, deliv1_still_active, deliv2_still_active, dt_order_removed, accept_deliv1_ok])

	# --- TESTE 4: Expiração Individual de Pedido Não Aceito ---
	total_tests += 1
	# delivery_1 foi aceito, delivery_2 ainda não
	order_mgr.expire_unaccepted_delivery_order(delivery_2)

	var deliv2_expired = (not order_mgr.active_orders.has(delivery_2)) and (delivery_2.delivery_stage == "NOT_ACCEPTED")
	var deliv1_still_in_progress = order_mgr.active_orders.has(delivery_1) and (delivery_1.delivery_stage == "PREPARING")

	if deliv2_expired and deliv1_still_in_progress:
		print("  ✅ TESTE 4: Expiração pontual encerrou apenas o pedido não aceito (#%03d), mantendo o outro ativo normalmente." % delivery_2.id)
		passed_tests += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Expiração de delivery atingiu pedidos indevidos (D2Expired: %s, D1Active: %s)" % [deliv2_expired, deliv1_still_in_progress])

	# --- TESTE 5: Veículo do Drive-Thru Não Fica Eternamente Esperando Sem Pedido ---
	total_tests += 1
	var car2 = DeliveryCarScene.instantiate()
	main_scene.add_child(car2)
	var dt_ord2 = car2.take_order(player)

	# Simula pedido cancelado / concluído
	order_mgr.complete_order(dt_ord2)
	car2._physics_process(0.1)

	var car_leaving = (car2.current_state == DeliveryCar.CarState.LEAVING)

	if car_leaving:
		print("  ✅ TESTE 5: Veículo do Drive-Thru transita imediatamente para LEAVING e parte após o fim do pedido.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 5 FALHOU: Carro permaneceu esperando após fim do pedido (State: %d)" % car2.current_state)

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
