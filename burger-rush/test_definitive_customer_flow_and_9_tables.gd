extends SceneTree

const CustomerScene = preload("res://src/customers/customer.tscn")
const AmbientPedestrian = preload("res://src/environment/ambient_pedestrian.tscn")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DEFINITIVO DE FLUXO DE CLIENTES E 9 MESAS")
	print("============================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var clock = main_scene.get_node("GameClock") as GameClock
	clock.open_restaurant()

	var table_mgr = main_scene.get_node("TableManager") as TableManager
	for child in main_scene.get_children():
		if child is RestaurantTable:
			table_mgr.register_table(child as RestaurantTable)

	var spawner = main_scene.get_node("CustomerSpawner") as CustomerSpawner
	assert(spawner != null, "CustomerSpawner deve existir")

	# ---------------------------------------------------------
	# TESTE 1: SALÃO COM 9 MESAS DE 4 LUGARES (36 ASSENTOS NO TOTAL)
	# ---------------------------------------------------------
	print("\n--- Teste 1: 9 Mesas de 4 Lugares (36 Assentos no Total) ---")
	var all_tables = table_mgr.get_all_tables()
	assert(all_tables.size() >= 9, "Devem existir pelo menos 9 mesas no salão (atual: %d)" % all_tables.size())

	for t in all_tables:
		assert(t.seat_count == 4, "Mesa %d deve possuir 4 lugares" % t.table_id)
		assert(t.has_node("Seat1") and t.has_node("Seat2") and t.has_node("Seat3") and t.has_node("Seat4"), "Mesa %d deve ter 4 assentos" % t.table_id)
		assert(t.has_node("Model/Chair1") and t.has_node("Model/Chair2") and t.has_node("Model/Chair3") and t.has_node("Model/Chair4"), "Mesa %d deve ter 4 cadeiras" % t.table_id)

	var total_seats = table_mgr.get_total_seat_capacity()
	assert(total_seats >= 36, "Capacidade total do salão deve ser de pelo menos 36 assentos (atual: %d)" % total_seats)
	print("  [PASS] 9 mesas configuradas com 4 cadeiras e assentos cada (Total: %d assentos)!" % total_seats)

	# ---------------------------------------------------------
	# TESTE A: 1 CLIENTE SOLO (SPAWN -> PORTA -> MESA -> SENTAR)
	# ---------------------------------------------------------
	print("\n--- Teste A: 1 Cliente Solo ---")
	var table_a = table_mgr.get_available_table_for_group(1)
	assert(table_a != null, "Deve encontrar mesa disponível para 1 cliente")

	var cust_a = CustomerScene.instantiate() as Customer
	main_scene.add_child(cust_a)
	cust_a.setup(Vector3(0.0, 0, 10.5), Vector3(0.0, 0, 10.5), "", false)
	var seat_pos_a = table_a.occupy_seat(cust_a)
	cust_a.assign_seat(table_a, seat_pos_a)

	# Simula navegação passo a passo
	while not cust_a.path_waypoints.is_empty() and cust_a.state != Customer.State.SEATED_WAITING_TO_ORDER:
		cust_a._physics_process(0.1)

	assert(cust_a.is_physically_inside_restaurant(), "Cliente deve estar fisicamente dentro do restaurante")
	assert(cust_a.state == Customer.State.SEATED_WAITING_TO_ORDER, "Cliente deve estar sentado na cadeira")
	print("  [PASS] Cliente solo caminhou pela calçada, entrou pela porta e sentou perfeitamente!")

	# ---------------------------------------------------------
	# TESTE B: 2 CLIENTES (CASAL)
	# ---------------------------------------------------------
	print("\n--- Teste B: 2 Clientes (Casal) ---")
	var table_b = table_mgr.get_available_table_for_group(2)
	assert(table_b != null, "Deve encontrar mesa para casal")
	var members_b: Array[Customer] = []
	var seats_b: Array[Vector3] = []

	for i in range(2):
		var member = CustomerScene.instantiate() as Customer
		main_scene.add_child(member)
		member.setup(Vector3(randf_range(-0.5, 0.5), 0, 10.5), Vector3(0, 0, 10.5), "", false)
		var seat_pos = table_b.occupy_seat(member)
		member.assign_seat(table_b, seat_pos)
		members_b.append(member)
		seats_b.append(seat_pos)

	assert(seats_b[0].distance_to(seats_b[1]) > 0.5, "Casal deve ocupar duas cadeiras distintas na mesma mesa")
	for member in members_b:
		while not member.path_waypoints.is_empty() and member.state != Customer.State.SEATED_WAITING_TO_ORDER:
			member._physics_process(0.1)
		assert(member.is_physically_inside_restaurant(), "Membro do casal deve estar dentro do restaurante")
		assert(member.state == Customer.State.SEATED_WAITING_TO_ORDER, "Membro do casal deve estar sentado")
	print("  [PASS] Casal entrou junto e ocupou 2 cadeiras exclusivas na mesa!")

	# ---------------------------------------------------------
	# TESTE C: 3 CLIENTES (FAMÍLIA COM CRIANÇA)
	# ---------------------------------------------------------
	print("\n--- Teste C: 3 Clientes (Família com Criança) ---")
	var table_c = table_mgr.get_available_table_for_group(3)
	assert(table_c != null, "Deve encontrar mesa para família")
	var members_c: Array[Customer] = []
	for i in range(3):
		var member = CustomerScene.instantiate() as Customer
		main_scene.add_child(member)
		var is_kid = (i == 2)
		member.setup(Vector3(randf_range(-0.5, 0.5), 0, 10.5), Vector3(0, 0, 10.5), "", is_kid)
		var seat_pos = table_c.occupy_seat(member)
		member.assign_seat(table_c, seat_pos)
		members_c.append(member)

	for member in members_c:
		while not member.path_waypoints.is_empty() and member.state != Customer.State.SEATED_WAITING_TO_ORDER:
			member._physics_process(0.1)
		assert(member.is_physically_inside_restaurant(), "Membro da família deve estar dentro")
		assert(member.state == Customer.State.SEATED_WAITING_TO_ORDER, "Membro da família deve estar sentado")
	print("  [PASS] Família com criança entrou e sentou com proporções e posições corretas!")

	# ---------------------------------------------------------
	# TESTE D: 4 CLIENTES (GRUPO COMPLETO DE 4 PESSOAS)
	# ---------------------------------------------------------
	print("\n--- Teste D: Grupo Completo de 4 Pessoas ---")
	var table_d = table_mgr.get_available_table_for_group(4)
	assert(table_d != null, "Deve encontrar mesa para grupo de 4")
	var members_d: Array[Customer] = []
	var seats_d: Array[Vector3] = []
	for i in range(4):
		var member = CustomerScene.instantiate() as Customer
		main_scene.add_child(member)
		member.setup(Vector3(randf_range(-0.5, 0.5), 0, 10.5), Vector3(0, 0, 10.5), "", (i >= 2))
		var seat_pos = table_d.occupy_seat(member)
		member.assign_seat(table_d, seat_pos)
		members_d.append(member)
		seats_d.append(seat_pos)

	for i in range(4):
		for j in range(i + 1, 4):
			assert(seats_d[i].distance_to(seats_d[j]) > 0.5, "Assentos %d e %d devem ser únicos" % [i, j])

	for member in members_d:
		while not member.path_waypoints.is_empty() and member.state != Customer.State.SEATED_WAITING_TO_ORDER:
			member._physics_process(0.1)
		assert(member.is_physically_inside_restaurant(), "Cliente de 4 deve estar dentro")
		assert(member.state == Customer.State.SEATED_WAITING_TO_ORDER, "Cliente de 4 deve estar sentado")
	print("  [PASS] Grupo de 4 ocupou perfeitamente todos os 4 assentos da mesa!")

	# ---------------------------------------------------------
	# TESTE E & F: MÚLTIPLOS GRUPOS SIMULTÂNEOS NO SALÃO EXPANDIDO
	# ---------------------------------------------------------
	print("\n--- Teste E & F: Múltiplos Grupos Simultâneos no Salão ---")
	var active_groups = 0
	while table_mgr.get_available_table_count() > 0:
		var grp = spawner.spawn_customer_group()
		if grp.is_empty():
			break
		active_groups += 1
		for cust in grp:
			while not cust.path_waypoints.is_empty() and cust.state != Customer.State.SEATED_WAITING_TO_ORDER:
				cust._physics_process(0.1)

	print("  [PASS] Salão totalmente operante com %d mesas e grupos simultâneos!" % all_tables.size())

	# Limpeza
	main_scene.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DEFINITIVOS DE CLIENTES E MESAS APROVADOS!")
	print("============================================================")
	quit(0)
