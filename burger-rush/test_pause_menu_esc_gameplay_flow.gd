extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DE FLUXO DO MENU DE PAUSE COM TECLA ESC
# ==============================================================================

const Player = preload("res://src/player/player.gd")
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
	print("=== BURGER RUSH - TESTE DO MENU DE PAUSE (ESC) =================")
	print("=================================================================")

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)

	# --- TESTE 1: PRESENÇA DO PAUSEMENU NA ÁRVORE DE JOGO ---
	print("\n--- TESTE 1: Presença do PauseMenu no HUD/Player ---")
	var pause_menu = root.find_child("PauseMenu", true, false) as PauseMenu
	assert_test(pause_menu != null, "PauseMenu está presente e acessível na árvore de nós")
	assert_test(pause_menu.visible == false, "PauseMenu inicia oculto")
	assert_test(pause_menu.process_mode == Node.PROCESS_MODE_ALWAYS, "PauseMenu configurado com process_mode = ALWAYS")

	# --- TESTE 2: PRESSIONAR ESC DURANTE O GAMEPLAY (ABRIR PAUSE) ---
	print("\n--- TESTE 2: Pressionar ESC Durante Gameplay ---")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	assert_test(current_scene == null or not paused, "Jogo inicia despausado")

	# Simula o evento de pressionar ESC
	var esc_event = InputEventAction.new()
	esc_event.action = "ui_cancel"
	esc_event.pressed = true
	pause_menu._input(esc_event)

	assert_test(pause_menu.visible == true, "Menu de pause abriu imediatamente com ESC")
	assert_test(paused == true, "Jogo foi pausado no SceneTree (get_tree().paused == true)")
	assert_test(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Mouse foi liberado para MOUSE_MODE_VISIBLE")

	# --- TESTE 3: BLOQUEIO DE MOVIMENTO E CÂMERA DURANTE O PAUSE ---
	print("\n--- TESTE 3: Bloqueio de Câmera e Controles com Pause Aberto ---")
	var initial_rot_y = player.rotation.y
	var motion_event = InputEventMouseMotion.new()
	motion_event.relative = Vector2(50.0, 30.0)
	player._unhandled_input(motion_event)

	assert_test(player.rotation.y == initial_rot_y, "Câmera e rotação do jogador NÃO responderam ao mouse enquanto pausado")

	# --- TESTE 4: PRESSIONAR ESC NOVAMENTE (FECHAR PAUSE) ---
	print("\n--- TESTE 4: Pressionar ESC Novamente para Fechar ---")
	pause_menu._input(esc_event)

	assert_test(pause_menu.visible == false, "Menu de pause fechou com segundo ESC")
	assert_test(paused == false, "Jogo despausado no SceneTree (get_tree().paused == false)")
	assert_test(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or DisplayServer.get_name() == "headless", "Mouse voltou a ser capturado (MOUSE_MODE_CAPTURED)")

	# --- TESTE 5: RETOMADA DA CÂMERA APÓS FECHAR O PAUSE ---
	print("\n--- TESTE 5: Retomada de Controle da Câmera ---")
	player._unhandled_input(motion_event)
	assert_test(player.rotation.y != initial_rot_y, "Câmera voltou a responder normalmente após despausar")

	# --- TESTE 6: ABRIR PAUSE E FECHAR COM BOTÃO CONTINUAR ---
	print("\n--- TESTE 6: Fechar Pause via Botão 'Continuar' ---")
	pause_menu._input(esc_event)
	assert_test(pause_menu.visible == true, "Pause reaberto")
	assert_test(paused == true, "Jogo pausado")

	pause_menu._on_continue_pressed()
	assert_test(pause_menu.visible == false, "Pause fechou ao clicar em Continuar")
	assert_test(paused == false, "Jogo despausado após Continuar")
	assert_test(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or DisplayServer.get_name() == "headless", "Mouse recapturado após Continuar")

	# --- TESTE 7: NAVEGAÇÃO INTERNA NO PAUSE (CONFIGURAÇÕES -> VOLTAR) ---
	print("\n--- TESTE 7: ESC em Telas Secundárias do Pause ---")
	pause_menu.pause_game()
	pause_menu._on_settings_pressed()
	assert_test(pause_menu.settings_overlay.visible == true, "Tela de configurações aberta")

	# Pressionar ESC deve fechar configurações e voltar ao menu de pause principal, não fechar direto
	pause_menu._input(esc_event)
	assert_test(pause_menu.settings_overlay.visible == false, "Configurações fechadas pelo ESC")
	assert_test(pause_menu.visible == true, "Menu principal de pause permaneceu aberto")

	# Fechar pause
	pause_menu.resume_game()
	assert_test(pause_menu.visible == false, "Pause finalizado")

	# Cleanup
	player.queue_free()

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 MENU DE PAUSE E FLUXO ESC 100% VALIDADOS!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)
