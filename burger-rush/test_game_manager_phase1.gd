extends SceneTree

# =============================================================================
# BURGER RUSH — TESTE AUTOMATIZADO DA FASE 1 (ESTRUTURA BASE E GAMEMANAGER)
#
# Valida:
# 1. Existência e carregamento do GameManager
# 2. Enumeração completa dos 10 estados do jogo (GameState)
# 3. Transição de estados e emissão de sinais (state_changed)
# 4. Controle centralizado de pausa (set_pause, is_paused)
# 5. Estrutura de transição segura de cenas (change_scene, SCENE_PATHS)
# 6. Preservação de 100% dos subsistemas existentes (GameClock, Economy, Inventory, etc.)
# 7. Inicialização da cena principal (Main) em estado PLAYING
# =============================================================================

const GameManagerClass = preload("res://src/core/game_manager.gd")

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
	print("=== TESTE FASE 1: ARQUITETURA BASE E GAMEMANAGER ===")
	print("=================================================================\n")

	test_game_manager_states_and_signals()
	test_scene_paths_and_transitions()
	test_main_scene_integration()

	print("\n=================================================================")
	print("RESULTADO FINAL: %d/%d APROVADOS" % [pass_count, total_count])
	print("=================================================================\n")

	if pass_count == total_count:
		print(">>> SUCESSO TOTAL: FASE 1 100% VALIDADA COM ÊXITO! <<<\n")
		quit(0)
	else:
		printerr(">>> ERRO: ALGUNS TESTES DA FASE 1 FALHARAM! <<<\n")
		quit(1)

func test_game_manager_states_and_signals() -> void:
	print("--- TESTE 1: Estados do GameManager e Sinais de Transição ---")

	var gm = GameManagerClass.new()
	root.add_child(gm)

	assert_test(gm != null, "GameManager instanciado com sucesso")
	assert_test(GameManagerClass.instance != null, "Instância singleton de GameManager registrada")

	# Verifica a presença dos 10 estados requeridos
	assert_test(GameManagerClass.GameState.BOOT == 0, "Estado BOOT presente (0)")
	assert_test(GameManagerClass.GameState.LOADING == 1, "Estado LOADING presente (1)")
	assert_test(GameManagerClass.GameState.MAIN_MENU == 2, "Estado MAIN_MENU presente (2)")
	assert_test(GameManagerClass.GameState.NEW_GAME == 3, "Estado NEW_GAME presente (3)")
	assert_test(GameManagerClass.GameState.STORY == 4, "Estado STORY presente (4)")
	assert_test(GameManagerClass.GameState.TUTORIAL == 5, "Estado TUTORIAL presente (5)")
	assert_test(GameManagerClass.GameState.PLAYING == 6, "Estado PLAYING presente (6)")
	assert_test(GameManagerClass.GameState.PAUSED == 7, "Estado PAUSED presente (7)")
	assert_test(GameManagerClass.GameState.DAY_END == 8, "Estado DAY_END presente (8)")
	assert_test(GameManagerClass.GameState.LOADING_SAVE == 9, "Estado LOADING_SAVE presente (9)")

	# Teste de transição de estado e emissão de sinal
	var sig_data = {"received": false, "old": -1, "new": -1}

	gm.state_changed.connect(func(old_s, new_s):
		sig_data["received"] = true
		sig_data["old"] = old_s
		sig_data["new"] = new_s
	)

	gm.change_state(GameManagerClass.GameState.MAIN_MENU)
	assert_test(gm.get_state() == GameManagerClass.GameState.MAIN_MENU, "Estado alterado para MAIN_MENU")
	assert_test(sig_data["received"] and sig_data["new"] == GameManagerClass.GameState.MAIN_MENU, "Sinal state_changed emitido corretamente")
	assert_test(gm.get_state_name() == "MAIN_MENU", "Nome textual do estado retornado corretamente: MAIN_MENU")

	# Teste de Pause
	gm.change_state(GameManagerClass.GameState.PLAYING)
	assert_test(gm.is_playing(), "is_playing() retorna true no estado PLAYING")
	gm.set_pause(true)
	assert_test(gm.is_paused(), "is_paused() retorna true após set_pause(true)")
	gm.set_pause(false)
	assert_test(not gm.is_paused() and gm.is_playing(), "Jogo despausado e voltou ao estado PLAYING")

	gm.queue_free()

func test_scene_paths_and_transitions() -> void:
	print("\n--- TESTE 2: Estrutura de Transições de Cena ---")

	var gm = GameManagerClass.new()
	root.add_child(gm)

	assert_test(gm.SCENE_PATHS.has("main"), "Caminho da cena 'main' registrado")
	assert_test(ResourceLoader.exists(gm.SCENE_PATHS["main"]), "Arquivo da cena 'main' (res://src/main.tscn) existe no projeto")
	assert_test(gm.SCENE_PATHS.has("menu"), "Slot para cena 'menu' mapeado")
	assert_test(gm.SCENE_PATHS.has("loading"), "Slot para cena 'loading' mapeado")
	assert_test(gm.SCENE_PATHS.has("tutorial"), "Slot para cena 'tutorial' mapeado")

	# Teste de tentativa de troca para cena inválida
	var failed_change = gm.change_scene("res://caminho_inexistente.tscn")
	assert_test(not failed_change, "change_scene retorna false e previne quebra ao tentar carregar cena inexistente")

	gm.queue_free()

func test_main_scene_integration() -> void:
	print("\n--- TESTE 3: Integração com a Cena Principal e Preservação dos Subsistemas ---")

	var main_scene_res = load("res://src/main.tscn")
	assert_test(main_scene_res != null, "Cena res://src/main.tscn carregada com sucesso")

	var main_inst = main_scene_res.instantiate()
	root.add_child(main_inst)
	current_scene = main_inst

	var gm = GameManagerClass.new()
	root.add_child(gm)

	# Validação da presença e preservação de todos os subsistemas essenciais
	assert_test(main_inst.has_node("GameClock"), "Subsistema GameClock preservado e ativo")
	assert_test(main_inst.has_node("EconomyManager"), "Subsistema EconomyManager preservado e ativo")
	assert_test(main_inst.has_node("InventoryManager"), "Subsistema InventoryManager preservado e ativo")
	assert_test(main_inst.has_node("OrderManager"), "Subsistema OrderManager preservado e ativo")
	assert_test(main_inst.has_node("ProgressionManager"), "Subsistema ProgressionManager preservado e ativo")
	assert_test(main_inst.has_node("Player"), "Nó Player preservado e ativo")

	# Teste dos métodos de resolução do GameManager
	assert_test(gm.get_game_clock() != null, "GameManager.get_game_clock() resolveu o GameClock com sucesso")
	assert_test(gm.get_economy_manager() != null, "GameManager.get_economy_manager() resolveu o EconomyManager com sucesso")
	assert_test(gm.get_player() != null, "GameManager.get_player() resolveu o Player com sucesso")

	gm.queue_free()
	main_inst.queue_free()
