extends SceneTree

# =============================================================================
# TEST SUITE: CALENDÁRIO VIVO, JORNAL DA CIDADE & EVENTOS CONECTADOS
# =============================================================================

const CalendarManagerScript = preload("res://src/core/calendar_manager.gd")
const DailyEventManagerScript = preload("res://src/core/daily_event_manager.gd")
const NewsManagerScript = preload("res://src/news/news_manager.gd")
const FinanceManagerScript = preload("res://src/economy/finance_manager.gd")
const OrderManagerScript = preload("res://src/orders/order_manager.gd")
const OrderScript = preload("res://src/orders/order.gd")
const ReputationManagerScript = preload("res://src/customers/reputation_manager.gd")
const CustomerReviewScript = preload("res://src/customers/customer_review.gd")
const WeatherManagerScript = preload("res://src/environment/weather_manager.gd")
const PowerManagerScript = preload("res://src/core/power_manager.gd")
const GameClockScript = preload("res://src/time/game_clock.gd")
const ComputerStationScript = preload("res://src/stations/computer_station.gd")
const ComputerUIScript = preload("res://src/ui/computer_ui.gd")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: CALENDÁRIO VIVO, JORNAL DA CIDADE & EVENTOS CONECTADOS NO PC")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# 1. SETUP DOS MANAGERS CENTRAIS
	var cal_mgr = CalendarManagerScript.new()
	cal_mgr.name = "CalendarManager"
	root.add_child(cal_mgr)
	CalendarManagerScript.instance = cal_mgr
	cal_mgr._ready()

	var event_mgr = DailyEventManagerScript.new()
	event_mgr.name = "DailyEventManager"
	root.add_child(event_mgr)
	DailyEventManagerScript.instance = event_mgr

	var news_mgr = NewsManagerScript.new()
	news_mgr.name = "NewsManager"
	root.add_child(news_mgr)
	NewsManagerScript.instance = news_mgr
	news_mgr._ready()

	var fin_mgr = FinanceManagerScript.new()
	fin_mgr.name = "FinanceManager"
	root.add_child(fin_mgr)
	FinanceManagerScript.instance = fin_mgr

	var order_mgr = OrderManagerScript.new()
	order_mgr.name = "OrderManager"
	root.add_child(order_mgr)
	OrderManagerScript.instance = order_mgr

	var rep_mgr = ReputationManagerScript.new()
	rep_mgr.name = "ReputationManager"
	root.add_child(rep_mgr)
	ReputationManagerScript.instance = rep_mgr

	var weather_mgr = WeatherManagerScript.new()
	weather_mgr.name = "WeatherManager"
	root.add_child(weather_mgr)
	WeatherManagerScript.instance = weather_mgr

	var power_mgr = PowerManagerScript.new()
	power_mgr.name = "PowerManager"
	root.add_child(power_mgr)
	PowerManagerScript.instance = power_mgr

	var game_clock = GameClockScript.new()
	game_clock.name = "GameClock"
	root.add_child(game_clock)
	GameClockScript.instance = game_clock
	game_clock._ready()

	# --- TESTE 1: Início Obrigatório do Calendário em 01/01/2026 (Quinta-feira, Dia 1) ---
	total_tests += 1
	var c_data = cal_mgr.get_calendar_data()
	var is_day_1 = (c_data.day_number == 1 and c_data.day == 1 and c_data.month == 1 and c_data.year == 2026)
	var is_thursday = (c_data.weekday_name == "Quinta-feira" and c_data.day_of_week == 4)
	var date_fmt = (c_data.formatted_date == "01/01/2026")

	if is_day_1 and is_thursday and date_fmt:
		print("  ✅ TESTE 1: Calendário inicializado em 01/01/2026 (Quinta-feira, Dia 1).")
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Início do calendário incorreto (%s, %s, Dia %d)" % [c_data.formatted_date, c_data.weekday_name, c_data.day_number])

	# --- TESTE 2: Cálculo Cronológico e Matriz Mensal do Calendário ---
	total_tests += 1
	var feb_day = cal_mgr.get_date_for_day_number(32) # 01/02/2026 (Domingo, Dia 32)
	var is_feb_1 = (feb_day.day == 1 and feb_day.month == 2 and feb_day.year == 2026 and feb_day.weekday_name == "Domingo")

	var jan_matrix = cal_mgr.get_month_matrix(2026, 1)
	var has_weeks = (jan_matrix.size() >= 5)

	if is_feb_1 and has_weeks:
		print("  ✅ TESTE 2: Transição de meses e matriz do mês de Janeiro (7 colunas) geradas com sucesso.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Cálculo de data futura ou matriz incorretos (Fev: %s, Semanas: %d)" % [feb_day.formatted_date, jan_matrix.size()])

	# --- TESTE 3: Geração Dinâmica de Notícias para Eventos Reais ---
	total_tests += 1
	event_mgr.current_event = DailyEventManagerScript.EventType.NETWORK_MAINTENANCE
	var news_articles = news_mgr.generate_daily_news(1)
	var main_news = news_articles[0]

	var has_event_headline = ("manutenção" in main_news.title.to_lower() or "elétrica" in main_news.title.to_lower())
	var has_fictional_source = (main_news.source == "Portal Central" or main_news.source == "Jornal da Cidade")
	var has_impact = (main_news.impact != "")

	if has_event_headline and has_fictional_source and has_impact:
		print("  ✅ TESTE 3: Notícias geradas dinamicamente com base no evento de Manutenção Elétrica.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Notícia do evento incorreta (Title: %s, Source: %s)" % [main_news.title, main_news.source])

	# --- TESTE 4: Atualização de Notícia Pós-Ocorrência do Evento ---
	total_tests += 1
	news_mgr.mark_event_occurred(DailyEventManagerScript.EventType.NETWORK_MAINTENANCE)
	var updated_main = news_mgr.get_today_news()[0]

	var is_confirmed = (updated_main.occurred and "URGENTE" in updated_main.status_badge)
	var is_occurred_title = ("confirmada" in updated_main.title.to_lower() or "queda" in updated_main.title.to_lower())

	if is_confirmed and is_occurred_title:
		print("  ✅ TESTE 4: Notícia atualizada de 'Previsão' para 'Ocorrência Confirmada' em tempo real.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Notícia pós-evento não atualizada (Badge: %s, Title: %s)" % [updated_main.status_badge, updated_main.title])

	# --- TESTE 5: Simulação de Atividade no Dia 1 e Encerramento ---
	total_tests += 1
	fin_mgr.register_channel_sale("dine_in", 45.0, "Venda Salão #001")
	fin_mgr.register_channel_sale("drive_thru", 30.0, "Venda Drive-Thru #002")
	fin_mgr.register_channel_sale("delivery", 55.0, "Venda Delivery #003")

	var dummy_order = OrderScript.new()
	dummy_order.id = 1
	dummy_order.source_type = "DINE_IN"
	dummy_order.total_price = 45.0
	order_mgr.record_order_to_history(dummy_order, "Concluído — Pago", true, 45.0, false, "12:30")

	var rev_d1 = CustomerReviewScript.new()
	rev_d1.customer_id = 1
	rev_d1.customer_name = "Carlos Silva"
	rev_d1.stars = 5.0
	rev_d1.comment = "Ótimo almoço!"
	rev_d1.day = 1
	rev_d1.date_string = "01/01/2026"
	rev_d1.time_string = "13:00"
	rev_d1.channel_type = "DINE_IN"
	rev_d1.channel_name = "Restaurante"
	rev_d1.tags.append("Comida Excelente")
	rep_mgr.add_review(rev_d1)

	# Fecha o Dia 1
	game_clock.close_day()
	var day_1_record = cal_mgr.get_day_record(1)

	var d1_fin_ok = (day_1_record.financial.revenue >= 130.0)
	var d1_orders_ok = (day_1_record.orders.total >= 1)
	var d1_rep_ok = (day_1_record.reputation.reviews_count >= 1)
	var d1_news_ok = (day_1_record.news.size() >= 1)

	if d1_fin_ok and d1_orders_ok and d1_rep_ok and d1_news_ok:
		print("  ✅ TESTE 5: Dia 1 encerrado e snapshot arquivado no Calendário com Finanças, Pedidos, Avaliações e Notícias.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 5 FALHOU: Snapshot do Dia 1 incompleto (Rev: %.2f, Orders: %d, Reviews: %d, News: %d)" % [day_1_record.financial.revenue, day_1_record.orders.total, day_1_record.reputation.reviews_count, day_1_record.news.size()])

	# --- TESTE 6: Avanço para o Dia 2 e Verificação de Isolamento Histórico ---
	total_tests += 1
	game_clock.start_next_day() # Avança para o Dia 2 (02/01/2026 - Sexta-feira)
	var d2_info = cal_mgr.get_calendar_data()

	var is_day_2 = (d2_info.day_number == 2 and d2_info.day == 2 and d2_info.weekday_name == "Sexta-feira")

	# Consulta retroativa ao Dia 1
	var past_day_1_record = cal_mgr.get_day_record(1)
	var past_data_preserved = (past_day_1_record.day_number == 1 and past_day_1_record.financial.revenue >= 130.0)

	if is_day_2 and past_data_preserved:
		print("  ✅ TESTE 6: Jogo avançou para o Dia 2 e histórico do Dia 1 permanece preservado e isolado.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 6 FALHOU: Avanço de dia ou consulta retroativa falhou (Dia: %d, Preservado: %s)" % [d2_info.day_number, past_data_preserved])

	# --- TESTE 7: Interface do PC (Aba Calendário, Grid e Inspeção de Sub-abas) ---
	total_tests += 1
	var pc_scene: PackedScene = load("res://src/stations/computer_station.tscn")
	var pc_station = pc_scene.instantiate()
	root.add_child(pc_station)
	pc_station._ready()

	var pc_ui = pc_station.computer_ui_instance
	if pc_ui:
		pc_ui._ready()
		pc_ui.open()
		pc_ui._switch_tab(ComputerUIScript.TabID.CALENDAR, "Calendário")

	var cal_tab_visible = (pc_ui and pc_ui.calendar_tab and pc_ui.calendar_tab.visible)
	var days_grid_has_cells = (pc_ui and pc_ui.days_grid and pc_ui.days_grid.get_child_count() > 20)

	# Testa seleção do Dia 1 no PC e inspeção das 4 sub-abas
	pc_ui._select_calendar_day(1)
	pc_ui._set_calendar_subtab("SUMMARY")
	var has_summary = (pc_ui.day_detail_content_vbox.get_child_count() > 0)

	pc_ui._set_calendar_subtab("ORDERS")
	var has_orders = (pc_ui.day_detail_content_vbox.get_child_count() > 0)

	pc_ui._set_calendar_subtab("REVIEWS")
	var has_reviews = (pc_ui.day_detail_content_vbox.get_child_count() > 0)

	pc_ui._set_calendar_subtab("NEWS")
	var has_news = (pc_ui.day_detail_content_vbox.get_child_count() > 0)

	var subtabs_ok = (has_summary and has_orders and has_reviews and has_news)

	if cal_tab_visible and days_grid_has_cells and subtabs_ok:
		print("  ✅ TESTE 7: Aba Calendário renderizada com grid mensal e inspeção das 4 sub-abas (Resumo, Pedidos, Avaliações, Notícias).")
		passed_tests += 1
	else:
		print("  ❌ TESTE 7 FALHOU: Renderização da aba Calendário falhou (Visible: %s, Cells: %d, Subtabs: %s)" % [cal_tab_visible, pc_ui.days_grid.get_child_count() if pc_ui.days_grid else 0, subtabs_ok])

	# --- TESTE 8: Interface do PC (Aba Jornal da Cidade & Portal Digital) ---
	total_tests += 1
	pc_ui._switch_tab(ComputerUIScript.TabID.NEWS, "Jornal da Cidade")

	var news_tab_visible = (pc_ui and pc_ui.news_tab and pc_ui.news_tab.visible)
	var news_cards_count = pc_ui.news_content_vbox.get_child_count() if pc_ui.news_content_vbox else 0

	if news_tab_visible and news_cards_count >= 1:
		print("  ✅ TESTE 8: Aba Jornal da Cidade renderizada com manchete principal e cards editoriais.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 8 FALHOU: Renderização da aba Jornal da Cidade falhou (Visible: %s, Cards: %d)" % [news_tab_visible, news_cards_count])

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
