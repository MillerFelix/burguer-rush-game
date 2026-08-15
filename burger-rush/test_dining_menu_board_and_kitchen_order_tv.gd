extends SceneTree

# Teste e validação:
# 1. Quadro de cardápio decorativo centralizado, flush na superfície e com margens adequadas
# 2. TV de pedidos (KDS) com interface simplificada, limpa, horizontal e sem textos flutuantes

func _init() -> void:
	print("================================================================================")
	print("BURGER RUSH - TESTE DO CARDÁPIO DE PAREDE E DA TV SIMPLIFICADA DA COZINHA")
	print("================================================================================")

	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	var room = main_scene.get_node("Room")
	assert(room != null, "Room deve existir")

	# -------------------------------------------------------------------------
	# 1. VALIDAÇÃO DO QUADRO DE CARDÁPIO CENTRALIZADO E FLUSH
	# -------------------------------------------------------------------------
	print("\n--- 1. Validação do Quadro de Cardápio na Parede (Mesa 1) ---")
	var menu_board = room.get_node_or_null("MenuBoard")
	assert(menu_board != null, "MenuBoard deve existir na parede das mesas")
	print("  Posição do Quadro: %s" % menu_board.position)
	assert(abs(menu_board.position.x - (-5.4)) < 0.2, "Quadro deve estar alinhado com a Mesa 1 (X = -5.4)")
	assert(menu_board.position.z > 0.0, "Quadro deve estar na face sul da parede divisória (Z > 0)")

	var title_lbl = menu_board.get_node_or_null("TitleLabel") as Label3D
	var content_lbl = menu_board.get_node_or_null("MenuContentLabel") as Label3D
	assert(title_lbl != null and content_lbl != null, "Labels do cardápio devem existir")

	print("  Título: '%s' (X = %.2f, Z = %.3f)" % [title_lbl.text, title_lbl.position.x, title_lbl.position.z])
	print("  Conteúdo:\n%s" % content_lbl.text)

	# Validação de centralização e montagem flush (sem flutuação 3D)
	assert(title_lbl.horizontal_alignment == 1, "Título deve estar centralizado (alignment = CENTER)")
	assert(content_lbl.horizontal_alignment == 1, "Conteúdo do cardápio deve estar centralizado (alignment = CENTER)")
	assert(content_lbl.position.z <= 0.025, "Texto deve estar colado na superfície do quadro (Z <= 0.025)")

	assert("HAMBÚRGUER" in content_lbl.text and "18,90" in content_lbl.text, "Preço do Hambúrguer deve estar presente")
	assert("CHEESEBURGER" in content_lbl.text and "22,90" in content_lbl.text, "Preço do Cheeseburger deve estar presente")
	assert("REFRIGERANTE" in content_lbl.text and "6,00" in content_lbl.text, "Preço do Refrigerante deve estar presente")
	print("  [PASS] Quadro de cardápio centralizado, flush na superfície e com preços brasileiros realistas!")

	# -------------------------------------------------------------------------
	# 2. VALIDAÇÃO DA TV DE PEDIDOS DA COZINHA (INTERFACE SIMPLIFICADA)
	# -------------------------------------------------------------------------
	print("\n--- 2. Validação da TV de Pedidos da Cozinha (KDS Simplificado) ---")
	var tv = room.get_node_or_null("KitchenOrderTV")
	assert(tv != null, "KitchenOrderTV deve existir no Room")
	print("  Posição da TV: %s" % tv.position)

	var tv_rot_y_deg = rad_to_deg(tv.rotation.y)
	print("  Rotação Y da TV: %.1f° (virada para a cozinha)" % tv_rot_y_deg)
	assert(abs(abs(tv_rot_y_deg) - 180.0) < 1.0, "TV deve estar voltada 180° para o interior da cozinha")

	var screen_lbl = tv.get_node_or_null("Model/ScreenLabel") as Label3D
	var header_lbl = tv.get_node_or_null("Model/HeaderLabel") as Label3D
	assert(screen_lbl != null and header_lbl != null, "Labels da TV devem existir")
	assert(screen_lbl.position.z <= 0.05, "Labels da TV devem estar na superfície da tela (sem flutuação 3D)")

	# FASE A: Sem pedidos ativos
	tv._update_display()
	print("  Texto da TV sem pedidos: '%s'" % screen_lbl.text)
	assert("COZINHA LIVRE" in screen_lbl.text, "TV deve indicar cozinha livre quando não há pedidos")
	print("  [PASS] TV exibe status limpo de cozinha livre quando sem pedidos.")

	# FASE B: Criação de um Pedido no Sistema
	print("\n--- 3. Validação do Painel Rápido de Produção ---")
	var order_mgr = main_scene.get_node_or_null("OrderManager")
	assert(order_mgr != null, "OrderManager deve existir")

	var test_order = order_mgr.create_order(null, "cheeseburger", 1, 2, "DINE_IN", 1)
	test_order.add_item("drink", "Refrigerante", 2, 6.0)
	tv._update_display()

	print("  Texto da TV com Pedido #%d:\n%s" % [test_order.id, screen_lbl.text])
	assert(str(test_order.id) in screen_lbl.text, "TV deve exibir o número do pedido (#ID)")
	assert("Mesa 2" in screen_lbl.text, "TV deve exibir a origem de forma compacta")
	assert("NOVO" in screen_lbl.text or "EM ANDAMENTO" in screen_lbl.text, "TV deve exibir status simples")
	assert("itens" in screen_lbl.text, "TV deve exibir a contagem rápida de itens")
	print("  [PASS] Pedido exibido em formato rápido, horizontal e legível!")

	# FASE C: Conclusão do Pedido
	test_order.state = Order.State.DELIVERED
	for it in test_order.items:
		it["delivered_quantity"] = it.get("quantity", 1)
	tv._update_display()

	print("  Texto da TV após entrega do pedido: '%s'" % screen_lbl.text)
	assert("COZINHA LIVRE" in screen_lbl.text, "Pedido entregue deve ser removido da TV ativa")
	print("  [PASS] TV atualiza em tempo real ao concluir o pedido!")

	main_scene.queue_free()

	print("\n================================================================================")
	print("CARDÁPIO DE PAREDE E TV SIMPLIFICADA 100% VALIDADOS E APROVADOS!")
	print("================================================================================")
	quit(0)
