extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DA INTRODUÇÃO DO DIA 1 (AMBOS OS FLUXOS) E CONFIG DO EXECUTÁVEL
# ==============================================================================

const SaveManager = preload("res://src/core/save_manager.gd")
const GameManager = preload("res://src/core/game_manager.gd")
const TutorialUI = preload("res://src/ui/tutorial.gd")
const HudUI = preload("res://src/ui/hud.gd")

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
	print("=== BURGER RUSH - TESTE INTRO DIA 1 (FLUXOS) E EXECUTÁVEL ===")
	print("=================================================================")

	var sm = SaveManager.get_instance()
	if not sm:
		if root.has_node("SaveManager"):
			sm = root.get_node("SaveManager")
		else:
			sm = SaveManager.new()
			sm.name = "SaveManager"
			root.add_child(sm)

	var gm = GameManager.get_instance()
	if not gm:
		if root.has_node("GameManager"):
			gm = root.get_node("GameManager")
		else:
			gm = GameManager.new()
			gm.name = "GameManager"
			root.add_child(gm)

	# --- TESTE 1: FLUXO A - CONCLUIR TUTORIAL → INTRO DO DIA 1 ---
	print("\n--- TESTE 1: Fluxo A (Concluir Tutorial → Intro Dia 1) ---")
	sm.create_new_career(1, "Rodrigo Chef")
	assert_test(sm.pending_save_data["player_name"] == "Rodrigo Chef", "Carreira criada com o nome 'Rodrigo Chef'")

	var tut_res = load("res://src/ui/tutorial.tscn")
	var tut = tut_res.instantiate() as TutorialUI
	root.add_child(tut)
	tut.tutorial_completed = true
	tut._on_start_day_pressed()

	assert_test(sm.pending_save_data.get("tutorial_completed") == true, "Tutorial marcado como concluído")
	assert_test(sm.pending_save_data.get("day1_intro_shown") == false, "day1_intro_shown inicializado como false")

	tut.queue_free()

	# Instancia HUD na cena de jogo
	var hud_res = load("res://src/ui/hud.tscn")
	var hud = hud_res.instantiate() as HudUI
	root.add_child(hud)
	hud._check_and_show_day1_intro()

	assert_test(hud.day1_welcome_modal != null and hud.day1_welcome_modal.visible == true, "Modal 'SEU PRIMEIRO DIA' exibido obrigatoriamente após concluir tutorial")
	assert_test(hud.day1_title_label.text == "SEU PRIMEIRO DIA", "Título correto: 'SEU PRIMEIRO DIA'")
	assert_test(hud.day1_body_label.text.contains("Chefe Rodrigo Chef, agora é pra valer."), "Corpo da mensagem contém o nome do jogador 'Rodrigo Chef'")
	assert_test(hud.day1_start_button.text == "COMEÇAR DIA 1", "Botão de confirmação 'COMEÇAR DIA 1'")

	# Confirmação do jogador
	hud._on_day1_start_button_pressed()
	assert_test(hud.day1_welcome_modal.visible == false, "Modal é fechado após confirmação")
	assert_test(sm.pending_save_data.get("day1_intro_shown") == true, "day1_intro_shown atualizado para true no save")

	hud.queue_free()

	# --- TESTE 2: FLUXO B - PULAR TUTORIAL → INTRO DO DIA 1 ---
	print("\n--- TESTE 2: Fluxo B (Pular Tutorial → Intro Dia 1) ---")
	sm.create_new_career(2, "Felix Master")
	assert_test(sm.pending_save_data["player_name"] == "Felix Master", "Carreira 2 criada com o nome 'Felix Master'")

	var tut2 = tut_res.instantiate() as TutorialUI
	root.add_child(tut2)
	tut2._on_confirm_skip_pressed()

	assert_test(sm.pending_save_data.get("tutorial_completed") == true, "Tutorial pulado e marcado como concluído")
	assert_test(sm.pending_save_data.get("day1_intro_shown") == false, "day1_intro_shown inicializado como false ao pular")

	tut2.queue_free()

	# Instancia HUD para o slot 2
	var hud2 = hud_res.instantiate() as HudUI
	root.add_child(hud2)
	hud2._check_and_show_day1_intro()

	assert_test(hud2.day1_welcome_modal != null and hud2.day1_welcome_modal.visible == true, "Modal 'SEU PRIMEIRO DIA' exibido obrigatoriamente após pular tutorial")
	assert_test(hud2.day1_body_label.text.contains("Chefe Felix Master, agora é pra valer."), "Corpo da mensagem contém o nome 'Felix Master' após pular tutorial")

	hud2._on_day1_start_button_pressed()
	assert_test(hud2.day1_welcome_modal.visible == false, "Modal fechado após confirmação")
	assert_test(sm.pending_save_data.get("day1_intro_shown") == true, "day1_intro_shown salvo como true para o slot 2")

	hud2.queue_free()

	# --- TESTE 3: CONFIGURAÇÃO LIMPA DO EXECUTÁVEL E ÍCONES ---
	print("\n--- TESTE 3: Configuração Limpa do Executável e Ícone Oficial ---")
	var proj_file = FileAccess.open("res://project.godot", FileAccess.READ)
	var proj_content = proj_file.get_as_text() if proj_file else ""
	proj_file.close()

	assert_test(proj_content.contains('config/name="Burger Rush"'), "project.godot configurado com nome oficial 'Burger Rush'")
	assert_test(proj_content.contains('config/icon="res://icon.png"'), "project.godot configurado com novo ícone icon.png")
	assert_test(FileAccess.file_exists("res://icon.png"), "Arquivo icon.png existe no projeto")
	assert_test(FileAccess.file_exists("res://icon.ico"), "Arquivo icon.ico existe no projeto para build Windows")

	var export_file = FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	var export_content = export_file.get_as_text() if export_file else ""
	export_file.close()

	assert_test(export_content.contains('application/product_name="Burger Rush"'), "export_presets.cfg configurado com Product Name 'Burger Rush'")
	assert_test(export_content.contains('application/icon="res://icon.ico"'), "export_presets.cfg configurado com ícone oficial icon.ico")
	assert_test(export_content.contains('application/show_console=false'), "Console/debug desativado no executável final")

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 FLUXOS DO DIA 1 E CONFIGURAÇÃO DO EXECUTÁVEL VALIDADOS COM 100% DE SUCESSO!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)
