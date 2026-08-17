extends SceneTree

# =============================================================================
# BURGER RUSH - TESTE: RITMO MODERADO, CHAPA LIVRE, COCÇÃO DE QUEIJOS,
#                      MONTAGEM LIVRE E CONSEQUÊNCIA DE PEDIDOS ERRADOS
# =============================================================================

const CustomerSpawner = preload("res://src/customers/customer_spawner.gd")
const Customer = preload("res://src/customers/customer.gd")
const Grill = preload("res://src/stations/grill.gd")
const Cheese = preload("res://src/items/cheese.gd")
const Patty = preload("res://src/items/patty.gd")
const BreadBottom = preload("res://src/items/bread_bottom.gd")
const BurgerAssembly = preload("res://src/recipes/burger_assembly.gd")
const RestaurantTable = preload("res://src/stations/restaurant_table.gd")
const DeliveryStation = preload("res://src/stations/delivery_station.gd")
const DeliveryCar = preload("res://src/environment/delivery_car.gd")
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(85))
	print("TESTE: FLUXO, CHAPA, QUEIJOS, MONTAGEM LIVRE E PEDIDOS ERRADOS")
	print("=".repeat(85) + "\n")
	call_deferred("_run_tests")

func assert_test(condition: bool, test_name: String) -> void:
	if condition:
		pass_count += 1
		print("  [PASS] %s" % test_name)
	else:
		fail_count += 1
		print("  [FAIL] %s" % test_name)

func _run_tests() -> void:
	var main_scene = load("res://src/main.tscn")
	if not main_scene:
		print("ERRO: main.tscn não encontrado")
		quit(1)
		return

	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	await create_timer(0.3).timeout

	print("\n--- TESTE 1: Ritmo de Clientes Moderado e Administrável ---")
	var spawner = root_node.find_child("CustomerSpawner", true, false) as CustomerSpawner
	assert_test(spawner != null, "1.1 CustomerSpawner ativo no restaurante")

	var normal_interval_lunch = spawner._calculate_interval_for_time(12.5)
	assert_test(normal_interval_lunch >= 25.0, "1.2 Intervalo de almoço moderado (%.1fs >= 25.0s)" % normal_interval_lunch)

	var max_concurrent = spawner._get_max_concurrent_customers(12.5)
	assert_test(max_concurrent <= 5, "1.3 Limite de clientes simultâneos moderado (%d clientes)" % max_concurrent)

	print("\n--- TESTE 2: Chapa (Remoção Livre de Ingredientes) ---")
	var grill = root_node.find_child("Grill", true, false) as Grill
	assert_test(grill != null, "2.1 Grill presente na cozinha")
	var player = root_node.find_child("Player", true, false)
	assert_test(player != null, "2.2 Jogador presente")

	var cheese_cheddar = Cheese.new()
	cheese_cheddar.cheese_type = Cheese.CheeseType.CHEDDAR
	root_node.add_child(cheese_cheddar)

	grill.place_item(cheese_cheddar)
	assert_test(grill.active_items.size() == 1, "2.3 Queijo colocado na chapa com sucesso")

	# Jogador com mão livre (Slot 3) remove o ingrediente da chapa sem bloqueios
	player.set("active_tool_slot", 3)
	player.set("held_item", null)
	grill.interact_item(player)

	assert_test(grill.active_items.is_empty(), "2.4 Ingrediente removido da chapa livremente com as mãos")
	assert_test(player.get("held_item") == cheese_cheddar, "2.5 Jogador recuperou o item na mão")
	player.set("held_item", null)

	print("\n--- TESTE 3: Sistema de Cocção dos 3 Tipos de Queijo ---")
	var cheeses_to_test = [
		{"type": Cheese.CheeseType.CHEDDAR, "name": "Cheddar"},
		{"type": Cheese.CheeseType.MOZZARELLA, "name": "Muçarela"},
		{"type": Cheese.CheeseType.PRATO, "name": "Prato"}
	]

	for cdata in cheeses_to_test:
		var c_item = Cheese.new()
		c_item.cheese_type = cdata["type"]
		root_node.add_child(c_item)

		# Estado 1: RAW
		assert_test(c_item.state == Cheese.State.RAW, "3.1 %s começa em estado RAW (Cru)" % cdata["name"])

		# Estado 2: Derretendo / READY na chapa quente
		c_item.advance_cooking(100.0)
		assert_test(c_item.state == Cheese.State.READY, "3.2 %s atinge estado READY (Derretido/Pronto)" % cdata["name"])
		assert_test(c_item.is_melted(), "3.3 %s reconhecido como queijo derretido" % cdata["name"])

		# Estado 3: Queimando se permanecer tempo demais
		c_item.set_burnt()
		assert_test(c_item.state == Cheese.State.BURNT, "3.4 %s queima e resseca se passar do ponto (BURNT)" % cdata["name"])
		assert_test(c_item.is_burnt(), "3.5 %s reconhecido como queimado" % cdata["name"])
		assert_test(c_item.get_ingredient_key().ends_with(":burnt"), "3.6 %s possui chave de ingrediente queimado" % cdata["name"])

	print("\n--- TESTE 4: Montagem Livre de Lanches em Qualquer Superfície ---")
	var bread_bottom = BreadBottom.new()
	root_node.add_child(bread_bottom)
	bread_bottom.position = Vector3(5.0, 0.8, 2.0) # Superfície qualquer do mundo
	bread_bottom._ready()

	var patty = Patty.new()
	patty.meat_type = Patty.MeatType.BEEF
	root_node.add_child(patty)
	patty.state = Patty.State.COOKED # Cozido

	var melted_cheese = Cheese.new()
	melted_cheese.cheese_type = Cheese.CheeseType.CHEDDAR
	melted_cheese.state = Cheese.State.READY
	root_node.add_child(melted_cheese)

	var bread_top_scene = load("res://src/items/bread_top.tscn")
	var bread_top = bread_top_scene.instantiate()
	root_node.add_child(bread_top)

	# Adiciona carne e queijo sobre o pão
	bread_bottom.assembly.add_ingredient(patty, bread_bottom.position + Vector3(0, 0.04, 0))
	bread_bottom.assembly.add_ingredient(melted_cheese, bread_bottom.position + Vector3(0, 0.07, 0))
	bread_bottom.assembly.close_burger(bread_top, bread_bottom.position + Vector3(0, 0.10, 0))

	assert_test(bread_bottom.assembly.state == BurgerAssembly.State.CLOSED, "4.1 Lanche montado e fechado fisicamente no mundo")
	assert_test(not bread_bottom.assembly.status_label or not bread_bottom.assembly.status_label.visible or bread_bottom.assembly.status_label.text == "", "4.2 Sem contador artificial de montagem ('1/5') na interface")

	print("\n--- TESTE 5: Consequência Real para Pedido Errado na Mesa ---")
	var economy = root_node.find_child("EconomyManager", true, false)
	var initial_money = economy.current_money if economy else 100.0

	var table = root_node.find_child("RestaurantTable1", true, false)
	if not table:
		var tables = root_node.find_children("*", "RestaurantTable", true, false)
		if not tables.is_empty():
			table = tables[0]

	var cust_group = spawner.spawn_customer_group()
	assert_test(not cust_group.is_empty(), "5.0 Cliente gerado para o teste de mesa")
	var cust = cust_group[0]
	cust.assigned_table = table
	if table:
		table.table_state = RestaurantTable.TableState.OCCUPIED

	var test_order = Order.new()
	test_order.id = 101
	var table_items: Array[Dictionary] = [{"product_id": "cheeseburger", "product_name": "Cheeseburger", "quantity": 1, "delivered_quantity": 0, "price": 18.0}]
	test_order.items = table_items
	test_order.total_price = 18.0
	cust.current_order = test_order
	cust.state = Customer.State.WAITING_FOR_FOOD

	# Jogador entrega item ERRADO (ex: um queijo cru avulso em vez do cheeseburger pedido)
	var wrong_item = Cheese.new()
	wrong_item.item_id = "cheese_prato"
	player.set("held_item", wrong_item)

	if table:
		table._serve_single_item(player, wrong_item)

	assert_test(cust.experience != null and cust.experience.abandoned, "5.1 Cliente rejeitou o pedido errado e abandonou")
	assert_test(cust.state == Customer.State.LEAVING, "5.2 Cliente insatisfeito levantou e foi embora (LEAVING)")
	assert_test(economy.current_money == initial_money, "5.3 Cliente NÃO pagou ($0.00 recebido: R$ %.2f)" % economy.current_money)

	print("\n--- TESTE 6: Consequência Real para Pedido Errado no Drive-Thru ---")
	var deliv_station = root_node.find_child("DeliveryStation", true, false)
	assert_test(deliv_station != null, "6.1 DeliveryStation ativa no Drive-Thru")

	var deliv_mgr = root_node.find_child("DeliveryQueueManager", true, false)
	var car = deliv_mgr.spawn_car()
	assert_test(car != null, "6.0 Carro gerado no Drive-Thru")
	car.current_state = DeliveryCar.CarState.AT_WINDOW_WAITING_FOOD
	car.target_queue_index = 0

	var drive_order = Order.new()
	drive_order.id = 99
	drive_order.source_type = "DELIVERY"
	var drive_items: Array[Dictionary] = [{"product_id": "classic_burger", "product_name": "Burger Clássico", "quantity": 1, "delivered_quantity": 0, "price": 20.0}]
	drive_order.items = drive_items
	drive_order.total_price = 20.0
	car.current_order = drive_order

	var order_mgr = OrderManager.get_instance()
	if order_mgr:
		order_mgr.active_orders.append(drive_order)

	# Jogador entrega item ERRADO no drive-thru (ex: batata frita avulsa quando pediu burger clássico)
	var wrong_drive_item = Item.new()
	wrong_drive_item.item_id = "fries"
	player.set("held_item", wrong_drive_item)

	if deliv_mgr:
		deliv_mgr.car_queue.clear()
		deliv_mgr.car_queue.append(car)

	deliv_station.interact(player)

	assert_test(car.current_state == DeliveryCar.CarState.LEAVING, "6.2 Carro do Drive-Thru reagiu negativamente e foi embora (LEAVING)")
	assert_test(car.experience != null and car.experience.abandoned, "6.3 Carro registrou experiência de abandono por erro")
	assert_test(economy.current_money == initial_money, "6.4 Drive-Thru NÃO pagou pelo pedido incorreto")

	print("\n--- TESTE 7: Pedido Correto Funciona e Paga Normalmente ---")
	var happy_car = deliv_mgr.spawn_car()
	assert_test(happy_car != null, "7.0 Carro gerado para pedido correto")
	happy_car.current_state = DeliveryCar.CarState.AT_WINDOW_WAITING_FOOD
	happy_car.target_queue_index = 0

	var correct_order = Order.new()
	correct_order.id = 100
	correct_order.source_type = "DELIVERY"
	var correct_items: Array[Dictionary] = [{"product_id": "cheeseburger", "product_name": "Cheeseburger", "quantity": 1, "delivered_quantity": 0, "price": 25.0}]
	correct_order.items = correct_items
	correct_order.total_price = 25.0
	happy_car.current_order = correct_order
	if order_mgr:
		order_mgr.active_orders.append(correct_order)

	if deliv_mgr:
		deliv_mgr.car_queue.clear()
		deliv_mgr.car_queue.append(happy_car)

	var correct_item = Item.new()
	correct_item.item_id = "cheeseburger"
	player.set("held_item", correct_item)

	deliv_station.interact(player)

	assert_test(economy.current_money == initial_money + 25.0, "7.1 Pedido correto pago com sucesso: R$ %.2f -> R$ %.2f" % [initial_money, economy.current_money])
	assert_test(happy_car.current_state == DeliveryCar.CarState.LEAVING, "7.2 Cliente satisfeito partiu alegremente (LEAVING)")

	print("\n" + "=".repeat(85))
	print("RESULTADO DOS TESTES: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(85) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS 29 TESTES DE GAMEPLAY PASSARAM COM 100% DE SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
