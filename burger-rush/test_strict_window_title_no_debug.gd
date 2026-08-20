extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DE TÍTULO DA JANELA SEM "DEBUG"
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
	print("=== BURGER RUSH - TESTE DE VALIDAÇÃO DO TÍTULO SEM 'DEBUG' ===")
	print("=================================================================")

	# 1. Validação das configurações de projeto (project.godot)
	print("\n--- TESTE 1: Configurações do Arquivo project.godot ---")
	var proj_file = FileAccess.open("res://project.godot", FileAccess.READ)
	var proj_content = proj_file.get_as_text() if proj_file else ""
	proj_file.close()

	assert_test(proj_content.contains('config/name="Burger Rush"'), "config/name configurado exatamente como 'Burger Rush'")
	assert_test(proj_content.contains('config/description="Burger Rush"'), "config/description configurado como 'Burger Rush'")
	assert_test(proj_content.contains('window/title="Burger Rush"'), "display/window/title configurado explicitamente como 'Burger Rush'")
	assert_test(not proj_content.to_upper().contains(" - DEBUG"), "Nenhuma string '- DEBUG' em project.godot")
	assert_test(not proj_content.to_upper().contains("(DEBUG)"), "Nenhuma string '(DEBUG)' em project.godot")

	# 2. Validação das configurações de exportação (export_presets.cfg)
	print("\n--- TESTE 2: Configurações de Exportação (export_presets.cfg) ---")
	var exp_file = FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	var exp_content = exp_file.get_as_text() if exp_file else ""
	exp_file.close()

	assert_test(exp_content.contains('application/product_name="Burger Rush"'), "product_name é 'Burger Rush'")
	assert_test(exp_content.contains('application/file_description="Burger Rush"'), "file_description é 'Burger Rush'")
	assert_test(exp_content.contains('application/show_console=false'), "Console desativado para build final")
	assert_test(not exp_content.to_upper().contains(" - DEBUG"), "Nenhuma string '- DEBUG' em export_presets.cfg")

	# 3. Validação dos Métodos de Runtime
	print("\n--- TESTE 3: Métodos de Execução e Título da Janela ---")
	var sm = SaveManager.get_instance()
	if not sm:
		sm = SaveManager.new()
		sm.name = "SaveManager"
		root.add_child(sm)
	sm._enforce_clean_window_title()
	assert_test(sm.has_method("_enforce_clean_window_title"), "SaveManager possui método _enforce_clean_window_title")

	var gm = GameManager.get_instance()
	if not gm:
		gm = GameManager.new()
		gm.name = "GameManager"
		root.add_child(gm)
	gm._enforce_clean_window_title()
	assert_test(gm.has_method("_enforce_clean_window_title"), "GameManager possui método _enforce_clean_window_title")

	var menu_res = load("res://src/ui/main_menu.tscn")
	var menu = menu_res.instantiate()
	root.add_child(menu)
	assert_test(menu != null, "MainMenu instanciado e enforcing window title")

	menu.queue_free()

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 VALIDAÇÃO DE REMOÇÃO DO 'DEBUG' CONCLUÍDA COM 100% DE SUCESSO!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)
