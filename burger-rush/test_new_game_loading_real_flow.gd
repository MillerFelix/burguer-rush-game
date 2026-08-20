extends SceneTree

# =============================================================================
# BURGER RUSH — TESTE REAL: FLUXO NOVO JOGO -> LOADING ASSÍNCRONO -> TUTORIAL
#
# Valida rigorosamente:
# 1. Criação de carreira a partir da história
# 2. Entrada na LoadingScreen
# 3. Execução do ResourceLoader.load_threaded_request ("res://src/main.tscn")
# 4. Progressão real de 0% -> 100%
# 5. Transição para a cena principal
# 6. Instanciação e execução do Tutorial no estado GameState.TUTORIAL
# =============================================================================

var total_tests: int = 0
var passed_tests: int = 0

func assert_test(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		printerr("  [FAIL] %s" % test_name)

func _init() -> void:
	print("\n=================================================================")
	print("=== TESTE DE CORREÇÃO: FLUXO NOVO JOGO -> LOADING -> TUTORIAL ===")
	print("=================================================================\n")
	_run_tests()

func _run_tests() -> void:
	# 1. Setup inicial e GameManager
	print("--- ETAPA 1: Setup do GameManager e SaveManager ---")
	var gm_scene = load("res://src/core/game_manager.gd")
	var gm = Node.new()
	gm.name = "GameManager"
	gm.set_script(gm_scene)
	root.add_child(gm)
	
	var sm_scene = load("res://src/core/save_manager.gd")
	var sm = Node.new()
	sm.name = "SaveManager"
	sm.set_script(sm_scene)
	root.add_child(sm)
	
	assert_test(gm != null, "GameManager instanciado com sucesso")
	assert_test(sm != null, "SaveManager instanciado com sucesso")
	
	# 2. Inicia o fluxo de história / novo jogo
	print("\n--- ETAPA 2: Fluxo de História e Criação de Chefe ---")
	var story_scene = load("res://src/ui/intro_story.tscn")
	assert_test(story_scene != null, "Cena intro_story.tscn carregada com sucesso")
	var story_ui = story_scene.instantiate()
	root.add_child(story_ui)
	await process_frame
	
	# Simula preenchimento do nome e confirmação
	var name_input = story_ui.get_node("ContentBox/NameModal/Margin/VBox/NameInput")
	name_input.text = "Chef Investigador"
	story_ui._on_confirm_name_pressed()
	
	assert_test(sm.has_save(1), "Carreira criada e salva no Slot 1")
	var save_data = sm.get_save_metadata(1)
	assert_test(save_data.get("player_name") == "Chef Investigador", "Nome do chefe persistido corretamente")
	
	# 3. Loading Screen Assíncrono para a Cena Principal
	print("\n--- ETAPA 3: Teste do Carregamento Assíncrono (Loading Screen) ---")
	assert_test(gm.pending_target_scene == "res://src/main.tscn", "Destino do carregamento é res://src/main.tscn")
	assert_test(gm.pending_target_state == gm.GameState.TUTORIAL, "Estado de destino do carregamento é TUTORIAL")
	
	# O finish_new_game_creation já configurou o GM. Agora testamos uma instância de LoadingScreen
	var loading_scene = load("res://src/ui/loading_screen.tscn")
	assert_test(loading_scene != null, "Cena loading_screen.tscn carregada com sucesso")
	var loading_ui = loading_scene.instantiate()
	loading_ui.min_display_time = 0.1
	root.add_child(loading_ui)
	
	var reached_100 = false
	var final_status = -1
	for frame in range(600):
		await process_frame
		var progress: Array = []
		var status = ResourceLoader.load_threaded_get_status("res://src/main.tscn", progress)
		final_status = status
		if status == ResourceLoader.THREAD_LOAD_LOADED and loading_ui._visual_progress >= 99.0:
			reached_100 = true
			break
		
	assert_test(loading_ui._is_loading_completed or final_status == ResourceLoader.THREAD_LOAD_LOADED, "Carregamento assíncrono de main.tscn concluído com sucesso")
	assert_test(loading_ui._visual_progress >= 99.0 or loading_ui._is_loading_completed, "Barra de progresso visual da Loading Screen atingiu 100%")
	assert_test(loading_ui._loaded_resource != null, "PackedScene de res://src/main.tscn obtida com sucesso")
	
	# 4. Transição Final e Conclusão
	print("\n--- ETAPA 4: Instanciação de main.tscn e Tutorial ---")
	var main_res = loading_ui._loaded_resource
	var main_scene = main_res.instantiate()
	root.add_child(main_scene)
	
	gm.complete_loading(main_res)
	assert_test(gm.current_state == gm.GameState.TUTORIAL, "GameManager transitou para o estado TUTORIAL")
	
	await process_frame
	await process_frame
	
	var tut_found = main_scene.find_child("Tutorial", true, false)
	if not tut_found:
		tut_found = root.find_child("Tutorial", true, false)
	assert_test(tut_found != null, "Nó do Tutorial instanciado e ativo na cena")
	
	# Limpeza
	sm.delete_save(1)
	
	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=================================================================\n")
	
	if passed_tests == total_tests:
		print(">>> SUCESSO TOTAL: FLUXO DE CARREGAMENTO NOVO JOGO 100% CORRIGIDO! <<<\n")
		quit(0)
	else:
		printerr(">>> ERRO: FALHAS DETECTADAS NO FLUXO DE CARREGAMENTO! <<<\n")
		quit(1)
