extends SceneTree

# =============================================================================
# BURGER RUSH - TEST SUITE: REORGANIZAÇÃO E ESTOQUE VISUAL DAS GELADEIRAS
# =============================================================================

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(70))
	print("TESTE: REORGANIZAÇÃO E ESTOQUE VISUAL DAS GELADEIRAS / FREEZERS")
	print("=".repeat(70) + "\n")
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

	print("--- TESTE 1: Posicionamento e Alinhamento na Mesma Parede ---")
	var ing_fridge: IngredientRefrigerator = root_node.get_node_or_null("IngredientRefrigerator")
	var meat_fridge: MeatRefrigerator = root_node.get_node_or_null("CommercialRefrigerator")
	var cheese_freezer: CommercialChestFreezer = root_node.get_node_or_null("CommercialChestFreezer")

	assert_test(ing_fridge != null, "Geladeira de Ingredientes encontrada na cena")
	assert_test(meat_fridge != null, "Geladeira de Carnes encontrada na cena")
	assert_test(cheese_freezer != null, "Freezer de Queijos encontrado na cena")

	if ing_fridge and meat_fridge and cheese_freezer:
		# Verifica que estão na mesma parede (Z = -8.35)
		assert_test(is_equal_approx(ing_fridge.position.z, -8.35), "Geladeira de Ingredientes alinhada na parede Norte (Z = %.2f)" % ing_fridge.position.z)
		assert_test(is_equal_approx(meat_fridge.position.z, -8.35), "Geladeira de Carnes alinhada na parede Norte (Z = %.2f)" % meat_fridge.position.z)
		assert_test(is_equal_approx(cheese_freezer.position.z, -8.35), "Freezer de Queijos alinhado na parede Norte (Z = %.2f)" % cheese_freezer.position.z)

		# Verifica ordem lado a lado: [ INGREDIENTES ] [ CARNES ] [ QUEIJOS ]
		assert_test(ing_fridge.position.x < meat_fridge.position.x and meat_fridge.position.x < cheese_freezer.position.x,
			"Ordem visual correta da esquerda para direita: [Ingredientes: %.1f] -> [Carnes: %.1f] -> [Queijos: %.1f]" % [ing_fridge.position.x, meat_fridge.position.x, cheese_freezer.position.x])

		# Verifica que estão viradas para frente (Sul / interior da sala)
		assert_test(is_equal_approx(ing_fridge.rotation.y, 0.0), "Geladeira de Ingredientes rotacionada para o armazém (rot_y = %.2f)" % ing_fridge.rotation.y)
		assert_test(is_equal_approx(meat_fridge.rotation.y, 0.0), "Geladeira de Carnes rotacionada para o armazém (rot_y = %.2f)" % meat_fridge.rotation.y)
		assert_test(is_equal_approx(cheese_freezer.rotation.y, 0.0), "Freezer de Queijos rotacionado para o armazém (rot_y = %.2f)" % cheese_freezer.rotation.y)

	print("\n--- TESTE 2: Remoção de Textos e Labels Flutuantes das Geladeiras ---")
	if ing_fridge:
		var labels_ing = ing_fridge.find_children("*", "Label3D", true, false)
		assert_test(labels_ing.size() == 0, "Geladeira de Ingredientes sem nenhum Label3D / texto de estoque (encontrados: %d)" % labels_ing.size())

	if meat_fridge:
		var labels_meat = meat_fridge.find_children("*", "Label3D", true, false)
		assert_test(labels_meat.size() == 0, "Geladeira de Carnes sem nenhum Label3D / texto de estoque (encontrados: %d)" % labels_meat.size())

	if cheese_freezer:
		var labels_cheese = cheese_freezer.find_children("*", "Label3D", true, false)
		assert_test(labels_cheese.size() == 0, "Freezer de Queijos sem nenhum Label3D / texto de estoque (encontrados: %d)" % labels_cheese.size())

	print("\n--- TESTE 3: Mecânica de Abertura / Fechamento com [E] e Interação [Clique] ---")
	var player = root_node.get_node_or_null("Player")
	assert_test(player != null, "Player presente na cena")

	if ing_fridge and meat_fridge and cheese_freezer and player:
		# Geladeira de Carnes
		assert_test(not meat_fridge.is_door_open(), "Geladeira de Carnes inicia fechada")
		meat_fridge.open_door(player)
		await create_timer(0.55).timeout
		assert_test(meat_fridge.is_door_open(), "Geladeira de Carnes abre com sucesso")
		assert_test(meat_fridge.beef_slot_col.disabled == false, "Slots de colisão da Carne ativados com a porta aberta")

		# Geladeira de Ingredientes
		assert_test(not ing_fridge.is_door_open(), "Geladeira de Ingredientes inicia fechada")
		ing_fridge.open_door(player)
		await create_timer(0.55).timeout
		assert_test(ing_fridge.is_door_open(), "Geladeira de Ingredientes abre com sucesso")
		assert_test(ing_fridge.col_lettuce.disabled == false, "Slots de colisão da Alface ativados com a porta aberta")

		# Freezer de Queijos
		assert_test(not cheese_freezer.is_door_open(), "Freezer de Queijos inicia fechado")
		cheese_freezer.open_freezer(player)
		await create_timer(0.55).timeout
		assert_test(cheese_freezer.is_door_open(), "Freezer de Queijos abre com sucesso")
		assert_test(cheese_freezer.che_slot_col.disabled == false, "Slots de colisão do Queijo ativados com o freezer aberto")

	print("\n--- TESTE 4: Validação do Sistema de Estoque Visual (3 Estágios) ---")
	var inv = InventoryManager.get_instance()
	assert_test(inv != null, "InventoryManager ativo")

	if inv and meat_fridge and ing_fridge and cheese_freezer:
		# 4.1 Geladeira de Carnes (patty_beef)
		inv.items["patty_beef"]["quantity"] = 30 # CHEIO
		meat_fridge._update_patty_visuals()
		assert_test(meat_fridge.beef_full.visible == true and meat_fridge.beef_med.visible == false and meat_fridge.beef_low.visible == false,
			"Carne Bovina CHEIA (qtd 30) -> Full visível, Medium/Low ocultos")

		inv.items["patty_beef"]["quantity"] = 10 # MÉDIO
		meat_fridge._update_patty_visuals()
		assert_test(meat_fridge.beef_full.visible == false and meat_fridge.beef_med.visible == true and meat_fridge.beef_low.visible == false,
			"Carne Bovina MÉDIA (qtd 10) -> Medium visível, Full/Low ocultos")

		inv.items["patty_beef"]["quantity"] = 3 # BAIXO
		meat_fridge._update_patty_visuals()
		assert_test(meat_fridge.beef_full.visible == false and meat_fridge.beef_med.visible == false and meat_fridge.beef_low.visible == true,
			"Carne Bovina BAIXA (qtd 3) -> Low visível, Full/Medium ocultos")

		inv.items["patty_beef"]["quantity"] = 0 # ZERO
		meat_fridge._update_patty_visuals()
		assert_test(meat_fridge.beef_full.visible == false and meat_fridge.beef_med.visible == false and meat_fridge.beef_low.visible == false,
			"Carne Bovina ZERO (qtd 0) -> Nenhum produto falso visível")

		# 4.2 Geladeira de Ingredientes (lettuce & potato_raw)
		inv.items["lettuce"]["quantity"] = 25 # CHEIO
		ing_fridge._update_all_visual_stocks()
		assert_test(ing_fridge.lettuce_full.visible == true and ing_fridge.lettuce_med.visible == false and ing_fridge.lettuce_low.visible == false,
			"Alface CHEIA (qtd 25) -> Full visível, Medium/Low ocultos")

		inv.items["lettuce"]["quantity"] = 8 # MÉDIO
		ing_fridge._update_all_visual_stocks()
		assert_test(ing_fridge.lettuce_full.visible == false and ing_fridge.lettuce_med.visible == true and ing_fridge.lettuce_low.visible == false,
			"Alface MÉDIA (qtd 8) -> Medium visível, Full/Low ocultos")

		inv.items["lettuce"]["quantity"] = 2 # BAIXO
		ing_fridge._update_all_visual_stocks()
		assert_test(ing_fridge.lettuce_full.visible == false and ing_fridge.lettuce_med.visible == false and ing_fridge.lettuce_low.visible == true,
			"Alface BAIXA (qtd 2) -> Low visível, Full/Medium ocultos")

		inv.items["lettuce"]["quantity"] = 0 # ZERO
		ing_fridge._update_all_visual_stocks()
		assert_test(ing_fridge.lettuce_full.visible == false and ing_fridge.lettuce_med.visible == false and ing_fridge.lettuce_low.visible == false,
			"Alface ZERO (qtd 0) -> Nenhum produto falso visível")

		# 4.3 Freezer de Queijos (cheese_cheddar)
		inv.items["cheese_cheddar"]["quantity"] = 25 # CHEIO
		cheese_freezer._update_all_visual_stocks()
		assert_test(cheese_freezer.che_full.visible == true and cheese_freezer.che_med.visible == false and cheese_freezer.che_low.visible == false,
			"Queijo Cheddar CHEIO (qtd 25) -> Full visível, Medium/Low ocultos")

		inv.items["cheese_cheddar"]["quantity"] = 10 # MÉDIO
		cheese_freezer._update_all_visual_stocks()
		assert_test(cheese_freezer.che_full.visible == false and cheese_freezer.che_med.visible == true and cheese_freezer.che_low.visible == false,
			"Queijo Cheddar MÉDIO (qtd 10) -> Medium visível, Full/Low ocultos")

		inv.items["cheese_cheddar"]["quantity"] = 2 # BAIXO
		cheese_freezer._update_all_visual_stocks()
		assert_test(cheese_freezer.che_full.visible == false and cheese_freezer.che_med.visible == false and cheese_freezer.che_low.visible == true,
			"Queijo Cheddar BAIXO (qtd 2) -> Low visível, Full/Medium ocultos")

		inv.items["cheese_cheddar"]["quantity"] = 0 # ZERO
		cheese_freezer._update_all_visual_stocks()
		assert_test(cheese_freezer.che_full.visible == false and cheese_freezer.che_med.visible == false and cheese_freezer.che_low.visible == false,
			"Queijo Cheddar ZERO (qtd 0) -> Nenhum produto falso visível")

	print("\n--- TESTE 5: Retirada de Itens com Clique e Prompts Limpos ---")
	if inv and player and ing_fridge and meat_fridge and cheese_freezer:
		# Restaura estoques
		inv.items["patty_beef"]["quantity"] = 10
		inv.items["lettuce"]["quantity"] = 10
		inv.items["cheese_cheddar"]["quantity"] = 10

		# Prompts limpos
		var p_beef = meat_fridge.get_node("BeefSlot").get_interaction_prompt(player)
		assert_test(not ("(" in p_beef or "%" in p_beef or "10" in p_beef), "Prompt de Carne Bovina sem números/estoque: '%s'" % p_beef)

		var p_lettuce = ing_fridge.get_ingredient_prompt(player, "lettuce")
		assert_test(not ("(" in p_lettuce or "%" in p_lettuce or "10" in p_lettuce), "Prompt de Alface sem números/estoque: '%s'" % p_lettuce)

		var p_cheddar = cheese_freezer.get_slot_prompt(player, Cheese.CheeseType.CHEDDAR)
		assert_test(not ("(" in p_cheddar or "%" in p_cheddar or "10" in p_cheddar), "Prompt de Cheddar sem números/estoque: '%s'" % p_cheddar)

		# Retirada de Carne Bovina
		meat_fridge.get_node("BeefSlot").interact_item(player)
		assert_test(player.held_item != null and player.held_item is Patty, "Jogador pegou Patty com sucesso via clique")
		assert_test(inv.get_stock("patty_beef") == 9, "Estoque de Carne Bovina decrementado para 9")

		# Devolução de Carne Bovina
		meat_fridge.get_node("BeefSlot").interact_item(player)
		assert_test(player.held_item == null, "Jogador devolveu Patty com sucesso via clique")
		assert_test(inv.get_stock("patty_beef") == 10, "Estoque de Carne Bovina incrementado de volta para 10")

	print("\n" + "=".repeat(70))
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(70) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES PASSARAM COM SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
