class_name DrinkMachine
extends StaticBody3D

@export var syrup_capacity: int = 15

@onready var cup_slot: Node3D = $CupSlot
@onready var status_label: Label3D = $StatusLabel

var syrup_current: int = 15
var current_cup: DrinkCup = null
var drink_cup_scene: PackedScene = preload("res://src/items/drink_cup.tscn")

var available_flavors: Array[String] = ["soda_cola", "soda_guarana", "soda_sprite"]
var current_flavor_index: int = 0

func _ready() -> void:
	syrup_current = syrup_capacity
	_update_label()

func get_current_flavor_id() -> String:
	return available_flavors[current_flavor_index]

func get_current_flavor_name() -> String:
	match get_current_flavor_id():
		"soda_cola":
			return "Cola"
		"soda_guarana":
			return "Guaraná"
		"soda_sprite":
			return "Limão"
	return "Refrigerante"

func cycle_flavor(worker: Node3D = null) -> String:
	current_flavor_index = (current_flavor_index + 1) % available_flavors.size()
	var fname = get_current_flavor_name()
	if worker:
		_show_feedback(worker, "🥤 Sabor selecionado: %s" % fname)
	_update_label()
	return fname

func has_syrup() -> bool:
	return syrup_current > 0

func refill_syrup(amount: int = 15, worker: Node3D = null) -> int:
	var needed = syrup_capacity - syrup_current
	var added = mini(needed, amount)
	syrup_current += added
	if worker:
		_show_feedback(worker, "✨ Reservatório de Xarope abastecido! (%d/%d doses)" % [syrup_current, syrup_capacity])
	_update_label()
	return added

func get_interaction_prompt(player: Node = null) -> String:
	var flavor_name = get_current_flavor_name()

	# 1. Se houver copo na máquina
	if current_cup:
		if player and player.get("held_item") != null:
			return ""
		match current_cup.state:
			DrinkCup.State.EMPTY:
				if not has_syrup():
					return "🔴 Reservatório Vazio! Abasteça a Máquina"
				return "E — Encher %s e Tampar" % flavor_name
			DrinkCup.State.FILLED:
				return "E — Colocar Tampa e Canudo"
			DrinkCup.State.CLOSED:
				return "E — Pegar %s" % current_cup.get_flavor_display_name()

	# 2. Se o jogador estiver segurando o Galão de Xarope para abastecimento
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held is SodaSyrupBottle or (held != null and str(held.get("item_id")) == "syrup_soda"):
			return "E — Abastecer Reservatório de Xarope (+10 doses)"

		if held is DrinkCup and (held as DrinkCup).state != DrinkCup.State.CLOSED:
			return "E — Colocar Copo na Máquina (Sabor: %s)" % flavor_name
		return ""

	# 3. Se o xarope estiver vazio ou baixo
	if syrup_current <= 3:
		return "E — Abastecer Xarope (%d/%d) | [F] Trocar Sabor: %s" % [syrup_current, syrup_capacity, flavor_name]

	var inv = InventoryManager.get_instance()
	if inv:
		if not inv.has_stock("cup_empty", 1):
			return "❌ Sem Copos Descartáveis no Estoque"
		if not has_syrup():
			return "🔴 Sem Xarope no Reservatório! (Abastecer)"
		if not inv.has_stock("cup_lid", 1):
			return "❌ Sem Tampas de Copo no Estoque"
		return "E — Servir %s (Xarope: %d/%d) | [F] Trocar Sabor" % [flavor_name, syrup_current, syrup_capacity]

	return "E — Servir %s" % flavor_name

func interact(player: Node3D) -> void:
	var inv = InventoryManager.get_instance()
	if not inv:
		return

	# 1. Abastecimento com Galão de Xarope segurado na mão
	var held_item = player.get("held_item")
	if held_item is SodaSyrupBottle or (held_item != null and str(held_item.get("item_id")) == "syrup_soda"):
		if player.has_method("take_held_item"):
			var bottle = player.take_held_item()
			bottle.queue_free()
			refill_syrup(syrup_capacity, player)
			return

	# 2. Abastecimento com as mãos vazias consumindo xarope do estoque
	if syrup_current < syrup_capacity and held_item == null and syrup_current <= 3:
		if inv.consume_stock("syrup_soda", 1):
			refill_syrup(syrup_capacity, player)
			return
		else:
			_show_feedback(player, "❌ Sem Galão de Xarope no estoque! Compre no computador.")
			return

	# 3. Retirar copo pronto da máquina
	if current_cup:
		if held_item == null and player.has_method("pick_up"):
			if current_cup.state == DrinkCup.State.CLOSED:
				var c = current_cup
				current_cup = null
				cup_slot.remove_child(c)
				player.pick_up(c)
				_show_feedback(player, "🥤 Refrigerante retirado da máquina!")
				_update_label()
				return
			elif current_cup.state == DrinkCup.State.EMPTY:
				if not has_syrup():
					_show_feedback(player, "❌ Reservatório de xarope vazio! Abasteça a máquina primeiro.")
					return
				if not inv.has_stock("cup_lid", 1):
					_show_feedback(player, "❌ Sem tampas de copo no estoque!")
					return
				syrup_current -= 1
				inv.consume_stock("cup_lid", 1)
				current_cup.set_flavor(get_current_flavor_id())
				current_cup.set_state(DrinkCup.State.CLOSED)
				_show_feedback(player, "🥤 %s cheio e tampado! (Xarope: %d/%d)" % [get_current_flavor_name(), syrup_current, syrup_capacity])
				_update_label()
				return

	# 4. Colocar copo do jogador na máquina
	if held_item is DrinkCup and (held_item as DrinkCup).state != DrinkCup.State.CLOSED and player.has_method("take_held_item"):
		var c = player.take_held_item() as DrinkCup
		current_cup = c
		cup_slot.add_child(c)
		c.position = Vector3.ZERO
		c.rotation = Vector3.ZERO
		if c.has_method("on_placed_in_station"):
			c.on_placed_in_station()
		_update_label()
		return

	# 5. Preparação direta com a mão vazia
	if held_item == null and player.has_method("pick_up"):
		if not has_syrup():
			_show_feedback(player, "❌ Reservatório de xarope vazio! Abasteça a máquina antes de servir.")
			return
		if not inv.has_stock("cup_empty", 1):
			_show_feedback(player, "❌ Sem copos no estoque! Compre no computador.")
			return
		if not inv.has_stock("cup_lid", 1):
			_show_feedback(player, "❌ Sem tampas de copo no estoque! Compre no computador.")
			return

		inv.consume_stock("cup_empty", 1)
		inv.consume_stock("cup_lid", 1)
		syrup_current -= 1

		var drink = drink_cup_scene.instantiate() as DrinkCup
		drink.set_flavor(get_current_flavor_id())
		drink.state = DrinkCup.State.CLOSED
		player.get_tree().root.add_child(drink)
		player.pick_up(drink)
		_show_feedback(player, "🥤 %s preparado e tampado! (Xarope: %d/%d)" % [get_current_flavor_name(), syrup_current, syrup_capacity])
		_update_label()

func _update_label() -> void:
	if not status_label:
		return

	var inv = InventoryManager.get_instance()
	var cups = inv.get_stock("cup_empty") if inv else 0
	var flavor_name = get_current_flavor_name()

	if current_cup:
		status_label.text = "🥤 MÁQUINA DE BEBIDAS\n✨ Copo no Bico (%s)\nXarope: %d/%d" % [flavor_name, syrup_current, syrup_capacity]
		status_label.modulate = Color(0.3, 1.0, 0.5, 1.0)
	else:
		if syrup_current <= 0:
			status_label.text = "🥤 MÁQUINA DE BEBIDAS\n🔴 SEM XAROPE!\n[E] Abastecer"
			status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
		elif cups <= 0:
			status_label.text = "🥤 MÁQUINA DE BEBIDAS\n🔴 SEM COPOS!"
			status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
		else:
			status_label.text = "🥤 MÁQUINA DE BEBIDAS\nSabor: %s | Xarope: %d/%d\n[F] Trocar Sabor" % [flavor_name, syrup_current, syrup_capacity]
			status_label.modulate = Color(0.3, 0.8, 1.0, 1.0)

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
