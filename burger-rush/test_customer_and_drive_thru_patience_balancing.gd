extends SceneTree

const CustomerMood = preload("res://src/customers/customer_mood.gd")
const CustomerExperience = preload("res://src/customers/customer_experience.gd")
const CustomerReview = preload("res://src/customers/customer_review.gd")
const ReputationManager = preload("res://src/customers/reputation_manager.gd")
const DeliveryCar = preload("res://src/environment/delivery_car.gd")

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DE BALANCEAMENTO DA PACIÊNCIA E INTEGRAÇÃO DO DRIVE-THRU")
	print("================================================================================")

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DA NOVA CURVA DE PACIÊNCIA PROGRESSIVA DO SALÃO
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação da Curva Progressiva de Humor (Cliente Padrão) ---")
	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var rep_mgr = main_scene.get_node("ReputationManager") as ReputationManager
	var order_mgr = main_scene.get_node("OrderManager")
	var deliv_queue_mgr = main_scene.get_node("DeliveryQueueManager") as DeliveryQueueManager
	assert(rep_mgr != null and order_mgr != null and deliv_queue_mgr != null, "Gerenciadores devem existir")
	rep_mgr.clear_all()

	var test_table = main_scene.get_node("Table1") as RestaurantTable
	test_table.release()

	var cust_test = load("res://src/customers/customer.tscn").instantiate() as Customer
	main_scene.add_child(cust_test)
	cust_test.archetype = Customer.Archetype.REGULAR
	cust_test.tolerance_order_wait = 80.0
	cust_test.tolerance_food_wait = 120.0
	cust_test.assign_seat(test_table, test_table.get_seat_position(1), 1)
	cust_test._complete_sitting_transition()

	# Fase 1: Carência inicial (15s de espera em 80s de tolerância = ~18% do tempo)
	for sec in range(15):
		cust_test._physics_process(1.0)
	print("  Após 15s de espera: Humor = %.1f (%s, %s)" % [cust_test.mood.current_mood, cust_test.mood.get_emoji(), cust_test.mood.get_label()])
	assert(cust_test.mood.current_mood >= 90.0, "Nos primeiros 15s o cliente deve permanecer feliz (humor >= 90)")

	# Fase 2: Espera aceitável (mais 25s = 40s total = 50% da tolerância)
	for sec in range(25):
		cust_test._physics_process(1.0)
	print("  Após 40s de espera: Humor = %.1f (%s, %s)" % [cust_test.mood.current_mood, cust_test.mood.get_emoji(), cust_test.mood.get_label()])
	assert(cust_test.mood.current_mood >= 65.0, "Com 40s de espera o cliente ainda deve estar satisfeito (humor >= 65)")

	# Fase 3: Impaciência (mais 25s = 65s total = ~81% da tolerância)
	for sec in range(25):
		cust_test._physics_process(1.0)
	print("  Após 65s de espera: Humor = %.1f (%s, %s)" % [cust_test.mood.current_mood, cust_test.mood.get_emoji(), cust_test.mood.get_label()])
	assert(cust_test.mood.current_mood < 65.0 and cust_test.mood.current_mood >= 25.0, "Com 65s o cliente deve estar impaciente")

	# Fase 4/5: Estouro de tolerância (mais 20s = 85s total > 80s de tolerância)
	for sec in range(20):
		cust_test._physics_process(1.0)
		if cust_test.state in [Customer.State.LEAVING, Customer.State.FINISHED]:
			break
	print("  Após 85s de espera: Estado = %s | Abandono = %s" % [Customer.State.keys()[cust_test.state], cust_test.experience.abandoned])
	assert(cust_test.experience.abandoned, "Cliente deve abandonar após ultrapassar a tolerância máxima real de 80s")
	assert(test_table.table_state == RestaurantTable.TableState.AVAILABLE, "Mesa deve ser liberada imediatamente")
	assert(rep_mgr.get_total_reviews() == 1, "Avaliação de abandono registrada no ReputationManager")
	print("  [PASS] Curva de paciência do salão validada: carência permissiva e abandono justo!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DO DRIVE-THRU (FLUXO COMPLETO DE SUCESSO)
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação do Drive-Thru: Atendimento e Avaliação de Sucesso ---")
	rep_mgr.clear_all()

	var car_happy = deliv_queue_mgr.spawn_car()
	assert(car_happy != null, "Carro deve ser spawnado")
	car_happy.set_target_position(DeliveryQueueManager.QUEUE_POSITIONS[0], 0)
	car_happy.current_state = DeliveryCar.CarState.AT_WINDOW_WAITING_ORDER

	# Carro aguarda 15s na janela (dentro da carência de 65s)
	for sec in range(15):
		car_happy._physics_process(1.0)
	assert(car_happy.mood.current_mood >= 90.0, "Motorista deve estar com humor alto nos primeiros 15s")

	# Anota pedido do Drive-Thru
	var dt_order = car_happy.take_order(null)
	assert(dt_order != null, "Pedido de drive-thru deve ser criado")
	assert(dt_order.source_type == "DELIVERY", "Origem do pedido deve ser DELIVERY")
	assert(car_happy.current_state == DeliveryCar.CarState.AT_WINDOW_WAITING_FOOD, "Carro deve aguardar entrega")

	# Entrega dos produtos (20s depois)
	for sec in range(20):
		car_happy._physics_process(1.0)
	car_happy.finish_and_leave()

	assert(car_happy.current_state == DeliveryCar.CarState.LEAVING, "Carro deve estar saindo")
	assert(rep_mgr.get_total_reviews() == 1, "Avaliação de Drive-Thru registrada")
	var dt_review = rep_mgr.get_latest_review()
	print("  Avaliação Drive-Thru Sucesso: %.1f★ (%s) | '%s'" % [dt_review.stars, dt_review.get_formatted_stars(), dt_review.comment])
	assert(dt_review.stars >= 4.5, "Atendimento ágil no drive-thru deve gerar >= 4.5 estrelas")
	assert("Drive-Thru" in dt_review.tags, "Tag 'Drive-Thru' deve estar presente")
	print("  [PASS] Drive-Thru com atendimento rápido gera avaliação excelente!")

	# -------------------------------------------------------------------------
	# 3. VALIDAÇÃO DO DRIVE-THRU (ABANDONO POR ESPERA EXCESSIVA)
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação do Drive-Thru: Abandono por Espera Excessiva ---")
	var car_abandon = deliv_queue_mgr.spawn_car()
	car_abandon.tolerance_order_wait = 10.0 # Tolerância de teste rápida
	car_abandon.set_target_position(DeliveryQueueManager.QUEUE_POSITIONS[0], 0)
	car_abandon.current_state = DeliveryCar.CarState.AT_WINDOW_WAITING_ORDER

	# Simula espera estourando a tolerância
	for sec in range(15):
		car_abandon._physics_process(1.0)
		if car_abandon.current_state == DeliveryCar.CarState.LEAVING:
			break

	assert(car_abandon.current_state == DeliveryCar.CarState.LEAVING, "Carro deve entrar em LEAVING após estourar tolerância")
	assert(car_abandon.experience.abandoned, "Carro deve registrar abandono")
	var dt_abandon_rev = rep_mgr.get_latest_review()
	print("  Avaliação Drive-Thru Abandono: %.1f★ | '%s'" % [dt_abandon_rev.stars, dt_abandon_rev.comment])
	assert(dt_abandon_rev.stars == 1.0, "Abandono no drive-thru deve gerar 1.0 estrela")
	assert(dt_abandon_rev.abandoned, "Flag abandoned deve ser true")
	print("  [PASS] Abandono no Drive-Thru gera avaliação negativa e libera a pista!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("BALANCEAMENTO E DRIVE-THRU 100% VALIDADOS E APROVADOS!")
	print("================================================================================")
	quit(0)
