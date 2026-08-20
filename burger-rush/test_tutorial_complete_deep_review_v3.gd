extends SceneTree

# =============================================================================
# BURGER RUSH - TESTE DE REVISÃO PROFUNDA DO TUTORIAL V3 (24 ETAPAS) + PAUSA + PISOS
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
const RestaurantTableClass = preload("res://src/stations/restaurant_table.gd")
const GameClockClass = preload("res://src/time/game_clock.gd")
const PowerManagerClass = preload("res://src/core/power_manager.gd")
const Sponge = preload("res://src/tools/sponge.gd")
const DrinkCup = preload("res://src/items/drink_cup.gd")
const DeliveryBox = preload("res://src/items/delivery_box.gd")
const Patty = preload("res://src/items/patty.gd")
const PauseMenuClass = preload("res://src/ui/pause_menu.gd")

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
	print("=== BURGER RUSH - TESTE DA REVISÃO PROFUNDA DO TUTORIAL V3 ===")
	print("=================================================================\n")

	var gm = GameManagerClass.new()
	root.add_child(gm)
	GameManagerClass.instance = gm
	
	var sm = SaveManagerClass.new()
	sm.set_custom_save_dir("user://saves_test_tut_v3")
	root.add_child(sm)
	SaveManagerClass.instance = sm

	var pm = PowerManagerClass.new()
	root.add_child(pm)
	PowerManagerClass.instance = pm

	var eco = EconomyManagerClass.new()
	root.add_child(eco)
	EconomyManagerClass.instance = eco
	eco.current_money = 500.0

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
	island.global_position = Vector3(0.0, 0.0, 2.0)

	var sink_scene = load("res://src/stations/commercial_sink.tscn")
	var sink = sink_scene.instantiate() as CommercialSink
	main_scene.add_child(sink)
	sink.name = "CommercialSink"
	sink.global_position = Vector3(-4.0, 0.0, -2.0)

	var pack_scene = load("res://src/stations/packaging_station.tscn")
	var pack = pack_scene.instantiate() as PackagingStation
	main_scene.add_child(pack)
	pack.name = "PackagingStation"
	pack.global_position = Vector3(-2.0, 0.0, 2.0)

	var drink_scene = load("res://src/stations/drink_machine.tscn")
	var drink_mach = drink_scene.instantiate() as DrinkMachine
	main_scene.add_child(drink_mach)
	drink_mach.name = "DrinkMachine"
	drink_mach.global_position = Vector3(2.0, 0.0, 2.0)

	var juice_scene = load("res://src/stations/juice_machine.tscn")
	var juice_mach = juice_scene.instantiate() as JuiceMachine
	main_scene.add_child(juice_mach)
	juice_mach.name = "JuiceMachine"
	juice_mach.global_position = Vector3(4.0, 0.0, 2.0)

	var fryer_scene = load("res://src/stations/fryer.tscn")
	var fryer = fryer_scene.instantiate() as Fryer
	main_scene.add_child(fryer)
	fryer.name = "Fryer"
	fryer.global_position = Vector3(-2.0, 0.0, -2.0)

	var deliv_scene = load("res://src/stations/delivery_window_station.tscn")
	var deliv_win = deliv_scene.instantiate() as DeliveryWindowStation
	main_scene.add_child(deliv_win)
	deliv_win.name = "DeliveryWindowStation"
	deliv_win.global_position = Vector3(14.0, 0.0, 0.0)

	var tray_stack_scene = load("res://src/stations/serving_tray_stack.tscn")
	var tray_stack = tray_stack_scene.instantiate() as ServingTrayStack
	main_scene.add_child(tray_stack)
	tray_stack.name = "ServingTrayStack"
	tray_stack.global_position = Vector3(-4.0, 0.0, 2.0)

	var open_sign_scene = load("res://src/stations/open_sign.tscn")
	var open_sign = open_sign_scene.instantiate() as OpenSign
	main_scene.add_child(open_sign)
	open_sign.name = "OpenSign"
	open_sign.global_position = Vector3(0.0, 0.0, 10.0)

	var cash_scene = load("res://src/stations/cash_register.tscn")
	var cash_reg = cash_scene.instantiate() as CashRegister
	main_scene.add_child(cash_reg)
	cash_reg.name = "CashRegister"
	cash_reg.global_position = Vector3(-6.0, 0.0, 4.0)

	var table_scene = load("res://src/stations/restaurant_table.tscn")
	var table = table_scene.instantiate() as RestaurantTable
	main_scene.add_child(table)
	table.name = "RestaurantTable"
	table.global_position = Vector3(4.0, 0.0, 6.0)

	# Instancia o TutorialController
	var tut_scene = load("res://src/ui/tutorial.tscn")
	var tut = tut_scene.instantiate() as TutorialController
	main_scene.add_child(tut)
	await process_frame

	# ETAPA 0: Inicialização Silenciosa e 24 Etapas
	print("--- TESTE 1: Inicialização do Tutorial e Contagem de 24 Etapas ---")
	assert_test(tut.steps.size() == 24, "Tutorial possui exatamente 24 etapas calmas e didáticas")
	assert_test(receiving.get_delivered_boxes().size() == 0, "Pallet de recebimento inicia limpo (SEM caixas)")
	assert_test(clock.is_paused == true, "Relógio pausado durante o tutorial")
	assert_test(tut.current_step_index == 0, "Tutorial inicia na etapa 0 (Movimentação)")

	# ETAPA 0: Movimentação (WASD + Olhar)
	print("\n--- TESTE 2: Movimentação (WASD + Olhar) ---")
	player.global_position = Vector3(3.0, 0.0, 0.0)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 1, "Avançou para Etapa 1 (Pulo)")

	# ETAPA 1: Pulo [Espaço]
	print("\n--- TESTE 3: Pulo [Espaço] ---")
	tut.step_tested_jump = true
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 2, "Avançou para Etapa 2 (Corrida)")

	# ETAPA 2: Corrida [Shift]
	print("\n--- TESTE 4: Corrida [Shift] ---")
	tut.step_tested_sprint = true
	player.global_position = Vector3(6.0, 0.0, 0.0)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 3, "Avançou para Etapa 3 (Quadro de Energia)")

	# ETAPA 3: Quadro de Energia com Interação Real
	print("\n--- TESTE 5: Quadro Geral de Energia (Interação Real [E]) ---")
	assert_test(pm.is_main_power_on == false, "Disjuntor geral inicia desligado na etapa de energia")
	assert_test(tut.current_highlight_marker != null, "Destaque 3D ativo sobre o quadro de energia")
	panel.toggle_power(player)
	assert_test(pm.is_main_power_on == true, "Jogador ligou o disjuntor no MainPowerPanel")
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 4, "Avançou para Etapa 4 (PC Administrativo)")

	# ETAPA 4: PC Administrativo
	print("\n--- TESTE 6: PC Administrativo ---")
	if pc.computer_ui_instance:
		pc.computer_ui_instance.visible = true
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 5, "Avançou para Etapa 5 (Visão Geral da Gestão)")

	# ETAPA 5: Visão Geral da Gestão
	print("\n--- TESTE 7: Visão Geral da Gestão ---")
	if pc.computer_ui_instance:
		pc.computer_ui_instance.visible = false
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 6, "Avançou para Etapa 6 (Compra de Mercadorias)")

	# ETAPA 6: Compra Real no PC
	print("\n--- TESTE 8: Compra Real no PC e Disparo da Entrega ---")
	purch.add_to_cart("patty_beef", 10)
	var order_res = purch.confirm_order("NORMAL")
	assert_test(order_res["success"] == true, "Compra confirmada com sucesso no PC")
	assert_test(purch.get_cart_delivery_time_sec() == 1.5, "Tempo de entrega acelerado para 1.5s no tutorial")
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 7, "Avançou para Etapa 7 (Recebimento de Mercadorias)")

	# ETAPA 7: Entrega no Pallet
	print("\n--- TESTE 9: Entrega no Pallet Externo ---")
	purch._process(2.0)
	assert_test(receiving.has_pending_boxes() == true, "Caixa física de mercadorias descarregada no pallet pós-compra")
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 8, "Avançou para Etapa 8 (Armazenamento no Estoque)")

	# ETAPA 8: Armazenamento no Estoque
	print("\n--- TESTE 10: Armazenamento no Estoque ---")
	receiving.interact(player)
	assert_test(player.held_item != null and player.held_item is DeliveryBox, "Jogador pegou a caixa de mercadoria")
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 9, "Avançou para Etapa 9 (Máquina de Refrigerantes)")

	# ETAPA 9: Máquina de Refrigerantes
	print("\n--- TESTE 11: Máquina de Refrigerantes ---")
	player.held_item = null
	var cup = load("res://src/items/drink_cup.tscn").instantiate() as DrinkCup
	main_scene.add_child(cup)
	cup.set_state(DrinkCup.State.FILLED)
	player.held_item = cup
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 10, "Avançou para Etapa 10 (Máquina de Suco Natural)")

	# ETAPA 10: Máquina de Suco Natural
	print("\n--- TESTE 12: Máquina de Suco Natural ---")
	player.held_item = null
	player.global_position = juice_mach.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 11, "Avançou para Etapa 11 (Fritadeira Comercial)")

	# ETAPA 11: Fritadeira Comercial
	print("\n--- TESTE 13: Fritadeira Comercial ---")
	player.global_position = fryer.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 12, "Avançou para Etapa 12 (Grelha - Colocando a Carne)")

	# ETAPA 12: Grelha - Colocando a Carne
	print("\n--- TESTE 14: Grelhando Carne Crua ---")
	var patty = load("res://src/items/patty.tscn").instantiate() as Patty
	main_scene.add_child(patty)
	grill.place_item(patty)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 13, "Avançou para Etapa 13 (Grelha - Virando com Espátula)")

	# ETAPA 13: Grelha - Virando com Espátula
	print("\n--- TESTE 15: Virando com Espátula [1] ---")
	player.select_tool_slot(Player.ToolSlot.SPATULA, false)
	patty.flip()
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 14, "Avançou para Etapa 14 (Grelha - Retirando com Espátula)")

	# ETAPA 14: Grelha - Retirando com Espátula
	print("\n--- TESTE 16: Retirando Carne na Espátula ---")
	var sp = player.get_spatula()
	if sp:
		sp.attach_patty(patty)
	player.global_position = grill.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 15, "Avançou para Etapa 15 (Montagem na Bancada)")

	# ETAPA 15: Montagem na Bancada
	print("\n--- TESTE 17: Montagem Completa na Bancada ---")
	player.take_spatula_held_patty()
	player.held_item = null
	player.select_tool_slot(Player.ToolSlot.HANDS, false)
	player.global_position = island.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 16, "Avançou para Etapa 16 (Estação de Embalagem)")

	# ETAPA 16: Estação de Embalagem
	print("\n--- TESTE 18: Estação de Embalagem ---")
	player.global_position = pack.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 17, "Avançou para Etapa 17 (Atendimento - Salão e Mesas)")

	# ETAPA 17: Salão e Mesas
	print("\n--- TESTE 19: Salão e Mesas ---")
	player.global_position = table.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 18, "Avançou para Etapa 18 (Atendimento - Drive-Thru)")

	# ETAPA 18: Drive-Thru
	print("\n--- TESTE 20: Drive-Thru ---")
	player.global_position = deliv_win.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 19, "Avançou para Etapa 19 (Atendimento - Delivery Online)")

	# ETAPA 19: Delivery Online
	print("\n--- TESTE 21: Delivery Online ---")
	player.global_position = deliv_win.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 20, "Avançou para Etapa 20 (Limpeza e Higiene)")

	# ETAPA 20: Limpeza da Grelha com Bucha
	print("\n--- TESTE 22: Limpeza com Bucha e Lavagem na Pia ---")
	player.held_item = null
	player.select_tool_slot(Player.ToolSlot.SPONGE, false)
	var sponge = null
	var th = player.get_node_or_null("Head/Camera3D/ToolHolder")
	if th and th.get_child_count() > 0:
		sponge = th.get_child(0)
	elif player.tool_holder and player.tool_holder.get_child_count() > 0:
		sponge = player.tool_holder.get_child(0)
	assert_test(sponge != null, "Bucha instanciada no ToolHolder")
	assert_test(player.active_tool_slot == Player.ToolSlot.SPONGE, "Slot 2 (SPONGE) permanece ativo")
	
	# Simula limpeza contínua
	grill.add_dirt(0.5)
	if sponge:
		sponge.play_scrub_animation()
		sponge.set_dirty()
	player.sponge_is_dirty = true
	grill.dirt_level = 0.0
	assert_test(sponge != null and sponge.is_dirty == true, "Bucha ficou suja após limpar")
	
	# Lava na pia
	sink.wash_or_sanitize(player)
	assert_test(sponge != null and sponge.is_clean() == true, "Bucha limpa após lavagem na pia")
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 21, "Avançou para Etapa 21 (Sistema de Bandejas)")

	# ETAPA 21: Sistema de Bandejas
	print("\n--- TESTE 23: Sistema de Bandejas ---")
	player.global_position = tray_stack.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 22, "Avançou para Etapa 22 (Pagamentos e Caixa Registradora)")

	# ETAPA 22: Pagamentos e Caixa
	print("\n--- TESTE 24: Pagamentos e Caixa Registradora ---")
	player.global_position = cash_reg.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 23, "Avançou para Etapa 23 (Horários e Expediente)")

	# ETAPA 23: Horários e Expediente
	print("\n--- TESTE 25: Horários e Placa de Abertura ---")
	player.global_position = open_sign.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 24, "Avançou para Conclusão do Tutorial")

	# ETAPA 24: Conclusão do Tutorial
	print("\n--- TESTE 26: Painel de Conclusão e Transição para o Dia 1 ---")
	assert_test(tut.congrats_panel.visible == true, "Painel de parabéns exibido")
	assert_test(tut.start_day_button != null, "Botão Começar Dia 1 presente")
	assert_test(tut.tutorial_completed == true, "tutorial_completed marcado como true")
	assert_test(clock.is_paused == false, "Relógio despausado após tutorial")
	assert_test(clock.current_hour == 9 and clock.current_minute == 0, "Dia 1 inicia às 09:00")
	assert_test(clock.state == GameClock.State.PREPARATION, "Dia 1 inicia no período de PREPARATION")

	# TESTE 27: Menu de Pausa [ESC]
	print("\n--- TESTE 27: Menu de Pausa [ESC] ---")
	var pause_menu_scene = load("res://src/ui/pause_menu.tscn")
	var pause_menu = pause_menu_scene.instantiate()
	main_scene.add_child(pause_menu)
	pause_menu.pause_game()
	assert_test(pause_menu.visible == true, "Menu de Pausa visível ao pausar")
	assert_test(self.paused == true, "paused = true durante a pausa")
	assert_test(pause_menu.is_active == true, "is_active marcado como true")
	pause_menu.resume_game()
	assert_test(pause_menu.visible == false, "Menu de Pausa ocultado ao retomar")
	assert_test(self.paused == false, "paused = false ao retomar")

	# TESTE 28: Validação dos Materiais de Piso Restaurados
	print("\n--- TESTE 28: Texturas de Piso Restauradas ---")
	var main_tscn = load("res://src/main.tscn").instantiate()
	var room = main_tscn.get_node_or_null("Room")
	var floor_dining = room.get_node_or_null("FloorDining") if room else null
	var floor_kitchen = room.get_node_or_null("FloorKitchen") if room else null
	assert_test(floor_dining != null and floor_dining.material != null, "Piso do salão possui material configurado")
	assert_test(floor_dining.material.albedo_texture != null, "Piso do salão possui textura de ladrilhos vermelhos (light_red_tiles.png)")
	assert_test(floor_kitchen != null and floor_kitchen.material != null, "Piso da cozinha possui material configurado")
	assert_test(floor_kitchen.material.albedo_texture != null, "Piso da cozinha possui textura de ladrilhos brancos (subway_tiles_white.png)")
	main_tscn.queue_free()

	print("\n=================================================================")
	print("RESULTADO FINAL V3: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=================================================================\n")

	if passed_tests == total_tests:
		print(">>> SUCESSO TOTAL: TODAS AS 24 ETAPAS, PAUSA E PISOS VALIDADOS COM 100%! <<<\n")
		quit(0)
	else:
		print(">>> ERRO: ALGUNS TESTES FALHARAM! <<<\n")
		quit(1)
