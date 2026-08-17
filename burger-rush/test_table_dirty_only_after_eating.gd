extends SceneTree

# =============================================================================
# BURGER RUSH - TEST SUITE: SUJEIRA DAS MESAS VINCULADA AO CONSUMO DA REFEIÇÃO
# =============================================================================

const RestaurantTable = preload("res://src/stations/restaurant_table.gd")
const Customer = preload("res://src/customers/customer.gd")
const Sponge = preload("res://src/tools/sponge.gd")

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(75))
	print("TESTE: SUJEIRA DAS MESAS SOMENTE APÓS CONSUMO EFETIVO DA REFEIÇÃO")
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
		print("ERRO: main.tscn não encontrado")
		quit(1)
		return

	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	await create_timer(0.2).timeout

	var table: RestaurantTable = root_node.get_node_or_null("Table1")
	assert_test(table != null, "Mesa 1 encontrada no restaurante")

	# Garante que a mesa começa limpa e disponível
	table.table_state = RestaurantTable.TableState.AVAILABLE
	table.dirt_amount = 0.0
	table._update_visual_status()

	print("\n--- CENÁRIO 1: Cliente Senta -> Não Come -> Vai Embora (Mesa Permanece LIMPA) ---")
	assert_test(table.is_available(), "Mesa inicialmente limpa e disponível")
	assert_test(not table.is_dirty(), "Mesa não está suja")

	# Cria cliente simulado via packed scene
	var customer_scene = load("res://src/customers/customer.tscn")
	var customer: Customer = customer_scene.instantiate() as Customer
	root_node.add_child(customer)
	table.seated_customers.append(customer)
	customer.assigned_table = table
	customer.state = Customer.State.SEATED_WAITING_TO_ORDER
	table.on_customer_seated(customer)

	assert_test(table.table_state == RestaurantTable.TableState.OCCUPIED, "Cliente ocupou a mesa")
	assert_test(not table.is_dirty(), "Mesa ainda limpa durante a espera")

	# Cliente perde a paciência / decide ir embora sem comer
	customer.abandon_restaurant("Paciência esgotada")
	await create_timer(0.2).timeout

	assert_test(table.table_state == RestaurantTable.TableState.AVAILABLE, "Mesa permaneceu DISPONÍVEL após cliente sair sem comer")
	assert_test(not table.is_dirty(), "Mesa NÃO ficou suja (is_dirty = false)")
	assert_test(table.dirt_amount == 0.0, "Quantidade de sujeira é 0.0")
	var dirt_mesh = table.get_node_or_null("Model/TableTop/TableTopDirt")
	assert_test(dirt_mesh != null and not dirt_mesh.visible, "Manchas visuais de sujeira continuam INVISÍVEIS")
	assert_test(table.is_available(), "Novo cliente pode sentar imediatamente sem necessidade de bucha")

	print("\n--- CENÁRIO 2: Cliente Senta -> Come Refeição -> Vai Embora (Mesa Fica SUJA) ---")
	# Novo cliente senta na mesma mesa
	var customer2: Customer = customer_scene.instantiate() as Customer
	root_node.add_child(customer2)
	table.seated_customers.append(customer2)
	customer2.assigned_table = table
	customer2.state = Customer.State.EATING
	table.on_customer_seated(customer2)

	# Simula que o cliente finalizou a refeição
	customer2._head_to_checkout_queue()
	await create_timer(0.2).timeout

	assert_test(table.table_state == RestaurantTable.TableState.DIRTY, "Mesa ficou SUJA após o cliente comer")
	assert_test(table.is_dirty(), "is_dirty() retorna true após refeição")
	assert_test(table.dirt_amount > 0.0, "Quantidade de sujeira registrada (dirt_amount = %.2f)" % table.dirt_amount)
	assert_test(dirt_mesh != null and dirt_mesh.visible, "Manchas visuais de sujeira agora estão VISÍVEIS na mesa")
	assert_test(not table.is_available(), "Mesa suja bloqueada para novos clientes até ser limpa")

	print("\n--- CENÁRIO 3: Limpeza da Mesa Suja com a Bucha ---")
	var player = root_node.get_node_or_null("Player")
	var sponge = Sponge.new()
	root_node.add_child(sponge)
	sponge.is_dirty = false

	# Limpa a mesa
	var cleaned = table.clean_progress(2.0, player)
	assert_test(cleaned, "Progresso de limpeza da mesa concluído")
	assert_test(table.table_state == RestaurantTable.TableState.AVAILABLE, "Mesa retornou para LIMPA e DISPONÍVEL")
	assert_test(not table.is_dirty(), "Mesa agora está 100% limpa")
	assert_test(dirt_mesh != null and not dirt_mesh.visible, "Manchas de sujeira desapareceram após a limpeza")

	print("\n" + "=".repeat(75))
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(75) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES DE SUJEIRA APÓS CONSUMO PASSARAM COM SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
