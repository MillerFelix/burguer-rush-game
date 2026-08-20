extends SceneTree

# =============================================================================
# BURGER RUSH - TESTE DE REESTRUTURAÇÃO COMPLETA DO TUTORIAL V2 (19 ETAPAS)
# =============================================================================

const GameManagerClass = preload("res://src/core/game_manager.gd")
const SaveManagerClass = preload("res://src/core/save_manager.gd")
const PlayerClass = preload("res://src/player/player.gd")
const MainPowerPanelClass = preload("res://src/stations/main_power_panel.gd")
const ComputerStationClass = preload("res://src/stations/computer_station.gd")
const PurchaseManagerClass = preload("res://src/purchasing/purchase_manager.gd")
const EconomyManagerClass = preload("res://src/economy/economy_manager.gd")
const InventoryManagerClass = preload("res://src/inventory/inventory_manager.gd")
const ReceivingAreaClass = preload("res://src/stations/receiving_area.gd")
const StorageRackClass = preload("res://src/stations/storage_rack.gd")
const MeatRefrigeratorClass = preload("res://src/stations/commercial_refrigerator.gd")
const GrillClass = preload("res://src/stations/grill.gd")
const PrepIslandClass = preload("res://src/stations/prep_island.gd")
const CommercialSinkClass = preload("res://src/stations/commercial_sink.gd")
const PackagingStationClass = preload("res://src/stations/packaging_station.gd")
const DrinkMachineClass = preload("res://src/stations/drink_machine.gd")
const JuiceMachineClass = preload("res://src/stations/juice_machine.gd")
const FryerClass = preload("res://src/stations/fryer.gd")
const DeliveryWindowStationClass = preload("res://src/stations/delivery_window_station.gd")
const ServingTrayStackClass = preload("res://src/stations/serving_tray_stack.gd")
const OpenSignClass = preload("res://src/stations/open_sign.gd")
const CashRegisterClass = preload("res://src/stations/cash_register.gd")
const GameClockClass = preload("res://src/time/game_clock.gd")
const PowerManagerClass = preload("res://src/core/power_manager.gd")
const Sponge = preload("res://src/tools/sponge.gd")

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
	call_deferred("run_all_tests")

func run_all_tests() -> void:
	print("\n=================================================================")
	print("=== BURGER RUSH - TESTE COMPLETO DO NOVO TUTORIAL V2 (19 ETAPAS) ===")
	print("=================================================================\n")

	var gm = GameManagerClass.new()
	root.add_child(gm)
	GameManagerClass.instance = gm
	
	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir("user://saves_test_tut_v2")
	root.add_child(sm)
	SaveManagerClass.instance = sm

	var pm = PowerManagerClass.new()
	root.add_child(pm)
	PowerManagerClass.instance = pm

	var eco = EconomyManagerClass.new()
	root.add_child(eco)
	EconomyManagerClass.instance = eco
	eco.current_money = 200.0

	var inv = InventoryManagerClass.new()
	root.add_child(inv)
	InventoryManagerClass.instance = inv

	var purch = PurchaseManagerClass.new()
	root.add_child(purch)
	PurchaseManagerClass.instance = purch

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

	var juice_scene = load("res://src/stations/juice_machine.tscn")
	var juice_mach = juice_scene.instantiate() as JuiceMachine
	main_scene.add_child(juice_mach)
	juice_mach.name = "JuiceMachine"
	juice_mach.global_position = Vector3(-6.0, 0.0, 2.0)

	var fryer = FryerClass.new()
	main_scene.add_child(fryer)
	fryer.name = "Fryer"
	fryer.global_position = Vector3(-2.0, 0.0, 2.0)

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

	print("\n--- TESTE 1: Inicialização sem Buzina e Início Controlado ---")
	assert_test(tut.steps.size() == 19, "Tutorial possui exatamente 19 etapas ricas e sequenciais")
	assert_test(receiving.has_pending_boxes() == false, "Pallet de recebimento inicia limpo (SEM caixas)")
	assert_test(clock.is_paused == true, "Relógio pausado durante o tutorial")
	assert_test(tut.current_step_index == 0, "Tutorial inicia na etapa 0 (Movimentação)")

	# ETAPA 0: Movimentação
	print("\n--- TESTE 2: Movimentação (WASD + Olhar + Espaço + Shift) ---")
	tut.step_start_pos = Vector3.ZERO
	tut.step_initialized = true
	tut.step_tested_sprint = true
	player.global_position = Vector3(3.5, 0.0, 0.0)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 1, "Avançou para Etapa 1 (Quadro de Energia)")

	# ETAPA 1: Quadro Geral de Energia
	print("\n--- TESTE 3: Quadro Geral de Energia ---")
	player.global_position = panel.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 2, "Avançou para Etapa 2 (PC Administrativo)")

	# ETAPA 2: PC Administrativo
	print("\n--- TESTE 4: PC Administrativo ---")
	if pc.computer_ui_instance:
		pc.computer_ui_instance.visible = true
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 3, "Avançou para Etapa 3 (Compra de Suprimentos)")

	# ETAPA 3: Compra Real no PC
	print("\n--- TESTE 5: Compra Real no PC e Disparo da Entrega ---")
	purch.add_to_cart("patty_beef", 10)
	var order_res = purch.confirm_order("NORMAL")
	assert_test(order_res["success"] == true, "Compra confirmada com sucesso no PC")
	assert_test(purch.get_cart_delivery_time_sec() == 1.5, "Tempo de entrega acelerado para 1.5s no tutorial")
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 4, "Avançou para Etapa 4 (Recebimento e Armazenamento)")

	# Simula chegada da van e descarregamento da caixa após a compra
	purch._process(2.0)
	assert_test(receiving.has_pending_boxes() == true, "Caixa física de mercadorias descarregada no pallet pós-compra")

	# ETAPA 4: Pegar Caixa e Armazenar
	print("\n--- TESTE 6: Pegar Caixa de Mercadorias ---")
	receiving.interact(player)
	assert_test(player.held_item != null and player.held_item is DeliveryBox, "Jogador pegou a caixa de mercadoria")
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 5, "Avançou para Etapa 5 (Máquina de Bebidas)")

	# ETAPA 5: Máquina de Bebidas
	print("\n--- TESTE 7: Máquina de Bebidas ---")
	player.held_item = null
	var cup = load("res://src/items/drink_cup.tscn").instantiate() as DrinkCup
	main_scene.add_child(cup)
	cup.set_state(DrinkCup.State.FILLED)
	player.held_item = cup
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 6, "Avançou para Etapa 6 (Máquina de Suco)")

	# ETAPA 6: Máquina de Suco Natural
	print("\n--- TESTE 8: Máquina de Suco Natural ---")
	player.held_item = null
	player.global_position = juice_mach.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 7, "Avançou para Etapa 7 (Fritadeira Comercial)")

	# ETAPA 7: Fritadeira Comercial
	print("\n--- TESTE 9: Fritadeira Comercial ---")
	player.global_position = fryer.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 8, "Avançou para Etapa 8 (Grelha - Colocar Carne)")

	# ETAPA 8: Grelha - Colocar Carne
	print("\n--- TESTE 10: Grelhando Carne Crua ---")
	var patty = load("res://src/items/patty.tscn").instantiate() as Patty
	main_scene.add_child(patty)
	grill.place_item(patty)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 9, "Avançou para Etapa 9 (Virando com Espátula)")

	# ETAPA 9: Grelha - Virando com Espátula
	print("\n--- TESTE 11: Virando com Espátula ---")
	patty.flip()
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 10, "Avançou para Etapa 10 (Retirando com Espátula)")

	# ETAPA 10: Retirando com Espátula
	print("\n--- TESTE 12: Retirando Carne na Espátula ---")
	patty.state = Patty.State.COOKED
	patty.side_a_cooked = 100.0
	patty.side_b_cooked = 100.0
	grill.active_items.clear()
	player.select_tool_slot(Player.ToolSlot.SPATULA, false)
	player.pick_up(patty)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 11, "Avançou para Etapa 11 (Montagem na Bancada)")

	# ETAPA 11: Montagem na Bancada com Nomes Amigáveis
	print("\n--- TESTE 13: Montagem Completa na Bancada ---")
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
	assert_test(tut.current_step_index == 12, "Avançou para Etapa 12 (Embalagem do Lanche)")

	# ETAPA 12: Embalagem do Lanche
	print("\n--- TESTE 14: Embalagem do Lanche ---")
	var pkg_burger = load("res://src/items/packaged_burger.tscn").instantiate()
	main_scene.add_child(pkg_burger)
	player.held_item = pkg_burger
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 13, "Avançou para Etapa 13 (Salão, Drive-Thru e Delivery)")

	# ETAPA 13: Salão, Drive-Thru e Delivery
	print("\n--- TESTE 15: Modalidades de Atendimento ---")
	player.global_position = deliv_window.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 14, "Avançou para Etapa 14 (Limpeza e Higiene)")

	# ETAPA 14: Limpeza da Grelha com Bucha
	print("\n--- TESTE 16: Limpeza com Bucha (Sem Auto-Switch de Ferramenta) ---")
	player.held_item = null
	player.select_tool_slot(Player.ToolSlot.SPONGE, true)
	await process_frame
	var sponge: Sponge = null
	for child in player.tool_holder.get_children():
		if child is Sponge and not child.is_queued_for_deletion():
			sponge = child
			break
	assert_test(sponge != null, "Bucha instanciada no ToolHolder")
	assert_test(sponge.visible == true, "Bucha visível na mão")
	assert_test(player.active_tool_slot == Player.ToolSlot.SPONGE, "Slot 2 (SPONGE) permanece ativo")
	
	# Simula limpeza contínua
	grill.add_dirt(0.5)
	sponge.play_scrub_animation()
	sponge.set_dirty()
	player.sponge_is_dirty = true
	grill.dirt_level = 0.0
	assert_test(sponge.is_dirty == true, "Bucha ficou suja após limpar")
	
	# Lava na pia
	sink.wash_or_sanitize(player)
	assert_test(sponge.is_clean() == true, "Bucha limpa após lavagem na pia")
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 15, "Avançou para Etapa 15 (Sistema de Bandejas)")

	# ETAPA 15: Sistema de Bandejas
	print("\n--- TESTE 17: Sistema de Bandejas ---")
	var tray = load("res://src/items/serving_tray.tscn").instantiate()
	main_scene.add_child(tray)
	tray.add_product(pkg_burger)
	player.held_item = tray
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 16, "Avançou para Etapa 16 (Pagamentos e Caixa)")

	# ETAPA 16: Pagamentos e Caixa
	print("\n--- TESTE 18: Pagamentos e Caixa ---")
	player.global_position = cash_register.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 17, "Avançou para Etapa 17 (Horários e Expediente)")

	# ETAPA 17: Horários e Expediente (OpenSign)
	print("\n--- TESTE 19: Horários e Expediente ---")
	player.global_position = open_sign.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 18, "Avançou para Etapa 18 (Conclusão do Tutorial)")

	# Teste do Modal de Boas-Vindas do Dia 1
	print("\n--- TESTE 20: Modal de Boas-Vindas do Primeiro Dia 1 ---")
	tut.tutorial_completed = true
	sm.create_new_career(1, "Carlos")
	sm.pending_save_data["day1_intro_shown"] = false
	var hud_scene = load("res://src/ui/hud.tscn")
	var hud = hud_scene.instantiate() as HUD
	main_scene.add_child(hud)
	await process_frame
	
	assert_test(hud.day1_welcome_modal != null, "Nó Day1WelcomeModal instanciado na HUD")
	assert_test(hud.day1_welcome_modal.visible == true, "Modal de boas-vindas exibido no primeiro Dia 1")
	assert_test(hud.day1_title_label.text.contains("CARLOS"), "Título do modal contém o nome do chefe salvo ('CARLOS')")
	
	hud._on_day1_start_button_pressed()
	assert_test(hud.day1_welcome_modal.visible == false, "Modal de boas-vindas ocultado ao clicar em Começar")
	assert_test(sm.pending_save_data.get("day1_intro_shown") == true, "day1_intro_shown persistido no SaveManager")

	# ETAPA 18: Conclusão e Início do Dia 1
	print("\n--- TESTE 21: Conclusão e Transição para o Dia 1 às 09:00 ---")
	tut.tutorial_completed = false
	tut._check_step_conditions()
	assert_test(tut.congrats_panel.visible == true, "Painel de parabéns exibido")
	assert_test(tut.start_day_button != null, "Botão Começar Dia 1 presente")

	tut._complete_tutorial(false)
	assert_test(tut.tutorial_completed == true, "tutorial_completed marcado como true")
	assert_test(clock.is_paused == false, "Relógio despausado após tutorial")
	assert_test(clock.current_hour == 9 and clock.current_minute == 0, "Dia 1 inicia às 09:00")
	assert_test(clock.state == GameClock.State.PREPARATION, "Dia 1 inicia no período de PREPARATION")

	print("\n=================================================================")
	print("RESULTADO FINAL V2: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=================================================================\n")

	if passed_tests == total_tests:
		print(">>> SUCESSO TOTAL: TODAS AS 19 ETAPAS E SISTEMAS VALIDADOS COM 100%! <<<\n")
		quit(0)
	else:
		printerr(">>> ERRO: ALGUNS TESTES FALHARAM! <<<\n")
		quit(1)
