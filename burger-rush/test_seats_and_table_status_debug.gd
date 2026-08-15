extends SceneTree

const CustomerScene = preload("res://src/customers/customer.tscn")
const AmbientPedestrian = preload("res://src/environment/ambient_pedestrian.tscn")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE DEBUG DE SEAT POINTS E STATUS DE MESA")
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
	# TESTE 1: TODAS AS 11 MESAS E SEUS 44 SEAT POINTS ESTÃO NO INTERIOR
	# ---------------------------------------------------------
	print("\n--- Teste 1: Validação de Coordenadas Globais dos 44 Seat Points ---")
	var all_tables = table_mgr.get_all_tables()
	assert(all_tables.size() == 11, "Devem existir exatamente 11 mesas no salão (atual: %d)" % all_tables.size())

	for t in all_tables:
		assert(t.seat_count == 4, "Mesa %d deve possuir 4 lugares" % t.table_id)
		for s_idx in range(1, 5):
			var seat_pos = t.get_seat_position(s_idx)
			# Validação de limites internos do restaurante
			assert(seat_pos.x >= -8.8 and seat_pos.x <= 8.8, "Seat %d da Mesa %d fora do limite X: %f" % [s_idx, t.table_id, seat_pos.x])
			assert(seat_pos.z >= -8.8 and seat_pos.z <= 8.2, "Seat %d da Mesa %d fora do limite Z (na rua/fora): %f" % [s_idx, t.table_id, seat_pos.z])

	var total_seats = table_mgr.get_total_seat_capacity()
	assert(total_seats == 44, "Capacidade total do salão deve ser de 44 assentos (atual: %d)" % total_seats)
	print("  [PASS] Todas as 11 mesas e seus 44 assentos estão 100%% dentro do salão interno!")

	# ---------------------------------------------------------
	# TESTE 2: TRANSIÇÃO DE STATUS DA MESA ("A CAMINHO" -> "OCUPADA")
	# ---------------------------------------------------------
	print("\n--- Teste 2: Transição de Status da Mesa ao Sentar ---")
	var test_table = all_tables[0]
	assert(test_table.table_state == RestaurantTable.TableState.AVAILABLE, "Mesa deve iniciar livre")

	var cust = CustomerScene.instantiate() as Customer
	main_scene.add_child(cust)
	cust.setup(Vector3(0.0, 0, 10.5), Vector3(0.0, 0, 10.5), "", false)
	var seat_pos = test_table.occupy_seat(cust)
	cust.assign_seat(test_table, seat_pos, 1)

	var lbl = test_table.get_node_or_null("StatusLabel") as Label3D
	assert(test_table.table_state == RestaurantTable.TableState.RESERVED, "Mesa deve ficar RESERVED (A Caminho...) enquanto cliente navega")
	if lbl:
		assert("A Caminho" in lbl.text, "Label da mesa deve mostrar 'A Caminho...'")

	# Simula caminhada do cliente até a cadeira
	while not cust.path_waypoints.is_empty() and cust.state != Customer.State.SEATED_WAITING_TO_ORDER:
		cust._physics_process(0.1)

	assert(cust.state == Customer.State.SEATED_WAITING_TO_ORDER, "Cliente deve estar sentado")
	assert(test_table.table_state == RestaurantTable.TableState.OCCUPIED, "Mesa DEVE transicionar para OCCUPIED quando o cliente senta!")
	if lbl:
		assert("Ocupada" in lbl.text, "Label da mesa deve mostrar 'Ocupada' (não 'A Caminho')")
	print("  [PASS] Status da mesa atualizado com sucesso de 'A Caminho' para 'Ocupada'!")

	# ---------------------------------------------------------
	# TESTE 3: GRUPOS DE 4 PESSOAS COM ASSENTOS EXCLUSIVOS
	# ---------------------------------------------------------
	print("\n--- Teste 3: Alocação de 4 Assentos Únicos para Família de 4 ---")
	var group_table = all_tables[1]
	var group_custs: Array[Customer] = []
	var group_seats: Array[Vector3] = []

	for i in range(4):
		var member = CustomerScene.instantiate() as Customer
		main_scene.add_child(member)
		member.setup(Vector3(randf_range(-0.5, 0.5), 0, 10.5), Vector3(0, 0, 10.5), "", (i >= 2))
		var s_pos = group_table.occupy_seat(member)
		member.assign_seat(group_table, s_pos, i + 1)
		group_custs.append(member)
		group_seats.append(s_pos)

	for i in range(4):
		for j in range(i + 1, 4):
			assert(group_seats[i].distance_to(group_seats[j]) > 0.5, "Assentos %d e %d não podem coincidir" % [i, j])

	for member in group_custs:
		while not member.path_waypoints.is_empty() and member.state != Customer.State.SEATED_WAITING_TO_ORDER:
			member._physics_process(0.1)
		assert(member.is_physically_inside_restaurant(), "Cliente deve estar dentro do restaurante")
		assert(member.state == Customer.State.SEATED_WAITING_TO_ORDER, "Cliente deve estar sentado")

	assert(group_table.table_state == RestaurantTable.TableState.OCCUPIED, "Mesa de grupo deve estar OCCUPIED")
	print("  [PASS] Grupo de 4 pessoas ocupou os 4 assentos distintos da mesma mesa!")

	# Limpeza
	main_scene.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE DEBUG DE MESAS E ASSENTOS FORAM APROVADOS!")
	print("============================================================")
	quit(0)
