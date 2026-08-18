extends SceneTree

# ===========================================================================
# TESTE COMPLETO: MONTAGEM, EMBALAGEM, SACOLA E PEDIDO ERRADO VS DEMORA
# ===========================================================================

func _init() -> void:
	print("\n===========================================================================")
	print("TESTE: MONTAGEM, EMBALAGEM, SACOLA E PEDIDO ERRADO VS DEMORA")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# -----------------------------------------------------------------------
	# PARTE 1: Montagem do Hambúrguer e Embalagem na Caixinha (Clean Visual)
	# -----------------------------------------------------------------------
	print("--- TESTE 1: Montagem do Hambúrguer e Embalagem na Caixinha ---")

	var burger_assembly_scene = load("res://src/recipes/burger_assembly.tscn")
	var box_scene = load("res://src/items/burger_box.tscn")
	var packaged_scene = load("res://src/items/packaged_burger.tscn")

	total_tests += 1
	if burger_assembly_scene and box_scene and packaged_scene:
		print("  [PASS] Cenas de montagem, caixinha e packaged_burger carregadas")
		passed_tests += 1
	else:
		print("  [FAIL] Falha ao carregar cenas básicas")

	# Cria montagem de burger
	var base_item = Item.new()
	base_item.item_id = "bread_bottom"
	base_item.name = "BreadBottom"
	root.add_child(base_item)

	var assembly = burger_assembly_scene.instantiate() as BurgerAssembly
	base_item.add_child(assembly)
	assembly.base_bun = base_item
	assembly.state = BurgerAssembly.State.ASSEMBLING

	# Adiciona ingredientes
	var patty = Item.new()
	patty.item_id = "patty_cooked"
	assembly.add_ingredient(patty)

	var top_bun = Item.new()
	top_bun.item_id = "bread_top"
	assembly.close_burger(top_bun, Vector3.ZERO, 0.0)

	total_tests += 1
	if assembly.state == BurgerAssembly.State.CLOSED and assembly.can_package():
		print("  [PASS] Hambúrguer fechado com sucesso e pronto para embalar")
		passed_tests += 1
	else:
		print("  [FAIL] Hambúrguer não fechou ou não pode embalar")

	# Embala na caixinha
	var box = box_scene.instantiate() as BurgerBox
	root.add_child(box)

	var packaged_burger = assembly.package_burger(box)

	total_tests += 1
	if packaged_burger != null and packaged_burger is PackagedBurger:
		print("  [PASS] Hambúrguer embalado com sucesso na caixinha (PackagedBurger)")
		passed_tests += 1
	else:
		print("  [FAIL] Falha ao gerar PackagedBurger")

	# Verifica limpeza visual da caixinha (sem Label3D poluído ativo)
	total_tests += 1
	var label_node = packaged_burger.get_node_or_null("Label3D")
	var is_clean = (label_node == null or not label_node.visible)
	if is_clean:
		print("  [PASS] Caixinha limpa visualmente sem textos flutuantes excessivos")
		passed_tests += 1
	else:
		print("  [FAIL] Caixinha possui Label3D visível poluindo a cena")

	# -----------------------------------------------------------------------
	# PARTE 2: Regras da Sacola de Delivery (Sequência Estrita)
	# -----------------------------------------------------------------------
	print("\n--- TESTE 2: Regras Estritas da Sacola de Delivery ---")

	var delivery_bag_scene = load("res://src/items/delivery_bag.tscn")
	var bag = delivery_bag_scene.instantiate() as DeliveryBag
	root.add_child(bag)

	# 1. Tentar colocar hambúrguer SOLTO (sem caixinha) -> DEVE REJEITAR
	var loose_burger = Item.new()
	loose_burger.item_id = "bread_bottom"
	loose_burger.item_type = "burger"
	root.add_child(loose_burger)

	total_tests += 1
	if not bag.can_accept_item(loose_burger):
		print("  [PASS] Sacola REJEITA hambúrguer solto diretamente (Caixinha é obrigatória)")
		passed_tests += 1
	else:
		print("  [FAIL] Sacola aceitou hambúrguer solto incorretamente!")
	loose_burger.queue_free()

	# 2. Colocar caixinha com hambúrguer na sacola -> DEVE ACEITAR
	total_tests += 1
	if bag.can_accept_item(packaged_burger):
		bag.add_contained_item(packaged_burger)
		if bag.has_burger() and bag.burger_visual and bag.burger_visual.visible:
			print("  [PASS] Caixinha de hambúrguer inserida e VISÍVEL na sacola")
			passed_tests += 1
		else:
			print("  [FAIL] Caixinha não ficou visível na sacola")
	else:
		print("  [FAIL] Sacola rejeitou caixinha de hambúrguer válida!")

	# 3. Preparar Batata Frita e colocar na sacola
	var fries = FriesPack.new()
	root.add_child(fries)

	total_tests += 1
	if bag.can_accept_item(fries):
		bag.add_contained_item(fries)
		if bag.has_fries() and bag.fries_visual and bag.fries_visual.visible:
			print("  [PASS] Batata frita inserida e VISÍVEL na sacola")
			passed_tests += 1
		else:
			print("  [FAIL] Batata não ficou visível na sacola")
	else:
		print("  [FAIL] Sacola rejeitou batata frita!")

	# 4. Copo Vazio -> DEVE REJEITAR
	var drink_cup_scene = load("res://src/items/drink_cup.tscn")
	var empty_cup = drink_cup_scene.instantiate() as DrinkCup
	root.add_child(empty_cup)
	empty_cup.set_state(DrinkCup.State.EMPTY)

	total_tests += 1
	if not bag.can_accept_item(empty_cup):
		print("  [PASS] Sacola REJEITA copo de bebida vazio")
		passed_tests += 1
	else:
		print("  [FAIL] Sacola aceitou copo vazio!")

	# 5. Copo Cheio de Refrigerante -> DEVE ACEITAR diretamente
	empty_cup.set_flavor("soda_cola")
	empty_cup.set_state(DrinkCup.State.FILLED)

	total_tests += 1
	if bag.can_accept_item(empty_cup):
		bag.add_contained_item(empty_cup)
		if bag.has_drink() and bag.drink_visual and bag.drink_visual.visible:
			print("  [PASS] Copo cheio de refrigerante inserido e VISÍVEL na sacola")
			passed_tests += 1
		else:
			print("  [FAIL] Bebida não ficou visível na sacola")
	else:
		print("  [FAIL] Sacola rejeitou copo cheio!")

	# 6. Validação do conteúdo completo da sacola
	total_tests += 1
	var prods = bag.get_products()
	if prods.size() == 3 and bag.has_burger() and bag.has_fries() and bag.has_drink():
		print("  [PASS] Sacola completa com 3 itens físicos identificados")
		passed_tests += 1
	else:
		print("  [FAIL] Sacola não contém os 3 itens esperados")

	# -----------------------------------------------------------------------
	# PARTE 3: Entrega Correta no Drive-Thru
	# -----------------------------------------------------------------------
	print("\n--- TESTE 3: Entrega Correta de Sacola no Drive-Thru ---")

	var deliv_station_scene = load("res://src/stations/delivery_station.tscn")
	var deliv_station = deliv_station_scene.instantiate() as DeliveryStation
	root.add_child(deliv_station)

	var car_scene = load("res://src/environment/delivery_car.tscn")
	var car = car_scene.instantiate() as DeliveryCar
	root.add_child(car)
	car.current_state = 4 # AT_WINDOW_WAITING_FOOD

	var order = Order.new()
	order.id = 101
	order.source_type = "DELIVERY"
	order.add_item("burger", "Hambúrguer", 1, 20.0)
	order.add_item("fries", "Batata Frita", 1, 10.0)
	order.add_item("soda_cola", "Refrigerante", 1, 6.0)
	car.current_order = order

	# Mock player com a sacola
	var player = Node3D.new()
	player.set_script(load("res://src/player/player.gd"))
	root.add_child(player)
	player.held_item = bag

	# Interage para entregar a sacola
	deliv_station.interact(player)

	total_tests += 1
	if order.is_all_delivered() and order.state == Order.State.COMPLETED:
		print("  [PASS] Pedido de Delivery entregue e marcado como COMPLETED")
		passed_tests += 1
	else:
		print("  [FAIL] Pedido de Delivery não foi concluído corretamente")

	total_tests += 1
	if car.experience and car.experience.order_correct and not car.experience.abandoned:
		print("  [PASS] Carro do Drive-Thru recebeu com sucesso e gerou review positiva")
		passed_tests += 1
	else:
		print("  [FAIL] Carro não registrou sucesso")

	# -----------------------------------------------------------------------
	# PARTE 4: Cliente Presencial — Pedido Errado vs Desistência por Demora
	# -----------------------------------------------------------------------
	print("\n--- TESTE 4: Cliente Presencial (Salão) — Pedido Errado vs Demora ---")

	var cust_scene = load("res://src/customers/customer.tscn")
	var cust_wrong = cust_scene.instantiate() as Customer
	root.add_child(cust_wrong)
	cust_wrong.state = Customer.State.WAITING_FOR_FOOD

	var cust_order = Order.new()
	cust_order.id = 202
	cust_order.add_item("cheeseburger", "Cheeseburger", 1, 22.0)
	cust_wrong.current_order = cust_order

	# 1. Simula recebimento de PEDIDO ERRADO
	cust_wrong.on_order_wrong("Item incorreto servido na mesa!")

	total_tests += 1
	if cust_wrong.state == Customer.State.LEAVING:
		print("  [PASS] Cliente vai embora imediatamente ao receber pedido errado")
		passed_tests += 1
	else:
		print("  [FAIL] Cliente não transicionou para LEAVING")

	total_tests += 1
	if cust_wrong.experience and cust_wrong.experience.abandon_type == CustomerExperience.AbandonType.WRONG_ORDER:
		print("  [PASS] Telemetria registrada como WRONG_ORDER")
		passed_tests += 1
	else:
		print("  [FAIL] Telemetria não registrou WRONG_ORDER")

	total_tests += 1
	var cust_label_text = cust_wrong.label_3d.text if cust_wrong.label_3d else ""
	if "errado" in cust_label_text.to_lower():
		print("  [PASS] Mensagem visual do cliente expressa 'Pedido Errado': \"%s\"" % cust_label_text)
		passed_tests += 1
	else:
		print("  [FAIL] Mensagem visual não indica pedido errado: \"%s\"" % cust_label_text)

	# 2. Simula DESISTÊNCIA POR DEMORA em outro cliente
	var cust_timeout = cust_scene.instantiate() as Customer
	root.add_child(cust_timeout)
	cust_timeout.state = Customer.State.WAITING_FOR_FOOD
	cust_timeout.abandon_restaurant("Demora na entrega da comida")

	total_tests += 1
	if cust_timeout.experience and cust_timeout.experience.abandon_type == CustomerExperience.AbandonType.TIMEOUT:
		print("  [PASS] Telemetria de desistência por demora registrada como TIMEOUT")
		passed_tests += 1
	else:
		print("  [FAIL] Telemetria não registrou TIMEOUT")

	total_tests += 1
	var timeout_label_text = cust_timeout.label_3d.text if cust_timeout.label_3d else ""
	if "esperar" in timeout_label_text.to_lower() or "demor" in timeout_label_text.to_lower():
		print("  [PASS] Mensagem visual de demora expressa 'Cansei de esperar': \"%s\"" % timeout_label_text)
		passed_tests += 1
	else:
		print("  [FAIL] Mensagem visual de demora incorreta: \"%s\"" % timeout_label_text)

	total_tests += 1
	if cust_label_text != timeout_label_text:
		print("  [PASS] Reações de 'Pedido Errado' e 'Demora' são COMPLETAMENTE DIFERENTES")
		passed_tests += 1
	else:
		print("  [FAIL] Reações de pedido errado e demora são idênticas!")

	# -----------------------------------------------------------------------
	# PARTE 5: Drive-Thru — Pedido Errado vs Desistência por Demora
	# -----------------------------------------------------------------------
	print("\n--- TESTE 5: Drive-Thru — Pedido Errado vs Demora ---")

	var car_wrong = car_scene.instantiate() as DeliveryCar
	root.add_child(car_wrong)
	car_wrong.current_state = 4 # AT_WINDOW_WAITING_FOOD

	var wrong_order_dt = Order.new()
	wrong_order_dt.id = 303
	wrong_order_dt.source_type = "DELIVERY"
	wrong_order_dt.add_item("burger", "Hambúrguer", 1, 20.0)
	car_wrong.current_order = wrong_order_dt

	# Simula entrega de item errado no Drive-Thru
	car_wrong.on_order_wrong("Pedido incorreto entregue no Drive-Thru!")

	total_tests += 1
	if car_wrong.current_state == DeliveryCar.CarState.LEAVING:
		print("  [PASS] Carro vai embora imediatamente após pedido errado")
		passed_tests += 1
	else:
		print("  [FAIL] Carro não transicionou para LEAVING")

	total_tests += 1
	if car_wrong.experience and car_wrong.experience.abandon_type == CustomerExperience.AbandonType.WRONG_ORDER:
		print("  [PASS] Carro registrou abandon_type como WRONG_ORDER")
		passed_tests += 1
	else:
		print("  [FAIL] Carro não registrou WRONG_ORDER")

	total_tests += 1
	var car_wrong_label = car_wrong.status_label.text if car_wrong.status_label else ""
	if "não é o meu" in car_wrong_label.to_lower() or "errad" in car_wrong_label.to_lower():
		print("  [PASS] Mensagem do carro expressa 'Pedido Errado': \"%s\"" % car_wrong_label)
		passed_tests += 1
	else:
		print("  [FAIL] Mensagem do carro não indica pedido errado: \"%s\"" % car_wrong_label)

	# Simula desistência por tempo no Drive-Thru
	var car_timeout = car_scene.instantiate() as DeliveryCar
	root.add_child(car_timeout)
	car_timeout.current_state = 4
	car_timeout.abandon_drive_thru("Demora na fila do Drive-Thru")

	total_tests += 1
	if car_timeout.experience and car_timeout.experience.abandon_type == CustomerExperience.AbandonType.TIMEOUT:
		print("  [PASS] Carro por tempo registrou abandon_type como TIMEOUT")
		passed_tests += 1
	else:
		print("  [FAIL] Carro por tempo não registrou TIMEOUT")

	total_tests += 1
	var car_timeout_label = car_timeout.status_label.text if car_timeout.status_label else ""
	if "demorou" in car_timeout_label.to_lower() or "desisti" in car_timeout_label.to_lower():
		print("  [PASS] Mensagem do carro por tempo expressa 'Demorou demais': \"%s\"" % car_timeout_label)
		passed_tests += 1
	else:
		print("  [FAIL] Mensagem do carro por tempo incorreta: \"%s\"" % car_timeout_label)

	total_tests += 1
	if car_wrong_label != car_timeout_label:
		print("  [PASS] Reações de Pedido Errado e Demora no Drive-Thru são DIFERENCIADAS")
		passed_tests += 1
	else:
		print("  [FAIL] Reações no Drive-Thru são idênticas!")

	# -----------------------------------------------------------------------
	# RESULTADO FINAL
	# -----------------------------------------------------------------------
	print("\n===========================================================================")
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [passed_tests, total_tests - passed_tests])
	print("===========================================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! <<<\n")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<\n")
		quit(1)
