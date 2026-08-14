class_name Grill
extends StaticBody3D

@export var cook_time: float = 4.0
@export var burn_time: float = 5.0

@onready var cooking_slot: Node3D = $CookingSlot

var current_patty: Patty = null
var cooking_timer: float = 0.0

func _process(delta: float) -> void:
	if not current_patty:
		return

	cooking_timer += delta

	if cooking_timer >= cook_time + burn_time:
		if current_patty.state != Patty.State.BURNT:
			current_patty.set_state(Patty.State.BURNT)
	elif cooking_timer >= cook_time:
		if current_patty.state != Patty.State.COOKED:
			current_patty.set_state(Patty.State.COOKED)

func get_interaction_prompt(player: Node = null) -> String:
	if current_patty:
		if player and player.get("held_item") != null:
			return ""
		
		match current_patty.state:
			Patty.State.BURNT:
				return "E — Retirar Carne Queimada"
			Patty.State.COOKED:
				return "E — Retirar Carne Pronta"
			Patty.State.COOKING:
				return "E — Retirar Carne (Em Preparo)"
			_:
				return "E — Retirar Carne"

	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held is Patty or (held != null and held.get("item_id") == "patty"):
			if held.get("state") != Patty.State.BURNT:
				return "E — Colocar Carne na Chapa"

	return ""

func interact(player: Node3D) -> void:
	if current_patty:
		if player.get("held_item") == null:
			_remove_patty_to_player(player)
		return

	if player.get("held_item") != null:
		var held = player.get("held_item")
		if held is Patty or (held != null and held.get("item_id") == "patty"):
			if held.get("state") != Patty.State.BURNT and player.has_method("take_held_item"):
				var patty: Patty = player.take_held_item() as Patty
				if patty:
					place_patty(patty)

func place_patty(patty: Patty) -> void:
	current_patty = patty
	cooking_slot.add_child(patty)
	patty.position = Vector3.ZERO
	patty.rotation = Vector3.ZERO

	if patty.collision_shape:
		patty.collision_shape.disabled = true

	match patty.state:
		Patty.State.RAW:
			patty.set_state(Patty.State.COOKING)
			cooking_timer = 0.0
		Patty.State.COOKING:
			cooking_timer = 0.0
		Patty.State.COOKED:
			cooking_timer = cook_time
		Patty.State.BURNT:
			cooking_timer = cook_time + burn_time

func _remove_patty_to_player(player: Node3D) -> void:
	var patty := current_patty
	current_patty = null
	cooking_timer = 0.0
	cooking_slot.remove_child(patty)

	if player.has_method("pick_up"):
		player.pick_up(patty)
