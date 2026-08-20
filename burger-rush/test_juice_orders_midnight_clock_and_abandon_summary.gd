extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE: SUCOS NOS PEDIDOS, RELÓGIO MEIA-NOITE & ABANDONO
# ==============================================================================

const OrderManagerClass = preload("res://src/orders/order_manager.gd")
const GameClockClass = preload("res://src/time/game_clock.gd")
const ReputationManagerClass = preload("res://src/customers/reputation_manager.gd")
const CustomerReviewClass = preload("res://src/customers/customer_review.gd")
const EconomyManagerClass = preload("res://src/economy/economy_manager.gd")
const HUDClass = preload("res://src/ui/hud.gd")

var passed: int = 0
var failed: int = 0

func assert_test(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("  [PASS] %s" % message)
	else:
		failed += 1
		print("  [FAIL] %s" % message)

func _init() -> void:
	print("\n=================================================================")
	print("=== TESTE: SUCOS NOS PEDIDOS, RELÓGIO MEIA-NOITE & ABANDONO =====")
	print("=================================================================")
	run_tests()
	quit(0 if failed == 0 else 1)

func run_tests() -> void:
	var root = Node3D.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	var econ = EconomyManagerClass.new()
	econ.name = "EconomyManager"
	root.add_child(econ)
	econ.current_money = 250.0

	var rep_mgr = ReputationManagerClass.new()
	rep_mgr.name = "ReputationManager"
	root.add_child(rep_mgr)

	var clock = GameClockClass.new()
	clock.name = "GameClock"
	root.add_child(clock)

	var hud_scene = load("res://src/ui/hud.tscn")
	var hud = hud_scene.instantiate() as HUDClass
	root.add_child(hud)

	# --------------------------------------------------------------------------
	# TESTE 1: Variedade de Bebidas (Refrigerantes e Sucos de Polpa nos Pedidos)
	# --------------------------------------------------------------------------
	print("\n--- TESTE 1: Variedade de Bebidas nos Pedidos (Sucos e Refrigerantes) ---")
	var om = OrderManagerClass.new()
	om.name = "OrderManager"
	root.add_child(om)

	var drinks_generated: Dictionary = {}
	var has_soda = false
	var has_juice = false

	# Gera 100 pedidos simulando clientes e delivery
	for i in range(100):
		var order = om.create_delivery_order()
		for it in order.items:
			var p_id = it.get("product_id", "")
			if p_id.begins_with("soda_"):
				has_soda = true
				drinks_generated[p_id] = drinks_generated.get(p_id, 0) + 1
			elif p_id.begins_with("juice_"):
				has_juice = true
				drinks_generated[p_id] = drinks_generated.get(p_id, 0) + 1

	print("  [INFO] Bebidas sorteadas em 100 pedidos: %s" % str(drinks_generated))
	assert_test(has_soda, "Pedidos incluem refrigerantes tradicionais")
	assert_test(has_juice, "Pedidos incluem sucos de polpa naturais (juice_orange, juice_grape, juice_strawberry)")
	assert_test(drinks_generated.has("juice_orange") or drinks_generated.has("juice_grape") or drinks_generated.has("juice_strawberry"), "Sucos de polpa registrados no sistema de pedidos")

	# --------------------------------------------------------------------------
	# TESTE 2: Relógio do Jogo Pós-Meia-Noite (23:00 -> 00:00 -> 01:00 -> 02:00)
	# --------------------------------------------------------------------------
	print("\n--- TESTE 2: Ciclo de 24 Horas do Relógio (00:00, 01:00, 02:00...) ---")
	clock.current_hour = 23
	clock.current_minute = 58
	clock.state = GameClockClass.State.CLOSING

	assert_test(clock.get_formatted_time() == "23:58", "Horário inicial configurado em 23:58")

	# Avança 2 minutos -> deve virar 00:00 (NÃO 24:00)
	clock._advance_minute()
	assert_test(clock.get_formatted_time() == "23:59", "Avanço para 23:59")
	
	clock._advance_minute()
	assert_test(clock.current_hour == 0, "current_hour zerou para 0 na meia-noite (23 -> 0)")
	assert_test(clock.get_formatted_time() == "00:00", "Relógio exibe '00:00' após 23:59 (e NÃO '24:00')")

	# Avança 60 minutos -> deve virar 01:00 (NÃO 25:00)
	for m in range(60):
		clock._advance_minute()

	assert_test(clock.current_hour == 1, "current_hour avançou para 1 (01:00)")
	assert_test(clock.get_formatted_time() == "01:00", "Relógio exibe '01:00' (e NÃO '25:00')")

	# Avança mais 60 minutos -> deve virar 02:00 (NÃO 26:00)
	for m in range(60):
		clock._advance_minute()

	assert_test(clock.current_hour == 2, "current_hour avançou para 2 (02:00)")
	assert_test(clock.get_formatted_time() == "02:00", "Relógio exibe '02:00' (e NÃO '26:00')")
	assert_test(clock.current_hour < 24, "current_hour estritamente menor que 24")

	# --------------------------------------------------------------------------
	# TESTE 3: Resumo do Fechamento com Contagem Real de Abandonos
	# --------------------------------------------------------------------------
	print("\n--- TESTE 3: Resumo do Fechamento com Contagem Real de Abandonos ---")
	# Simula 3 clientes que abandonaram o restaurante por desistência de espera no Dia 1
	for a in range(3):
		var r_ab = CustomerReviewClass.new()
		r_ab.day = 1
		r_ab.stars = 1.0
		r_ab.abandoned = true
		r_ab.abandon_reason = "Demora no atendimento da mesa"
		rep_mgr.add_review(r_ab)

	# Simula 5 clientes atendidos com sucesso no Dia 1
	for s in range(5):
		var r_ok = CustomerReviewClass.new()
		r_ok.day = 1
		r_ok.stars = 5.0
		r_ok.abandoned = false
		rep_mgr.add_review(r_ok)

	assert_test(rep_mgr.get_daily_abandoned(1) == 3, "ReputationManager registrou exatamente 3 abandonos reais no Dia 1")

	# Fecha o dia no GameClock
	clock.day_number = 1
	clock.starting_day_money = 150.0
	var summary = clock.close_day()

	assert_test(summary.customers_abandoned == 3, "DaySummary capturou os 3 clientes reais que abandonaram o restaurante")

	# Envia para o HUD
	hud._on_day_ended(summary)
	assert_test(hud.report_completed != null, "Label de resultado presente no HUD")
	assert_test(hud.report_completed.text.contains("Abandono: 3 clientes"), "Resumo do fechamento exibe com fidelidade: '%s'" % hud.report_completed.text)

	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d/%d APROVADOS" % [passed, passed + failed])
	print("=================================================================")
	if failed == 0:
		print("🎉 SUCOS NOS PEDIDOS, RELÓGIO 24H E RESUMO DE ABANDONO 100% VALIDADOS!")
