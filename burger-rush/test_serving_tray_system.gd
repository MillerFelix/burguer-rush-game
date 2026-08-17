extends SceneTree

# =============================================================================
# BURGER RUSH - TEST SUITE: ASSENTAMENTO PRECISO DA BANDEJA NAS MESAS
# (Validação de Superfície, Ausência de Flutuação e Estabilidade)
# =============================================================================

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(75))
	print("TESTE: ASSENTAMENTO DA BANDEJA NAS MESAS DOS CLIENTES")
	print("=".repeat(75) + "\n")
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
		print("ERRO CRÍTICO: Não foi possível carregar main.tscn")
		quit(1)
		return

	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	await create_timer(0.2).timeout

	print("--- TESTE 1: Geometria e Superfície Real do Tampo das Mesas (Y = 0.805m) ---")
	var table: RestaurantTable = root_node.get_node_or_null("Table7")
	assert_test(table != null, "Mesa de restaurante encontrada na cena")

	if table:
		var col_shape = table.get_node("CollisionShape3D")
		assert_test(col_shape != null, "Colisor da mesa presente")
		if col_shape:
			var cylinder: CylinderShape3D = col_shape.shape as CylinderShape3D
			var top_collision_y = col_shape.position.y + (cylinder.height * 0.5)
			assert_test(is_equal_approx(top_collision_y, 0.805),
				"Topo da colisão da mesa alinhado com o tampo visual: %.3fm (0.805m)" % top_collision_y)
			assert_test(is_equal_approx(table.plate_slot.position.y, 0.805),
				"PlateSlot alinhado com o tampo da mesa: %.3fm (0.805m)" % table.plate_slot.position.y)

	var player = root_node.get_node_or_null("Player")
	assert_test(player != null, "Player ativo")

	var tray_stack: ServingTrayStack = root_node.get_node_or_null("ServingTrayStack")
	assert_test(tray_stack != null, "Pilha de bandejas ativa")

	# Pega 1 bandeja
	tray_stack.interact_item(player)
	var tray: ServingTray = player.held_item as ServingTray
	assert_test(tray != null, "Jogador segurando a bandeja")

	print("\n--- TESTE 2: Drop e Assentamento da Bandeja em Vários Pontos da Mesa ---")
	if tray and table and player:
		# Posições de teste sobre o tampo da mesa (Centro e 4 quadrantes)
		var test_offsets = [
			Vector3(0.0, 0.0, 0.0),    # Centro
			Vector3(-0.15, 0.0, 0.10), # Quadrante Noroeste
			Vector3(0.15, 0.0, 0.10),  # Quadrante Nordeste
			Vector3(-0.10, 0.0, -0.12),# Quadrante Sudoeste
			Vector3(0.10, 0.0, -0.12)  # Quadrante Sudeste
		]

		for i in range(test_offsets.size()):
			var offset = test_offsets[i]
			var table_world_pos = table.global_position
			var drop_target = table_world_pos + Vector3(offset.x, 1.2, offset.z) # Solta de cima

			tray.global_position = drop_target
			tray.on_dropped()
			tray._physics_process(0.2) # Executa física de descida e apoio

			var expected_y = table.global_position.y + 0.805 + tray.bottom_offset
			var actual_y = tray.global_position.y
			var diff = abs(actual_y - expected_y)

			assert_test(diff <= 0.005,
				"Ponto %d (%+.2f, %+.2f): Bandeja encostou no tampo sem flutuar (Y = %.3fm, esperado = %.3fm, diff = %.4fm)" %
				[i + 1, offset.x, offset.z, actual_y, expected_y, diff])

			assert_test(actual_y >= table.global_position.y + 0.800,
				"Ponto %d: Bandeja não atravessa nem entra dentro da mesa" % (i + 1))

			assert_test(tray.rotation == Vector3.ZERO or is_equal_approx(tray.rotation.x, 0.0) and is_equal_approx(tray.rotation.z, 0.0),
				"Ponto %d: Bandeja permanece perfeitamente horizontal e estável" % (i + 1))

	print("\n--- TESTE 3: Montagem e Entrega de Pedido Grande na Mesa ---")
	if tray and table and player:
		# Pega a bandeja de volta
		tray.interact_item(player)
		assert_test(player.held_item == tray, "Jogador pegou a bandeja de volta com Clique Esquerdo")

		# Adiciona 4 lanches + 3 bebidas + 1 batata
		var b_scene = load("res://src/items/cheeseburger.tscn")
		var f_scene = load("res://src/items/fries_pack.tscn")
		var d_scene = load("res://src/items/drink_cup.tscn")

		for j in range(4):
			tray.add_product(b_scene.instantiate())
		for k in range(3):
			tray.add_product(d_scene.instantiate())
		tray.add_product(f_scene.instantiate())

		assert_test(tray.carried_items.size() == 8, "Bandeja carregada com 8 itens (4 lanches, 3 bebidas, 1 batata)")

		# Simula cliente na mesa e entrega
		var customer_scene = load("res://src/customers/customer.tscn")
		var customer: Customer = customer_scene.instantiate()
		root_node.add_child(customer)
		table.occupy(customer)
		customer.assigned_table = table
		customer.state = Customer.State.WAITING_FOR_FOOD

		var order = Order.new()
		order.customer_ref = customer
		order.table_id = table.table_id
		order.add_item("burger", "Hambúrguer", 4, 15.0)
		order.add_item("fries", "Batata Frita", 1, 8.0)
		order.add_item("soda_cola", "Refrigerante", 3, 6.0)
		customer.current_order = order

		table.interact(player)
		assert_test(player.held_item == null, "Bandeja entregue na mesa do cliente")
		assert_test(tray.get_parent() == table.plate_slot, "Bandeja acoplada ao plate_slot da mesa")
		assert_test(is_equal_approx(tray.position.y, 0.0), "Bandeja entregue no plate_slot sem elevação espúria (Y local = 0.0)")

	print("\n--- TESTE 4: Pós-Consumo e Recolhimento da Mesa ---")
	if table and tray and player:
		table.release()
		assert_test(tray.tray_state == ServingTray.TrayState.USED, "Bandeja preservada no estado USED na mesa")
		assert_test(table.table_state == RestaurantTable.TableState.DIRTY, "Mesa aguardando limpeza")

		tray.interact_item(player)
		assert_test(player.held_item == tray, "Jogador recolheu a bandeja usada com Clique Esquerdo")

	print("\n" + "=".repeat(75))
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(75) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES DE ASSENTAMENTO PASSARAM COM SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
