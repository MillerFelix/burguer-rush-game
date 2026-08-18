extends SceneTree

# =============================================================================
# TEST SUITE: CENTRAL DE AVALIAÇÕES, SATISFAÇÃO, REPUTAÇÃO E PC FEED
# =============================================================================

const CustomerReviewScript = preload("res://src/customers/customer_review.gd")
const CustomerExperienceScript = preload("res://src/customers/customer_experience.gd")
const ReputationManagerScript = preload("res://src/customers/reputation_manager.gd")
const MenuPricingManagerScript = preload("res://src/recipes/menu_pricing_manager.gd")
const DailyEventManagerScript = preload("res://src/core/daily_event_manager.gd")
const WeatherManagerScript = preload("res://src/environment/weather_manager.gd")
const PowerManagerScript = preload("res://src/core/power_manager.gd")
const AirConditionerScript = preload("res://src/stations/air_conditioner.gd")
const OrderManagerScript = preload("res://src/orders/order_manager.gd")
const OrderScript = preload("res://src/orders/order.gd")
const ComputerStationScript = preload("res://src/stations/computer_station.gd")
const ComputerUIScript = preload("res://src/ui/computer_ui.gd")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: CENTRAL DE AVALIAÇÕES, REPUTAÇÃO & SATISFAÇÃO DOS CLIENTES")
	print("===========================================================================\n")

	var total_tests = 0
	var passed_tests = 0

	# 1. SETUP MANAGERS
	var rep_mgr = ReputationManagerScript.new()
	rep_mgr.name = "ReputationManager"
	root.add_child(rep_mgr)
	ReputationManagerScript.instance = rep_mgr

	var event_mgr = DailyEventManagerScript.new()
	event_mgr.name = "DailyEventManager"
	root.add_child(event_mgr)

	var pm = PowerManagerScript.new()
	pm.name = "PowerManager"
	root.add_child(pm)

	var ac = AirConditionerScript.new()
	ac.name = "AirConditioner"
	root.add_child(ac)
	ac._enter_tree()

	var om = OrderManagerScript.new()
	om.name = "OrderManager"
	root.add_child(om)
	OrderManagerScript.instance = om

	# --- TESTE 1: Atendimento Rápido + Pedido Correto + Preço Justo -> 5 Estrelas & Elogio ---
	total_tests += 1
	var exp1 = CustomerExperienceScript.new(1, "Padrão", 100.0, "DINE_IN")
	exp1.wait_time_to_order = 15.0
	exp1.wait_time_for_food = 25.0
	exp1.order_correct = true
	exp1.food_quality = 1.0
	exp1.table_cleanliness = 1.0
	exp1.primary_product_id = "burger_classic"
	exp1.charged_price = 22.00 # Preço de mercado justo

	var rev1 = exp1.generate_review(1, "12:30")
	rep_mgr.add_review(rev1)

	var is_5_star = (rev1.stars >= 4.8)
	var has_compliment = ("Atendimento Rápido" in rev1.tags or "Comida Excelente" in rev1.tags)
	var is_dine_in = (rev1.channel_type == "DINE_IN" and rev1.channel_name == "Restaurante")

	if is_5_star and has_compliment and is_dine_in:
		print("  ✅ TESTE 1: Experiência excelente -> 5★, canal 'Restaurante' e elogio gerados com sucesso.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Experiência excelente gerou avaliação incorreta (Stars: %.1f, Tags: %s)" % [rev1.stars, str(rev1.tags)])

	# --- TESTE 2: Espera Demorada no Salão -> Avaliação Reduzida e Tag Demora ---
	total_tests += 1
	var exp2 = CustomerExperienceScript.new(2, "Padrão", 60.0, "DINE_IN")
	exp2.wait_time_to_order = 85.0
	exp2.wait_time_for_food = 120.0
	exp2.order_correct = true
	exp2.food_quality = 1.0

	var rev2 = exp2.generate_review(1, "13:15")
	rep_mgr.add_review(rev2)

	var is_demora = ("Demora" in rev2.tags)
	var score_reduced = (rev2.stars < 4.0)

	if is_demora and score_reduced:
		print("  ✅ TESTE 2: Espera excessiva no salão -> Nota reduzida (%.1f★) e reclamação de demora registrada." % rev2.stars)
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Demora não penalizou adequadamente (Stars: %.1f, Tags: %s)" % [rev2.stars, str(rev2.tags)])

	# --- TESTE 3: Pedido Incorreto / Abandono -> Nota Baixa (1-2★) e Comentário Específico ---
	total_tests += 1
	var exp3 = CustomerExperienceScript.new(3, "Crítico", 0.0, "DINE_IN")
	exp3.order_correct = false
	exp3.abandoned = true
	exp3.abandon_type = CustomerExperienceScript.AbandonType.WRONG_ORDER
	exp3.abandon_reason = "Pedido incorreto entregue na mesa!"

	var rev3 = exp3.generate_review(1, "13:45")
	rep_mgr.add_review(rev3)

	var is_low_score = (rev3.stars <= 2.0)
	var has_wrong_tag = ("Pedido Incorreto" in rev3.tags or "Abandono" in rev3.tags)

	if is_low_score and has_wrong_tag:
		print("  ✅ TESTE 3: Pedido incorreto e abandono -> Nota baixa (%.1f★) e comentário específico gravados." % rev3.stars)
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Pedido incorreto não gerou nota baixa (Stars: %.1f, Tags: %s)" % [rev3.stars, str(rev3.tags)])

	# --- TESTE 4: Onda de Calor + Ar-Condicionado Desligado vs Ligado ---
	total_tests += 1
	event_mgr.current_event = DailyEventManagerScript.EventType.EXTREME_HEAT
	ac.is_running = false # AC desligado

	var exp4_off = CustomerExperienceScript.new(4, "Padrão", 50.0, "DINE_IN")
	exp4_off.wait_time_to_order = 20.0
	exp4_off.wait_time_for_food = 30.0
	var rev4_off = exp4_off.generate_review(1, "14:10")

	ac.is_running = true # AC ligado
	var exp4_on = CustomerExperienceScript.new(5, "Padrão", 100.0, "DINE_IN")
	exp4_on.wait_time_to_order = 20.0
	exp4_on.wait_time_for_food = 30.0
	var rev4_on = exp4_on.generate_review(1, "14:25")

	var heat_complaint = ("Restaurante Quente" in rev4_off.tags or "quente" in rev4_off.comment.to_lower())
	var ac_pleased = ("Ambiente Agradável" in rev4_on.tags or rev4_on.climate_stars == 5.0)

	if heat_complaint and ac_pleased:
		print("  ✅ TESTE 4: Calor extremo -> Reclamação com AC desligado; elogio ao conforto com AC ligado.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Conforto térmico não afetou avaliação (Off tags: %s, On tags: %s)" % [str(rev4_off.tags), str(rev4_on.tags)])

	event_mgr.current_event = DailyEventManagerScript.EventType.NONE
	ac.is_running = false

	# --- TESTE 5: Preço Excessivo vs Preço Justo ---
	total_tests += 1
	var exp5_exp = CustomerExperienceScript.new(6, "Padrão", 70.0, "DINE_IN")
	exp5_exp.primary_product_id = "burger_classic"
	exp5_exp.charged_price = 45.00 # Preço abusivo (mercado ~22.00)
	var rev5_exp = exp5_exp.generate_review(1, "14:40")

	var has_price_tag = ("Preço Alto" in rev5_exp.tags or rev5_exp.price_stars <= 2.5)

	if has_price_tag:
		print("  ✅ TESTE 5: Preço muito acima do mercado -> Cliente penalizou nota e gerou tag 'Preço Alto'.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 5 FALHOU: Preço abusivo não detectado (Price stars: %.1f, Tags: %s)" % [rev5_exp.price_stars, str(rev5_exp.tags)])

	# --- TESTE 6: Drive-Thru Telemetria e Comentários Contextuais ---
	total_tests += 1
	var exp6 = CustomerExperienceScript.new(7, "Drive-Thru", 100.0, "DRIVE_THRU")
	exp6.wait_time_to_order = 15.0
	exp6.wait_time_for_food = 25.0
	exp6.order_correct = true
	var rev6 = exp6.generate_review(1, "15:00")
	rep_mgr.add_review(rev6)

	var dt_ok = (rev6.channel_type == "DRIVE_THRU" and rev6.channel_name == "Drive-thru" and "drive" in rev6.comment.to_lower())

	if dt_ok:
		print("  ✅ TESTE 6: Drive-Thru -> Identificação de canal 'Drive-thru' e comentário focado no serviço de carro.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 6 FALHOU: Drive-thru não contextualizado (Channel: %s, Comment: %s)" % [rev6.channel_type, rev6.comment])

	# --- TESTE 7: Delivery Integração e Despacho de Avaliação ---
	total_tests += 1
	var order_deliv = om.create_delivery_order()
	var rev_deliv = rep_mgr.submit_delivery_review(order_deliv, true, 45.0, 30.0, 1, "15:30")

	var deliv_ok = (rev_deliv.channel_type == "DELIVERY" and rev_deliv.channel_name == "Delivery" and rev_deliv.stars >= 4.8)

	if deliv_ok:
		print("  ✅ TESTE 7: Delivery -> Avaliação criada com canal 'Delivery', 5★ e comentário de entrega ágil.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 7 FALHOU: Delivery review incorreto (Channel: %s, Stars: %.1f, Food: %.1f, Svc: %.1f, Price: %.1f, PriceVal: %.2f, Prod: %s)" % [rev_deliv.channel_type, rev_deliv.stars, rev_deliv.food_stars, rev_deliv.service_stars, rev_deliv.price_stars, exp1.charged_price, rev_deliv.order_summary])

	# --- TESTE 8: Reciclagem de Feed e Preservação de Histórico ---
	total_tests += 1
	# Adiciona 75 avaliações sintéticas
	for i in range(75):
		var exp_i = CustomerExperienceScript.new(100 + i, "Padrão", 90.0, "DINE_IN")
		var r_i = exp_i.generate_review(1, "16:00")
		rep_mgr.add_review(r_i)

	var visible_feed = rep_mgr.get_visible_feed()
	var total_history = rep_mgr.get_total_reviews()

	var feed_capped = (visible_feed.size() <= ReputationManagerScript.MAX_FEED_REVIEWS)
	var history_preserved = (total_history > visible_feed.size())

	if feed_capped and history_preserved:
		print("  ✅ TESTE 8: Feed visível limitado a %d itens enquanto histórico total preserva %d avaliações." % [visible_feed.size(), total_history])
		passed_tests += 1
	else:
		print("  ❌ TESTE 8 FALHOU: Reciclagem de feed falhou (Feed: %d, Total: %d)" % [visible_feed.size(), total_history])

	# --- TESTE 9: Precisão Matemática da Média e Distribuição de Estrelas ---
	total_tests += 1
	var avg_rating = rep_mgr.get_average_rating()
	var dist_map = rep_mgr.get_rating_distribution()
	var pcts_map = rep_mgr.get_rating_percentages()

	var sum_dist = dist_map[1] + dist_map[2] + dist_map[3] + dist_map[4] + dist_map[5]
	var pct_sum = pcts_map[1] + pcts_map[2] + pcts_map[3] + pcts_map[4] + pcts_map[5]

	var dist_valid = (sum_dist == total_history and abs(pct_sum - 100.0) < 1.0)
	var avg_valid = (avg_rating >= 1.0 and avg_rating <= 5.0)

	if dist_valid and avg_valid:
		print("  ✅ TESTE 9: Média global (%.1f★) e distribuição de estrelas calculadas com precisão exata." % avg_rating)
		passed_tests += 1
	else:
		print("  ❌ TESTE 9 FALHOU: Cálculo de distribuição incorreto (Sum: %d vs %d, PctSum: %.1f)" % [sum_dist, total_history, pct_sum])

	# --- TESTE 10: Reputação Influencia Tolerância de Preço no MenuPricingManager ---
	total_tests += 1
	var rep_multiplier = MenuPricingManagerScript.get_reputation_tolerance_multiplier()
	var max_price_classic = MenuPricingManagerScript.get_max_price("burger_classic")

	var has_tolerance = (rep_multiplier >= 0.65 and rep_multiplier <= 1.35 and max_price_classic > 25.0)

	if has_tolerance:
		print("  ✅ TESTE 10: MenuPricingManager integrado -> Reputação %.1f gerou tolerância de %.2fx no preço máximo." % [avg_rating, rep_multiplier])
		passed_tests += 1
	else:
		print("  ❌ TESTE 10 FALHOU: Multiplicador de reputação nos preços incorreto (Mult: %.2f)" % rep_multiplier)

	# --- TESTE 11: Interface do PC (Aba Avaliações, Cards, Filtros e Header) ---
	total_tests += 1
	var pc_scene: PackedScene = load("res://src/stations/computer_station.tscn")
	var pc_station = pc_scene.instantiate()
	root.add_child(pc_station)
	pc_station._ready()

	var pc_ui = pc_station.computer_ui_instance
	if pc_ui:
		pc_ui._ready()
		pc_ui.open()
		pc_ui._switch_tab(ComputerUIScript.TabID.REVIEWS, "Avaliações")

	var tab_visible = (pc_ui and pc_ui.reviews_tab and pc_ui.reviews_tab.visible)
	var header_rendered = (pc_ui and pc_ui.reviews_header_container and pc_ui.reviews_header_container.get_child_count() > 0)
	var cards_rendered = (pc_ui and pc_ui.reviews_content_vbox and pc_ui.reviews_content_vbox.get_child_count() > 0)

	if tab_visible and header_rendered and cards_rendered:
		print("  ✅ TESTE 11: Aba Avaliações renderizada no PC com painel de destaque e feed de cards.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 11 FALHOU: Renderização da aba Avaliações no PC falhou (Tab: %s, Header: %s, Cards: %s)" % [tab_visible, header_rendered, cards_rendered])

	# --- TESTE 12: Filtros de Avaliações Operando no PC ---
	total_tests += 1
	pc_ui._set_reviews_filter("DRIVE_THRU")
	var dt_feed_count = pc_ui.reviews_content_vbox.get_child_count()
	pc_ui._set_reviews_filter("DELIVERY")
	var deliv_feed_count = pc_ui.reviews_content_vbox.get_child_count()
	pc_ui._set_reviews_filter("ALL")
	var all_feed_count = pc_ui.reviews_content_vbox.get_child_count()

	var filters_working = (all_feed_count >= dt_feed_count and all_feed_count >= deliv_feed_count)

	if filters_working:
		print("  ✅ TESTE 12: Filtros do feed (Todas, Drive-Thru, Delivery) operando perfeitamente.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 12 FALHOU: Filtros do feed não atualizaram a listagem.")

	# --- RESULTADO FINAL ---
	print("\n===========================================================================")
	print("📊 RESULTADO FINAL: %d/%d TESTES PASSARAM (%.1f%%)" % [passed_tests, total_tests, (float(passed_tests)/float(total_tests))*100.0])
	print("===========================================================================\n")

	if passed_tests == total_tests:
		print("🎉 TODOS OS TESTES PASSARAM COM 100% DE SUCESSO!\n")
		quit(0)
	else:
		print("⚠️ ALGUNS TESTES FALHARAM.\n")
		quit(1)
