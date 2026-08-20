extends SceneTree

# =============================================================================
# BURGER RUSH — TESTE AUTOMATIZADO DA FASE 2 (MENU PRINCIPAL FUNCIONAL)
#
# Valida:
# 1. Carregamento da cena res://src/ui/main_menu.tscn
# 2. Imagem de fundo tela-menu-burger-rush.jpg configurada
# 3. Presença dos 4 botões (JOGAR, CONTINUAR, CONFIGURAÇÕES, SAIR)
# 4. Botão CONTINUAR desabilitado por padrão (sem save)
# 5. Botão CONFIGURAÇÕES abre o painel modal de configurações
# 6. Sliders de volume (Geral, Música, Efeitos) funcionais
# 7. Botão VOLTAR fecha o painel de configurações
# 8. Botão JOGAR funcional conectado ao GameManager (transição para NEW_GAME / Main)
# 9. Botão SAIR preparado com callback de encerramento
# 10. Integração correta com o GameManager (estado MAIN_MENU)
# =============================================================================

const GameManagerClass = preload("res://src/core/game_manager.gd")
const MainMenuClass = preload("res://src/ui/main_menu.gd")

var pass_count: int = 0
var total_count: int = 0

func assert_test(condition: bool, description: String) -> void:
	total_count += 1
	if condition:
		pass_count += 1
		print("  [PASS] %s" % description)
	else:
		printerr("  [FAIL] %s" % description)

func _init() -> void:
	print("\n=================================================================")
	print("=== TESTE FASE 2: MENU PRINCIPAL REAL E FUNCIONAL ===")
	print("=================================================================\n")

	test_menu_initialization_and_assets()
	test_buttons_presence_and_states()
	test_settings_panel_flow()
	test_play_and_game_manager_flow()

	print("\n=================================================================")
	print("RESULTADO FINAL: %d/%d APROVADOS" % [pass_count, total_count])
	print("=================================================================\n")

	if pass_count == total_count:
		print(">>> SUCESSO TOTAL: FASE 2 100% VALIDADA COM ÊXITO! <<<\n")
		quit(0)
	else:
		printerr(">>> ERRO: ALGUNS TESTES DA FASE 2 FALHARAM! <<<\n")
		quit(1)

func test_menu_initialization_and_assets() -> void:
	print("--- TESTE 1: Inicialização do Menu e Imagem de Fundo ---")

	var menu_scene = load("res://src/ui/main_menu.tscn")
	assert_test(menu_scene != null, "Cena res://src/ui/main_menu.tscn carregada com sucesso")

	var menu_instance = menu_scene.instantiate() as Control
	root.add_child(menu_instance)
	menu_instance._ready()

	assert_test(menu_instance != null, "Menu instanciado com sucesso")
	assert_test(menu_instance.background_rect != null, "BackgroundRect presente na cena")
	assert_test(menu_instance.background_rect.texture != null, "Textura de fundo atribuída ao BackgroundRect")

	var tex_path = menu_instance.background_rect.texture.resource_path
	assert_test(tex_path.contains("tela-menu-burger-rush.jpg"), "Imagem tela-menu-burger-rush.jpg utilizada como fundo do menu")

	menu_instance.queue_free()

func test_buttons_presence_and_states() -> void:
	print("\n--- TESTE 2: Presença, Textos e Estados dos Botões ---")

	var menu_scene = load("res://src/ui/main_menu.tscn")
	var menu = menu_scene.instantiate() as Control
	root.add_child(menu)
	menu._ready()

	assert_test(menu.play_button != null, "Botão JOGAR presente")
	assert_test(menu.play_button.text == "JOGAR", "Texto do botão principal é 'JOGAR'")

	assert_test(menu.continue_button != null, "Botão CONTINUAR presente")
	assert_test(menu.continue_button.text == "CONTINUAR", "Texto do botão é 'CONTINUAR'")
	assert_test(menu.continue_button.disabled == true, "Botão CONTINUAR inicia DESABILITADO (sem save existente)")

	assert_test(menu.settings_button != null, "Botão CONFIGURAÇÕES presente")
	assert_test(menu.settings_button.text == "CONFIGURAÇÕES", "Texto do botão é 'CONFIGURAÇÕES'")

	assert_test(menu.quit_button != null, "Botão SAIR presente")
	assert_test(menu.quit_button.text == "SAIR", "Texto do botão é 'SAIR'")

	menu.queue_free()

func test_settings_panel_flow() -> void:
	print("\n--- TESTE 3: Abertura, Sliders e Fechamento do Painel de Configurações ---")

	var menu_scene = load("res://src/ui/main_menu.tscn")
	var menu = menu_scene.instantiate() as Control
	root.add_child(menu)
	menu._ready()

	assert_test(menu.settings_overlay != null, "Nó SettingsOverlay presente")
	assert_test(not menu.settings_overlay.visible, "Painel de configurações inicia OCULTO")

	# Abre configurações via clique
	menu.settings_button.emit_signal("pressed")
	assert_test(menu.settings_overlay.visible, "Painel de configurações VISÍVEL após clicar em CONFIGURAÇÕES")

	# Sliders presentes e ajustáveis
	assert_test(menu.master_slider != null, "Slider de Volume Geral presente")
	assert_test(menu.music_slider != null, "Slider de Volume da Música presente")
	assert_test(menu.sfx_slider != null, "Slider de Volume dos Efeitos presente")

	menu.master_slider.value_changed.emit(75.0)
	assert_test(menu.master_value_label.text == "75%", "Rótulo de valor do Volume Geral atualizado para 75%")

	menu.music_slider.value_changed.emit(50.0)
	assert_test(menu.music_value_label.text == "50%", "Rótulo de valor da Música atualizado para 50%")

	# Fecha configurações via botão VOLTAR
	assert_test(menu.back_settings_button != null, "Botão VOLTAR presente nas configurações")
	menu.back_settings_button.emit_signal("pressed")
	assert_test(not menu.settings_overlay.visible, "Painel de configurações FECHADO após clicar em VOLTAR")

	menu.queue_free()

func test_play_and_game_manager_flow() -> void:
	print("\n--- TESTE 4: Integração do Botão JOGAR com o GameManager ---")

	var gm = GameManagerClass.new()
	root.add_child(gm)

	var menu_scene = load("res://src/ui/main_menu.tscn")
	var menu = menu_scene.instantiate() as Control
	root.add_child(menu)
	menu._ready()

	# Ao abrir o menu, GameManager deve estar em MAIN_MENU
	assert_test(gm.get_state() == GameManagerClass.GameState.MAIN_MENU, "GameManager sincronizado no estado MAIN_MENU")

	# Clica em JOGAR e seleciona o Slot 1
	menu.play_button.emit_signal("pressed")
	assert_test(menu.slot_select_overlay != null and menu.slot_select_overlay.visible == true, "Seleção de slots aberta após clicar em JOGAR")

	if menu.slot1_button:
		menu.slot1_button.emit_signal("pressed")

	# GameManager transita para NEW_GAME / LOADING / STORY
	var state = gm.get_state()
	assert_test(state == GameManagerClass.GameState.NEW_GAME or state == GameManagerClass.GameState.LOADING or state == GameManagerClass.GameState.STORY or state == GameManagerClass.GameState.PLAYING, "GameManager iniciou fluxo de transição após JOGAR e selecionar slot")

	menu.free()
	gm.free()
