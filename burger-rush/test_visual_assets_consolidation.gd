extends SceneTree

func _check_scene(scene_path, required_nodes):
	var packed = load(scene_path)
	if packed == null:
		push_error("Scene not found: " + scene_path)
		return false
	var inst = packed.instantiate()
	var ok = true
	for n in required_nodes:
		if not inst.has_node(n):
			push_error("[FAIL] " + scene_path.get_file() + " missing node: " + n)
			ok = false
	inst.queue_free()
	return ok

func _init():
	print("========== ETAPA 10 VISUAL ASSETS TESTS ==========")
	var all_passed = true

	var station_tests = [
		["res://src/stations/grill.tscn", ["Model/Cabinet","Model/GrillPlate","Model/SplashGuardBack","Model/Knob1","Model/Leg1","CookingSlot","StatusLabel"]],
		["res://src/stations/fryer.tscn", ["Model/Cabinet","Model/OilMesh","Model/BasketWire","Model/BasketHandle","FryerSlot","StatusLabel"]],
		["res://src/stations/drink_machine.tscn", ["Model/BaseCabinet","Model/Nozzle1","Model/Nozzle2","Model/Nozzle3","Model/DripTray","CupSlot","StatusLabel"]],
		["res://src/stations/prep_table.tscn", ["Model/TableTop","Model/GNPan1","Model/Leg1","ItemSlot","StatusLabel"]],
		["res://src/stations/packaging_station.tscn", ["Model/PaperRoll","Model/BoxStack","PackagingSlot","StatusLabel"]],
		["res://src/stations/restaurant_table.tscn", ["Model/TableTop","Model/TablePole","Model/Chair1","Model/Chair2","Seat","PlateSlot","StatusLabel"]],
		["res://src/stations/computer_station.tscn", ["Model/MonitorScreen","Model/Keyboard","StatusLabel"]],
		["res://src/stations/ingredient_dispenser.tscn", ["Model/ShelfStand","Model/StorageBin","Label3D"]],
		["res://src/stations/trash_bin.tscn", ["Model/CanBody","Model/Pedal","StatusLabel"]],
		["res://src/stations/receiving_area.tscn", ["Model/Beam1","Model/Plank1","CrateSpawnSlot","StatusLabel"]],
	]
	for entry in station_tests:
		var passed = _check_scene(entry[0], entry[1])
		if passed:
			print("[PASS] " + entry[0].get_file())
		else:
			all_passed = false

	var char_tests = [
		["res://src/customers/customer.tscn", ["Model/Head","Model/Hair","Model/Torso","Model/ArmLeft","Model/ArmRight","Model/LegLeft","Model/LegRight","Model/ShoeLeft","Model/ShoeRight"]],
		["res://src/employees/employee.tscn", ["Model/Head","Model/Hat","Model/Torso","Model/Apron","Model/Badge","Model/ArmLeft","Model/ArmRight"]],
	]
	for entry in char_tests:
		var passed = _check_scene(entry[0], entry[1])
		if passed:
			print("[PASS] " + entry[0].get_file())
		else:
			all_passed = false

	var main_scene = load("res://src/main.tscn").instantiate()
	if main_scene == null:
		push_error("FAIL: main.tscn not loaded")
		all_passed = false
	else:
		var room = main_scene.get_node_or_null("Room")
		if room == null:
			push_error("FAIL: Room node missing in main.tscn")
			all_passed = false
		else:
			for sig_node in ["NeonSign","MenuBoard"]:
				if room.has_node(sig_node):
					print("[PASS] main.tscn Room/" + sig_node)
				else:
					push_error("[FAIL] main.tscn Room/" + sig_node + " missing")
					all_passed = false
		main_scene.queue_free()

	print("========== SUMMARY ==========")
	if all_passed:
		print("ALL ETAPA 10 VISUAL TESTS PASSED!")
		quit(0)
	else:
		print("SOME TESTS FAILED")
		quit(1)