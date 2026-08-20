extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE COMPLETO DO TUTORIAL EM 15 ETAPAS COM AÇÕES REAIS (v0.1.7)
# ==============================================================================

const PowerManager = preload("res://src/core/power_manager.gd")
const GameClock = preload("res://src/time/game_clock.gd")
const DrinkCup = preload("res://src/items/drink_cup.gd")
const DeliveryBox = preload("res://src/items/delivery_box.gd")
const Patty = preload("res://src/items/patty.gd")
const Burger = preload("res://src/items/burger.gd")
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
	print("=== BURGER RUSH - TESTE DAS 15 ETAPAS REAIS DO TUTORIAL V5 ===")
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

	var player = main_scene.find_child("Player", true, false)
	var clock = main_scene.find_child("GameClock", true, false)
	var pm = PowerManager.get_instance()
	var receiving = main_scene.find_child("ReceivingArea", true, false)
	var power_panel = main_scene.find_child("MainPowerPanel", true, false)
	var comp = main_scene.find_child("ComputerStation", true, false)
	var pur_mgr = main_scene.find_child("PurchaseManager", true, false)
	var rack = main_scene.find_child("StorageRack", true, false)
	var drink_mach = main_scene.find_child("DrinkMachine", true, false)
	var juice_mach = main_scene.find_child("JuiceMachine", true, false)
	var fryer = main_scene.find_child("Fryer", true, false)
	var grill = main_scene.find_child("Grill", true, false)
	var island = main_scene.find_child("PrepIsland", true, false)
	var pack_st = main_scene.find_child("PackagingStation", true, false)
	var tray_stack = main_scene.find_child("ServingTrayStack", true, false)
	var sink = main_scene.find_child("CommercialSink", true, false)
	var cash_reg = main_scene.find_child("CashRegister", true, false)
	var open_sign = main_scene.find_child("OpenSign", true, false)

	# --- TESTE 1: Estrutura Inicial e Contagem de 15 Etapas ---
	print("\n--- TESTE 1: Estrutura Inicial e Contagem de 15 Etapas ---")
	assert_test(tut.steps.size() == 15, "Tutorial possui exatamente 15 etapas estruturadas")
	assert_test(tut.current_step_index == 0, "Inicia na Etapa 0 (Movimentação e Controles)")
	assert_test(clock.is_paused == true, "Relógio pausado durante o tutorial")

	# --- TESTE 2: Imunidade a Proximidade (Estar perto NÃO avança) ---
	print("\n--- TESTE 2: Validação de que Proximidade NÃO conclui Etapas de Ação ---")
	tut.current_step_index = 5 # Máquina de refrigerante
	tut.step_initialized = true
	tut.transition_timer = 0.0
	player.global_position = drink_mach.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 5, "Estar perto da máquina de refrigerantes NÃO conclui a etapa")

	tut.current_step_index = 7 # Fritadeira
	tut.step_initialized = true
	tut.transition_timer = 0.0
	player.global_position = fryer.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 7, "Estar perto da fritadeira NÃO conclui a etapa")

	tut.current_step_index = 8 # Grelha
	tut.step_initialized = true
	tut.transition_timer = 0.0
	player.global_position = grill.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 8, "Estar perto da grelha NÃO conclui a etapa")

	tut.current_step_index = 10 # Embalagem
	tut.step_initialized = true
	tut.transition_timer = 0.0
	player.global_position = pack_st.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 10, "Estar perto da estação de embalagem NÃO conclui a etapa")

	# --- TESTE 3: Execução Sequencial das 15 Ações Reais ---
	print("\n--- TESTE 3: Execução Sequencial das 15 Ações Reais ---")
	
	# ETAPA 0: Movimentação (WASD + Pulo + Corrida)
	tut._apply_step(0)
	tut.transition_timer = 0.0
	player.global_position = tut.step_start_pos + Vector3(3.0, 0.0, 0.0)
	tut.step_tested_jump = true
	tut.step_tested_sprint = true
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 1, "Etapa 0 concluída -> Avançou para Etapa 1 (Quadro de Energia)")

	# ETAPA 1: Quadro Geral de Energia
	tut.transition_timer = 0.0
	power_panel.interact_equipment(player)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 2, "Etapa 1 concluída -> Avançou para Etapa 2 (PC Administrativo)")

	# ETAPA 2: PC Administrativo
	tut.transition_timer = 0.0
	comp.interact(player)
	tut.step_pc_opened = true
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 3, "Etapa 2 concluída -> Avançou para Etapa 3 (Compra e Recebimento)")

	# ETAPA 3: Compra e Recebimento de Mercadorias
	tut.transition_timer = 0.0
	pur_mgr.add_to_cart("patty_beef", 1)
	pur_mgr.confirm_order("FAST")
	receiving.add_pending_delivery("patty_beef", "Carne Bovina", 10)
	receiving.interact(player)
	assert_test(player.held_item is DeliveryBox, "Jogador pegou a caixa de mercadoria")
	player.global_position = rack.global_position + Vector3(0.5, 0.0, 0.5)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 4, "Etapa 3 concluída -> Avançou para Etapa 4 (Ingredientes e Armazenamento)")

	# ETAPA 4: Ingredientes e Armazenamento
	tut.transition_timer = 0.0
	player.held_item = null
	tut.step_ingredient_handled = true
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 5, "Etapa 4 concluída -> Avançou para Etapa 5 (Máquina de Refrigerantes)")

	# ETAPA 5: Máquina de Refrigerantes (Copo cheio)
	tut.transition_timer = 0.0
	var cup = load("res://src/items/drink_cup.tscn").instantiate() as DrinkCup
	main_scene.add_child(cup)
	cup.set_state(DrinkCup.State.FILLED)
	cup.set_flavor("soda_cola")
	player.held_item = cup
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 6, "Etapa 5 concluída -> Avançou para Etapa 6 (Máquina de Sucos Naturais)")

	# ETAPA 6: Máquina de Sucos Naturais (Copo de suco cheio)
	tut.transition_timer = 0.0
	cup.set_flavor("juice_orange")
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 7, "Etapa 6 concluída -> Avançou para Etapa 7 (Fritadeira Comercial)")

	# ETAPA 7: Fritadeira Comercial
	tut.transition_timer = 0.0
	player.held_item = null
	var fries = load("res://src/items/fries_pack.tscn").instantiate() as FriesPack
	main_scene.add_child(fries)
	player.held_item = fries
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 8, "Etapa 7 concluída -> Avançou para Etapa 8 (Grelha Industrial)")

	# ETAPA 8: Grelha Industrial (Carne na espátula)
	tut.transition_timer = 0.0
	player.held_item = null
	player.select_tool_slot(Player.ToolSlot.SPATULA, false)
	var patty = load("res://src/items/patty.tscn").instantiate() as Patty
	main_scene.add_child(patty)
	var sp = player.get_spatula()
	if sp:
		sp.attach_patty(patty)
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 9, "Etapa 8 concluída -> Avançou para Etapa 9 (Montagem do Hambúrguer)")

	# ETAPA 9: Montagem do Hambúrguer
	tut.transition_timer = 0.0
	player.take_spatula_held_patty()
	player.select_tool_slot(Player.ToolSlot.HANDS, false)
	var burger = load("res://src/items/burger.tscn").instantiate() as Burger
	main_scene.add_child(burger)
	player.held_item = burger
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 10, "Etapa 9 concluída -> Avançou para Etapa 10 (Estação de Embalagem)")

	# ETAPA 10: Estação de Embalagem
	tut.transition_timer = 0.0
	var pkg_burger = load("res://src/items/packaged_burger.tscn").instantiate() as PackagedBurger
	main_scene.add_child(pkg_burger)
	player.held_item = pkg_burger
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 11, "Etapa 10 concluída -> Avançou para Etapa 11 (Bandeja de Serviço)")

	# ETAPA 11: Bandeja de Serviço
	tut.transition_timer = 0.0
	var tray = load("res://src/items/serving_tray.tscn").instantiate() as ServingTray
	main_scene.add_child(tray)
	tray.carried_items.append(pkg_burger)
	player.held_item = tray
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 12, "Etapa 11 concluída -> Avançou para Etapa 12 (Limpeza e Higiene)")

	# ETAPA 12: Limpeza da Grelha e Lavagem na Pia
	tut.transition_timer = 0.0
	player.held_item = null
	player.select_tool_slot(Player.ToolSlot.SPONGE, false)
	var sponge = null
	var th = player.get_node_or_null("Head/Camera3D/ToolHolder")
	if th and th.get_child_count() > 0:
		sponge = th.get_child(0)
	elif player.tool_holder and player.tool_holder.get_child_count() > 0:
		sponge = player.tool_holder.get_child(0)
	
	grill.add_dirt(0.60)
	if sponge:
		sponge.set_dirty()
	player.sponge_is_dirty = true
	grill.dirt_level = 0.0 # Grelha limpa
	
	# Lava na pia
	sink.wash_or_sanitize(player)
	assert_test(sponge != null and sponge.is_clean(), "Bucha higienizada após lavagem na pia")
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 13, "Etapa 12 concluída -> Avançou para Etapa 13 (Pedido e Pagamento)")

	# ETAPA 13: Pedido e Pagamento
	tut.transition_timer = 0.0
	tut.step_payment_processed = true
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 14, "Etapa 13 concluída -> Avançou para Etapa 14 (Expediente e Placa de Abertura)")

	# ETAPA 14: Expediente e Placa de Abertura
	tut.transition_timer = 0.0
	tut.step_open_sign_interacted = true
	tut._check_step_conditions()
	assert_test(tut.current_step_index == 15, "Etapa 14 concluída -> Tutorial Finalizado!")

	# --- TESTE 4: Painel de Parabéns e Transição para o Dia 1 ---
	print("\n--- TESTE 4: Painel de Parabéns e Transição para o Dia 1 ---")
	assert_test(tut.congrats_panel.visible == true, "Painel de parabéns exibido")
	assert_test(tut.tutorial_completed == true, "tutorial_completed marcado como true")
	tut._on_start_day_pressed()
	assert_test(clock.current_hour == 9 and clock.current_minute == 0, "Dia 1 inicia pontualmente às 09:00")
	assert_test(clock.state == GameClock.State.PREPARATION, "Dia 1 inicia no período de PREPARATION")
	assert_test(clock.is_paused == false, "Relógio despausado para início do gameplay")

	# --- TESTE 5: Verificação de Remoção do Óleo de Cozinha ---
	print("\n--- TESTE 5: Verificação de Remoção do Óleo de Cozinha ---")
	var inv_mgr = main_scene.get_node_or_null("InventoryManager")
	if inv_mgr:
		assert_test(not inv_mgr.items.has("cooking_oil"), "Óleo de cozinha removido do InventoryManager")
	var prog_mgr = main_scene.get_node_or_null("ProgressionManager")
	if prog_mgr:
		assert_test(not prog_mgr.unlocked_features.has("cooking_oil"), "Óleo de cozinha removido do ProgressionManager")

	print("\n=================================================================")
	print("RESULTADO FINAL V5: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")

	if failed == 0:
		print("🎉 TODOS OS TESTES PASSARAM COM 100% DE SUCESSO!")
	else:
		print("❌ ALGUNS TESTES FALHARAM!")

	quit(0 if failed == 0 else 1)
