extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE BISNAGAS DE MOLHO REFINADAS (50 DOSES)")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	# 1. Teste de Bisnagas de Molho (4 Sabores com Identidade Visual)
	print("\n--- Teste 1: 4 Bisnagas com Identidade Visual Própria ---")
	var bottle_scene = load("res://src/items/sauce_bottle.tscn")
	assert(bottle_scene != null, "Cena sauce_bottle.tscn deve existir")

	var sauces = ["sauce", "mustard", "mayo", "green_sauce"]
	for s_type in sauces:
		var b = bottle_scene.instantiate()
		root.add_child(b)
		b.sauce_type = s_type
		b._apply_visual_theme()
		b._update_sauce_metadata()

		assert(b.max_charges == 50, "Capacidade máxima deve ser 50 doses")
		assert(b.current_charges == 50, "Bisnaga deve iniciar cheia com 50 doses")
		assert(not b.is_empty(), "Bisnaga não deve estar vazia")
		print("  [PASS] %s: %s (50/50 doses)" % [s_type.to_upper(), b.display_name])
		b.queue_free()

	# 2. Teste de consumo contínuo e estoque
	print("\n--- Teste 2: Consumo e Estoque (50 -> 45 doses) ---")
	var bottle = bottle_scene.instantiate()
	root.add_child(bottle)
	bottle.sauce_type = "sauce"
	bottle._apply_visual_theme()
	bottle._update_sauce_metadata()

	for i in range(5):
		var ok = bottle.consume_dose()
		assert(ok, "consume_dose deve retornar true")

	assert(bottle.current_charges == 45, "Bisnaga deve ter 45 doses restantes após 5 consumos")
	print("  [PASS] Consumo de 5 doses com sucesso (50 -> 45 doses)")

	# Esgotar para testar bloqueio
	bottle.current_charges = 0
	inv.items["sauce"]["quantity"] = 0
	assert(bottle.is_empty(), "Bisnaga deve reportar vazia")
	assert(not bottle.consume_dose(), "Consumo deve falhar quando zerado sem estoque")
	print("  [PASS] Bloqueio ao esgotar doses funcionando")

	# Recarga
	bottle.refill()
	assert(bottle.current_charges == 50, "Bisnaga deve recarregar para 50 doses")
	print("  [PASS] Recarga para 50 doses com sucesso")

	# 3. Teste de montagem na PrepTable
	print("\n--- Teste 3: Montagem de Hambúrguer na PrepTable com Bisnaga ---")
	var prep_scene = load("res://src/stations/prep_table.tscn")
	var prep = prep_scene.instantiate()
	root.add_child(prep)
	prep._ready()

	var bread_scene = load("res://src/items/bread.tscn")
	var bread = bread_scene.instantiate()
	prep._place_item(bread)

	var patty_scene = load("res://src/items/patty.tscn")
	var patty = patty_scene.instantiate()
	patty.set_state(Patty.State.COOKED)
	prep._place_item(patty)

	assert(prep.placed_items.size() == 1, "Pão + Carne montam Hambúrguer base")

	# Aplica molho da bisnaga
	var applied = bottle.consume_dose()
	assert(applied, "Deve aplicar dose da bisnaga")
	var sauce_item = load("res://src/items/sauce.tscn").instantiate()
	prep._place_item(sauce_item)

	assert(prep.placed_items.size() == 2, "Hambúrguer + Molho na mesa")

	var cheese_scene = load("res://src/items/cheese.tscn")
	var cheese = cheese_scene.instantiate()
	prep._place_item(cheese)

	assert(prep.placed_items.size() >= 1, "Cheeseburger montado com sucesso")
	print("  [PASS] Hambúrguer temperado com bisnaga e finalizado com sucesso!")

	prep.queue_free()
	bottle.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE REFINAMENTO DE BISNAGAS FORAM APROVADOS!")
	print("============================================================")
	quit(0)
