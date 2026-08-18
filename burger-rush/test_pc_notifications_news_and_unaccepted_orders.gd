extends SceneTree

# =============================================================================
# TEST SUITE: NOTIFICAÇÕES NO PC, ABA DE NOTÍCIAS & PEDIDOS NÃO ACEITOS
# =============================================================================

const OrderManagerScript = preload("res://src/orders/order_manager.gd")
const OrderScript = preload("res://src/orders/order.gd")
const NewsManagerScript = preload("res://src/news/news_manager.gd")
const DailyEventManagerScript = preload("res://src/core/daily_event_manager.gd")
const CalendarManagerScript = preload("res://src/core/calendar_manager.gd")
const ComputerUIScene: PackedScene = preload("res://src/ui/computer_ui.tscn")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: NOTIFICAÇÕES NO PC, NOTÍCIAS REAIS & PEDIDOS NÃO ACEITOS")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# 1. Setup managers
	var cal = CalendarManagerScript.new()
	root.add_child(cal)
	cal._ready()

	var dem = DailyEventManagerScript.new()
	root.add_child(dem)

	var nm = NewsManagerScript.new()
	nm.name = "NewsManager"
	root.add_child(nm)
	nm._ready()

	var om = OrderManagerScript.new()
	root.add_child(om)
	om._ready()

	var comp_ui = ComputerUIScene.instantiate()
	root.add_child(comp_ui)
	comp_ui._ready()

	# --- TESTE 1: Pedidos Não Aceitos no Prazo (Delivery Timeout) ---
	total_tests += 1
	var del_order = om.create_delivery_order()
	del_order.delivery_accept_timer = 0.5 # Acelera timer para teste

	# Simula passagem de tempo sem o jogador aceitar o pedido
	om._process(0.6)

	var hist = om.get_order_history()
	var found_unaccepted = false
	for h in hist:
		if h.get("id") == del_order.id and h.get("status") == "Não aceito no prazo" and not h.get("is_paid") and is_equal_approx(h.get("payment_amount"), 0.0):
			found_unaccepted = true
			break

	var not_in_active = not om.active_orders.has(del_order)
	var state_ok = (del_order.state == OrderScript.State.NOT_ACCEPTED)

	if found_unaccepted and not_in_active and state_ok:
		print("  ✅ TESTE 1: Pedido delivery não aceito dentro do prazo registrado como 'Não aceito no prazo' no histórico diário.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Pedido expirado não registrado corretamente (Found: %s, InActive: %s, State: %s)" % [found_unaccepted, not not_in_active, del_order.state])

	# --- TESTE 2: Notificação de Novos Pedidos no PC (Não Bloqueante / Top Toast) ---
	total_tests += 1
	comp_ui.open() # Abre o PC no Estoque
	comp_ui._switch_tab(comp_ui.TabID.INVENTORY, "Estoque Geral")

	var prev_badge_count = comp_ui.unviewed_orders_count
	var new_order = om.create_delivery_order()

	var toast = comp_ui.notification_toast_panel
	var toast_visible = (toast != null and toast.visible)
	var is_non_blocking = (toast != null and toast.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	var is_at_top = (toast != null and toast.position.y < 100.0)
	var badge_increased = (comp_ui.unviewed_orders_count > prev_badge_count)

	if toast_visible and is_non_blocking and is_at_top and badge_increased:
		print("  ✅ TESTE 2: Notificação discreta de novo pedido exibida no topo do PC, sem bloquear navegação ou cliques (MOUSE_FILTER_IGNORE).")
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Toast de notificação incorreto (Vis: %s, NonBlock: %s, Top: %s, Badge: %s)" % [toast_visible, is_non_blocking, is_at_top, badge_increased])

	# --- TESTE 3: Sininho na Área de Pedidos e Limpeza ao Visualizar ---
	total_tests += 1
	comp_ui._switch_tab(comp_ui.TabID.ORDERS, "Pedidos & Delivery")

	var badge_cleared = (comp_ui.unviewed_orders_count == 0)
	var toast_hidden = (toast != null and not toast.visible)

	if badge_cleared and toast_hidden:
		print("  ✅ TESTE 3: Acessar a aba de Pedidos limpa o contador do sininho e oculta a notificação.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Limpeza do sininho falhou (Count: %d, ToastVis: %s)" % [comp_ui.unviewed_orders_count, toast_hidden])

	# --- TESTE 4: Aba de Notícias em Dia Sem Evento (Mensagem Amigável Sem Notícias Fictícias) ---
	total_tests += 1
	dem.current_event = DailyEventManagerScript.EventType.NONE
	var normal_arts = nm.generate_daily_news(1)

	comp_ui._switch_tab(comp_ui.TabID.NEWS, "Jornal da Cidade")
	comp_ui._refresh_news_tab()

	var vbox = comp_ui.news_content_vbox
	if not vbox:
		vbox = comp_ui.get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/NewsTab/NewsScroll/Margin/NewsContentVBox")

	if normal_arts.is_empty() and vbox and vbox.get_child_count() == 1:
		print("  ✅ TESTE 4: Dia sem eventos exibe a mensagem 'Nenhuma notícia nova hoje. O dia segue normalmente.' sem notícias fictícias.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Notícias em dia normal incorretas (ArtsCount: %d, VBoxChildren: %d)" % [normal_arts.size(), vbox.get_child_count() if vbox else 0])

	# --- TESTE 5: Aba de Notícias em Dia Com Evento Real e Influência no Gameplay ---
	total_tests += 1
	dem.current_event = DailyEventManagerScript.EventType.RAINY_DAY
	var rain_arts = nm.generate_daily_news(2)

	comp_ui._refresh_news_tab()

	var has_rain_art = (rain_arts.size() >= 1)
	var first_art = rain_arts[0] if has_rain_art else {}
	var has_impacts = (first_art.get("impacts", []).size() >= 2)
	var mentions_drive_thru = false
	for imp in first_art.get("impacts", []):
		if "drive-thru" in imp.to_lower() or "delivery" in imp.to_lower():
			mentions_drive_thru = true

	if has_rain_art and has_impacts and mentions_drive_thru:
		print("  ✅ TESTE 5: Notícia de Chuva Intensa detalha claramente a 'Influência no dia' no gameplay (Drive-thru e Salão).")
		passed_tests += 1
	else:
		print("  ❌ TESTE 5 FALHOU: Notícia com influência no gameplay incorreta (HasArt: %s, Impacts: %d, DT: %s)" % [has_rain_art, first_art.get("impacts", []).size() if has_rain_art else 0, mentions_drive_thru])

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
