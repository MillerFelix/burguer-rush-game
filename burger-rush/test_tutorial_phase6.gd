extends SceneTree

# =============================================================================
# BURGER RUSH — TESTE AUTOMATIZADO DA FASE 6 (TUTORIAL E FLUXO JOGÁVEL)
#
# Valida:
# 1. Carreira nova entra no tutorial (estado correto, cena instanciada).
# 2. Funcionamento de todas as etapas (movimentação, PC, pickup, chapa, montagem,
#    embalagem, bandeja, limpeza, finalização).
# 3. Persistência do tutorial no SaveManager (tutorial_completed, tutorial_step).
# 4. Skip/Pular Tutorial com confirmação (Dia 1 às 08:00 iniciado).
# 5. Continue Flow (continua da etapa correta ou não abre se já concluído).
# 6. Preservação de dados da carreira (player_name, money, progressão).
# =============================================================================

const GameManagerClass = preload("res://src/core/game_manager.gd")
const SaveManagerClass = preload("res://src/core/save_manager.gd")
const PlayerClass = preload("res://src/player/player.gd")
const ComputerStationClass = preload("res://src/stations/computer_station.gd")
const MeatRefrigeratorClass = preload("res://src/stations/commercial_refrigerator.gd")
const GrillClass = preload("res://src/stations/grill.gd")
const PrepIslandClass = preload("res://src/stations/prep_island.gd")
const GameClockClass = preload("res://src/time/game_clock.gd")
const PowerManagerClass = preload("res://src/core/power_manager.gd")

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
	print("=== TESTE FASE 6: TUTORIAL INICIAL E PRIMEIRO FLUXO JOGÁVEL ===")
	print("=================================================================\n")

	await test_tutorial_initialization_and_steps()
	await test_tutorial_skip_flow()
	await test_tutorial_persistence_and_continue()

	print("\n=================================================================")
	print("RESULTADO FINAL DA FASE 6: %d/%d APROVADOS" % [pass_count, total_count])
	print("=================================================================\n")

	if pass_count == total_count:
		print(">>> SUCESSO TOTAL: FASE 6 100% VALIDADA! <<<\n")
		quit(0)
	else:
		printerr(">>> ERRO: ALGUNS TESTES DA FASE 6 FALHARAM! <<<\n")
		quit(1)

func test_tutorial_initialization_and_steps() -> void:
	print("--- TESTE 1: Inicialização do Tutorial e Etapas de Gameplay ---")

	# Instancia dependências
	var gm = GameManagerClass.new()
	root.add_child(gm)
	GameManagerClass.instance = gm
	
	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir("user://saves_test_phase6")
	root.add_child(sm)
	SaveManagerClass.instance = sm

	var pm = PowerManagerClass.new()
	root.add_child(pm)
	PowerManagerClass.instance = pm

	# Cria uma cena Mock / Main
	var main_scene = Node3D.new()
	main_scene.name = "Main"
	root.add_child(main_scene)
	current_scene = main_scene

	var clock = GameClockClass.new()
	main_scene.add_child(clock)
	GameClockClass.instance = clock

	var player = PlayerClass.new()
	# Estrutura de nos esperados pelo script do player
	var head = Node3D.new()
	head.name = "Head"
	player.add_child(head)
	
	var cam = Camera3D.new()
	cam.name = "Camera3D"
	head.add_child(cam)
	
	var ray = RayCast3D.new()
	ray.name = "RayCast3D"
	cam.add_child(ray)
	
	var hold = Node3D.new()
	hold.name = "HoldPosition"
	cam.add_child(hold)
	
	var hud = Control.new()
	hud.name = "HUD"
	var hud_script = GDScript.new()
	hud_script.source_code = "extends Control\nfunc show_prompt(text: String) -> void:\n\tpass\nfunc hide_prompt() -> void:\n\tpass\nfunc show_temporary_feedback(msg: String) -> void:\n\tpass\nfunc update_carried_items(items: Array) -> void:\n\tpass"
	hud_script.reload()
	hud.set_script(hud_script)
	player.add_child(hud)
	
	main_scene.add_child(player)
	player.name = "Player"

	var pc = ComputerStationClass.new()
	var pc_ui = CanvasLayer.new()
	pc_ui.set_script(load("res://src/ui/computer_ui.gd"))
	pc_ui.name = "ComputerUI"
	pc_ui.visible = false
	pc.computer_ui_instance = pc_ui
	main_scene.add_child(pc)
	pc.name = "ComputerStation"

	var fridge = MeatRefrigeratorClass.new()
	main_scene.add_child(fridge)
	fridge.name = "MeatRefrigerator"

	var grill = GrillClass.new()
	var cooking_slot = Marker3D.new()
	cooking_slot.name = "CookingSlot"
	grill.add_child(cooking_slot)
	main_scene.add_child(grill)
	grill.name = "Grill"

	var island = PrepIslandClass.new()
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	island.add_child(col)
	main_scene.add_child(island)
	island.name = "PrepIsland"

	# Instancia o tutorial
	var tut = load("res://src/ui/tutorial.tscn").instantiate()
	main_scene.add_child(tut)
	tut.name = "Tutorial"

	# Aguarda frame para rodar ready de todos os nós
	await process_frame

	assert_test(tut != null, "Tutorial instanciado com sucesso")
	assert_test(gm.current_state == GameManagerClass.GameState.BOOT, "Estado do GameManager inicializado")

	# Simula nova carreira criada
	sm.create_new_career(1, "Chef Test")
	assert_test(sm.pending_save_data.get("tutorial_completed") == false, "Carreira nova inicia com tutorial_completed = false")
	assert_test(sm.pending_save_data.get("tutorial_step") == 0, "Carreira nova inicia na etapa 0")
	assert_test(clock.is_paused == true, "Relógio do jogo pausado durante o tutorial")
	assert_test(pm.is_main_power_on == true, "Chave geral de energia ligada automaticamente para o tutorial")

	# 1. Teste Etapa 0: Movimentação
	assert_test(tut.current_step_index == 0, "Tutorial inicia na etapa 0: Movimentação")
	tut.step_start_pos = Vector3.ZERO
	tut.step_initialized = true
	player.global_position = Vector3(4.0, 0.0, 0.0) # Simula movimento de 4m
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 1, "Avançou para etapa 1 após movimentação")

	# 2. Teste Etapa 1: PC
	pc_ui.visible = true
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 2, "Avançou para etapa 2 após abrir o PC")

	# 3. Teste Etapa 2: Pegar Ingrediente
	var patty = load("res://src/items/patty.tscn").instantiate()
	main_scene.add_child(patty)
	patty.meat_type = 0 # BEEF
	patty.state = 0 # RAW
	player.held_item = patty
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 3, "Avançou para etapa 3 após pegar a carne")

	# 4. Teste Etapa 3: Colocar na chapa
	player.held_item = null
	grill.place_item(patty)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 4, "Avançou para etapa 4 após colocar na chapa")

	# 5. Teste Etapa 4: Virar carne
	patty.flip()
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 5, "Avançou para etapa 5 após virar com espátula")

	# 6. Teste Etapa 5: Retirar carne
	# Simula que a carne terminou de grelhar e o jogador a retirou
	patty.state = 4 # COOKED
	patty.side_a_cooked = 100.0
	patty.side_b_cooked = 100.0
	grill.active_items.clear()
	player.held_item = patty
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 6, "Avançou para etapa 6 após retirar carne pronta")

	# 7. Teste Etapa 6: Colocar pão inferior na bancada
	player.held_item = null
	var bread_bottom = load("res://src/items/bread_bottom.tscn").instantiate()
	main_scene.add_child(bread_bottom)
	var assembly_node = load("res://src/recipes/burger_assembly.tscn").instantiate()
	bread_bottom.assembly = assembly_node
	bread_bottom.add_child(assembly_node)
	island.placed_items.append(bread_bottom)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 7, "Avançou para etapa 7 após colocar BreadBottom na ilha")

	# 8. Teste Etapa 7: Adicionar carne ao pão
	bread_bottom.assembly.add_ingredient(patty)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 8, "Avançou para etapa 8 após adicionar carne ao lanche")

	# 9. Teste Etapa 8: Fechar o lanche
	var bread_top = load("res://src/items/bread_top.tscn").instantiate()
	main_scene.add_child(bread_top)
	bread_bottom.assembly.close_burger(bread_top, Vector3.ZERO)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 9, "Avançou para etapa 9 após fechar lanche")

	# 10. Teste Etapa 9: Embalar lanche
	# Simula lanche embalado na mão
	var packaged = load("res://src/items/packaged_burger.tscn").instantiate()
	main_scene.add_child(packaged)
	player.held_item = packaged
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 10, "Avançou para etapa 10 após embalar")

	# 11. Teste Etapa 10: Colocar na bandeja
	player.held_item = null
	var tray = load("res://src/items/serving_tray.tscn").instantiate()
	main_scene.add_child(tray)
	player.held_item = tray
	tray.add_product(packaged)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 11, "Avançou para etapa 11 após colocar lanche na bandeja")

	# 12. Teste Etapa 11: Limpeza da chapa
	grill.dirt_level = 0.0
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 12, "Avançou para etapa 12 (Conclusão) após chapa ser limpa")

	# Limpa
	tut.queue_free()
	main_scene.queue_free()
	gm.queue_free()
	sm.queue_free()
	pm.queue_free()
	await process_frame

func test_tutorial_skip_flow() -> void:
	print("\n--- TESTE 2: Fluxo de Pular Tutorial (Skip) e Início do Dia 1 ---")

	var gm = GameManagerClass.new()
	root.add_child(gm)
	GameManagerClass.instance = gm
	
	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir("user://saves_test_phase6")
	root.add_child(sm)
	SaveManagerClass.instance = sm

	var pm = PowerManagerClass.new()
	root.add_child(pm)
	PowerManagerClass.instance = pm

	var main_scene = Node3D.new()
	main_scene.name = "Main"
	root.add_child(main_scene)
	current_scene = main_scene

	var clock = GameClockClass.new()
	main_scene.add_child(clock)
	GameClockClass.instance = clock

	var player = PlayerClass.new()
	# Estrutura de nos esperados pelo script do player
	var head = Node3D.new()
	head.name = "Head"
	player.add_child(head)
	
	var cam = Camera3D.new()
	cam.name = "Camera3D"
	head.add_child(cam)
	
	var ray = RayCast3D.new()
	ray.name = "RayCast3D"
	cam.add_child(ray)
	
	var hold = Node3D.new()
	hold.name = "HoldPosition"
	cam.add_child(hold)
	
	var hud = Control.new()
	hud.name = "HUD"
	var hud_script = GDScript.new()
	hud_script.source_code = "extends Control\nfunc show_prompt(text: String) -> void:\n\tpass\nfunc hide_prompt() -> void:\n\tpass\nfunc show_temporary_feedback(msg: String) -> void:\n\tpass\nfunc update_carried_items(items: Array) -> void:\n\tpass"
	hud_script.reload()
	hud.set_script(hud_script)
	player.add_child(hud)
	
	main_scene.add_child(player)
	player.name = "Player"

	var pc = ComputerStationClass.new()
	var pc_ui = CanvasLayer.new()
	pc_ui.set_script(load("res://src/ui/computer_ui.gd"))
	pc_ui.name = "ComputerUI"
	pc_ui.visible = false
	pc.computer_ui_instance = pc_ui
	main_scene.add_child(pc)
	pc.name = "ComputerStation"

	var tut = load("res://src/ui/tutorial.tscn").instantiate()
	main_scene.add_child(tut)
	tut.name = "Tutorial"

	# Aguarda frame
	await process_frame

	sm.create_new_career(1, "Chef Miller")
	gm.change_state(GameManagerClass.GameState.TUTORIAL)

	# Simula o clique em pular e confirmação
	tut._on_skip_pressed()
	assert_test(tut.confirm_dialog.visible == true, "Diálogo de confirmação de skip foi exibido")
	assert_test(paused == true, "Jogo pausado durante o diálogo de skip")

	tut._on_confirm_skip_pressed()
	assert_test(paused == false, "Jogo despausado após confirmação de skip")
	assert_test(sm.pending_save_data.get("tutorial_completed") == true, "tutorial_completed salvo como true no SaveManager")
	assert_test(sm.pending_save_data.get("player_name") == "Chef Miller", "Nome do chefe 'Chef Miller' preservado com sucesso")
	assert_test(gm.current_state == GameManagerClass.GameState.PLAYING, "GameManager transitou para o estado PLAYING")
	assert_test(clock.is_paused == false, "Relógio do jogo despausado")
	assert_test(clock.current_hour == 9 and clock.current_minute == 0, "Dia 1 iniciou às 09:00")
	assert_test(clock.state == GameClockClass.State.PREPARATION, "Dia 1 iniciou na fase de PREPARAÇÃO")

	# Limpa
	main_scene.queue_free()
	gm.queue_free()
	sm.queue_free()
	pm.queue_free()
	await process_frame

func test_tutorial_persistence_and_continue() -> void:
	print("\n--- TESTE 3: Persistência do Passo e Comportamento do Continue ---")

	var gm = GameManagerClass.new()
	# Mantém gm fora da árvore inicialmente para evitar que continue_game agende transições de cena
	GameManagerClass.instance = gm
	
	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir("user://saves_test_phase6")
	root.add_child(sm)
	SaveManagerClass.instance = sm

	var pm = PowerManagerClass.new()
	root.add_child(pm)
	PowerManagerClass.instance = pm

	# 1. Simula progresso intermediário (etapa 4)
	sm.create_new_career(1, "Chef Alpha")
	sm.pending_save_data["tutorial_completed"] = false
	sm.pending_save_data["tutorial_step"] = 4
	sm.save_game(1)

	# Reseta e recarrega
	sm.pending_save_data = {}
	sm.has_active_game = false
	
	# Aguarda frame para garantir que os autoloads entraram na árvore
	await process_frame

	# Executa continuar fora da árvore (change_scene não agenda nada)
	gm.continue_game(1)
	
	# Adiciona gm à árvore
	root.add_child(gm)
	await process_frame
	
	# Carrega patty.tscn como base mock da cena Main e conclui loading
	var mock_scene_packed = load("res://src/items/patty.tscn")
	gm.complete_loading(mock_scene_packed)
	
	# Aguarda a transição assíncrona do change_scene_to_packed e o _instantiate_tutorial diferido
	await process_frame
	await process_frame

	# Agora adicionamos os filhos necessários à cena carregada para o tutorial continuar
	var main_scene = current_scene
	main_scene.name = "Main"
	
	var clock = GameClockClass.new()
	main_scene.add_child(clock)
	GameClockClass.instance = clock

	var player = PlayerClass.new()
	# Estrutura de nos esperados pelo script do player
	var head = Node3D.new()
	head.name = "Head"
	player.add_child(head)
	
	var cam = Camera3D.new()
	cam.name = "Camera3D"
	head.add_child(cam)
	
	var ray = RayCast3D.new()
	ray.name = "RayCast3D"
	cam.add_child(ray)
	
	var hold = Node3D.new()
	hold.name = "HoldPosition"
	cam.add_child(hold)
	
	var hud = Control.new()
	hud.name = "HUD"
	var hud_script = GDScript.new()
	hud_script.source_code = "extends Control\nfunc show_prompt(text: String) -> void:\n\tpass\nfunc hide_prompt() -> void:\n\tpass\nfunc show_temporary_feedback(msg: String) -> void:\n\tpass\nfunc update_carried_items(items: Array) -> void:\n\tpass"
	hud_script.reload()
	hud.set_script(hud_script)
	player.add_child(hud)
	
	main_scene.add_child(player)
	player.name = "Player"

	var pc = ComputerStationClass.new()
	var pc_ui = CanvasLayer.new()
	pc_ui.set_script(load("res://src/ui/computer_ui.gd"))
	pc_ui.name = "ComputerUI"
	pc_ui.visible = false
	pc.computer_ui_instance = pc_ui
	main_scene.add_child(pc)
	pc.name = "ComputerStation"

	# Aguarda frame para o tutorial processar as referências
	await process_frame

	assert_test(gm.current_state == GameManagerClass.GameState.TUTORIAL, "Continue direcionou jogador de volta ao TUTORIAL")

	var tut = main_scene.get_node_or_null("Tutorial")
	if tut == null:
		# Procura nos filhos
		for child in main_scene.get_children():
			if child.name == "Tutorial" or child.get_script() == load("res://src/ui/tutorial.gd"):
				tut = child
				break
	assert_test(tut != null, "Tutorial instanciado automaticamente pelo GameManager")
	if tut:
		assert_test(tut.current_step_index == 4, "Tutorial continuou corretamente do passo 4 salvo")

	# 2. Simula tutorial já concluído
	if tut:
		tut._complete_tutorial()
	
	# Remove gm da árvore para repetir a jogada
	root.remove_child(gm)
	
	sm.pending_save_data = {}
	sm.has_active_game = false

	# Executa continuar fora da árvore
	gm.continue_game(1)
	
	# Adiciona de volta
	root.add_child(gm)
	await process_frame
	
	var mock_scene_packed_2 = load("res://src/items/patty.tscn")
	gm.complete_loading(mock_scene_packed_2)
	await process_frame
	await process_frame
	
	var main_scene_2_actual = current_scene
	if main_scene_2_actual:
		main_scene_2_actual.name = "Main"
		var clock_2 = GameClockClass.new()
		main_scene_2_actual.add_child(clock_2)
		GameClockClass.instance = clock_2
	
	await process_frame
	
	assert_test(gm.current_state == GameManagerClass.GameState.PLAYING, "Continue direcionou jogador direto para PLAYING (tutorial concluído)")
	if main_scene_2_actual:
		assert_test(main_scene_2_actual.has_node("Tutorial") == false, "Tutorial não foi instanciado na cena")

	# Limpa
	if is_instance_valid(main_scene):
		main_scene.queue_free()
	if is_instance_valid(main_scene_2_actual):
		main_scene_2_actual.queue_free()
	gm.queue_free()
	sm.queue_free()
	pm.queue_free()
	await process_frame
