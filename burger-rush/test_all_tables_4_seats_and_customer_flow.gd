extends SceneTree

const CustomerScene = preload("res://src/customers/customer.tscn")
const AmbientPedestrian = preload("res://src/environment/ambient_pedestrian.tscn")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE MESAS DE 4, FLUXO DE CLIENTES E SALÃO")
	print("============================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var clock = main_scene.get_node("GameClock") as GameClock
	clock.open_restaurant()

	var table_mgr = main_scene.get_node("TableManager") as TableManager
	for child in main_scene.get_children():
		if child is RestaurantTable:
			table_mgr.register_table(child as RestaurantTable)

	# ---------------------------------------------------------
	# TESTE 1: TODAS AS MESAS TÊM 4 LUGARES E TOTAL DE 7 MESAS (28 ASSENTOS)
	# ---------------------------------------------------------
	print("\n--- Teste 1: 7 Mesas de 4 Lugares (28 Assentos no Total) ---")
	var all_tables = table_mgr.get_all_tables()
	assert(all_tables.size() >= 7, "Devem existir pelo menos 7 mesas (atual: %d)" % all_tables.size())

	for t in all_tables:
		assert(t.seat_count == 4, "Mesa %d deve possuir seat_count = 4 (atual: %d)" % [t.table_id, t.seat_count])
		assert(t.has_node("Seat1") and t.has_node("Seat2") and t.has_node("Seat3") and t.has_node("Seat4"), "Mesa %d deve possuir Seat1 a Seat4" % t.table_id)
		assert(t.has_node("Model/Chair1") and t.has_node("Model/Chair2") and t.has_node("Model/Chair3") and t.has_node("Model/Chair4"), "Mesa %d deve possuir 4 cadeiras visíveis" % t.table_id)

	var total_seats = table_mgr.get_total_seat_capacity()
	assert(total_seats >= 28, "Capacidade total do salão deve ser de pelo menos 28 assentos (atual: %d)" % total_seats)
	print("  [PASS] 7 mesas com 4 cadeiras e 4 posições de assento cada (Total: %d assentos)!" % total_seats)

	# ---------------------------------------------------------
	# TESTE 2: SEPARAÇÃO ENTRE CLIENTE E PEDESTRE EXTERNO
	# ---------------------------------------------------------
	print("\n--- Teste 2: Classificação e Separação de NPCs ---")
	var ped = AmbientPedestrian.instantiate()
	root.add_child(ped)
	assert(not ped.has_method("place_order"), "Pedestre externo não deve ter método de fazer pedido")
	assert(not ped.has_method("assign_seat"), "Pedestre externo não deve ter método de sentar em mesa")
	ped.queue_free()

	var cust = CustomerScene.instantiate() as Customer
	root.add_child(cust)
	assert(cust.has_method("place_order"), "Cliente deve possuir método de fazer pedido")
	assert(cust.has_method("assign_seat"), "Cliente deve possuir método de sentar em mesa")
	cust.queue_free()
	print("  [PASS] Comportamento de pedestres e clientes totalmente segregado!")

	# ---------------------------------------------------------
	# TESTE 3: CLIENTE NUNCA PODE SENTAR FORA DO SALÃO
	# ---------------------------------------------------------
	print("\n--- Teste 3: Proibição Estrita de Sentada Fora do Salão ---")
	var outside_cust = CustomerScene.instantiate() as Customer
	root.add_child(outside_cust)
	outside_cust.setup(Vector3(0.0, 0, 10.2), Vector3(0.0, 0, 10.2), "", false)

	# Tentativa de sentar na calçada / rua
	outside_cust._try_reach_seat()
	assert(outside_cust.state != Customer.State.SEATED_WAITING_TO_ORDER, "Cliente fora do salão não pode entrar em SEATED_WAITING_TO_ORDER")
	outside_cust.queue_free()
	print("  [PASS] Cliente fora do restaurante nunca entra no estado de sentada!")

	# ---------------------------------------------------------
	# TESTE 4: GRUPOS DE 1 A 4 PESSOAS COM ASSENTOS ÚNICOS NA MESMA MESA
	# ---------------------------------------------------------
	print("\n--- Teste 4: Alocação de 4 Assentos Únicos para Grupos de 4 ---")
	var target_table = all_tables[0]
	var group_members: Array[Customer] = []
	var seat_positions: Array[Vector3] = []

	for i in range(4):
		var member = CustomerScene.instantiate() as Customer
		root.add_child(member)
		member.setup(Vector3(0.0, 0, 10.2), Vector3(0.0, 0, 10.2), "", false)
		var seat_pos = target_table.occupy_seat(member)
		member.assign_seat(target_table, seat_pos)
		group_members.append(member)
		seat_positions.append(seat_pos)

	# Verifica se cada membro recebeu um assento diferente
	for i in range(4):
		for j in range(i + 1, 4):
			assert(seat_positions[i].distance_to(seat_positions[j]) > 0.5, "Assentos %d e %d não podem ser duplicados" % [i, j])

	for member in group_members:
		member.queue_free()
	target_table.release()
	print("  [PASS] Todos os 4 assentos da mesa são únicos e suportam grupos de 1 a 4 pessoas!")

	# ---------------------------------------------------------
	# TESTE 5: LIXEIRA DO SALÃO VOLTADA PARA O SALÃO (NÃO PARA A PAREDE)
	# ---------------------------------------------------------
	print("\n--- Teste 5: Orientação da Lixeira do Salão ---")
	var waste_station = main_scene.get_node("DiningWasteStation") as Node3D
	assert(waste_station != null, "DiningWasteStation deve existir")
	# Rotacionada 180 graus (transform.basis.z aponta para -Z)
	assert(waste_station.transform.basis.z.z < -0.5, "Lixeira deve estar voltada para o salão (-Z), não para a parede (+Z)")
	print("  [PASS] Lixeira do salão devidamente voltada para o cliente e área do salão!")

	# ---------------------------------------------------------
	# TESTE 6: PLACA ABRIR/FECHAR JUNTO À PORTA PRINCIPAL
	# ---------------------------------------------------------
	print("\n--- Teste 6: Posicionamento da Placa Aberto/Fechado na Porta ---")
	var open_sign = main_scene.get_node("OpenSign") as Node3D
	assert(open_sign != null, "OpenSign deve existir")
	assert(open_sign.position.z >= 8.0 and open_sign.position.z <= 9.2, "Placa deve estar próxima da porta de entrada (z ~ 8.5)")
	assert(abs(open_sign.position.x) <= 3.0, "Placa deve estar ao lado da passagem da porta principal")
	print("  [PASS] Placa de Abrir/Fechar posicionada perfeitamente ao lado da porta principal!")

	# Limpeza
	main_scene.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE MESAS, FLUXO E SALÃO FORAM APROVADOS!")
	print("============================================================")
	quit(0)
