class_name JuiceMachine
extends StaticBody3D

@export var juice_capacity: int = 50

@onready var cup_slot: Node3D = $CupSlot
@onready var status_label: Label3D = $StatusLabel
@onready var lever_1: Node3D = $Model/Lever1 if has_node("Model/Lever1") else null
@onready var lever_2: Node3D = $Model/Lever2 if has_node("Model/Lever2") else null
@onready var lever_3: Node3D = $Model/Lever3 if has_node("Model/Lever3") else null

var juice_current: int = 50
var current_cup: DrinkCup = null
var drink_cup_scene: PackedScene = preload("res://src/items/drink_cup.tscn")

var available_flavors: Array[String] = [
	"juice_orange",   # 0: Suco de Laranja
	"juice_grape",    # 1: Suco de Uva
	"juice_passion"   # 2: Suco de Maracujá
]
var current_flavor_index: int = 0
var is_filling: bool = false
var fill_progress: float = 0.0

func _ready() -> void:
	juice_current = juice_capacity
	_update_label()

func _process(delta: float) -> void:
	if is_filling and current_cup:
		fill_progress += delta * 1.2 # Enche em ~0.8s
		current_cup.fill_amount = clampf(fill_progress, 0.0, 1.0)
		current_cup._update_visuals()

		# Animação da alavanca inclinada para baixo
		_animate_active_lever(true)

		if fill_progress >= 1.0:
			is_filling = false
			_animate_active_lever(false)
			current_cup.set_state(DrinkCup.State.FILLED)
			_update_label()
	else:
		_animate_active_lever(false)

func _animate_active_lever(active: bool) -> void:
	var target_angle = deg_to_rad(28.0) if active else 0.0
	var active_lever = _get_lever_by_index(current_flavor_index)
	if active_lever:
		active_lever.rotation.x = lerp_angle(active_lever.rotation.x, target_angle, 0.25)

func _get_lever_by_index(idx: int) -> Node3D:
	match idx:
		0: return lever_1
		1: return lever_2
		2: return lever_3
	return null

func get_current_flavor_id() -> String:
	return available_flavors[current_flavor_index]

func _get_flavor_name_by_index(idx: int) -> String:
	match available_flavors[idx]:
		"juice_orange":
			return "Suco de Laranja"
		"juice_grape":
			return "Suco de Uva"
		"juice_passion":
			return "Suco de Maracujá"
	return "Suco Natural"

func get_current_flavor_name() -> String:
	return _get_flavor_name_by_index(current_flavor_index)

func get_aimed_flavor_index(player: Node = null) -> int:
	if not player:
		return current_flavor_index
	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if ray and ray is RayCast3D and ray.is_colliding():
		var col_pt = to_local(ray.get_collision_point())
		if col_pt.y >= 0.7:
			if col_pt.x < -0.2:
				return 0 # Laranja
			elif col_pt.x > 0.2:
				return 2 # Maracujá
			else:
				return 1 # Uva
	return current_flavor_index

func cycle_flavor(worker: Node3D = null) -> String:
	current_flavor_index = (current_flavor_index + 1) % available_flavors.size()
	var fname = get_current_flavor_name()
	if worker:
		_show_feedback(worker, "🍹 Suco selecionado: %s" % fname)
	_update_label()
	return fname

func select_flavor_by_index(idx: int, worker: Node3D = null) -> String:
	current_flavor_index = clampi(idx, 0, available_flavors.size() - 1)
	var fname = get_current_flavor_name()
	if worker:
		_show_feedback(worker, "🍹 Suco selecionado: %s" % fname)
	_update_label()
	return fname

func has_juice() -> bool:
	return juice_current > 0

func refill_juice(amount: int = 50, worker: Node3D = null) -> int:
	var needed = juice_capacity - juice_current
	var added = mini(needed, amount)
	juice_current += added
	if worker:
		_show_feedback(worker, "✨ Reservatório de Sucos abastecido! (%d/%d doses)" % [juice_current, juice_capacity])
	_update_label()
	return added

func get_interaction_prompt(player: Node = null) -> String:
	var aimed_idx = get_aimed_flavor_index(player)
	var aimed_flavor_name = _get_flavor_name_by_index(aimed_idx)

	# 1. Se houver copo na máquina
	if current_cup:
		if is_filling:
			return "⏳ Servindo %s... (%d%%)" % [current_cup.get_flavor_display_name(), int(fill_progress * 100)]
		if player and player.get("held_item") != null:
			return ""
		match current_cup.state:
			DrinkCup.State.EMPTY:
				if not has_juice():
					return "🔴 Reservatório Vazio! Abasteça a Máquina"
				return "E — Puxar Alavanca e Servir %s" % aimed_flavor_name
			DrinkCup.State.FILLED:
				return "E — Colocar Tampa e Selar Suco"
			DrinkCup.State.CLOSED:
				return "E — Pegar %s Pronto" % current_cup.get_flavor_display_name()

	# 2. Se o jogador estiver segurando copo
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held is DrinkCup and (held as DrinkCup).state != DrinkCup.State.CLOSED:
			return "E — Posicionar Copo sob a Torneira (%s)" % aimed_flavor_name
		return ""

	var inv = InventoryManager.get_instance()
	if inv:
		if not inv.has_stock("cup_empty", 1):
			return "❌ Sem Copos no Estoque"
		if not has_juice():
			return "🔴 Sem Suco no Reservatório!"
		return "E — Servir %s (Xarope: %d/%d) | [F] Trocar Sabor" % [aimed_flavor_name, juice_current, juice_capacity]

	return "E — Servir %s" % aimed_flavor_name

func interact(player: Node3D) -> void:
	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var aimed_idx = get_aimed_flavor_index(player)
	current_flavor_index = aimed_idx

	var held_item = player.get("held_item") if player else null

	# 1. Retirar copo ou interagir com copo na máquina
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
				_show_feedback(player, "🍹 Suco retirado da máquina!")
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
				if not has_juice():
					_show_feedback(player, "❌ Reservatório de suco vazio! Abasteça a máquina primeiro.")
					return
				juice_current -= 1
				current_cup.set_flavor(get_current_flavor_id())
				is_filling = true
				fill_progress = 0.0
				_show_feedback(player, "🍹 Puxando alavanca e enchendo copo com %s..." % get_current_flavor_name())
				_update_label()
				return

	# 2. Colocar copo do jogador na máquina
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

	# 3. Preparação direta com a mão vazia
	if held_item == null and player and player.has_method("pick_up"):
		if not has_juice():
			_show_feedback(player, "❌ Reservatório de suco vazio! Abasteça a máquina antes de servir.")
			return
		if not inv.has_stock("cup_empty", 1):
			_show_feedback(player, "❌ Sem copos no estoque! Compre no computador.")
			return
		if not inv.has_stock("cup_lid", 1):
			_show_feedback(player, "❌ Sem tampas de copo no estoque! Compre no computador.")
			return

		inv.consume_stock("cup_empty", 1)
		inv.consume_stock("cup_lid", 1)
		juice_current -= 1

		var drink = drink_cup_scene.instantiate() as DrinkCup
		drink.set_flavor(get_current_flavor_id())
		drink.state = DrinkCup.State.CLOSED
		player.get_tree().root.add_child(drink)
		player.pick_up(drink)
		_show_feedback(player, "🍹 %s preparado e selado! (Doses: %d/%d)" % [get_current_flavor_name(), juice_current, juice_capacity])
		_update_label()

func _update_label() -> void:
	if not status_label:
		return

	var inv = InventoryManager.get_instance()
	var cups = inv.get_stock("cup_empty") if inv else 0
	var flavor_name = get_current_flavor_name()

	if current_cup:
		if is_filling:
			status_label.text = "🍹 SUQUEIRA INDUSTRIAL (3 RESERVATÓRIOS)\n⏳ Servindo %s... (%d%%)" % [current_cup.get_flavor_display_name(), int(fill_progress * 100)]
			status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
		elif current_cup.state == DrinkCup.State.FILLED:
			status_label.text = "🍹 SUQUEIRA INDUSTRIAL\n✨ %s Cheio! [E] Selar" % current_cup.get_flavor_display_name()
			status_label.modulate = Color(0.3, 1.0, 0.5, 1.0)
		elif current_cup.state == DrinkCup.State.CLOSED:
			status_label.text = "🍹 SUQUEIRA INDUSTRIAL\n✨ %s Pronto! [E] Pegar" % current_cup.get_flavor_display_name()
			status_label.modulate = Color(0.3, 1.0, 0.5, 1.0)
		else:
			status_label.text = "🍹 SUQUEIRA INDUSTRIAL\n🟡 Copo Posicionado\n[E] Puxar Alavanca (%s)" % flavor_name
			status_label.modulate = Color(0.3, 0.8, 1.0, 1.0)
	else:
		if juice_current <= 0:
			status_label.text = "🍹 SUQUEIRA INDUSTRIAL\n🔴 RESERVATÓRIO VAZIO!"
			status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
		elif cups <= 0:
			status_label.text = "🍹 SUQUEIRA INDUSTRIAL\n🔴 SEM COPOS NO ESTOQUE"
			status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
		else:
			status_label.text = "🍹 SUQUEIRA INDUSTRIAL (3 SABORES)\nSabor: %s | Doses: %d/%d\n[E] Servir | [F] Trocar Sabor" % [flavor_name, juice_current, juice_capacity]
			status_label.modulate = Color(0.3, 0.8, 1.0, 1.0)

func _show_feedback(player: Node3D, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback(message)
