extends SceneTree

# =============================================================================
# BURGER RUSH - TEST SUITE: REWORK DO PC (ETAPA 1: ESTOQUE REAL E POLIMENTO)
#
# Validações dos Novos Requisitos:
# 1. Ausência total de 'cup_lid' (Tampa de copo) e 'cooking_oil' (Óleo)
# 2. Remoção do ingrediente genérico 'bread' (Pão) mantendo 'bread_bottom' e 'bread_top'
# 3. Renomeação de 'patty_beef' para 'Hambúrguer de Carne'
# 4. Renomeação de 'onion' para 'Cebola Comum'
# 5. Renomeação e categorização de 'potato_raw' para 'Saco de Batata' em EMBALAGENS (SUPPLIES)
# 6. Ícone correto de embalagem/saco de batatas (🍟) sem cortes ou batata individual (🥔)
# 7. 4 Cilindros de refrigerante individuais com limite reserva de 1 / 1
# 8. Separação entre cilindro instalado e estoque reserva
# 9. Polpas de fruta (Laranja, Uva, Morango) ativas com 10 / 10
# 10. Filtros por Categoria (TODOS, INGREDIENTES, BEBIDAS, EMBALAGENS) e Busca em tempo real
# =============================================================================

const ComputerStation = preload("res://src/stations/computer_station.gd")
const ComputerUI = preload("res://src/ui/computer_ui.gd")
const InventoryManager = preload("res://src/inventory/inventory_manager.gd")
const DrinkMachine = preload("res://src/stations/drink_machine.gd")

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(85))
	print("TESTE: REWORK DO PC - ETAPA 1: ESTOQUE REAL, RENOMEAÇÕES E POLIMENTO VISUAL")
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

	print("\n--- TESTE 1: Remoção de Letras Flutuantes e Itens Obsoletos ---")
	var floating_label = comp_station.get_node_or_null("StatusLabel")
	assert_test(floating_label == null, "1.2 Nenhum texto flutuante 3D (StatusLabel) sobre o computador")

	var inv = InventoryManager.get_instance()
	assert_test(inv != null, "1.3 InventoryManager ativo")
	assert_test(inv.get_item("cooking_oil") == null, "1.4 Óleo ('cooking_oil') removido 100% do estoque")
	assert_test(inv.get_item("cup_lid") == null, "1.5 Tampa de copo ('cup_lid') removida 100% do estoque")
	assert_test(inv.items.get("bread") == null, "1.6 Pão genérico ('bread') removido do catálogo de itens")

	print("\n--- TESTE 2: Ingredientes e Renomeações Oficiais ---")
	assert_test(inv.get_item("bread_bottom") != null, "2.1 Base do Pão presente no estoque")
	assert_test(inv.get_item("bread_top") != null, "2.2 Tampa do Pão presente no estoque")

	var patty = inv.get_item("patty_beef")
	assert_test(patty != null and patty.get("display_name") == "Hambúrguer de Carne", "2.3 Carne bovina renomeada para 'Hambúrguer de Carne'")

	var onion = inv.get_item("onion")
	assert_test(onion != null and onion.get("display_name") == "Cebola Comum", "2.4 Cebola normal renomeada para 'Cebola Comum'")

	var potato_item = inv.get_item("potato_raw")
	assert_test(potato_item != null and potato_item.get("display_name") == "Saco de Batata", "2.5 Batata crua renomeada para 'Saco de Batata'")
	assert_test(potato_item != null and potato_item.get("category") == "supplies", "2.6 'Saco de Batata' categorizado em EMBALAGENS (supplies)")

	print("\n--- TESTE 3: Interface do PC e Filtros de Categorias ---")
	var comp_ui = comp_station.computer_ui_instance
	assert_test(comp_ui != null, "3.1 Instância de ComputerUI v2.0 presente")
	comp_ui.open()

	# Filtro Ingredientes: Deve conter Base do pão, Tampa do pão, Hambúrguer de carne, Hambúrguer de frango, etc.
	comp_ui._set_category_filter("INGREDIENTS")
	var ing_cards = comp_ui.stock_cards_grid.get_children()
	var ing_names: Array[String] = []
	for c in ing_cards:
		var labels = c.find_children("", "Label", true, false)
		if labels.size() > 0:
			ing_names.append((labels[0] as Label).text)
	
	var has_bread_bottom = false
	var has_bread_top = false
	var has_carne = false
	var has_frango = false
	var has_generic_pao = false
	for n in ing_names:
		if "Base do Pão" in n: has_bread_bottom = true
		if "Tampa do Pão" in n: has_bread_top = true
		if "Hambúrguer de Carne" in n: has_carne = true
		if "Hambúrguer de Frango" in n: has_frango = true
		if n.strip_edges() == "🍞 Pão" or n.strip_edges() == "🍞  Pão" or "Pão de Hambúrguer" in n:
			has_generic_pao = true

	assert_test(has_bread_bottom and has_bread_top, "3.2 Base do Pão e Tampa do Pão listadas em INGREDIENTES")
	assert_test(has_carne and has_frango, "3.3 Hambúrguer de Carne e Hambúrguer de Frango listados em INGREDIENTES")
	assert_test(not has_generic_pao, "3.4 'Pão' genérico NÃO aparece em INGREDIENTES")

	# Filtro Embalagens: Deve conter Copo, Saco de batata, Caixa de lanche, Saco de delivery
	comp_ui._set_category_filter("SUPPLIES")
	var sup_cards = comp_ui.stock_cards_grid.get_children()
	var sup_names: Array[String] = []
	for c in sup_cards:
		var labels = c.find_children("", "Label", true, false)
		if labels.size() > 0:
			sup_names.append((labels[0] as Label).text)

	var has_copo = false
	var has_saco_batata = false
	var has_caixa_lanche = false
	var has_tampa_copo = false
	var has_burger_embalado = false
	for n in sup_names:
		if "Copo" in n and not ("Tampa" in n): has_copo = true
		if "Saco de Batata" in n: has_saco_batata = true
		if "Caixa de Lanche" in n: has_caixa_lanche = true
		if "Tampa de Copo" in n: has_tampa_copo = true
		if "Burger Embalado" in n: has_burger_embalado = true

	assert_test(has_copo and has_saco_batata and has_caixa_lanche, "3.5 EMBALAGENS lista Copo, Saco de Batata e Caixa de Lanche")
	assert_test(not has_tampa_copo, "3.6 'Tampa de Copo' NÃO aparece em EMBALAGENS")
	assert_test(not has_burger_embalado and inv.get_item("packaged_burger") == null, "3.7 'Burger Embalado' ('packaged_burger') removido 100% do estoque e interface")

	print("\n--- TESTE 4: 4 Cilindros Individuais de Bebidas e Polpas ---")
	comp_ui._set_category_filter("DRINKS")
	var drink_cards = comp_ui.stock_cards_grid.get_children()
	assert_test(drink_cards.size() == 7, "4.1 Categoria BEBIDAS contém exatamente 7 itens (4 Cilindros + 3 Polpas)")

	assert_test(inv.get_stock("cylinder_cola") == 1 and inv.get_max_capacity("cylinder_cola") == 1, "4.2 Cilindro Cola: 1 / 1 un")
	assert_test(inv.get_stock("cylinder_cola_zero") == 1 and inv.get_max_capacity("cylinder_cola_zero") == 1, "4.3 Cilindro Cola Zero: 1 / 1 un")
	assert_test(inv.get_stock("cylinder_soda") == 1 and inv.get_max_capacity("cylinder_soda") == 1, "4.4 Cilindro Soda: 1 / 1 un")
	assert_test(inv.get_stock("cylinder_citrus") == 1 and inv.get_max_capacity("cylinder_citrus") == 1, "4.5 Cilindro Citrus: 1 / 1 un")

	print("\n--- TESTE 5: Busca por Texto Atualizada ---")
	comp_ui._set_category_filter("ALL")
	comp_ui._on_search_text_changed("batata")
	var batata_cards = comp_ui.stock_cards_grid.get_children()
	assert_test(batata_cards.size() >= 2, "5.1 Pesquisa por 'batata' exibe 'Saco de Batata' e 'Embalagem de Batata'")

	comp_ui._on_search_text_changed("")
	comp_ui.close()
	assert_test(not comp_ui.visible, "5.2 Computador fechado corretamente")

	print("\n" + "=".repeat(85))
	print("RESULTADO FINAL DOS TESTES: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(85) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES DE RENOMEAÇÕES E POLIMENTO DO ESTOQUE PASSARAM COM 100% DE SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
