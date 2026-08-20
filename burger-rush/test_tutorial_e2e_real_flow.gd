extends SceneTree

# =============================================================================
# BURGER RUSH — TESTE E2E DO FLUXO COMPLETO DO NOVO TUTORIAL (18 ETAPAS)
# =============================================================================

const GameManagerClass = preload("res://src/core/game_manager.gd")
const SaveManagerClass = preload("res://src/core/save_manager.gd")
const PlayerClass = preload("res://src/player/player.gd")
const MainPowerPanelClass = preload("res://src/stations/main_power_panel.gd")
const ComputerStationClass = preload("res://src/stations/computer_station.gd")
const ReceivingAreaClass = preload("res://src/stations/receiving_area.gd")
const StorageRackClass = preload("res://src/stations/storage_rack.gd")
const MeatRefrigeratorClass = preload("res://src/stations/commercial_refrigerator.gd")
const GrillClass = preload("res://src/stations/grill.gd")
const PrepIslandClass = preload("res://src/stations/prep_island.gd")
const CommercialSinkClass = preload("res://src/stations/commercial_sink.gd")
const PackagingStationClass = preload("res://src/stations/packaging_station.gd")
const DrinkMachineClass = preload("res://src/stations/drink_machine.gd")
const DeliveryWindowStationClass = preload("res://src/stations/delivery_window_station.gd")
const ServingTrayStackClass = preload("res://src/stations/serving_tray_stack.gd")
const OpenSignClass = preload("res://src/stations/open_sign.gd")
const CashRegisterClass = preload("res://src/stations/cash_register.gd")
const GameClockClass = preload("res://src/time/game_clock.gd")
const PowerManagerClass = preload("res://src/core/power_manager.gd")

var total_tests: int = 0
var passed_tests: int = 0

func assert_test(condition: bool, description: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % description)
	else:
		printerr("  [FAIL] %s" % description)

func _init() -> void:
	call_deferred("run_e2e")

func run_e2e() -> void:
	print("\n=================================================================")
	print("=== BURGER RUSH - TESTE E2E DAS 18 ETAPAS DO NOVO TUTORIAL ===")
	print("=================================================================\n")

	var gm = GameManagerClass.new()
	root.add_child(gm)
	GameManagerClass.instance = gm
	
	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir("user://saves_test_e2e_tut18")
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

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	main_scene.add_child(player)
	player.name = "Player"

	var panel = MainPowerPanelClass.new()
	main_scene.add_child(panel)
	panel.name = "MainPowerPanel"
	panel.global_position = Vector3(10.0, 0.0, 0.0)

	var pc_scene = load("res://src/stations/computer_station.tscn")
	var pc = pc_scene.instantiate() as ComputerStation
	main_scene.add_child(pc)
	pc.name = "ComputerStation"
	pc.global_position = Vector3(8.0, 0.0, -8.0)

	var receiving_scene = load("res://src/stations/receiving_area.tscn")
	var receiving = receiving_scene.instantiate() as ReceivingArea
	main_scene.add_child(receiving)
	receiving.name = "ReceivingArea"
	receiving.global_position = Vector3(12.0, 0.0, -4.0)

	var rack = StorageRackClass.new()
	main_scene.add_child(rack)
	rack.name = "StorageRack"
	rack.global_position = Vector3(6.0, 0.0, -4.0)

	var fridge = MeatRefrigeratorClass.new()
	main_scene.add_child(fridge)
	fridge.name = "MeatRefrigerator"
	fridge.global_position = Vector3(4.0, 0.0, -2.0)

	var grill = GrillClass.new()
	var cooking_slot = Marker3D.new()
	cooking_slot.name = "CookingSlot"
	grill.add_child(cooking_slot)
	main_scene.add_child(grill)
	grill.name = "Grill"
	grill.global_position = Vector3(0.0, 0.0, -2.0)

	var island_scene = load("res://src/stations/prep_island.tscn")
	var island = island_scene.instantiate() as PrepIsland
	main_scene.add_child(island)
	island.name = "PrepIsland"
	island.global_position = Vector3(0.0, 0.0, 0.0)

	var sink_scene = load("res://src/stations/commercial_sink.tscn")
	var sink = sink_scene.instantiate() as CommercialSink
	main_scene.add_child(sink)
	sink.name = "CommercialSink"
	sink.global_position = Vector3(-4.0, 0.0, -2.0)

	var packaging_scene = load("res://src/stations/packaging_station.tscn")
	var packaging = packaging_scene.instantiate() as PackagingStation
	main_scene.add_child(packaging)
	packaging.name = "PackagingStation"
	packaging.global_position = Vector3(-2.0, 0.0, 0.0)

	var drink_scene = load("res://src/stations/drink_machine.tscn")
	var drink_mach = drink_scene.instantiate() as DrinkMachine
	main_scene.add_child(drink_mach)
	drink_mach.name = "DrinkMachine"
	drink_mach.global_position = Vector3(-4.0, 0.0, 2.0)

	var deliv_window = DeliveryWindowStationClass.new()
	main_scene.add_child(deliv_window)
	deliv_window.name = "DeliveryWindowStation"
	deliv_window.global_position = Vector3(8.0, 0.0, 4.0)

	var open_sign_scene = load("res://src/stations/open_sign.tscn")
	var open_sign = open_sign_scene.instantiate() as OpenSign
	main_scene.add_child(open_sign)
	open_sign.name = "OpenSign"
	open_sign.global_position = Vector3(0.0, 0.0, 6.0)

	var cash_scene = load("res://src/stations/cash_register.tscn")
	var cash_register = cash_scene.instantiate() as CashRegister
	main_scene.add_child(cash_register)
	cash_register.name = "CashRegister"
	cash_register.global_position = Vector3(2.0, 0.0, 4.0)

	var tut_scene = load("res://src/ui/tutorial.tscn")
	var tut = tut_scene.instantiate() as TutorialController
	main_scene.add_child(tut)
	tut.name = "Tutorial"

	await process_frame

	print("--- 1. Inicialização do Tutorial ---")
	sm.create_new_career(1, "Chef Miller")
	assert_test(tut.current_step_index == 0, "Etapa 0 ativa (Movimentação)")

	# ETAPA 0: Movimentação
	tut.step_start_pos = Vector3.ZERO
	tut.step_initialized = true
	tut.step_tested_sprint = true
	player.global_position = Vector3(4.0, 0.0, 0.0)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 1, "Avançou para Etapa 1 (Quadro de Energia)")

	# ETAPA 1: Quadro Geral de Energia
	player.global_position = panel.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 2, "Avançou para Etapa 2 (PC Administrativo)")

	# ETAPA 2: PC Administrativo
	if pc.computer_ui_instance:
		pc.computer_ui_instance.visible = true
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 3, "Avançou para Etapa 3 (Reposição e Compras)")

	# ETAPA 3: Reposição e Compras
	tut.step_initialized = true
	if pc.computer_ui_instance:
		pc.computer_ui_instance.visible = false
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 4, "Avançou para Etapa 4 (Recebimento e Estoque)")

	# ETAPA 4: Recebimento e Estoque
	var box = load("res://src/items/delivery_box.tscn").instantiate()
	main_scene.add_child(box)
	player.held_item = box
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 5, "Avançou para Etapa 5 (Máquinas do Restaurante)")

	# ETAPA 5: Máquinas do Restaurante
	player.held_item = null
	player.global_position = grill.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 6, "Avançou para Etapa 6 (Grelhando Carne)")

	# ETAPA 6: Grelhando Carne Crua
	var patty = load("res://src/items/patty.tscn").instantiate() as Patty
	main_scene.add_child(patty)
	grill.place_item(patty)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 7, "Avançou para Etapa 7 (Virando com Espátula)")

	# ETAPA 7: Virando Carne
	patty.flip()
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 8, "Avançou para Etapa 8 (Retirando Carne)")

	# ETAPA 8: Retirando Carne com Espátula
	patty.state = Patty.State.COOKED
	patty.side_a_cooked = 100.0
	patty.side_b_cooked = 100.0
	grill.active_items.clear()
	player.select_tool_slot(Player.ToolSlot.SPATULA, false)
	player.pick_up(patty)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 9, "Avançou para Etapa 9 (Montagem na Bancada)")

	# ETAPA 9: Montagem na Bancada
	var bread_bottom = load("res://src/items/bread_bottom.tscn").instantiate() as BreadBottom
	main_scene.add_child(bread_bottom)
	bread_bottom.global_position = island.global_position + Vector3(0, 0.9, 0)
	bread_bottom.location = Item.ItemLocation.WORLD
	bread_bottom.assembly.add_ingredient(patty)
	var bread_top = load("res://src/items/bread_top.tscn").instantiate()
	main_scene.add_child(bread_top)
	bread_bottom.assembly.close_burger(bread_top, Vector3.ZERO)
	island._cleanup_placed_items()
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 10, "Avançou para Etapa 10 (Limpeza e Higiene)")

	# ETAPA 10: Limpeza da Grelha e Pia
	player.held_item = null
	player.select_tool_slot(Player.ToolSlot.SPONGE, true)
	await process_frame
	var sponge = player.tool_holder.get_child(0) as Sponge
	assert_test(sponge != null, "Bucha instanciada no ToolHolder")
	assert_test(sponge.visible == true, "Bucha visível na mão")
	grill.add_dirt(0.5)
	sponge.play_scrub_animation()
	grill.clean_progress(1.0, player)
	grill.dirt_level = 0.0
	sink.wash_or_sanitize(player)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 11, "Avançou para Etapa 11 (Embalando o Lanche)")

	# ETAPA 11: Embalando o Lanche
	var pkg_burger = load("res://src/items/packaged_burger.tscn").instantiate()
	main_scene.add_child(pkg_burger)
	player.held_item = pkg_burger
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 12, "Avançou para Etapa 12 (Preparo de Bebidas)")

	# ETAPA 12: Preparo de Bebidas
	var cup = load("res://src/items/drink_cup.tscn").instantiate() as DrinkCup
	main_scene.add_child(cup)
	cup.set_state(DrinkCup.State.FILLED)
	player.held_item = cup
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 13, "Avançou para Etapa 13 (Modalidades de Atendimento)")

	# ETAPA 13: Modalidades de Atendimento (Delivery Window)
	player.global_position = deliv_window.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 14, "Avançou para Etapa 14 (Sistema de Bandejas)")

	# ETAPA 14: Sistema de Bandejas
	var tray = load("res://src/items/serving_tray.tscn").instantiate() as ServingTray
	main_scene.add_child(tray)
	tray.add_product(pkg_burger)
	player.held_item = tray
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 15, "Avançou para Etapa 15 (Horário e Expediente)")

	# ETAPA 15: Horário e Expediente (OpenSign)
	player.global_position = open_sign.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 16, "Avançou para Etapa 16 (Pagamentos e Caixa)")

	# ETAPA 16: Pagamentos e Caixa
	player.global_position = cash_register.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 17, "Avançou para Etapa 17 (Conclusão do Tutorial)")

	# ETAPA 17: Conclusão do Tutorial
	tut._check_step_conditions()
	assert_test(tut.congrats_panel.visible == true, "Painel de parabéns exibido")
	tut._complete_tutorial(false)
	assert_test(tut.tutorial_completed == true, "Tutorial finalizado")
	assert_test(sm.pending_save_data.get("tutorial_completed") == true, "Salvo no SaveManager")
	assert_test(clock.current_hour == 9 and clock.current_minute == 0, "Dia 1 às 09:00")
	assert_test(clock.state == GameClock.State.PREPARATION, "Estado PREPARATION ativo")

	print("\n=================================================================")
	print("RESULTADO FINAL E2E: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=================================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS TESTES E2E PASSARAM COM 100% DE SUCESSO! <<<\n")
		quit(0)
	else:
		printerr(">>> ERRO: ALGUNS TESTES E2E FALHARAM! <<<\n")
		quit(1)
