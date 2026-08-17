extends SceneTree

# =============================================================================
# BURGER RUSH - SUÍTE DE TESTES: CENTRAL DE COMPRAS E MERCADO (ETAPA 2 DO PC)
#
# Validações dos Requisitos:
# 1. Nova aba COMPRAS integrada no PC v2.0
# 2. Catálogo de produtos com Preço Base, Preço de Mercado Diário e Notícias
# 3. Limite estrito de compra (Estoque Atual + Carrinho <= Capacidade Máxima)
# 4. Fornecedores: Rápido (+15%), Normal (0%), Atacado (-12%) e Prazos
# 5. Evento diário de transporte (+25% no tempo de entrega)
# 6. Desconto imediato no caixa (EconomyManager) sem aumentar o estoque
# 7. Entrega temporizada gerando caixas físicas no Pallet da ReceivingArea
# 8. Transporte e armazenamento de caixas nas estações correspondentes
# 9. Bloqueio ao tentar armazenar caixas na estação incorreta
# =============================================================================

const ComputerStation = preload("res://src/stations/computer_station.gd")
const ComputerUI = preload("res://src/ui/computer_ui.gd")
const InventoryManager = preload("res://src/inventory/inventory_manager.gd")
const PurchaseManager = preload("res://src/purchasing/purchase_manager.gd")
const EconomyManager = preload("res://src/economy/economy_manager.gd")
const DailyEventManager = preload("res://src/core/daily_event_manager.gd")
const ReceivingArea = preload("res://src/stations/receiving_area.gd")
const DeliveryBox = preload("res://src/items/delivery_box.gd")

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(85))
	print("TESTE: CENTRAL DE COMPRAS, MERCADO VOLÁTIL, FORNECEDORES E RECEBIMENTO FÍSICO")
	print("=".repeat(85) + "\n")
	call_deferred("_run_tests")

func assert_test(condition: bool, test_name: String) -> void:
	if condition:
		pass_count += 1
		print("  [PASS] %s" % test_name)
	else:
		fail_count += 1
		print("  [FAIL] %s" % test_name)

func _run_tests() -> void:
	var main_scene = load("res://src/main.tscn")
	if not main_scene:
		print("ERRO: main.tscn não encontrado")
		quit(1)
		return

	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	await create_timer(0.3).timeout

	var comp_station = root_node.find_child("ComputerStation", true, false) as ComputerStation
	assert_test(comp_station != null, "1.1 ComputerStation presente no restaurante")

	var comp_ui = comp_station.computer_ui_instance
	assert_test(comp_ui != null, "1.2 Instância de ComputerUI presente")
	comp_ui.open()

	print("\n--- TESTE 1: Navegação e Interface da Central de Compras ---")
	comp_ui._switch_tab(ComputerUI.TabID.PURCHASES, "Central de Compras")
	assert_test(comp_ui.purchases_tab != null and comp_ui.purchases_tab.visible, "1.3 Aba COMPRAS ativa e visível")
	assert_test(comp_ui.inventory_tab != null and not comp_ui.inventory_tab.visible, "1.4 Aba Estoque ocultada ao abrir Compras")

	var pm = PurchaseManager.get_instance()
	assert_test(pm != null, "1.5 PurchaseManager singleton ativo")
	var inv = InventoryManager.get_instance()
	assert_test(inv != null, "1.6 InventoryManager singleton ativo")

	print("\n--- TESTE 2: Catálogo de Produtos e Mercado Volátil ---")
	var catalog = pm.get_catalog_items()
	assert_test(catalog.size() >= 15, "2.1 Catálogo contém todos os produtos do jogo (%d itens)" % catalog.size())

	# Verifica ausência definitiva de itens removidos e molhos
	assert_test(not catalog.has("bread"), "2.2 'bread' genérico NÃO existe no catálogo de compras")
	assert_test(not catalog.has("cup_lid"), "2.3 'cup_lid' (Tampa de copo) NÃO existe no catálogo de compras")
	assert_test(not catalog.has("cooking_oil"), "2.4 'cooking_oil' (Óleo) NÃO existe no catálogo de compras")
	assert_test(not catalog.has("packaged_burger"), "2.5 'packaged_burger' (Burger embalado) NÃO existe no catálogo de compras")
	assert_test(not catalog.has("sauce_ketchup") and not catalog.has("sauce_mustard") and not catalog.has("sauce_mayo") and not catalog.has("sauce_special"), "2.5.1 Molhos NÃO entram no catálogo de compras")
	assert_test(not inv.items.has("sauce_ketchup") and not inv.items.has("sauce_mayo"), "2.5.2 Molhos NÃO possuem estoque numérico no InventoryManager")

	# Itens presentes
	assert_test(catalog.has("bread_bottom") and catalog.has("bread_top"), "2.6 Base do Pão e Tampa do Pão presentes")
	assert_test(catalog.has("patty_beef") and catalog.has("patty_chicken"), "2.7 Hambúrguer de Carne e Frango presentes")
	assert_test(catalog.has("potato_raw"), "2.8 Saco de Batata presente")
	assert_test(catalog.has("cylinder_cola") and catalog.has("cylinder_cola_zero"), "2.9 Cilindros de Bebidas presentes")

	# Mercado volátil
	pm.roll_daily_market()
	var beef_item = pm.get_catalog_item("patty_beef")
	assert_test(beef_item["market_price"] > 0.0, "2.10 Preço de mercado do Hambúrguer de Carne: $%.2f (Base: $%.2f, Var: %+d%%)" % [
		beef_item["market_price"], beef_item["base_price"], int(beef_item["market_variation_pct"] * 100.0)
	])

	print("\n--- TESTE 3: Regras Rígidas de Limite de Compra e Carrinho ---")
	var max_tom = inv.get_max_capacity("tomato")
	var cur_tom = inv.get_stock("tomato")
	var free_tom = max_tom - cur_tom
	var can_buy_tom = pm.get_available_to_buy("tomato")
	assert_test(can_buy_tom <= free_tom, "3.1 Tomate: Disponível para compra (%d) <= Espaço livre (%d)" % [can_buy_tom, free_tom])

	# Adiciona ao carrinho e confere recálculo de espaço
	var add_res = pm.add_to_cart("tomato", 5)
	assert_test(add_res["success"], "3.2 Adicionado 5x Tomate ao carrinho com sucesso")
	var new_avail_tom = pm.get_available_to_buy("tomato")
	assert_test(new_avail_tom == can_buy_tom - 5, "3.3 Disponível para compra atualizado no carrinho: %d -> %d" % [can_buy_tom, new_avail_tom])

	# Tentativa de exceder a capacidade
	var overflow_res = pm.add_to_cart("tomato", 999)
	var in_cart_tom = pm.get_cart().get("tomato", {}).get("quantity", 0)
	assert_test(cur_tom + in_cart_tom <= max_tom, "3.4 Sistema impediu ultrapassar a capacidade máxima de Tomates")

	# 2. Teste com Cilindro de Bebida (Máximo 1 reserva)
	inv.consume_stock("cylinder_cola", 1) # Torna estoque reserva = 0 / 1
	var can_buy_cyl = pm.get_available_to_buy("cylinder_cola")
	assert_test(can_buy_cyl == 1, "3.5 Cilindro Cola com reserva 0/1: pode comprar exatamente 1 unidade")
	pm.add_to_cart("cylinder_cola", 1)
	assert_test(pm.get_available_to_buy("cylinder_cola") == 0, "3.6 Com 1 Cilindro no carrinho: disponível para compra passa para 0")

	print("\n--- TESTE 4: Fornecedores e Evento de Transporte ---")
	pm.clear_cart()
	pm.add_to_cart("patty_beef", 10)
	var subtotal = pm.get_cart_subtotal()

	# Fornecedor Normal
	pm.set_selected_supplier("NORMAL")
	var total_normal = pm.get_cart_total()
	var time_normal = pm.get_cart_delivery_time_sec()
	assert_test(total_normal == subtotal, "4.1 Fornecedor Normal: Preço padrão $%.2f (Prazo: %.0fs)" % [total_normal, time_normal])

	# Fornecedor Rápido (+15%)
	pm.set_selected_supplier("FAST")
	var total_fast = pm.get_cart_total()
	var time_fast = pm.get_cart_delivery_time_sec()
	assert_test(total_fast > total_normal and time_fast < time_normal, "4.2 Fornecedor Rápido: Custo maior $%.2f, Prazo menor %.0fs" % [total_fast, time_fast])

	# Fornecedor Atacado (-12%)
	pm.set_selected_supplier("WHOLESALE")
	var total_wholesale = pm.get_cart_total()
	var time_wholesale = pm.get_cart_delivery_time_sec()
	assert_test(total_wholesale < total_normal and time_wholesale > time_normal, "4.3 Fornecedor Atacado: Desconto $%.2f, Prazo maior %.0fs" % [total_wholesale, time_wholesale])

	# Evento Diário de Transporte (+25% de tempo)
	var daily_event_mgr = DailyEventManager.get_instance()
	daily_event_mgr.force_event(DailyEventManager.EventType.TRANSPORT_DISRUPTION)
	var time_with_event = pm.get_cart_delivery_time_sec()
	assert_test(time_with_event == time_wholesale * 1.25, "4.4 Evento PROBLEMAS NO TRANSPORTE aplica +25%% no prazo de entrega: %.0fs -> %.0fs" % [time_wholesale, time_with_event])
	daily_event_mgr.force_event(DailyEventManager.EventType.NONE)

	print("\n--- TESTE 5: Confirmação de Pedido e Entrega Física no Pallet ---")
	var econ = EconomyManager.get_instance()
	econ.current_money = 1000.0
	var initial_money = econ.get_money()
	var initial_meat_stock = inv.get_stock("patty_beef")

	pm.clear_cart()
	pm.set_selected_supplier("NORMAL")
	pm.add_to_cart("patty_beef", 10)
	var order_cost = pm.get_cart_total()

	var order_res = pm.confirm_order("NORMAL")
	assert_test(order_res["success"], "5.1 Pedido confirmado com sucesso")
	assert_test(econ.get_money() == initial_money - order_cost, "5.2 Dinheiro descontado imediatamente: $%.2f -> $%.2f" % [initial_money, econ.get_money()])
	assert_test(inv.get_stock("patty_beef") == initial_meat_stock, "5.3 Estoque NÃO subiu antes da mercadoria chegar e ser guardada")

	var active_orders = pm.get_active_deliveries()
	assert_test(active_orders.size() == 1, "5.4 Pedido registrado como entrega em andamento")

	# Simula o avanço do tempo até a chegada
	var order_obj = active_orders[0]
	pm._handle_delivery_arrival(order_obj)

	var receiving_area = root_node.find_child("ReceivingArea", true, false) as ReceivingArea
	assert_test(receiving_area != null, "5.5 ReceivingArea presente no beco de serviço")
	assert_test(receiving_area.get_node_or_null("StatusLabel") == null, "5.6 Pallet NÃO possui texto flutuante (StatusLabel removido)")
	assert_test(receiving_area.has_pending_boxes(), "5.7 Caixas de mercadoria geradas fisicamente sobre o Pallet externo")

	print("\n--- TESTE 6: Transporte e Armazenamento nas Estações Corretas ---")
	var player = root_node.find_child("Player", true, false)
	assert_test(player != null, "6.1 Jogador presente na cena")

	# 1. Jogador pega a caixa de carne do pallet
	receiving_area.interact(player)
	var held_box = player.get("held_item") as DeliveryBox
	assert_test(held_box != null and held_box.contained_item_id == "patty_beef", "6.2 Jogador pegou a %s" % (held_box.display_name if held_box else "null"))
	assert_test(held_box.get_node_or_null("BoxBody/FrontStamp") != null, "6.3 Caixa de papelão possui carimbo frontal estampado no papelão")

	# 2. Tentar guardar na estação errada (Ex: Geladeira de Vegetais com porta aberta)
	var veg_fridge = root_node.find_child("IngredientRefrigerator", true, false)
	assert_test(veg_fridge != null, "6.4 Geladeira de Vegetais presente")
	veg_fridge.is_open = true
	veg_fridge.handle_ingredient_interaction(player, "lettuce")
	assert_test(player.get("held_item") == held_box, "6.5 Bloqueio: Caixa de carne NÃO foi aceita no compartimento de alface e permaneceu na mão")

	# 3. Guardar na estação correta (Geladeira de Carnes)
	var meat_fridge = root_node.find_child("CommercialRefrigerator", true, false)
	assert_test(meat_fridge != null, "6.6 Geladeira de Carnes presente")
	meat_fridge.is_open = true
	meat_fridge.pick_meat(player, "patty_beef")
	assert_test(player.get("held_item") == null, "6.7 Caixa armazenada com sucesso na Geladeira de Carnes")
	assert_test(inv.get_stock("patty_beef") == initial_meat_stock + 10, "6.8 Estoque de Hambúrguer de Carne subiu corretamente: %d -> %d" % [initial_meat_stock, inv.get_stock("patty_beef")])

	print("\n--- TESTE 7: Comportamento Especial dos Molhos (Infinitos & Retorno Diário) ---")
	var ketchup_bottle = root_node.find_child("KetchupBottle", true, false)
	if not ketchup_bottle:
		ketchup_bottle = root_node.find_child("SauceBottle", true, false)
	assert_test(ketchup_bottle != null, "7.1 Bisnaga de molho presente no restaurante")
	if ketchup_bottle:
		assert_test(not ketchup_bottle.is_empty(), "7.2 Molho nunca fica vazio (is_empty == false)")
		# Simula movimentação da bisnaga para longe da bancada
		var original_pos = ketchup_bottle.global_position
		ketchup_bottle.global_position = Vector3(100, 10, 100)
		ketchup_bottle.reset_to_home_position()
		assert_test(ketchup_bottle.global_position.distance_to(original_pos) < 0.1, "7.3 Bisnaga fora de posição retornou automaticamente ao suporte original no final do dia")

	print("\n" + "=".repeat(85))
	print("RESULTADO DOS TESTES: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(85) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES DA CENTRAL DE COMPRAS E AJUSTES DE MOLHOS/CAIXAS PASSARAM COM 100% DE SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
