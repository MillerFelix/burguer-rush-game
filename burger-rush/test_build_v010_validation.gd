extends SceneTree

# =============================================================================
# BURGER RUSH — TESTE AUTOMATIZADO DA FASE 7 (VALIDAÇÃO DO BUILD v0.1.0)
#
# Valida o ciclo de vida completo do executável/build:
# 1. Boot no Menu Principal (run/main_scene).
# 2. Estado inicial limpo (CONTINUAR desabilitado).
# 3. Criação de nova carreira (Slot 1: "Teste Build").
# 4. Execução do Tutorial e avanço para o Dia 1 às 08:00.
# 5. Persistência real em user://saves/ e fechamento da sessão.
# 6. Reabertura (novo boot), detecção de save e CONTINUAR habilitado.
# 7. Restauração fiel de dados (player_name, money, day, tutorial_completed).
# 8. Isolamento estrito de múltiplos slots (Slot 1 vs Slot 2).
# =============================================================================

const GameManagerClass = preload("res://src/core/game_manager.gd")
const SaveManagerClass = preload("res://src/core/save_manager.gd")
const GameClockClass = preload("res://src/time/game_clock.gd")
const EconomyManagerClass = preload("res://src/economy/economy_manager.gd")

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
	call_deferred("run_tests")

func run_tests() -> void:
	print("\n=================================================================")
	print("=== TESTE FASE 7: VALIDAÇÃO DO BUILD STANDALONE v0.1.0 ===")
	print("=================================================================\n")

	await test_main_menu_clean_boot()
	await test_new_game_and_tutorial_flow()
	await test_save_and_reopen_continue_flow()
	await test_multi_slot_independence()

	print("\n=================================================================")
	print("RESULTADO FINAL DA FASE 7: %d/%d APROVADOS" % [pass_count, total_count])
	print("=================================================================\n")

	if pass_count == total_count:
		print(">>> SUCESSO TOTAL: BUILD v0.1.0 100% VALIDADO COM ÊXITO! <<<\n")
		quit(0)
	else:
		printerr(">>> ERRO: FALHAS NA VALIDAÇÃO DO BUILD v0.1.0! <<<\n")
		quit(1)

func test_main_menu_clean_boot() -> void:
	print("--- TESTE 1: Inicialização Limpa e Menu Principal ---")

	var gm = GameManagerClass.new()
	root.add_child(gm)
	GameManagerClass.instance = gm

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir("user://saves_test_build_v010")
	root.add_child(sm)
	SaveManagerClass.instance = sm

	# Garante diretório de teste limpo
	sm.delete_save(1)
	sm.delete_save(2)

	var menu_scene = load("res://src/ui/main_menu.tscn")
	assert_test(menu_scene != null, "Cena do Menu Principal (res://src/ui/main_menu.tscn) carregada")

	var menu = menu_scene.instantiate()
	root.add_child(menu)
	await process_frame

	assert_test(menu != null, "Menu Principal instanciado com sucesso")
	assert_test(menu.play_button != null, "Botão JOGAR presente no Menu")
	assert_test(menu.continue_button != null, "Botão CONTINUAR presente no Menu")
	assert_test(menu.settings_button != null, "Botão CONFIGURAÇÕES presente no Menu")
	assert_test(menu.quit_button != null, "Botão SAIR presente no Menu")
	assert_test(menu.continue_button.disabled == true, "Botão CONTINUAR inicia desabilitado quando não há save")

	menu.queue_free()
	gm.queue_free()
	sm.queue_free()
	await process_frame

func test_new_game_and_tutorial_flow() -> void:
	print("\n--- TESTE 2: Fluxo de Nova Carreira, Tutorial e Início do Dia 1 ---")

	var gm = GameManagerClass.new()
	root.add_child(gm)
	GameManagerClass.instance = gm

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir("user://saves_test_build_v010")
	root.add_child(sm)
	SaveManagerClass.instance = sm

	var eco = EconomyManagerClass.new()
	root.add_child(eco)
	EconomyManagerClass.instance = eco

	# Cria nova carreira no Slot 1
	var career_created = sm.create_new_career(1, "Teste Build")
	assert_test(career_created == true, "Nova carreira criada com sucesso no Slot 1")
	assert_test(sm.pending_save_data.get("player_name") == "Teste Build", "Nome do chefe 'Teste Build' registrado")
	assert_test(sm.pending_save_data.get("tutorial_completed") == false, "Carreira inicia com tutorial_completed = false")
	assert_test(sm.pending_save_data.get("tutorial_step") == 0, "Carreira inicia na etapa 0 do tutorial")

	# Mock da cena Main para o tutorial
	var main_scene = Node3D.new()
	main_scene.name = "Main"
	root.add_child(main_scene)
	current_scene = main_scene

	var clock = GameClockClass.new()
	main_scene.add_child(clock)
	GameClockClass.instance = clock

	var tut = load("res://src/ui/tutorial.tscn").instantiate()
	main_scene.add_child(tut)
	tut.name = "Tutorial"
	await process_frame

	assert_test(tut != null, "Tutorial carregado na cena de jogo")
	assert_test(clock.is_paused == true, "Relógio do jogo pausado durante o tutorial")

	# Conclui o tutorial e inicia o Dia 1
	tut._complete_tutorial(false)
	assert_test(sm.pending_save_data.get("tutorial_completed") == true, "tutorial_completed atualizado para true")
	assert_test(gm.current_state == GameManagerClass.GameState.PLAYING, "GameManager transitou para o estado PLAYING")
	assert_test(clock.is_paused == false, "Relógio do jogo despausado")
	assert_test(clock.current_hour == 8 and clock.current_minute == 0, "Dia 1 iniciado pontualmente às 08:00")
	assert_test(clock.state == GameClockClass.State.PREPARATION, "Dia 1 iniciado na fase de PREPARAÇÃO")

	# Salva e fecha sessão
	sm.save_game(1)
	assert_test(sm.has_valid_save(1) == true, "Save do Slot 1 gravado no disco com sucesso")

	main_scene.queue_free()
	gm.queue_free()
	sm.queue_free()
	eco.queue_free()
	await process_frame

func test_save_and_reopen_continue_flow() -> void:
	print("\n--- TESTE 3: Simulação de Fechar e Reabrir (CONTINUAR) ---")

	# Simula nova inicialização limpa do aplicativo
	var gm = GameManagerClass.new()
	root.add_child(gm)
	GameManagerClass.instance = gm

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir("user://saves_test_build_v010")
	root.add_child(sm)
	SaveManagerClass.instance = sm

	var menu_scene = load("res://src/ui/main_menu.tscn")
	var menu = menu_scene.instantiate()
	root.add_child(menu)
	await process_frame

	assert_test(sm.has_any_save() == true, "SaveManager detectou a existência de save prévio")
	assert_test(menu.continue_button.disabled == false, "Botão CONTINUAR habilitado automaticamente no Menu Principal")

	# Carrega Slot 1
	var loaded_data = sm.load_game(1)
	assert_test(not loaded_data.is_empty(), "Dados do Slot 1 carregados com sucesso do disco")
	assert_test(loaded_data.get("player_name") == "Teste Build", "Nome do chefe 'Teste Build' restaurado perfeitamente")
	assert_test(loaded_data.get("tutorial_completed") == true, "Flag tutorial_completed restaurada como true")
	assert_test(loaded_data.get("day") == 1, "Dia 1 restaurado corretamente")
	assert_test(loaded_data.get("money") == 100.0, "Saldo inicial de R$ 100.00 restaurado corretamente")

	menu.queue_free()
	gm.queue_free()
	sm.queue_free()
	await process_frame

func test_multi_slot_independence() -> void:
	print("\n--- TESTE 4: Teste dos Dois Slots e Isolamento Estrito ---")

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir("user://saves_test_build_v010")
	root.add_child(sm)
	SaveManagerClass.instance = sm

	# Cria Slot 2 com outro chefe e valores distintos
	sm.create_new_career(2, "Teste Build B")
	sm.pending_save_data["money"] = 450.50
	sm.pending_save_data["current_day"] = 3
	sm.pending_save_data["day"] = 3
	sm.pending_save_data["tutorial_completed"] = true
	sm.save_game(2)

	assert_test(sm.has_valid_save(1) == true, "Slot 1 permanece válido")
	assert_test(sm.has_valid_save(2) == true, "Slot 2 gravado com sucesso")

	var slot1_data = sm.load_game(1)
	var slot2_data = sm.load_game(2)

	assert_test(slot1_data.get("player_name") == "Teste Build", "Slot 1 preserva nome 'Teste Build'")
	assert_test(slot1_data.get("money") == 100.0, "Slot 1 preserva dinheiro R$ 100.00")
	assert_test(slot1_data.get("day") == 1, "Slot 1 preserva Dia 1")

	assert_test(slot2_data.get("player_name") == "Teste Build B", "Slot 2 preserva nome 'Teste Build B'")
	assert_test(slot2_data.get("money") == 450.50, "Slot 2 preserva dinheiro R$ 450.50")
	assert_test(slot2_data.get("day") == 3, "Slot 2 preserva Dia 3")

	# Limpa saves de teste
	sm.delete_save(1)
	sm.delete_save(2)
	assert_test(sm.has_any_save() == false, "Diretório de saves de teste limpo com sucesso")

	sm.queue_free()
	await process_frame
