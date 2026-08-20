extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE COMPLETO DO SISTEMA DE SAVES, EXCLUSÃO E TITULO LIMPO
# ==============================================================================

const SaveManager = preload("res://src/core/save_manager.gd")
const GameManager = preload("res://src/core/game_manager.gd")
const MainMenuUI = preload("res://src/ui/main_menu.gd")

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
	print("=== BURGER RUSH - TESTE DO SISTEMA DE SAVES E EXCLUSÃO LIMPA ===")
	print("=================================================================")

	var sm = SaveManager.get_instance()
	if not sm:
		if root.has_node("SaveManager"):
			sm = root.get_node("SaveManager")
		else:
			sm = SaveManager.new()
			sm.name = "SaveManager"
			root.add_child(sm)

	# Isola o diretório de testes para não afetar o save real do jogador
	var test_dir = "user://saves_test_clean_suite"
	sm.set_custom_save_dir(test_dir)
	_cleanup_test_dir(test_dir)

	var gm = GameManager.get_instance()
	if not gm:
		if root.has_node("GameManager"):
			gm = root.get_node("GameManager")
		else:
			gm = GameManager.new()
			gm.name = "GameManager"
			root.add_child(gm)

	var menu_res = load("res://src/ui/main_menu.tscn")
	var menu = menu_res.instantiate() as MainMenuUI
	root.add_child(menu)

	# --- TESTE 1: PRIMEIRA EXECUÇÃO — TODOS OS SLOTS VAZIOS ---
	print("\n--- TESTE 1: Primeira Execução (Slots 100% Vazios) ---")
	assert_test(not sm.has_any_save(), "Nenhum save pré-existente encontrado na primeira execução")
	assert_test(not sm.has_valid_save(1), "Slot 1 está vazio")
	assert_test(not sm.has_valid_save(2), "Slot 2 está vazio")

	menu._update_continue_button_state()
	assert_test(menu.continue_button.disabled == true, "Botão CONTINUAR desabilitado na primeira execução")

	menu._open_slot_selection()
	assert_test(menu.slot1_details.text.contains("Slot Vazio"), "Slot 1 exibido visualmente como Vazio")
	assert_test(menu.slot2_details.text.contains("Slot Vazio"), "Slot 2 exibido visualmente como Vazio")
	assert_test(menu.slot1_delete_button.visible == false, "Botão de excluir do Slot 1 oculto quando vazio")
	assert_test(menu.slot2_delete_button.visible == false, "Botão de excluir do Slot 2 oculto quando vazio")

	# --- TESTE 2: CRIAR NOVO JOGO NO SLOT 1 ---
	print("\n--- TESTE 2: Criar Novo Jogo no Slot 1 (Chef Miller) ---")
	sm.create_new_career(1, "Chef Miller")
	assert_test(sm.has_valid_save(1), "Save do Slot 1 criado com sucesso")
	assert_test(sm.pending_save_data["player_name"] == "Chef Miller", "Nome do chefe salvo como 'Chef Miller'")
	assert_test(sm.pending_save_data["day1_intro_shown"] == false, "day1_intro_shown inicializado como false")

	menu._refresh_slots_ui()
	menu._update_continue_button_state()
	assert_test(menu.continue_button.disabled == false, "Botão CONTINUAR habilitado após criar save")
	assert_test(menu.slot1_details.text.contains("Chef Miller"), "Slot 1 exibe o nome 'Chef Miller'")
	assert_test(menu.slot1_delete_button.visible == true, "Botão de excluir visível no Slot 1 ocupado")
	assert_test(menu.slot2_details.text.contains("Slot Vazio"), "Slot 2 permanece Vazio")

	# --- TESTE 3: EXCLUIR SAVE DO SLOT 1 COM CONFIRMAÇÃO ---
	print("\n--- TESTE 3: Excluir Save do Slot 1 ---")
	menu._on_delete_slot_pressed(1)
	assert_test(menu.delete_confirm_overlay != null and menu.delete_confirm_overlay.visible == true, "Modal de confirmação de exclusão aberto")
	assert_test(menu.delete_warn_message.text.contains("Chef Miller"), "Modal de confirmação identifica a carreira 'Chef Miller'")

	# Confirma a exclusão
	menu._on_confirm_delete_pressed()
	assert_test(menu.delete_confirm_overlay.visible == false, "Modal de confirmação fechado após exclusão")
	assert_test(not sm.has_valid_save(1), "Arquivo de save do Slot 1 removido com sucesso")
	assert_test(menu.slot1_details.text.contains("Slot Vazio"), "Slot 1 volta imediatamente a ser 'Slot Vazio'")
	assert_test(menu.slot1_delete_button.visible == false, "Botão de excluir do Slot 1 oculto após exclusão")
	assert_test(menu.continue_button.disabled == true, "Botão CONTINUAR volta a ficar desabilitado após excluir todos os saves")

	# --- TESTE 4: CRIAR NOVO JOGO NO SLOT 2 ---
	print("\n--- TESTE 4: Criar Novo Jogo no Slot 2 (Chef Gordon) ---")
	sm.create_new_career(2, "Chef Gordon")
	assert_test(sm.has_valid_save(2), "Save do Slot 2 criado com sucesso")
	assert_test(not sm.has_valid_save(1), "Slot 1 permanece vazio")

	menu._refresh_slots_ui()
	menu._update_continue_button_state()
	assert_test(menu.continue_button.disabled == false, "Botão CONTINUAR habilitado para o Slot 2")
	assert_test(menu.slot2_details.text.contains("Chef Gordon"), "Slot 2 exibe o nome 'Chef Gordon'")
	assert_test(menu.slot2_delete_button.visible == true, "Botão de excluir do Slot 2 visível")
	assert_test(menu.slot1_details.text.contains("Slot Vazio"), "Slot 1 permanece exibido como Vazio")

	# --- TESTE 5: CONFIGURAÇÃO LIMPA DO TÍTULO E EXECUTÁVEL ---
	print("\n--- TESTE 5: Configurações de Janela e Executável ---")
	var proj_file = FileAccess.open("res://project.godot", FileAccess.READ)
	var proj_content = proj_file.get_as_text() if proj_file else ""
	proj_file.close()

	assert_test(proj_content.contains('config/name="Burger Rush"'), "Nome do projeto é estritamente 'Burger Rush'")
	assert_test(not proj_content.to_upper().contains("DEBUG"), "Nenhuma string DEBUG encontrada nas configurações de projeto")
	assert_test(FileAccess.file_exists("res://icon.ico"), "Ícone icon.ico multi-resolução gerado e presente")

	menu.queue_free()
	_cleanup_test_dir(test_dir)
	sm.set_custom_save_dir("") # Restaura para o padrão user://saves

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 SISTEMA DE SAVES, EXCLUSÃO E TÍTULO LIMPO VALIDADOS COM 100% DE SUCESSO!")
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
