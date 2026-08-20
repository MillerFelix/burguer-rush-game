extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DE RESTAURAÇÃO DE INPUT, CÂMERA, MOUSE E PAUSE NO DIA 1
# ==============================================================================

const SaveManager = preload("res://src/core/save_manager.gd")
const GameManager = preload("res://src/core/game_manager.gd")
const Player = preload("res://src/player/player.gd")
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
	print("=== BURGER RUSH - TESTE DE INPUT, CÂMERA E PAUSE NO DIA 1 =======")
	print("=================================================================")

	var test_dir = "user://saves_test_day1_input"
	_cleanup_test_dir(test_dir)

	var sm = SaveManager.get_instance()
	if not sm:
		sm = SaveManager.new()
		sm.name = "SaveManager"
		root.add_child(sm)
	sm.set_custom_save_dir(test_dir)

	var gm = GameManager.get_instance()
	if not gm:
		gm = GameManager.new()
		gm.name = "GameManager"
		root.add_child(gm)

	var player_res = load("res://src/player/player.tscn")
	var player = player_res.instantiate()
	root.add_child(player)

	var hud = player.get_node_or_null("HUD")
	if not hud:
		var hud_res = load("res://src/ui/hud.tscn")
		hud = hud_res.instantiate()
		root.add_child(hud)

	var pause_menu_res = load("res://src/ui/pause_menu.tscn")
	var pause_menu = pause_menu_res.instantiate()
	root.add_child(pause_menu)

	# --- ETAPA 1 & 2: INICIAR JOGO E CONCLUIR/PULAR TUTORIAL ---
	print("\n--- ETAPA 1 & 2: Início e Pular/Concluir Tutorial ---")
	sm.create_new_career(1, "Chef Miller")
	sm.pending_save_data["tutorial_completed"] = true
	sm.pending_save_data["day1_intro_shown"] = false
	sm.save_game(1)
	sm.load_game(1)

	gm.change_state(GameManager.GameState.PLAYING)
	assert_test(sm.has_active_game == true, "Carreira ativa no Slot 1")
	assert_test(sm.pending_save_data.get("tutorial_completed") == true, "Tutorial marcado como concluído")

	# --- ETAPA 3: ENTRAR NO DIA 1 E CONFIRMAR INTRODUÇÃO ---
	print("\n--- ETAPA 3: Introdução do Dia 1 e Confirmação ---")
	hud._check_and_show_day1_intro()
	assert_test(hud.day1_welcome_modal.visible == true, "Modal do Primeiro Dia exibido na entrada do Dia 1")
	assert_test(hud.day1_body_label.text.contains("Chefe Miller, agora é pra valer."), "Mensagem de boas-vindas personalizada para Chef Miller")

	# Confirma início do Dia 1
	hud._on_day1_start_button_pressed()
	assert_test(hud.day1_welcome_modal.visible == false, "Modal do Primeiro Dia fechado após confirmação")
	assert_test(gm.current_state == GameManager.GameState.PLAYING, "GameManager restaurado para GameState.PLAYING")

	# --- ETAPA 4: MOVER O MOUSE E CONFIRMAR QUE A CÂMERA RESPONDE ---
	print("\n--- ETAPA 4: Movimentação do Mouse e Resposta da Câmera ---")
	var initial_player_rot_y = player.rotation.y
	var initial_head_rot_x = player.head.rotation.x

	var mouse_event = InputEventMouseMotion.new()
	mouse_event.relative = Vector2(25.0, 15.0)
	player._unhandled_input(mouse_event)

	assert_test(player.rotation.y != initial_player_rot_y, "Corpo do personagem rotacionou no eixo Y com o movimento horizontal do mouse")
	assert_test(player.head.rotation.x != initial_head_rot_x, "Cabeça/câmera do personagem rotacionou no eixo X com o movimento vertical do mouse")

	# --- ETAPA 5: PRESSIONAR ESC E CONFIRMAR QUE O PAUSE ABRE ---
	print("\n--- ETAPA 5: Pressionar ESC para Abrir Menu de Pausa ---")
	var esc_event = InputEventKey.new()
	esc_event.pressed = true
	esc_event.keycode = KEY_ESCAPE

	pause_menu._input(esc_event)
	assert_test(pause_menu.visible == true, "Menu de pausa abriu com sucesso ao pressionar ESC")
	assert_test(self.paused == true, "Jogo entrou em estado pausado (get_tree().paused == true)")

	# --- ETAPA 6: FECHAR/DESPAUSAR E CONFIRMAR RETORNO DA CÂMERA ---
	print("\n--- ETAPA 6: Fechar Menu de Pausa e Retomar Câmera ---")
	pause_menu.resume_game()
	assert_test(pause_menu.visible == false, "Menu de pausa fechado")
	assert_test(self.paused == false, "Jogo despausado (get_tree().paused == false)")
	assert_test(gm.current_state == GameManager.GameState.PLAYING, "GameManager restaurado para PLAYING")

	# Testa novo movimento de câmera após despausar
	var rot_after_resume_y = player.rotation.y
	var rot_after_resume_x = player.head.rotation.x
	mouse_event.relative = Vector2(-30.0, -20.0)
	player._unhandled_input(mouse_event)
	assert_test(player.rotation.y != rot_after_resume_y, "Câmera volta a girar horizontalmente após despausar")
	assert_test(player.head.rotation.x != rot_after_resume_x, "Câmera volta a girar verticalmente após despausar")

	# --- ETAPA 7: CONFIRMAR MOVIMENTO FISICO DO PERSONAGEM (WASD) ---
	print("\n--- ETAPA 7: Movimento Físico do Personagem ---")
	player._physics_process(0.016)
	assert_test(player.is_inside_tree(), "Personagem ativo na cena e pronto para gameplay")

	# Cleanup
	player.queue_free()
	pause_menu.queue_free()
	_cleanup_test_dir(test_dir)
	sm.set_custom_save_dir("")

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 INPUT, CÂMERA, MOUSE E PAUSE 100% VALIDADOS NO DIA 1!")
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
