extends SceneTree

# =============================================================================
# BURGER RUSH - TESTE DA ESTAÇÃO DE EMBALAGENS + ESTOQUE VISUAL (10 TESTES)
# =============================================================================

const DeliveryBagScript = preload("res://src/items/delivery_bag.gd")

func _init() -> void:
	print("\n============================================================")
	print("BURGER RUSH - TESTES: ESTAÇÃO DE EMBALAGENS + ESTOQUE VISUAL")
	print("============================================================")

	var r = get_root()
	var world = Node3D.new()
	world.name = "TestWorld"
	r.add_child(world)

	# 1. Inicializa InventoryManager
	var inv = InventoryManager.new()
	world.add_child(inv)
	inv._ready()

	# 2. Instancia Player
	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate()
	world.add_child(player)
	player.global_position = Vector3(0, 0, 0)
	player._ready()

	# 3. Instancia PackagingStation
	var station_scene = load("res://src/stations/packaging_station.tscn")
	assert(station_scene != null, "Cena packaging_station.tscn carregada com sucesso")
	var station = station_scene.instantiate() as PackagingStation
	world.add_child(station)
	station.global_position = Vector3(0, 0, 0)
	station._ready()

	# --- TESTE 1: MESA CHEIA (50 UNIDADES) E SEM LABELS FLUTUANTES ---
	print("\n--- TESTE 1: Mesa Cheia e Ausência de Texto Flutuante na Mesa ---")
	assert(station.get_node_or_null("StatusLabel") == null, "Nenhum Label3D/StatusLabel flutuante na mesa")
	assert(inv.get_stock("burger_box") == 50, "Estoque inicial de caixas: 50")
	assert(inv.get_stock("potato_box") == 50, "Estoque inicial de batatas: 50")
	assert(inv.get_stock("cup_empty") == 50, "Estoque inicial de copos: 50")
	assert(inv.get_stock("delivery_bag") == 50, "Estoque inicial de sacos de delivery: 50")

	station._update_all_visual_stocks()
	assert(station.burger_box_full.visible and not station.burger_box_med.visible and not station.burger_box_low.visible, "Caixas: estágio CHEIO visível")
	assert(station.potato_box_full.visible and not station.potato_box_med.visible and not station.potato_box_low.visible, "Batatas: estágio CHEIO visível")
	assert(station.cups_full.visible and not station.cups_med.visible and not station.cups_low.visible, "Copos: estágio CHEIO visível")
	assert(station.delivery_bags_full.visible and not station.delivery_bags_med.visible and not station.delivery_bags_low.visible, "Sacos Delivery: estágio CHEIO visível")
	print("  [PASS] Mesa cheia com 50/50 em todas as 4 seções e sem textos flutuantes.")

	# --- TESTE 2: PEGAR COPO (CLIQUE ESQUERDO) ---
	print("\n--- TESTE 2: Pegar Copo via Clique Esquerdo ---")
	player.global_position = station.global_position + Vector3(0, 0, 0.25)
	var cup_prompt = station.get_interaction_prompt(player)
	assert("Copo" in cup_prompt, "Prompt de copo exibido: %s" % cup_prompt)
	station.interact_item(player)
	assert(player.held_item != null and player.held_item is DrinkCup, "Jogador pegou 1 DrinkCup")
	assert(inv.get_stock("cup_empty") == 49, "Estoque de copos reduzido para 49")
	player.take_held_item().queue_free()
	print("  [PASS] Copo transparente retirado com sucesso e estoque atualizado para 49.")

	# --- TESTE 3: PEGAR EMBALAGEM DE BATATA (CLIQUE ESQUERDO) ---
	print("\n--- TESTE 3: Pegar Embalagem de Batata via Clique Esquerdo ---")
	player.global_position = station.global_position + Vector3(0, 0, -0.25)
	var fries_prompt = station.get_interaction_prompt(player)
	assert("Batata" in fries_prompt, "Prompt de batata exibido: %s" % fries_prompt)
	station.interact_item(player)
	assert(player.held_item != null and (player.held_item is PotatoBoxItem or str(player.held_item.get("item_id")) == "potato_box"), "Jogador pegou embalagem de batata")
	assert(inv.get_stock("potato_box") == 49, "Estoque de batata reduzido para 49")
	player.take_held_item().queue_free()
	print("  [PASS] Embalagem de batata retirada com sucesso e estoque atualizado para 49.")

	# --- TESTE 4: PEGAR CAIXINHA DE LANCHE (CLIQUE ESQUERDO) ---
	print("\n--- TESTE 4: Pegar Caixinha de Lanche via Clique Esquerdo ---")
	player.global_position = station.global_position + Vector3(0, 0, -0.75)
	var box_prompt = station.get_interaction_prompt(player)
	assert("Caixa" in box_prompt or "Hambúrguer" in box_prompt, "Prompt de caixa exibido: %s" % box_prompt)
	station.interact_item(player)
	assert(player.held_item != null and (player.held_item is BurgerBox or str(player.held_item.get("item_id")) == "burger_box"), "Jogador pegou BurgerBox")
	assert(inv.get_stock("burger_box") == 49, "Estoque de caixas reduzido para 49")
	player.take_held_item().queue_free()
	print("  [PASS] Caixa de lanche retirada com sucesso e estoque atualizado para 49.")

	# --- TESTE 5: PEGAR SACO DE DELIVERY (CLIQUE ESQUERDO) ---
	print("\n--- TESTE 5: Pegar Saco de Delivery via Clique Esquerdo ---")
	player.global_position = station.global_position + Vector3(0, 0, 0.75)
	var bag_prompt = station.get_interaction_prompt(player)
	assert("Delivery" in bag_prompt or "Saco" in bag_prompt, "Prompt de saco delivery exibido: %s" % bag_prompt)
	station.interact_item(player)
	assert(player.held_item != null and (player.held_item is DeliveryBagScript or str(player.held_item.get("item_id")) == "delivery_bag"), "Jogador pegou DeliveryBag")
	assert(inv.get_stock("delivery_bag") == 49, "Estoque de sacos reduzido para 49")
	player.take_held_item().queue_free()
	print("  [PASS] Saco de delivery retirado com sucesso e estoque atualizado para 49.")

	# --- TESTE 6: CONSUMIR VÁRIAS UNIDADES E ATUALIZAÇÃO VISUAL ---
	print("\n--- TESTE 6: Consumo Contínuo e Resposta Visual ---")
	inv.consume_stock("burger_box", 10)
	inv.consume_stock("potato_box", 10)
	inv.consume_stock("cup_empty", 10)
	inv.consume_stock("delivery_bag", 10)
	assert(inv.get_stock("burger_box") == 39, "Estoque em 39")
	station._update_all_visual_stocks()
	assert(station.burger_box_full.visible, "Ainda no estágio CHEIO (39 >= 35)")
	print("  [PASS] Estoque de 39 unidades mantém visual CHEIO.")

	# --- TESTE 7: ESTOQUE MÉDIO (15 a 34 UNIDADES) ---
	print("\n--- TESTE 7: Transição para o Estágio MÉDIO (25 unidades) ---")
	inv.items["burger_box"]["quantity"] = 25
	inv.items["potato_box"]["quantity"] = 25
	inv.items["cup_empty"]["quantity"] = 25
	inv.items["delivery_bag"]["quantity"] = 25
	station._update_all_visual_stocks()
	assert(not station.burger_box_full.visible and station.burger_box_med.visible and not station.burger_box_low.visible, "Caixas: estágio MÉDIO")
	assert(not station.potato_box_full.visible and station.potato_box_med.visible and not station.potato_box_low.visible, "Batatas: estágio MÉDIO")
	assert(not station.cups_full.visible and station.cups_med.visible and not station.cups_low.visible, "Copos: estágio MÉDIO")
	assert(not station.delivery_bags_full.visible and station.delivery_bags_med.visible and not station.delivery_bags_low.visible, "Sacos Delivery: estágio MÉDIO")
	print("  [PASS] Transição visual para estágio MÉDIO confirmada com sucesso.")

	# --- TESTE 8: ESTOQUE BAIXO (1 a 14 UNIDADES) ---
	print("\n--- TESTE 8: Transição para o Estágio BAIXO (5 unidades) ---")
	inv.items["burger_box"]["quantity"] = 5
	inv.items["potato_box"]["quantity"] = 5
	inv.items["cup_empty"]["quantity"] = 5
	inv.items["delivery_bag"]["quantity"] = 5
	station._update_all_visual_stocks()
	assert(not station.burger_box_full.visible and not station.burger_box_med.visible and station.burger_box_low.visible, "Caixas: estágio BAIXO")
	assert(not station.potato_box_full.visible and not station.potato_box_med.visible and station.potato_box_low.visible, "Batatas: estágio BAIXO")
	assert(not station.cups_full.visible and not station.cups_med.visible and station.cups_low.visible, "Copos: estágio BAIXO")
	assert(not station.delivery_bags_full.visible and not station.delivery_bags_med.visible and station.delivery_bags_low.visible, "Sacos Delivery: estágio BAIXO")
	print("  [PASS] Transição visual para estágio BAIXO ('isso está acabando') confirmada.")

	# --- TESTE 9: ESTOQUE ZERO (0 UNIDADES) ---
	print("\n--- TESTE 9: Estoque Zero (Nenhum item visível) ---")
	inv.items["burger_box"]["quantity"] = 0
	inv.items["potato_box"]["quantity"] = 0
	inv.items["cup_empty"]["quantity"] = 0
	inv.items["delivery_bag"]["quantity"] = 0
	station._update_all_visual_stocks()
	assert(not station.burger_box_full.visible and not station.burger_box_med.visible and not station.burger_box_low.visible, "Caixas: 100% invisíveis no slot")
	assert(not station.potato_box_full.visible and not station.potato_box_med.visible and not station.potato_box_low.visible, "Batatas: 100% invisíveis no slot")
	assert(not station.cups_full.visible and not station.cups_med.visible and not station.cups_low.visible, "Copos: 100% invisíveis no slot")
	assert(not station.delivery_bags_full.visible and not station.delivery_bags_med.visible and not station.delivery_bags_low.visible, "Sacos Delivery: 100% invisíveis no slot")
	print("  [PASS] Estoque zero: bancada limpa sem itens fantasmas.")

	# --- TESTE 10: LIMITE MÁXIMO (50/50) E DEVOLUÇÃO AO ESTOQUE ---
	print("\n--- TESTE 10: Limite Rigoroso de 50/50 e Devolução ---")
	inv.items["cup_empty"]["quantity"] = 49
	var cup_to_return = load("res://src/items/drink_cup.tscn").instantiate()
	player.pick_up(cup_to_return)
	player.global_position = station.global_position + Vector3(0, 0, 0.25)
	station.interact_item(player)
	assert(player.held_item == null, "Copo devolvido ao estoque com sucesso")
	assert(inv.get_stock("cup_empty") == 50, "Estoque retornou a 50")

	# Tentativa de devolver com estoque já em 50
	var extra_cup = load("res://src/items/drink_cup.tscn").instantiate()
	player.pick_up(extra_cup)
	station.interact_item(player)
	assert(player.held_item == extra_cup, "Item bloqueado: estoque já está no limite 50/50")
	assert(inv.get_stock("cup_empty") == 50, "Estoque não ultrapassa 50")
	player.take_held_item().queue_free()
	print("  [PASS] Limite máximo 50/50 respeitado rigorosamente e bloqueio de overflow validado.")

	# --- TESTE 11: FUNCIONAMENTO DO SACO DE DELIVERY (CONTAINER) ---
	print("\n--- TESTE 11: Saco de Delivery agrupando itens do pedido ---")
	var bag = load("res://src/items/delivery_bag.tscn").instantiate()
	world.add_child(bag)
	assert(bag.can_accept_item(load("res://src/items/drink_cup.tscn").instantiate()), "Aceita copo de bebida")
	assert(bag.can_accept_item(load("res://src/items/burger_box.tscn").instantiate()), "Aceita caixa de hambúrguer")
	assert(bag.can_accept_item(load("res://src/items/potato_box.tscn").instantiate()), "Aceita embalagem de batata")

	var drink_test = load("res://src/items/drink_cup.tscn").instantiate() as DrinkCup
	world.add_child(drink_test)
	drink_test.set_flavor("soda_cola")
	drink_test.set_state(DrinkCup.State.CLOSED)
	bag.add_contained_item(drink_test)
	assert(bag.has_drink(), "Saco contém a bebida")
	assert(bag.contained_items.size() == 1, "1 item dentro da sacola")
	bag.queue_free()
	print("  [PASS] Saco de delivery preparado para agrupar pedidos de delivery.")

	print("\n============================================================")
	print("TODOS OS 10+ TESTES DA ESTAÇÃO DE EMBALAGENS FORAM APROVADOS!")
	print("============================================================")

	quit()
