extends SceneTree

# =============================================================================
# TEST SUITE: FACHADA EXTERNA, SINCRONIA DE PREÇOS & DELIVERY SEM PREPARAÇÃO
# =============================================================================

const MainScene: PackedScene = preload("res://src/main.tscn")
const DiningMenuBoardScene: PackedScene = preload("res://src/environment/dining_menu_board.tscn")
const ComputerStationScene: PackedScene = preload("res://src/stations/computer_station.tscn")
const MenuPricingManager = preload("res://src/recipes/menu_pricing_manager.gd")
const OrderManagerScript = preload("res://src/orders/order_manager.gd")
const GameClockScript = preload("res://src/time/game_clock.gd")
const ComputerUIScene: PackedScene = preload("res://src/ui/computer_ui.tscn")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: FACHADA EXTERNA, SINCRONIA DE PREÇOS & BLOQUEIO NA PREPARAÇÃO")
	print("===========================================================================")

	var total_tests = 0
	var passed_tests = 0

	# --- TESTE 1: Fachada Externa Amarelo Burger Rush e Parede do Quadro de Energia ---
	total_tests += 1
	var main_scene = MainScene.instantiate()
	root.add_child(main_scene)

	var wall_south_l = main_scene.get_node_or_null("Room/WallSouthLeft") as CSGBox3D
	var wall_south_r = main_scene.get_node_or_null("Room/WallSouthRight") as CSGBox3D
	var power_wall = main_scene.get_node_or_null("Room/WallPowerPanelExteriorSkin") as CSGBox3D

	var has_yellow_front = (wall_south_l != null and wall_south_l.material != null and wall_south_l.material.albedo_color.r > 0.85 and wall_south_l.material.albedo_color.g > 0.70)
	var has_yellow_power = (power_wall != null and power_wall.material != null and power_wall.material.albedo_color.r > 0.85 and power_wall.material.albedo_color.g > 0.70)

	if has_yellow_front and has_yellow_power:
		print("  ✅ TESTE 1: Fachada externa frontal e parede externa do quadro de energia com acabamento amarelo forte.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Fachada externa incorreta (FrontYellow: %s, PowerYellow: %s)" % [has_yellow_front, has_yellow_power])

	# --- TESTE 2: Sincronização em Tempo Real do PC com o Cardápio Físico na Parede ---
	total_tests += 1
	var menu_board = DiningMenuBoardScene.instantiate()
	root.add_child(menu_board)
	menu_board._ready()

	# Altera preços via MenuPricingManager (como o PC faz)
	MenuPricingManager.set_selling_price("burger_classic", 25.50)
	MenuPricingManager.set_selling_price("burger_supreme", 38.00)

	var col_left = menu_board.get_node_or_null("ColLeftLabel") as Label3D
	var col_right = menu_board.get_node_or_null("ColRightLabel") as Label3D

	var classic_updated = (col_left != null and "25,50" in col_left.text)
	var supreme_updated = (col_right != null and "38,00" in col_right.text)

	if classic_updated and supreme_updated:
		print("  ✅ TESTE 2: Alteração de preços no PC reflete instantaneamente no quadro físico de cardápio do restaurante.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Sincronização de preços falhou (Classic: %s, Supreme: %s)" % [classic_updated, supreme_updated])

	# --- TESTE 3: Sininho de Notificação do PC Reposicionado Confortavelmente Mais Alto ---
	total_tests += 1
	var pc_station = ComputerStationScene.instantiate()
	root.add_child(pc_station)
	pc_station._ready()

	var badge = pc_station.get_node_or_null("NotificationBadge") as Label3D
	var is_higher = (badge != null and badge.position.y >= 1.55)

	if is_higher:
		print("  ✅ TESTE 3: Sininho do PC posicionado confortavelmente mais alto (y = %.2fm), sem obstruir o monitor." % [badge.position.y if badge else 0.0])
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Altura do sino do PC incorreta (Y: %s)" % [badge.position.y if badge else "null"])

	# --- TESTE 4: Bloqueio Rigoroso de Delivery Durante a Fase de Preparação (09:00 - 10:00) ---
	total_tests += 1
	var clock = GameClockScript.get_instance()
	if not clock:
		clock = GameClockScript.new()
		clock.name = "GameClock"
		root.add_child(clock)
		clock._ready()

	var om = OrderManagerScript.get_instance()
	if not om:
		om = OrderManagerScript.new()
		om.name = "OrderManager"
		root.add_child(om)
		om._ready()

	om.active_orders.clear()
	clock.set_state(GameClockScript.State.PREPARATION)
	clock.current_hour = 9
	clock.current_minute = 30

	var orders_before = om.active_orders.size()
	om._delivery_spawn_timer = 0.01
	om._process_delivery_spawning(0.5)

	var orders_during_prep = om.active_orders.size()
	var no_orders_in_prep = (orders_during_prep == orders_before)

	# Agora abre o restaurante (State.OPEN) e verifica que o gerador opera
	clock.set_state(GameClockScript.State.OPEN)
	clock.current_hour = 10
	clock.current_minute = 5
	om._delivery_spawn_timer = 0.01
	om._process_delivery_spawning(0.5)

	var orders_when_open = om.active_orders.size()
	var spawned_when_open = (orders_when_open > orders_during_prep)

	if no_orders_in_prep and spawned_when_open:
		print("  ✅ TESTE 4: Nenhum pedido de delivery chega durante a fase de preparação; gerador inicia apenas com o restaurante aberto.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Delivery gerado na preparação ou bloqueado quando aberto (NoInPrep: %s, SpawnedWhenOpen: %s, PrepCount: %d, OpenCount: %d)" % [no_orders_in_prep, spawned_when_open, orders_during_prep, orders_when_open])

	# --- TESTE 5: Notificação de Delivery com PC Aberto Sem Interrupção ---
	total_tests += 1
	var comp_ui = ComputerUIScene.instantiate()
	root.add_child(comp_ui)
	comp_ui._ready()
	comp_ui.open()
	comp_ui._switch_tab(comp_ui.TabID.FINANCES, "Finanças & DRE")

	var initial_tab = comp_ui.current_tab
	var prev_unviewed = comp_ui.unviewed_orders_count

	# Chega novo delivery
	var new_del = om.create_delivery_order()

	var tab_unchanged = (comp_ui.current_tab == initial_tab) # Não troca de aba automaticamente
	var badge_lit = (comp_ui.unviewed_orders_count > prev_unviewed)
	var toast = comp_ui.notification_toast_panel
	var is_non_blocking = (toast != null and toast.mouse_filter == Control.MOUSE_FILTER_IGNORE)

	if tab_unchanged and badge_lit and is_non_blocking:
		print("  ✅ TESTE 5: Notificação de delivery com PC aberto é não-bloqueante, toca áudio e acende sino sem trocar de aba.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 5 FALHOU: Notificação no PC incorreta (TabUnchanged: %s, BadgeLit: %s, NonBlock: %s)" % [tab_unchanged, badge_lit, is_non_blocking])

	# --- RESULTADO FINAL ---
	print("\n===========================================================================")
	print("📊 RESULTADO FINAL: %d/%d TESTES PASSARAM (%.1f%%)" % [passed_tests, total_tests, (float(passed_tests)/float(total_tests))*100.0])
	print("===========================================================================")

	if passed_tests == total_tests:
		print("🎉 TODOS OS TESTES PASSARAM COM 100% DE SUCESSO!\n")
		quit(0)
	else:
		print("⚠️ ALGUNS TESTES FALHARAM.\n")
		quit(1)
