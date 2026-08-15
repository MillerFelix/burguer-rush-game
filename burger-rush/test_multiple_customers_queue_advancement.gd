extends SceneTree

const CashRegister = preload("res://src/stations/cash_register.gd")

# Teste e validação de fila com múltiplos clientes e avanço ordenado:
# - Múltiplos clientes entram na fila sequencialmente
# - Posicionamento ordenado em slots (sem sobreposição)
# - Pagamento no caixa libera o cliente da frente e avança toda a fila
# - Limpeza e esvaziamento correto da fila

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DE FILA COM MÚLTIPLOS CLIENTES E AVANÇO AUTOMÁTICO")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var register = main_scene.get_node_or_null("CashRegister") as CashRegister
	assert(register != null, "CashRegister deve existir no balcão")

	var customer_scene = load("res://src/customers/customer.tscn")
	var customers: Array[Customer] = []

	print("\n--- 1. Entrada de 3 Clientes na Fila ---")
	for i in range(3):
		var c = customer_scene.instantiate() as Customer
		main_scene.add_child(c)
		c.customer_id = 100 + i
		c.state = Customer.State.EATING
		c.eat_timer = c.eat_duration + 0.1
		c._physics_process(0.016)
		customers.append(c)

	assert(register.queue_customers.size() == 3, "Devem existir exatamente 3 clientes na fila")

	# Verifica slots
	for i in range(3):
		var expected_slot = register.get_slot_position(i)
		var c = register.queue_customers[i]
		print("  Cliente #%d -> Alvo da Fila: %s" % [c.customer_id, c.target_position])
		assert((c.target_position - expected_slot).length() < 0.05, "Cliente #%d deve estar mirando no slot %d" % [c.customer_id, i])

	print("  [PASS] 3 clientes posicionados em slots separados sem sobreposição!")

	print("\n--- 2. Atendimento do Cliente 1 e Avanço da Fila ---")
	var cust1 = register.get_first_in_queue()
	assert(cust1 == customers[0], "Primeiro da fila deve ser o Cliente 1")

	# Posiciona cliente no slot 0 e atende
	cust1.position = register.get_slot_position(0)
	cust1.state = Customer.State.IN_QUEUE
	register.process_checkout(null)

	assert(cust1.state == Customer.State.LEAVING, "Cliente 1 deve estar saindo")
	assert(register.queue_customers.size() == 2, "Fila deve agora conter 2 clientes")
	assert(register.get_first_in_queue() == customers[1], "Cliente 2 deve agora ser o primeiro da fila")

	var new_first = register.get_first_in_queue()
	var expected_slot0 = register.get_slot_position(0)
	print("  Novo primeiro da fila: Cliente #%d -> Novo alvo: %s" % [new_first.customer_id, new_first.target_position])
	assert((new_first.target_position - expected_slot0).length() < 0.05, "Cliente 2 deve ter avançado para o slot 0")

	print("  [PASS] Fila avançou automaticamente com sucesso!")

	print("\n--- 3. Atendimento dos Clientes Restantes ---")
	# Atende cliente 2
	new_first.position = register.get_slot_position(0)
	new_first.state = Customer.State.IN_QUEUE
	register.process_checkout(null)
	assert(register.queue_customers.size() == 1, "Fila deve agora conter 1 cliente")

	# Atende cliente 3
	var last_cust = register.get_first_in_queue()
	assert(last_cust == customers[2], "Cliente 3 deve ser o último")
	last_cust.position = register.get_slot_position(0)
	last_cust.state = Customer.State.IN_QUEUE
	register.process_checkout(null)

	assert(register.queue_customers.is_empty(), "Fila deve estar completamente vazia")
	print("  [PASS] Todos os clientes atendidos e fila 100% livre!")

	for c in customers:
		c.queue_free()
	main_scene.queue_free()

	print("\n================================================================================")
	print("TESTE DE MULTI-CLIENTES E AVANÇO DA FILA APROVADO COM SUCESSO!")
	print("================================================================================")
	quit(0)
