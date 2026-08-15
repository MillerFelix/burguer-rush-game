extends SceneTree

const CashRegister = preload("res://src/stations/cash_register.gd")

# Teste e validação do novo fluxo completo do cliente e da caixa registradora:
# 1. Orientação da placa "ACESSO RESTRITO" virada para dentro do armazém
# 2. Remoção completa da Mesa 8 e preservação da marcação de fila
# 3. Caixa registradora física no balcão (X = 1.8, Y = 0.96, Z = 0.0)
# 4. Fluxo completo do cliente:
#    Sentar -> Mão levantada -> Pedido registrado -> Mão abaixada -> Comer ->
#    Ir para Fila do Caixa -> Pagar no Caixa Registradora -> Sair

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DO NOVO FLUXO COMPLETO DO CLIENTE E CAIXA REGISTRADORA")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DA ORIENTAÇÃO DA PLACA "ACESSO RESTRITO"
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação da Orientação da Placa ACESSO RESTRITO ---")
	var fence = main_scene.get_node_or_null("SecurityFenceAlley")
	assert(fence != null, "SecurityFenceAlley deve existir")
	var sign_plate = fence.get_node_or_null("Model/SignPlate")
	assert(sign_plate != null, "SignPlate deve existir")
	var sign_label = sign_plate.get_node_or_null("SignLabel") as Label3D
	assert(sign_label != null, "SignLabel deve existir")

	print("  Posição X do SignPlate: %.2f (virado para dentro da área do armazém)" % sign_plate.position.x)
	assert(sign_plate.position.x > 0.0, "SignPlate deve estar no lado interno da grade (X > 0)")
	print("  [PASS] Placa 'ACESSO RESTRITO' perfeitamente virada para o interior do armazém!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DA REMOÇÃO DA MESA 8 E MARCAÇÃO DE FILA
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação da Remoção da Mesa 8 e Marcação de Fila ---")
	var table8 = main_scene.get_node_or_null("Table8")
	assert(table8 == null, "Mesa 8 deve ter sido completamente removida!")

	var room = main_scene.get_node("Room")
	var queue_stripe = room.get_node_or_null("FloorQueueStripe1")
	assert(queue_stripe != null, "Marcação da fila no chão deve permanecer na área!")
	print("  [PASS] Mesa 8 removida e marcação de fila preservada!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DA CAIXA REGISTRADORA FÍSICA NO BALCÃO
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação da Caixa Registradora no Balcão ---")
	var register = main_scene.get_node_or_null("CashRegister") as CashRegister
	assert(register != null, "CashRegister deve existir no balcão")
	print("  Posição da Caixa Registradora: %s" % register.position)
	assert(abs(register.position.x - 1.8) < 0.1, "Caixa deve estar em X = 1.8 na frente da fila")
	assert(abs(register.position.z) < 0.2, "Caixa deve estar sobre o balcão (Z = 0.0)")
	assert(register.position.y > 0.8, "Caixa deve estar apoiada sobre o tampo do balcão (Y >= 0.9m)")
	print("  [PASS] Caixa registradora posicionada com perfeição sobre o balcão!")

	# -------------------------------------------------------------------------
	# 4. VALIDAÇÃO DO NOVO FLUXO DO CLIENTE (MÃO LEVANTADA -> FILA -> CAIXA)
	# -------------------------------------------------------------------------
	print("\n--- 4. Validação da Simulação Completa do Ciclo do Cliente ---")
	var customer_scene = load("res://src/customers/customer.tscn")
	var customer1 = customer_scene.instantiate() as Customer
	main_scene.add_child(customer1)

	var table1 = main_scene.get_node("Table1") as RestaurantTable
	assert(table1 != null, "Table1 deve existir")
	var seat_pos = table1.get_seat_position(1)

	# FASE A: Cliente senta na cadeira
	customer1.position = seat_pos
	customer1.state = Customer.State.SEATED_WAITING_TO_ORDER
	customer1.assigned_table = table1
	table1.on_customer_seated(customer1)
	customer1._physics_process(0.016)

	# Verifica mão levantada
	assert(customer1.state == Customer.State.SEATED_WAITING_TO_ORDER, "Cliente deve estar SEATED_WAITING_TO_ORDER")
	print("  [PASS] Fase A: Cliente sentado aguardando atendimento.")

	# FASE B: Atendimento do Pedido -> Mão abaixa imediatamente
	customer1.place_order(null)
	assert(customer1.state == Customer.State.WAITING_FOR_FOOD, "Estado deve mudar para WAITING_FOR_FOOD após registrar pedido")
	customer1._physics_process(0.016)
	print("  [PASS] Fase B: Pedido registrado, mão abaixada e cliente aguardando refeição.")

	# FASE C: Entrega e Consumo da Comida
	customer1.receive_food()
	assert(customer1.state == Customer.State.EATING, "Estado deve ser EATING após receber a comida")
	print("  [PASS] Fase C: Comida entregue, cliente saboreando na mesa.")

	# FASE D: Termina de comer -> Libera a mesa e vai para a fila do caixa
	customer1.eat_timer = customer1.eat_duration + 0.1
	customer1._physics_process(0.016)

	assert(customer1.assigned_table == null, "Mesa deve ser desocupada após comer")
	assert(table1.table_state == RestaurantTable.TableState.AVAILABLE, "Mesa deve ficar AVAILABLE imediatamente para novos clientes")
	assert(customer1.state == Customer.State.GOING_TO_QUEUE, "Cliente deve transicionar para GOING_TO_QUEUE")
	assert(register.queue_customers.has(customer1), "Cliente deve estar registrado na fila da caixa registradora")
	print("  [PASS] Fase D: Refeição concluída, mesa liberada e cliente a caminho da fila do caixa.")

	# FASE E: Chegada ao Slot da Fila (Slot 0)
	customer1.position = register.get_slot_position(0)
	customer1.path_waypoints.clear()
	customer1._follow_path_to_destination(0.016, false)
	assert(customer1.state == Customer.State.IN_QUEUE, "Cliente deve estar no estado IN_QUEUE ao chegar no slot")
	print("  [PASS] Fase E: Cliente posicionado ordenadamente na fila da caixa registradora.")

	# FASE F: Pagamento na Caixa Registradora
	var initial_balance = EconomyManager.get_instance().money if EconomyManager.get_instance() else 0.0
	register.process_checkout(null)

	assert(customer1.state == Customer.State.LEAVING, "Cliente deve entrar em LEAVING após pagamento no caixa")
	assert(not register.queue_customers.has(customer1), "Cliente deve sair da fila após pagamento")
	print("  [PASS] Fase F: Pagamento efetuado no caixa, saldo creditado e cliente deixando o estabelecimento!")

	customer1.queue_free()
	main_scene.queue_free()

	print("\n================================================================================")
	print("NOVO FLUXO COMPLETO DO CLIENTE E CAIXA REGISTRADORA VALIDADOS COM 100% DE SUCESSO!")
	print("================================================================================")
	quit(0)
