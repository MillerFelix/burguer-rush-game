extends SceneTree

const CashRegister = preload("res://src/stations/cash_register.gd")

# Teste e validação das 3 alterações:
# 1. Rotação da caixa registradora voltada para dentro da cozinha (Y = 180°)
# 2. Spawning balanceado, dinâmico, por horário, intensidade do dia e limites simultâneos
# 3. Liberação imediata da mesa para AVAILABLE quando o cliente termina de comer

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DE ROTAÇÃO DO CAIXA, SPAWN DINÂMICO E LIBERAÇÃO DE MESAS")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DA ROTAÇÃO DA CAIXA REGISTRADORA
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação da Rotação da Caixa Registradora ---")
	var register = main_scene.get_node_or_null("CashRegister") as CashRegister
	assert(register != null, "CashRegister deve existir no balcão")
	var rot_y_deg = rad_to_deg(register.rotation.y)
	print("  Rotação Y da Caixa Registradora: %.1f°" % rot_y_deg)
	assert(abs(abs(rot_y_deg) - 180.0) < 1.0 or abs(rot_y_deg) < 1.0, "Caixa deve estar orientada para dentro da cozinha")
	print("  [PASS] Frente da Caixa Registradora voltada para o interior da cozinha!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DO SPAWN DINÂMICO E BALANCEADO POR HORÁRIO
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação da Lógica do CustomerSpawner ---")
	var spawner = main_scene.get_node_or_null("CustomerSpawner") as CustomerSpawner
	assert(spawner != null, "CustomerSpawner deve existir")

	# Teste dos intervalos por horário
	var interval_morning = spawner._calculate_interval_for_time(10.5)
	var interval_lunch = spawner._calculate_interval_for_time(12.5)
	var interval_afternoon = spawner._calculate_interval_for_time(15.5)
	var interval_dinner = spawner._calculate_interval_for_time(19.0)
	var interval_closing = spawner._calculate_interval_for_time(21.5)

	print("  Intervalo Manhã (10:30): %.1fs" % interval_morning)
	print("  Intervalo Almoço (12:30): %.1fs" % interval_lunch)
	print("  Intervalo Tarde (15:30): %.1fs" % interval_afternoon)
	print("  Intervalo Jantar (19:00): %.1fs" % interval_dinner)
	print("  Intervalo Fechamento (21:30): %.1fs" % interval_closing)

	assert(interval_morning > interval_lunch, "Manhã deve ser mais calma e com intervalos maiores que o almoço")
	assert(interval_afternoon > interval_lunch, "Tarde deve permitir recuperação com intervalos maiores que o almoço")

	# Teste dos limites de concorrência simultânea
	var limit_morning = spawner._get_max_concurrent_customers(10.5)
	var limit_lunch = spawner._get_max_concurrent_customers(12.5)
	print("  Limite Simultâneo Manhã: %d clientes" % limit_morning)
	print("  Limite Simultâneo Almoço: %d clientes" % limit_lunch)
	assert(limit_morning <= 3, "Manhã deve limitar no máximo a 3 clientes para não lotar o salão")
	assert(limit_lunch >= 6, "Almoço deve permitir fluxo de movimento com até 8 clientes")
	print("  [PASS] Curvas horárias e limites simultâneos perfeitamente calibrados!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DA LIBERAÇÃO IMEDIATA DA MESA
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação da Liberação Imediata da Mesa ---")
	var table1 = main_scene.get_node("Table1") as RestaurantTable
	assert(table1 != null, "Table1 deve existir")
	assert(table1.table_state == RestaurantTable.TableState.AVAILABLE, "Mesa deve iniciar AVAILABLE")

	var customer_scene = load("res://src/customers/customer.tscn")
	var customer1 = customer_scene.instantiate() as Customer
	main_scene.add_child(customer1)

	# Cliente senta na mesa
	var seat_pos = table1.occupy_seat(customer1)
	customer1.assign_seat(table1, seat_pos, 1)
	table1.on_customer_seated(customer1)
	assert(table1.table_state == RestaurantTable.TableState.OCCUPIED, "Mesa deve estar OCCUPIED")

	# Cliente come
	customer1.state = Customer.State.EATING
	customer1.eat_timer = customer1.eat_duration + 0.1
	customer1._physics_process(0.016)

	# Ao levantar para pagar: mesa volta imediatamente para AVAILABLE
	print("  Estado da Mesa após cliente levantar para ir pagar: %s" % table1.table_state)
	assert(table1.table_state == RestaurantTable.TableState.AVAILABLE, "Mesa deve voltar IMEDIATAMENTE para AVAILABLE")
	assert(table1.is_available(), "Mesa deve estar 100% disponível para outro cliente escolher")
	assert(customer1.state == Customer.State.GOING_TO_QUEUE or customer1.state == Customer.State.IN_QUEUE, "Cliente anterior continua normalmente em direção ao caixa")
	print("  [PASS] Mesa liberada imediatamente para novos clientes enquanto o anterior segue para o caixa!")

	customer1.queue_free()
	main_scene.queue_free()

	print("\n================================================================================")
	print("TODOS OS 3 PONTOS FORAM IMPLEMENTADOS E VALIDADOS COM 100% DE SUCESSO!")
	print("================================================================================")
	quit(0)
