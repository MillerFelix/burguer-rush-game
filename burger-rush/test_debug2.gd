extends SceneTree

func _init() -> void:
	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var player = Node3D.new()
	root.add_child(player)

	var machine_scene = load("res://src/stations/drink_machine.tscn")
	var machine = machine_scene.instantiate() as DrinkMachine
	root.add_child(machine)
	machine._ready()

	var cup_scene = load("res://src/items/drink_cup.tscn")
	var cup = cup_scene.instantiate() as DrinkCup
	machine.cup_slot.add_child(cup)
	cup.set_state(DrinkCup.State.EMPTY)
	machine.current_cup = cup

	print("DEBUG START")
	print("  inv: ", inv)
	print("  InventoryManager.get_instance(): ", InventoryManager.get_instance())
	print("  player: ", player)
	print("  machine.current_cup: ", machine.current_cup)
	print("  machine.current_cup.state: ", machine.current_cup.state)
	print("  DrinkCup.State.EMPTY: ", DrinkCup.State.EMPTY)
	print("  machine.syrup_current: ", machine.syrup_current)

	machine.interact(player)

	print("  machine.is_filling: ", machine.is_filling)
	print("DEBUG END")
	quit(0)
