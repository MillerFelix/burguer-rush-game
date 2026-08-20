extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE COMPLETO DO SISTEMA DE EVENTOS, NOTÍCIAS E TRANSIÇÃO
# ==============================================================================

const DailyEventManager = preload("res://src/core/daily_event_manager.gd")
const NewsManager = preload("res://src/news/news_manager.gd")
const CalendarManager = preload("res://src/core/calendar_manager.gd")
const GameClock = preload("res://src/time/game_clock.gd")
const HUD = preload("res://src/ui/hud.gd")
const ComputerUI = preload("res://src/ui/computer_ui.gd")

var passed: int = 0
var failed: int = 0

func assert_test(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("  [PASS] %s" % message)
	else:
		failed += 1
		print("  [FAIL] %s" % message)

func _init() -> void:
	call_deferred("run_all_tests")

func run_all_tests() -> void:
	print("\n=================================================================")
	print("=== BURGER RUSH - TESTE: EVENTOS, NOTÍCIAS E TRANSIÇÃO ==========")
	print("=================================================================")

	var cal = CalendarManager.new()
	root.add_child(cal)

	var dem = DailyEventManager.new()
	root.add_child(dem)

	var nm = NewsManager.new()
	root.add_child(nm)

	var clock = GameClock.new()
	root.add_child(clock)

	var hud_scene = load("res://src/ui/hud.tscn")
	var hud = hud_scene.instantiate() as HUD
	root.add_child(hud)

	var comp_ui_scene = load("res://src/ui/computer_ui.tscn")
	var comp_ui = comp_ui_scene.instantiate() as ComputerUI
	root.add_child(comp_ui)

	# --------------------------------------------------------------------------
	# PARTE 1: VERIFICAÇÃO DOS 8 EVENTOS CADASTRADOS + EVENTO NONE
	# --------------------------------------------------------------------------
	print("\n--- TESTE 1: Validação Individual de Cada Evento Cadastrado ---")

	var all_events = [
		DailyEventManager.EventType.NETWORK_MAINTENANCE,
		DailyEventManager.EventType.NETWORK_REGULATION,
		DailyEventManager.EventType.WATER_SUPPLY_PROBLEM,
		DailyEventManager.EventType.RAINY_DAY,
		DailyEventManager.EventType.STORM_DAY,
		DailyEventManager.EventType.EXTREME_HEAT,
		DailyEventManager.EventType.GAME_DAY,
		DailyEventManager.EventType.TRANSPORT_DISRUPTION
	]

	for ev in all_events:
		dem.force_event(ev)
		var edata = dem.get_current_event_data()
		var ev_name = edata.get("event_name", "")
		assert_test(edata.get("has_event") == true, "Evento %s registrado com has_event = true" % ev_name)
		assert_test(edata.get("title") != "", "Evento %s possui título definido: '%s'" % [ev_name, edata.get("title")])
		assert_test(edata.get("headline") != "", "Evento %s possui manchete: '%s'" % [ev_name, edata.get("headline")])
		assert_test(edata.get("body") != "", "Evento %s possui descrição: '%s'" % [ev_name, edata.get("body")])

		# Notícias do PC
		var articles = nm.get_today_news()
		assert_test(articles.size() >= 1, "Notícias do dia geradas para evento %s" % ev_name)
		var main_art = articles[0]
		assert_test(main_art.get("is_main") == true, "Notícia principal criada para evento %s" % ev_name)
		assert_test(main_art.get("event_type") == ev, "Tipo de evento da notícia coincide com %s" % ev_name)
		assert_test(main_art.get("impacts").size() > 0, "Notícia detalha impactos práticos na operação")

		# Tela de Transição / Aviso no HUD
		hud._on_daily_event_started(ev, edata)
		assert_test(hud.daily_notice_modal.visible == true, "Modal de aviso diário VISÍVEL para evento %s" % ev_name)
		assert_test(hud.notice_title_label.text == edata.get("title"), "Título no modal do HUD coincide com o evento %s" % ev_name)

	# --------------------------------------------------------------------------
	# PARTE 2: DIA SEM EVENTO (NONE)
	# --------------------------------------------------------------------------
	print("\n--- TESTE 2: Dia Sem Evento (Operação Normal / NONE) ---")
	dem.force_event(DailyEventManager.EventType.NONE)
	var none_data = dem.get_current_event_data()
	assert_test(none_data.get("has_event") == false, "has_event = false quando EventType.NONE")

	# Notícias do PC
	var none_articles = nm.get_today_news()
	assert_test(none_articles.size() >= 1, "Informativo municipal gerado para o dia normal")
	var none_main = none_articles[0]
	assert_test(none_main.get("title").contains("Boletim da Cidade"), "Título do informativo é neutro ('Boletim da Cidade')")
	assert_test(none_main.get("status_badge").contains("REGULAR"), "Status da notícia indica OPERAÇÃO REGULAR")

	# Tela de Transição / Aviso no HUD
	hud._on_daily_event_started(DailyEventManager.EventType.NONE, none_data)
	assert_test(hud.daily_notice_modal.visible == false, "Modal de aviso diário RIGOROSAMENTE OCULTO quando não há evento")

	# --------------------------------------------------------------------------
	# PARTE 3: ABA DE NOTÍCIAS DO PC (CONSULTA EM TEMPO REAL E HISTÓRICO)
	# --------------------------------------------------------------------------
	print("\n--- TESTE 3: Exibição na Aba Notícias do PC ---")
	if comp_ui:
		dem.force_event(DailyEventManager.EventType.EXTREME_HEAT)
		comp_ui._refresh_news_tab()
		var vbox = comp_ui.get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/NewsTab/NewsScroll/Margin/NewsContentVBox")
		assert_test(vbox != null, "Container de notícias do PC presente")
		assert_test(vbox.get_child_count() > 0, "Cards de notícias renderizados na aba Notícias do PC")

		# Histórico de notícias arquivadas no calendário do PC
		cal.day_number = 3
		nm.generate_daily_news(3)
		var history_news = nm.get_news_for_day(3)
		assert_test(history_news.size() > 0, "Histórico de notícias do Dia 3 recuperado com sucesso")

	# --------------------------------------------------------------------------
	# PARTE 4: SIMULAÇÃO RANDOMIZADA DE VÁRIOS DIAS CONSECUTIVOS
	# --------------------------------------------------------------------------
	print("\n--- TESTE 4: Simulação de 15 Dias Consecutivos com Sorteio Randomizado ---")
	var count_events = 0
	var count_none = 0

	for d in range(1, 16):
		cal.day_number = d
		clock.day_number = d
		dem.roll_daily_event()
		var current_ev = dem.current_event
		var c_data = dem.get_current_event_data()

		if current_ev != DailyEventManager.EventType.NONE:
			count_events += 1
			hud._on_daily_event_started(current_ev, c_data)
			assert_test(hud.daily_notice_modal.visible == true, "Dia %d: Evento %s -> Modal de aviso visível" % [d, c_data.get("event_name")])
			var today_news = nm.get_today_news()
			assert_test(today_news[0].get("event_type") == current_ev, "Dia %d: Notícia principal corresponde ao evento %s" % [d, c_data.get("event_name")])
		else:
			count_none += 1
			hud._on_daily_event_started(current_ev, c_data)
			assert_test(hud.daily_notice_modal.visible == false, "Dia %d: Sem evento (NONE) -> Modal de aviso oculto" % d)
			var today_news = nm.get_today_news()
			assert_test(today_news[0].get("status_badge").contains("REGULAR"), "Dia %d: Notícia indica operação regular sem alerta fictício" % d)

	print("\n  [INFO] Distribuição nos 15 dias: %d dias com eventos especiais, %d dias de operação normal" % [count_events, count_none])
	assert_test(count_events > 0, "Ocorreram dias com eventos sorteados")
	assert_test(count_none > 0, "Ocorreram dias de operação normal sem eventos (NONE)")

	# Cleanup
	cal.queue_free()
	dem.queue_free()
	nm.queue_free()
	clock.queue_free()
	hud.queue_free()
	comp_ui.queue_free()

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 SISTEMA DE EVENTOS, NOTÍCIAS E TRANSIÇÃO 100% VALIDADOS!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)
