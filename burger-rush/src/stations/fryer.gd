class_name Fryer
extends StaticBody3D

enum OilQuality {
	NEW,
	GOOD,
	USED,
	BAD
}

@export var cook_time: float = 4.0
@export var burn_time: float = 8.0

@onready var slot: Node3D = $FryerSlot
@onready var status_label: Label3D = $StatusLabel

var current_potato: Potato = null
var cooking_timer: float = 0.0
var oil_uses: int = 0

var fries_pack_scene: PackedScene = preload("res://src/items/fries_pack.tscn")

func _ready() -> void:
	_update_visual_status()

func get_oil_quality() -> OilQuality:
	if oil_uses < 4:
		return OilQuality.NEW
	elif oil_uses < 8:
		return OilQuality.GOOD
	elif oil_uses < 14:
		return OilQuality.USED
	else:
		return OilQuality.BAD

func get_oil_quality_name() -> String:
	match get_oil_quality():
		OilQuality.NEW:
			return "🟢 Novo"
		OilQuality.GOOD:
			return "🟢 Bom"
		OilQuality.USED:
			return "🟡 Usado"
		OilQuality.BAD:
			return "🔴 Saturado / Troca Necessária"
	return "Desconhecido"

func is_oil_bad() -> bool:
	return get_oil_quality() == OilQuality.BAD

func get_effective_cook_time() -> float:
	return cook_time + (2.0 if get_oil_quality() == OilQuality.BAD else 0.0)

func _process(delta: float) -> void:
	if current_potato:
		cooking_timer += delta
		var eff_cook = get_effective_cook_time()

		if cooking_timer >= burn_time:
			if current_potato.state != Potato.State.BURNT:
				current_potato.set_state(Potato.State.BURNT)
		elif cooking_timer >= eff_cook:
			if current_potato.state != Potato.State.COOKED:
				current_potato.set_state(Potato.State.COOKED)

		_update_visual_status()

func get_interaction_prompt(player: Node = null) -> String:
	# 1. Se houver batata na fritadeira
	if current_potato:
		match current_potato.state:
			Potato.State.COOKING:
				var eff_cook = get_effective_cook_time()
				var remain = maxf(0.0, eff_cook - cooking_timer)
				return "⏳ Fritando Batata... (%.1fs)" % remain
			Potato.State.COOKED:
				if player and player.get("held_item") != null:
					var held = player.get("held_item")
					if held is PotatoBoxItem or (held != null and str(held.get("item_id")) == "potato_box"):
						return "E — Colocar Batata no Recipiente"
					return ""

				var inv = InventoryManager.get_instance()
				var box_stock = inv.get_stock("potato_box") if inv else 0
				if box_stock > 0:
					return "E — Embalar Batata Frita (Consome 1 Recipiente)"
				else:
					return "🔴 Sem Recipientes de Batata! (Comprar no PC)"
			Potato.State.BURNT:
				return "E — Retirar Batata Queimada (Descartar no Lixo)"
			_:
				return ""

	# 2. Se a fritadeira estiver livre e o jogador segurar galão de óleo para troca
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held is CookingOil or (held != null and str(held.get("item_id")) == "cooking_oil"):
			return "E — Trocar Óleo da Fritadeira (%s)" % get_oil_quality_name()

		if held is Potato and held.state == Potato.State.RAW:
			return "E — Colocar Batata Crua na Fritadeira"

	# 3. Se a fritadeira estiver livre e o óleo estiver saturado/usado
	if oil_uses >= 8:
		return "E — Trocar Óleo da Fritadeira (%s)" % get_oil_quality_name()

	return ""

func interact(player: Node3D) -> void:
	var inv = InventoryManager.get_instance()

	# Caso haja batata na fritadeira
	if current_potato:
		if current_potato.state == Potato.State.COOKING:
			_show_feedback(player, "A batata ainda está fritando no óleo quente!")
			return

		var held = player.get("held_item")

		# Se o jogador estiver segurando o recipiente de batatas
		if held is PotatoBoxItem or (held != null and str(held.get("item_id")) == "potato_box"):
			if current_potato.state == Potato.State.COOKED and player.has_method("take_held_item") and player.has_method("pick_up"):
				var used_box = player.take_held_item()
				used_box.queue_free()

				current_potato.queue_free()
				current_potato = null
				oil_uses += 1

				var pack = fries_pack_scene.instantiate() as FriesPack
				player.get_tree().root.add_child(pack)
				player.pick_up(pack)
				_show_feedback(player, "🍟 Batata frita dourada colocada na embalagem!")
				_update_visual_status()
				return

		# Se as mãos do jogador estiverem livres
		if held == null and player.has_method("pick_up"):
			if current_potato.state == Potato.State.COOKED:
				if not inv or not inv.has_stock("potato_box", 1):
					_show_feedback(player, "❌ Sem recipientes de batata no estoque! Compre no computador.")
					return

				inv.consume_stock("potato_box", 1)
				current_potato.queue_free()
				current_potato = null
				oil_uses += 1

				var pack = fries_pack_scene.instantiate() as FriesPack
				player.get_tree().root.add_child(pack)
				player.pick_up(pack)
				_show_feedback(player, "🍟 Batata frita embalada com sucesso!")
				_update_visual_status()
				return

			elif current_potato.state == Potato.State.BURNT:
				var pot = current_potato
				current_potato = null
				slot.remove_child(pot)
				player.pick_up(pot)
				_show_feedback(player, "🗑️ Batata queimada retirada. Descarte na lixeira!")
				_update_visual_status()
				return
		return

	# Caso o jogador esteja segurando o galão de óleo para efetuar a troca
	var held_item = player.get("held_item")
	if held_item is CookingOil or (held_item != null and str(held_item.get("item_id")) == "cooking_oil"):
		if player.has_method("take_held_item"):
			var oil_bottle = player.take_held_item()
			oil_bottle.queue_free()
			change_oil(player)
			return

	# Caso o jogador aperte E na fritadeira para trocar óleo usando o estoque direto
	if oil_uses >= 8 and (held_item == null):
		if inv and inv.consume_stock("cooking_oil", 1):
			change_oil(player)
			return
		else:
			_show_feedback(player, "❌ Sem Galão de Óleo no estoque! Compre no computador.")
			return

	# Colocar batata crua
	if held_item is Potato and held_item.state == Potato.State.RAW:
		if player.has_method("take_held_item"):
			var pot = player.take_held_item() as Potato
			current_potato = pot
			slot.add_child(pot)
			pot.position = Vector3.ZERO
			pot.rotation = Vector3.ZERO
			pot.set_state(Potato.State.COOKING)
			cooking_timer = 0.0
			_show_feedback(player, "🔥 Batata colocada no óleo quente!")
			_update_visual_status()

func change_oil(worker: Node3D = null) -> void:
	oil_uses = 0
	if worker:
		_show_feedback(worker, "✨ Óleo da fritadeira renovado com sucesso! (100% Novo)")
	_update_visual_status()

func _update_visual_status() -> void:
	if not status_label:
		return

	var q_str = get_oil_quality_name()

	if not current_potato:
		if get_oil_quality() == OilQuality.BAD:
			status_label.text = "🍟 FRITADEIRA\n🔴 ÓLEO SATURADO\n[E] Trocar Óleo"
			status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
		else:
			status_label.text = "🍟 FRITADEIRA\nÓleo: %s\n🟢 Disponível" % q_str
			status_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
		return

	match current_potato.state:
		Potato.State.COOKING:
			var eff_cook = get_effective_cook_time()
			var remain = maxf(0.0, eff_cook - cooking_timer)
			status_label.text = "🍟 FRITADEIRA\n⏳ Fritando (%.1fs)\nÓleo: %s" % [remain, q_str]
			status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
		Potato.State.COOKED:
			status_label.text = "🍟 FRITADEIRA\n✨ CROCANTE E PRONTA!\n[E] Embalar"
			status_label.modulate = Color(0.3, 1.0, 0.5, 1.0)
		Potato.State.BURNT:
			status_label.text = "🍟 FRITADEIRA\n🔥 QUEIMADA!\n[E] Retirar p/ Lixeira"
			status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)

func _show_feedback(worker: Node3D, message: String) -> void:
	var hud = worker.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
