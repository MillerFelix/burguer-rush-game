extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DE TRANSIÇÃO DO TUTORIAL PARA O DIA 1 VIA LOADING SCREEN
# ==============================================================================

const GameManager = preload("res://src/core/game_manager.gd")
const SaveManager = preload("res://src/core/save_manager.gd")
const GameClock = preload("res://src/time/game_clock.gd")
const TutorialController = preload("res://src/ui/tutorial.gd")
const PauseMenu = preload("res://src/ui/pause_menu.gd")
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
	print("=== BURGER RUSH - TESTE DE TRANSIÇÃO TUTORIAL -> DIA 1 (v0.1.8) ===")
	print("=================================================================")

	var sm = SaveManager.new()
	sm.name = "SaveManager"
	root.add_child(sm)
	sm.create_new_career(1, "Miller")
	sm.load_game(1)

	var gm = GameManager.new()
	gm.name = "GameManager"
	root.add_child(gm)

	# --- TESTE 1: Fluxo de Conclusão Normal do Tutorial ---
	print("\n--- TESTE 1: Conclusão Normal do Tutorial e Transição para Loading Screen ---")
	var tut_scene_res = load("res://src/ui/tutorial.tscn")
	var tut = tut_scene_res.instantiate() as TutorialController
	root.add_child(tut)

	# Conclui todas as etapas
	tut._complete_tutorial()
	assert_test(tut.tutorial_completed == true, "Tutorial marcado como completo")
	
	# Jogador clica no botão 'COMEÇAR DIA 1'
	tut._on_start_day_pressed()
	assert_test(sm.pending_save_data.get("tutorial_completed") == true, "Save persistiu tutorial_completed = true")
	assert_test(sm.pending_save_data.get("day1_intro_shown") == false, "Save configurou day1_intro_shown = false para disparar mensagem")
	assert_test(sm.pending_save_data.get("clock_hour") == 9 and sm.pending_save_data.get("clock_minute") == 0, "Save configurou relógio pontualmente para as 09:00")
	assert_test(sm.pending_save_data.get("clock_state") == "PREPARATION", "Save configurou período de PREPARATION")
	assert_test(gm.pending_target_scene == "res://src/main.tscn", "GameManager direcionou destino da Loading Screen para res://src/main.tscn")
	assert_test(gm.pending_target_state == GameManager.GameState.PLAYING, "GameManager configurou estado alvo como PLAYING")

	tut.queue_free()

	# --- TESTE 2: Carregamento do Dia 1 e Exibição da Mensagem de Introdução ---
	print("\n--- TESTE 2: Cena do Dia 1 e Mensagem 'PRIMEIRO DIA' ---")
	var main_scene_res = load("res://src/main.tscn")
	var main_scene = main_scene_res.instantiate()
	root.add_child(main_scene)

	var hud = main_scene.find_child("HUD", true, false) as HUD
	assert_test(hud != null, "HUD instanciado na cena do Dia 1")
	assert_test(hud.day1_welcome_modal != null, "Modal de boas-vindas do Dia 1 presente no HUD")
	assert_test(hud.day1_welcome_modal.visible == true, "Modal do Primeiro Dia visível na tela")
	assert_test(hud.day1_title_label.text == "SEU PRIMEIRO DIA", "Título da mensagem é 'SEU PRIMEIRO DIA'")
	assert_test(hud.day1_body_label.text.contains("Chefe Miller, agora é pra valer.") and hud.day1_body_label.text.contains("Boa sorte. O seu primeiro dia começa agora!"), "Corpo da mensagem contém 'Chefe [nome]' e 'Boa sorte. O seu primeiro dia começa agora!'")

	# Confirma a mensagem do primeiro dia
	hud._on_day1_start_button_pressed()
	assert_test(hud.day1_welcome_modal.visible == false, "Modal fechado após confirmação do jogador")
	assert_test(sm.pending_save_data.get("day1_intro_shown") == true, "Flag day1_intro_shown salva como true para não repetir")
	assert_test(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or DisplayServer.get_name() == "headless", "Mouse capturado e gameplay 100% liberado")

	main_scene.queue_free()

	# --- TESTE 3: Fluxo de Pular Tutorial pelo Menu de Pausa ---
	print("\n--- TESTE 3: Pular Tutorial pelo Menu de Pausa e Transição para Loading Screen ---")
	sm.create_new_career(2, "Miller")
	sm.load_game(2)
	var pause_menu_res = load("res://src/ui/pause_menu.tscn")
	var pause_menu = pause_menu_res.instantiate() as PauseMenu
	root.add_child(pause_menu)

	var tut2 = tut_scene_res.instantiate() as TutorialController
	root.add_child(tut2)

	pause_menu.pause_game()
	pause_menu._on_skip_tutorial_pressed()
	pause_menu._on_confirm_ok_pressed()

	assert_test(sm.pending_save_data.get("tutorial_completed") == true, "Ao pular tutorial, tutorial_completed = true")
	assert_test(sm.pending_save_data.get("day1_intro_shown") == false, "Ao pular tutorial, day1_intro_shown = false")
	assert_test(sm.pending_save_data.get("clock_hour") == 9 and sm.pending_save_data.get("clock_minute") == 0, "Ao pular tutorial, horário configurado para 09:00")
	assert_test(gm.pending_target_scene == "res://src/main.tscn", "Pular tutorial transita para a Loading Screen com destino main.tscn")

	pause_menu.queue_free()
	if is_instance_valid(tut2):
		tut2.queue_free()

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 FLUXO DE TRANSIÇÃO DO TUTORIAL VALIDADO COM 100% DE SUCESSO!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)
