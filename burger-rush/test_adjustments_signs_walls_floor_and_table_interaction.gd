extends SceneTree

# =============================================================================
# TEST SUITE: PLACA DO CAIXA NO BALCÃO, FACHADA EXTERNA, PISO SALÃO E INTERAÇÃO MESAS
# =============================================================================

const MainScene: PackedScene = preload("res://src/main.tscn")
const RestaurantTableScene: PackedScene = preload("res://src/stations/restaurant_table.tscn")
const CustomerScene: PackedScene = preload("res://src/customers/customer.tscn")
const PlayerScene: PackedScene = preload("res://src/player/player.tscn")
const CashRegisterScene: PackedScene = preload("res://src/stations/cash_register.tscn")
const OrderTrayScene: PackedScene = preload("res://src/items/order_tray.tscn")
const PackagedBurgerScene: PackedScene = preload("res://src/items/packaged_burger.tscn")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: PLACA CAIXA, PAREDES EXTERNAS, PISO VERMELHO E INTERAÇÃO AMPLA DE MESAS")
	print("===========================================================================")

	var total_tests = 0
	var passed_tests = 0

	var main_scene = MainScene.instantiate()
	root.add_child(main_scene)

	# --- TESTE 1: Placa CAIXA Encostada na Madeira do Balcão Abaixo da Registradora ---
	total_tests += 1
	var cash_reg = main_scene.get_node_or_null("CashRegister")
	var sign_node = cash_reg.get_node_or_null("PhysicalCashSign") if cash_reg else null
	var sign_label = sign_node.get_node_or_null("SignLabel") as Label3D if sign_node else null

	var sign_pos_ok = sign_node != null and sign_node.position.y < -0.15 and sign_node.position.z < -0.25
	var sign_text_ok = sign_label != null and sign_label.text.contains("CAIXA")

	if sign_pos_ok and sign_text_ok:
		print("  ✅ TESTE 1: Placa física CAIXA posicionada no balcão de madeira abaixo da registradora (Pos: %s) voltada para o salão." % str(sign_node.position))
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Posição ou placa CAIXA inválida (PosOK: %s, TextOK: %s)" % [sign_pos_ok, sign_text_ok])

	# --- TESTE 2: Consistência das Paredes Externas (Amarelo Forte em Todo Exterior) ---
	total_tests += 1
	var room = main_scene.get_node_or_null("Room")
	var ext_mat = null
	if room:
		var wall_south = room.get_node_or_null("WallSouthLeft") as CSGBox3D
		if wall_south:
			ext_mat = wall_south.material

	var north_wall = room.get_node_or_null("AlleyWallNorth") as CSGBox3D if room else null
	var south_alley = room.get_node_or_null("AlleyWallSouth") as CSGBox3D if room else null
	var west_wall = room.get_node_or_null("WallWestNorth") as CSGBox3D if room else null
	var east_wall = room.get_node_or_null("WallEastSill1") as CSGBox3D if room else null

	var walls_yellow = (north_wall and north_wall.material == ext_mat and
		south_alley and south_alley.material == ext_mat and
		west_wall and west_wall.material == ext_mat and
		east_wall and east_wall.material == ext_mat)

	if walls_yellow and ext_mat:
		print("  ✅ TESTE 2: Todas as paredes externas (Armazém, Beco, Leste e Fachada) usam o material amarelo forte padronizado.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Inconsistência nas cores das paredes externas.")

	# --- TESTE 3: Piso Interno do Salão (Cerâmica Vermelho-Claro com Rejunte e Textura) ---
	total_tests += 1
	var dining_floor = room.get_node_or_null("FloorDining") as CSGBox3D if room else null
	var floor_mat = dining_floor.material as StandardMaterial3D if dining_floor else null
	var floor_ok = floor_mat != null and floor_mat.albedo_texture != null and floor_mat.albedo_texture.resource_path.contains("light_red_tiles")

	if floor_ok:
		print("  ✅ TESTE 3: Piso interno do salão configurado com cerâmica vermelho-claro quadrada individual e alinhada (18x9).")
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Material do piso do salão inválido (Mat: %s)" % [floor_mat])

	# --- TESTE 4: Área Ampla de Interação da Mesa & Atendimento ao Clicar no Cliente ou Mesa ---
	total_tests += 1
	var table = RestaurantTableScene.instantiate() as RestaurantTable
	main_scene.add_child(table)
	table.table_id = 7

	var customer = CustomerScene.instantiate() as Customer
	main_scene.add_child(customer)
	customer.assigned_table = table
	customer.state = Customer.State.SEATED_WAITING_TO_ORDER
	table.occupy_seat(customer)
	table.on_customer_seated(customer)

	var player = PlayerScene.instantiate()
	main_scene.add_child(player)

	var area_node = table.get_node_or_null("TableInteractionArea")
	var has_wide_area = area_node != null

	# 1. Pegar pedido clicando no cliente
	customer.interact(player)
	var order_taken = (customer.state == Customer.State.WAITING_FOR_FOOD and customer.current_order != null)

	# 2. Entregar pedido trazendo bandeja
	var tray = OrderTrayScene.instantiate()
	main_scene.add_child(tray)
	var burger = PackagedBurgerScene.instantiate()
	main_scene.add_child(burger)
	tray.add_item(burger)
	player.pick_up(tray)

	# Jogador clica na mesa (ou no cliente) para entregar
	table.interact(player)
	var food_served = (customer.state == Customer.State.EATING)

	if has_wide_area and order_taken and food_served:
		print("  ✅ TESTE 4: Interação ampla e natural com a mesa e cliente funcionando para receber pedidos e entregar refeições.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Falha no fluxo amplo de atendimento da mesa (Area: %s, OrderTaken: %s, FoodServed: %s)" % [has_wide_area, order_taken, food_served])

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
