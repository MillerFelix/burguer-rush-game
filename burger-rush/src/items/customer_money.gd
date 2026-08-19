class_name CustomerMoney
extends Item

@export var amount: float = 25.0
var customer_ref: Node = null
var is_customer_deposit_money: bool = true

func _ready() -> void:
	item_id = "customer_money"
	display_name = "Dinheiro (R$ %.2f)" % amount
	item_type = "currency"
	prompt_text = "Pegar Dinheiro (R$ %.2f)" % amount
	is_held = false
	collision_layer = 1
	collision_mask = 1

func setup(p_amount: float, p_customer: Node = null) -> void:
	amount = p_amount
	customer_ref = p_customer
	display_name = "Dinheiro (R$ %.2f)" % amount
	prompt_text = "Pegar Dinheiro (R$ %.2f)" % amount

func get_display_name() -> String:
	return "Dinheiro (R$ %.2f)" % amount

func get_interaction_prompt(player: Node = null) -> String:
	return "🖱️ / E — Pegar Dinheiro (R$ %.2f)" % amount

func interact_item(player: Node3D) -> void:
	interact(player)

func interact(player: Node3D) -> void:
	if not player:
		return
	if player.get("held_item") != null:
		var hud = player.get_node_or_null("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback("⚠️ Libere as mãos para pegar o dinheiro do cliente!")
		return

	if customer_ref and is_instance_valid(customer_ref):
		if customer_ref.has_method("on_money_picked_by_player"):
			customer_ref.on_money_picked_by_player()
		else:
			customer_ref.set("has_money_to_give", false)
			if customer_ref.has_method("_hide_hand_money"):
				customer_ref._hide_hand_money()

	if get_parent():
		get_parent().remove_child(self)

	var root_scene = player.get_tree().current_scene if (player.is_inside_tree() and player.get_tree()) else player.get_parent()
	if root_scene:
		root_scene.add_child(self)

	if player.has_method("pick_up"):
		player.pick_up(self)
	else:
		player.held_item = self

	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback("💵 Você pegou R$ %.2f do cliente. Deposite na gaveta do caixa!" % amount)
