extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DE ISOLAMENTO DO TUTORIAL E EXPORTAÇÃO LIMPA
# ==============================================================================

const SaveManager = preload("res://src/core/save_manager.gd")
const GameManager = preload("res://src/core/game_manager.gd")
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
	print("=== BURGER RUSH - TESTE DE ISOLAMENTO DO TUTORIAL & EXPORTAÇÃO ===")
	print("=================================================================")

	var test_dir = "user://saves_test_tutorial_isolation"
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

	var hud_res = load("res://src/ui/hud.tscn")
	var hud = hud_res.instantiate()
	root.add_child(hud)

	# --- TESTE 1: NOVO JOGO E INÍCIO DO TUTORIAL (MODAL DIA 1 DEVE FICAR OCULTO) ---
	print("\n--- TESTE 1: Bloqueio Estrito do Dia 1 Durante o Tutorial ---")
	sm.create_new_career(1, "Chef Rodrigo")
	sm.pending_save_data["tutorial_completed"] = false
	sm.pending_save_data["day1_intro_shown"] = false
	sm.save_game(1)
	sm.load_game(1)

	gm.change_state(GameManager.GameState.TUTORIAL)

	# Cria nó simulador de tutorial ativo
	var tut_node = Node.new()
	tut_node.name = "Tutorial"
	tut_node.set("tutorial_completed", false)
	root.add_child(tut_node)

	# Executa verificação do HUD durante o tutorial
	hud._check_and_show_day1_intro()
	assert_test(hud.day1_welcome_modal != null, "Modal do Primeiro Dia existe no HUD")
	assert_test(hud.day1_welcome_modal.visible == false, "Modal do Primeiro Dia está RIGOROSAMENTE OCULTO durante o tutorial")

	# --- TESTE 2: CONCLUSÃO DO TUTORIAL → TRANSIÇÃO PARA O DIA 1 ---
	print("\n--- TESTE 2: Conclusão do Tutorial → Exibição da Intro do Dia 1 ---")
	root.remove_child(tut_node)
	tut_node.queue_free()

	sm.pending_save_data["tutorial_completed"] = true
	sm.pending_save_data["day1_intro_shown"] = false
	sm.save_game(1)

	gm.change_state(GameManager.GameState.PLAYING)

	hud._check_and_show_day1_intro()
	assert_test(hud.day1_welcome_modal.visible == true, "Modal do Primeiro Dia é exibido após concluir o tutorial")
	assert_test(hud.day1_title_label.text == "SEU PRIMEIRO DIA", "Título é 'SEU PRIMEIRO DIA'")
	assert_test(hud.day1_body_label.text.contains("Chefe Rodrigo, agora é pra valer."), "Texto personalizado com o nome do chefe")

	# Jogador clica em 'COMEÇAR DIA 1'
	hud._on_day1_start_button_pressed()
	assert_test(hud.day1_welcome_modal.visible == false, "Modal é fechado após confirmação")
	assert_test(sm.pending_save_data.get("day1_intro_shown") == true, "day1_intro_shown salvo como true")

	# Nova verificação não deve reabrir o modal
	hud._check_and_show_day1_intro()
	assert_test(hud.day1_welcome_modal.visible == false, "Modal permanece fechado após ter sido visualizado")

	# --- TESTE 3: PULAR TUTORIAL → TRANSIÇÃO DIRETA PARA O DIA 1 ---
	print("\n--- TESTE 3: Pular Tutorial → Exibição da Intro do Dia 1 ---")
	sm.create_new_career(2, "Chef Felix")
	sm.pending_save_data["tutorial_completed"] = false
	sm.pending_save_data["day1_intro_shown"] = false
	sm.save_game(2)
	sm.load_game(2)

	# Simula pular tutorial pelo menu de pausa
	sm.pending_save_data["tutorial_completed"] = true
	sm.pending_save_data["day1_intro_shown"] = false
	sm.save_game(2)

	gm.change_state(GameManager.GameState.PLAYING)

	hud._check_and_show_day1_intro()
	assert_test(hud.day1_welcome_modal.visible == true, "Modal do Primeiro Dia exibido ao pular tutorial")
	assert_test(hud.day1_body_label.text.contains("Chefe Felix, agora é pra valer."), "Texto personalizado para o Chef Felix")

	hud._on_day1_start_button_pressed()
	assert_test(hud.day1_welcome_modal.visible == false, "Modal fecha corretamente após confirmação ao pular tutorial")

	# Cleanup
	hud.queue_free()
	_cleanup_test_dir(test_dir)
	sm.set_custom_save_dir("")

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 ISOLAMENTO DO TUTORIAL E FLUXO DO DIA 1 VALIDADOS COM 100% DE SUCESSO!")
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
