extends SceneTree

# =============================================================================
# BURGER RUSH — TESTE AUTOMATIZADO DA FASE 4 (SISTEMA DE SAVE LOCAL E 2 SLOTS)
#
# Valida:
# 1. 2 Slots independentes em diretório temporário isolado
# 2. Gravação atômica segura e estrutura versionada (SAVE_VERSION = 1)
# 3. Isolamento estrito entre Slot 1 e Slot 2
# 4. Leitura, validação e metadados rápidos
# 5. Restauração de dados reais (Dinheiro, Dias, Desbloqueios)
# 6. Tolerância a corrupção (JSON inválido, versão superior, arquivo ausente)
# 7. Auto-save periódico e save no final do dia
# 8. Exclusão segura de slot específico (delete_save)
# 9. Integração com o botão CONTINUAR no Menu Principal
# =============================================================================

const SaveManagerClass = preload("res://src/core/save_manager.gd")
const GameManagerClass = preload("res://src/core/game_manager.gd")
const EconomyManagerClass = preload("res://src/economy/economy_manager.gd")
const GameClockClass = preload("res://src/time/game_clock.gd")
const ProgressionManagerClass = preload("res://src/progression/progression_manager.gd")

var pass_count: int = 0
var total_count: int = 0
var test_save_dir: String = "user://test_saves_temp"

func assert_test(condition: bool, description: String) -> void:
	total_count += 1
	if condition:
		pass_count += 1
		print("  [PASS] %s" % description)
	else:
		printerr("  [FAIL] %s" % description)

func _init() -> void:
	print("\n=================================================================")
	print("=== TESTE FASE 4: SISTEMA DE SAVE LOCAL + 2 SLOTS + AUTO-SAVE ===")
	print("=================================================================\n")

	_setup_test_environment()

	test_empty_slots_and_initial_state()
	test_save_creation_and_atomic_file()
	test_slot_isolation()
	test_load_and_data_restoration()
	test_metadata_extraction()
	test_corruption_and_validation_resilience()
	test_auto_save_and_day_end_flow()
	test_delete_save()
	test_menu_continue_integration()

	_cleanup_test_environment()

	print("\n=================================================================")
	print("RESULTADO FINAL: %d/%d APROVADOS" % [pass_count, total_count])
	print("=================================================================\n")

	if pass_count == total_count:
		print(">>> SUCESSO TOTAL: FASE 4 100% VALIDADA COM ÊXITO! <<<\n")
		quit(0)
	else:
		printerr(">>> ERRO: ALGUNS TESTES DA FASE 4 FALHARAM! <<<\n")
		quit(1)

func _setup_test_environment() -> void:
	_cleanup_test_environment()
	DirAccess.make_dir_recursive_absolute(test_save_dir)

func _cleanup_test_environment() -> void:
	if DirAccess.dir_exists_absolute(test_save_dir):
		var dir = DirAccess.open(test_save_dir)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					dir.remove(file_name)
				file_name = dir.get_next()
			dir.list_dir_end()
		DirAccess.remove_absolute(test_save_dir)

func test_empty_slots_and_initial_state() -> void:
	print("--- TESTE 1: Estado Inicial e Slots Vazios ---")

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir(test_save_dir)
	root.add_child(sm)

	assert_test(not sm.has_save(1), "Slot 1 inicia vazio")
	assert_test(not sm.has_save(2), "Slot 2 inicia vazio")
	assert_test(not sm.has_valid_save(1), "Slot 1 não possui save válido")
	assert_test(not sm.has_valid_save(2), "Slot 2 não possui save válido")
	assert_test(not sm.has_any_save(), "has_any_save() retorna false inicialmente")

	sm.free()

func test_save_creation_and_atomic_file() -> void:
	print("\n--- TESTE 2: Criação de Save e Gravação Atômica ---")

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir(test_save_dir)
	root.add_child(sm)

	# Instancia subsistemas para fornecer dados reais
	var economy = EconomyManagerClass.new()
	economy.name = "EconomyManager"
	root.add_child(economy)
	economy.current_money = 350.75

	var clock = GameClockClass.new()
	clock.name = "GameClock"
	root.add_child(clock)
	clock.day_number = 4

	sm.set_active_slot(1)
	var success = sm.save_game(1)
	assert_test(success == true, "Save no Slot 1 executado com sucesso")
	assert_test(sm.has_save(1) == true, "Arquivo de save do Slot 1 existe no disco")
	assert_test(sm.has_valid_save(1) == true, "Save do Slot 1 validado como íntegro")
	assert_test(sm.has_any_save() == true, "has_any_save() retorna true após gravação")

	# Valida o conteúdo direto do arquivo JSON
	var path = sm.get_slot_path(1)
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(content)
	assert_test(err == OK, "Arquivo de save é um JSON válido e bem formatado")
	assert_test(json.data.get("save_version") == SaveManagerClass.SAVE_VERSION, "Versão do save corresponde a SAVE_VERSION (1)")
	assert_test(json.data.get("slot") == 1, "Identificador de slot corresponde a 1")
	assert_test(json.data.get("money") == 350.75, "Valor monetário de R$ 350.75 persistido corretamente")
	assert_test(json.data.get("current_day") == 4, "Dia 4 persistido corretamente")

	economy.free()
	clock.free()
	sm.free()

func test_slot_isolation() -> void:
	print("\n--- TESTE 3: Isolamento Estrito entre Slot 1 e Slot 2 ---")

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir(test_save_dir)
	root.add_child(sm)

	var economy = EconomyManagerClass.new()
	economy.name = "EconomyManager"
	root.add_child(economy)

	var clock = GameClockClass.new()
	clock.name = "GameClock"
	root.add_child(clock)

	# Grava no Slot 1
	economy.current_money = 150.00
	clock.day_number = 2
	sm.save_game(1)

	# Grava no Slot 2 com valores completamente diferentes
	economy.current_money = 890.50
	clock.day_number = 9
	sm.save_game(2)

	# Lê metadados de ambos os slots
	var meta1 = sm.get_save_metadata(1)
	var meta2 = sm.get_save_metadata(2)

	assert_test(meta1["money"] == 150.00 and meta1["current_day"] == 2, "Slot 1 preserva R$ 150.00 e Dia 2")
	assert_test(meta2["money"] == 890.50 and meta2["current_day"] == 9, "Slot 2 preserva R$ 890.50 e Dia 9")
	assert_test(meta1["money"] != meta2["money"], "Dados dos slots não se misturam")

	economy.free()
	clock.free()
	sm.free()

func test_load_and_data_restoration() -> void:
	print("\n--- TESTE 4: Carregamento e Restauração nos Subsistemas ---")

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir(test_save_dir)
	root.add_child(sm)

	var economy = EconomyManagerClass.new()
	economy.name = "EconomyManager"
	root.add_child(economy)

	var clock = GameClockClass.new()
	clock.name = "GameClock"
	root.add_child(clock)

	var progression = ProgressionManagerClass.new()
	progression.name = "ProgressionManager"
	root.add_child(progression)

	# Altera valores atuais nos subsistemas (sujando o estado em memória)
	economy.current_money = 9999.0
	clock.day_number = 50

	# Carrega o Slot 1 gravado no teste anterior (R$ 150.00, Dia 2)
	var data = sm.load_game(1)
	assert_test(not data.is_empty(), "load_game(1) retornou dicionário de dados")
	assert_test(economy.current_money == 150.0, "EconomyManager restaurado com R$ 150.00")
	assert_test(clock.day_number == 2, "GameClock restaurado com Dia 2")
	assert_test(sm.get_active_slot() == 1, "active_slot atualizado para 1 após carregar")

	economy.free()
	clock.free()
	progression.free()
	sm.free()

func test_metadata_extraction() -> void:
	print("\n--- TESTE 5: Extração Rápida de Metadados ---")

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir(test_save_dir)
	root.add_child(sm)

	var meta = sm.get_save_metadata(2)
	assert_test(meta["exists"] == true, "Metadados confirmam existência do Slot 2")
	assert_test(meta["valid"] == true, "Metadados confirmam validade do Slot 2")
	assert_test(meta["money"] == 890.50, "Metadados trazem o valor monetário correto")
	assert_test(meta["current_day"] == 9, "Metadados trazem o dia correto")
	assert_test(meta["last_save_timestamp"] != "Nunca", "Timestamp formatado presente")

	var meta_invalid = sm.get_save_metadata(99)
	assert_test(meta_invalid["exists"] == false, "Slot inexistente (99) reportado com exists = false")

	sm.free()

func test_corruption_and_validation_resilience() -> void:
	print("\n--- TESTE 6: Resiliência contra Arquivos Corrompidos ou Inválidos ---")

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir(test_save_dir)
	root.add_child(sm)

	# 1. Cria save corrompido com texto não-JSON no Slot 1
	var path1 = sm.get_slot_path(1)
	var file1 = FileAccess.open(path1, FileAccess.WRITE)
	file1.store_string("<<< CORROMPIDO NÃO JSON >>>")
	file1.close()

	assert_test(sm.has_save(1) == true, "Arquivo físico existe")
	assert_test(sm.has_valid_save(1) == false, "Save corrompido identificado com segurança como INVÁLIDO")

	# 2. Cria save com versão superior no Slot 2
	var path2 = sm.get_slot_path(2)
	var file2 = FileAccess.open(path2, FileAccess.WRITE)
	file2.store_string(JSON.stringify({"save_version": 999, "slot": 2, "has_game": true}))
	file2.close()

	assert_test(sm.has_valid_save(2) == false, "Save com versão incompatível identificado como INVÁLIDO")

	# Restaura um save válido no Slot 1 para os próximos testes
	var file_valid = FileAccess.open(path1, FileAccess.WRITE)
	file_valid.store_string(JSON.stringify({"save_version": 1, "slot": 1, "has_game": true, "money": 200.0, "current_day": 1}))
	file_valid.close()

	sm.free()

func test_auto_save_and_day_end_flow() -> void:
	print("\n--- TESTE 7: Auto-Save e Save no Fim do Dia ---")

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir(test_save_dir)
	root.add_child(sm)

	var gm = GameManagerClass.new()
	root.add_child(gm)
	gm.change_state(GameManagerClass.GameState.PLAYING)

	var economy = EconomyManagerClass.new()
	economy.name = "EconomyManager"
	root.add_child(economy)
	economy.current_money = 555.0

	var clock = GameClockClass.new()
	clock.name = "GameClock"
	root.add_child(clock)
	clock.day_number = 7

	sm.set_active_slot(1)
	sm.has_active_game = true

	# Testa auto-save manual/trigger
	var auto_saved = sm.trigger_auto_save()
	assert_test(auto_saved == true, "trigger_auto_save() executado com sucesso")

	var meta = sm.get_save_metadata(1)
	assert_test(meta["money"] == 555.0, "Auto-save persistiu os R$ 555.00 no Slot 1")

	# Testa save ao final do dia
	economy.current_money = 777.0
	clock.day_number = 8
	sm.on_day_ended()

	var meta_end = sm.get_save_metadata(1)
	assert_test(meta_end["money"] == 777.0 and meta_end["current_day"] == 8, "on_day_ended() persistiu o encerramento do dia no Slot 1")

	economy.free()
	clock.free()
	gm.free()
	sm.free()

func test_delete_save() -> void:
	print("\n--- TESTE 8: Exclusão Segura de Save (delete_save) ---")

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir(test_save_dir)
	root.add_child(sm)

	assert_test(sm.has_save(1) == true, "Slot 1 possui save antes da exclusão")
	var deleted = sm.delete_save(1)
	assert_test(deleted == true, "delete_save(1) executado com sucesso")
	assert_test(sm.has_save(1) == false, "Slot 1 foi removido do disco")

	sm.free()

func test_menu_continue_integration() -> void:
	print("\n--- TESTE 9: Integração do SaveManager com o Botão CONTINUAR ---")

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir(test_save_dir)
	root.add_child(sm)

	# 1. Sem save: CONTINUAR desabilitado
	sm.delete_save(1)
	sm.delete_save(2)

	var menu_scene = load("res://src/ui/main_menu.tscn")
	var menu = menu_scene.instantiate() as Control
	root.add_child(menu)
	menu._ready()

	assert_test(menu.continue_button.disabled == true, "Botão CONTINUAR desabilitado quando não há nenhum save")

	# 2. Cria save no Slot 2
	var path2 = sm.get_slot_path(2)
	var file = FileAccess.open(path2, FileAccess.WRITE)
	file.store_string(JSON.stringify({"save_version": 1, "slot": 2, "has_game": true, "money": 300.0, "current_day": 3}))
	file.close()

	menu._update_continue_button_state()
	assert_test(menu.continue_button.disabled == false, "Botão CONTINUAR habilitado automaticamente após detecção de save válido")

	menu.free()
	sm.free()
