extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DE TRANSIÇÃO DE DIAS, PRESERVAÇÃO DE ITENS E RESUMO
# ==============================================================================

const SaveManagerClass = preload("res://src/core/save_manager.gd")
const GameManagerClass = preload("res://src/core/game_manager.gd")
const GameClockClass = preload("res://src/time/game_clock.gd")
const CalendarManagerClass = preload("res://src/core/calendar_manager.gd")
const EconomyManagerClass = preload("res://src/economy/economy_manager.gd")
const ReputationManagerClass = preload("res://src/customers/reputation_manager.gd")
const CustomerReviewClass = preload("res://src/customers/customer_review.gd")
const SauceBottleClass = preload("res://src/items/sauce_bottle.gd")
const ItemClass = preload("res://src/items/item.gd")

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
	print("=== BURGER RUSH - TRANSIÇÃO DE DIAS & PRESERVAÇÃO DE ESTADO =====")
	print("=================================================================")

	# --------------------------------------------------------------------------
	# PREPARAÇÃO DOS GERENCIADORES E CENA
	# --------------------------------------------------------------------------
	var sm = SaveManagerClass.new()
	sm.name = "SaveManager"
	root.add_child(sm)
	sm.active_slot = 1
	sm.has_active_game = true
	sm.pending_save_data = {
		"slot_id": 1,
		"chef_name": "Miller",
		"restaurant_name": "Burger Rush",
		"money": 250.0,
		"current_day": 1,
		"day": 1,
		"tutorial_completed": true,
		"day1_intro_shown": true
	}
	sm.save_game(1)

	var gm = GameManagerClass.new()
	gm.name = "GameManager"
	root.add_child(gm)

	var cal = CalendarManagerClass.new()
	cal.name = "CalendarManager"
	root.add_child(cal)
	cal.day_number = 1
	cal.day_of_week = 4

	var econ = EconomyManagerClass.new()
	econ.name = "EconomyManager"
	root.add_child(econ)
	econ.current_money = 250.0

	var rep_mgr = ReputationManagerClass.new()
	rep_mgr.name = "ReputationManager"
	root.add_child(rep_mgr)

	# Registra 2 avaliações no Dia 1: 1 cliente atendido com sucesso e 1 abandono por espera
	var r1 = CustomerReviewClass.new()
	r1.day = 1
	r1.stars = 5.0
	r1.abandoned = false
	rep_mgr.add_review(r1)

	var r2 = CustomerReviewClass.new()
	r2.day = 1
	r2.stars = 1.0
	r2.abandoned = true
	r2.abandon_reason = "Demora no atendimento da mesa"
	rep_mgr.add_review(r2)

	var clock = GameClockClass.new()
	clock.name = "GameClock"
	root.add_child(clock)
	clock.day_number = 1
	clock.current_hour = 10
	clock.current_minute = 0
	clock.state = GameClockClass.State.OPEN

	var hud_scene = load("res://src/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	root.add_child(hud)

	# --------------------------------------------------------------------------
	# TESTE 1: CRIAR E POSICIONAR ITENS E BISNAGA DE MOLHO NO RESTAURANTE
	# --------------------------------------------------------------------------
	print("\n--- TESTE 1: Posicionamento de Itens e Bisnagas no Cenário ---")
	var counter_patty = ItemClass.new()
	counter_patty.item_id = "patty_cooked"
	counter_patty.item_type = "patty"
	counter_patty.position = Vector3(2.5, 0.9, -1.2)
	root.add_child(counter_patty)

	var floor_fries = ItemClass.new()
	floor_fries.item_id = "french_fries"
	floor_fries.item_type = "fries"
	floor_fries.position = Vector3(-1.0, 0.05, 3.4)
	root.add_child(floor_fries)

	var sauce_rack = Node3D.new()
	sauce_rack.name = "SauceRack"
	sauce_rack.position = Vector3(0.0, 0.9, -2.0)
	root.add_child(sauce_rack)

	var sauce_bottle = SauceBottleClass.new()
	sauce_bottle.sauce_type = "ketchup"
	sauce_bottle.position = Vector3(0.1, 0.0, 0.0) # Posição relativa no rack
	sauce_rack.add_child(sauce_bottle)

	assert_test(counter_patty.position == Vector3(2.5, 0.9, -1.2), "Hambúrguer posicionado na bancada")
	assert_test(floor_fries.position == Vector3(-1.0, 0.05, 3.4), "Batata frita posicionada no chão")
	assert_test(sauce_bottle.get_parent() == sauce_rack, "Bisnaga de molho no suporte original")

	# Jogador pega a bisnaga de molho e a move para longe (ex: na mesa do salão)
	sauce_rack.remove_child(sauce_bottle)
	root.add_child(sauce_bottle)
	sauce_bottle.position = Vector3(5.0, 0.75, 4.0)
	assert_test(sauce_bottle.position == Vector3(5.0, 0.75, 4.0), "Bisnaga de molho movida para mesa distante")

	# --------------------------------------------------------------------------
	# TESTE 2: FECHAMENTO DO DIA E RESUMO COM CLIENTES QUE ABANDONARAM
	# --------------------------------------------------------------------------
	print("\n--- TESTE 2: Fechamento do Dia e Resumo de Abandonos ---")
	print("DEBUG rep_mgr instance: ", ReputationManagerClass.get_instance())
	print("DEBUG rep_mgr total_abandoned: ", rep_mgr.get_total_abandoned(), " daily(1): ", rep_mgr.get_daily_abandoned(1))
	var summary = clock.close_day()
	print("DEBUG summary.customers_abandoned: ", summary.customers_abandoned)
	assert_test(summary != null, "Resumo do Dia 1 gerado pelo GameClock")
	assert_test(summary.customers_abandoned == 1, "Resumo registrou exatamente 1 cliente que abandonou no Dia 1")

	# Envia evento de encerramento para o HUD
	hud._on_day_ended(summary)

	assert_test(hud.report_modal != null and hud.report_modal.visible == true, "Modal 'Dia Encerrado' exibido na tela")
	assert_test(hud.process_mode == Node.PROCESS_MODE_ALWAYS, "HUD configurado com process_mode ALWAYS para receber inputs mesmo pausado")
	assert_test(hud.report_modal.process_mode == Node.PROCESS_MODE_ALWAYS, "DayReportModal configurado com process_mode ALWAYS")
	assert_test(hud.report_completed != null, "Label de pedidos e abandonos presente")
	assert_test(hud.report_completed.text.contains("Abandono: 1 clientes"), "Texto do resumo exibe 'Abandono: 1 clientes' com precisão: '%s'" % hud.report_completed.text)
	assert_test(not hud.report_completed.text.contains("cancelados"), "Texto de 'cancelados' foi totalmente substituído pelo abandono")

	# --------------------------------------------------------------------------
	# TESTE 3: CLIQUE EM 'PRÓXIMO DIA' E TRANSIÇÃO IMEDIATA
	# --------------------------------------------------------------------------
	print("\n--- TESTE 3: Clique em 'Próximo Dia' e Início do Dia 2 ---")
	hud._on_next_day_button_pressed()

	assert_test(hud.report_modal.visible == false, "Modal de fechamento do dia fechado com sucesso")
	assert_test(paused == false, "Jogo despausado após avançar o dia")
	assert_test(clock.day_number == 2, "GameClock avançou com sucesso para o Dia 2")
	assert_test(clock.current_hour == 9 and clock.current_minute == 0, "Horário do Dia 2 iniciado pontualmente às 09:00")
	assert_test(clock.state == GameClockClass.State.PREPARATION, "Estado do restaurante reiniciado em PREPARATION")
	assert_test(clock.is_paused == false, "Relógio do jogo rodando normalmente")

	# --------------------------------------------------------------------------
	# TESTE 4: PRESERVAÇÃO DE OBJETOS DO RESTAURANTE & RETORNO DE MOLHO
	# --------------------------------------------------------------------------
	print("\n--- TESTE 4: Preservação de Objetos e Retorno da Bisnaga de Molho ---")
	assert_test(is_instance_valid(counter_patty), "Hambúrguer na bancada permanece instanciado no mundo")
	assert_test(counter_patty.position == Vector3(2.5, 0.9, -1.2), "Posição do hambúrguer na bancada 100% PRESERVADA")

	assert_test(is_instance_valid(floor_fries), "Batata frita no chão permanece instanciada no mundo")
	assert_test(floor_fries.position == Vector3(-1.0, 0.05, 3.4), "Posição da batata frita no chão 100% PRESERVADA")

	# A bisnaga de molho deve ser a ÚNICA a retornar para o suporte original
	assert_test(sauce_bottle.get_parent() == sauce_rack, "Bisnaga de molho retornou com sucesso para o suporte de molhos")
	assert_test(sauce_bottle.position == Vector3(0.1, 0.0, 0.0), "Posição da bisnaga restaurada no suporte")

	# --------------------------------------------------------------------------
	# TESTE 5: PERSISTÊNCIA NO SAVE SYSTEM
	# --------------------------------------------------------------------------
	print("\n--- TESTE 5: Persistência do Dia 2 no Disco ---")
	var active_sm = SaveManagerClass.get_instance()
	if not active_sm: active_sm = sm
	print("sm id: ", sm.get_instance_id(), " active_sm id: ", active_sm.get_instance_id())
	print("DEBUG sm.pending_save_data: ", sm.pending_save_data)
	print("DEBUG active_sm.pending_save_data: ", active_sm.pending_save_data)
	var loaded_disk = sm.load_game(1)
	print("DEBUG loaded_disk: ", loaded_disk.get("current_day"))
	assert_test(int(loaded_disk.get("current_day", 1)) == 2, "Save no disco gravou Dia 2 com sucesso")
	assert_test(int(active_sm.pending_save_data.get("clock_hour", 0)) == 9, "Save no disco gravou horário das 09:00")
	assert_test(str(active_sm.pending_save_data.get("clock_state", "")) == "PREPARATION", "Save no disco gravou PREPARATION")

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 FLUXO DO PRÓXIMO DIA, RESUMO E PRESERVAÇÃO 100% VALIDADOS!")
	else:
		print("❌ TESTE FALHOU!")

	# Limpeza
	counter_patty.queue_free()
	floor_fries.queue_free()
	sauce_bottle.queue_free()
	sauce_rack.queue_free()
	hud.queue_free()
	clock.queue_free()
	rep_mgr.queue_free()
	econ.queue_free()
	cal.queue_free()
	gm.queue_free()
	sm.queue_free()

	quit(0 if failed == 0 else 1)
