class_name ComputerUI
extends CanvasLayer

# =============================================================================
# BURGER RUSH - SISTEMA ADMINISTRATIVO DO RESTAURANTE (PC v2.0)
#
# Interface institucional moderna e fluida:
# - Header: Identidade Burger Rush, Relógio/Data real, Caixa em tempo real, Botão Fechar.
# - Sidebar: Menu lateral estruturado para todas as abas do sistema.
# - Aba 1: ESTOQUE GERAL (Conexão real com InventoryManager, filtros, busca, cards dinâmicos)
# - Aba 2: CENTRAL DE COMPRAS (Catálogo, mercado volátil, carrinho, fornecedores, entregas)
# =============================================================================

signal closed()

# Elementos do Header
@onready var header_date_label: Label = $MainPanel/OuterWindow/VBox/Header/HBox/DateLabel
@onready var header_time_label: Label = $MainPanel/OuterWindow/VBox/Header/HBox/TimeLabel
@onready var header_money_label: Label = $MainPanel/OuterWindow/VBox/Header/HBox/MoneyBadge/MoneyLabel
@onready var close_btn: Button = $MainPanel/OuterWindow/VBox/Header/HBox/CloseButton

# Sidebar / Abas
@onready var nav_buttons_container: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/Sidebar/VBox/NavScroll/NavButtons

# Área de Conteúdo
@onready var inventory_tab: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/InventoryTab
@onready var purchases_tab: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab
@onready var placeholder_tab: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/PlaceholderTab
@onready var placeholder_title: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/PlaceholderTab/TitleLabel
@onready var placeholder_desc: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/PlaceholderTab/DescLabel

# Elementos da Aba Estoque
@onready var stock_search_input: LineEdit = $MainPanel/OuterWindow/VBox/Body/ContentArea/InventoryTab/TopBar/HBox/SearchInput
@onready var stock_summary_label: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/InventoryTab/TopBar/HBox/SummaryLabel
@onready var filter_all_btn: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/InventoryTab/FilterBar/BtnAll
@onready var filter_ingredients_btn: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/InventoryTab/FilterBar/BtnIngredients
@onready var filter_drinks_btn: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/InventoryTab/FilterBar/BtnDrinks
@onready var filter_supplies_btn: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/InventoryTab/FilterBar/BtnSupplies
@onready var filter_others_btn: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/InventoryTab/FilterBar/BtnOthers
@onready var stock_cards_grid: GridContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/InventoryTab/Scroll/GridMargin/Grid

# Elementos da Aba Compras
@onready var purchases_search_input: LineEdit = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/TopBar/HBox/PurchasesSearchInput
@onready var market_status_label: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/TopBar/HBox/MarketStatusLabel
@onready var btn_buy_all: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/MainLayout/CatalogColumn/FilterBar/BtnBuyAll
@onready var btn_buy_ingredients: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/MainLayout/CatalogColumn/FilterBar/BtnBuyIngredients
@onready var btn_buy_fries: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/MainLayout/CatalogColumn/FilterBar/BtnBuyFries
@onready var btn_buy_drinks: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/MainLayout/CatalogColumn/FilterBar/BtnBuyDrinks
@onready var btn_buy_supplies: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/MainLayout/CatalogColumn/FilterBar/BtnBuySupplies
@onready var purchases_catalog_grid: GridContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/MainLayout/CatalogColumn/Scroll/GridMargin/CatalogGrid

@onready var clear_cart_btn: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/MainLayout/CartColumn/CartMargin/CartVBox/CartHeader/ClearCartBtn
@onready var cart_items_list: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/MainLayout/CartColumn/CartMargin/CartVBox/CartScroll/CartItemsList
@onready var supplier_option: OptionButton = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/MainLayout/CartColumn/CartMargin/CartVBox/SupplierOption
@onready var supplier_info_label: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/MainLayout/CartColumn/CartMargin/CartVBox/SupplierInfoLabel
@onready var cart_subtotal_val: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/MainLayout/CartColumn/CartMargin/CartVBox/TotalsBox/SubtotalHBox/CartSubtotalVal
@onready var cart_fee_val: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/MainLayout/CartColumn/CartMargin/CartVBox/TotalsBox/FeeHBox/CartFeeVal
@onready var cart_total_val: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/MainLayout/CartColumn/CartMargin/CartVBox/TotalsBox/TotalHBox/CartTotalVal
@onready var cart_feedback_label: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/MainLayout/CartColumn/CartMargin/CartVBox/FeedbackLabel
@onready var confirm_order_btn: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/MainLayout/CartColumn/CartMargin/CartVBox/ConfirmOrderBtn
@onready var deliveries_label: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/PurchasesTab/DeliveriesBar/DeliveriesPanel/DeliveriesLabel

enum TabID {
	INVENTORY,
	PURCHASES,
	EMPLOYEES,
	ORDERS,
	MENU,
	FINANCES,
	ENERGY,
	NEWS,
	EQUIPMENT,
	RECIPES,
	SETTINGS
}

var current_tab: TabID = TabID.INVENTORY
var current_filter: String = "ALL"
var current_search: String = ""

var current_buy_filter: String = "ALL"
var current_buy_search: String = ""

# Quantidades temporárias selecionadas nos cards antes de adicionar ao carrinho
var card_selected_quantities: Dictionary = {}

var nav_buttons_map: Dictionary = {}

func _ready() -> void:
	visible = false
	_setup_signals()
	_setup_navigation_sidebar()
	_setup_purchases_tab()

func _setup_signals() -> void:
	if close_btn:
		close_btn.pressed.connect(close)

	if stock_search_input:
		stock_search_input.text_changed.connect(_on_search_text_changed)

	if filter_all_btn: filter_all_btn.pressed.connect(func(): _set_category_filter("ALL"))
	if filter_ingredients_btn: filter_ingredients_btn.pressed.connect(func(): _set_category_filter("INGREDIENTS"))
	if filter_drinks_btn: filter_drinks_btn.pressed.connect(func(): _set_category_filter("DRINKS"))
	if filter_supplies_btn: filter_supplies_btn.pressed.connect(func(): _set_category_filter("SUPPLIES"))
	if filter_others_btn: filter_others_btn.pressed.connect(func(): _set_category_filter("OTHERS"))

	# Conecta ao InventoryManager
	var inv = InventoryManager.get_instance()
	if inv and not inv.stock_changed.is_connected(_on_stock_changed):
		inv.stock_changed.connect(_on_stock_changed)

	# Conecta ao PurchaseManager
	var pm = PurchaseManager.get_instance()
	if pm:
		if not pm.cart_updated.is_connected(_on_cart_updated):
			pm.cart_updated.connect(_on_cart_updated)
		if not pm.market_updated.is_connected(_on_market_updated):
			pm.market_updated.connect(_on_market_updated)
		if not pm.delivery_progress_updated.is_connected(_on_delivery_progress_updated):
			pm.delivery_progress_updated.connect(_on_delivery_progress_updated)
		if not pm.delivery_arrived.is_connected(_on_delivery_arrived):
			pm.delivery_arrived.connect(_on_delivery_arrived)

func _setup_purchases_tab() -> void:
	if purchases_search_input:
		purchases_search_input.text_changed.connect(_on_buy_search_text_changed)

	if btn_buy_all: btn_buy_all.pressed.connect(func(): _set_buy_category_filter("ALL"))
	if btn_buy_ingredients: btn_buy_ingredients.pressed.connect(func(): _set_buy_category_filter("INGREDIENTS"))
	if btn_buy_fries: btn_buy_fries.pressed.connect(func(): _set_buy_category_filter("FRIES"))
	if btn_buy_drinks: btn_buy_drinks.pressed.connect(func(): _set_buy_category_filter("DRINKS"))
	if btn_buy_supplies: btn_buy_supplies.pressed.connect(func(): _set_buy_category_filter("SUPPLIES"))

	if clear_cart_btn:
		clear_cart_btn.pressed.connect(_on_clear_cart_pressed)

	if confirm_order_btn:
		confirm_order_btn.pressed.connect(_on_confirm_order_pressed)

	if supplier_option:
		supplier_option.clear()
		supplier_option.add_item("🚚 Fornecedor Normal (Padrão)", 0)
		supplier_option.add_item("⚡ Fornecedor Rápido (Expresso)", 1)
		supplier_option.add_item("📦 Fornecedor Atacado (Econômico)", 2)
		supplier_option.item_selected.connect(_on_supplier_selected)

func _setup_navigation_sidebar() -> void:
	if not nav_buttons_container:
		return

	for child in nav_buttons_container.get_children():
		child.queue_free()
	nav_buttons_map.clear()

	var tabs_def = [
		{"id": TabID.INVENTORY, "icon": "📦", "title": "Estoque Geral", "active": true, "badge": ""},
		{"id": TabID.PURCHASES, "icon": "🛒", "title": "Central de Compras", "active": true, "badge": "NOVO"},
		{"id": TabID.EMPLOYEES, "icon": "👥", "title": "Funcionários", "active": false, "badge": "Em breve"},
		{"id": TabID.ORDERS, "icon": "📋", "title": "Histórico de Pedidos", "active": false, "badge": "Em breve"},
		{"id": TabID.MENU, "icon": "🍔", "title": "Cardápio & Preços", "active": false, "badge": "Em breve"},
		{"id": TabID.FINANCES, "icon": "💵", "title": "Fluxo Financeiro", "active": false, "badge": "Em breve"},
		{"id": TabID.ENERGY, "icon": "⚡", "title": "Rede Elétrica", "active": false, "badge": "Em breve"},
		{"id": TabID.NEWS, "icon": "📰", "title": "Jornal da Cidade", "active": false, "badge": "Em breve"},
		{"id": TabID.EQUIPMENT, "icon": "⚙️", "title": "Equipamentos", "active": false, "badge": "Em breve"},
		{"id": TabID.RECIPES, "icon": "📖", "title": "Livro de Receitas", "active": false, "badge": "Em breve"},
		{"id": TabID.SETTINGS, "icon": "🛠️", "title": "Configurações", "active": false, "badge": "Em breve"}
	]

	for t in tabs_def:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 42)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE

		var text = "%s  %s" % [t["icon"], t["title"]]
		if t["badge"] != "":
			text += "  [%s]" % t["badge"]
		btn.text = text

		var tab_id_val: TabID = t["id"]
		btn.pressed.connect(func(): _switch_tab(tab_id_val, t["title"]))
		nav_buttons_container.add_child(btn)
		nav_buttons_map[t["id"]] = btn

	_update_nav_button_styles()

func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_switch_tab(current_tab, "Estoque Geral" if current_tab == TabID.INVENTORY else "Central de Compras")
	_refresh_header_data()
	if current_tab == TabID.INVENTORY:
		_refresh_inventory_tab()
	elif current_tab == TabID.PURCHASES:
		_refresh_purchases_tab()

func close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()

func _process(_delta: float) -> void:
	if visible:
		_refresh_header_data()

func _refresh_header_data() -> void:
	var clock = GameClock.get_instance()
	if clock:
		if header_date_label:
			header_date_label.text = "📅 DIA %d (%s)" % [clock.day_number, clock.get_weekday_name().to_upper()]
		if header_time_label:
			header_time_label.text = "⏰ %s • %s" % [clock.get_formatted_time(), clock.get_state_string()]

	var econ = EconomyManager.get_instance()
	if econ and header_money_label:
		header_money_label.text = "$ %.2f" % econ.get_money()

func _switch_tab(tab_id: TabID, tab_title: String = "") -> void:
	current_tab = tab_id
	_update_nav_button_styles()

	if inventory_tab: inventory_tab.visible = (tab_id == TabID.INVENTORY)
	if purchases_tab: purchases_tab.visible = (tab_id == TabID.PURCHASES)
	if placeholder_tab: placeholder_tab.visible = (tab_id != TabID.INVENTORY and tab_id != TabID.PURCHASES)

	if tab_id == TabID.INVENTORY:
		_refresh_inventory_tab()
	elif tab_id == TabID.PURCHASES:
		_refresh_purchases_tab()
	else:
		if placeholder_tab:
			if placeholder_title:
				placeholder_title.text = "Módulo: %s" % tab_title
			if placeholder_desc:
				placeholder_desc.text = "Este módulo será integrado nas próximas etapas do Burger Rush OS.\nTodos os dados e sistemas de gameplay continuam funcionando normalmente."

func _update_nav_button_styles() -> void:
	for t_id in nav_buttons_map.keys():
		var btn: Button = nav_buttons_map[t_id]
		if not is_instance_valid(btn):
			continue

		var is_active = (t_id == current_tab)
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_bottom_left = 6

		if is_active:
			style.bg_color = Color(0.18, 0.24, 0.35, 1.0)
			style.border_width_left = 4
			style.border_color = Color(1.0, 0.75, 0.1, 1.0)
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		else:
			style.bg_color = Color(0.1, 0.12, 0.17, 0.0)
			btn.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1))

		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

# =============================================================================
# ABA 1: ESTOQUE GERAL
# =============================================================================

func _on_search_text_changed(new_text: String) -> void:
	current_search = new_text.strip_edges().to_lower()
	_refresh_inventory_tab()

func _set_category_filter(filter_name: String) -> void:
	current_filter = filter_name
	_update_filter_button_styles()
	_refresh_inventory_tab()

func _update_filter_button_styles() -> void:
	var filter_btns = {
		"ALL": filter_all_btn,
		"INGREDIENTS": filter_ingredients_btn,
		"DRINKS": filter_drinks_btn,
		"SUPPLIES": filter_supplies_btn,
		"OTHERS": filter_others_btn
	}

	for k in filter_btns.keys():
		var btn: Button = filter_btns[k]
		if not is_instance_valid(btn):
			continue
		var is_active = (k == current_filter)
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_right = 5
		style.corner_radius_bottom_left = 5

		if is_active:
			style.bg_color = Color(0.2, 0.3, 0.45, 1.0)
			style.border_width_bottom = 2
			style.border_color = Color(1.0, 0.75, 0.1, 1.0)
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		else:
			style.bg_color = Color(0.12, 0.15, 0.2, 0.8)
			btn.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 1))

		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

func _on_stock_changed(_item_id: String, _new_quantity: int) -> void:
	if visible and current_tab == TabID.INVENTORY:
		_refresh_inventory_tab()
	elif visible and current_tab == TabID.PURCHASES:
		_refresh_purchases_tab()

func _refresh_inventory_tab() -> void:
	if not stock_cards_grid:
		return

	var inv = InventoryManager.get_instance()
	if not inv:
		if stock_summary_label:
			stock_summary_label.text = "⚠️ Sistema de estoque indisponível."
		return

	var all_items = inv.get_all_items()
	var total_items_count = 0
	var low_stock_count = 0

	for child in stock_cards_grid.get_children():
		stock_cards_grid.remove_child(child)
		child.queue_free()

	for item_id in all_items.keys():
		var it = all_items[item_id]
		var d_name: String = it.get("display_name", item_id)
		var cat: String = it.get("category", "other")
		var qty: int = it.get("quantity", 0)
		var max_cap: int = it.get("max_capacity", 50)

		if not _is_item_in_filter(cat, current_filter):
			continue

		if current_search != "":
			var match_name = d_name.to_lower().contains(current_search)
			var match_id = item_id.to_lower().contains(current_search)
			if not (match_name or match_id):
				continue

		total_items_count += 1
		if max_cap > 1 and qty <= (max_cap * 0.25):
			low_stock_count += 1
		elif max_cap == 1 and qty == 0:
			low_stock_count += 1

		var card = _create_stock_card(item_id, d_name, cat, qty, max_cap)
		stock_cards_grid.add_child(card)

	if stock_summary_label:
		if low_stock_count > 0:
			stock_summary_label.text = "Exibindo %d itens  |  ⚠️ %d item(ns) com estoque baixo!" % [total_items_count, low_stock_count]
			stock_summary_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2, 1.0))
		else:
			stock_summary_label.text = "Exibindo %d itens cadastrados no restaurante" % total_items_count
			stock_summary_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9, 1.0))

func _is_item_in_filter(item_cat: String, filter_type: String) -> bool:
	match filter_type:
		"ALL":
			return true
		"INGREDIENTS":
			return item_cat in ["bakery", "meats", "cheeses", "vegetables", "extras", "sauces"]
		"DRINKS":
			return item_cat in ["beverages", "drinks", "pulps"]
		"SUPPLIES":
			return item_cat in ["supplies", "packaging"]
		"OTHERS":
			return not (item_cat in ["bakery", "meats", "cheeses", "vegetables", "extras", "sauces", "beverages", "drinks", "pulps", "supplies", "packaging"])
		_:
			return true

func _create_stock_card(id: String, item_name: String, _cat: String, qty: int, max_cap: int) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 110)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1

	var pct = float(qty) / float(max_cap) if max_cap > 0 else 0.0
	var badge_text = ""
	var badge_color = Color(1, 1, 1, 1)

	if max_cap == 1:
		if qty >= 1:
			badge_text = "🟢 ESTOQUE MÁXIMO"
			badge_color = Color(0.3, 0.9, 0.4, 1.0)
			style.bg_color = Color(0.10, 0.14, 0.12, 1.0)
			style.border_color = Color(0.18, 0.4, 0.25, 1.0)
		else:
			badge_text = "🔴 SEM RESERVA"
			badge_color = Color(1.0, 0.35, 0.35, 1.0)
			style.bg_color = Color(0.15, 0.08, 0.08, 1.0)
			style.border_color = Color(0.6, 0.2, 0.2, 1.0)
	else:
		if pct <= 0.0:
			badge_text = "🔴 ESGOTADO"
			badge_color = Color(1.0, 0.3, 0.3, 1.0)
			style.bg_color = Color(0.15, 0.08, 0.08, 1.0)
			style.border_color = Color(0.6, 0.2, 0.2, 1.0)
		elif pct <= 0.25:
			badge_text = "⚠️ ESTOQUE BAIXO"
			badge_color = Color(1.0, 0.65, 0.15, 1.0)
			style.bg_color = Color(0.15, 0.12, 0.08, 1.0)
			style.border_color = Color(0.55, 0.35, 0.15, 1.0)
		elif pct <= 0.65:
			badge_text = "🟡 ESTOQUE MÉDIO"
			badge_color = Color(0.9, 0.85, 0.3, 1.0)
			style.bg_color = Color(0.11, 0.13, 0.16, 1.0)
			style.border_color = Color(0.25, 0.3, 0.4, 1.0)
		else:
			badge_text = "🟢 ESTOQUE ALTO"
			badge_color = Color(0.3, 0.9, 0.4, 1.0)
			style.bg_color = Color(0.10, 0.14, 0.12, 1.0)
			style.border_color = Color(0.18, 0.4, 0.25, 1.0)

	card.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var top_row = HBoxContainer.new()
	vbox.add_child(top_row)

	var icon_label = Label.new()
	icon_label.text = _get_item_icon(id) + "  " + item_name
	icon_label.add_theme_font_size_override("font_size", 14)
	icon_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	top_row.add_child(icon_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	var badge_label = Label.new()
	badge_label.text = badge_text
	badge_label.add_theme_font_size_override("font_size", 11)
	badge_label.add_theme_color_override("font_color", badge_color)
	top_row.add_child(badge_label)

	var mid_row = HBoxContainer.new()
	vbox.add_child(mid_row)

	var qty_label = Label.new()
	qty_label.text = "%d / %d un" % [qty, max_cap]
	qty_label.add_theme_font_size_override("font_size", 15)
	qty_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1.0))
	mid_row.add_child(qty_label)

	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_row.add_child(spacer2)

	var pct_label = Label.new()
	pct_label.text = "%d%%" % int(pct * 100.0)
	pct_label.add_theme_font_size_override("font_size", 12)
	pct_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 1.0))
	mid_row.add_child(pct_label)

	var pbar = ProgressBar.new()
	pbar.custom_minimum_size = Vector2(0, 8)
	pbar.show_percentage = false
	pbar.max_value = 1.0
	pbar.value = pct

	var pb_style = StyleBoxFlat.new()
	pb_style.corner_radius_top_left = 4
	pb_style.corner_radius_top_right = 4
	pb_style.corner_radius_bottom_right = 4
	pb_style.corner_radius_bottom_left = 4
	pb_style.bg_color = badge_color
	pbar.add_theme_stylebox_override("fill", pb_style)

	var pb_bg = StyleBoxFlat.new()
	pb_bg.corner_radius_top_left = 4
	pb_bg.corner_radius_top_right = 4
	pb_bg.corner_radius_bottom_right = 4
	pb_bg.corner_radius_bottom_left = 4
	pb_bg.bg_color = Color(0.06, 0.08, 0.12, 1.0)
	pbar.add_theme_stylebox_override("background", pb_bg)

	vbox.add_child(pbar)
	return card

# =============================================================================
# ABA 2: CENTRAL DE COMPRAS & MERCADO
# =============================================================================

func _on_buy_search_text_changed(new_text: String) -> void:
	current_buy_search = new_text.strip_edges().to_lower()
	_refresh_purchases_catalog()

func _set_buy_category_filter(filter_name: String) -> void:
	current_buy_filter = filter_name
	_update_buy_filter_button_styles()
	_refresh_purchases_catalog()

func _update_buy_filter_button_styles() -> void:
	var filter_btns = {
		"ALL": btn_buy_all,
		"INGREDIENTS": btn_buy_ingredients,
		"FRIES": btn_buy_fries,
		"DRINKS": btn_buy_drinks,
		"SUPPLIES": btn_buy_supplies
	}

	for k in filter_btns.keys():
		var btn: Button = filter_btns[k]
		if not is_instance_valid(btn):
			continue
		var is_active = (k == current_buy_filter)
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_right = 5
		style.corner_radius_bottom_left = 5

		if is_active:
			style.bg_color = Color(0.2, 0.35, 0.5, 1.0)
			style.border_width_bottom = 2
			style.border_color = Color(1.0, 0.8, 0.15, 1.0)
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		else:
			style.bg_color = Color(0.12, 0.15, 0.2, 0.8)
			btn.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 1))

		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

func _on_cart_updated() -> void:
	if visible and current_tab == TabID.PURCHASES:
		_refresh_cart_view()
		_refresh_purchases_catalog()

func _on_market_updated() -> void:
	if visible and current_tab == TabID.PURCHASES:
		_refresh_purchases_catalog()

func _on_delivery_progress_updated(active_deliveries: Array[Dictionary]) -> void:
	if not deliveries_label:
		return
	if active_deliveries.is_empty():
		deliveries_label.text = "🚚 Nenhuma entrega a caminho no momento."
		deliveries_label.add_theme_color_override("font_color", Color(0.5, 0.65, 0.8, 1.0))
	else:
		var txt = ""
		for d in active_deliveries:
			var rem = maxf(0.0, d.get("time_remaining_sec", 0.0))
			var m = int(rem / 60.0)
			var s = int(rem) % 60
			txt += "🚚 Pedido #%d (%s) • Chegada em %02dm %02ds   " % [d["order_id"], d["supplier_name"], m, s]
		deliveries_label.text = txt
		deliveries_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0, 1.0))

func _on_delivery_arrived(_order: Dictionary) -> void:
	if visible and current_tab == TabID.PURCHASES:
		_refresh_purchases_tab()
	elif visible and current_tab == TabID.INVENTORY:
		_refresh_inventory_tab()

func _on_supplier_selected(index: int) -> void:
	var pm = PurchaseManager.get_instance()
	if not pm:
		return
	match index:
		0: pm.set_selected_supplier("NORMAL")
		1: pm.set_selected_supplier("FAST")
		2: pm.set_selected_supplier("WHOLESALE")
	_refresh_cart_view()

func _on_clear_cart_pressed() -> void:
	var pm = PurchaseManager.get_instance()
	if pm:
		pm.clear_cart()
		if cart_feedback_label:
			cart_feedback_label.text = "Carrinho limpo."
			cart_feedback_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))

func _on_confirm_order_pressed() -> void:
	var pm = PurchaseManager.get_instance()
	if not pm:
		return

	var res = pm.confirm_order()
	if cart_feedback_label:
		cart_feedback_label.text = res["message"]
		if res["success"]:
			cart_feedback_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1.0))
		else:
			cart_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))

	_refresh_header_data()
	_refresh_purchases_tab()

func _refresh_purchases_tab() -> void:
	_update_buy_filter_button_styles()
	_refresh_purchases_catalog()
	_refresh_cart_view()
	var pm = PurchaseManager.get_instance()
	if pm:
		_on_delivery_progress_updated(pm.get_active_deliveries())

func _refresh_purchases_catalog() -> void:
	if not purchases_catalog_grid:
		return

	var pm = PurchaseManager.get_instance()
	var inv = InventoryManager.get_instance()
	if not pm or not inv:
		return

	for child in purchases_catalog_grid.get_children():
		purchases_catalog_grid.remove_child(child)
		child.queue_free()

	var catalog = pm.get_catalog_items()

	for item_id in catalog.keys():
		var it = catalog[item_id]
		var cat = it["category"]
		var d_name = it["display_name"]

		if not _is_buy_item_in_filter(cat, current_buy_filter):
			continue

		if current_buy_search != "":
			var match_name = d_name.to_lower().contains(current_buy_search)
			var match_id = item_id.to_lower().contains(current_buy_search)
			if not (match_name or match_id):
				continue

		var card = _create_purchase_catalog_card(it)
		purchases_catalog_grid.add_child(card)

func _is_buy_item_in_filter(cat: String, filter_type: String) -> bool:
	match filter_type:
		"ALL": return true
		"INGREDIENTS": return cat == "ingredients"
		"FRIES": return cat == "fries"
		"DRINKS": return cat in ["beverages", "drinks"]
		"SUPPLIES": return cat in ["supplies", "packaging"]
		_: return true

func _create_purchase_catalog_card(item_data: Dictionary) -> Control:
	var id = item_data["id"]
	var d_name = item_data["display_name"]
	var base_price = item_data["base_price"] as float
	var market_price = item_data["market_price"] as float
	var var_pct = item_data["market_variation_pct"] as float
	var market_avail = item_data["market_available_qty"] as int
	var news = item_data.get("market_news", "")

	var inv = InventoryManager.get_instance()
	var pm = PurchaseManager.get_instance()
	var cur_stock = inv.get_stock(id) if inv else 0
	var max_cap = inv.get_max_capacity(id) if inv else 50
	var can_buy = pm.get_available_to_buy(id) if pm else 0

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 130)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.bg_color = Color(0.11, 0.13, 0.18, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.2, 0.25, 0.35, 1.0)
	card.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Linha 1: Ícone + Nome + Variação de Preço
	var row1 = HBoxContainer.new()
	vbox.add_child(row1)

	var title_lbl = Label.new()
	title_lbl.text = "%s  %s" % [_get_item_icon(id), d_name]
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	row1.add_child(title_lbl)

	var sp1 = Control.new()
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(sp1)

	var var_lbl = Label.new()
	var var_str = "%+d%%" % int(var_pct * 100.0)
	if var_pct > 0.01:
		var_lbl.text = "🔺 " + var_str
		var_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 1.0))
	elif var_pct < -0.01:
		var_lbl.text = "🔻 " + var_str
		var_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.5, 1.0))
	else:
		var_lbl.text = "➖ 0%"
		var_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	var_lbl.add_theme_font_size_override("font_size", 11)
	row1.add_child(var_lbl)

	# Linha 2: Preço de Mercado vs Base + Estoque Atual
	var row2 = HBoxContainer.new()
	vbox.add_child(row2)

	var price_lbl = Label.new()
	price_lbl.text = "$ %.2f / un  " % market_price
	price_lbl.add_theme_font_size_override("font_size", 14)
	price_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0))
	row2.add_child(price_lbl)

	var base_lbl = Label.new()
	base_lbl.text = "(Base: $%.2f)" % base_price
	base_lbl.add_theme_font_size_override("font_size", 11)
	base_lbl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7, 1.0))
	row2.add_child(base_lbl)

	var sp2 = Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(sp2)

	var stock_info_lbl = Label.new()
	stock_info_lbl.text = "Estoque: %d/%d (Disp: %d)" % [cur_stock, max_cap, can_buy]
	stock_info_lbl.add_theme_font_size_override("font_size", 11)
	stock_info_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 1.0))
	row2.add_child(stock_info_lbl)

	# Linha 3: Notícia de Mercado (se houver)
	if news != "":
		var news_lbl = Label.new()
		news_lbl.text = "📰 %s" % news
		news_lbl.add_theme_font_size_override("font_size", 10)
		news_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95, 0.85))
		news_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(news_lbl)

	# Linha 4: Controles de Quantidade e Adição ao Carrinho
	var row4 = HBoxContainer.new()
	row4.add_theme_constant_override("separation", 8)
	vbox.add_child(row4)

	var default_buy_qty = 10 if max_cap > 1 else 1
	var cur_sel_qty = card_selected_quantities.get(id, mini(default_buy_qty, maxi(1, can_buy)))
	cur_sel_qty = mini(cur_sel_qty, maxi(1, can_buy))
	card_selected_quantities[id] = cur_sel_qty

	var minus_btn = Button.new()
	minus_btn.text = " − "
	minus_btn.custom_minimum_size = Vector2(30, 28)
	minus_btn.focus_mode = Control.FOCUS_NONE
	row4.add_child(minus_btn)

	var qty_input = SpinBox.new()
	qty_input.custom_minimum_size = Vector2(70, 28)
	qty_input.min_value = 1
	qty_input.max_value = maxi(1, can_buy)
	qty_input.value = cur_sel_qty
	qty_input.editable = can_buy > 0
	row4.add_child(qty_input)

	var plus_btn = Button.new()
	plus_btn.text = " + "
	plus_btn.custom_minimum_size = Vector2(30, 28)
	plus_btn.focus_mode = Control.FOCUS_NONE
	row4.add_child(plus_btn)

	minus_btn.pressed.connect(func():
		var v = int(qty_input.value) - (5 if max_cap > 1 else 1)
		qty_input.value = maxi(1, v)
		card_selected_quantities[id] = int(qty_input.value)
	)
	plus_btn.pressed.connect(func():
		var v = int(qty_input.value) + (5 if max_cap > 1 else 1)
		qty_input.value = mini(can_buy, v)
		card_selected_quantities[id] = int(qty_input.value)
	)
	qty_input.value_changed.connect(func(val):
		card_selected_quantities[id] = int(val)
	)

	var sp4 = Control.new()
	sp4.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row4.add_child(sp4)

	var add_btn = Button.new()
	add_btn.custom_minimum_size = Vector2(120, 28)
	add_btn.focus_mode = Control.FOCUS_NONE
	if can_buy <= 0:
		add_btn.text = "Estoque Cheio"
		add_btn.disabled = true
	else:
		add_btn.text = "🛒 Adicionar"
		add_btn.disabled = false
		add_btn.pressed.connect(func():
			var q = int(qty_input.value)
			var res = pm.add_to_cart(id, q)
			if cart_feedback_label:
				cart_feedback_label.text = res["message"]
				cart_feedback_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1.0) if res["success"] else Color(1.0, 0.4, 0.4, 1.0))
		)
	row4.add_child(add_btn)

	return card

func _refresh_cart_view() -> void:
	if not cart_items_list:
		return

	var pm = PurchaseManager.get_instance()
	if not pm:
		return

	for child in cart_items_list.get_children():
		cart_items_list.remove_child(child)
		child.queue_free()

	var cart = pm.get_cart()

	if cart.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Nenhum produto no carrinho.\nAdicione itens do catálogo ao lado."
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65, 1.0))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cart_items_list.add_child(empty_lbl)
	else:
		for item_id in cart.keys():
			var item = cart[item_id]
			var row = _create_cart_item_row(item)
			cart_items_list.add_child(row)

	# Atualiza informações de fornecedor e totais
	var sup = pm.get_selected_supplier()
	var eta_sec = pm.get_cart_delivery_time_sec()
	var mins = int(eta_sec / 60.0)
	var secs = int(eta_sec) % 60

	if supplier_info_label:
		var mult = sup.get("price_multiplier", 1.0) as float
		var adj_str = "Preço Padrão"
		if mult > 1.0:
			adj_str = "+%d%% Taxa Expresso" % int((mult - 1.0) * 100.0)
		elif mult < 1.0:
			adj_str = "%d%% Desconto Atacado" % int((mult - 1.0) * 100.0)
		supplier_info_label.text = "%s %s\nPrazo: %dm %02ds • %s" % [sup["icon"], sup["name"], mins, secs, adj_str]

	var subtotal = pm.get_cart_subtotal()
	var total = pm.get_cart_total()
	var fee = total - subtotal

	if cart_subtotal_val: cart_subtotal_val.text = "$ %.2f" % subtotal
	if cart_fee_val:
		if fee > 0.0:
			cart_fee_val.text = "+$ %.2f" % fee
			cart_fee_val.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 1.0))
		elif fee < 0.0:
			cart_fee_val.text = "-$ %.2f" % absf(fee)
			cart_fee_val.add_theme_color_override("font_color", Color(0.35, 1.0, 0.5, 1.0))
		else:
			cart_fee_val.text = "$ 0.00"
			cart_fee_val.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 1.0))
	if cart_total_val: cart_total_val.text = "$ %.2f" % total

	if confirm_order_btn:
		confirm_order_btn.disabled = cart.is_empty()

func _create_cart_item_row(item: Dictionary) -> Control:
	var id = item["item_id"]
	var d_name = item["display_name"]
	var qty = item["quantity"] as int
	var unit_p = item["unit_price"] as float
	var total_p = qty * unit_p

	var container = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.bg_color = Color(0.12, 0.15, 0.2, 0.9)
	container.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	container.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	margin.add_child(hbox)

	var name_lbl = Label.new()
	name_lbl.text = "%s %s" % [_get_item_icon(id), d_name]
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	hbox.add_child(name_lbl)

	var qty_lbl = Label.new()
	qty_lbl.text = "×%d" % qty
	qty_lbl.add_theme_font_size_override("font_size", 12)
	qty_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	hbox.add_child(qty_lbl)

	var price_lbl = Label.new()
	price_lbl.text = "$ %.2f" % total_p
	price_lbl.add_theme_font_size_override("font_size", 12)
	price_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1.0))
	hbox.add_child(price_lbl)

	var del_btn = Button.new()
	del_btn.text = "✖"
	del_btn.custom_minimum_size = Vector2(22, 22)
	del_btn.focus_mode = Control.FOCUS_NONE
	del_btn.pressed.connect(func():
		var pm = PurchaseManager.get_instance()
		if pm: pm.remove_from_cart(id)
	)
	hbox.add_child(del_btn)

	return container

func _get_item_icon(id: String) -> String:
	match id:
		"bread_bottom", "bread_top":
			return "🍞"
		"patty_beef", "patty":
			return "🥩"
		"patty_chicken":
			return "🍗"
		"cheese_mozzarella", "cheese_cheddar", "cheese_prato", "cheese":
			return "🧀"
		"lettuce":
			return "🥬"
		"tomato":
			return "🍅"
		"onion", "red_onion":
			return "🧅"
		"pickle":
			return "🥒"
		"bacon":
			return "🥓"
		"egg":
			return "🍳"
		"sauce_ketchup", "ketchup", "sauce":
			return "🥫"
		"sauce_mustard", "mustard":
			return "🟡"
		"sauce_mayo", "mayo":
			return "⚪"
		"sauce_special", "special_sauce":
			return "🟠"
		"potato_raw", "potato_box", "french_fries_box", "fries_box":
			return "🍟"
		"cup_empty", "cup", "drink_cup":
			return "🥤"
		"cylinder_cola", "cylinder_cola_zero", "cylinder_soda", "cylinder_citrus", "syrup_soda":
			return "🍾"
		"burger_box":
			return "📦"
		"delivery_bag", "bag":
			return "🛍️"
		"pulp_orange":
			return "🍊"
		"pulp_grape":
			return "🍇"
		"pulp_strawberry":
			return "🍓"
		_:
			return "📦"
