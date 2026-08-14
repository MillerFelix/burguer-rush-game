class_name DrinkMachine
extends StaticBody3D

@export var syrup_capacity: int = 50

@onready var cup_slot: Node3D = $CupSlot
@onready var status_label: Label3D = $StatusLabel

var syrup_current: int = 50
var current_cup: DrinkCup = null
var drink_cup_scene: PackedScene = preload("res://src/items/drink_cup.tscn")

var available_flavors: Array[String] = [
	"soda_cola",       # 0: Cola
	"soda_guarana",    # 1: Guaraná
	"soda_sprite",     # 2: Limão
	"soda_grape",      # 3: Uva
	"soda_cola_zero"   # 4: Cola Zero
]
var current_flavor_index: int = 0
var is_filling: bool = false
var fill_progress: float = 0.0

func _ready() -> void:
	syrup_current = syrup_capacity
	_update_label()

func _process(delta: float) -> void:
	if is_filling and current_cup:
		fill_progress += delta * 1.2 # Enche em ~0.8 segundo
		current_cup.fill_amount = clampf(fill_progress, 0.0, 1.0)
		current_cup._update_visuals()

		if fill_progress >= 1.0:
			is_filling = false
			current_cup.set_state(DrinkCup.State.FILLED)
			_update_label()

func get_current_flavor_id() -> String:
	return available_flavors[current_flavor_index]

func _get_flavor_name_by_index(idx: int) -> String:
	match available_flavors[idx]:
		"soda_cola":
			return "Cola"
		"soda_guarana":
			return "Guaraná"
		"soda_sprite":
			return "Limão"
		"soda_grape":
			return "Uva"
		"soda_cola_zero":
			return "Cola Zero"
	return "Refrigerante"

func get_current_flavor_name() -> String:
	return _get_flavor_name_by_index(current_flavor_index)

func get_aimed_flavor_index(player: Node = null) -> int:
	if not player:
		return current_flavor_index
	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if ray and ray is RayCast3D and ray.is_colliding():
		var col_pt = to_local(ray.get_collision_point())
		if col_pt.y >= 0.7:
			if col_pt.x < -0.42:
				return 0 # Cola
			elif col_pt.x < -0.14:
				return 1 # Guaraná
			elif col_pt.x < 0.14:
				return 2 # Limão
			elif col_pt.x < 0.42:
				return 3 # Uva
			else:
				return 4 # Cola Zero
	return current_flavor_index

func cycle_flavor(worker: Node3D = null) -> String:
	current_flavor_index = (current_flavor_index + 1) % available_flavors.size()
	var fname = get_current_flavor_name()
	if worker:
		_show_feedback(worker, "🥤 Sabor selecionado: %s" % fname)
	_update_label()
	return fname

func select_flavor_by_index(idx: int, worker: Node3D = null) -> String:
	current_flavor_index = clampi(idx, 0, available_flavors.size() - 1)
	var fname = get_current_flavor_name()
	if worker:
		_show_feedback(worker, "🥤 Sabor selecionado: %s" % fname)
	_update_label()
	return fname

func has_syrup() -> bool:
	return syrup_current > 0

func refill_syrup(amount: int = 50, worker: Node3D = null) -> int:
	var needed = syrup_capacity - syrup_current
	var added = mini(needed, amount)
	syrup_current += added
	if worker:
		_show_feedback(worker, "✨ Reservatório de Xarope abastecido! (%d/%d doses)" % [syrup_current, syrup_capacity])
	_update_label()
	return added

func get_interaction_prompt(player: Node = null) -> String:
	var aimed_idx = get_aimed_flavor_index(player)
	var aimed_flavor_name = _get_flavor_name_by_index(aimed_idx)

	# 1. Se houver copo na máquina
	if current_cup:
		if is_filling:
			return "⏳ Enchendo %s... (%d%%)" % [current_cup.get_flavor_display_name(), int(fill_progress * 100)]
		if player and player.get("held_item") != null:
			return ""
		match current_cup.state:
			DrinkCup.State.EMPTY:
				if not has_syrup():
					return "🔴 Reservatório Vazio! Abasteça a Máquina"
				return "E — Pressionar Alavanca e Servir %s" % aimed_flavor_name
			DrinkCup.State.FILLED:
				return "E — Colocar Tampa e Selar Bebida"
			DrinkCup.State.CLOSED:
				return "E — Pegar %s Pronto" % current_cup.get_flavor_display_name()

	# 2. Se o jogador estiver segurando o Galão de Xarope para abastecimento
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held is SodaSyrupBottle or (held != null and str(held.get("item_id")) == "syrup_soda"):
			return "E — Abastecer Reservatório de Xarope (+25 doses)"

		if held is DrinkCup and (held as DrinkCup).state != DrinkCup.State.CLOSED:
			return "E — Posicionar Copo no Bico (%s)" % aimed_flavor_name
		return ""

	# 3. Se o xarope estiver vazio ou baixo
	if syrup_current <= 5:
		return "E — Abastecer Xarope (%d/%d) | [F] Trocar Sabor: %s" % [syrup_current, syrup_capacity, aimed_flavor_name]

	var inv = InventoryManager.get_instance()
	if inv:
		if not inv.has_stock("cup_empty", 1):
			return "❌ Sem Copos Descartáveis no Estoque"
		if not has_syrup():
			return "🔴 Sem Xarope no Reservatório! (Abastecer)"
		return "E — Servir %s (Xarope: %d/%d) | [F] Trocar Sabor" % [aimed_flavor_name, syrup_current, syrup_capacity]

	return "E — Servir %s" % aimed_flavor_name

func interact(player: Node3D) -> void:
	var inv = InventoryManager.get_instance()
	if not inv:
		return

	# Sincroniza o sabor com a mira do jogador
	var aimed_idx = get_aimed_flavor_index(player)
	current_flavor_index = aimed_idx

	# 1. Abastecimento com Galão de Xarope segurado na mão
	var held_item = player.get("held_item") if player else null
	if held_item is SodaSyrupBottle or (held_item != null and str(held_item.get("item_id")) == "syrup_soda"):
		if player.has_method("take_held_item"):
			var bottle = player.take_held_item()
			bottle.queue_free()
			refill_syrup(syrup_capacity, player)
			return

	# 2. Abastecimento com as mãos vazias consumindo xarope do estoque
	if syrup_current < syrup_capacity and held_item == null and syrup_current <= 5:
		if inv.consume_stock("syrup_soda", 1):
			refill_syrup(syrup_capacity, player)
			return
		else:
			_show_feedback(player, "❌ Sem Galão de Xarope no estoque! Compre no computador.")
			return

	# 3. Retirar copo ou interagir com copo na máquina
	if current_cup:
		if is_filling:
			return
		if held_item == null:
			if current_cup.state == DrinkCup.State.CLOSED:
				var c = current_cup
				current_cup = null
				if cup_slot and c.get_parent() == cup_slot:
					cup_slot.remove_child(c)
				if player and player.has_method("pick_up"):
					player.pick_up(c)
				_show_feedback(player, "🥤 Refrigerante retirado da máquina!")
				_update_label()
				return
			elif current_cup.state == DrinkCup.State.FILLED:
				if not inv.has_stock("cup_lid", 1):
					_show_feedback(player, "❌ Sem tampas de copo no estoque! Compre no computador.")
					return
				inv.consume_stock("cup_lid", 1)
				current_cup.set_state(DrinkCup.State.CLOSED)
				_show_feedback(player, "✨ %s selado com tampa e canudo!" % current_cup.get_flavor_display_name())
				_update_label()
				return
			elif current_cup.state == DrinkCup.State.EMPTY:
				if not has_syrup():
					_show_feedback(player, "❌ Reservatório de xarope vazio! Abasteça a máquina primeiro.")
					return
				syrup_current -= 1
				current_cup.set_flavor(get_current_flavor_id())
				is_filling = true
				fill_progress = 0.0
				_show_feedback(player, "🥤 Enchendo copo com %s..." % get_current_flavor_name())
				_update_label()
				return

	# 4. Colocar copo do jogador na máquina
	if held_item is DrinkCup and (held_item as DrinkCup).state != DrinkCup.State.CLOSED and player and player.has_method("take_held_item"):
		var c = player.take_held_item() as DrinkCup
		current_cup = c
		if cup_slot:
			cup_slot.add_child(c)
		c.position = Vector3.ZERO
		c.rotation = Vector3.ZERO
		if c.has_method("on_placed_in_station"):
			c.on_placed_in_station()
		_update_label()
		return

	# 5. Preparação direta com a mão vazia
	if held_item == null and player and player.has_method("pick_up"):
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
		_show_feedback(player, "🥤 %s preparado e selado! (Xarope: %d/%d)" % [get_current_flavor_name(), syrup_current, syrup_capacity])
		_update_label()

func _update_label() -> void:
	if not status_label:
		return

	var inv = InventoryManager.get_instance()
	var cups = inv.get_stock("cup_empty") if inv else 0
	var flavor_name = get_current_flavor_name()

	if current_cup:
		if is_filling:
			status_label.text = "🥤 MÁQUINA DE REFRIGERANTES (5 SABORES)\n⏳ Enchendo %s... (%d%%)" % [current_cup.get_flavor_display_name(), int(fill_progress * 100)]
			status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
		elif current_cup.state == DrinkCup.State.FILLED:
			status_label.text = "🥤 MÁQUINA DE REFRIGERANTES\n✨ %s Cheio! [E] Selar" % current_cup.get_flavor_display_name()
			status_label.modulate = Color(0.3, 1.0, 0.5, 1.0)
		elif current_cup.state == DrinkCup.State.CLOSED:
			status_label.text = "🥤 MÁQUINA DE REFRIGERANTES\n✨ %s Pronto! [E] Pegar" % current_cup.get_flavor_display_name()
			status_label.modulate = Color(0.3, 1.0, 0.5, 1.0)
		else:
			status_label.text = "🥤 MÁQUINA DE REFRIGERANTES\n🟡 Copo Posicionado\n[E] Servir %s" % flavor_name
			status_label.modulate = Color(0.3, 0.8, 1.0, 1.0)
	else:
		if syrup_current <= 0:
			status_label.text = "🥤 MÁQUINA DE REFRIGERANTES\n🔴 SEM XAROPE!\n[E] Abastecer"
			status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
		elif cups <= 0:
			status_label.text = "🥤 MÁQUINA DE REFRIGERANTES\n🔴 SEM COPOS NO ESTOQUE"
			status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
		else:
			status_label.text = "🥤 MÁQUINA DE REFRIGERANTES (5 SABORES)\nSabor: %s | Xarope: %d/%d\n[E] Servir | [F] Trocar Sabor" % [flavor_name, syrup_current, syrup_capacity]
			status_label.modulate = Color(0.3, 0.8, 1.0, 1.0)

func _show_feedback(player: Node3D, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback(message)
