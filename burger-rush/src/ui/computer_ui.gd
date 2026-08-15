class_name ComputerUI
extends CanvasLayer

signal closed()

@onready var tab_container: TabContainer = $PanelContainer/VBox/TabContainer

# Visão Geral Labels
@onready var ov_day_time: Label = $"PanelContainer/VBox/TabContainer/Visão Geral/VBox/DayTimeLabel"
@onready var ov_money: Label = $"PanelContainer/VBox/TabContainer/Visão Geral/VBox/MoneyLabel"
@onready var ov_revenue: Label = $"PanelContainer/VBox/TabContainer/Visão Geral/VBox/StatsGrid/RevenueLabel"
@onready var ov_purchases: Label = $"PanelContainer/VBox/TabContainer/Visão Geral/VBox/StatsGrid/PurchasesLabel"
@onready var ov_waste: Label = $"PanelContainer/VBox/TabContainer/Visão Geral/VBox/StatsGrid/WasteLabel"
@onready var ov_profit: Label = $"PanelContainer/VBox/TabContainer/Visão Geral/VBox/StatsGrid/ProfitLabel"
@onready var ov_orders: Label = $"PanelContainer/VBox/TabContainer/Visão Geral/VBox/StatsGrid/OrdersLabel"
@onready var ov_rating: Label = $"PanelContainer/VBox/TabContainer/Visão Geral/VBox/StatsGrid/RatingLabel"
@onready var ov_alerts: Label = $"PanelContainer/VBox/TabContainer/Visão Geral/VBox/AlertsLabel"

# Estoque Container
@onready var stock_vbox: VBoxContainer = $PanelContainer/VBox/TabContainer/Estoque/Scroll/StockVBox

# Compras Container
@onready var purchase_scroll_vbox: VBoxContainer = $PanelContainer/VBox/TabContainer/Compras/VBox/Scroll/PurchasesVBox
@onready var purchase_feedback: Label = $PanelContainer/VBox/TabContainer/Compras/VBox/FeedbackLabel

# Cardápio Container
@onready var menu_scroll_vbox: VBoxContainer = $PanelContainer/VBox/TabContainer/Cardápio/VBox/Scroll/MenuVBox
@onready var menu_feedback: Label = $PanelContainer/VBox/TabContainer/Cardápio/VBox/FeedbackLabel

# Equipamentos Container
@onready var equipment_scroll_vbox: VBoxContainer = $PanelContainer/VBox/TabContainer/Equipamentos/VBox/Scroll/EquipmentVBox
@onready var equipment_feedback: Label = $PanelContainer/VBox/TabContainer/Equipamentos/VBox/FeedbackLabel

# Funcionários Container
@onready var emp_scroll_vbox: VBoxContainer = $PanelContainer/VBox/TabContainer/Funcionários/VBox/Scroll/EmployeesVBox
@onready var emp_feedback_label: Label = $PanelContainer/VBox/TabContainer/Funcionários/VBox/TopHBox/EmpFeedbackLabel

# Relatório Semanal Container
@onready var weekly_header_label: Label = $"PanelContainer/VBox/TabContainer/Relatório Semanal/VBox/WeeklyHeaderLabel"
@onready var weekly_content_label: Label = $"PanelContainer/VBox/TabContainer/Relatório Semanal/VBox/Scroll/WeeklyContentLabel"

# Avaliações Container
@onready var rep_header_label: Label = $PanelContainer/VBox/TabContainer/Avaliações/VBox/ReputationHeaderLabel
@onready var reviews_scroll_vbox: VBoxContainer = $PanelContainer/VBox/TabContainer/Avaliações/VBox/Scroll/ReviewsVBox

# Finanças UI
@onready var fin_summary_label: Label = $PanelContainer/VBox/TabContainer/Finanças/VBox/SummaryLabel
@onready var fin_transactions_label: Label = $PanelContainer/VBox/TabContainer/Finanças/VBox/Scroll/TransactionsLabel

var buy_quantities: Dictionary = {}

func _ready() -> void:
	visible = false

func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refresh_all_tabs()

func close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()

func refresh_all_tabs() -> void:
	_refresh_overview()
	_refresh_inventory()
	_refresh_purchases()
	_refresh_menu()
	_refresh_equipment()
	_refresh_employees()
	_refresh_weekly_report()
	_refresh_reviews()
	_refresh_finances()

# ==============================================================================
# 1. 🏠 VISÃO GERAL
# ==============================================================================
func _refresh_overview() -> void:
	var clock = GameClock.get_instance()
	var economy = EconomyManager.get_instance()
	var order_mgr = OrderManager.get_instance()
	var inv = InventoryManager.get_instance()
	var waste_mgr = WasteManager.get_instance()
	var rep_mgr = ReputationManager.get_instance()
	var emp_mgr = EmployeeManager.get_instance()

	if clock and ov_day_time:
		ov_day_time.text = "📅 DIA %d (%s)  |  ⏰ %s  |  Status: %s" % [clock.day_number, clock.get_weekday_name(), clock.get_formatted_time(), clock.get_state_string()]

	var rev = economy.get_daily_sales() if economy else 0.0
	var pur = economy.get_daily_purchases() if economy else 0.0
	var wst = waste_mgr.get_daily_waste_cost() if waste_mgr else 0.0
	var net = rev - pur - wst

	if economy and ov_money:
		ov_money.text = "💰 Caixa Disponível: $%.2f" % economy.get_money()
	if ov_revenue:
		ov_revenue.text = "💵 Vendas do Dia: $%.2f" % rev
	if ov_purchases:
		ov_purchases.text = "🛒 Gastos em Compras Hoje: $%.2f" % pur
	if ov_waste:
		ov_waste.text = "🗑️ Desperdício / Perdas Hoje: -$%.2f" % wst
		ov_waste.modulate = Color(1.0, 0.4, 0.4, 1) if wst > 0 else Color(0.8, 0.8, 0.8, 1)
	if ov_profit:
		ov_profit.text = "📈 Lucro do Dia: $%.2f" % net
		ov_profit.modulate = Color(0.3, 1.0, 0.4, 1) if net >= 0 else Color(1.0, 0.3, 0.3, 1)
	if order_mgr and ov_orders:
		ov_orders.text = "📋 Pedidos Concluídos: %d (Ativos: %d)" % [order_mgr.daily_completed_orders, order_mgr.get_active_orders().size()]
	if rep_mgr and ov_rating:
		ov_rating.text = "⭐ Avaliação Média: %s %.1f / 5.0" % [rep_mgr.get_stars_string(), rep_mgr.get_average_rating()]

	# Alertas Operacionais Inteligentes
	var alerts: Array[String] = []
	if inv:
		var low_stocks = inv.get_low_stock_alerts()
		for a in low_stocks:
			alerts.append("Estoque de %s" % a)

	var main_scene = get_tree().current_scene if get_tree() else null
	if main_scene:
		var grill = main_scene.get_node_or_null("Grill") as Grill
		if grill and grill.is_dirty():
			alerts.append("Chapa com excesso de gordura (limpeza necessária)")

		var fryer = main_scene.get_node_or_null("Fryer") as Fryer
		if fryer and fryer.is_oil_bad():
			alerts.append("Fritadeira precisa de troca de óleo urgente")

		var drink = main_scene.get_node_or_null("DrinkMachine") as DrinkMachine
		if drink and drink.syrup_current == 0:
			alerts.append("Máquina de refrigerante sem xarope")

	if emp_mgr and emp_mgr.get_employees().size() > 0:
		alerts.append("%d funcionário(s) contratado(s) em serviço" % emp_mgr.get_employees().size())

	if ov_alerts:
		if alerts.is_empty():
			ov_alerts.text = "🟢 Alertas Operacionais: Tudo funcionando normalmente."
			ov_alerts.modulate = Color(0.4, 1.0, 0.4, 1)
		else:
			ov_alerts.text = "⚠️ Alertas Importantes:\n• " + "\n• ".join(alerts)
			ov_alerts.modulate = Color(1.0, 0.85, 0.2, 1)

# ==============================================================================
# 2. 📦 ESTOQUE
# ==============================================================================
func _refresh_inventory() -> void:
	if not stock_vbox:
		return

	for child in stock_vbox.get_children():
		child.queue_free()

	var inv = InventoryManager.get_instance()
	if not inv:
		return

	for item in inv.get_all_items().values():
		var card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.15, 0.18, 0.23, 0.8)
		card_style.set_corner_radius_all(6)
		card.add_theme_stylebox_override("panel", card_style)

		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 8)
		card.add_child(margin)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 15)
		margin.add_child(hbox)

		var item_id_str: String = item.get("id", "")
		var icon = _get_item_icon(item_id_str)
		var name_lbl = Label.new()
		name_lbl.custom_minimum_size = Vector2(220, 0)
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.text = "%s %s" % [icon, item.get("display_name", item_id_str)]
		hbox.add_child(name_lbl)

		var qty: int = item.get("quantity", 0)
		var max_cap: int = item.get("max_capacity", 0)
		var reorder: int = item.get("reorder_level", 5)
		var qty_lbl = Label.new()
		qty_lbl.custom_minimum_size = Vector2(160, 0)
		qty_lbl.text = "Estoque: %d / %d un" % [qty, max_cap]
		hbox.add_child(qty_lbl)

		var cost_lbl = Label.new()
		cost_lbl.custom_minimum_size = Vector2(140, 0)
		cost_lbl.text = "Custo: $%.2f / un" % item.get("unit_cost", 0.0)
		hbox.add_child(cost_lbl)

		var status_lbl = Label.new()
		status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if qty <= 0:
			status_lbl.text = "🔴 ESGOTADO"
			status_lbl.modulate = Color(1.0, 0.3, 0.3, 1)
		elif qty <= reorder:
			status_lbl.text = "🟡 ESTOQUE BAIXO"
			status_lbl.modulate = Color(1.0, 0.8, 0.2, 1)
		else:
			status_lbl.text = "🟢 DISPONÍVEL"
			status_lbl.modulate = Color(0.3, 1.0, 0.4, 1)
		hbox.add_child(status_lbl)

		stock_vbox.add_child(card)

# ==============================================================================
# 3. 🛒 COMPRAS
# ==============================================================================
func _refresh_purchases() -> void:
	if not purchase_scroll_vbox:
		return

	for child in purchase_scroll_vbox.get_children():
		child.queue_free()

	var inv = InventoryManager.get_instance()
	var prog = ProgressionManager.get_instance()
	if not inv:
		return

	var categories = {
		"🍞 PADARIA": ["bread", "bread_bottom", "bread_top"],
		"🥩 CARNES": ["patty_beef", "patty_chicken"],
		"🧀 QUEIJOS": ["cheese_mozzarella", "cheese_cheddar", "cheese_prato"],
		"🥗 VEGETAIS": ["lettuce", "tomato", "onion", "red_onion", "pickle"],
		"🥓 EXTRAS": ["bacon", "egg"],
		"🥫 MOLHOS": ["sauce_ketchup", "sauce_mustard", "sauce_mayo", "sauce_special"],
		"🍟 BATATAS": ["potato_raw", "potato_box"],
		"🥤 BEBIDAS": ["syrup_soda", "cup_empty", "cup_lid"],
		"🛢️ MANUTENÇÃO": ["cooking_oil"]
	}

	for cat_title in categories.keys():
		var header = Label.new()
		header.add_theme_font_size_override("font_size", 16)
		header.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1))
		header.text = cat_title
		purchase_scroll_vbox.add_child(header)

		for item_id in categories[cat_title]:
			var item = inv.get_item(item_id)
			if not item:
				continue

			if not buy_quantities.has(item.id):
				buy_quantities[item.id] = 5

			var is_unlocked = prog.is_unlocked(item.id) if prog else true
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)

			var name_lbl = Label.new()
			name_lbl.custom_minimum_size = Vector2(180, 0)
			name_lbl.text = "%s %s" % [_get_item_icon(item.id), item.display_name]
			row.add_child(name_lbl)

			if not is_unlocked:
				var lock_lbl = Label.new()
				var cost = prog.get_unlock_cost(item.id) if prog else 0.0
				lock_lbl.text = "🔒 Bloqueado (Desbloqueie no Cardápio por $%.2f)" % cost
				lock_lbl.modulate = Color(0.7, 0.7, 0.7, 1)
				row.add_child(lock_lbl)
				purchase_scroll_vbox.add_child(row)
				continue

			var btn_m5 = Button.new()
			btn_m5.text = "-5"
			btn_m5.custom_minimum_size = Vector2(36, 0)
			btn_m5.pressed.connect(func(): _adjust_buy_qty(item.id, -5))
			row.add_child(btn_m5)

			var btn_m1 = Button.new()
			btn_m1.text = "-1"
			btn_m1.custom_minimum_size = Vector2(36, 0)
			btn_m1.pressed.connect(func(): _adjust_buy_qty(item.id, -1))
			row.add_child(btn_m1)

			var qty_lbl = Label.new()
			qty_lbl.custom_minimum_size = Vector2(65, 0)
			qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			qty_lbl.text = "Qtd: %d" % buy_quantities[item.id]
			row.add_child(qty_lbl)

			var btn_p1 = Button.new()
			btn_p1.text = "+1"
			btn_p1.custom_minimum_size = Vector2(36, 0)
			btn_p1.pressed.connect(func(): _adjust_buy_qty(item.id, 1))
			row.add_child(btn_p1)

			var btn_p5 = Button.new()
			btn_p5.text = "+5"
			btn_p5.custom_minimum_size = Vector2(36, 0)
			btn_p5.pressed.connect(func(): _adjust_buy_qty(item.id, 5))
			row.add_child(btn_p5)

			var cost_lbl = Label.new()
			cost_lbl.custom_minimum_size = Vector2(170, 0)
			cost_lbl.text = "Total: $%.2f ($%.2f/un)" % [buy_quantities[item.id] * item.unit_cost, item.unit_cost]
			row.add_child(cost_lbl)

			var btn_buy = Button.new()
			btn_buy.text = "Comprar %s" % item.display_name
			btn_buy.custom_minimum_size = Vector2(160, 0)
			var id_to_buy = item.id
			btn_buy.pressed.connect(func(): _execute_purchase(id_to_buy))
			row.add_child(btn_buy)

			purchase_scroll_vbox.add_child(row)

		var sep = HSeparator.new()
		purchase_scroll_vbox.add_child(sep)

func _adjust_buy_qty(id: String, delta: int) -> void:
	buy_quantities[id] = maxi(1, buy_quantities.get(id, 5) + delta)
	_refresh_purchases()

func _execute_purchase(id: String) -> void:
	var purchase_mgr = PurchaseManager.get_instance()
	if not purchase_mgr:
		return

	var qty = buy_quantities.get(id, 5)
	var res = purchase_mgr.buy_ingredient(id, qty)

	if purchase_feedback:
		purchase_feedback.text = res.get("message", "")
		if res.get("success", false):
			purchase_feedback.modulate = Color(0.4, 1.0, 0.4, 1)
		else:
			purchase_feedback.modulate = Color(1.0, 0.3, 0.3, 1)

	refresh_all_tabs()

# ==============================================================================
# 4. 🍔 CARDÁPIO
# ==============================================================================
func _refresh_menu() -> void:
	if not menu_scroll_vbox:
		return

	for child in menu_scroll_vbox.get_children():
		child.queue_free()

	var prog = ProgressionManager.get_instance()
	var recipes = RecipeDatabase.get_all_recipes()

	var available_recipes: Array[Recipe] = []
	var locked_recipes: Array[Recipe] = []

	for rec in recipes:
		if rec.id.ends_with("_upgrade"):
			continue
		if prog and not prog.is_unlocked(rec.id):
			locked_recipes.append(rec)
		else:
			available_recipes.append(rec)

	# 1. Receitas Disponíveis
	var avail_title = Label.new()
	avail_title.add_theme_font_size_override("font_size", 16)
	avail_title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 1))
	avail_title.text = "✅ RECEITAS DISPONÍVEIS NO CARDÁPIO:"
	menu_scroll_vbox.add_child(avail_title)

	for rec in available_recipes:
		var card = _create_recipe_card(rec, true)
		menu_scroll_vbox.add_child(card)

	var sep = HSeparator.new()
	menu_scroll_vbox.add_child(sep)

	# 2. Receitas Bloqueadas
	if not locked_recipes.is_empty():
		var lock_title = Label.new()
		lock_title.add_theme_font_size_override("font_size", 16)
		lock_title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2, 1))
		lock_title.text = "🔒 RECEITAS DISPONÍVEIS PARA DESBLOQUEIO:"
		menu_scroll_vbox.add_child(lock_title)

		for rec in locked_recipes:
			var card = _create_recipe_card(rec, false)
			menu_scroll_vbox.add_child(card)

func _create_recipe_card(rec: Recipe, is_unlocked: bool) -> PanelContainer:
	var card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.15, 0.18, 0.23, 0.8)
	card_style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", card_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var cat_icon = "🍔"
	match rec.category:
		"burger":
			cat_icon = "🍔"
		"fries":
			cat_icon = "🍟"
		"drink":
			cat_icon = "🥤"
		"combo":
			cat_icon = "🍔🍟🥤"

	var title = Label.new()
	title.add_theme_font_size_override("font_size", 15)
	title.text = "%s %s  |  Ingredientes: %s" % [cat_icon, rec.display_name, " + ".join(rec.required_ingredients)]
	vbox.add_child(title)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)

	if is_unlocked:
		var price_lbl = Label.new()
		price_lbl.custom_minimum_size = Vector2(180, 0)
		price_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 1))
		price_lbl.text = "Preço de Venda: $%.2f" % rec.base_price
		hbox.add_child(price_lbl)

		var btn_m1 = Button.new()
		btn_m1.text = "- $1"
		btn_m1.custom_minimum_size = Vector2(40, 0)
		var r_id = rec.id
		btn_m1.pressed.connect(func(): _adjust_recipe_price(r_id, -1.0))
		hbox.add_child(btn_m1)

		var btn_p1 = Button.new()
		btn_p1.text = "+ $1"
		btn_p1.custom_minimum_size = Vector2(40, 0)
		btn_p1.pressed.connect(func(): _adjust_recipe_price(r_id, 1.0))
		hbox.add_child(btn_p1)

		var cost_lbl = Label.new()
		cost_lbl.custom_minimum_size = Vector2(150, 0)
		cost_lbl.text = "Custo: $%.2f" % rec.calculate_cost()
		hbox.add_child(cost_lbl)

		var profit_lbl = Label.new()
		profit_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.2, 1))
		profit_lbl.text = "Margem: $%.2f" % rec.get_estimated_profit()
		hbox.add_child(profit_lbl)
	else:
		var prog = ProgressionManager.get_instance()
		var cost = prog.get_unlock_cost(rec.id) if prog else 0.0

		var btn_unlock = Button.new()
		btn_unlock.text = "🔓 Desbloquear Receita ($%.2f)" % cost
		btn_unlock.custom_minimum_size = Vector2(240, 0)
		var r_id = rec.id
		btn_unlock.pressed.connect(func(): _execute_unlock_recipe(r_id))
		hbox.add_child(btn_unlock)

	return card

func _execute_unlock_recipe(recipe_id: String) -> void:
	var prog = ProgressionManager.get_instance()
	if not prog:
		return

	var res = prog.unlock_with_money(recipe_id)
	if menu_feedback:
		menu_feedback.text = res.get("message", "")
		if res.get("success", false):
			menu_feedback.modulate = Color(0.4, 1.0, 0.4, 1)
		else:
			menu_feedback.modulate = Color(1.0, 0.3, 0.3, 1)

	refresh_all_tabs()

func _adjust_recipe_price(id: String, delta: float) -> void:
	var rec = RecipeDatabase.get_recipe_by_id(id)
	if rec:
		var new_price = maxf(1.0, rec.base_price + delta)
		RecipeDatabase.update_recipe_price(id, new_price)
		_refresh_menu()

# ==============================================================================
# 5. ⚙️ EQUIPAMENTOS
# ==============================================================================
func _refresh_equipment() -> void:
	if not equipment_scroll_vbox:
		return

	for child in equipment_scroll_vbox.get_children():
		child.queue_free()

	# 1. Diagnóstico Operacional
	var diag_title = Label.new()
	diag_title.add_theme_font_size_override("font_size", 16)
	diag_title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1))
	diag_title.text = "📊 DIAGNÓSTICO DOS EQUIPAMENTOS ATIVOS:"
	equipment_scroll_vbox.add_child(diag_title)

	var main_scene = get_tree().current_scene if get_tree() else null
	if main_scene:
		var grill = main_scene.get_node_or_null("Grill") as Grill
		if grill:
			var g_lbl = Label.new()
			var pct = int((grill.dirt_level / 5.0) * 100.0)
			var status_str = "🔴 Precisa Limpeza" if grill.is_dirty() else ("🟡 Gordura: %d%%" % pct if grill.dirt_level > 0 else "🟢 Limpa")
			g_lbl.text = "🍳 Chapa Principal: %s (Gordura acumulada: %d%%)" % [status_str, pct]
			equipment_scroll_vbox.add_child(g_lbl)

		var fryer = main_scene.get_node_or_null("Fryer") as Fryer
		if fryer:
			var f_lbl = Label.new()
			var q_name = fryer.get_oil_quality_name()
			f_lbl.text = "🍟 Fritadeira: Óleo %s (%d usos realizados)" % [q_name, fryer.oil_uses]
			equipment_scroll_vbox.add_child(f_lbl)

		var drink = main_scene.get_node_or_null("DrinkMachine") as DrinkMachine
		if drink:
			var d_lbl = Label.new()
			var pct = int((float(drink.syrup_current) / float(drink.syrup_capacity)) * 100.0)
			d_lbl.text = "🥤 Máquina de Bebidas: Xarope %d/%d doses (%d%%)" % [drink.syrup_current, drink.syrup_capacity, pct]
			equipment_scroll_vbox.add_child(d_lbl)

	var sep = HSeparator.new()
	equipment_scroll_vbox.add_child(sep)

	# 2. Catálogo de Expansão
	var cat_title = Label.new()
	cat_title.add_theme_font_size_override("font_size", 16)
	cat_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1))
	cat_title.text = "🛒 EXPANSÃO FÍSICA E NOVOS EQUIPAMENTOS:"
	equipment_scroll_vbox.add_child(cat_title)

	var equip_mgr = EquipmentManager.get_instance()
	if not equip_mgr:
		return

	for equip in equip_mgr.get_all_equipment():
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var name_lbl = Label.new()
		name_lbl.custom_minimum_size = Vector2(250, 0)
		name_lbl.text = "🔧 %s" % equip.get("name", "Equipamento")
		row.add_child(name_lbl)

		if equip.get("installed", false):
			var inst_lbl = Label.new()
			inst_lbl.text = "🟢 INSTALADO E ATIVO"
			inst_lbl.modulate = Color(0.3, 1.0, 0.4, 1)
			row.add_child(inst_lbl)
		else:
			var cost_lbl = Label.new()
			cost_lbl.custom_minimum_size = Vector2(100, 0)
			cost_lbl.text = "$%.2f" % equip.get("cost", 100.0)
			row.add_child(cost_lbl)

			var btn_buy = Button.new()
			btn_buy.text = "Comprar e Instalar"
			btn_buy.custom_minimum_size = Vector2(160, 0)
			var equip_id = equip.get("id", "")
			btn_buy.pressed.connect(func(): _execute_buy_equipment(equip_id))
			row.add_child(btn_buy)

		equipment_scroll_vbox.add_child(row)

func _execute_buy_equipment(equipment_id: String) -> void:
	var equip_mgr = EquipmentManager.get_instance()
	if not equip_mgr:
		return

	var res = equip_mgr.purchase_equipment(equipment_id)
	if equipment_feedback:
		equipment_feedback.text = res.get("message", "")
		if res.get("success", false):
			equipment_feedback.modulate = Color(0.4, 1.0, 0.4, 1)
		else:
			equipment_feedback.modulate = Color(1.0, 0.3, 0.3, 1)

	refresh_all_tabs()

# ==============================================================================
# 6. 👥 FUNCIONÁRIOS
# ==============================================================================
func _refresh_employees() -> void:
	if not emp_scroll_vbox:
		return

	for child in emp_scroll_vbox.get_children():
		child.queue_free()

	var emp_mgr = EmployeeManager.get_instance()
	if not emp_mgr:
		return

	var list = emp_mgr.get_employees()
	if list.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Nenhum funcionário contratado no momento. Contrate para automatizar a cozinha e o salão!"
		empty_lbl.modulate = Color(0.7, 0.7, 0.7, 1)
		emp_scroll_vbox.add_child(empty_lbl)
		return

	for emp in list:
		var card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.15, 0.18, 0.23, 0.8)
		card_style.set_corner_radius_all(6)
		card.add_theme_stylebox_override("panel", card_style)

		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 8)
		card.add_child(margin)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		margin.add_child(hbox)

		var info_lbl = Label.new()
		info_lbl.custom_minimum_size = Vector2(240, 0)
		info_lbl.text = "👤 %s\nSalário: $%.2f/sem | Tarefas: %d" % [emp.employee_name, emp.weekly_salary, emp.tasks_completed_this_week]
		hbox.add_child(info_lbl)

		var role_lbl = Label.new()
		role_lbl.custom_minimum_size = Vector2(130, 0)
		role_lbl.text = "Função: %s" % emp.get_role_name()
		hbox.add_child(role_lbl)

		var btn_grill = Button.new()
		btn_grill.text = "🍳 Chapa"
		var emp_id = emp.employee_id
		btn_grill.pressed.connect(func(): _change_emp_role(emp_id, Employee.Role.GRILL))
		hbox.add_child(btn_grill)

		var btn_att = Button.new()
		btn_att.text = "📝 Atendimento"
		btn_att.pressed.connect(func(): _change_emp_role(emp_id, Employee.Role.ATTENDANT))
		hbox.add_child(btn_att)

		var btn_clean = Button.new()
		btn_clean.text = "🧹 Limpeza"
		btn_clean.pressed.connect(func(): _change_emp_role(emp_id, Employee.Role.CLEANER))
		hbox.add_child(btn_clean)

		var btn_fire = Button.new()
		btn_fire.text = "❌ Demitir"
		btn_fire.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1))
		btn_fire.pressed.connect(func(): _fire_emp(emp_id))
		hbox.add_child(btn_fire)

		emp_scroll_vbox.add_child(card)

func _on_hire_button_pressed() -> void:
	var emp_mgr = EmployeeManager.get_instance()
	if not emp_mgr:
		return

	var res = emp_mgr.hire_employee("", Employee.Role.GRILL)
	if emp_feedback_label:
		emp_feedback_label.text = res.get("message", "")
		if res.get("success", false):
			emp_feedback_label.modulate = Color(0.4, 1.0, 0.4, 1)
		else:
			emp_feedback_label.modulate = Color(1.0, 0.3, 0.3, 1)

	refresh_all_tabs()

func _change_emp_role(emp_id: int, new_role: Employee.Role) -> void:
	var emp_mgr = EmployeeManager.get_instance()
	if emp_mgr:
		emp_mgr.set_employee_role(emp_id, new_role)
		refresh_all_tabs()

func _fire_emp(emp_id: int) -> void:
	var emp_mgr = EmployeeManager.get_instance()
	if emp_mgr:
		emp_mgr.fire_employee(emp_id)
		refresh_all_tabs()

# ==============================================================================
# 7. ⭐ AVALIAÇÕES
# ==============================================================================
func _refresh_reviews() -> void:
	if not reviews_scroll_vbox:
		return

	for child in reviews_scroll_vbox.get_children():
		child.queue_free()

	var rep_mgr = ReputationManager.get_instance()
	if not rep_mgr:
		return

	var avg = rep_mgr.get_average_rating()
	var rev_list = rep_mgr.get_reviews()

	if rep_header_label:
		rep_header_label.text = "⭐ SATISFAÇÃO GERAL: %s %.1f / 5.0 (%d avaliações)" % [rep_mgr.get_stars_string(), avg, rev_list.size()]

	if rev_list.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Nenhuma avaliação recebida ainda. Atenda os clientes no salão para gerar avaliações!"
		empty_lbl.modulate = Color(0.7, 0.7, 0.7, 1)
		reviews_scroll_vbox.add_child(empty_lbl)
		return

	var start_idx = maxi(0, rev_list.size() - 10)
	for i in range(rev_list.size() - 1, start_idx - 1, -1):
		var rev: CustomerReview = rev_list[i]
		var card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.15, 0.18, 0.23, 0.8)
		card_style.set_corner_radius_all(6)
		card.add_theme_stylebox_override("panel", card_style)

		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 6)
		card.add_child(margin)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		margin.add_child(vbox)

		var title = Label.new()
		title.text = "[Dia %d %s] Cliente #%03d — %s (%.1f/5.0)" % [rev.day, rev.time_string, rev.customer_id, rev.get_formatted_stars(), rev.stars]
		title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1))
		vbox.add_child(title)

		var comment_lbl = Label.new()
		comment_lbl.text = "💬 \"%s\"" % rev.comment
		vbox.add_child(comment_lbl)

		if rev.order_summary != "":
			var order_lbl = Label.new()
			order_lbl.text = "🍔 Consumiu: %s" % rev.order_summary
			order_lbl.modulate = Color(0.6, 0.8, 1.0, 1)
			vbox.add_child(order_lbl)

		reviews_scroll_vbox.add_child(card)

# ==============================================================================
# 8. 💰 RELATÓRIO SEMANAL
# ==============================================================================
func _refresh_weekly_report() -> void:
	var weekly_mgr = WeeklyReportManager.get_instance()
	if not weekly_mgr or not weekly_content_label:
		return

	var rep = weekly_mgr.get_latest_report()
	if not rep:
		weekly_content_label.text = "Nenhum fechamento semanal ocorrido ainda.\nO fechamento semanal ocorre automaticamente todo Domingo às 18:00."
		return

	if weekly_header_label:
		weekly_header_label.text = "📊 RELATÓRIO DE FECHAMENTO — SEMANA #%d" % rep.week_number

	var text = "================================================================================\n"
	text += "📅 FECHAMENTO DA SEMANA #%d (Segunda-feira → Domingo)\n" % rep.week_number
	text += "================================================================================\n\n"
	text += "💰 RESUMO FINANCEIRO:\n"
	text += "  • Saldo Inicial da Semana:    $%.2f\n" % rep.starting_balance
	text += "  • Saldo Final da Semana:      $%.2f\n" % rep.ending_balance
	text += "  • Receita Bruta de Vendas:   +$%.2f\n" % rep.total_sales
	text += "  • Gastos em Compras:         -$%.2f\n" % rep.total_purchases
	text += "  • Perdas por Desperdício:    -$%.2f\n" % rep.total_waste
	text += "  • Folha Salarial Paga:       -$%.2f\n" % rep.total_salaries
	text += "  ------------------------------------------------------------------------------\n"
	text += "  📈 LUCRO LÍQUIDO SEMANAL:     $%.2f\n\n" % rep.net_profit

	text += "📋 RESUMO OPERACIONAL:\n"
	text += "  • Pedidos Concluídos:         %d\n" % rep.orders_completed
	text += "  • Clientes Atendidos:         %d\n" % rep.customers_served
	text += "  • Satisfação Média:           %.1f / 5.0 ⭐\n\n" % rep.avg_satisfaction

	if not rep.employees_summary.is_empty():
		text += "👥 DESEMPENHO DOS FUNCIONÁRIOS:\n"
		for emp in rep.employees_summary:
			text += "  • %-12s | %-16s | Salário Pago: $%.2f | Tarefas: %d\n" % [emp.get("name", ""), emp.get("role", ""), emp.get("salary", 0.0), emp.get("tasks_completed", 0)]

	weekly_content_label.text = text

# ==============================================================================
# 9. 📊 FINANÇAS
# ==============================================================================
func _refresh_finances() -> void:
	var economy = EconomyManager.get_instance()
	var waste_mgr = WasteManager.get_instance()
	if not economy:
		return

	var w_loss = waste_mgr.get_daily_waste_cost() if waste_mgr else 0.0

	if fin_summary_label:
		fin_summary_label.text = "💰 Saldo Atual: $%.2f  |  💵 Vendas Hoje: $%.2f  |  🛒 Compras: $%.2f  |  🗑️ Desperdício: -$%.2f  |  📈 Lucro: $%.2f" % [
			economy.get_money(),
			economy.get_daily_sales(),
			economy.get_daily_purchases(),
			w_loss,
			economy.get_daily_net() - w_loss
		]

	if fin_transactions_label:
		var txs = economy.get_transactions()
		if txs.is_empty():
			fin_transactions_label.text = "Nenhuma transação registrada nesta sessão."
		else:
			var text = "EXTRATO RECENTE DE TRANSAÇÕES:\n"
			var start_idx = maxi(0, txs.size() - 15)
			for i in range(txs.size() - 1, start_idx - 1, -1):
				var t: Transaction = txs[i]
				var sign_str = "+" if t.type == Transaction.Type.SALE else "-"
				text += "[Dia %d %s] %-8s | %-36s | %s$%.2f\n" % [t.day, t.time_string, t.get_type_string(), t.description, sign_str, t.amount]
			fin_transactions_label.text = text

func _get_item_icon(item_id: String) -> String:
	match item_id:
		# Padaria
		"bread", "bread_bottom", "bread_top":
			return "🍞"
		# Carnes
		"patty_beef", "patty":
			return "🥩"
		"patty_chicken":
			return "🍗"
		# Queijos
		"cheese_cheddar", "cheese":
			return "🧀"
		"cheese_mozzarella":
			return "🧀"
		"cheese_prato":
			return "🧀"
		# Vegetais
		"lettuce":
			return "🥬"
		"tomato":
			return "🍅"
		"onion":
			return "🧅"
		"red_onion":
			return "🧅"
		"pickle":
			return "🥒"
		# Extras
		"bacon":
			return "🥓"
		"egg":
			return "🥚"
		# Molhos
		"sauce_ketchup", "sauce":
			return "🥫"
		"sauce_mustard":
			return "🥫"
		"sauce_mayo":
			return "🥫"
		"sauce_special":
			return "⭐"
		# Suprimentos
		"potato_raw":
			return "🥔"
		"potato_box":
			return "🍟"
		"burger_box":
			return "📦"
		"cup_empty":
			return "🥤"
		"cup_lid":
			return "🫙"
		"syrup_soda":
			return "🥤"
		"cooking_oil":
			return "🛢️"
		_:
			return "📦"

func _on_close_button_pressed() -> void:
	close()
