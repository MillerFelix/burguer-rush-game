extends SceneTree

# =============================================================================
# BURGER RUSH - TESTE: SISTEMA DE FRITURA DO QUEIJO E BLOQUEIO NA GRELHA
# =============================================================================

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(85))
	print("TESTE: FRITURA DO QUEIJO E BLOQUEIO DE ITENS NÃO FRITÁVEIS NA GRELHA")
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

	var grill = root_node.find_child("Grill", true, false)
	assert_test(grill != null, "1.1 Grill presente na cozinha")
	var player = root_node.find_child("Player", true, false)
	assert_test(player != null, "1.2 Jogador presente")

	print("\n--- TESTE 1: Hambúrguer continua funcionando exatamente como antes ---")
	var patty = Patty.new()
	patty.meat_type = Patty.MeatType.BEEF
	root_node.add_child(patty)
	assert_test(grill.can_cook_item(patty), "1.3 Hambúrguer é reconhecido como item fritável")

	grill.place_item(patty)
	assert_test(grill.active_items.size() == 1, "1.4 Hambúrguer colocado na chapa com sucesso")

	# Lado 1 cozinha
	patty.advance_cooking(100.0)
	assert_test(patty.state == Patty.State.READY_SIDE_1, "1.5 Hambúrguer Lado 1 pronto (READY_SIDE_1)")

	# Flip com espátula
	player.set("active_tool_slot", 1) # Espátula
	grill.interact_item(player)
	assert_test(patty.is_flipped, "1.6 Hambúrguer virado com a espátula")

	# Lado 2 cozinha
	patty.advance_cooking(100.0)
	assert_test(patty.is_fully_cooked(), "1.7 Hambúrguer 100% cozido (COOKED)")

	# Remoção do hambúrguer
	grill.interact_item(player)
	assert_test(grill.active_items.is_empty(), "1.8 Hambúrguer retirado da chapa com sucesso")
	player.set("held_item", null)

	print("\n--- TESTE 2: Fritura, Derretimento e Queima dos 3 Tipos de Queijo ---")
	var cheese_types = [
		{"type": Cheese.CheeseType.CHEDDAR, "name": "Cheddar"},
		{"type": Cheese.CheeseType.MOZZARELLA, "name": "Muçarela"},
		{"type": Cheese.CheeseType.PRATO, "name": "Prato"}
	]

	for cdata in cheese_types:
		var c_item = Cheese.new()
		c_item.cheese_type = cdata["type"]
		root_node.add_child(c_item)

		# Estado 1: RAW
		assert_test(grill.can_cook_item(c_item), "2.1 %s é reconhecido como item fritável" % cdata["name"])
		assert_test(c_item.state == Cheese.State.RAW, "2.2 %s inicia no estado RAW" % cdata["name"])

		# Coloca na chapa
		grill.place_item(c_item)
		assert_test(grill.active_items.size() == 1, "2.3 %s colocado na chapa" % cdata["name"])

		# Estado 2: FRYING (Derretendo e amolecendo)
		c_item.advance_cooking(45.0)
		assert_test(c_item.state == Cheese.State.FRYING, "2.4 %s entra em estado FRYING (45%% progresso)" % cdata["name"])
		assert_test(c_item.cook_progress >= 45.0, "2.5 Progresso de cocção registrado continuamente")

		# Estado 3: READY (Completamente derretido)
		c_item.advance_cooking(60.0)
		assert_test(c_item.state == Cheese.State.READY, "2.6 %s atinge estado READY (Derretido)" % cdata["name"])
		assert_test(c_item.is_ready() and c_item.is_melted(), "2.7 %s reconhecido como queijo derretido e pronto" % cdata["name"])

		# Estado 4: BURNT (Queimado se passar do tempo)
		c_item.set_burnt()
		assert_test(c_item.state == Cheese.State.BURNT, "2.8 %s atinge estado BURNT (Queimado)" % cdata["name"])
		assert_test(c_item.is_burnt(), "2.9 %s reconhecido como queimado" % cdata["name"])
		assert_test(c_item.get_ingredient_key().ends_with(":burnt"), "2.10 Chave de ingrediente queimado gerada")

		# Remoção do queijo da chapa
		player.set("active_tool_slot", 3)
		player.set("held_item", null)
		grill.interact_item(player)
		assert_test(grill.active_items.is_empty(), "2.11 %s retirado da chapa livremente" % cdata["name"])
		player.set("held_item", null)

	print("\n--- TESTE 3: Bloqueio Rigoroso de Itens Não Fritáveis na Grelha ---")
	var invalid_items = [
		{"name": "Base do Pão", "item": BreadBottom.new()},
		{"name": "Tomate", "item": Item.new()},
		{"name": "Alface", "item": Item.new()},
		{"name": "Garrafa de Molho", "item": Item.new()},
		{"name": "Copo", "item": Item.new()}
	]
	invalid_items[1]["item"].item_id = "tomato"
	invalid_items[2]["item"].item_id = "lettuce"
	invalid_items[3]["item"].item_id = "sauce_ketchup"
	invalid_items[4]["item"].item_id = "cup_drink"

	for inv in invalid_items:
		var itm = inv["item"] as Item
		root_node.add_child(itm)

		# 1. Validação can_cook_item
		assert_test(not grill.can_cook_item(itm), "3.1 %s NÃO pode ser cozido na chapa" % inv["name"])

		# 2. Tentativa direta de place_item é rejeitada
		var placed = grill.place_item(itm)
		assert_test(not placed, "3.2 place_item rejeitou colocar %s na chapa" % inv["name"])
		assert_test(grill.active_items.is_empty(), "3.3 Chapa permaneceu vazia")

		# 3. Jogador tentando colocar com clique
		player.set("held_item", itm)
		grill.interact_item(player)

		# 4. Item não entrou na grelha e foi solto da mão
		assert_test(grill.active_items.is_empty(), "3.4 %s bloqueado e NÃO entrou na grelha" % inv["name"])
		assert_test(player.get("held_item") == null, "3.5 %s liberado da mão do jogador" % inv["name"])
		assert_test(is_instance_valid(itm), "3.6 %s preservado no mundo (não foi destruído nem sumiu)" % inv["name"])

	print("\n" + "=".repeat(85))
	print("RESULTADO DOS TESTES: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(85) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES DE FRITURA E BLOQUEIO PASSARAM COM 100% DE SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
