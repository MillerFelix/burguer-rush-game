extends SceneTree

const CustomerScene = preload("res://src/customers/customer.tscn")
const DayNightCycle = preload("res://src/time/day_night_cycle.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE ATENDIMENTO DE PEDIDO E CICLO DIA/NOITE")
	print("============================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var clock = main_scene.get_node("GameClock") as GameClock
	GameClock.instance = clock
	var order_mgr = main_scene.get_node("OrderManager") as OrderManager
	OrderManager.instance = order_mgr
	var economy_mgr = main_scene.get_node("EconomyManager") as EconomyManager
	EconomyManager.instance = economy_mgr
	var table_mgr = main_scene.get_node("TableManager") as TableManager
	var day_night = main_scene.get_node("DayNightCycle") as DayNightCycle
	var open_sign = main_scene.get_node("OpenSign") as OpenSign
	var player = main_scene.get_node("Player") as Node3D

	assert(clock != null, "GameClock deve existir")
	assert(order_mgr != null, "OrderManager deve existir")
	assert(table_mgr != null, "TableManager deve existir")
	assert(day_night != null, "DayNightCycle deve existir")
	assert(open_sign != null, "OpenSign deve existir")

	for child in main_scene.get_children():
		if child is RestaurantTable:
			table_mgr.register_table(child as RestaurantTable)

	# ---------------------------------------------------------
	# TESTE 1: HORÁRIO OFICIAL 09:00 — 21:00
	# ---------------------------------------------------------
	print("\n--- Teste 1: Validação do Horário Oficial 09:00 — 21:00 ---")
	assert(clock.auto_open_hour == 9, "Abertura automática deve ser às 09:00")
	assert(clock.closing_hour == 21, "Fechamento oficial deve ser às 21:00")

	clock.set_state(GameClock.State.PREPARATION)
	open_sign._update_sign()
	assert("09:00 — 21:00" in open_sign.label_3d.text, "Placa em PREPARAÇÃO deve conter '09:00 — 21:00'")

	clock.open_restaurant()
	open_sign._update_sign()
	print("DEBUG open_sign text: ", open_sign.label_3d.text)
	assert("09:00 — 21:00" in open_sign.label_3d.text, "Placa em ABERTO deve conter '09:00 — 21:00'")
	assert("ABERTO" in open_sign.label_3d.text, "Placa deve mostrar ABERTO")

	clock.set_state(GameClock.State.CLOSING)
	open_sign._update_sign()
	assert("09:00 — 21:00" in open_sign.label_3d.text, "Placa em ENCERRANDO deve conter '09:00 — 21:00'")

	clock.set_state(GameClock.State.CLOSED)
	open_sign._update_sign()
	assert("09:00 — 21:00" in open_sign.label_3d.text, "Placa em FECHADO deve conter '09:00 — 21:00'")
	assert("FECHADO" in open_sign.label_3d.text, "Placa deve mostrar FECHADO")
	print("  [PASS] Horário oficial 09:00 — 21:00 validado no relógio e em todos os estados da placa!")

	# ---------------------------------------------------------
	# TESTE 2: ATENDIMENTO DE PEDIDO COM 'E' SEM CRASH (FLUXO COMPLETO)
	# ---------------------------------------------------------
	print("\n--- Teste 2: Atendimento de Pedidos de Clientes Sentados ---")
	clock.open_restaurant()
	var tables = table_mgr.get_all_tables()

	for i in range(min(5, tables.size())):
		var tbl = tables[i]
		var cust = CustomerScene.instantiate() as Customer
		main_scene.add_child(cust)
		cust.setup(Vector3(0, 0, 10.5), Vector3(0, 0, 10.5), "burger_cheese", false)

		var seat_pos = tbl.occupy_seat(cust)
		cust.assign_seat(tbl, seat_pos, 1)

		# Caminhada até a cadeira
		while not cust.path_waypoints.is_empty() and cust.state != Customer.State.SEATED_WAITING_TO_ORDER:
			cust._physics_process(0.1)

		assert(cust.state == Customer.State.SEATED_WAITING_TO_ORDER, "Cliente %d deve estar esperando para pedir" % i)

		# Jogador interage com E diretamente no cliente
		var prompt = cust.get_interaction_prompt(player)
		assert("Atender Cliente" in prompt, "Prompt deve indicar atendimento")

		# Executa interação
		print("DEBUG cust state before interact: ", cust.state)
		cust.interact(player)
		print("DEBUG cust state after interact: ", cust.state)

		assert(cust.state == Customer.State.WAITING_FOR_FOOD, "Cliente deve transicionar para WAITING_FOR_FOOD após atendimento")
		assert(cust.current_order != null, "Pedido do cliente deve ter sido criado no OrderManager")
		assert(cust.current_order.table_id == tbl.table_id, "Pedido deve estar vinculado à mesa correta")

	print("  [PASS] Atendimento de pedidos executado com sucesso e sem qualquer crash!")

	# ---------------------------------------------------------
	# TESTE 3: CICLO DE ILUMINAÇÃO DINÂMICA (09:00, 12:00, 15:00, 17:30, 19:00, 20:30, 21:00)
	# ---------------------------------------------------------
	print("\n--- Teste 3: Transições de Iluminação Dinâmica ao Longo do Dia ---")
	var test_hours = [9.0, 12.0, 15.0, 17.5, 19.0, 20.5, 21.0]

	for h in test_hours:
		var hours_int = int(h)
		var mins_int = int((h - hours_int) * 60)
		day_night._on_time_tick(hours_int, mins_int)

		var sun = day_night.sun_light
		var env = day_night.world_environment.environment if day_night.world_environment else null

		if h < 14.0:
			# Manhã e Almoço: Sol claro com energia alta
			assert(sun.light_energy >= 1.0, "Energia solar diurna deve ser >= 1.0 às %02d:%02d (atual: %f)" % [hours_int, mins_int, sun.light_energy])
			assert(env.background_energy_multiplier >= 0.9, "Céu diurno deve ser claro às %02d:%02d" % [hours_int, mins_int])
		elif h == 17.5:
			# Fim de tarde: Luz dourada/aquecida e sol com ângulo mais baixo
			assert(sun.light_color.r > sun.light_color.b, "Luz de fim de tarde deve ser mais avermelhada/dourada")
		elif h >= 19.0:
			# Noite: Sol escurecido (luar) e luzes ativadas
			assert(sun.light_energy < 0.25, "Luz solar deve ser mínima à noite às %02d:%02d (atual: %f)" % [hours_int, mins_int, sun.light_energy])
			assert(env.background_energy_multiplier <= 0.35, "Céu noturno deve ser escuro às %02d:%02d" % [hours_int, mins_int])

		print("  [PASS] Horário %02d:%02d verificado com sucesso (Energia Sol: %.2f, Cor: %s)" % [hours_int, mins_int, sun.light_energy, str(sun.light_color)])

	main_scene.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE ATENDIMENTO E CICLO DIA/NOITE FORAM APROVADOS!")
	print("============================================================")
	quit(0)
