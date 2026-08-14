class_name Grill
extends StaticBody3D

@export var cook_time: float = 4.0
@export var burn_time: float = 5.0

@onready var cooking_slot: Node3D = $CookingSlot
@onready var status_label: Label3D = $StatusLabel

var current_patty: Patty = null
var cooking_timer: float = 0.0
var dirt_level: float = 0.0 # 0.0 a 5.0+ (acima de 4.0 fica suja)

func _ready() -> void:
	_update_status_display()

func is_dirty() -> bool:
	return dirt_level >= 4.0

func get_effective_cook_time() -> float:
	return cook_time + (1.5 if is_dirty() else 0.0)

func _process(delta: float) -> void:
	if not current_patty:
		return

	cooking_timer += delta
	var eff_cook_time = get_effective_cook_time()

	if cooking_timer >= eff_cook_time + burn_time:
		if current_patty.state != Patty.State.BURNT:
			current_patty.set_state(Patty.State.BURNT)
	elif cooking_timer >= eff_cook_time:
		if current_patty.state != Patty.State.COOKED:
			current_patty.set_state(Patty.State.COOKED)

	_update_status_display()

func get_interaction_prompt(player: Node = null) -> String:
	# 1. Se houver carne na chapa
	if current_patty:
		if player and player.get("held_item") != null:
			return ""

		match current_patty.state:
			Patty.State.BURNT:
				return "E — Retirar Carne Queimada"
			Patty.State.COOKED:
				return "E — Retirar Carne Pronta"
			Patty.State.COOKING:
				var eff_cook = get_effective_cook_time()
				var pct = int(clampf((cooking_timer / eff_cook) * 100.0, 0.0, 99.0))
				return "E — Retirar Carne (Cozinhando %d%%)" % pct
			_:
				return "E — Retirar Carne"

	# 2. Se o jogador estiver segurando carne crua
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held is Patty or (held != null and str(held.get("item_id")) == "patty"):
			if held.get("state") != Patty.State.BURNT:
				return "E — Colocar Carne na Chapa"
		return ""

	# 3. Se a chapa estiver vazia e tiver gordura/sujeira
	if dirt_level > 0.0:
		var pct = int(clampf((dirt_level / 5.0) * 100.0, 10.0, 100.0))
		return "E — Raspar e Limpar Chapa (Gordura: %d%%)" % pct

	return ""

func interact(player: Node3D) -> void:
	# 1. Retirar carne
	if current_patty:
		if player.get("held_item") == null:
			_remove_patty_to_worker(player)
		return

	# 2. Colocar carne
	if player.get("held_item") != null:
		var held = player.get("held_item")
		if held is Patty or (held != null and str(held.get("item_id")) == "patty"):
			if held.get("state") != Patty.State.BURNT and player.has_method("take_held_item"):
				var patty: Patty = player.take_held_item() as Patty
				if patty:
					place_patty(patty)
		return

	# 3. Limpar chapa se vazia
	if dirt_level > 0.0:
		clean_grill(player)

func clean_grill(worker: Node3D = null) -> void:
	dirt_level = 0.0
	if worker:
		_show_feedback(worker, "✨ Chapa raspada e higienizada com sucesso!")
	_update_status_display()

func place_patty(patty: Patty) -> void:
	current_patty = patty
	cooking_slot.add_child(patty)
	patty.position = Vector3.ZERO
	patty.rotation = Vector3.ZERO

	if patty.collision_shape:
		patty.collision_shape.disabled = true

	var eff_cook_time = get_effective_cook_time()
	match patty.state:
		Patty.State.RAW:
			patty.set_state(Patty.State.COOKING)
			cooking_timer = 0.0
		Patty.State.COOKING:
			cooking_timer = 0.0
		Patty.State.COOKED:
			cooking_timer = eff_cook_time
		Patty.State.BURNT:
			cooking_timer = eff_cook_time + burn_time

	_update_status_display()

func _remove_patty_to_worker(worker: Node3D) -> void:
	var patty := current_patty
	current_patty = null
	cooking_timer = 0.0
	cooking_slot.remove_child(patty)

	# Acumula gordura e sujeira na chapa
	dirt_level = minf(6.0, dirt_level + 1.0)

	if worker.has_method("pick_up"):
		worker.pick_up(patty)

	_update_status_display()

func _update_status_display() -> void:
	if not status_label:
		return

	if not current_patty:
		if is_dirty():
			status_label.text = "🍳 CHAPA\n🔴 SUJA DE GORDURA\n[E] Raspar"
			status_label.modulate = Color(1.0, 0.4, 0.2, 1.0)
		elif dirt_level > 0.0:
			status_label.text = "🍳 CHAPA\n🟡 Gordura: %.0f%%\n[E] Limpar" % ((dirt_level / 5.0) * 100.0)
			status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
		else:
			status_label.text = "🍳 CHAPA LIVRE\n🟢 Limpa"
			status_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
		return

	var eff_cook = get_effective_cook_time()
	match current_patty.state:
		Patty.State.COOKING:
			var pct = int(clampf((cooking_timer / eff_cook) * 100.0, 0.0, 99.0))
			var dirty_txt = " (Gordura +1.5s)" if is_dirty() else ""
			status_label.text = "🟡 COZINHANDO... (%d%%)%s" % [pct, dirty_txt]
			status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
		Patty.State.COOKED:
			var time_left = maxf(0.0, (eff_cook + burn_time) - cooking_timer)
			status_label.text = "🟢 CARNE PRONTA!\n(Queima em %.1fs)" % time_left
			status_label.modulate = Color(0.3, 1.0, 0.4, 1.0)
		Patty.State.BURNT:
			status_label.text = "🔴 QUEIMADA!\n[E] Retirar"
			status_label.modulate = Color(1.0, 0.2, 0.2, 1.0)
		_:
			status_label.text = "CHAPA"
			status_label.modulate = Color.WHITE

func _show_feedback(worker: Node3D, message: String) -> void:
	var hud = worker.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
