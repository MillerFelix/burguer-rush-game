extends SceneTree

## test_master_system_regression.gd
## Suite mestre de regressao — testa sistemas centrais do Burger Rush.

var total_pass := 0
var total_fail := 0

func _assert(condition: bool, label: String) -> void:
	if condition:
		total_pass += 1
		print("  [PASS] " + label)
	else:
		total_fail += 1
		push_error("  [FAIL] " + label)

func _section(name: String) -> void:
	print("\n--- " + name + " ---")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - MASTER SYSTEM REGRESSION SUITE")
	print("============================================================")

	# --------------------------------------------------------
	# 1. ECONOMY MANAGER
	# --------------------------------------------------------
	_section("EconomyManager")
	var econ = EconomyManager.new()
	root.add_child(econ)
	await process_frame
	var initial = econ.get_money()
	econ.add_money(500.0)
	_assert(econ.get_money() == initial + 500.0, "add_money increases balance")
	var spent = econ.spend_money(200.0)
	_assert(spent == true, "spend_money succeeds when balance sufficient")
	_assert(absf(econ.get_money() - (initial + 300.0)) < 0.01, "spend_money deducts correctly")
	var cant_spend = econ.spend_money(99999.0)
	_assert(cant_spend == false, "spend_money fails when insufficient funds")
	econ.queue_free()

	# --------------------------------------------------------
	# 2. INVENTORY MANAGER
	# --------------------------------------------------------
	_section("InventoryManager")
	var inv = InventoryManager.new()
	root.add_child(inv)
	await process_frame
	var initial_beef = inv.get_stock("patty")
	inv.add_stock("patty", 5)
	_assert(inv.get_stock("patty") == initial_beef + 5, "add_stock increases quantity")
	var consumed = inv.consume_stock("patty", 3)
	_assert(consumed == true, "consume_stock succeeds when sufficient")
	_assert(inv.get_stock("patty") == initial_beef + 2, "consume_stock deducts correctly")
	_assert(inv.has_stock("patty", 1) == true, "has_stock true when sufficient")
	_assert(inv.has_stock("patty", 99999) == false, "has_stock false when insufficient")
	inv.queue_free()

	# --------------------------------------------------------
	# 3. GAME CLOCK
	# --------------------------------------------------------
	_section("GameClock")
	var clock = GameClock.new()
	root.add_child(clock)
	await process_frame
	_assert(clock.state == GameClock.State.PREPARATION, "clock starts in PREPARATION")
	clock.open_restaurant()
	_assert(clock.state == GameClock.State.OPEN, "open_restaurant sets state OPEN")
	clock.set_state(GameClock.State.CLOSED)
	_assert(clock.state == GameClock.State.CLOSED, "set_state CLOSED works")
	_assert(clock.get_formatted_time() != "", "get_formatted_time returns non-empty string")
	clock.queue_free()

	# --------------------------------------------------------
	# 4-10. STATION SCENE NODES
	# --------------------------------------------------------
	_section("Grill scene nodes")
	var grill_scene = load("res://src/stations/grill.tscn").instantiate()
	_assert(grill_scene.has_node("CookingSlot"), "Grill has CookingSlot")
	_assert(grill_scene.has_node("StatusLabel"), "Grill has StatusLabel")
	_assert(grill_scene.has_node("Model/GrillPlate"), "Grill has Model/GrillPlate")
	_assert(grill_scene.has_node("Model/Knob1"), "Grill has Model/Knob1")
	grill_scene.free()

	_section("Fryer scene nodes")
	var fryer_scene = load("res://src/stations/fryer.tscn").instantiate()
	_assert(fryer_scene.has_node("FryerSlot"), "Fryer has FryerSlot")
	_assert(fryer_scene.has_node("Model/OilMesh"), "Fryer has Model/OilMesh")
	_assert(fryer_scene.has_node("Model/BasketHandle"), "Fryer has Model/BasketHandle")
	fryer_scene.free()

	_section("DrinkMachine scene nodes")
	var dm_scene = load("res://src/stations/drink_machine.tscn").instantiate()
	_assert(dm_scene.has_node("CupSlot"), "DrinkMachine has CupSlot")
	_assert(dm_scene.has_node("Model/Nozzle1"), "DrinkMachine has Nozzle1")
	_assert(dm_scene.has_node("Model/DripTray"), "DrinkMachine has DripTray")
	dm_scene.free()

	_section("PrepTable scene nodes")
	var pt_scene = load("res://src/stations/prep_table.tscn").instantiate()
	_assert(pt_scene.has_node("ItemSlot"), "PrepTable has ItemSlot")
	_assert(pt_scene.has_node("Model/TableTop"), "PrepTable has Model/TableTop")
	_assert(pt_scene.has_node("Model/GNPan1"), "PrepTable has Model/GNPan1")
	pt_scene.free()

	_section("PackagingStation scene nodes")
	var ps_scene = load("res://src/stations/packaging_station.tscn").instantiate()
	_assert(ps_scene.has_node("PackagingSlot"), "PackagingStation has PackagingSlot")
	_assert(ps_scene.has_node("Model/PaperRoll"), "PackagingStation has Model/PaperRoll")
	_assert(ps_scene.has_node("Model/BoxStack"), "PackagingStation has Model/BoxStack")
	ps_scene.free()

	_section("RestaurantTable scene nodes")
	var rt_scene = load("res://src/stations/restaurant_table.tscn").instantiate()
	_assert(rt_scene.has_node("Seat"), "RestaurantTable has Seat")
	_assert(rt_scene.has_node("PlateSlot"), "RestaurantTable has PlateSlot")
	_assert(rt_scene.has_node("Model/Chair1"), "RestaurantTable has Model/Chair1")
	_assert(rt_scene.has_node("Model/Chair2"), "RestaurantTable has Model/Chair2")
	_assert(rt_scene.has_node("Model/TableTop"), "RestaurantTable has Model/TableTop")
	rt_scene.free()

	# --------------------------------------------------------
	# 11. CHARACTERS
	# --------------------------------------------------------
	_section("Customer humanoid model")
	var cust_scene = load("res://src/customers/customer.tscn").instantiate()
	_assert(cust_scene.has_node("Model/Head"), "Customer has Model/Head")
	_assert(cust_scene.has_node("Model/Torso"), "Customer has Model/Torso")
	_assert(cust_scene.has_node("Model/LegLeft"), "Customer has Model/LegLeft")
	_assert(cust_scene.has_node("Model/LegRight"), "Customer has Model/LegRight")
	_assert(cust_scene.has_node("Model/ShoeLeft"), "Customer has Model/ShoeLeft")
	cust_scene.free()

	_section("Employee humanoid model")
	var emp_scene = load("res://src/employees/employee.tscn").instantiate()
	_assert(emp_scene.has_node("Model/Head"), "Employee has Model/Head")
	_assert(emp_scene.has_node("Model/Head/Hat") or emp_scene.has_node("Model/Hat"), "Employee has Hat on Head")
	_assert(emp_scene.has_node("Model/Apron"), "Employee has Model/Apron")
	_assert(emp_scene.has_node("Model/Badge"), "Employee has Model/Badge")
	emp_scene.free()

	# --------------------------------------------------------
	# 12. MAIN SCENE
	# --------------------------------------------------------
	_section("Main scene architecture and signage")
	var main_scene = load("res://src/main.tscn").instantiate()
	_assert(main_scene.has_node("Room"), "main.tscn has Room")
	_assert(main_scene.has_node("Room/FloorDining"), "main.tscn has FloorDining")
	_assert(main_scene.has_node("Room/FloorKitchen"), "main.tscn has FloorKitchen")
	_assert(main_scene.has_node("Room/WallNorth"), "main.tscn has WallNorth")
	_assert(main_scene.has_node("Room/NeonSign"), "main.tscn has NeonSign")
	_assert(main_scene.has_node("Room/MenuBoard"), "main.tscn has MenuBoard")
	_assert(main_scene.has_node("Player"), "main.tscn has Player")
	main_scene.queue_free()

	# --------------------------------------------------------
	# FINAL REPORT
	# --------------------------------------------------------
	print("\n============================================================")
	print("MASTER REGRESSION RESULTS")
	print("  PASS: " + str(total_pass))
	print("  FAIL: " + str(total_fail))
	print("============================================================")
	if total_fail == 0:
		print("ALL SYSTEMS PASS - BURGER RUSH REGRESSION SUITE GREEN!")
		quit(0)
	else:
		print("REGRESSION FAILURES DETECTED - review errors above")
		quit(1)