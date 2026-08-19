extends SceneTree

var passed_tests: int = 0
var total_tests: int = 0

func assert_test(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		print("  [FAIL] %s" % test_name)

func _init() -> void:
	print("\n=================================================================")
	print("=== TESTE DE REFORMULAÇÃO VISUAL E PERSISTÊNCIA DAS CAIXAS ===")
	print("=================================================================\n")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	var box_scene = load("res://src/items/delivery_box.tscn")
	var box: DeliveryBox = box_scene.instantiate() as DeliveryBox
	root.add_child(box)
	box._ready()

	# =========================================================================
	# TESTE 1: APARÊNCIA DA CAIXA (PAPELÃO, NÃO METÁLICO)
	# =========================================================================
	print("\n--- 1. Aparência e Textura da Caixa ---")
	box.setup_box("patty_beef", "Hambúrguer de Carne", 20)

	var mesh_instance = box.get_node_or_null("BoxBody") as MeshInstance3D
	assert_test(mesh_instance != null, "Corpo 3D da caixa (BoxBody) presente")

	var box_mesh = mesh_instance.mesh as BoxMesh
	assert_test(box_mesh != null, "Mesh do corpo da caixa configurado")
	assert_test(box_mesh.size.x >= 0.40 and box_mesh.size.z >= 0.30, "Dimensões adequadas da caixa (%.2fm x %.2fm)" % [box_mesh.size.x, box_mesh.size.z])

	var mat = box_mesh.material as StandardMaterial3D
	assert_test(mat != null, "Material da caixa configurado")
	assert_test(mat.metallic == 0.0, "Material estritamente NÃO metálico (metallic = 0.0)")
	assert_test(mat.roughness >= 0.80, "Rugosidade realista de papelão (roughness = %.2f)" % mat.roughness)
	assert_test(mat.albedo_texture != null, "Textura de papelão Kraft aplicada")

	# =========================================================================
	# TESTE 2: IDENTIFICAÇÃO ESCRITA (BRANCA, PEQUENA, CENTRALIZADA, SEM ÍCONES)
	# =========================================================================
	print("\n--- 2. Identificação Escrita na Caixa ---")
	var front_stamp: Label3D = box.get_node_or_null("BoxBody/FrontStamp") as Label3D
	assert_test(front_stamp != null, "Rótulo frontal (FrontStamp) presente na face da caixa")
	assert_test(front_stamp.modulate == Color.WHITE, "Texto do rótulo é BRANCO (Color.WHITE)")
	assert_test(front_stamp.font_size <= 16, "Tamanho de fonte pequeno e proporcional (font_size = %d)" % front_stamp.font_size)
	assert_test(front_stamp.text == "CARNE\n\n20 UN.", "Texto formatado exatamente como 'CARNE\\n\\n20 UN.' (atual: '%s')" % front_stamp.text.replace("\n", "\\n"))
	assert_test(not front_stamp.text.contains("📦") and not front_stamp.text.contains("🥩"), "Sem ícones ou emojis poluindo a identificação")
	assert_test(not front_stamp.text.contains("R$") and not front_stamp.text.contains("COD"), "Sem preços ou códigos extras desnecessários")

	# Outros exemplos de ingredientes
	box.setup_box("tomato", "Tomate", 15)
	assert_test(front_stamp.text == "TOMATE\n\n15 UN.", "Rótulo dinâmico para Tomate: 'TOMATE\\n\\n15 UN.'")

	box.setup_box("bread", "Pão", 30)
	assert_test(front_stamp.text == "PÃO\n\n30 UN.", "Rótulo dinâmico para Pão: 'PÃO\\n\\n30 UN.'")

	# =========================================================================
	# TESTE 3: RETIRADA PARCIAL E ATUALIZAÇÃO DINÂMICA
	# =========================================================================
	print("\n--- 3. Retirada Parcial e Atualização Dinâmica da Quantidade ---")
	box.setup_box("patty_beef", "Hambúrguer de Carne", 20)
	assert_test(box.quantity == 20, "Caixa inicial com 20 carnes")

	# Retira 5 carnes
	var taken1 = box.consume_units(5)
	assert_test(taken1 == 5, "Retirou 5 unidades")
	assert_test(box.quantity == 15, "Quantidade restante = 15")
	assert_test(front_stamp.text == "CARNE\n\n15 UN.", "Texto sincronizado dinamicamente para 'CARNE\\n\\n15 UN.'")

	# Retira mais 10 carnes
	var taken2 = box.consume_units(10)
	assert_test(taken2 == 10, "Retirou mais 10 unidades")
	assert_test(box.quantity == 5, "Quantidade restante = 5")
	assert_test(front_stamp.text == "CARNE\n\n5 UN.", "Texto sincronizado dinamicamente para 'CARNE\\n\\n5 UN.'")

	# =========================================================================
	# TESTE 4: PICKUP E DROP DA CAIXA COM CONTEÚDO REMANESCENTE
	# =========================================================================
	print("\n--- 4. Pickup e Drop de Caixa Parcial ---")
	_clear_player(player)

	# Jogador pega a caixa de 5 carnes
	player.pick_up(box)
	assert_test(player.held_item == box, "Jogador segurando a caixa com 5 unidades restantes")

	# Jogador solta a caixa no chão
	player.drop_item()
	assert_test(player.held_item == null, "Mão do jogador liberada")
	assert_test(is_instance_valid(box), "A mesma caixa continua existindo no mundo (não foi destruída)")
	assert_test(box.quantity == 5, "Quantidade permanece intacta em 5 unidades")
	assert_test(front_stamp.text == "CARNE\n\n5 UN.", "Texto visual preservado em 'CARNE\\n\\n5 UN.'")

	# =========================================================================
	# TESTE 5: PERSISTÊNCIA ENTRE DIAS
	# =========================================================================
	print("\n--- 5. Persistência da Caixa com Conteúdo na Mudança de Dia ---")
	var econ = EconomyManager.new()
	root.add_child(econ)
	econ.start_new_day()

	assert_test(is_instance_valid(box), "Caixa com 5 unidades persiste perfeitamente após início do novo dia")
	assert_test(box.quantity == 5, "Quantidade permanece 5 unidades")

	# =========================================================================
	# TESTE 6: ESVAZIAMENTO DA CAIXA (QUANTIDADE = 0)
	# =========================================================================
	print("\n--- 6. Esvaziamento Completo da Caixa ---")
	var taken3 = box.consume_units(5)
	assert_test(taken3 == 5, "Retirou as últimas 5 unidades")
	assert_test(box.quantity == 0, "Quantidade da caixa chegou a 0")

	print("\n=================================================================")
	print("RESULTADO FINAL: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=================================================================\n")

	if passed_tests == total_tests:
		print(">>> SUCESSO TOTAL: REFORMULAÇÃO VISUAL E PERSISTÊNCIA DAS CAIXAS 100% VALIDADAS! <<<\n")
		quit(0)
	else:
		print(">>> FALHA NOS TESTES! <<<\n")
		quit(1)

func _clear_player(player: Player) -> void:
	player.quick_slots.clear()
	player.quick_slots.append({})
	player.quick_slots.append({})
	player.quick_slots.append({})
	player.active_quick_slot = -1
	player.active_tool_slot = Player.ToolSlot.HANDS
	if player.held_item != null:
		if is_instance_valid(player.held_item) and player.held_item.get_parent():
			player.held_item.get_parent().remove_child(player.held_item)
		player.held_item = null
