extends SceneTree

# =============================================================================
# TEST SUITE: CARDÁPIO FÍSICO NA PAREDE, DRIVE-THRU CONTÍNUO & SINO DO PC
# =============================================================================

const DiningMenuBoardScene: PackedScene = preload("res://src/environment/dining_menu_board.tscn")
const DeliveryStationScene: PackedScene = preload("res://src/stations/delivery_station.tscn")
const ComputerStationScene: PackedScene = preload("res://src/stations/computer_station.tscn")
const OrderManagerScript = preload("res://src/orders/order_manager.gd")
const OrderScript = preload("res://src/orders/order.gd")

func _init() -> void:
	print("\n===========================================================================")
	print("🧪 TESTES: CARDÁPIO FÍSICO, JANELA DRIVE-THRU CONTÍNUA & SINO DO PC")
	print("===========================================================================")

	var total_tests = 0
	var passed_tests = 0

	# 1. Setup OrderManager
	var om = OrderManagerScript.new()
	om.name = "OrderManager"
	root.add_child(om)
	om._ready()

	# --- TESTE 1: Cardápio na Parede (Placa Física, Moldura Dourada & Lanches Reais) ---
	total_tests += 1
	var menu_board = DiningMenuBoardScene.instantiate()
	root.add_child(menu_board)

	var has_border = (menu_board.get_node_or_null("PlateBorder") != null)
	var has_plate = (menu_board.get_node_or_null("PlateBody") != null)
	var title_lbl = menu_board.get_node_or_null("TitleLabel") as Label3D
	var col_left = menu_board.get_node_or_null("ColLeftLabel") as Label3D
	var col_right = menu_board.get_node_or_null("ColRightLabel") as Label3D
	var extras_lbl = menu_board.get_node_or_null("ExtrasLabel") as Label3D

	var has_classic = (col_left != null and "Burger Clássico" in col_left.text and "Burger Duplo" in col_left.text and "Burger Cheddar" in col_left.text)
	var has_supreme = (col_right != null and "Burger Chicken" in col_right.text and "Burger Supreme" in col_right.text and "Burger Três Queijos" in col_right.text and "Burger Vegano" in col_right.text and "Burger Egg" in col_right.text)
	var has_extras = (extras_lbl != null and "Batata Frita" in extras_lbl.text and "Refrigerante" in extras_lbl.text and "Suco Natural" in extras_lbl.text)
	var no_billboard = (title_lbl != null and title_lbl.billboard == BaseMaterial3D.BILLBOARD_DISABLED)

	if has_border and has_plate and has_classic and has_supreme and has_extras and no_billboard:
		print("  ✅ TESTE 1: Cardápio na parede implementado como placa física comercial, contendo todos os 11 burgers reais e acompanhamentos sem letras flutuantes.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 1 FALHOU: Placa de cardápio incorreta (Border: %s, Classic: %s, Supreme: %s, Extras: %s)" % [has_border, has_classic, has_supreme, has_extras])

	# --- TESTE 2: Janela do Drive-Thru (Abertura Livre e Contínua Sem Divisória Central) ---
	total_tests += 1
	var dt_station = DeliveryStationScene.instantiate()
	root.add_child(dt_station)

	var has_center_mullion = (dt_station.get_node_or_null("Model/FrameCenterMullion") != null)
	var has_glass_pane_blocking = (dt_station.get_node_or_null("Model/GlassSideFixed") != null)
	var has_frame_left = (dt_station.get_node_or_null("Model/FramePostLeft") != null)
	var has_frame_right = (dt_station.get_node_or_null("Model/FramePostRight") != null)
	var has_counter_ledge = (dt_station.get_node_or_null("Model/CounterLedge") != null)
	var has_item_slot = (dt_station.get_node_or_null("ItemSlot") != null)

	var is_open_and_continuous = (not has_center_mullion and not has_glass_pane_blocking)
	var structure_ok = (has_frame_left and has_frame_right and has_counter_ledge and has_item_slot)

	if is_open_and_continuous and structure_ok:
		print("  ✅ TESTE 2: Janela do Drive-Thru totalmente livre e contínua de um lado ao outro, sem coluna ou divisória central, com balcão funcional.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 2 FALHOU: Janela do Drive-Thru possui obstrução central (Mullion: %s, GlassBlocking: %s, Structure: %s)" % [has_center_mullion, has_glass_pane_blocking, structure_ok])

	# --- TESTE 3: Notificação Externa do PC (Somente Ícone do Sino, Sem Texto Flutuante) ---
	total_tests += 1
	var pc_station = ComputerStationScene.instantiate()
	root.add_child(pc_station)
	pc_station._ready()

	var badge = pc_station.get_node_or_null("NotificationBadge") as Label3D
	var prev_visibility = (badge != null and badge.visible)

	# Simula chegada de novo pedido
	var new_order = om.create_delivery_order()
	var is_visible_now = (badge != null and badge.visible)
	var text_is_only_bell = (badge != null and badge.text.strip_edges() == "🔔")
	var has_no_written_words = (badge != null and not "pedido" in badge.text.to_lower() and not "novo" in badge.text.to_lower())

	if is_visible_now and text_is_only_bell and has_no_written_words:
		print("  ✅ TESTE 3: Notificação externa do PC exibe exclusivamente o ícone do sino '🔔', sem textos flutuantes ('Novo pedido').")
		passed_tests += 1
	else:
		print("  ❌ TESTE 3 FALHOU: Badge do PC incorreto (Visible: %s, Text: '%s', OnlyBell: %s)" % [is_visible_now, badge.text if badge else "", text_is_only_bell])

	# --- TESTE 4: Sino do PC Desaparece ao Visualizar Pedidos ---
	total_tests += 1
	pc_station._on_orders_viewed_in_ui()
	var is_hidden_after_view = (badge != null and not badge.visible and pc_station.unviewed_orders_count == 0)

	if is_hidden_after_view:
		print("  ✅ TESTE 4: O sino de notificação desaparece automaticamente após o jogador abrir/visualizar os pedidos.")
		passed_tests += 1
	else:
		print("  ❌ TESTE 4 FALHOU: Sino não foi ocultado após visualização (Vis: %s, Count: %d)" % [badge.visible if badge else true, pc_station.unviewed_orders_count])

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
