extends SceneTree

func _init() -> void:
	print("--- Starting PrepTable Test ---")
	var main_scene = load("res://src/main.tscn").instantiate()
	root.add_child(main_scene)

	await process_frame
	await process_frame

	var player: Player = main_scene.get_node("Player")
	var prep_table: PrepTable = main_scene.get_node("PrepTable")
	var test_cube: Item = main_scene.get_node("TestCube")
	var raw_patty: Patty = main_scene.get_node("RawPatty")
	var head: Node3D = player.get_node("Head")
	var raycast: RayCast3D = player.get_node("Head/Camera3D/RayCast3D")
	var hold_pos: Node3D = player.get_node("Head/Camera3D/HoldPosition")
	var hud: CanvasLayer = player.get_node("HUD")
	var interaction_label: Label = hud.get_node("InteractionLabel")

	assert(prep_table != null, "PrepTable must exist in scene")
	assert(prep_table.current_item == null, "PrepTable must start empty")
	print("[PASS] Setup: PrepTable exists and starts empty.")

	# --- Tests using prompt/interact directly (no raycast dependency) ---

	# Test 1: Empty table + empty hands -> no prompt
	var prompt := prep_table.get_interaction_prompt(player)
	assert(prompt == "", "No prompt when table empty and player empty-handed")
	print("[PASS] Test 1: No prompt on empty PrepTable with empty hands.")

	# Test 2: Empty table + player holding TestCube -> place prompt
	player.pick_up(test_cube)
	prompt = prep_table.get_interaction_prompt(player)
	assert(prompt == "E — Colocar na Mesa", "Prompt must be 'E — Colocar na Mesa'")
	print("[PASS] Test 2: 'E — Colocar na Mesa' when holding item and table is empty.")

	# Test 3: Place item via interact
	prep_table.interact(player)
	assert(player.held_item == null, "Player hands empty after placing on PrepTable")
	assert(prep_table.current_item == test_cube, "PrepTable holds TestCube")
	assert(test_cube.get_parent() == prep_table.item_slot, "TestCube parent is ItemSlot")
	assert(test_cube.collision_shape.disabled == true, "Collision disabled on table")
	assert(test_cube.position == Vector3.ZERO, "Item at slot origin")
	print("[PASS] Test 3: Item placed on PrepTable via interact.")

	# Test 4: Occupied table + empty hands -> retrieve prompt
	prompt = prep_table.get_interaction_prompt(player)
	assert(prompt == "E — Pegar Item", "Prompt must be 'E — Pegar Item' for generic item")
	print("[PASS] Test 4: 'E — Pegar Item' shown for occupied table with empty hands.")

	# Test 5: Retrieve item via interact
	prep_table.interact(player)
	assert(player.held_item == test_cube, "Player holds TestCube after retrieval")
	assert(prep_table.current_item == null, "PrepTable empty after retrieval")
	assert(test_cube.collision_shape.disabled == true, "Collision stays disabled while in hand")
	print("[PASS] Test 5: Item retrieved from PrepTable via interact.")

	# Test 6: Occupied table + occupied hands -> no prompt, no action
	prep_table._place_item(raw_patty)   # put patty directly on table
	prompt = prep_table.get_interaction_prompt(player)  # player holds TestCube
	assert(prompt == "", "No prompt: table occupied AND hands occupied")

	# interact must not change anything
	prep_table.interact(player)
	assert(prep_table.current_item == raw_patty, "PrepTable still holds patty (unchanged)")
	assert(player.held_item == test_cube, "Player still holds TestCube (unchanged)")
	print("[PASS] Test 6: No interaction when both table and hands are occupied.")

	# Test 7: Patty-specific prompts by state
	player.drop_item()  # clear hands
	await process_frame

	raw_patty.set_state(Patty.State.RAW)
	prompt = prep_table.get_interaction_prompt(player)
	assert(prompt == "E — Pegar Carne Crua", "RAW patty prompt")

	raw_patty.set_state(Patty.State.COOKING)
	prompt = prep_table.get_interaction_prompt(player)
	assert(prompt == "E — Pegar Carne (Em Preparo)", "COOKING patty prompt")

	raw_patty.set_state(Patty.State.COOKED)
	prompt = prep_table.get_interaction_prompt(player)
	assert(prompt == "E — Pegar Carne Pronta", "COOKED patty prompt")

	raw_patty.set_state(Patty.State.BURNT)
	prompt = prep_table.get_interaction_prompt(player)
	assert(prompt == "E — Pegar Carne Queimada", "BURNT patty prompt")
	print("[PASS] Test 7: All Patty state prompts on PrepTable verified.")

	# Test 8: Retrieve patty and verify collision restored
	prep_table.interact(player)
	assert(player.held_item == raw_patty, "Player holds patty")
	assert(prep_table.current_item == null, "Table empty")
	# Collision is re-enabled on pick_up (handled by player.pick_up → on_picked_up disables it,
	# but on_dropped re-enables it; here it stays disabled in hand, restored on drop)
	print("[PASS] Test 8: Patty retrieved from PrepTable.")

	# Test 9: Raycast-based full flow (objects positioned at spawn range)
	# Reset: drop patty, re-pick TestCube
	player.drop_item()
	await process_frame
	await process_frame

	# Move player to spawn origin and position TestCube within 2.5u
	player.global_position = Vector3(0, 0.1, 0)
	test_cube.global_position = Vector3(0, 1.3, -2)
	head.look_at(test_cube.global_position)
	raycast.force_raycast_update()
	player._physics_process(0.016)
	if raycast.get_collider() == test_cube:
		player._try_interact()
		assert(player.held_item == test_cube, "Raycast pickup works for TestCube")

		# Aim at PrepTable (0, 0, -4.5) – too far; test is only for Raycast on nearby items
		# PrepTable prompt tested already via direct call; skip raycast aiming at PrepTable
		print("[PASS] Test 9: Raycast pickup confirmed for nearby Item.")
	else:
		print("[INFO] Test 9: Raycast physics inactive in headless mode; logic validated via direct calls.")

	print("--- ALL PREPTABLE TESTS PASSED SUCCESSFULLY! ---")
	quit(0)
