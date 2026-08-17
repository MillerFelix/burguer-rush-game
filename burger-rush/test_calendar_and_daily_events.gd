extends SceneTree

# =============================================================================
# BURGER RUSH - TEST SUITE: CALENDÁRIO, EVENTOS DIÁRIOS E OCORRÊNCIAS
# =============================================================================

const CalendarManager = preload("res://src/core/calendar_manager.gd")
const DailyEventManager = preload("res://src/core/daily_event_manager.gd")
const PowerManager = preload("res://src/core/power_manager.gd")
const WeatherManager = preload("res://src/environment/weather_manager.gd")
const MainPowerPanel = preload("res://src/stations/main_power_panel.gd")
const CommercialSink = preload("res://src/stations/commercial_sink.gd")
const Sponge = preload("res://src/tools/sponge.gd")

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(75))
	print("TESTE: SISTEMA DE CALENDÁRIO REAL E EVENTOS DIÁRIOS (BURGER RUSH)")
	print("=".repeat(75) + "\n")
	call_deferred("_run_tests")

func assert_test(condition: bool, test_name: String) -> void:
	if condition:
		pass_count += 1
		print("  [PASS] %s" % test_name)
	else:
		fail_count += 1
		print("  [FAIL] %s" % test_name)

func _run_tests() -> void:
	var main_scene = load("res://src/main.tscn")
	if not main_scene:
		print("ERRO: main.tscn não encontrado")
		quit(1)
		return

	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	await create_timer(0.2).timeout

	var player = root_node.get_node_or_null("Player")
	assert_test(player != null, "Player ativo no mundo")

	var cal = CalendarManager.get_instance()
	if not cal:
		cal = root_node.get_node_or_null("CalendarManager")
	assert_test(cal != null, "CalendarManager presente na cena")

	var dem = DailyEventManager.get_instance()
	if not dem:
		dem = root_node.get_node_or_null("DailyEventManager")
	assert_test(dem != null, "DailyEventManager presente na cena")

	var pm: PowerManager = root_node.get_node_or_null("PowerManager")
	assert_test(pm != null, "PowerManager central presente")

	var breaker_panel: MainPowerPanel = root_node.get_node_or_null("MainPowerPanel")
	assert_test(breaker_panel != null, "Quadro Geral de Energia presente")

	var sink: CommercialSink = root_node.get_node_or_null("CommercialSink")
	assert_test(sink != null, "Pia Industrial presente")

	var hud = root_node.find_child("HUD", true, false)
	assert_test(hud != null, "HUD ativo")

	print("\n--- TESTE 1: Calendário Real — Início em 01/01/2026 (Quinta-feira, Dia 1) ---")
	cal.reset_calendar()
	assert_test(cal.day_number == 1, "Dia inicial é o Dia 1")
	assert_test(cal.get_formatted_date() == "01/01/2026", "Data inicial formatada é 01/01/2026")
	assert_test(cal.get_weekday_name() == "Quinta-feira", "Dia da semana inicial é Quinta-feira")
	assert_test(cal.get_full_date_string() == "Quinta-feira, 1 de janeiro de 2026", "Data por extenso: '%s'" % cal.get_full_date_string())
	assert_test(not cal.is_weekend(), "Dia 1 não é fim de semana")

	print("\n--- TESTE 2: Progressão Cronológica do Calendário e Finais de Semana ---")
	# Avança para Dia 2 (Sexta-feira, 02/01/2026)
	cal.advance_day()
	assert_test(cal.day_number == 2 and cal.get_formatted_date() == "02/01/2026" and cal.get_weekday_name() == "Sexta-feira", "Avanço para Dia 2 (Sexta-feira, 02/01/2026)")
	assert_test(not cal.is_weekend(), "Sexta-feira ainda é dia de semana útil")

	# Avança para Dia 3 (Sábado, 03/01/2026) -> FIM DE SEMANA
	cal.advance_day()
	assert_test(cal.day_number == 3 and cal.get_formatted_date() == "03/01/2026" and cal.get_weekday_name() == "Sábado", "Avanço para Dia 3 (Sábado, 03/01/2026)")
	assert_test(cal.is_weekend(), "Sábado reconhecido como FIM DE SEMANA (is_weekend = true)")
	assert_test(dem.get_customer_demand_multiplier() == 1.25, "Modificador de maior movimento aplicado no Sábado (1.25x)")

	# Avança para Dia 4 (Domingo, 04/01/2026) -> FIM DE SEMANA
	cal.advance_day()
	assert_test(cal.day_number == 4 and cal.get_formatted_date() == "04/01/2026" and cal.get_weekday_name() == "Domingo", "Avanço para Dia 4 (Domingo, 04/01/2026)")
	assert_test(cal.is_weekend(), "Domingo reconhecido como FIM DE SEMANA (is_weekend = true)")
	assert_test(dem.get_customer_demand_multiplier() == 1.25, "Modificador de maior movimento aplicado no Domingo (1.25x)")

	# Avança para Dia 5 (Segunda-feira, 05/01/2026) -> DIA DE SEMANA NORMAL
	cal.advance_day()
	assert_test(cal.day_number == 5 and cal.get_formatted_date() == "05/01/2026" and cal.get_weekday_name() == "Segunda-feira", "Avanço para Dia 5 (Segunda-feira, 05/01/2026)")
	assert_test(not cal.is_weekend(), "Segunda-feira retorna a dia de semana útil")
	assert_test(dem.get_customer_demand_multiplier() == 1.0, "Modificador de movimento normal na Segunda-feira (1.0x)")

	print("\n--- TESTE 3: Evento — Manutenção da Rede Elétrica (NETWORK_MAINTENANCE) ---")
	dem.force_event(DailyEventManager.EventType.NETWORK_MAINTENANCE)
	var evt_data = dem.get_current_event_data()
	assert_test(evt_data.has_event and evt_data.title == "MANUTENÇÃO PROGRAMADA", "Notícia de Manutenção Programada gerada")
	
	# Liga a energia geral
	pm.set_main_power(true)
	assert_test(pm.is_main_power_on, "Rede elétrica inicialmente ligada")

	# Simula avanço do relógio até 14h00 (horário da primeira queda programada)
	dem._process_timed_event_effects(14.1)
	await create_timer(0.2).timeout
	assert_test(not pm.is_main_power_on, "Queda de energia ocorreu às 14h00 devido à manutenção")
	assert_test(breaker_panel.lever_pivot.rotation_degrees.z < 0.0, "Alavanca do quadro desceu automaticamente com a queda")

	# Jogador vai até o quadro e religa manualmente
	breaker_panel.interact_equipment(player)
	await create_timer(0.2).timeout
	assert_test(pm.is_main_power_on, "Jogador religou o quadro com sucesso")

	print("\n--- TESTE 4: Evento — Regulagem da Rede Elétrica (NETWORK_REGULATION) ---")
	dem.force_event(DailyEventManager.EventType.NETWORK_REGULATION)
	assert_test(dem.get_electricity_cost_multiplier() == 1.30, "Multiplicador de tarifa de 1.30x ativo (+30% no custo)")
	pm.total_energy_kwh = 100.0 # 100 kWh acumulados
	var calculated_cost = pm.get_daily_electricity_cost()
	# 100 kWh * 0.85 base * 1.30 mult = R$ 110.50
	assert_test(is_equal_approx(calculated_cost, 100.0 * 0.85 * 1.30), "Custo da energia do dia calculado com 30%% de acréscimo (R$ %.2f)" % calculated_cost)

	print("\n--- TESTE 5: Evento — Problema no Abastecimento de Água (WATER_SUPPLY_PROBLEM) ---")
	dem.force_event(DailyEventManager.EventType.WATER_SUPPLY_PROBLEM)
	assert_test(dem.is_water_available(), "Água disponível no início da manhã (antes do corte)")

	# Simula chegada das 13h30 (dentro do intervalo de 2 horas: 13h00 às 15h00)
	dem._process_timed_event_effects(13.5)
	assert_test(not dem.is_water_available(), "Abastecimento de água interrompido às 13h30 (is_water_available = false)")

	var sponge_scene = load("res://src/tools/sponge.tscn")
	var sponge: Sponge = sponge_scene.instantiate() as Sponge
	root_node.add_child(sponge)
	sponge.set_dirty()
	assert_test(sponge.is_dirty, "Bucha está suja")

	# Tenta lavar a bucha durante a falta de água
	sink.wash_or_sanitize(player)
	assert_test(not sink.is_water_running, "Torneira não libera fluxo de água durante o corte")
	assert_test(sponge.is_dirty, "Bucha permanece suja pois não havia água na pia")

	# Simula chegada das 15h05 (após o término das 2 horas de corte)
	dem._process_timed_event_effects(15.1)
	assert_test(dem.is_water_available(), "Fornecimento de água restaurado automaticamente após 2 horas")
	sink.wash_or_sanitize(player)
	assert_test(sink.is_water_running, "Torneira volta a liberar água normalmente")

	print("\n--- TESTE 6: Evento — Dia de Chuva (RAINY_DAY) ---")
	dem.force_event(DailyEventManager.EventType.RAINY_DAY)
	assert_test(dem.get_dine_in_multiplier() < 1.0, "Demanda presencial reduzida na chuva (%.2fx)" % dem.get_dine_in_multiplier())
	assert_test(dem.get_drive_thru_multiplier() > 1.0, "Demanda do drive-thru aumentada na chuva (%.2fx)" % dem.get_drive_thru_multiplier())
	var wm = WeatherManager.get_instance()
	assert_test(wm != null and wm.current_weather == WeatherManager.WeatherType.RAINY, "Ambiente externo sincronizado com clima chuvoso")

	print("\n--- TESTE 7: Evento — Tempestade (STORM_DAY) ---")
	dem.force_event(DailyEventManager.EventType.STORM_DAY)
	assert_test(dem.get_dine_in_multiplier() <= 0.65, "Demanda presencial significativamente menor na tempestade (%.2fx)" % dem.get_dine_in_multiplier())
	assert_test(dem.get_drive_thru_multiplier() >= 1.40, "Drive-thru em alta demanda na tempestade (%.2fx)" % dem.get_drive_thru_multiplier())

	print("\n--- TESTE 8: Evento — Calor Extremo (EXTREME_HEAT) ---")
	dem.force_event(DailyEventManager.EventType.EXTREME_HEAT)
	assert_test(dem.get_beverage_demand_multiplier() >= 2.0, "Demanda por bebidas duplicada na onda de calor (%.1fx)" % dem.get_beverage_demand_multiplier())

	print("\n--- TESTE 9: Evento — Dia de Jogo no Estádio (GAME_DAY) ---")
	dem.force_event(DailyEventManager.EventType.GAME_DAY)
	# Durante o dia (14h00): movimento normal
	assert_test(dem.get_customer_demand_multiplier(14.0) == 1.0, "Movimento normal durante a tarde (14h00 = 1.0x)")
	# Noite pós-jogo (19h30): pico de clientes
	assert_test(dem.get_customer_demand_multiplier(19.5) >= 1.60, "Pico de clientes à noite após o término do jogo (19h30 = %.2fx)" % dem.get_customer_demand_multiplier(19.5))

	print("\n--- TESTE 10: Encerramento do Dia e Limpeza de Modificadores ---")
	dem.end_day_event()
	assert_test(dem.current_event == DailyEventManager.EventType.NONE, "Evento diário encerrado com sucesso")
	assert_test(dem.get_electricity_cost_multiplier() == 1.0, "Multiplicador de energia resetado para 1.0x")
	assert_test(dem.get_beverage_demand_multiplier() == 1.0, "Multiplicador de bebidas resetado para 1.0x")
	assert_test(dem.event_history.size() > 0, "Histórico de eventos arquivado para o futuro sistema do PC")

	print("\n" + "=".repeat(75))
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(75) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES DE CALENDÁRIO E EVENTOS PASSARAM COM 100% DE SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
