extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DO SAVE IMEDIATO, BLOQUEIO DE GAMEPLAY E AUTOSAVE 5 MIN
# ==============================================================================

const SaveManager = preload("res://src/core/save_manager.gd")
const GameManager = preload("res://src/core/game_manager.gd")
const CalendarManager = preload("res://src/core/calendar_manager.gd")
const EconomyManager = preload("res://src/economy/economy_manager.gd")
const ReputationManager = preload("res://src/customers/reputation_manager.gd")
const GameClock = preload("res://src/time/game_clock.gd")
const DaySummary = preload("res://src/time/day_summary.gd")
const HUD = preload("res://src/ui/hud.gd")
const PauseMenu = preload("res://src/ui/pause_menu.gd")

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
	print("=== BURGER RUSH - TESTE DE SAVE IMEDIATO, BLOQUEIO & AUTOSAVE ===")
	print("=================================================================")

	var test_dir = "user://saves_test_day_end_suite"
	_cleanup_test_dir(test_dir)

	var sm = SaveManager.get_instance()
	if not sm:
		if root.has_node("SaveManager"):
			sm = root.get_node("SaveManager")
		else:
			sm = SaveManager.new()
			sm.name = "SaveManager"
			root.add_child(sm)
	sm.set_custom_save_dir(test_dir)

	var gm = GameManager.get_instance()
	if not gm:
		if root.has_node("GameManager"):
			gm = root.get_node("GameManager")
		else:
			gm = GameManager.new()
			gm.name = "GameManager"
			root.add_child(gm)
	gm.change_state(GameManager.GameState.PLAYING)

	var cal = CalendarManager.get_instance()
	if not cal:
		if root.has_node("CalendarManager"):
			cal = root.get_node("CalendarManager")
		else:
			cal = CalendarManager.new()
			cal.name = "CalendarManager"
			root.add_child(cal)
	cal.day_number = 1
	cal.day_of_week = 4

	var eco = EconomyManager.get_instance()
	if not eco:
		if root.has_node("EconomyManager"):
			eco = root.get_node("EconomyManager")
		else:
			eco = EconomyManager.new()
			eco.name = "EconomyManager"
			root.add_child(eco)
	eco.current_money = 150.0

	var rep = ReputationManager.get_instance()
	if not rep:
		if root.has_node("ReputationManager"):
			rep = root.get_node("ReputationManager")
		else:
			rep = ReputationManager.new()
			rep.name = "ReputationManager"
			root.add_child(rep)

	var clock = GameClock.get_instance()
	if not clock:
		if root.has_node("GameClock"):
			clock = root.get_node("GameClock")
		else:
			clock = GameClock.new()
			clock.name = "GameClock"
			root.add_child(clock)
	clock.day_number = 1
	clock.start_hour = 9
	clock.start_minute = 0
	clock.current_hour = 9
	clock.current_minute = 0
	clock.state = GameClock.State.PREPARATION
	clock.is_paused = false

	var hud_res = load("res://src/ui/hud.tscn")
	var hud = hud_res.instantiate()
	root.add_child(hud)

	var pause_menu_res = load("res://src/ui/pause_menu.tscn")
	var pause_menu = pause_menu_res.instantiate()
	root.add_child(pause_menu)

	# Inicializa carreira no Slot 1
	sm.create_new_career(1, "Chef Miller")
	sm.pending_save_data["tutorial_completed"] = true
	sm.save_game(1)
	sm.load_game(1)
	assert_test(sm.has_active_game == true, "Carreira ativa no Slot 1")

	# --- TESTE 1: AUTOSAVE DE 5 MINUTOS (300 SEGUNDOS) ---
	print("\n--- TESTE 1: Sistema de Auto-Save (5 Minutos) ---")
	sm._auto_save_timer = 299.0
	eco.current_money = 175.50
	sm._process(1.5) # Ultrapassa 300 segundos
	assert_test(sm._auto_save_timer < 1.0, "Timer de auto-save foi reiniciado após o disparo")
	
	# Verifica que o arquivo no disco foi atualizado pelo auto-save
	var disk_data_mid = sm.load_game(1)
	assert_test(disk_data_mid.get("money") == 175.50, "Auto-save de 5 minutos persistiu R$ 175.50 no disco")

	# --- TESTE 2: SAVE IMEDIATO AO ENCERRAR O DIA (ANTES DE QUALQUER TRANSIÇÃO) ---
	print("\n--- TESTE 2: Save Imediato no Encerramento do Dia ---")
	eco.current_money = 350.0

	# O relógio encerra o dia (22:00 / close_day)
	var summary = clock.close_day()
	assert_test(clock.state == GameClock.State.CLOSED, "Restaurante fechado com sucesso")
	assert_test(clock.is_paused == true, "Relógio pausado no final do dia")

	# Valida que o save em disco foi gravado IMEDIATAMENTE na chamada close_day
	var disk_data_end = sm.load_game(1)
	assert_test(disk_data_end.get("current_day") == 1, "Save no disco gravou Dia 1 imediatamente")
	assert_test(disk_data_end.get("money") == summary.ending_balance, "Save no disco gravou saldo final do dia imediatamente")
	assert_test(disk_data_end.get("tutorial_completed") == true, "Progresso do tutorial/carreira preservado")

	# --- TESTE 3: BLOQUEIO DE GAMEPLAY NA TELA 'DIA ENCERRADO' ---
	print("\n--- TESTE 3: Bloqueio de Gameplay e Inputs na Tela 'Dia Encerrado' ---")
	# Exibe o modal do dia encerrado no HUD
	hud._on_day_ended(summary)
	assert_test(hud.report_modal != null and hud.report_modal.visible == true, "Modal 'Dia Encerrado' está visível na tela")
	assert_test(paused == true, "Árvore de nós (get_tree().paused) está pausada")
	assert_test(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Cursor do mouse liberado para interação na tela de resumo")

	# Simula envio de teclas de interação, pulo, ferramentas
	var key_event = InputEventKey.new()
	key_event.pressed = true
	key_event.keycode = KEY_SPACE
	hud._unhandled_input(key_event)
	assert_test(hud.report_modal.visible == true, "Pressionar Espaço NÃO fechou nem avançou a tela")

	key_event.keycode = KEY_E
	hud._unhandled_input(key_event)
	assert_test(hud.report_modal.visible == true, "Pressionar E NÃO reiniciou nem avançou o dia")

	# Simula ESC para tentar abrir o menu de pausa por trás
	key_event.keycode = KEY_ESCAPE
	pause_menu._input(key_event)
	assert_test(pause_menu.visible == false, "ESC NÃO abriu o menu de pausa por trás da tela de Dia Encerrado")

	# --- TESTE 4: AVANÇAR PARA O PRÓXIMO DIA AO CLICAR NO BOTÃO ---
	print("\n--- TESTE 4: Avançar para o Próximo Dia (Dia 2) ---")
	hud._on_next_day_button_pressed()
	assert_test(hud.report_modal.visible == false, "Modal de Dia Encerrado fechado após clicar em Próximo Dia")
	assert_test(paused == false, "Gameplay despausado para a transição")

	# Valida que o save foi atualizado para o Dia 2 às 09:00 PREPARATION
	var disk_data_day2 = sm.load_game(1)
	assert_test(disk_data_day2.get("current_day") == 2, "Save no disco atualizado para o Dia 2")
	assert_test(disk_data_day2.get("clock_hour") == 9, "Horário do Dia 2 salvo exatamente às 09:00")
	assert_test(disk_data_day2.get("clock_state") == "PREPARATION", "Estado inicial do Dia 2 salvo como PREPARATION")

	# Cleanup
	hud.queue_free()
	pause_menu.queue_free()
	_cleanup_test_dir(test_dir)
	sm.set_custom_save_dir("")

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 SAVE IMEDIATO, BLOQUEIO DE GAMEPLAY E AUTOSAVE 100% VALIDADOS!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)

func _cleanup_test_dir(dir_path: String) -> void:
	if DirAccess.dir_exists_absolute(dir_path):
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var fn = dir.get_next()
			while fn != "":
				if not dir.current_is_dir():
					DirAccess.remove_absolute("%s/%s" % [dir_path, fn])
				fn = dir.get_next()
			dir.list_dir_end()
		DirAccess.remove_absolute(dir_path)
