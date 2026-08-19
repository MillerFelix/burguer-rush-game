extends SceneTree

var passed_tests: int = 0
var total_tests: int = 0

func assert_test(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		print("  [FAIL] %s" % test_name)

func _init() -> void:
	print("\n=================================================================")
	print("=== TESTE: SOM DO PC, JORNAL/EVENTOS E SISTEMA DE CONTAS ===")
	print("=================================================================\n")

	# 1. SETUP DE GERENCIADORES CENTRAIS
	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var econ = EconomyManager.new()
	root.add_child(econ)
	econ._ready()
	econ.current_money = 2000.0 # Saldo inicial para testes

	var clock = load("res://src/time/game_clock.gd").new()
	root.add_child(clock)
	clock._ready()
	clock.day_number = 1

	var dem = load("res://src/core/daily_event_manager.gd").new()
	root.add_child(dem)
	dem._ready()

	var fin = load("res://src/economy/finance_manager.gd").new()
	root.add_child(fin)
	fin._ready()

	var news_mgr = load("res://src/news/news_manager.gd").new()
	root.add_child(news_mgr)
	news_mgr._ready()

	# =========================================================================
	# TESTE 1: SOM DE CLIQUE NO PC
	# =========================================================================
	print("\n--- TESTE 1: Som de Clique no PC ---")
	var click_stream = SoundSynthesizer.get_stream("pc_ui_click")
	assert_test(click_stream != null, "SoundSynthesizer sintetiza o som 'pc_ui_click'")
	if click_stream:
		assert_test(click_stream.data.size() > 0, "Buffer de áudio do clique possui dados PCM (%d bytes)" % click_stream.data.size())
		assert_test(click_stream.mix_rate == 44100, "Taxa de amostragem de áudio é de 44.1kHz")

	var comp_scene = load("res://src/ui/computer_ui.tscn")
	var comp_ui: ComputerUI = comp_scene.instantiate() as ComputerUI
	root.add_child(comp_ui)
	comp_ui._ready()
	comp_ui.open()

	assert_test(comp_ui.visible == true, "Terminal PC abre e fica visível")
	assert_test(comp_ui.has_method("_play_ui_click"), "ComputerUI possui o método _play_ui_click implementado")

	# =========================================================================
	# TESTE 2: JORNAL / NOTÍCIAS (COM EVENTO, SEM EVENTO E NUNCA VAZIA)
	# =========================================================================
	print("\n--- TESTE 2: Aba de Notícias / Jornal da Cidade ---")
	# 2.1 Sem evento (Dia Normal)
	dem.current_event = DailyEventManager.EventType.NONE
	var normal_news = news_mgr.generate_daily_news(1)
	assert_test(not normal_news.is_empty(), "Dia sem evento: Jornal gera boletim informativo e não fica vazio (%d notícias)" % normal_news.size())
	assert_test(normal_news[0].get("title", "").contains("Boletim") or normal_news[0].get("title", "").contains("tranquilo"), "Boletim de dia normal informa situação regular: '%s'" % normal_news[0].get("title", ""))

	# 2.2 Com evento (Onda de Calor Extremo)
	dem.current_event = DailyEventManager.EventType.EXTREME_HEAT
	var event_news = news_mgr.generate_daily_news(2)
	assert_test(not event_news.is_empty(), "Dia com evento: Jornal gera artigo principal de alerta (%d notícias)" % event_news.size())
	assert_test(event_news[0].get("title", "").to_lower().contains("calor") or event_news[0].get("title", "").to_lower().contains("temperatura"), "Artigo do evento descreve o alerta corretamente: '%s'" % event_news[0].get("title", ""))

	# 2.3 Renderização na UI do PC
	comp_ui._refresh_news_tab()
	var news_count = comp_ui.news_content_vbox.get_child_count() if comp_ui.news_content_vbox else 0
	assert_test(news_count > 0, "Aba de Notícias no PC possui cards renderizados na tela (Cards: %d)" % news_count)

	# =========================================================================
	# TESTE 3: SISTEMA DE CONTAS (3 CATEGORIAS OBRIGATÓRIAS)
	# =========================================================================
	print("\n--- TESTE 3: Sistema de Contas (Energia, Água, Sala dos Funcionários) ---")
	var active_b = fin.get_active_bills()
	assert_test(active_b.has("electricity"), "Conta de Energia está presente no sistema")
	assert_test(active_b.has("water"), "Conta de Água está presente no sistema")
	assert_test(active_b.has("staff_room"), "Conta da Sala dos Funcionários está presente no sistema")

	var elec_val = fin.get_category_pending_amount("electricity")
	var water_val = fin.get_category_pending_amount("water")
	var staff_val = fin.get_category_pending_amount("staff_room")
	var total_initial_debt = fin.get_total_pending_debt()

	print("  -> Valores das contas geradas:")
	print("     - Energia: R$ %.2f" % elec_val)
	print("     - Água: R$ %.2f" % water_val)
	print("     - Sala dos Funcionários: R$ %.2f" % staff_val)
	print("     - Total Pendente: R$ %.2f" % total_initial_debt)

	assert_test(elec_val > 0.0, "Energia possui valor tarifado calculado")
	assert_test(water_val > 0.0, "Água possui valor tarifado calculado")
	assert_test(staff_val > 0.0, "Sala dos Funcionários possui valor operacional calculado")
	assert_test(is_equal_approx(total_initial_debt, elec_val + water_val + staff_val), "Total pendente inicial corresponde à soma das 3 categorias")

	# =========================================================================
	# TESTE 4: CONTAS ACUMULAM QUANDO NÃO PAGAS
	# =========================================================================
	print("\n--- TESTE 4: Acumulação de Contas Não Pagas ---")
	# Simula o encerramento do Dia 1 sem pagar
	fin.close_current_day()
	assert_test(fin.pending_bills.size() == 3, "Ao fechar o Dia 1 sem pagar, as 3 contas são movidas para pendências acumuladas (%d contas)" % fin.pending_bills.size())

	# Inicia o Dia 2
	clock.day_number = 2
	fin.start_new_day()

	var total_day_2 = fin.get_total_pending_debt()
	print("  -> Total pendente no Dia 2 (acumulado Dia 1 + Dia 2): R$ %.2f" % total_day_2)
	assert_test(total_day_2 > total_initial_debt, "Contas acumularam novo valor no Dia 2 (R$ %.2f > R$ %.2f)" % [total_day_2, total_initial_debt])

	# =========================================================================
	# TESTE 5: PAGAMENTO DE CONTAS COM DINHEIRO SUFICIENTE
	# =========================================================================
	print("\n--- TESTE 5: Pagamento de Contas no PC ---")
	econ.current_money = 1500.0
	var elec_pending_before = fin.get_category_pending_amount("electricity")
	var pay_res = fin.pay_bill("electricity")
	assert_test(pay_res.get("success", false) == true, "Pagamento da conta de Energia realizado com sucesso")
	assert_test(fin.get_category_pending_amount("electricity") == 0.0, "Dívida de Energia zerada após pagamento")
	assert_test(econ.current_money < 1500.0, "Saldo do jogador debitado após pagamento (Novo saldo: R$ %.2f)" % econ.current_money)

	# Quitação total das restantes
	var pay_all_res = fin.pay_all_bills()
	assert_test(pay_all_res.get("success", false) == true, "Quitação total de contas realizada com sucesso")
	assert_test(fin.get_total_pending_debt() == 0.0, "Todas as contas pendentes do restaurante zeradas")

	# =========================================================================
	# TESTE 6: PRAZO DE 7 DIAS E MULTA DE 25%
	# =========================================================================
	print("\n--- TESTE 6: Prazo de 7 Dias e Multa de 25% ---")
	fin.pending_bills.clear()
	# Cria uma conta pendente emitida no Dia 1 (vencimento Dia 8) no valor de R$ 1.000,00
	fin.pending_bills.append({
		"id": "elec_d1",
		"category": "electricity",
		"title": "Energia (Dia 1)",
		"amount": 1000.0,
		"original_amount": 1000.0,
		"day_issued": 1,
		"due_day": 8,
		"penalty_applied": false,
		"is_paid": false
	})

	# No Dia 7 (dentro do prazo), o valor ainda deve ser R$ 1.000,00 sem multa
	econ.current_money = 0.0 # Sem saldo para não debitar automaticamente
	fin._process_overdue_and_pending_bills(7)
	assert_test(fin.pending_bills[0]["amount"] == 1000.0, "Dia 7 (dentro do prazo): Conta permanece no valor original de R$ 1.000,00")
	assert_test(fin.pending_bills[0]["penalty_applied"] == false, "Dia 7: Nenhuma multa aplicada")

	# No Dia 8 (ao atingir 7 dias de atraso), aplica exatamente 25% de multa (R$ 1.000 -> R$ 1.250)
	fin._process_overdue_and_pending_bills(8)
	assert_test(fin.pending_bills[0]["amount"] == 1250.0, "Dia 8 (prazo atingido): Multa de 25%% aplicada com sucesso (R$ 1.000 -> R$ 1.250)")
	assert_test(fin.pending_bills[0]["penalty_applied"] == true, "Dia 8: Flag penalty_applied ativada")

	# =========================================================================
	# TESTE 7 & 8: SEM DINHEIRO NÃO CRASHA E JUROS NÃO DUPLICAM NOS DIAS SEGUINTES
	# =========================================================================
	print("\n--- TESTE 7 & 8: Falta de Dinheiro Segura e Juros Não-Duplicados ---")
	econ.current_money = 0.0

	# Dia 9
	fin._process_overdue_and_pending_bills(9)
	assert_test(fin.pending_bills[0]["amount"] == 1250.0, "Dia 9: Multa NÃO duplicada, valor permanece fixo em R$ 1.250,00")
	assert_test(econ.current_money >= 0.0, "Saldo do jogador não ficou negativo (R$ %.2f)" % econ.current_money)

	# Dia 10
	fin._process_overdue_and_pending_bills(10)
	assert_test(fin.pending_bills[0]["amount"] == 1250.0, "Dia 10: Multa NÃO duplicada em dias subsequentes")

	# Jogador ganha dinheiro no Dia 11 e o sistema realiza a cobrança automática
	econ.current_money = 2000.0
	fin._process_overdue_and_pending_bills(11)
	assert_test(fin.pending_bills.is_empty(), "Dia 11: Ao receber fundos, a cobrança pendente com juros é quitada automaticamente")
	assert_test(is_equal_approx(econ.current_money, 2000.0 - 1250.0), "Saldo debitado exatamente em R$ 1.250,00 (Novo saldo: R$ %.2f)" % econ.current_money)

	print("\n=================================================================")
	print("RESULTADO FINAL: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=================================================================\n")

	if passed_tests == total_tests:
		print(">>> SUCESSO TOTAL: SOM DO PC, JORNAL E CONTAS 100% VALIDADOS! <<<\n")
		quit(0)
	else:
		print(">>> FALHA NOS TESTES! <<<\n")
		quit(1)
