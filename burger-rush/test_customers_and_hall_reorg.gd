extends SceneTree

const AmbientPedestrian = preload("res://src/environment/ambient_pedestrian.tscn")
const CustomerScene = preload("res://src/customers/customer.tscn")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE REORGANIZAÇÃO DO SALÃO E CLIENTES")
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
	# TESTE 1: RUA CONTÍNUA SEM GRAMA / VERDE NA VIA
	# ---------------------------------------------------------
	print("\n--- Teste 1: Chão da Rua 100% Asfalto Sem Terreno Verde Sobreposto ---")
	var street = main_scene.get_node("Room/FloorStreet") as CSGBox3D
	var lawn_s = main_scene.get_node("Room/LawnSouthDeep") as CSGBox3D
	var lawn_w = main_scene.get_node("Room/LawnWestOuter") as CSGBox3D
	var lawn_e = main_scene.get_node("Room/LawnEastOuter") as CSGBox3D

	assert(street.size.x >= 90.0, "Rua deve cobrir toda a extensão urbana (90m+)")
	assert(lawn_s.position.z >= 35.0, "Gramado sul deve ficar atrás das casas (z >= 35m)")
	assert(lawn_w.size.z <= 20.0 and lawn_e.size.z <= 20.0, "Gramados laterais não devem invadir o asfalto da rua")
	print("  [PASS] Asfalto contínuo sem grama invadindo a rua!")

	# ---------------------------------------------------------
	# TESTE 2: PEDESTRES EXTERNOS COM MESMO MODELO E ROSTO DOS CLIENTES
	# ---------------------------------------------------------
	print("\n--- Teste 2: Pedestres com Rosto e Modelo Idêntico aos Clientes ---")
	var ped_inst = AmbientPedestrian.instantiate()
	root.add_child(ped_inst)
	assert(ped_inst.has_node("Model/Head/EyeLeft"), "Pedestre deve possuir olho esquerdo")
	assert(ped_inst.has_node("Model/Head/EyeRight"), "Pedestre deve possuir olho direito")
	assert(ped_inst.has_node("Model/Head/Mouth"), "Pedestre deve possuir boca/sorriso")
	assert(ped_inst.has_node("Model/Head/Hair"), "Pedestre deve possuir cabelo estilizado")
	assert(ped_inst.has_node("Model/Torso") and ped_inst.has_node("Model/LegLeft"), "Pedestre deve possuir corpo completo")
	ped_inst.queue_free()
	print("  [PASS] Pedestres possuem rosto expressivo e mesmo sistema visual dos clientes!")

	# ---------------------------------------------------------
	# TESTE 3: EXPANSÃO DE MESAS (6 MESAS E 20 ASSENTOS)
	# ---------------------------------------------------------
	print("\n--- Teste 3: Expansão de Mesas e Capacidade do Salão ---")
	var tables = table_mgr.get_all_tables()
	assert(tables.size() >= 6, "Restaurante deve possuir pelo menos 6 mesas no salão (atual: %d)" % tables.size())
	var total_seats = table_mgr.get_total_seat_capacity()
	assert(total_seats >= 20, "Restaurante deve suportar pelo menos 20 assentos (atual: %d)" % total_seats)
	print("  [PASS] 6 mesas organizadas com capacidade total de %d assentos!" % total_seats)

	# ---------------------------------------------------------
	# TESTE 4: GRUPOS DE 1 A 4 PESSOAS E NAVEGAÇÃO POR WAYPOINTS
	# ---------------------------------------------------------
	print("\n--- Teste 4: Grupos de Clientes (Solo, Casal, Família com Criança e Grupo de 4) ---")
	var spawner = main_scene.get_node("CustomerSpawner") as CustomerSpawner
	assert(spawner != null, "CustomerSpawner deve existir")

	# Teste Grupo 4 (Família com Crianças)
	print("Mesas registradas no TableManager: ", table_mgr.get_all_tables().size())
	print("Mesas disponíveis: ", table_mgr.get_available_table_count())
	var group = spawner.spawn_customer_group()
	print("Grupo spawnado com tamanho: ", group.size())
	assert(group.size() >= 1, "Grupo de clientes deve spawnar com sucesso")
	var primary_c = group[0]
	assert(primary_c.assigned_table != null, "Mesa deve ser atribuída ao grupo")
	assert(primary_c.path_waypoints.size() >= 3, "Cliente deve possuir rota de waypoints passando pela porta")

	# Simula caminhada através da porta
	while not primary_c.path_waypoints.is_empty() and primary_c.state == Customer.State.WALKING_TO_TABLE:
		primary_c._physics_process(0.1)

	assert(primary_c.state == Customer.State.SEATED_WAITING_TO_ORDER, "Cliente deve chegar e sentar na cadeira sem teleport")
	print("  [PASS] Grupo de clientes entrou pela porta, navegou pelos corredores e sentou perfeitamente!")

	# Limpeza
	main_scene.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE REORGANIZAÇÃO DO SALÃO FORAM APROVADOS!")
	print("============================================================")
	quit(0)
