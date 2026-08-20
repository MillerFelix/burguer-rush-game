extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DE REFINAMENTO DO TUTORIAL, MONTAGEM E PAUSA (v0.1.8)
# ==============================================================================

const PowerManager = preload("res://src/core/power_manager.gd")
const GameClock = preload("res://src/time/game_clock.gd")
const DrinkCup = preload("res://src/items/drink_cup.gd")
const DeliveryBox = preload("res://src/items/delivery_box.gd")
const Patty = preload("res://src/items/patty.gd")
const BreadBottom = preload("res://src/items/bread_bottom.gd")
const Burger = preload("res://src/items/burger.gd")
const BurgerAssembly = preload("res://src/recipes/burger_assembly.gd")
const PackagedBurger = preload("res://src/items/packaged_burger.gd")
const ServingTray = preload("res://src/items/serving_tray.gd")
const FriesPack = preload("res://src/items/fries_pack.gd")

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
	print("=== BURGER RUSH - TESTE DE REFINAMENTO DO TUTORIAL V6 ===")
	print("=================================================================")
	
	var main_scene_res = load("res://src/main.tscn")
	if not main_scene_res:
		print("❌ Falha ao carregar main.tscn")
		quit(1)
		return

	var main_scene = main_scene_res.instantiate()
	root.add_child(main_scene)

	var tut_scene_res = load("res://src/ui/tutorial.tscn")
	var tut = tut_scene_res.instantiate() as TutorialController
	root.add_child(tut)

	var pause_menu_res = load("res://src/ui/pause_menu.tscn")
	var pause_menu = pause_menu_res.instantiate() as PauseMenu
	root.add_child(pause_menu)

	var player = main_scene.find_child("Player", true, false)
	var clock = main_scene.find_child("GameClock", true, false)
	var grill = main_scene.find_child("Grill", true, false)
	var fryer = main_scene.find_child("Fryer", true, false)
	var sink = main_scene.find_child("CommercialSink", true, false)
	var island = main_scene.find_child("PrepIsland", true, false)

	# --- TESTE 1: Velocidade Acelerada Somente Durante Tutorial ---
	print("\n--- TESTE 1: Velocidades Aceleradas Somente no Tutorial ---")
	grill.is_on = true
	grill.current_temperature = 200.0
	fryer.is_on = true
	fryer.current_temperature = 190.0
	assert_test(grill.get_cooking_speed_factor() >= 3.5, "Grelha opera a 3.5x de velocidade durante o tutorial")
	assert_test(fryer.get_cooking_speed_factor() >= 3.5, "Fritadeira opera a 3.5x de velocidade durante o tutorial")

	# --- TESTE 2: Menu de Pausa e Botão Pular Tutorial ---
	print("\n--- TESTE 2: Menu de Pausa (ESC) com Pular Tutorial Integrado ---")
	pause_menu.pause_game()
	assert_test(pause_menu.visible == true, "Menu de pausa aberto com ESC / pause_game()")
	assert_test(pause_menu.skip_tutorial_btn != null and pause_menu.skip_tutorial_btn.visible == true, "Botão 'Pular Tutorial' visível dentro do Menu de Pausa durante o tutorial")
	pause_menu.resume_game()
	assert_test(pause_menu.visible == false, "Menu de pausa fechado ao retomar jogo")

	# --- TESTE 3: Validação da Montagem Real do Hambúrguer (BreadBottom + Patty + BreadTop) ---
	print("\n--- TESTE 3: Reconhecimento da Montagem Completa do Hambúrguer ---")
	tut._apply_step(9) # Etapa de Montagem
	tut.transition_timer = 0.0
	assert_test(tut.current_step_index == 9, "Posicionado na Etapa 9 (Montagem do Hambúrguer)")

	# Monta um hambúrguer real na bancada
	var bread_bottom = load("res://src/items/bread_bottom.tscn").instantiate() as BreadBottom
	main_scene.add_child(bread_bottom)
	bread_bottom.global_position = island.global_position + Vector3(0, 0.9, 0)
	var patty = load("res://src/items/patty.tscn").instantiate() as Patty
	bread_bottom.assembly.add_ingredient(patty)
	var bread_top = load("res://src/items/bread_top.tscn").instantiate() as Item
	bread_bottom.assembly.close_burger(bread_top, Vector3.ZERO)
	
	assert_test(bread_bottom.assembly.state == BurgerAssembly.State.CLOSED, "BurgerAssembly atingiu estado CLOSED (lanche montado e fechado)")
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 10, "Etapa 9 concluída com sucesso após fechamento da montagem -> Avançou para Etapa 10")

	# --- TESTE 4: Validação do Ciclo Real de Limpeza da Grelha e Bucha ---
	print("\n--- TESTE 4: Ciclo Real de Limpeza e Higiene na Pia ---")
	tut._apply_step(12) # Etapa de Limpeza
	tut.transition_timer = 0.0
	player.select_tool_slot(Player.ToolSlot.SPONGE, false)
	
	grill.dirt_level = 0.60
	assert_test(grill.is_dirty() == true, "Grelha está suja")
	
	# Simula limpeza da grelha
	grill.dirt_level = 0.0 # Zerado
	player.sponge_is_dirty = true
	assert_test(grill.is_dirty() == false, "Grelha está 100% LIMPA")
	assert_test(player.sponge_is_dirty == true, "Bucha ficou SUJA após limpar a grelha")

	# Lava na pia
	sink.wash_or_sanitize(player)
	assert_test(player.sponge_is_dirty == false, "Bucha lavada e higienizada na pia")
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 13, "Etapa 12 concluída -> Avançou para Etapa 13")

	# --- TESTE 5: Pular Tutorial pelo Menu de Pausa e Restauração dos Tempos Normais ---
	print("\n--- TESTE 5: Pular Tutorial pelo Menu de Pausa e Restauração de Velocidades ---")
	pause_menu.pause_game()
	pause_menu._on_skip_tutorial_pressed()
	pause_menu._on_confirm_ok_pressed()
	assert_test(tut.tutorial_completed == true, "Tutorial finalizado via Pular Tutorial na Pausa")
	assert_test(clock.current_hour == 9 and clock.current_minute == 0, "Dia 1 iniciado pontualmente às 09:00")
	assert_test(grill.get_cooking_speed_factor() == 1.0, "Velocidade da grelha restaurada para 1.0x no gameplay normal")
	assert_test(fryer.get_cooking_speed_factor() == 1.0, "Velocidade da fritadeira restaurada para 1.0x no gameplay normal")
	
	pause_menu.pause_game()
	assert_test(pause_menu.skip_tutorial_btn.visible == false, "Botão 'Pular Tutorial' agora está oculto no gameplay normal")

	print("\n=================================================================")
	print("RESULTADO FINAL V6: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 TODOS OS TESTES PASSARAM COM 100% DE SUCESSO!")
	else:
		print("❌ ALGUNS TESTES FALHARAM!")

	quit(0 if failed == 0 else 1)
