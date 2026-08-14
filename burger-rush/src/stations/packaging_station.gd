class_name PackagingStation
extends StaticBody3D

@onready var slot: Node3D = $PackagingSlot
@onready var status_label: Label3D = $StatusLabel

var packaged_item: Node3D = null

func _ready() -> void:
	var inv = InventoryManager.get_instance()
	if inv:
		inv.stock_changed.connect(_on_stock_changed)
	_update_status()

func get_interaction_prompt(player: Node = null) -> String:
	if packaged_item:
		var name_str = packaged_item.get_display_name() if packaged_item.has_method("get_display_name") else "Lanche"

		if player and player.get("held_item") != null:
			var held = player.get("held_item")
			if held is BurgerBox:
				return "E — Embalar %s na Caixa" % name_str
			return ""

		if packaged_item.get("is_packaged") == true:
			return "E — Pegar %s Embalado" % name_str
		else:
			var inv = InventoryManager.get_instance()
			var stock = inv.get_stock("burger_box") if inv else 0
			if stock > 0:
				return "E — Embalar %s com Caixa do Estoque" % name_str
			else:
				return "E — Pegar %s (Sem Embalagem)" % name_str

	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held.get("item_type") == "final_product" and held.get("item_id") != "fries" and held.get("item_id") != "soda":
			var name_str = held.get_display_name() if held.has_method("get_display_name") else "Lanche"
			return "E — Colocar %s na Bancada de Embalagem" % name_str
		elif held is BurgerBox:
			return "E — Colocar Caixa na Bancada"

	return ""

func interact(player: Node3D) -> void:
	var inv = InventoryManager.get_instance()

	# Caso haja item na bancada
	if packaged_item:
		var held = player.get("held_item")

		# Se o jogador estiver segurando a caixa de hambúrguer
		if held is BurgerBox:
			if player.has_method("take_held_item"):
				var box = player.take_held_item()
				box.queue_free()
				packaged_item.set("is_packaged", true)
				_show_feedback(player, "📦 %s embalado na caixa com sucesso!" % packaged_item.get_display_name())
				_update_status()
				return

		# Se o jogador estiver com as mãos livres
		if held == null and player.has_method("pick_up"):
			if packaged_item.get("is_packaged") != true:
				if inv and inv.has_stock("burger_box", 1):
					inv.consume_stock("burger_box", 1)
					packaged_item.set("is_packaged", true)
					_show_feedback(player, "📦 Caixa retirada do estoque e lanche embalado!")
				else:
					_show_feedback(player, "⚠️ Lanche retirado sem embalagem! Compre caixas no computador.")

			var item = packaged_item
			packaged_item = null
			slot.remove_child(item)
			player.pick_up(item)
			_update_status()
			return
		return

	# Caso a bancada esteja livre e o jogador coloque o lanche
	if player.get("held_item") != null:
		var held = player.get("held_item")
		if held.get("item_type") == "final_product" and held.get("item_id") != "fries" and held.get("item_id") != "soda":
			if player.has_method("take_held_item"):
				var item = player.take_held_item()
				packaged_item = item
				slot.add_child(item)
				item.position = Vector3.ZERO
				item.rotation = Vector3.ZERO
				if item.has_method("on_placed_in_station"):
					item.on_placed_in_station()
				_show_feedback(player, "🍔 %s colocado na bancada de embalagem." % item.get_display_name())
				_update_status()

func _on_stock_changed(item_id: String, _qty: int) -> void:
	if item_id == "burger_box":
		_update_status()

func _update_status() -> void:
	if not status_label:
		return

	var inv = InventoryManager.get_instance()
	var box_stock = inv.get_stock("burger_box") if inv else 0

	if packaged_item:
		var name_str = packaged_item.get_display_name() if packaged_item.has_method("get_display_name") else "Lanche"
		var pkg_status = "✨ EMBALADO" if packaged_item.get("is_packaged") == true else "🟡 Aguarda Caixa"
		status_label.text = "📦 EMBALAGEM\n%s\n(%s)" % [name_str, pkg_status]
		status_label.modulate = Color(0.3, 1.0, 0.5, 1.0) if packaged_item.get("is_packaged") == true else Color(1.0, 0.85, 0.2, 1.0)
	else:
		if box_stock <= 0:
			status_label.text = "📦 EMBALAGEM\n🔴 SEM CAIXAS!"
			status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
		else:
			status_label.text = "📦 EMBALAGEM\nCaixas em Estoque: %d" % box_stock
			status_label.modulate = Color(0.8, 0.8, 0.8, 1.0)

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
