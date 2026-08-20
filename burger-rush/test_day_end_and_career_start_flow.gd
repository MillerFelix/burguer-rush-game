extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DO FLUXO DE ENCERRAMENTO DO DIA E INÍCIO DE CARREIRA
# ==============================================================================

const GameManager = preload("res://src/core/game_manager.gd")
const SaveManager = preload("res://src/core/save_manager.gd")
const GameClock = preload("res://src/time/game_clock.gd")
const CalendarManager = preload("res://src/core/calendar_manager.gd")
const EconomyManager = preload("res://src/economy/economy_manager.gd")
const ReputationManager = preload("res://src/customers/reputation_manager.gd")
const DaySummary = preload("res://src/time/day_summary.gd")
const HUD = preload("res://src/ui/hud.gd")

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
	print("=== BURGER RUSH - TESTE DE ENCERRAMENTO DO DIA E INÍCIO DOS DIAS ===")
	print("=================================================================")

	var sm = SaveManager.new()
	sm.name = "SaveManager"
	root.add_child(sm)
	sm.create_new_career(1, "Felix")
	sm.load_game(1)

	var gm = GameManager.new()
	gm.name = "GameManager"
	root.add_child(gm)

	var cal = CalendarManager.new()
	cal.name = "CalendarManager"
	cal.day_number = 1
	cal.day_of_week = 4 # Quinta
	root.add_child(cal)

	var eco = EconomyManager.new()
	eco.name = "EconomyManager"
	eco.current_money = 150.0
	root.add_child(eco)

	var rep = ReputationManager.new()
	rep.name = "ReputationManager"
	root.add_child(rep)

	var clock = GameClock.new()
	clock.name = "GameClock"
	clock.day_number = 1
	clock.day_of_week = 4
	clock.week_number = 1
	clock.current_hour = 9
	clock.current_minute = 0
	root.add_child(clock)

	var hud_res = load("res://src/ui/hud.tscn")
	var hud = hud_res.instantiate() as HUD
	root.add_child(hud)

	# --- TESTE 1: Mensagem Especial de Início da Carreira (Primeiro Dia) ---
	print("\n--- TESTE 1: Apresentação do Primeiro Dia ('AGORA É PRA VALER!') ---")
	sm.pending_save_data["tutorial_completed"] = true
	sm.pending_save_data["day1_intro_shown"] = false
	hud._check_and_show_day1_intro()

	assert_test(hud.day1_welcome_modal != null, "Modal do Primeiro Dia presente no HUD")
	assert_test(hud.day1_welcome_modal.visible == true, "Modal do Primeiro Dia visível na tela")
	assert_test(hud.day1_title_label.text == "SEU PRIMEIRO DIA", "Título é 'SEU PRIMEIRO DIA'")
	assert_test(hud.day1_body_label.text.contains("Chefe Felix, agora é pra valer.") and hud.day1_body_label.text.contains("Boa sorte. O seu primeiro dia começa agora!"), "Corpo contém a mensagem completa e personalizada")
	assert_test(hud.day1_start_button.text == "COMEÇAR DIA 1", "Botão tem o texto 'COMEÇAR DIA 1'")

	# Confirma início do primeiro dia
	hud._on_day1_start_button_pressed()
	assert_test(hud.day1_welcome_modal.visible == false, "Modal fecha após confirmação")
	assert_test(sm.pending_save_data.get("day1_intro_shown") == true, "Flag day1_intro_shown salva como true")

	# --- TESTE 2: Encerramento do Dia (Dia 1) ---
	print("\n--- TESTE 2: Tela Grande de 'DIA ENCERRADO' e Resumo Financeiro ---")
	var summary = DaySummary.new()
	summary.day_number = 1
	summary.starting_balance = 100.0
	summary.revenue = 250.0
	summary.purchases = 50.0
	summary.net_profit = 200.0
	summary.orders_completed = 10
	summary.orders_cancelled = 1
	summary.total_orders = 11
	summary.avg_wait_time = 14.5
	summary.ending_balance = 300.0
	summary.reputation = 4.8

	# Simula disparo de fechamento do dia pelo GameClock
	clock.close_day()
	assert_test(clock.is_paused == true, "GameClock pausado no encerramento do dia")

	hud._on_day_ended(summary)
	assert_test(hud.report_modal.visible == true, "Tela de DIA ENCERRADO aberta e visível")
	assert_test(hud.report_title.text.contains("DIA 1 ENCERRADO"), "Título mostra claramente o Dia 1 encerrado")
	assert_test(hud.report_starting_balance.text.contains("100.00"), "Dinheiro inicial exibido corretamente")
	assert_test(hud.report_revenue.text.contains("250.00"), "Vendas do dia exibidas")
	assert_test(hud.report_purchases.text.contains("50.00"), "Despesas exibidas")
	assert_test(hud.report_net_profit.text.contains("200.00"), "Lucro líquido exibido")
	assert_test(hud.report_completed.text.contains("10 concluídos"), "Pedidos atendidos exibidos")
	assert_test(hud.report_reputation.text.contains("4.8"), "Reputação exibida")
	assert_test(hud.report_balance.text.contains("300.00"), "Dinheiro final exibido")

	# --- TESTE 3: Avanço para o Próximo Dia (09:00 e Loading Screen) ---
	print("\n--- TESTE 3: Próximo Dia com Salvamento, Avanço do Calendário e 09:00 ---")
	hud._on_next_day_button_pressed()

	assert_test(sm.pending_save_data.get("current_day") == 2, "Save avançou para o Dia 2")
	assert_test(sm.pending_save_data.get("day_of_week") == 5, "Dia da semana avançou para Sexta (5)")
	assert_test(sm.pending_save_data.get("clock_hour") == 9 and sm.pending_save_data.get("clock_minute") == 0, "Novo dia agendado para começar às 09:00")
	assert_test(sm.pending_save_data.get("clock_state") == "PREPARATION", "Período agendado como PREPARATION")
	assert_test(gm.pending_target_scene == "res://src/main.tscn", "Transição via Loading Screen acionada para main.tscn")

	# Aplica o save no jogo simulando carregamento da cena principal
	sm.apply_save_data_to_game(sm.pending_save_data)
	assert_test(cal.day_number == 2, "CalendarManager atualizado para o Dia 2")
	assert_test(cal.day_of_week == 5, "CalendarManager dia da semana é Sexta-feira")
	assert_test(clock.day_number == 2, "GameClock atualizado para o Dia 2")
	assert_test(clock.current_hour == 9 and clock.current_minute == 0, "GameClock iniciando pontualmente às 09:00")
	assert_test(clock.is_paused == false, "GameClock despausado para gameplay")

	hud.queue_free()
	clock.queue_free()
	rep.queue_free()
	eco.queue_free()
	cal.queue_free()
	gm.queue_free()
	sm.queue_free()

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 FLUXO DE ENCERRAMENTO E INÍCIO DOS DIAS VALIDADO COM 100% DE SUCESSO!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)
