extends SceneTree

const CustomerMood = preload("res://src/customers/customer_mood.gd")
const CustomerExperience = preload("res://src/customers/customer_experience.gd")
const CustomerReview = preload("res://src/customers/customer_review.gd")
const ReputationManager = preload("res://src/customers/reputation_manager.gd")

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DO SISTEMA DE HUMOR, EXPERIÊNCIA E AVALIAÇÃO DOS CLIENTES")
	print("================================================================================")

	# -------------------------------------------------------------------------
	# 1. TESTE DA CLASSE CustomerMood
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação de Estados e Dinâmica do CustomerMood ---")
	var mood = CustomerMood.new(100.0, 1.0)
	assert(mood.get_state() == CustomerMood.MoodState.VERY_HAPPY, "100 de humor deve ser VERY_HAPPY")
	assert(mood.get_emoji() == "😄", "Emoji inicial deve ser 😄")
	assert(mood.get_label() == "Muito Feliz", "Label deve ser Muito Feliz")

	mood.decay(20.0) # 80.0
	assert(mood.get_state() == CustomerMood.MoodState.HAPPY, "80 de humor deve ser HAPPY")
	assert(mood.get_emoji() == "😊", "Emoji deve ser 😊")

	mood.decay(20.0) # 60.0
	assert(mood.get_state() == CustomerMood.MoodState.SATISFIED, "60 de humor deve ser SATISFIED")
	assert(mood.get_emoji() == "🙂", "Emoji deve ser 🙂")

	mood.decay(15.0) # 45.0
	assert(mood.get_state() == CustomerMood.MoodState.NEUTRAL, "45 de humor deve ser NEUTRAL")
	assert(mood.get_emoji() == "😐", "Emoji deve ser 😐")

	mood.decay(15.0) # 30.0
	assert(mood.get_state() == CustomerMood.MoodState.IMPATIENT, "30 de humor deve ser IMPATIENT")
	assert(mood.get_emoji() == "😒", "Emoji deve ser 😒")

	mood.decay(12.0) # 18.0
	assert(mood.get_state() == CustomerMood.MoodState.ANGRY, "18 de humor deve ser ANGRY")
	assert(mood.get_emoji() == "😠", "Emoji deve ser 😠")
	assert(mood.is_critical(), "18 de humor deve ser crítico")

	mood.decay(10.0) # 8.0
	assert(mood.get_state() == CustomerMood.MoodState.VERY_ANGRY, "8 de humor deve ser VERY_ANGRY")
	assert(mood.get_emoji() == "😡", "Emoji deve ser 😡")

	mood.decay(8.0) # 0.0
	assert(mood.get_state() == CustomerMood.MoodState.EXTREMELY_FRUSTRATED, "0 de humor deve ser EXTREMELY_FRUSTRATED")
	assert(mood.get_emoji() == "🤬", "Emoji deve ser 🤬")
	assert(mood.is_exhausted(), "0 de humor deve ser exhausted")

	# Teste de Boost de Humor
	mood.boost(60.0)
	assert(mood.current_mood == 60.0, "Boost deve recuperar humor para 60.0")
	assert(mood.get_state() == CustomerMood.MoodState.SATISFIED, "Humor recuperado deve ser SATISFIED")

	# Teste de Multiplicador de Decaimento por Arquétipo
	var impatient_mood = CustomerMood.new(100.0, 2.0)
	impatient_mood.decay(10.0) # Decai 20.0
	assert(impatient_mood.current_mood == 80.0, "Cliente apressado deve decair com multiplicador 2.0x")
	print("  [PASS] CustomerMood: Estados emocionais, emojis, cores e recuperação validados!")

	# -------------------------------------------------------------------------
	# 2. TESTE DA TELEMETRIA E GERAÇÃO DE AVALIAÇÕES (CustomerExperience)
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação da Telemetria e Cálculo de Avaliações (CustomerExperience) ---")

	# Cenário A: Experiência Perfeita (5 Estrelas)
	var exp_perfect = CustomerExperience.new(1, "Padrão", 100.0)
	exp_perfect.wait_time_to_order = 8.0
	exp_perfect.wait_time_for_food = 15.0
	exp_perfect.wait_time_checkout = 5.0
	exp_perfect.order_correct = true
	exp_perfect.food_quality = 1.0
	exp_perfect.table_cleanliness = 1.0
	exp_perfect.final_mood = 95.0
	var rev_perfect = exp_perfect.generate_review(1, "12:30")
	print("  Avaliação Perfeita: %.1f Estrelas (%s) | '%s'" % [rev_perfect.stars, rev_perfect.get_formatted_stars(), rev_perfect.comment])
	assert(rev_perfect.stars >= 4.8, "Experiência perfeita deve gerar ~5 estrelas")
	assert("Atendimento Rápido" in rev_perfect.tags or "Comida Excelente" in rev_perfect.tags, "Tags de sucesso devem existir")

	# Cenário B: Atendimento com Demora Real
	var exp_slow = CustomerExperience.new(2, "Padrão", 100.0)
	exp_slow.wait_time_to_order = 50.0
	exp_slow.wait_time_for_food = 75.0
	exp_slow.order_correct = true
	exp_slow.food_quality = 1.0
	exp_slow.table_cleanliness = 1.0
	exp_slow.final_mood = 60.0
	var rev_slow = exp_slow.generate_review(1, "13:00")
	print("  Avaliação com Demora: %.1f Estrelas (%s) | '%s'" % [rev_slow.stars, rev_slow.get_formatted_stars(), rev_slow.comment])
	assert(rev_slow.stars >= 3.5 and rev_slow.stars <= 4.5, "Comida boa com demora deve ficar entre 3.5 e 4.5 estrelas")
	assert("Demora" in rev_slow.tags, "Tag 'Demora' deve ser atribuída")

	# Cenário C: Mesa Suja
	var exp_dirty = CustomerExperience.new(3, "Crítico", 100.0)
	exp_dirty.wait_time_to_order = 10.0
	exp_dirty.wait_time_for_food = 20.0
	exp_dirty.table_cleanliness = 0.2
	exp_dirty.final_mood = 50.0
	var rev_dirty = exp_dirty.generate_review(1, "13:30")
	print("  Avaliação Mesa Suja: %.1f Estrelas (%s) | '%s'" % [rev_dirty.stars, rev_dirty.get_formatted_stars(), rev_dirty.comment])
	assert(rev_dirty.cleanliness_stars <= 2.0, "Limpeza de mesa suja deve pontuar baixo")
	assert("Mesa Suja" in rev_dirty.tags, "Tag 'Mesa Suja' deve ser atribuída")

	# Cenário D: Pedido Incorreto
	var exp_wrong = CustomerExperience.new(4, "Padrão", 100.0)
	exp_wrong.order_correct = false
	exp_wrong.final_mood = 30.0
	var rev_wrong = exp_wrong.generate_review(1, "14:00")
	print("  Avaliação Pedido Incorreto: %.1f Estrelas (%s) | '%s'" % [rev_wrong.stars, rev_wrong.get_formatted_stars(), rev_wrong.comment])
	assert(rev_wrong.food_stars <= 2.0, "Pedido incorreto deve derrubar a nota de comida")
	assert("Pedido Incorreto" in rev_wrong.tags, "Tag 'Pedido Incorreto' deve ser atribuída")

	# Cenário E: Abandono por Espera Excessiva (1 Estrela)
	var exp_abandon = CustomerExperience.new(5, "Apressado", 100.0)
	exp_abandon.abandoned = true
	exp_abandon.abandon_reason = "Demora no atendimento da mesa"
	exp_abandon.final_mood = 0.0
	var rev_abandon = exp_abandon.generate_review(1, "14:30")
	print("  Avaliação de Abandono: %.1f Estrelas (%s) | '%s'" % [rev_abandon.stars, rev_abandon.get_formatted_stars(), rev_abandon.comment])
	assert(rev_abandon.stars == 1.0, "Abandono deve gerar 1.0 estrela")
	assert(rev_abandon.abandoned, "Flag abandoned deve ser true")
	assert("Cancelei" in rev_abandon.comment or "Desisti" in rev_abandon.comment or "esperando" in rev_abandon.comment or "atendeu" in rev_abandon.comment, "Comentário de abandono deve ser contextualizado")
	print("  [PASS] CustomerExperience: Telemetria, notas ponderadas e comentários contextuais validados!")

	# -------------------------------------------------------------------------
	# 3. TESTE DE INTEGRAÇÃO COM A CENA PRINCIPAL (GAMEPLAY)
	# -------------------------------------------------------------------------
	print("\n--- 3. Validação de Integração de Gameplay do Cliente e Abandono ---")
	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var table_mgr = main_scene.get_node("TableManager")
	var order_mgr = main_scene.get_node("OrderManager")
	var rep_mgr = main_scene.get_node("ReputationManager") as ReputationManager
	assert(table_mgr != null and order_mgr != null and rep_mgr != null, "Gerenciadores devem existir")
	rep_mgr.clear_all()

	# Subcenário A: Abandono Real de Cliente Impaciente na Mesa
	var test_table = main_scene.get_node("Table1") as RestaurantTable
	assert(test_table != null, "Table1 deve existir na cena")
	test_table.release()

	var cust_abandon = load("res://src/customers/customer.tscn").instantiate() as Customer
	main_scene.add_child(cust_abandon)
	cust_abandon.archetype = Customer.Archetype.IMPATIENT
	cust_abandon.tolerance_order_wait = 10.0
	cust_abandon.assign_seat(test_table, test_table.get_seat_position(1), 1)

	# Simula cliente sentado aguardando atendimento
	cust_abandon._complete_sitting_transition()
	assert(test_table.table_state == RestaurantTable.TableState.OCCUPIED, "Mesa deve estar OCCUPIED")

	# Simula passagem de tempo acima da tolerância
	for sec in range(20):
		cust_abandon._physics_process(1.0)
		print("  sec %d: state=%s, wait=%.1f, mood=%.1f" % [sec, Customer.State.keys()[cust_abandon.state], cust_abandon.experience.wait_time_to_order, cust_abandon.mood.current_mood])
		if cust_abandon.state in [Customer.State.LEAVING, Customer.State.FINISHED]:
			break

	assert(cust_abandon.state in [Customer.State.LEAVING, Customer.State.FINISHED], "Cliente deve transitar para LEAVING/FINISHED após estourar tolerância")
	assert(cust_abandon.experience.abandoned, "Cliente deve registrar experiência de abandono")
	assert(test_table.table_state == RestaurantTable.TableState.AVAILABLE, "Mesa deve ser liberada imediatamente ao abandonar")
	assert(rep_mgr.get_total_reviews() == 1, "Avaliação de 1 estrela deve ser registrada no ReputationManager")
	assert(rep_mgr.get_latest_review().stars == 1.0, "Nota registrada deve ser 1.0")
	print("  [PASS] Abandono de cliente por espera excessiva limpa a mesa e registra avaliação negativa com sucesso!")

	# Subcenário B: Cliente Atendido com Sucesso e Fluxo Completo
	var cust_happy = load("res://src/customers/customer.tscn").instantiate() as Customer
	main_scene.add_child(cust_happy)
	cust_happy.archetype = Customer.Archetype.PATIENT
	cust_happy.assign_seat(test_table, test_table.get_seat_position(1), 1)
	cust_happy._complete_sitting_transition()

	# Atendimento rápido
	cust_happy._physics_process(2.0)
	cust_happy.place_order(null)
	assert(cust_happy.state == Customer.State.WAITING_FOR_FOOD, "Cliente deve estar WAITING_FOR_FOOD")

	# Entrega da comida rápida
	cust_happy._physics_process(3.0)
	cust_happy.receive_food()
	assert(cust_happy.state == Customer.State.EATING, "Cliente deve estar EATING")

	# Finalização e pagamento
	cust_happy._physics_process(cust_happy.eat_duration + 0.5)
	cust_happy.on_payment_completed()
	assert(cust_happy.state == Customer.State.LEAVING, "Cliente deve estar LEAVING após pagamento")
	assert(rep_mgr.get_total_reviews() == 2, "Segunda avaliação deve ser registrada")
	assert(rep_mgr.get_latest_review().stars >= 4.5, "Cliente com atendimento rápido deve deixar avaliação alta (>= 4.5)")
	print("  [PASS] Fluxo completo de cliente feliz gera avaliação excelente e registra reputação!")

	# -------------------------------------------------------------------------
	# 4. VALIDAÇÃO DAS MÉTRICAS DO REPUTATIONMANAGER
	# -------------------------------------------------------------------------
	print("\n--- 4. Validação das Métricas do ReputationManager ---")
	print("  Média Geral de Avaliações: %.2f / 5.0 (%s)" % [rep_mgr.get_average_rating(), rep_mgr.get_stars_string()])
	print("  Total de Avaliações: %d (Abandonos: %d)" % [rep_mgr.get_total_reviews(), rep_mgr.get_total_abandoned()])
	var dist = rep_mgr.get_rating_distribution()
	print("  Distribuição de Estrelas: 1★: %d | 2★: %d | 3★: %d | 4★: %d | 5★: %d" % [dist[1], dist[2], dist[3], dist[4], dist[5]])
	assert(rep_mgr.get_total_abandoned() == 1, "Deve haver exatamente 1 abandono registrado")
	assert(dist[1] == 1, "Deve haver 1 avaliação de 1 estrela")
	assert(dist[5] == 1, "Deve haver 1 avaliação de 5 estrelas")
	print("  [PASS] Métricas e estatísticas do ReputationManager validadas com 100% de precisão!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("SISTEMA DE HUMOR, EXPERIÊNCIA E AVALIAÇÃO 100% VALIDADO E APROVADO!")
	print("================================================================================")
	quit(0)
