extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DE PAGAMENTO DE GRUPOS E ENCERRAMENTO REAL ÀS 22:00")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	# -------------------------------------------------------------------------
	# 1. VERIFICAÇÃO DE INSTÂNCIA ÚNICA DO ORDERMANAGER
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação de Instância Única do OrderManager ---")
	var order_managers: Array[Node] = []
	for child in main_scene.get_children():
		if child is OrderManager or child.name == "OrderManager":
			order_managers.append(child)

	print("  Instâncias de OrderManager encontradas na cena raiz: %d" % order_managers.size())
	assert(order_managers.size() == 1, "Deve existir exatamente UMA instância de OrderManager na cena")
	print("  [PASS] Instância única do OrderManager validada sem duplicatas!")

	# -------------------------------------------------------------------------
	# 2. TESTE CENÁRIO 1: CLIENTE SOZINHO (FLUXO COMPLETO)
	# -------------------------------------------------------------------------
	print("\n--- 2. Cenário 1: Cliente Sozinho (Mesa -> Fila -> Caixa -> Saída) ---")
	var table1 = main_scene.get_node("Table1") as RestaurantTable
	assert(table1 != null, "Table1 deve existir")
	table1.release()

	var single_cust = load("res://src/customers/customer.tscn").instantiate() as Customer
	main_scene.add_child(single_cust)
	single_cust.assigned_table = table1
	table1.occupy(single_cust)
	table1.on_customer_seated(single_cust)
	assert(table1.table_state == RestaurantTable.TableState.OCCUPIED, "Mesa deve estar ocupada")

	var order_mgr = main_scene.get_node("OrderManager") as OrderManager
	single_cust.current_order = order_mgr.create_order(single_cust, "burger", 1, table1.table_id, "DINE_IN", 1)

	# Cliente termina de comer e vai para a fila
	single_cust.state = Customer.State.EATING
	single_cust._head_to_checkout_queue()

	# Mesa deve estar imediatamente liberada
	assert(table1.table_state == RestaurantTable.TableState.AVAILABLE, "Mesa deve ser liberada imediatamente ao levantar")
	assert(single_cust.state in [Customer.State.GOING_TO_QUEUE, Customer.State.IN_QUEUE], "Cliente deve estar a caminho da fila")

	var register = main_scene.get_node("CashRegister") as CashRegister
	assert(register.has_customers_in_queue(), "Caixa deve ter o cliente na fila")

	# Realiza o pagamento
	register.process_checkout()
	assert(single_cust.state == Customer.State.LEAVING, "Cliente deve estar saindo após pagar")
	assert(not register.has_customers_in_queue(), "Fila deve estar vazia após o checkout")
	print("  [PASS] Cenário 1 (Cliente Sozinho) validado com 100% de sucesso!")

	single_cust.queue_free()

	# -------------------------------------------------------------------------
	# 3. TESTE CENÁRIO 2: FAMÍLIA / GRUPO (1 MESA = 1 PAGADOR NA FILA)
	# -------------------------------------------------------------------------
	print("\n--- 3. Cenário 2: Família / Grupo (1 Mesa = 1 Pagador no Caixa) ---")
	var table2 = main_scene.get_node("Table2") as RestaurantTable
	table2.release()

	var adult1 = load("res://src/customers/customer.tscn").instantiate() as Customer
	var adult2 = load("res://src/customers/customer.tscn").instantiate() as Customer
	var child1 = load("res://src/customers/customer.tscn").instantiate() as Customer
	adult1.is_child = false
	adult2.is_child = false
	child1.is_child = true

	main_scene.add_child(adult1)
	main_scene.add_child(adult2)
	main_scene.add_child(child1)

	adult1.assigned_table = table2
	adult2.assigned_table = table2
	child1.assigned_table = table2
	table2.occupy(adult1)
	table2.occupy(adult2)
	table2.occupy(child1)
	table2.on_customer_seated(adult1)

	var group_order = order_mgr.create_group_order(adult1, 3, table2.table_id, "DINE_IN")
	adult1.current_order = group_order
	adult2.current_order = group_order
	child1.current_order = group_order

	print("  Grupo de 3 sentados na Mesa 2. Pedido total: R$ %.2f" % group_order.total_price)

	# Grupo termina de comer e vai para o caixa
	adult1.state = Customer.State.EATING
	adult1._head_to_checkout_queue()

	# Mesa deve estar disponível imediatamente
	assert(table2.table_state == RestaurantTable.TableState.AVAILABLE, "Mesa deve estar liberada para novos clientes")

	# Apenas 1 cliente (o pagador) deve estar na fila do caixa
	print("  Clientes na fila do caixa: %d" % register.queue_customers.size())
	assert(register.queue_customers.size() == 1, "Exatamente 1 membro do grupo deve entrar na fila do caixa")
	assert(register.queue_customers[0] == adult1, "O pagador eleito deve ser o Adulto 1")

	# Os demais membros devem estar em WAITING_FOR_GROUP_PAYMENT
	assert(adult2.state == Customer.State.WAITING_FOR_GROUP_PAYMENT, "Adulto 2 deve estar aguardando pagamento do grupo")
	assert(child1.state == Customer.State.WAITING_FOR_GROUP_PAYMENT, "Criança deve estar aguardando pagamento do grupo")
	print("  Acompanhantes em estado de espera: OK")

	# Pagamento é realizado no caixa
	var balance_before = register.register_balance
	register.process_checkout()
	var balance_after = register.register_balance
	print("  Valor cobrado: R$ %.2f" % (balance_after - balance_before))
	assert(balance_after - balance_before == group_order.total_price, "Deve cobrar o valor total da mesa")

	# Após o pagamento, todos os membros do grupo devem estar saindo juntos
	assert(adult1.state == Customer.State.LEAVING, "Pagador deve estar saindo")
	assert(adult2.state == Customer.State.LEAVING, "Adulto 2 deve estar saindo junto")
	assert(child1.state == Customer.State.LEAVING, "Criança deve estar saindo junto")
	assert(not register.has_customers_in_queue(), "Fila deve estar vazia após checkout da família")
	print("  [PASS] Cenário 2 (Família com 1 Pagador) validado com 100% de sucesso!")

	adult1.queue_free()
	adult2.queue_free()
	child1.queue_free()

	# -------------------------------------------------------------------------
	# 4. TESTE CENÁRIO 3 E 4: ENCERRAMENTO ÀS 22:00
	# -------------------------------------------------------------------------
	print("\n--- 4. Cenário 3 & 4: Encerramento do Expediente às 22:00 ---")
	var clock = main_scene.get_node("GameClock") as GameClock
	clock.open_restaurant()
	assert(clock.state == GameClock.State.OPEN, "Restaurante deve estar OPEN")

	# Simula 22:00 com 1 cliente ativo
	var late_cust = load("res://src/customers/customer.tscn").instantiate() as Customer
	main_scene.add_child(late_cust)
	late_cust.state = Customer.State.EATING
	var late_order = order_mgr.create_order(late_cust, "burger", 1, 1, "DINE_IN", 1)
	late_cust.current_order = late_order

	# Relógio bate 22:00
	clock.current_hour = 22
	clock.current_minute = 0
	clock._advance_minute()

	print("  Estado às 22:00 com cliente dentro: %s" % GameClock.State.keys()[clock.state])
	assert(clock.state == GameClock.State.CLOSING, "Às 22:00 o restaurante deve estar em CLOSING (não CLOSED!)")
	assert(not clock.can_finish_day(), "can_finish_day deve ser falso enquanto houver cliente dentro")

	# Cliente finaliza, paga e sai
	late_cust.state = Customer.State.FINISHED
	late_order.state = Order.State.COMPLETED
	order_mgr.active_orders.erase(late_order)

	# Agora sem clientes, can_finish_day deve ser true
	assert(clock.can_finish_day(), "can_finish_day deve ser verdadeiro quando não há mais clientes")
	clock._process(0.1)
	assert(clock.state == GameClock.State.CLOSED, "Restaurante deve fechar o dia automaticamente após todos saírem")
	print("  [PASS] Cenário 3 & 4 (Encerramento Real às 22:00) validado com 100% de sucesso!")

	late_cust.queue_free()
	main_scene.queue_free()

	print("\n================================================================================")
	print("TODAS AS CORREÇÕES E REGRAS DE NEGÓCIO IMPLEMENTADAS E VALIDADAS COM SUCESSO!")
	print("================================================================================")
	quit(0)
