extends SceneTree

# =============================================================================
# TEST SUITE: SISTEMA COMPLETO DE PAGAMENTO DOS CLIENTES & CAIXA REGISTRADORA
# =============================================================================

const MainScene: PackedScene = preload("res://src/main.tscn")
const CashRegisterScene: PackedScene = preload("res://src/stations/cash_register.tscn")
const CustomerScene: PackedScene = preload("res://src/customers/customer.tscn")
const CustomerMoneyScene: PackedScene = preload("res://src/items/customer_money.tscn")
const PlayerScene: PackedScene = preload("res://src/player/player.tscn")
const CustomerMoney = preload("res://src/items/customer_money.gd")
const Customer = preload("res://src/customers/customer.gd")
const Order = preload("res://src/orders/order.gd")
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: SISTEMA COMPLETO DE PAGAMENTO, CAIXA, DINHEIRO & SONS")
	print("===========================================================================")

	var total_tests = 0
	var passed_tests = 0

	var main_scene = MainScene.instantiate()
	root.add_child(main_scene)

	var cash_reg = main_scene.get_node_or_null("CashRegister") as CashRegister
	if not cash_reg:
		cash_reg = CashRegisterScene.instantiate()
		main_scene.add_child(cash_reg)

	# --- TESTE 1: Fila do Caixa Posicionada à Direita (X = 2.30, Z = 0.75m) ---
	total_tests += 1
	var slot_0 = cash_reg.get_slot_position(0)
	var slot_1 = cash_reg.get_slot_position(1)

	var slot_pos_ok = (is_equal_approx(slot_0.x, 2.30) and is_equal_approx(slot_0.z, 0.75) and is_equal_approx(slot_1.z, 1.75))

	if slot_pos_ok:
		print("  ✅ TESTE 1: Fila do caixa posicionada à direita da registradora (X = 2.30), com primeiro cliente próximo ao balcão (Z = 0.75m).")
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Posições da fila incorretas (Slot0: %s, Slot1: %s)" % [slot_0, slot_1])

	# --- TESTE 2: Gaveta Física da Caixa Registradora com Divisórias e Abertura ---
	total_tests += 1
	var drawer = cash_reg.get_node_or_null("Model/CashDrawer")
	var bills_slot = cash_reg.get_node_or_null("Model/CashDrawer/BillsSlot1")
	var coins_slot = cash_reg.get_node_or_null("Model/CashDrawer/CoinsSlot1")

	cash_reg.open_drawer()
	var drawer_is_open = cash_reg.is_drawer_open

	cash_reg.close_drawer()
	var drawer_is_closed = not cash_reg.is_drawer_open

	if drawer != null and bills_slot != null and coins_slot != null and drawer_is_open and drawer_is_closed:
		print("  ✅ TESTE 2: Gaveta física da registradora com interior dividido (cédulas/moedas) e abertura/fechamento mecânico.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Gaveta física incorreta (Drawer: %s, Bills: %s, Coins: %s)" % [drawer != null, bills_slot != null, coins_slot != null])

	# --- TESTE 3: Cliente Estende a Mão com Dinheiro Físico no Balcão ---
	total_tests += 1
	var cust1 = CustomerScene.instantiate() as Customer
	cust1.position = slot_0
	main_scene.add_child(cust1)

	var fake_order = Order.new()
	fake_order.id = 101
	fake_order.total_price = 32.50
	cust1.current_order = fake_order

	cash_reg.join_queue(cust1)
	cust1.update_queue_slot(slot_0, true)

	var cust_is_paying = (cust1.state == Customer.State.PAYING)
	var has_hand_money = (cust1.hand_money_mesh != null)
	var prompt_text = cust1.get_interaction_prompt()

	if cust_is_paying and has_hand_money and prompt_text.contains("32.50"):
		print("  ✅ TESTE 3: Cliente no balcão entra em estado PAYING, estende a mão e exibe notas físicas de dinheiro visíveis.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Cliente no balcão incorreto (StatePaying: %s, HandMoney: %s, Prompt: '%s')" % [cust_is_paying, has_hand_money, prompt_text])

	# --- TESTE 4: Jogador Pega Dinheiro e Entra em Estado Protegido de Depósito ---
	total_tests += 1
	var player = PlayerScene.instantiate()
	main_scene.add_child(player)

	cust1.interact(player)

	var player_has_money = (player.held_item != null and (player.held_item is CustomerMoney or player.held_item.get("is_customer_deposit_money") == true))
	var hand_money_hidden = (cust1.hand_money_mesh == null)

	# Tentativa de soltar no chão (deve ser bloqueada)
	player.drop_item()
	var still_holding_after_drop_attempt = (player.held_item != null)

	if player_has_money and hand_money_hidden and still_holding_after_drop_attempt:
		print("  ✅ TESTE 4: Dinheiro transferido para a mão do jogador como objeto protegido contra drop ou descarte indevido.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Proteção do dinheiro na mão do jogador falhou (HasMoney: %s, Hidden: %s, Protected: %s)" % [player_has_money, hand_money_hidden, still_holding_after_drop_attempt])

	# --- TESTE 5: Depósito na Gaveta do Caixa com Crédito Financeiro e Sons ---
	total_tests += 1
	var initial_balance = cash_reg.register_balance

	cash_reg.interact(player)

	var player_empty_hand = (player.held_item == null)
	var balance_credited = is_equal_approx(cash_reg.register_balance, initial_balance + 32.50)
	var cust_leaving = (cust1.state == Customer.State.LEAVING)

	if player_empty_hand and balance_credited and cust_leaving:
		print("  ✅ TESTE 5: Dinheiro depositado na gaveta, receita de R$ 32.50 creditada, cliente liberado e fila avançada.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 5 FALHOU: Depósito no caixa incorreto (EmptyHand: %s, BalanceCredited: %s, CustLeaving: %s)" % [player_empty_hand, balance_credited, cust_leaving])

	# --- TESTE 6: Síntese Sonora da Caixa e de Pagamento Positivo ---
	total_tests += 1
	var snd_drawer = SoundSynthesizer.get_stream("register_drawer_open")
	var snd_cash = SoundSynthesizer.get_stream("payment_success_cash")

	var sounds_valid = (snd_drawer != null and snd_cash != null and snd_drawer.data.size() > 100 and snd_cash.data.size() > 100)

	if sounds_valid:
		print("  ✅ TESTE 6: Sons sintetizados de abertura de caixa e pagamento positivo (chime de notas/moedas) operacionais.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 6 FALHOU: Sons de caixa e pagamento inválidos (Drawer: %s, Cash: %s)" % [snd_drawer != null, snd_cash != null])

	# --- RESULTADO FINAL ---
	print("\n===========================================================================")
	print("📊 RESULTADO FINAL: %d/%d TESTES PASSARAM (%.1f%%)" % [passed_tests, total_tests, (float(passed_tests)/float(total_tests))*100.0])
	print("===========================================================================")

	if passed_tests == total_tests:
		print("🎉 TODOS OS TESTES PASSARAM COM 100% DE SUCESSO!\n")
		quit(0)
	else:
		print("⚠️ ALGUNS TESTES FALHARAM.\n")
		quit(1)
