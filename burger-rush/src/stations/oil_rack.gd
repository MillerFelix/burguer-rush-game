class_name OilRack
extends StaticBody3D

# ================================================================
# PRATELEIRA METÁLICA DE ÓLEO DO ARMAZÉM
# ================================================================

@export var max_display_bottles: int = 4
var oil_item_scene: PackedScene = load("res://src/items/cooking_oil.tscn")

@onready var bottle_slots: Node3D = $BottleSlots
@onready var status_label: Label3D = get_node_or_null("StatusLabel")

func _ready() -> void:
	var inv = InventoryManager.get_instance()
	if inv and not inv.stock_changed.is_connected(_on_stock_changed):
		inv.stock_changed.connect(_on_stock_changed)
	_update_visuals()

func _on_stock_changed(item_id: String, _new_qty: int) -> void:
	if item_id == "cooking_oil":
		_update_visuals()

func _update_visuals() -> void:
	var inv = InventoryManager.get_instance()
	var stock = inv.get_stock("cooking_oil") if inv else 5

	if status_label:
		status_label.text = "🛢️ ÓLEO VEGETAL\nEstoque: %d un" % stock

	if bottle_slots:
		var visible_count = clampi(stock, 0, max_display_bottles)
		for i in range(max_display_bottles):
			var b = bottle_slots.get_node_or_null("Bottle%d" % i)
			if b:
				b.visible = (i < visible_count)

func interact_item(player: Node3D) -> void:
	if not player:
		return

	var inv = InventoryManager.get_instance()
	var is_large = player.has_method("is_holding_large_item") and player.is_holding_large_item()

	# Se mãos livres de itens grandes -> Pega galão de óleo da prateleira
	if not is_large:
		if inv and inv.consume_stock("cooking_oil", 1):
			var oil_bottle = oil_item_scene.instantiate() as CookingOil
			if player.is_inside_tree() and player.get_tree() and player.get_tree().root:
				player.get_tree().root.add_child(oil_bottle)
			elif is_inside_tree() and get_tree() and get_tree().root:
				get_tree().root.add_child(oil_bottle)
			elif player.get_parent():
				player.get_parent().add_child(oil_bottle)
			else:
				add_child(oil_bottle)
			if player.has_method("pick_up"):
				player.pick_up(oil_bottle)
			_show_feedback(player, "🛢️ Galão de Óleo de Cozinha pego do armazém!")
			_update_visuals()
		else:
			_show_feedback(player, "❌ Sem Galões de Óleo no estoque! Compre no computador.")
	else:
		_show_feedback(player, "⚠️ Mãos ocupadas! Solte antes de pegar o galão.")

# Clique Direito (RMB) — DEVOLVER 1 UNIDADE
func interact_return(player: Node3D) -> void:
	return_item(player)

func return_item(player: Node3D) -> void:
	var inv = InventoryManager.get_instance()
	var held = player.get("held_item") if player else null

	if held is CookingOil or (held != null and str(held.get("item_id")) == "cooking_oil"):
		var oil_item = player.take_held_item()
		if oil_item:
			oil_item.queue_free()
		if inv:
			inv.add_stock("cooking_oil", 1)
		_show_feedback(player, "📦 Devolveu 1x Galão de Óleo ao estoque!")
		_update_visuals()
		return
	elif player and player.has_method("has_matching_ingredient") and player.has_matching_ingredient("cooking_oil"):
		var returned = player.return_one_matching_ingredient("cooking_oil")
		if returned:
			if inv:
				inv.add_stock("cooking_oil", 1)
			_show_feedback(player, "📦 Devolveu 1x Galão de Óleo ao estoque!")
			_update_visuals()
			return

	_show_feedback(player, "⚠️ Armazenamento incompatível! Esta prateleira armazena Galões de Óleo.")

func interact_equipment(player: Node3D) -> void:
	interact_item(player)

func interact(player: Node3D) -> void:
	interact_item(player)

func get_interaction_prompt(player: Node = null) -> String:
	var inv = InventoryManager.get_instance()
	var stock = inv.get_stock("cooking_oil") if inv else 5
	var held = player.get("held_item") if player else null

	var prompt = ""
	if stock > 0:
		prompt = "🛢️ 🖱️ [Esq] Pegar Galão de Óleo (%d un.)" % stock
	else:
		prompt = "🔴 Sem Óleo no Estoque (Comprar no PC)"

	if held is CookingOil or (held != null and str(held.get("item_id")) == "cooking_oil") or (player and player.has_method("has_matching_ingredient") and player.has_matching_ingredient("cooking_oil")):
		prompt += " | 🖱️ [Dir] Devolver 1x"

	return prompt

func _show_feedback(player: Node3D, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback(message)
