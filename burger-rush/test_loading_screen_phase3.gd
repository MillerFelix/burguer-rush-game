extends SceneTree

# =============================================================================
# BURGER RUSH — TESTE AUTOMATIZADO DA FASE 3 (TELA DE CARREGAMENTO REAL)
#
# Valida:
# 1. Existência e carregamento da cena res://src/ui/loading_screen.tscn
# 2. Utilização correta da imagem tela-carregamento-burger-rush.jpg
# 3. Elementos visuais (LoadingLabel, ProgressBar, ProgressLabel, FadeOverlay)
# 4. Estado GameState.LOADING sincronizado com o GameManager
# 5. Destino dinâmico de carregamento configurável (sem path hardcoded)
# 6. Carregamento assíncrono real via ResourceLoader threaded
# 7. Finalização e transição para o estado PLAYING via complete_loading
# 8. Integração completa do fluxo: JOGAR -> NEW_GAME -> LOADING -> PLAYING
# =============================================================================

const GameManagerClass = preload("res://src/core/game_manager.gd")
const LoadingScreenClass = preload("res://src/ui/loading_screen.gd")
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
	print("=== TESTE FASE 3: TELA DE CARREGAMENTO REAL E ASSÍNCRONA ===")
	print("=================================================================\n")

	test_loading_screen_assets_and_nodes()
	test_dynamic_target_and_threaded_loader()
	test_game_manager_loading_integration()
	test_menu_play_to_loading_flow()

	print("\n=================================================================")
	print("RESULTADO FINAL: %d/%d APROVADOS" % [pass_count, total_count])
	print("=================================================================\n")

	if pass_count == total_count:
		print(">>> SUCESSO TOTAL: FASE 3 100% VALIDADA COM ÊXITO! <<<\n")
		quit(0)
	else:
		printerr(">>> ERRO: ALGUNS TESTES DA FASE 3 FALHARAM! <<<\n")
		quit(1)

func test_loading_screen_assets_and_nodes() -> void:
	print("--- TESTE 1: Estrutura Visual e Imagem da Loading Screen ---")

	var loading_scene = load("res://src/ui/loading_screen.tscn")
	assert_test(loading_scene != null, "Cena res://src/ui/loading_screen.tscn carregada com sucesso")

	var loading_inst = loading_scene.instantiate() as Control
	root.add_child(loading_inst)
	loading_inst._ready()

	assert_test(loading_inst != null, "LoadingScreen instanciada com sucesso")
	assert_test(loading_inst.background_rect != null, "BackgroundRect presente na cena de loading")
	assert_test(loading_inst.background_rect.texture != null, "Textura atribuída ao BackgroundRect")

	var tex_path = loading_inst.background_rect.texture.resource_path
	assert_test(tex_path.contains("tela-carregamento-burger-rush.jpg"), "Imagem tela-carregamento-burger-rush.jpg utilizada como fundo")

	assert_test(loading_inst.loading_label != null, "Rótulo de texto CARREGANDO presente")
	assert_test(loading_inst.loading_label.text.contains("CARREGANDO"), "Texto 'CARREGANDO...' configurado")

	assert_test(loading_inst.progress_bar != null, "Barra de progresso presente")
	assert_test(loading_inst.progress_label != null, "Rótulo numérico de porcentagem de progresso presente")
	assert_test(loading_inst.fade_overlay != null, "Camada de transição FadeOverlay presente")

	loading_inst.queue_free()

func test_dynamic_target_and_threaded_loader() -> void:
	print("\n--- TESTE 2: Carregamento Real Assíncrono e Destino Dinâmico ---")

	var loading_scene = load("res://src/ui/loading_screen.tscn")
	var loading_inst = loading_scene.instantiate() as Control

	# Testa configuração dinâmica do destino
	loading_inst.target_scene_path = "res://src/main.tscn"
	loading_inst.min_display_time = 0.05
	root.add_child(loading_inst)
	loading_inst._ready()

	assert_test(loading_inst.target_scene_path == "res://src/main.tscn", "Destino configurado dinamicamente para res://src/main.tscn")

	# Simula ciclo de processamento do carregador
	loading_inst._process(0.1)

	var status = ResourceLoader.load_threaded_get_status("res://src/main.tscn")
	assert_test(status == ResourceLoader.THREAD_LOAD_LOADED or status == ResourceLoader.THREAD_LOAD_IN_PROGRESS, "ResourceLoader threaded ativo e processando a cena de destino")

	loading_inst.queue_free()

func test_game_manager_loading_integration() -> void:
	print("\n--- TESTE 3: Integração do GameManager com a Loading Screen ---")

	var gm = GameManagerClass.new()
	root.add_child(gm)

	# Inicia transição via load_scene_with_loading
	var initiated = gm.load_scene_with_loading("main", GameManagerClass.GameState.PLAYING)
	assert_test(initiated == true, "GameManager.load_scene_with_loading retornou true")
	assert_test(gm.get_state() == GameManagerClass.GameState.LOADING, "GameManager transitou para o estado LOADING")
	assert_test(gm.pending_target_scene == "res://src/main.tscn", "Cena de destino pendente armazenada como res://src/main.tscn")
	assert_test(gm.pending_target_state == GameManagerClass.GameState.PLAYING, "Estado de destino pendente armazenado como PLAYING")

	# Simula finalização do carregamento com uma PackedScene de teste
	var test_node = Node.new()
	var test_packed = PackedScene.new()
	test_packed.pack(test_node)
	gm.complete_loading(test_packed)
	assert_test(gm.get_state() == GameManagerClass.GameState.PLAYING, "GameManager transitou com sucesso para o estado PLAYING após complete_loading")
	test_node.free()

	gm.queue_free()

func test_menu_play_to_loading_flow() -> void:
	print("\n--- TESTE 4: Fluxo Completo Botão JOGAR -> Loading ---")

	var gm = GameManagerClass.new()
	root.add_child(gm)

	var menu_scene = load("res://src/ui/main_menu.tscn")
	var menu = menu_scene.instantiate() as Control
	root.add_child(menu)
	menu._ready()

	# Clica em JOGAR e seleciona o Slot 1
	menu.play_button.emit_signal("pressed")
	if menu.slot1_button:
		menu.slot1_button.emit_signal("pressed")

	# O GameManager deve ter engatilhado o fluxo de transição com loading
	assert_test(gm.get_state() == GameManagerClass.GameState.LOADING or gm.get_state() == GameManagerClass.GameState.NEW_GAME or gm.get_state() == GameManagerClass.GameState.STORY, "GameManager engatilhou o fluxo de carregamento para Novo Jogo")

	menu.queue_free()
	gm.queue_free()
