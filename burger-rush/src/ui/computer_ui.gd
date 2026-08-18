class_name ComputerUI
extends CanvasLayer

const MenuPricingManager = preload("res://src/recipes/menu_pricing_manager.gd")
const FinanceManager = preload("res://src/economy/finance_manager.gd")
const WaterManager = preload("res://src/core/water_manager.gd")

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
@onready var menu_tab: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/MenuTab
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

# Elementos da Aba Cardápio
@onready var menu_search_input: LineEdit = $MainPanel/OuterWindow/VBox/Body/ContentArea/MenuTab/TopBar/HBox/MenuSearchInput
@onready var menu_summary_label: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/MenuTab/TopBar/HBox/MenuSummaryLabel
@onready var btn_menu_all: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/MenuTab/FilterBar/HBox/BtnMenuAll
@onready var btn_menu_burgers: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/MenuTab/FilterBar/HBox/BtnMenuBurgers
@onready var btn_menu_sides: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/MenuTab/FilterBar/HBox/BtnMenuSides
@onready var btn_menu_drinks: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/MenuTab/FilterBar/HBox/BtnMenuDrinks
@onready var menu_list_container: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/MenuTab/MenuScroll/Margin/MenuList

# Elementos da Aba Receitas
@onready var recipes_tab: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/RecipesTab
@onready var recipes_search_input: LineEdit = $MainPanel/OuterWindow/VBox/Body/ContentArea/RecipesTab/TopBar/HBox/RecipesSearchInput
@onready var recipes_summary_label: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/RecipesTab/TopBar/HBox/RecipesSummaryLabel
@onready var btn_recipe_all: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/RecipesTab/FilterBar/HBox/BtnRecipeAll
@onready var btn_recipe_burgers: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/RecipesTab/FilterBar/HBox/BtnRecipeBurgers
@onready var btn_recipe_sides: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/RecipesTab/FilterBar/HBox/BtnRecipeSides
@onready var btn_recipe_drinks: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/RecipesTab/FilterBar/HBox/BtnRecipeDrinks
@onready var recipes_grid_container: GridContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/RecipesTab/RecipesScroll/Margin/RecipesGrid

# Elementos da Aba Finanças
@onready var finances_tab: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab
@onready var finances_summary_label: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/TopBar/HBox/FinancesSummaryLabel
@onready var finances_kpi_hbox: HBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/KPICardsBar/HBox
@onready var btn_finances_overview: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/FilterBar/HBox/BtnFinancesOverview
@onready var btn_finances_revenue: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/FilterBar/HBox/BtnFinancesRevenue
@onready var btn_finances_expenses: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/FilterBar/HBox/BtnFinancesExpenses
@onready var btn_finances_bills: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/FilterBar/HBox/BtnFinancesBills
@onready var btn_finances_history: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/FilterBar/HBox/BtnFinancesHistory
@onready var finances_content_vbox: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/FinancesScroll/Margin/FinancesContentVBox

enum TabID {
	INVENTORY,
	PURCHASES,
	MENU,
	RECIPES,
	FINANCES,
	EMPLOYEES,
	ORDERS,
	ENERGY,
	NEWS,
	EQUIPMENT,
	SETTINGS
}

var current_tab: TabID = TabID.INVENTORY
var current_filter: String = "ALL"
var current_search: String = ""

var current_buy_filter: String = "ALL"
var current_buy_search: String = ""

var current_menu_filter: String = "ALL"
var current_menu_search: String = ""

var current_recipe_filter: String = "ALL"
var current_recipe_search: String = ""

var current_finances_section: String = "OVERVIEW" # OVERVIEW, REVENUE, EXPENSES, BILLS, HISTORY

# Quantidades temporárias selecionadas nos cards antes de adicionar ao carrinho
var card_selected_quantities: Dictionary = {}

var nav_buttons_map: Dictionary = {}

func _ready() -> void:
	visible = false
	_setup_signals()
	_setup_navigation_sidebar()
	_setup_purchases_tab()
	_setup_menu_tab()
	_setup_recipes_tab()
	_setup_finances_tab()

func _setup_signals() -> void:
	if close_btn and not close_btn.pressed.is_connected(close):
		close_btn.pressed.connect(close)

	if stock_search_input and not stock_search_input.text_changed.is_connected(_on_search_text_changed):
		stock_search_input.text_changed.connect(_on_search_text_changed)

	if filter_all_btn and not filter_all_btn.pressed.is_connected(_on_filter_all_pressed):
		filter_all_btn.pressed.connect(_on_filter_all_pressed)
	if filter_ingredients_btn and not filter_ingredients_btn.pressed.is_connected(_on_filter_ingredients_pressed):
		filter_ingredients_btn.pressed.connect(_on_filter_ingredients_pressed)
	if filter_drinks_btn and not filter_drinks_btn.pressed.is_connected(_on_filter_drinks_pressed):
		filter_drinks_btn.pressed.connect(_on_filter_drinks_pressed)
	if filter_supplies_btn and not filter_supplies_btn.pressed.is_connected(_on_filter_supplies_pressed):
		filter_supplies_btn.pressed.connect(_on_filter_supplies_pressed)
	if filter_others_btn and not filter_others_btn.pressed.is_connected(_on_filter_others_pressed):
		filter_others_btn.pressed.connect(_on_filter_others_pressed)

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

func _on_filter_all_pressed() -> void: _set_category_filter("ALL")
func _on_filter_ingredients_pressed() -> void: _set_category_filter("INGREDIENTS")
func _on_filter_drinks_pressed() -> void: _set_category_filter("DRINKS")
func _on_filter_supplies_pressed() -> void: _set_category_filter("SUPPLIES")
func _on_filter_others_pressed() -> void: _set_category_filter("OTHERS")

func _setup_purchases_tab() -> void:
	if purchases_search_input and not purchases_search_input.text_changed.is_connected(_on_buy_search_text_changed):
		purchases_search_input.text_changed.connect(_on_buy_search_text_changed)

	if btn_buy_all and not btn_buy_all.pressed.is_connected(_on_buy_all_pressed):
		btn_buy_all.pressed.connect(_on_buy_all_pressed)
	if btn_buy_ingredients and not btn_buy_ingredients.pressed.is_connected(_on_buy_ingredients_pressed):
		btn_buy_ingredients.pressed.connect(_on_buy_ingredients_pressed)
	if btn_buy_fries and not btn_buy_fries.pressed.is_connected(_on_buy_fries_pressed):
		btn_buy_fries.pressed.connect(_on_buy_fries_pressed)
	if btn_buy_drinks and not btn_buy_drinks.pressed.is_connected(_on_buy_drinks_pressed):
		btn_buy_drinks.pressed.connect(_on_buy_drinks_pressed)
	if btn_buy_supplies and not btn_buy_supplies.pressed.is_connected(_on_buy_supplies_pressed):
		btn_buy_supplies.pressed.connect(_on_buy_supplies_pressed)

	if clear_cart_btn and not clear_cart_btn.pressed.is_connected(_on_clear_cart_pressed):
		clear_cart_btn.pressed.connect(_on_clear_cart_pressed)

	if confirm_order_btn and not confirm_order_btn.pressed.is_connected(_on_confirm_order_pressed):
		confirm_order_btn.pressed.connect(_on_confirm_order_pressed)

	if supplier_option:
		supplier_option.clear()
		supplier_option.add_item("🚚 Fornecedor Normal (Padrão)", 0)
		supplier_option.add_item("⚡ Fornecedor Rápido (Expresso)", 1)
		supplier_option.add_item("📦 Fornecedor Atacado (Econômico)", 2)
		if not supplier_option.item_selected.is_connected(_on_supplier_selected):
			supplier_option.item_selected.connect(_on_supplier_selected)

func _on_buy_all_pressed() -> void: _set_buy_category_filter("ALL")
func _on_buy_ingredients_pressed() -> void: _set_buy_category_filter("INGREDIENTS")
func _on_buy_fries_pressed() -> void: _set_buy_category_filter("FRIES")
func _on_buy_drinks_pressed() -> void: _set_buy_category_filter("DRINKS")
func _on_buy_supplies_pressed() -> void: _set_buy_category_filter("SUPPLIES")

func _setup_navigation_sidebar() -> void:
	if not nav_buttons_container:
		return

	for child in nav_buttons_container.get_children():
		child.queue_free()
	nav_buttons_map.clear()

	var tabs_def = [
		{"id": TabID.INVENTORY, "icon": "📦", "title": "Estoque Geral", "active": true, "badge": ""},
		{"id": TabID.PURCHASES, "icon": "🛒", "title": "Central de Compras", "active": true, "badge": ""},
		{"id": TabID.MENU, "icon": "🍔", "title": "Cardápio & Preços", "active": true, "badge": ""},
		{"id": TabID.RECIPES, "icon": "📖", "title": "Livro de Receitas", "active": true, "badge": ""},
		{"id": TabID.FINANCES, "icon": "💵", "title": "Fluxo Financeiro", "active": true, "badge": "NOVO"},
		{"id": TabID.EMPLOYEES, "icon": "👥", "title": "Funcionários", "active": false, "badge": "Em breve"},
		{"id": TabID.ORDERS, "icon": "📋", "title": "Histórico de Pedidos", "active": false, "badge": "Em breve"},
		{"id": TabID.ENERGY, "icon": "⚡", "title": "Rede Elétrica", "active": false, "badge": "Em breve"},
		{"id": TabID.NEWS, "icon": "📰", "title": "Jornal da Cidade", "active": false, "badge": "Em breve"},
		{"id": TabID.EQUIPMENT, "icon": "⚙️", "title": "Equipamentos", "active": false, "badge": "Em breve"},
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
	var t_title = "Estoque Geral"
	if current_tab == TabID.PURCHASES: t_title = "Central de Compras"
	elif current_tab == TabID.MENU: t_title = "Cardápio & Preços"
	elif current_tab == TabID.RECIPES: t_title = "Livro de Receitas"
	elif current_tab == TabID.FINANCES: t_title = "Fluxo Financeiro"
	_switch_tab(current_tab, t_title)
	_refresh_header_data()
	if current_tab == TabID.INVENTORY:
		_refresh_inventory_tab()
	elif current_tab == TabID.PURCHASES:
		_refresh_purchases_tab()
	elif current_tab == TabID.MENU:
		_refresh_menu_tab()
	elif current_tab == TabID.RECIPES:
		_refresh_recipes_tab()
	elif current_tab == TabID.FINANCES:
		_refresh_finances_tab()

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

func _get_tab_node(tab_name: String) -> VBoxContainer:
	return get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/" + tab_name) as VBoxContainer

func _switch_tab(tab_id: TabID, tab_title: String = "") -> void:
	current_tab = tab_id
	_update_nav_button_styles()

	var inv_t = inventory_tab if inventory_tab else _get_tab_node("InventoryTab")
	var pur_t = purchases_tab if purchases_tab else _get_tab_node("PurchasesTab")
	var men_t = menu_tab if menu_tab else _get_tab_node("MenuTab")
	var rec_t = recipes_tab if recipes_tab else _get_tab_node("RecipesTab")
	var fin_t = finances_tab if finances_tab else _get_tab_node("FinancesTab")
	var plc_t = placeholder_tab if placeholder_tab else _get_tab_node("PlaceholderTab")

	inventory_tab = inv_t
	purchases_tab = pur_t
	menu_tab = men_t
	recipes_tab = rec_t
	finances_tab = fin_t
	placeholder_tab = plc_t

	if inv_t: inv_t.visible = (tab_id == TabID.INVENTORY)
	if pur_t: pur_t.visible = (tab_id == TabID.PURCHASES)
	if men_t: men_t.visible = (tab_id == TabID.MENU)
	if rec_t: rec_t.visible = (tab_id == TabID.RECIPES)
	if fin_t: fin_t.visible = (tab_id == TabID.FINANCES)
	if plc_t: plc_t.visible = (tab_id != TabID.INVENTORY and tab_id != TabID.PURCHASES and tab_id != TabID.MENU and tab_id != TabID.RECIPES and tab_id != TabID.FINANCES)

	if tab_id == TabID.INVENTORY:
		_refresh_inventory_tab()
	elif tab_id == TabID.PURCHASES:
		_refresh_purchases_tab()
	elif tab_id == TabID.MENU:
		_refresh_menu_tab()
	elif tab_id == TabID.RECIPES:
		_refresh_recipes_tab()
	elif tab_id == TabID.FINANCES:
		_refresh_finances_tab()
	else:
		if plc_t:
			var p_title = placeholder_title if placeholder_title else plc_t.get_node_or_null("TitleLabel") as Label
			var p_desc = placeholder_desc if placeholder_desc else plc_t.get_node_or_null("DescLabel") as Label
			if p_title:
				p_title.text = "Módulo: %s" % tab_title
			if p_desc:
				p_desc.text = "Este módulo será integrado nas próximas etapas do Burger Rush OS.\nTodos os dados e sistemas de gameplay continuam funcionando normalmente."

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
			return item_cat in ["bakery", "meats", "cheeses", "vegetables", "extras", "sauces", "ingredients", "fries"]
		"DRINKS":
			return item_cat in ["beverages", "drinks", "pulps"]
		"SUPPLIES":
			return item_cat in ["supplies", "packaging"] and not (item_cat in ["vegetables", "ingredients", "extras"])
		"OTHERS":
			return not (item_cat in ["bakery", "meats", "cheeses", "vegetables", "extras", "sauces", "ingredients", "fries", "beverages", "drinks", "pulps", "supplies", "packaging"])
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
		"potato_raw", "potato_bag", "french_fries_bag":
			return "🥔"
		"onion_rings_raw", "onion_bag", "onion_rings", "fried_onions":
			return "🧅"
		"potato_box", "french_fries_box", "fries_box", "fries":
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

# =============================================================================
# ABA 3: CARDÁPIO & PRECIFICAÇÃO DINÂMICA
# =============================================================================

func _setup_menu_tab() -> void:
	if menu_search_input and not menu_search_input.text_changed.is_connected(_on_menu_search_text_changed):
		menu_search_input.text_changed.connect(_on_menu_search_text_changed)

	if btn_menu_all and not btn_menu_all.pressed.is_connected(_on_menu_filter_all_pressed):
		btn_menu_all.pressed.connect(_on_menu_filter_all_pressed)
	if btn_menu_burgers and not btn_menu_burgers.pressed.is_connected(_on_menu_filter_burgers_pressed):
		btn_menu_burgers.pressed.connect(_on_menu_filter_burgers_pressed)
	if btn_menu_sides and not btn_menu_sides.pressed.is_connected(_on_menu_filter_sides_pressed):
		btn_menu_sides.pressed.connect(_on_menu_filter_sides_pressed)
	if btn_menu_drinks and not btn_menu_drinks.pressed.is_connected(_on_menu_filter_drinks_pressed):
		btn_menu_drinks.pressed.connect(_on_menu_filter_drinks_pressed)

func _on_menu_filter_all_pressed() -> void: _set_menu_category_filter("ALL")
func _on_menu_filter_burgers_pressed() -> void: _set_menu_category_filter("BURGER")
func _on_menu_filter_sides_pressed() -> void: _set_menu_category_filter("SIDES")
func _on_menu_filter_drinks_pressed() -> void: _set_menu_category_filter("DRINKS")

func _on_menu_search_text_changed(new_text: String) -> void:
	current_menu_search = new_text.strip_edges().to_lower()
	_refresh_menu_tab()

func _set_menu_category_filter(cat: String) -> void:
	current_menu_filter = cat
	_update_menu_filter_button_styles()
	_refresh_menu_tab()

func _update_menu_filter_button_styles() -> void:
	var buttons = {
		"ALL": btn_menu_all,
		"BURGER": btn_menu_burgers,
		"SIDES": btn_menu_sides,
		"DRINKS": btn_menu_drinks
	}

	for key in buttons.keys():
		var b: Button = buttons[key]
		if not b:
			continue
		var is_sel = (key == current_menu_filter)
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_bottom_left = 6
		if is_sel:
			style.bg_color = Color(0.85, 0.2, 0.15, 1.0)
			style.border_width_bottom = 2
			style.border_color = Color(1.0, 0.85, 0.2, 1.0)
			b.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		else:
			style.bg_color = Color(0.12, 0.15, 0.22, 1.0)
			b.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1))
		b.add_theme_stylebox_override("normal", style)
		b.add_theme_stylebox_override("hover", style)
		b.add_theme_stylebox_override("pressed", style)

func _refresh_menu_tab() -> void:
	var list_c = menu_list_container if menu_list_container else get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/MenuTab/MenuScroll/Margin/MenuList") as VBoxContainer
	if not list_c:
		return

	for child in list_c.get_children():
		list_c.remove_child(child)
		child.queue_free()

	_update_menu_filter_button_styles()

	var all_recipes = RecipeDatabase.get_all_recipes()
	var displayed_count = 0
	var total_margin_sum = 0.0
	var valid_margin_count = 0

	for recipe in all_recipes:
		var r_id = recipe.id
		var cat = recipe.category # "burger", "fries", "drink"
		var d_name = recipe.display_name

		# 1. Filtro por categoria
		if current_menu_filter != "ALL":
			match current_menu_filter:
				"BURGER":
					if cat != "burger": continue
				"SIDES":
					if cat != "fries" and not r_id.contains("fries") and not r_id.contains("onion"): continue
				"DRINKS":
					if cat != "drink" and not r_id.begins_with("soda_") and not r_id.begins_with("juice_"): continue

		# 2. Filtro por busca
		if current_menu_search != "":
			if not d_name.to_lower().contains(current_menu_search) and not r_id.to_lower().contains(current_menu_search):
				continue

		displayed_count += 1

		# 3. Cálculos Dinâmicos
		var cost = MenuPricingManager.calculate_production_cost(r_id)
		var market_ref = MenuPricingManager.get_market_reference_price(r_id)
		var recommended = MenuPricingManager.get_recommended_price(r_id)
		var min_price = MenuPricingManager.get_min_price(r_id)
		var max_price = MenuPricingManager.get_max_price(r_id)
		var current_price = MenuPricingManager.get_selling_price(r_id)
		var margin_pct = MenuPricingManager.get_gross_margin_pct(r_id)
		var gross_profit = MenuPricingManager.get_gross_profit(r_id)

		total_margin_sum += margin_pct
		valid_margin_count += 1

		# 4. Criação da Linha/Card do Produto
		var row_card = _create_menu_item_row(recipe, cost, market_ref, recommended, min_price, max_price, current_price, margin_pct, gross_profit)
		list_c.add_child(row_card)

	var s_lbl = menu_summary_label if menu_summary_label else get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/MenuTab/TopBar/HBox/MenuSummaryLabel") as Label
	if s_lbl:
		var avg_margin = (total_margin_sum / float(valid_margin_count)) if valid_margin_count > 0 else 0.0
		s_lbl.text = "%d itens • Margem Média: %.1f%%" % [displayed_count, avg_margin]

func _create_menu_item_row(
	recipe: Recipe,
	cost: float,
	market_ref: float,
	recommended: float,
	min_price: float,
	max_price: float,
	current_price: float,
	margin_pct: float,
	gross_profit: float
) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 48)

	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.10, 0.12, 0.17, 0.95)
	p_style.border_width_left = 1
	p_style.border_width_top = 1
	p_style.border_width_right = 1
	p_style.border_width_bottom = 1
	p_style.border_color = Color(0.18, 0.22, 0.30, 1.0)
	p_style.corner_radius_top_left = 8
	p_style.corner_radius_top_right = 8
	p_style.corner_radius_bottom_right = 8
	p_style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", p_style)

	var margin_c = MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 12)
	margin_c.add_theme_constant_override("margin_right", 12)
	margin_c.add_theme_constant_override("margin_top", 6)
	margin_c.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin_c)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin_c.add_child(hbox)

	# 1. Coluna Produto
	var col_prod = HBoxContainer.new()
	col_prod.custom_minimum_size = Vector2(230, 0)
	col_prod.add_theme_constant_override("separation", 8)
	hbox.add_child(col_prod)

	var icon_lbl = Label.new()
	icon_lbl.text = _get_recipe_icon(recipe)
	icon_lbl.add_theme_font_size_override("font_size", 16)
	col_prod.add_child(icon_lbl)

	var name_vbox = VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vbox.add_theme_constant_override("separation", 0)
	col_prod.add_child(name_vbox)

	var name_lbl = Label.new()
	name_lbl.text = recipe.display_name
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_vbox.add_child(name_lbl)

	var cat_tag = Label.new()
	cat_tag.text = _get_category_label(recipe.category)
	cat_tag.add_theme_font_size_override("font_size", 10)
	cat_tag.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 1))
	name_vbox.add_child(cat_tag)

	# 2. Coluna Custo Real
	var cost_lbl = Label.new()
	cost_lbl.custom_minimum_size = Vector2(110, 0)
	cost_lbl.text = "$ %.2f" % cost
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_font_size_override("font_size", 13)
	cost_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0, 1))
	hbox.add_child(cost_lbl)

	# 3. Coluna Mercado Regional
	var market_lbl = Label.new()
	market_lbl.custom_minimum_size = Vector2(110, 0)
	market_lbl.text = "$ %.2f" % market_ref
	market_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	market_lbl.add_theme_font_size_override("font_size", 13)
	market_lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9, 1))
	hbox.add_child(market_lbl)

	# 4. Coluna Sugerido
	var rec_lbl = Label.new()
	rec_lbl.custom_minimum_size = Vector2(110, 0)
	rec_lbl.text = "$ %.2f" % recommended
	rec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rec_lbl.add_theme_font_size_override("font_size", 13)
	rec_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1))
	hbox.add_child(rec_lbl)

	# 5. Coluna Seu Preço (com controles interativos)
	var price_ctrl = HBoxContainer.new()
	price_ctrl.custom_minimum_size = Vector2(200, 0)
	price_ctrl.add_theme_constant_override("separation", 4)
	hbox.add_child(price_ctrl)

	var btn_minus = Button.new()
	btn_minus.text = "－"
	btn_minus.custom_minimum_size = Vector2(28, 28)
	btn_minus.focus_mode = Control.FOCUS_NONE
	btn_minus.add_theme_font_size_override("font_size", 12)
	price_ctrl.add_child(btn_minus)

	var price_input = LineEdit.new()
	price_input.text = "%.2f" % current_price
	price_input.custom_minimum_size = Vector2(65, 28)
	price_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_input.add_theme_font_size_override("font_size", 13)
	var in_style = StyleBoxFlat.new()
	in_style.bg_color = Color(0.06, 0.08, 0.12, 1)
	in_style.border_width_left = 1
	in_style.border_width_top = 1
	in_style.border_width_right = 1
	in_style.border_width_bottom = 1
	in_style.border_color = Color(0.25, 0.32, 0.45, 1)
	in_style.corner_radius_top_left = 4
	in_style.corner_radius_top_right = 4
	in_style.corner_radius_bottom_right = 4
	in_style.corner_radius_bottom_left = 4
	price_input.add_theme_stylebox_override("normal", in_style)
	price_ctrl.add_child(price_input)

	var btn_plus = Button.new()
	btn_plus.text = "＋"
	btn_plus.custom_minimum_size = Vector2(28, 28)
	btn_plus.focus_mode = Control.FOCUS_NONE
	btn_plus.add_theme_font_size_override("font_size", 12)
	price_ctrl.add_child(btn_plus)

	var btn_reset = Button.new()
	btn_reset.text = "↺"
	btn_reset.tooltip_text = "Restaurar Preço Sugerido ($ %.2f)" % recommended
	btn_reset.custom_minimum_size = Vector2(28, 28)
	btn_reset.focus_mode = Control.FOCUS_NONE
	btn_reset.add_theme_font_size_override("font_size", 12)
	price_ctrl.add_child(btn_reset)

	# 6. Coluna Margem Bruta (Badge Colorida)
	var margin_panel = PanelContainer.new()
	margin_panel.custom_minimum_size = Vector2(140, 28)
	var m_style = StyleBoxFlat.new()
	m_style.corner_radius_top_left = 5
	m_style.corner_radius_top_right = 5
	m_style.corner_radius_bottom_right = 5
	m_style.corner_radius_bottom_left = 5
	if margin_pct >= 40.0:
		m_style.bg_color = Color(0.08, 0.35, 0.18, 0.9)
		m_style.border_width_left = 1
		m_style.border_color = Color(0.2, 0.7, 0.4, 1)
	elif margin_pct >= 20.0:
		m_style.bg_color = Color(0.40, 0.30, 0.08, 0.9)
		m_style.border_width_left = 1
		m_style.border_color = Color(0.8, 0.65, 0.2, 1)
	else:
		m_style.bg_color = Color(0.40, 0.10, 0.10, 0.9)
		m_style.border_width_left = 1
		m_style.border_color = Color(0.8, 0.25, 0.25, 1)
	margin_panel.add_theme_stylebox_override("panel", m_style)
	hbox.add_child(margin_panel)

	var margin_lbl = Label.new()
	margin_lbl.text = "%.1f%% (+$%.2f)" % [margin_pct, gross_profit]
	margin_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	margin_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	margin_lbl.add_theme_font_size_override("font_size", 11)
	margin_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	margin_panel.add_child(margin_lbl)

	# 7. Coluna Limites Permitidos
	var limits_lbl = Label.new()
	limits_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	limits_lbl.text = "Mín: $%.2f | Máx: $%.2f" % [min_price, max_price]
	limits_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	limits_lbl.add_theme_font_size_override("font_size", 11)
	limits_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 1))
	hbox.add_child(limits_lbl)

	# Callbacks Interativos para Alteração de Preço com Validação
	var apply_new_price = func(target_p: float):
		var clamped = clampf(target_p, min_price, max_price)
		MenuPricingManager.set_selling_price(recipe.id, clamped)
		_refresh_menu_tab()

	btn_minus.pressed.connect(func():
		var p = MenuPricingManager.get_selling_price(recipe.id) - 0.50
		apply_new_price.call(p)
	)

	btn_plus.pressed.connect(func():
		var p = MenuPricingManager.get_selling_price(recipe.id) + 0.50
		apply_new_price.call(p)
	)

	btn_reset.pressed.connect(func():
		apply_new_price.call(recommended)
	)

	price_input.text_submitted.connect(func(text_val: String):
		var val = text_val.to_float()
		if val <= 0.0:
			val = current_price
		apply_new_price.call(val)
	)

	return panel

# =============================================================================
# ABA 4: LIVRO DE RECEITAS DO RESTAURANTE
# =============================================================================

func _setup_recipes_tab() -> void:
	if recipes_search_input and not recipes_search_input.text_changed.is_connected(_on_recipe_search_text_changed):
		recipes_search_input.text_changed.connect(_on_recipe_search_text_changed)

	if btn_recipe_all and not btn_recipe_all.pressed.is_connected(_on_recipe_filter_all_pressed):
		btn_recipe_all.pressed.connect(_on_recipe_filter_all_pressed)
	if btn_recipe_burgers and not btn_recipe_burgers.pressed.is_connected(_on_recipe_filter_burgers_pressed):
		btn_recipe_burgers.pressed.connect(_on_recipe_filter_burgers_pressed)
	if btn_recipe_sides and not btn_recipe_sides.pressed.is_connected(_on_recipe_filter_sides_pressed):
		btn_recipe_sides.pressed.connect(_on_recipe_filter_sides_pressed)
	if btn_recipe_drinks and not btn_recipe_drinks.pressed.is_connected(_on_recipe_filter_drinks_pressed):
		btn_recipe_drinks.pressed.connect(_on_recipe_filter_drinks_pressed)

func _on_recipe_filter_all_pressed() -> void: _set_recipe_category_filter("ALL")
func _on_recipe_filter_burgers_pressed() -> void: _set_recipe_category_filter("BURGER")
func _on_recipe_filter_sides_pressed() -> void: _set_recipe_category_filter("SIDES")
func _on_recipe_filter_drinks_pressed() -> void: _set_recipe_category_filter("DRINKS")

func _on_recipe_search_text_changed(new_text: String) -> void:
	current_recipe_search = new_text.strip_edges().to_lower()
	_refresh_recipes_tab()

func _set_recipe_category_filter(cat: String) -> void:
	current_recipe_filter = cat
	_update_recipe_filter_button_styles()
	_refresh_recipes_tab()

func _update_recipe_filter_button_styles() -> void:
	var buttons = {
		"ALL": btn_recipe_all,
		"BURGER": btn_recipe_burgers,
		"SIDES": btn_recipe_sides,
		"DRINKS": btn_recipe_drinks
	}

	for key in buttons.keys():
		var b: Button = buttons[key]
		if not b:
			continue
		var is_sel = (key == current_recipe_filter)
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_bottom_left = 6
		if is_sel:
			style.bg_color = Color(0.85, 0.2, 0.15, 1.0)
			style.border_width_bottom = 2
			style.border_color = Color(1.0, 0.85, 0.2, 1.0)
			b.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		else:
			style.bg_color = Color(0.12, 0.15, 0.22, 1.0)
			b.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1))
		b.add_theme_stylebox_override("normal", style)
		b.add_theme_stylebox_override("hover", style)
		b.add_theme_stylebox_override("pressed", style)

func _refresh_recipes_tab() -> void:
	var grid = recipes_grid_container if recipes_grid_container else get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/RecipesTab/RecipesScroll/Margin/RecipesGrid") as GridContainer
	if not grid:
		return

	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	_update_recipe_filter_button_styles()

	var all_recipes = RecipeDatabase.get_all_recipes()
	var displayed_count = 0

	for recipe in all_recipes:
		var r_id = recipe.id
		var cat = recipe.category
		var d_name = recipe.display_name

		# 1. Filtro por categoria
		if current_recipe_filter != "ALL":
			match current_recipe_filter:
				"BURGER":
					if cat != "burger": continue
				"SIDES":
					if cat != "fries" and not r_id.contains("fries") and not r_id.contains("onion"): continue
				"DRINKS":
					if cat != "drink" and not r_id.begins_with("soda_") and not r_id.begins_with("juice_"): continue

		# 2. Filtro por busca
		if current_recipe_search != "":
			if not d_name.to_lower().contains(current_recipe_search) and not r_id.to_lower().contains(current_recipe_search):
				continue

		displayed_count += 1
		var card = _create_recipe_detail_card(recipe)
		grid.add_child(card)

	var s_lbl = recipes_summary_label if recipes_summary_label else get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/RecipesTab/TopBar/HBox/RecipesSummaryLabel") as Label
	if s_lbl:
		s_lbl.text = "%d receitas cadastradas • Montagem flexível" % displayed_count

func _create_recipe_detail_card(recipe: Recipe) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.10, 0.12, 0.17, 0.95)
	p_style.border_width_left = 1
	p_style.border_width_top = 1
	p_style.border_width_right = 1
	p_style.border_width_bottom = 1
	p_style.border_color = Color(0.20, 0.25, 0.35, 1.0)
	p_style.corner_radius_top_left = 8
	p_style.corner_radius_top_right = 8
	p_style.corner_radius_bottom_right = 8
	p_style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", p_style)

	var margin_c = MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 14)
	margin_c.add_theme_constant_override("margin_right", 14)
	margin_c.add_theme_constant_override("margin_top", 12)
	margin_c.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin_c)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin_c.add_child(vbox)

	# 1. Cabeçalho do Card da Receita
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(header_hbox)

	var icon_lbl = Label.new()
	icon_lbl.text = _get_recipe_icon(recipe)
	icon_lbl.add_theme_font_size_override("font_size", 20)
	header_hbox.add_child(icon_lbl)

	var title_vbox = VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 0)
	header_hbox.add_child(title_vbox)

	var title_lbl = Label.new()
	title_lbl.text = recipe.display_name
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(1, 0.95, 0.8, 1))
	title_vbox.add_child(title_lbl)

	var cat_tag = Label.new()
	cat_tag.text = "[%s]" % _get_category_label(recipe.category)
	cat_tag.add_theme_font_size_override("font_size", 10)
	cat_tag.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85, 1))
	title_vbox.add_child(cat_tag)

	# Badges Financeiras no Cabeçalho
	var cost = MenuPricingManager.calculate_production_cost(recipe.id)
	var price = MenuPricingManager.get_selling_price(recipe.id)
	var margin_pct = MenuPricingManager.get_gross_margin_pct(recipe.id)

	var badges_hbox = HBoxContainer.new()
	badges_hbox.add_theme_constant_override("separation", 6)
	header_hbox.add_child(badges_hbox)

	var cost_badge = _create_pill_badge("Custo: $%.2f" % cost, Color(0.12, 0.28, 0.45, 0.9), Color(0.5, 0.8, 1.0, 1))
	badges_hbox.add_child(cost_badge)

	var price_badge = _create_pill_badge("Venda: $%.2f" % price, Color(0.35, 0.25, 0.05, 0.9), Color(1.0, 0.85, 0.3, 1))
	badges_hbox.add_child(price_badge)

	var margin_col = Color(0.2, 0.7, 0.4, 1) if margin_pct >= 40.0 else (Color(0.85, 0.7, 0.2, 1) if margin_pct >= 20.0 else Color(0.9, 0.3, 0.3, 1))
	var margin_bg = Color(0.08, 0.30, 0.15, 0.9) if margin_pct >= 40.0 else (Color(0.35, 0.25, 0.05, 0.9) if margin_pct >= 20.0 else Color(0.35, 0.08, 0.08, 0.9))
	var margin_badge = _create_pill_badge("Margem: %.1f%%" % margin_pct, margin_bg, margin_col)
	badges_hbox.add_child(margin_badge)

	# 2. Aviso de Montagem Livre
	var free_order_panel = PanelContainer.new()
	var fo_style = StyleBoxFlat.new()
	fo_style.bg_color = Color(0.08, 0.10, 0.14, 0.9)
	fo_style.border_width_left = 2
	fo_style.border_color = Color(1.0, 0.8, 0.2, 0.8)
	fo_style.corner_radius_top_left = 4
	fo_style.corner_radius_top_right = 4
	fo_style.corner_radius_bottom_right = 4
	fo_style.corner_radius_bottom_left = 4
	free_order_panel.add_theme_stylebox_override("panel", fo_style)
	vbox.add_child(free_order_panel)

	var fo_margin = MarginContainer.new()
	fo_margin.add_theme_constant_override("margin_left", 8)
	fo_margin.add_theme_constant_override("margin_right", 8)
	fo_margin.add_theme_constant_override("margin_top", 4)
	fo_margin.add_theme_constant_override("margin_bottom", 4)
	free_order_panel.add_child(fo_margin)

	var fo_label = Label.new()
	fo_label.text = "🔓 Montagem Livre: Todos os ingredientes necessários devem estar presentes. A ordem entre os pães é livre!"
	fo_label.add_theme_font_size_override("font_size", 11)
	fo_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6, 1))
	fo_margin.add_child(fo_label)

	# 3. Lista Estruturada de Ingredientes Necessários
	var ing_section = VBoxContainer.new()
	ing_section.add_theme_constant_override("separation", 3)
	vbox.add_child(ing_section)

	var ing_title = Label.new()
	ing_title.text = "📋 INGREDIENTES NECESSÁRIOS:"
	ing_title.add_theme_font_size_override("font_size", 11)
	ing_title.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85, 1))
	ing_section.add_child(ing_title)

	var lines = _format_recipe_ingredients_list(recipe)
	for line in lines:
		var line_lbl = Label.new()
		line_lbl.text = "  " + line
		line_lbl.add_theme_font_size_override("font_size", 12)
		line_lbl.add_theme_color_override("font_color", Color(0.9, 0.92, 0.96, 1))
		ing_section.add_child(line_lbl)

	# 4. Rodapé do Card
	var footer_hbox = HBoxContainer.new()
	vbox.add_child(footer_hbox)

	var active_lbl = Label.new()
	active_lbl.text = "🟢 Ativo no Restaurante"
	active_lbl.add_theme_font_size_override("font_size", 11)
	active_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 0.5, 1))
	footer_hbox.add_child(active_lbl)

	var f_spacer = Control.new()
	f_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_hbox.add_child(f_spacer)

	var yield_lbl = Label.new()
	yield_lbl.text = "Rendimento: 1 unidade"
	yield_lbl.add_theme_font_size_override("font_size", 11)
	yield_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 1))
	footer_hbox.add_child(yield_lbl)

	return panel

func _create_pill_badge(text: String, bg_color: Color, text_color: Color) -> PanelContainer:
	var pill = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	pill.add_theme_stylebox_override("panel", style)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 6)
	m.add_theme_constant_override("margin_right", 6)
	m.add_theme_constant_override("margin_top", 2)
	m.add_theme_constant_override("margin_bottom", 2)
	pill.add_child(m)

	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", text_color)
	m.add_child(lbl)

	return pill

func _format_recipe_ingredients_list(recipe: Recipe) -> Array[String]:
	var result: Array[String] = []

	if recipe.category == "burger":
		result.append("🍞 1x Base do Pão (Inferior)")

		# Conta ingredientes da receita
		var counts: Dictionary = {}
		for ing in recipe.required_ingredients:
			var clean = ing
			if clean == "bread":
				continue
			counts[clean] = counts.get(clean, 0) + 1

		for k in counts.keys():
			var qty = counts[k]
			var desc = _get_ingredient_display_name_and_icon(k, qty)
			result.append(desc)

		result.append("🍞 1x Tampa do Pão (Superior)")
		result.append("📦 1x Embalado na Caixa de Hambúrguer")

	elif recipe.category == "fries" or recipe.id == "fries" or recipe.id == "onion_rings":
		if recipe.id == "fries":
			result.append("🥔 1x Saco de Batata (1 Saco abastece o Cesto -> 5 Porções)")
			result.append("🍟 1x Embalagem de Batata")
		else:
			result.append("🧅 1x Saco de Cebola (1 Saco abastece o Cesto -> 3 Porções)")
			result.append("🍟 1x Embalagem de Cebola")

	elif recipe.category == "drink" or recipe.id.begins_with("soda_") or recipe.id.begins_with("juice_"):
		if recipe.id.begins_with("soda_"):
			match recipe.id:
				"soda_cola": result.append("🍾 1x Xarope de Cola (1 Cilindro = 20 Copos)")
				"soda_cola_zero": result.append("🍾 1x Xarope de Cola Zero (1 Cilindro = 20 Copos)")
				"soda_lime": result.append("🍾 1x Xarope de Limão/Soda (1 Cilindro = 20 Copos)")
				"soda_citrus": result.append("🍾 1x Xarope Citrus (1 Cilindro = 20 Copos)")
				_: result.append("🍾 1x Xarope do Cilindro (1 Cilindro = 20 Copos)")
			result.append("🥤 1x Copo Descartável")
		elif recipe.id.begins_with("juice_"):
			match recipe.id:
				"juice_orange": result.append("🍊 1x Polpa de Laranja (1 Polpa = 5 Copos)")
				"juice_grape": result.append("🍇 1x Polpa de Uva (1 Polpa = 5 Copos)")
				"juice_strawberry": result.append("🍓 1x Polpa de Morango (1 Polpa = 5 Copos)")
				_: result.append("🍊 1x Polpa de Fruta (1 Polpa = 5 Copos)")
			result.append("🥤 1x Copo Descartável")
		else:
			result.append("🥤 1x Copo de Bebida")
	else:
		for ing in recipe.required_ingredients:
			result.append("• 1x %s" % ing.capitalize())

	return result

func _get_ingredient_display_name_and_icon(ing_key: String, qty: int) -> String:
	match ing_key:
		"patty_beef:cooked", "patty_beef", "patty":
			return "🥩 %dx Carne Bovina (Grelhada)" % qty
		"patty_chicken:cooked", "patty_chicken":
			return "🍗 %dx Hambúrguer de Frango (Grelhado)" % qty
		"cheese_cheddar", "cheese":
			return "🧀 %dx Queijo Cheddar" % qty
		"cheese_mozzarella":
			return "🧀 %dx Queijo Muçarela" % qty
		"cheese_prato":
			return "🧀 %dx Queijo Prato" % qty
		"lettuce":
			return "🥬 %dx Alface Fresca" % qty
		"tomato":
			return "🍅 %dx Tomate em Rodelas" % qty
		"onion":
			return "🧅 %dx Cebola Comum" % qty
		"red_onion":
			return "🧅 %dx Cebola Roxa" % qty
		"pickle":
			return "🥒 %dx Picles Fatiado" % qty
		"bacon", "bacon:cooked":
			return "🥓 %dx Bacon Crocante (Frito)" % qty
		"egg", "egg:cooked":
			return "🍳 %dx Ovo Frito" % qty
		"ketchup":
			return "🥫 %dx Ketchup Especial" % qty
		"mustard":
			return "🟡 %dx Mostarda Suave" % qty
		"mayo":
			return "⚪ %dx Maionese da Casa" % qty
		"special_sauce":
			return "🟠 %dx Molho Especial Secreto" % qty
		_:
			return "• %dx %s" % [qty, ing_key.capitalize()]

func _get_recipe_icon(recipe: Recipe) -> String:
	if recipe.id == "juice_orange": return "🍊"
	elif recipe.id == "juice_grape": return "🍇"
	elif recipe.id == "juice_strawberry": return "🍓"
	elif recipe.id == "onion_rings": return "🧅"
	elif recipe.id == "fries": return "🍟"
	elif recipe.category == "burger": return "🍔"
	elif recipe.category == "drink": return "🥤"
	return "🍽️"

func _get_category_label(cat: String) -> String:
	match cat:
		"burger": return "Hambúrguer"
		"fries": return "Acompanhamento"
		"drink": return "Bebida"
		_: return "Geral"

# =============================================================================
# ABA 5: FINANÇAS & CONTAS DO RESTAURANTE (FINANCES TAB)
# =============================================================================

func _setup_finances_tab() -> void:
	if not finances_tab:
		finances_tab = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab")
	if not finances_summary_label:
		finances_summary_label = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/TopBar/HBox/FinancesSummaryLabel")
	if not finances_kpi_hbox:
		finances_kpi_hbox = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/KPICardsBar/HBox")
	if not btn_finances_overview:
		btn_finances_overview = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/FilterBar/HBox/BtnFinancesOverview")
	if not btn_finances_revenue:
		btn_finances_revenue = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/FilterBar/HBox/BtnFinancesRevenue")
	if not btn_finances_expenses:
		btn_finances_expenses = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/FilterBar/HBox/BtnFinancesExpenses")
	if not btn_finances_bills:
		btn_finances_bills = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/FilterBar/HBox/BtnFinancesBills")
	if not btn_finances_history:
		btn_finances_history = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/FilterBar/HBox/BtnFinancesHistory")
	if not finances_content_vbox:
		finances_content_vbox = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/FinancesScroll/Margin/FinancesContentVBox")

	if btn_finances_overview and not btn_finances_overview.pressed.is_connected(_on_finances_overview_pressed):
		btn_finances_overview.pressed.connect(_on_finances_overview_pressed)
	if btn_finances_revenue and not btn_finances_revenue.pressed.is_connected(_on_finances_revenue_pressed):
		btn_finances_revenue.pressed.connect(_on_finances_revenue_pressed)
	if btn_finances_expenses and not btn_finances_expenses.pressed.is_connected(_on_finances_expenses_pressed):
		btn_finances_expenses.pressed.connect(_on_finances_expenses_pressed)
	if btn_finances_bills and not btn_finances_bills.pressed.is_connected(_on_finances_bills_pressed):
		btn_finances_bills.pressed.connect(_on_finances_bills_pressed)
	if btn_finances_history and not btn_finances_history.pressed.is_connected(_on_finances_history_pressed):
		btn_finances_history.pressed.connect(_on_finances_history_pressed)

	var fin = FinanceManager.get_instance()
	if fin:
		if not fin.finances_updated.is_connected(_on_finances_manager_updated):
			fin.finances_updated.connect(_on_finances_manager_updated)

func _on_finances_manager_updated() -> void:
	if visible and current_tab == TabID.FINANCES:
		_refresh_finances_tab()

func _on_finances_overview_pressed() -> void:
	_set_finances_section("OVERVIEW")

func _on_finances_revenue_pressed() -> void:
	_set_finances_section("REVENUE")

func _on_finances_expenses_pressed() -> void:
	_set_finances_section("EXPENSES")

func _on_finances_bills_pressed() -> void:
	_set_finances_section("BILLS")

func _on_finances_history_pressed() -> void:
	_set_finances_section("HISTORY")

func _set_finances_section(sec: String) -> void:
	current_finances_section = sec
	_update_finances_filter_button_styles()
	_refresh_finances_tab()

func _update_finances_filter_button_styles() -> void:
	var buttons = {
		"OVERVIEW": btn_finances_overview,
		"REVENUE": btn_finances_revenue,
		"EXPENSES": btn_finances_expenses,
		"BILLS": btn_finances_bills,
		"HISTORY": btn_finances_history
	}

	for sec in buttons.keys():
		var btn = buttons[sec]
		if not btn:
			continue
		var is_selected = (sec == current_finances_section)
		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(6)
		style.set_content_margin_all(8)
		if is_selected:
			style.bg_color = Color(0.20, 0.45, 0.85, 0.95)
			style.border_color = Color(0.4, 0.7, 1.0, 1.0)
			style.border_width_bottom = 2
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		else:
			style.bg_color = Color(0.12, 0.16, 0.24, 0.85)
			style.border_color = Color(0.2, 0.28, 0.4, 0.6)
			style.border_width_bottom = 1
			btn.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1))
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

func _refresh_finances_tab() -> void:
	if not finances_kpi_hbox:
		finances_kpi_hbox = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/KPICardsBar/HBox")
	if not finances_content_vbox:
		finances_content_vbox = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/FinancesScroll/Margin/FinancesContentVBox")
	if not finances_summary_label:
		finances_summary_label = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/FinancesTab/TopBar/HBox/FinancesSummaryLabel")

	var fin = FinanceManager.get_instance()
	if not fin and is_inside_tree() and get_tree() and get_tree().root:
		fin = get_tree().root.find_child("FinanceManager", true, false) as FinanceManager

	var econ = EconomyManager.get_instance()
	if not econ and is_inside_tree() and get_tree() and get_tree().root:
		econ = get_tree().root.find_child("EconomyManager", true, false) as EconomyManager

	var clock = GameClock.get_instance()
	if clock and finances_summary_label:
		finances_summary_label.text = "Dia %d • %s | Balanço Operacional" % [clock.day_number, clock.get_weekday_name()]

	var balance: float = econ.get_money() if econ else 0.0
	var revenue: float = fin.get_total_daily_revenue() if fin else 0.0
	var expenses: float = fin.get_total_daily_expenses() if fin else 0.0
	var net_profit: float = fin.get_daily_net_profit() if fin else 0.0

	_render_kpi_cards(balance, revenue, expenses, net_profit)
	_update_finances_filter_button_styles()

	if not finances_content_vbox:
		return

	# Limpa o container de conteúdo
	for child in finances_content_vbox.get_children():
		finances_content_vbox.remove_child(child)
		child.queue_free()

	if not fin:
		var empty_lbl = Label.new()
		empty_lbl.text = "⚠️ Sistema financeiro indisponível no momento."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		finances_content_vbox.add_child(empty_lbl)
		return

	match current_finances_section:
		"OVERVIEW":
			_render_overview_section(fin, econ)
		"REVENUE":
			_render_revenue_section(fin)
		"EXPENSES":
			_render_expenses_section(fin)
		"BILLS":
			_render_bills_section(fin)
		"HISTORY":
			_render_history_section(fin)

func _render_kpi_cards(balance: float, revenue: float, expenses: float, net_profit: float) -> void:
	if not finances_kpi_hbox:
		return

	for child in finances_kpi_hbox.get_children():
		finances_kpi_hbox.remove_child(child)
		child.queue_free()

	var kpis = [
		{
			"icon": "💰",
			"title": "SALDO ATUAL",
			"value": "R$ %.2f" % balance,
			"color": Color(0.3, 0.85, 0.45, 1.0),
			"bg": Color(0.08, 0.18, 0.12, 0.95),
			"border": Color(0.2, 0.6, 0.3, 0.8)
		},
		{
			"icon": "📈",
			"title": "RECEITA DO DIA",
			"value": "+R$ %.2f" % revenue,
			"color": Color(0.35, 0.75, 1.0, 1.0),
			"bg": Color(0.08, 0.14, 0.22, 0.95),
			"border": Color(0.2, 0.5, 0.8, 0.8)
		},
		{
			"icon": "📉",
			"title": "DESPESAS DO DIA",
			"value": "-R$ %.2f" % expenses,
			"color": Color(1.0, 0.45, 0.4, 1.0),
			"bg": Color(0.22, 0.08, 0.08, 0.95),
			"border": Color(0.8, 0.3, 0.3, 0.8)
		},
		{
			"icon": "🏆",
			"title": "LUCRO LÍQUIDO",
			"value": "%sR$ %.2f" % ["+" if net_profit >= 0.0 else "", net_profit],
			"color": Color(0.3, 0.95, 0.5, 1.0) if net_profit >= 0.0 else Color(1.0, 0.3, 0.3, 1.0),
			"bg": Color(0.12, 0.18, 0.12, 0.95) if net_profit >= 0.0 else Color(0.25, 0.08, 0.08, 0.95),
			"border": Color(0.3, 0.7, 0.4, 0.8) if net_profit >= 0.0 else Color(0.9, 0.25, 0.25, 0.8)
		}
	]

	for k in kpis:
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(0, 68)

		var style = StyleBoxFlat.new()
		style.bg_color = k["bg"]
		style.border_color = k["border"]
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.set_content_margin_all(10)
		card.add_theme_stylebox_override("panel", style)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		var icon_lbl = Label.new()
		icon_lbl.text = k["icon"]
		icon_lbl.add_theme_font_size_override("font_size", 24)
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(icon_lbl)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var title_lbl = Label.new()
		title_lbl.text = k["title"]
		title_lbl.add_theme_font_size_override("font_size", 11)
		title_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
		vbox.add_child(title_lbl)

		var val_lbl = Label.new()
		val_lbl.text = k["value"]
		val_lbl.add_theme_font_size_override("font_size", 17)
		val_lbl.add_theme_color_override("font_color", k["color"])
		vbox.add_child(val_lbl)

		hbox.add_child(vbox)
		card.add_child(hbox)
		finances_kpi_hbox.add_child(card)

# =============================================================================
# SEÇÃO 1: VISÃO GERAL
# =============================================================================

func _render_overview_section(fin: FinanceManager, _econ: EconomyManager) -> void:
	# 1. Painel de Contas a Pagar / Pendentes
	var bills_title = Label.new()
	bills_title.text = "📑 CONTAS DO DIA (PAGAMENTOS OPERACIONAIS)"
	bills_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	bills_title.add_theme_font_size_override("font_size", 14)
	finances_content_vbox.add_child(bills_title)

	var bills = fin.get_active_bills()
	var bills_grid = HBoxContainer.new()
	bills_grid.add_theme_constant_override("separation", 10)
	bills_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for bill_id in ["electricity", "water", "salaries"]:
		if bills.has(bill_id):
			var bill_card = _create_bill_card(bills[bill_id], fin)
			bill_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bills_grid.add_child(bill_card)

	finances_content_vbox.add_child(bills_grid)

	# 2. Resumo de Entradas e Saídas lado a lado
	var summary_split = HBoxContainer.new()
	summary_split.add_theme_constant_override("separation", 14)
	summary_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Coluna Esquerda: Entradas por Canal
	var revenue_items = [
		{"name": "🍔 Vendas no Salão / Balcão", "amount": fin.get_daily_revenue_by_channel("dine_in")},
		{"name": "🚗 Vendas no Drive-Thru", "amount": fin.get_daily_revenue_by_channel("drive_thru")},
		{"name": "🛵 Vendas por Delivery / App", "amount": fin.get_daily_revenue_by_channel("delivery")},
		{"name": "✨ Outras Entradas", "amount": fin.get_daily_revenue_by_channel("other")}
	]
	var revenue_card = _create_breakdown_card("Entradas de Vendas", "📥", fin.get_total_daily_revenue(), revenue_items, false)
	revenue_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_split.add_child(revenue_card)

	# Coluna Direita: Saídas por Categoria
	var expense_items = [
		{"name": "🛒 Compras de Insumos / Embalagens", "amount": fin.get_daily_purchases_cost()},
		{"name": "⚡ Conta de Energia Elétrica (%.1f kWh)" % fin.get_daily_electricity_kwh(), "amount": fin.calculate_daily_electricity_cost()},
		{"name": "💧 Conta de Água (%.1f Litros)" % fin.get_daily_water_liters(), "amount": fin.calculate_daily_water_cost()},
		{"name": "👥 Salários de Funcionários (%d ativos)" % fin.get_active_employees_count(), "amount": fin.calculate_daily_salaries_cost()}
	]
	var expense_card = _create_breakdown_card("Despesas Operacionais", "📤", fin.get_total_daily_expenses(), expense_items, true)
	expense_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_split.add_child(expense_card)

	finances_content_vbox.add_child(summary_split)

# =============================================================================
# SEÇÃO 2: ENTRADAS DETALHADAS (VENDAS)
# =============================================================================

func _render_revenue_section(fin: FinanceManager) -> void:
	var title = Label.new()
	title.text = "📥 DETALHAMENTO DE ENTRADAS E VENDAS POR CANAL"
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	title.add_theme_font_size_override("font_size", 15)
	finances_content_vbox.add_child(title)

	var total_rev = fin.get_total_daily_revenue()

	var channels = [
		{
			"id": "dine_in",
			"icon": "🍔",
			"name": "Restaurante / Balcão (Salão)",
			"desc": "Pedidos feitos e consumidos nas mesas ou retirados no balcão presencial.",
			"amount": fin.get_daily_revenue_by_channel("dine_in")
		},
		{
			"id": "drive_thru",
			"icon": "🚗",
			"name": "Janela Drive-Thru",
			"desc": "Pedidos atendidos e entregues pela janela do Drive-Thru automotivo.",
			"amount": fin.get_daily_revenue_by_channel("drive_thru")
		},
		{
			"id": "delivery",
			"icon": "🛵",
			"name": "Entregas Delivery & App",
			"desc": "Pedidos solicitados via aplicativo ou telefone com despacho para entrega.",
			"amount": fin.get_daily_revenue_by_channel("delivery")
		},
		{
			"id": "other",
			"icon": "✨",
			"name": "Outras Receitas Operacionais",
			"desc": "Bônus por avaliações positivas, recompensas de eventos e gorjetas.",
			"amount": fin.get_daily_revenue_by_channel("other")
		}
	]

	for ch in channels:
		var card = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.10, 0.15, 0.22, 0.9)
		style.border_color = Color(0.2, 0.4, 0.65, 0.7)
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.set_content_margin_all(14)
		card.add_theme_stylebox_override("panel", style)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)

		var icon_lbl = Label.new()
		icon_lbl.text = ch["icon"]
		icon_lbl.add_theme_font_size_override("font_size", 28)
		hbox.add_child(icon_lbl)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl = Label.new()
		name_lbl.text = ch["name"]
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		vbox.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = ch["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 1.0))
		vbox.add_child(desc_lbl)

		# Barra de proporção percentual
		var pct = (ch["amount"] / total_rev * 100.0) if total_rev > 0.0 else 0.0
		var pct_lbl = Label.new()
		pct_lbl.text = "Participação no Faturamento: %.1f%%" % pct
		pct_lbl.add_theme_font_size_override("font_size", 11)
		pct_lbl.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0, 1.0))
		vbox.add_child(pct_lbl)

		hbox.add_child(vbox)

		var amount_lbl = Label.new()
		amount_lbl.text = "+R$ %.2f" % ch["amount"]
		amount_lbl.add_theme_font_size_override("font_size", 18)
		amount_lbl.add_theme_color_override("font_color", Color(0.35, 0.85, 0.5, 1.0))
		amount_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(amount_lbl)

		card.add_child(hbox)
		finances_content_vbox.add_child(card)

# =============================================================================
# SEÇÃO 3: SAÍDAS DETALHADAS (CUSTOS)
# =============================================================================

func _render_expenses_section(fin: FinanceManager) -> void:
	var title = Label.new()
	title.text = "📤 DETALHAMENTO DE DESPESAS E CUSTOS OPERACIONAIS"
	title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4, 1.0))
	title.add_theme_font_size_override("font_size", 15)
	finances_content_vbox.add_child(title)

	var expenses_list = [
		{
			"icon": "🛒",
			"name": "Compras de Ingredientes e Embalagens",
			"details": "Gastos reais na Central de Compras (Hambúrgueres, Queijos, Batatas, Caixas, Copos, etc.)",
			"metric": "Compras do Dia",
			"amount": fin.get_daily_purchases_cost()
		},
		{
			"icon": "⚡",
			"name": "Energia Elétrica (kWh)",
			"details": "Consumo de equipamentos (Geladeiras, Freezers, Chapa, Fritadeira, TV, AC). Geladeiras abertas consomem 3x mais.",
			"metric": "Consumo: %.2f kWh (Tarifa R$ %.2f/kWh)" % [fin.get_daily_electricity_kwh(), fin.electricity_tariff_kwh],
			"amount": fin.calculate_daily_electricity_cost()
		},
		{
			"icon": "💧",
			"name": "Água e Saneamento (Litros)",
			"details": "Consumo da Pia industrial (lavagem de bucha), Máquina de Refrigerante e Máquina de Suco.",
			"metric": "Consumo: %.1f Litros (Tarifa R$ %.2f/L)" % [fin.get_daily_water_liters(), fin.water_tariff_liter],
			"amount": fin.calculate_daily_water_cost()
		},
		{
			"icon": "👥",
			"name": "Folha de Salários de Funcionários",
			"details": "Salário diário fixo estabelecido na contratação de cada funcionário operacional.",
			"metric": "%d funcionários ativos (R$ %.2f/dia cada)" % [fin.get_active_employees_count(), fin.daily_salary_per_employee],
			"amount": fin.calculate_daily_salaries_cost()
		}
	]

	for exp in expenses_list:
		var card = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.18, 0.10, 0.12, 0.9)
		style.border_color = Color(0.65, 0.25, 0.25, 0.7)
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.set_content_margin_all(14)
		card.add_theme_stylebox_override("panel", style)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)

		var icon_lbl = Label.new()
		icon_lbl.text = exp["icon"]
		icon_lbl.add_theme_font_size_override("font_size", 28)
		hbox.add_child(icon_lbl)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl = Label.new()
		name_lbl.text = exp["name"]
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		vbox.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = exp["details"]
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.7, 0.7, 1.0))
		vbox.add_child(desc_lbl)

		var metric_lbl = Label.new()
		metric_lbl.text = "📊 %s" % exp["metric"]
		metric_lbl.add_theme_font_size_override("font_size", 11)
		metric_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4, 1.0))
		vbox.add_child(metric_lbl)

		hbox.add_child(vbox)

		var amount_lbl = Label.new()
		amount_lbl.text = "-R$ %.2f" % exp["amount"]
		amount_lbl.add_theme_font_size_override("font_size", 18)
		amount_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
		amount_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(amount_lbl)

		card.add_child(hbox)
		finances_content_vbox.add_child(card)

# =============================================================================
# SEÇÃO 4: CONTAS A PAGAR (BILLS)
# =============================================================================

func _render_bills_section(fin: FinanceManager) -> void:
	var title = Label.new()
	title.text = "📑 CONTAS A PAGAR & FATURAS DO RESTAURANTE"
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	title.add_theme_font_size_override("font_size", 15)
	finances_content_vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Gerencie e efetue o pagamento das contas de utilidades e salários diretamente pelo terminal."
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	finances_content_vbox.add_child(desc)

	var bills = fin.get_active_bills()
	for bill_id in ["electricity", "water", "salaries"]:
		if bills.has(bill_id):
			var card = _create_bill_card(bills[bill_id], fin, true)
			finances_content_vbox.add_child(card)

# =============================================================================
# SEÇÃO 5: RELATÓRIOS E HISTÓRICO DOS DIAS
# =============================================================================

func _render_history_section(fin: FinanceManager) -> void:
	var title = Label.new()
	title.text = "📅 HISTÓRICO DE DIAS & RELATÓRIOS FINANCEIROS FECHADOS"
	title.add_theme_color_override("font_color", Color(0.4, 0.85, 0.6, 1.0))
	title.add_theme_font_size_override("font_size", 15)
	finances_content_vbox.add_child(title)

	var history = fin.get_reports_history()
	if history.is_empty():
		var empty_panel = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.15, 0.20, 0.9)
		style.border_color = Color(0.2, 0.3, 0.45, 0.7)
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.set_content_margin_all(20)
		empty_panel.add_theme_stylebox_override("panel", style)

		var empty_lbl = Label.new()
		empty_lbl.text = "📅 Nenhum dia anterior fechado ainda.\nO relatório consolidado de cada dia será salvo e disponibilizado aqui ao encerrar o expediente!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
		empty_panel.add_child(empty_lbl)
		finances_content_vbox.add_child(empty_panel)
		return

	# Renderiza os relatórios do mais recente ao mais antigo
	for i in range(history.size() - 1, -1, -1):
		var rep = history[i]
		var card = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.10, 0.14, 0.20, 0.95)
		style.border_color = Color(0.25, 0.45, 0.7, 0.7)
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.set_content_margin_all(14)
		card.add_theme_stylebox_override("panel", style)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)

		# Top header do dia
		var top_hbox = HBoxContainer.new()
		var day_lbl = Label.new()
		day_lbl.text = "📅 DIA %d (%s)" % [rep.get("day_number", 1), rep.get("weekday", "Segunda-feira").to_upper()]
		day_lbl.add_theme_font_size_override("font_size", 14)
		day_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
		top_hbox.add_child(day_lbl)

		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_hbox.add_child(spacer)

		var net_p: float = rep.get("net_profit", 0.0)
		var profit_lbl = Label.new()
		profit_lbl.text = "Lucro Líquido: %sR$ %.2f" % ["+" if net_p >= 0.0 else "", net_p]
		profit_lbl.add_theme_font_size_override("font_size", 14)
		profit_lbl.add_theme_color_override("font_color", Color(0.35, 0.9, 0.5, 1.0) if net_p >= 0.0 else Color(1.0, 0.4, 0.4, 1.0))
		top_hbox.add_child(profit_lbl)
		vbox.add_child(top_hbox)

		# Linha de métricas
		var metrics_hbox = HBoxContainer.new()
		metrics_hbox.add_theme_constant_override("separation", 20)

		var rev_lbl = Label.new()
		rev_lbl.text = "📈 Receita: R$ %.2f" % rep.get("total_revenue", 0.0)
		rev_lbl.add_theme_font_size_override("font_size", 12)
		rev_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
		metrics_hbox.add_child(rev_lbl)

		var pur_lbl = Label.new()
		pur_lbl.text = "🛒 Compras: R$ %.2f" % rep.get("purchases_cost", 0.0)
		pur_lbl.add_theme_font_size_override("font_size", 12)
		pur_lbl.add_theme_color_override("font_color", Color(0.85, 0.7, 0.7, 1.0))
		metrics_hbox.add_child(pur_lbl)

		var elec_lbl = Label.new()
		elec_lbl.text = "⚡ Energia: R$ %.2f (%.1f kWh)" % [rep.get("electricity_cost", 0.0), rep.get("electricity_kwh", 0.0)]
		elec_lbl.add_theme_font_size_override("font_size", 12)
		elec_lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4, 1.0))
		metrics_hbox.add_child(elec_lbl)

		var water_lbl = Label.new()
		water_lbl.text = "💧 Água: R$ %.2f (%.1f L)" % [rep.get("water_cost", 0.0), rep.get("water_liters", 0.0)]
		water_lbl.add_theme_font_size_override("font_size", 12)
		water_lbl.add_theme_color_override("font_color", Color(0.4, 0.7, 0.9, 1.0))
		metrics_hbox.add_child(water_lbl)

		var sal_lbl = Label.new()
		sal_lbl.text = "👥 Salários: R$ %.2f" % rep.get("salaries_cost", 0.0)
		sal_lbl.add_theme_font_size_override("font_size", 12)
		sal_lbl.add_theme_color_override("font_color", Color(0.8, 0.7, 0.9, 1.0))
		metrics_hbox.add_child(sal_lbl)

		vbox.add_child(metrics_hbox)
		card.add_child(vbox)
		finances_content_vbox.add_child(card)

# =============================================================================
# HELPERS DE CARDS
# =============================================================================

func _create_bill_card(bill: Dictionary, fin: FinanceManager, expanded: bool = false) -> PanelContainer:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	var is_paid: bool = bill.get("is_paid", false)
	var amount: float = bill.get("amount", 0.0)

	if is_paid:
		style.bg_color = Color(0.08, 0.16, 0.12, 0.92)
		style.border_color = Color(0.2, 0.6, 0.35, 0.8)
	else:
		style.bg_color = Color(0.18, 0.12, 0.08, 0.92)
		style.border_color = Color(0.85, 0.55, 0.2, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 8)

	var icon_str = "⚡"
	if bill.get("id") == "water": icon_str = "💧"
	elif bill.get("id") == "salaries": icon_str = "👥"

	var icon_lbl = Label.new()
	icon_lbl.text = icon_str
	icon_lbl.add_theme_font_size_override("font_size", 18)
	top_hbox.add_child(icon_lbl)

	var title_lbl = Label.new()
	title_lbl.text = bill.get("title", "Conta")
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	top_hbox.add_child(title_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)

	var status_badge = Label.new()
	if is_paid:
		status_badge.text = "✔ PAGA"
		status_badge.add_theme_color_override("font_color", Color(0.3, 0.9, 0.45, 1.0))
	else:
		status_badge.text = "⚠️ PENDENTE"
		status_badge.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2, 1.0))
	status_badge.add_theme_font_size_override("font_size", 11)
	top_hbox.add_child(status_badge)

	vbox.add_child(top_hbox)

	var details_lbl = Label.new()
	details_lbl.text = bill.get("details", "")
	details_lbl.add_theme_font_size_override("font_size", 11)
	details_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	vbox.add_child(details_lbl)

	var bot_hbox = HBoxContainer.new()
	bot_hbox.add_theme_constant_override("separation", 10)

	var amount_lbl = Label.new()
	amount_lbl.text = "R$ %.2f" % amount
	amount_lbl.add_theme_font_size_override("font_size", 16)
	amount_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	bot_hbox.add_child(amount_lbl)

	var bot_spacer = Control.new()
	bot_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_hbox.add_child(bot_spacer)

	if not is_paid and amount > 0.0:
		var pay_btn = Button.new()
		pay_btn.custom_minimum_size = Vector2(100 if not expanded else 140, 30)
		pay_btn.text = "💳 PAGAR"
		pay_btn.focus_mode = Control.FOCUS_NONE
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.15, 0.55, 0.25, 0.95)
		btn_style.set_corner_radius_all(6)
		pay_btn.add_theme_stylebox_override("normal", btn_style)
		var bill_id_str = bill.get("id", "")
		pay_btn.pressed.connect(func(): _on_pay_bill_clicked(bill_id_str, fin))
		bot_hbox.add_child(pay_btn)

	vbox.add_child(bot_hbox)
	card.add_child(vbox)
	return card

func _create_breakdown_card(title: String, icon: String, total_amount: float, items: Array[Dictionary], is_expense: bool = false) -> PanelContainer:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.16, 0.22, 0.92) if not is_expense else Color(0.18, 0.12, 0.14, 0.92)
	style.border_color = Color(0.25, 0.45, 0.7, 0.7) if not is_expense else Color(0.7, 0.3, 0.35, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	var header_hbox = HBoxContainer.new()
	var title_lbl = Label.new()
	title_lbl.text = "%s %s" % [icon, title]
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0) if not is_expense else Color(1.0, 0.55, 0.5, 1.0))
	header_hbox.add_child(title_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)

	var total_lbl = Label.new()
	total_lbl.text = "%sR$ %.2f" % ["-" if is_expense else "+", total_amount]
	total_lbl.add_theme_font_size_override("font_size", 15)
	total_lbl.add_theme_color_override("font_color", Color(0.35, 0.9, 0.5, 1.0) if not is_expense else Color(1.0, 0.4, 0.4, 1.0))
	header_hbox.add_child(total_lbl)
	vbox.add_child(header_hbox)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	for item in items:
		var item_hbox = HBoxContainer.new()
		var item_name = Label.new()
		item_name.text = item.get("name", "")
		item_name.add_theme_font_size_override("font_size", 12)
		item_name.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 1.0))
		item_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_hbox.add_child(item_name)

		var item_val = Label.new()
		var amt = item.get("amount", 0.0)
		item_val.text = "R$ %.2f" % amt
		item_val.add_theme_font_size_override("font_size", 12)
		item_val.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
		item_hbox.add_child(item_val)

		vbox.add_child(item_hbox)

	card.add_child(vbox)
	return card

func _on_pay_bill_clicked(bill_id: String, fin: FinanceManager) -> void:
	if not fin:
		return

	var res = fin.pay_bill(bill_id)
	_refresh_header_data()
	_refresh_finances_tab()

	var p = get_parent()
	if p and p.has_node("HUD") and p.get_node("HUD").has_method("show_temporary_feedback"):
		var icon = "💳" if res.get("success", false) else "⚠️"
		p.get_node("HUD").show_temporary_feedback("%s %s" % [icon, res.get("message", "")])
