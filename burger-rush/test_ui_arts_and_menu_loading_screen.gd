extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DO VISUAL DO MENU PRINCIPAL E TELA DE CARREGAMENTO
# ==============================================================================

const MainMenuUI = preload("res://src/ui/main_menu.gd")
const LoadingScreenUI = preload("res://src/ui/loading_screen.gd")
const SaveManager = preload("res://src/core/save_manager.gd")
const GameManager = preload("res://src/core/game_manager.gd")

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
	print("=== BURGER RUSH - TESTE DO NOVO VISUAL DO MENU E LOADING SCREEN ===")
	print("=================================================================")

	var sm = SaveManager.new()
	sm.name = "SaveManager"
	root.add_child(sm)

	var gm = GameManager.new()
	gm.name = "GameManager"
	root.add_child(gm)

	# --- TESTE 1: Menu Principal com Nova Arte e Layout à Esquerda ---
	print("\n--- TESTE 1: Menu Principal (tela-menu-burger-rush.png) ---")
	var menu_scene_res = load("res://src/ui/main_menu.tscn")
	assert_test(menu_scene_res != null, "Cena main_menu.tscn carregada com sucesso")

	var menu = menu_scene_res.instantiate() as MainMenuUI
	root.add_child(menu)
	assert_test(menu != null, "MainMenuUI instanciado na árvore")

	var bg_menu = menu.find_child("BackgroundRect", true, false) as TextureRect
	assert_test(bg_menu != null and bg_menu.texture != null, "Fundo do menu possui textura atribuída")
	assert_test(bg_menu.texture.resource_path.contains("tela-menu-burger-rush.png"), "Fundo utiliza a nova arte tela-menu-burger-rush.png")
	assert_test(bg_menu.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Textura configurada com KEEP_ASPECT_COVERED para evitar distorções")

	var menu_center = menu.get_node("MenuCenter") as Control
	assert_test(menu_center != null, "Contêiner do menu presente")
	assert_test(menu_center.offset_left < 200.0 and menu_center.offset_right < 600.0, "Menu posicionado no canto esquerdo conforme a composição da arte")

	assert_test(menu.play_button != null, "Botão JOGAR presente e funcional")
	assert_test(menu.continue_button != null, "Botão CONTINUAR presente e funcional")
	assert_test(menu.settings_button != null, "Botão CONFIGURAÇÕES presente e funcional")
	assert_test(menu.quit_button != null, "Botão SAIR presente e funcional")

	# Verifica estilo arredondado dos botões
	var play_style = menu.play_button.get_theme_stylebox("normal") as StyleBoxFlat
	assert_test(play_style != null and play_style.corner_radius_top_left >= 12, "Botão JOGAR com cantos arredondados modernos (corner_radius >= 12)")

	var btn_style = menu.settings_button.get_theme_stylebox("normal") as StyleBoxFlat
	assert_test(btn_style != null and btn_style.corner_radius_top_left >= 10, "Botões secundários com estilo arredondado e borda dourada")

	# Verifica overlays funcionais
	assert_test(menu.settings_overlay != null, "Painel de configurações presente")
	assert_test(menu.slot_select_overlay != null, "Modal de seleção de slots presente")
	assert_test(menu.overwrite_confirm_overlay != null, "Modal de confirmação de overwrite presente")

	menu.queue_free()

	# --- TESTE 2: Tela de Carregamento com Nova Arte e Barra Grande ---
	print("\n--- TESTE 2: Tela de Carregamento (tela-carregamento-burger-rush.png) ---")
	var load_scene_res = load("res://src/ui/loading_screen.tscn")
	assert_test(load_scene_res != null, "Cena loading_screen.tscn carregada com sucesso")

	var loading_screen = load_scene_res.instantiate() as LoadingScreenUI
	root.add_child(loading_screen)
	assert_test(loading_screen != null, "LoadingScreenUI instanciado na árvore")

	var bg_load = loading_screen.find_child("BackgroundRect", true, false) as TextureRect
	assert_test(bg_load != null and bg_load.texture != null, "Fundo do loading possui textura atribuída")
	assert_test(bg_load.texture.resource_path.contains("tela-carregamento-burger-rush.png"), "Fundo utiliza a nova arte tela-carregamento-burger-rush.png")
	assert_test(bg_load.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Textura de loading configurada com KEEP_ASPECT_COVERED")

	var p_bar = loading_screen.progress_bar
	assert_test(p_bar != null, "Barra de progresso presente")
	assert_test(p_bar.custom_minimum_size.x >= 800.0, "Barra de progresso grande e destacada na parte inferior (largura >= 800px)")

	var p_fill = p_bar.get_theme_stylebox("fill") as StyleBoxFlat
	assert_test(p_fill != null and p_fill.corner_radius_top_left >= 8, "Barra de preenchimento estilizada com cantos arredondados")

	var p_label = loading_screen.progress_label
	assert_test(p_label != null, "Rótulo de porcentagem real de carregamento presente")

	var l_label = loading_screen.loading_label
	assert_test(l_label != null and l_label.text.contains("CARREGANDO"), "Rótulo de texto de carregamento presente")

	loading_screen.queue_free()
	gm.queue_free()
	sm.queue_free()

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 NOVO VISUAL DO MENU E TELA DE CARREGAMENTO VALIDADOS COM 100% DE SUCESSO!")
	else:
		print("❌ TESTE FALHOU!")

	quit(0 if failed == 0 else 1)
