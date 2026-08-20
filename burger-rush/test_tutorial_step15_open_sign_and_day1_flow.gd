extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DA ETAPA 15 (ABERTURA DA PLACA) E TRANSIÇÃO DIA 1
# ==============================================================================

const TutorialController = preload("res://src/ui/tutorial.gd")
const SaveManager = preload("res://src/core/save_manager.gd")
const GameManager = preload("res://src/core/game_manager.gd")
const GameClock = preload("res://src/time/game_clock.gd")
const OpenSign = preload("res://src/stations/open_sign.gd")
const Player = preload("res://src/player/player.gd")
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
	print("=== BURGER RUSH - TESTE DA ETAPA 15 E TRANSIÇÃO PARA DIA 1 ===")
	print("=================================================================")

	# 1. Configuração dos Gerenciadores
	var sm = SaveManager.get_instance()
	if not sm:
		if root.has_node("SaveManager"):
			sm = root.get_node("SaveManager")
		else:
			sm = SaveManager.new()
			sm.name = "SaveManager"
			root.add_child(sm)
	sm.create_new_career(1, "Rodrigo")
	sm.load_game(1)

	var gm = GameManager.get_instance()
	if not gm:
		if root.has_node("GameManager"):
			gm = root.get_node("GameManager")
		else:
			gm = GameManager.new()
			gm.name = "GameManager"
			root.add_child(gm)

	var clock = GameClock.new()
	clock.name = "GameClock"
	clock.current_hour = 9
	clock.current_minute = 0
	clock.state = GameClock.State.PREPARATION
	root.add_child(clock)

	var player_res = load("res://src/player/player.tscn")
	var player = player_res.instantiate() as Player
	root.add_child(player)

	var open_sign_res = load("res://src/stations/open_sign.tscn")
	var open_sign = open_sign_res.instantiate() as OpenSign
	root.add_child(open_sign)

	var tut_res = load("res://src/ui/tutorial.tscn")
	var tut = tut_res.instantiate() as TutorialController
	root.add_child(tut)

	# --- TESTE 1: Interação com a Placa e Abertura do Restaurante na Etapa 15 ---
	print("\n--- TESTE 1: Interação com a Placa de Abertura (Etapa 15) ---")
	tut._apply_step(14)
	assert_test(tut.current_step_index == 14, "Tutorial posicionado na Etapa 15 (Placa de Abertura)")
	assert_test(clock.state == GameClock.State.PREPARATION, "Restaurante inicia em PREPARATION")

	# Jogador interage com a Placa de Abertura normalmente
	open_sign.interact(player)

	# Verifica se o tutorial detectou a abertura real e concluiu sem travar
	assert_test(tut.step_open_sign_interacted == true, "Tutorial registrou abertura real da placa sem exigir 2ª interação")
	assert_test(tut.tutorial_completed == true, "Tutorial foi concluído automaticamente com sucesso")
	assert_test(tut.congrats_panel != null and tut.congrats_panel.visible == true, "Tela de parabéns e conclusão do treinamento está visível")
	assert_test(tut.start_day_button != null and tut.start_day_button.text == "COMEÇAR DIA 1", "Botão 'COMEÇAR DIA 1' visível na tela de conclusão")

	# --- TESTE 2: Conclusão do Treinamento e Início do Dia 1 ---
	print("\n--- TESTE 2: Conclusão e Persistência para o Dia 1 ---")
	tut._on_start_day_pressed()

	assert_test(sm.pending_save_data.get("tutorial_completed") == true, "Save persistiu tutorial_completed = true")
	assert_test(sm.pending_save_data.get("day1_intro_shown") == false, "Save configurou day1_intro_shown = false")
	assert_test(sm.pending_save_data.get("day_number") == 1, "Save configurou dia 1")
	assert_test(sm.pending_save_data.get("clock_hour") == 9, "Save configurou horário exatamente às 09:00")
	assert_test(sm.pending_save_data.get("clock_state") == "PREPARATION", "Save configurou período de PREPARATION")

	# --- TESTE 3: Cena do Dia 1 e Modal 'SEU PRIMEIRO DIA' ---
	print("\n--- TESTE 3: Mensagem Especial 'SEU PRIMEIRO DIA' ---")
	var hud_res = load("res://src/ui/hud.tscn")
	var hud = hud_res.instantiate() as HUD
	root.add_child(hud)

	# Simula o _ready do HUD
	hud._check_and_show_day1_intro()

	assert_test(hud.day1_welcome_modal != null and hud.day1_welcome_modal.visible == true, "Modal do Primeiro Dia está visível na tela")
	assert_test(hud.day1_title_label != null and hud.day1_title_label.text == "SEU PRIMEIRO DIA", "Título da mensagem é 'SEU PRIMEIRO DIA'")
	assert_test(hud.day1_body_label != null and hud.day1_body_label.text.contains("Chefe Rodrigo, agora é pra valer."), "Mensagem contém o nome salvo do chefe ('Chefe Rodrigo, agora é pra valer.')")
	assert_test(hud.day1_body_label.text.contains("Boa sorte. O seu primeiro dia começa agora!"), "Mensagem contém 'Boa sorte. O seu primeiro dia começa agora!'")
	assert_test(hud.day1_start_button != null and hud.day1_start_button.text == "COMEÇAR DIA 1", "Botão tem o texto 'COMEÇAR DIA 1'")

	# Confirmação do modal
	hud._on_day1_start_button_pressed()
	assert_test(hud.day1_welcome_modal.visible == false, "Modal fecha após a confirmação")
	assert_test(sm.pending_save_data.get("day1_intro_shown") == true, "Flag day1_intro_shown salva como true para não repetir")

	# Cleanup
	hud.queue_free()
	tut.queue_free()
	open_sign.queue_free()
	player.queue_free()
	clock.queue_free()
	gm.queue_free()
	sm.queue_free()

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 FLUXO DE ABERTURA DA ETAPA 15 E TRANSIÇÃO DIA 1 VALIDADOS COM 100% DE SUCESSO!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)
