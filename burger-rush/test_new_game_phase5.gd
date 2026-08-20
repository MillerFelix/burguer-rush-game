extends SceneTree

# =============================================================================
# BURGER RUSH — TESTE AUTOMATIZADO DA FASE 5 (NOVO JOGO + HISTÓRIA + CHEFE)
#
# Valida:
# 1. Menu Principal com Seleção de 2 Slots para Novo Jogo e Continuar
# 2. Proteção contra sobrescrita com modal de confirmação (Cancelar / Substituir)
# 3. Cena de História com 5 painéis narrativos e pulo para criação do chefe
# 4. Criação do nome do chefe com sanitização e validação de strings vazias
# 5. Gravação da nova carreira no slot selecionado (SaveManager.create_new_career)
# 6. Preparação e transição de estado para GameState.TUTORIAL
# 7. Isolamento de dados e preservação do fluxo CONTINUAR
# =============================================================================

const SaveManagerClass = preload("res://src/core/save_manager.gd")
const GameManagerClass = preload("res://src/core/game_manager.gd")
const IntroStoryScript = preload("res://src/ui/intro_story.gd")

var pass_count: int = 0
var total_count: int = 0
var test_save_dir: String = "user://test_phase5_saves"

func assert_test(condition: bool, description: String) -> void:
	total_count += 1
	if condition:
		pass_count += 1
		print("  [PASS] %s" % description)
	else:
		printerr("  [FAIL] %s" % description)

func _init() -> void:
	print("\n=================================================================")
	print("=== TESTE FASE 5: SELEÇÃO DE SLOTS + HISTÓRIA + NOME DO CHEFE ===")
	print("=================================================================\n")

	_setup_test_environment()

	test_slot_selection_ui_and_modes()
	test_overwrite_protection_flow()
	test_intro_story_flow_and_panels()
	test_chef_name_validation_and_creation()
	test_new_career_save_persistence()
	test_continue_slot_selection_flow()

	_cleanup_test_environment()

	print("\n=================================================================")
	print("RESULTADO FINAL: %d/%d APROVADOS" % [pass_count, total_count])
	print("=================================================================\n")

	if pass_count == total_count:
		print(">>> SUCESSO TOTAL: FASE 5 100% VALIDADA COM ÊXITO! <<<\n")
		quit(0)
	else:
		printerr(">>> ERRO: ALGUNS TESTES DA FASE 5 FALHARAM! <<<\n")
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

func test_slot_selection_ui_and_modes() -> void:
	print("--- TESTE 1: Interface de Seleção de Slots no Menu ---")

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir(test_save_dir)
	root.add_child(sm)

	var menu_scene = load("res://src/ui/main_menu.tscn")
	var menu = menu_scene.instantiate() as Control
	root.add_child(menu)
	menu._ready()

	assert_test(menu.slot_select_overlay != null, "Overlay SlotSelectOverlay presente na cena")
	assert_test(menu.slot_select_overlay.visible == false, "SlotSelectOverlay inicia oculto")

	# Clica em JOGAR
	menu.play_button.emit_signal("pressed")
	assert_test(menu.slot_select_overlay.visible == true, "SlotSelectOverlay visível após clicar em JOGAR")
	assert_test(menu._current_slot_mode == menu.SlotMode.NEW_GAME, "Modo de seleção configurado para NEW_GAME")
	assert_test(menu.slot1_button.text == "CRIAR CARREIRA", "Slot 1 vazio exibe 'CRIAR CARREIRA'")
	assert_test(menu.slot2_button.text == "CRIAR CARREIRA", "Slot 2 vazio exibe 'CRIAR CARREIRA'")

	# Fecha a seleção
	menu.back_slot_select_button.emit_signal("pressed")
	assert_test(menu.slot_select_overlay.visible == false, "SlotSelectOverlay fechado após voltar")

	menu.free()
	sm.free()

func test_overwrite_protection_flow() -> void:
	print("\n--- TESTE 2: Proteção contra Sobrescrita Acidental de Save ---")

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir(test_save_dir)
	root.add_child(sm)

	# Cria save pré-existente no Slot 1
	var path1 = sm.get_slot_path(1)
	var file1 = FileAccess.open(path1, FileAccess.WRITE)
	file1.store_string(JSON.stringify({
		"save_version": 1,
		"slot": 1,
		"has_game": true,
		"player_name": "Veterano",
		"current_day": 15,
		"money": 3500.0
	}))
	file1.close()

	var menu_scene = load("res://src/ui/main_menu.tscn")
	var menu = menu_scene.instantiate() as Control
	root.add_child(menu)
	menu._ready()

	# Abre JOGAR e seleciona Slot 1 ocupado
	menu.play_button.emit_signal("pressed")
	menu.slot1_button.emit_signal("pressed")

	assert_test(menu.overwrite_confirm_overlay.visible == true, "Modal de confirmação de sobrescrita EXIBIDO para slot ocupado")
	assert_test("Veterano" in menu.warn_message.text, "Mensagem de aviso cita o nome do chefe existente ('Veterano')")

	# Simula CANCELAR
	menu.cancel_overwrite_button.emit_signal("pressed")
	assert_test(menu.overwrite_confirm_overlay.visible == false, "Modal de confirmação ocultado após CANCELAR")

	# Verifica se o save do Slot 1 continua intacto
	var meta_after_cancel = sm.get_save_metadata(1)
	assert_test(meta_after_cancel["player_name"] == "Veterano" and meta_after_cancel["current_day"] == 15, "Save original permaneceu 100% INTACTO após Cancelar")

	menu.free()
	sm.free()

func test_intro_story_flow_and_panels() -> void:
	print("\n--- TESTE 3: Cena de História, Navegação e Avanço ---")

	var gm = GameManagerClass.new()
	root.add_child(gm)

	var story_scene = load("res://src/ui/intro_story.tscn")
	var story = story_scene.instantiate() as Control
	root.add_child(story)
	story._ready()

	assert_test(gm.get_state() == GameManagerClass.GameState.STORY, "GameManager transitou para o estado STORY")
	assert_test(story.story_panel.visible == true, "Painel de história visível inicialmente")
	assert_test(story.name_modal.visible == false, "Modal de nome do chefe inicia oculto")
	assert_test(story.step_label.text == "1 / 5", "História inicia no painel 1 / 5")

	# Avança painéis
	story.next_button.emit_signal("pressed")
	assert_test(story.step_label.text == "2 / 5", "História avançou para o painel 2 / 5")

	story.next_button.emit_signal("pressed")
	assert_test(story.step_label.text == "3 / 5", "História avançou para o painel 3 / 5")

	# Pular história leva direto ao modal de nome
	story.skip_button.emit_signal("pressed")
	assert_test(story.story_panel.visible == false, "Painel de história oculto após PULAR")
	assert_test(story.name_modal.visible == true, "Modal de nome do chefe EXIBIDO após PULAR")

	story.free()
	gm.free()

func test_chef_name_validation_and_creation() -> void:
	print("\n--- TESTE 4: Validação do Nome do Chefe ---")

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir(test_save_dir)
	root.add_child(sm)

	var gm = GameManagerClass.new()
	root.add_child(gm)

	var story_scene = load("res://src/ui/intro_story.tscn")
	var story = story_scene.instantiate() as Control
	story.target_slot = 2
	root.add_child(story)
	story._ready()
	story._open_name_modal()

	# 1. Tenta submeter nome vazio
	story.name_input.text = "   "
	story.confirm_button.emit_signal("pressed")
	assert_test(story.error_label.text != "", "Nome vazio rejeitado com mensagem de erro")
	assert_test(story.name_modal.visible == true, "Permanece no modal de criação")

	# 2. Submete nome válido com espaços nas extremidades
	story.name_input.text = "   Chef Miller   "
	story.confirm_button.emit_signal("pressed")

	assert_test(gm.get_state() == GameManagerClass.GameState.TUTORIAL or gm.get_state() == GameManagerClass.GameState.LOADING, "GameManager avançou para a preparação do TUTORIAL")

	# Verifica o save gerado no Slot 2
	var meta = sm.get_save_metadata(2)
	assert_test(meta["valid"] == true, "Nova carreira criada com sucesso no Slot 2")
	assert_test(meta["player_name"] == "Chef Miller", "Nome do chefe sanitizado e persistido como 'Chef Miller'")
	assert_test(meta["current_day"] == 1, "Nova carreira inicia no Dia 1")
	assert_test(meta["money"] == 100.0, "Nova carreira inicia com saldo padrão de R$ 100.00")

	story.free()
	gm.free()
	sm.free()

func test_new_career_save_persistence() -> void:
	print("\n--- TESTE 5: Persistência e Isolamento de Múltiplas Carreiras ---")

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir(test_save_dir)
	root.add_child(sm)

	# Cria carreira no Slot 1
	sm.create_new_career(1, "Chef Alpha")
	# Cria carreira no Slot 2
	sm.create_new_career(2, "Chef Beta")

	var meta1 = sm.get_save_metadata(1)
	var meta2 = sm.get_save_metadata(2)

	assert_test(meta1["player_name"] == "Chef Alpha" and meta1["slot"] == 1, "Slot 1 persistido com Chef Alpha")
	assert_test(meta2["player_name"] == "Chef Beta" and meta2["slot"] == 2, "Slot 2 persistido com Chef Beta")
	assert_test(meta1["player_name"] != meta2["player_name"], "Isolamento total entre os dois slots garantido")

	sm.free()

func test_continue_slot_selection_flow() -> void:
	print("\n--- TESTE 6: Fluxo do Botão CONTINUAR com Seleção de Slots ---")

	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir(test_save_dir)
	root.add_child(sm)

	# Garante apenas Slot 2 preenchido
	sm.delete_save(1)
	sm.create_new_career(2, "Chef Continuidade")

	var menu_scene = load("res://src/ui/main_menu.tscn")
	var menu = menu_scene.instantiate() as Control
	root.add_child(menu)
	menu._ready()

	assert_test(menu.continue_button.disabled == false, "Botão CONTINUAR habilitado")

	# Abre CONTINUAR
	menu.continue_button.emit_signal("pressed")
	assert_test(menu.slot_select_overlay.visible == true, "Seleção de slots aberta no modo CONTINUAR")
	assert_test(menu.slot1_button.disabled == true, "Slot 1 desabilitado no CONTINUAR (está vazio)")
	assert_test(menu.slot2_button.disabled == false, "Slot 2 habilitado no CONTINUAR (possui save)")
	assert_test(menu.slot2_button.text == "CARREGAR", "Botão do Slot 2 exibe 'CARREGAR'")

	menu.free()
	sm.free()
