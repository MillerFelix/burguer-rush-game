extends SceneTree

# =============================================================================
# TEST SUITE: AUDIO ADJUSTMENTS, PC NOTIFICATIONS & CUSTOMER SOUNDS
# =============================================================================

const SoundSynthesizerScript = preload("res://src/audio/sound_synthesizer.gd")
const CustomerScript = preload("res://src/customers/customer.gd")
const OrderManagerScript = preload("res://src/orders/order_manager.gd")
const OrderScript = preload("res://src/orders/order.gd")
const ComputerStationScript = preload("res://src/stations/computer_station.gd")
const ComputerUIScript = preload("res://src/ui/computer_ui.gd")
const WeatherManagerScript = preload("res://src/environment/weather_manager.gd")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: SISTEMA DE ÁUDIO, NOTIFICAÇÕES DO PC E SONS DE CLIENTES")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# 1. SETUP MANAGERS
	var om = OrderManagerScript.new()
	om.name = "OrderManager"
	root.add_child(om)
	OrderManagerScript.instance = om

	# --- TESTE 1: Cliente Chama Atendimento -> Exclusivamente Assovio Existente ---
	total_tests += 1
	var customer = CustomerScript.new()
	customer.name = "TestCustomer"
	root.add_child(customer)
	customer._setup_audio()

	customer._call_attention_to_order()
	var whistle_stream = customer.customer_audio.stream
	var expected_whistle_stream = SoundSynthesizerScript.get_stream("customer_call_whistle")

	if whistle_stream != null and whistle_stream == expected_whistle_stream:
		print("  ✅ TESTE 1: Cliente levantou a mão para chamar -> Tocou somente o assovio existente.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Som de chamada do cliente incorreto ou diferente de assovio.")

	# --- TESTE 2: Cliente em Situação Negativa -> Exclusivamente Som Negativo ---
	total_tests += 1
	customer.on_order_wrong("Lanche incorreto")
	var negative_stream = customer.customer_audio.stream
	var expected_negative_stream = SoundSynthesizerScript.get_stream("customer_wrong_order")

	if negative_stream != null and negative_stream == expected_negative_stream:
		print("  ✅ TESTE 2: Cliente recebeu pedido incorreto -> Tocou exclusivamente o som negativo existente.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Som de evento negativo incorreto.")

	# --- TESTE 3: Desistência do Cliente -> Exclusivamente Som Negativo ---
	total_tests += 1
	customer.state = CustomerScript.State.WAITING_FOR_FOOD
	customer.abandon_restaurant("Demora no atendimento")
	var abandon_stream = customer.customer_audio.stream

	if abandon_stream != null and abandon_stream == expected_negative_stream:
		print("  ✅ TESTE 3: Cliente desistiu e foi embora -> Tocou somente o som negativo existente.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Som de abandono incorreto.")

	# --- TESTE 4: Notificação Sonora e Visual do PC com Novo Pedido ---
	total_tests += 1
	var pc_scene: PackedScene = load("res://src/stations/computer_station.tscn")
	var pc_station = pc_scene.instantiate()
	root.add_child(pc_station)
	pc_station._ready()

	var pc_ui = pc_station.computer_ui_instance
	if pc_ui:
		pc_ui._ready()
	var initial_unread = pc_station.unviewed_orders_count

	# Cria novo pedido de Delivery
	var order_deliv = om.create_delivery_order()
	var pc_audio_stream = pc_station.audio_player.stream if pc_station.audio_player else null
	var expected_pc_chime = SoundSynthesizerScript.get_stream("pc_notification")

	var has_sound = (pc_audio_stream == expected_pc_chime)
	var badge_active = (pc_station.notification_badge and pc_station.notification_badge.visible)
	var unread_incremented = (pc_station.unviewed_orders_count == initial_unread + 1)
	var toast_active = (pc_ui and pc_ui.notification_toast_panel and pc_ui.notification_toast_panel.visible)

	if has_sound and badge_active and unread_incremented and toast_active:
		print("  ✅ TESTE 4: Novo pedido chegou -> Som curto de notificação tocou + Indicador 3D e Toast no PC ativos.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Notificação de novo pedido no PC falhou (Som: %s, Badge: %s, Unread: %s, Toast: %s)" % [has_sound, badge_active, unread_incremented, toast_active])

	# --- TESTE 5: Sem Notificações Duplicadas para o Mesmo Pedido ---
	total_tests += 1
	var unread_before_dup = pc_station.unviewed_orders_count
	# Dispara evento novamente para o mesmo pedido já notificado
	pc_station._on_order_created(order_deliv)
	var unread_after_dup = pc_station.unviewed_orders_count

	if unread_before_dup == unread_after_dup:
		print("  ✅ TESTE 5: Pedido duplicado ignorado -> Sem notificações sonoras ou visuais duplicadas.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 5 FALHOU: Notificações duplicadas foram geradas.")

	# --- TESTE 6: Abertura e Visualização dos Pedidos no PC -> Notificação Marcada como Lida ---
	total_tests += 1
	pc_ui.open()
	pc_ui._switch_tab(ComputerUIScript.TabID.ORDERS, "Pedidos & Delivery")

	var badge_cleared = (pc_station.notification_badge and not pc_station.notification_badge.visible)
	var unread_cleared = (pc_station.unviewed_orders_count == 0 and pc_ui.unviewed_orders_count == 0)
	var toast_hidden = (pc_ui.notification_toast_panel and not pc_ui.notification_toast_panel.visible)

	if badge_cleared and unread_cleared and toast_hidden:
		print("  ✅ TESTE 6: Pedidos visualizados no PC -> Indicadores 3D e Toast limpos com sucesso.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 6 FALHOU: Notificações não foram marcadas como lidas (Badge: %s, Unread: %s, Toast: %s)" % [badge_cleared, unread_cleared, toast_hidden])

	# --- TESTE 7: Volume da Chuva Reduzido Confortavelmente como Som Ambiente ---
	total_tests += 1
	var wm = WeatherManagerScript.new()
	root.add_child(wm)
	wm.set_weather(WeatherManagerScript.WeatherType.RAINY, true)
	wm._process_spatial_audio(Vector3(0.0, 1.0, 0.0)) # Posição interior

	var int_vol_ok = (wm.rain_audio_int != null and wm.rain_audio_int.volume_db <= -22.0)
	var ext_vol_ok = (wm.rain_audio_ext != null and wm.rain_audio_ext.volume_db <= -20.0)

	if int_vol_ok and ext_vol_ok:
		print("  ✅ TESTE 7: Volume da chuva reduzido para som de fundo (Int: %.1f dB, Ext: %.1f dB)." % [wm.rain_audio_int.volume_db, wm.rain_audio_ext.volume_db])
		passed_tests += 1
	else:
		print("  ❌ TESTE 7 FALHOU: Volume da chuva ainda muito alto.")

	# --- RESULTADO FINAL ---
	print("\n===========================================================================")
	print("📊 RESULTADO FINAL: %d/%d TESTES PASSARAM (%.1f%%)" % [passed_tests, total_tests, (float(passed_tests)/float(total_tests))*100.0])
	print("===========================================================================\n")

	if passed_tests == total_tests:
		print("🎉 TODOS OS TESTES PASSARAM COM 100% DE SUCESSO!\n")
		quit(0)
	else:
		print("⚠️ ALGUNS TESTES FALHARAM.\n")
		quit(1)
