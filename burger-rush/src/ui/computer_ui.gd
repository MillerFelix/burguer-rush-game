class_name ComputerUI
extends CanvasLayer

const MenuPricingManager = preload("res://src/recipes/menu_pricing_manager.gd")
const FinanceManager = preload("res://src/economy/finance_manager.gd")
const WaterManager = preload("res://src/core/water_manager.gd")
const EmployeeManager = preload("res://src/employees/employee_manager.gd")
const Employee = preload("res://src/employees/employee.gd")
const OrderManager = preload("res://src/orders/order_manager.gd")
const Order = preload("res://src/orders/order.gd")
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")
const ReputationManager = preload("res://src/customers/reputation_manager.gd")
const CustomerReview = preload("res://src/customers/customer_review.gd")
const NewsManager = preload("res://src/news/news_manager.gd")
const CalendarManager = preload("res://src/core/calendar_manager.gd")

# =============================================================================
# BURGER RUSH - SISTEMA ADMINISTRATIVO DO RESTAURANTE (PC v2.0)
#
# Interface institucional moderna e fluida:
# - Header: Identidade Burger Rush, Relógio/Data real, Caixa em tempo real, Botão Fechar.
# - Sidebar: Menu lateral estruturado para todas as abas do sistema.
# - Aba 1: ESTOQUE GERAL (Conexão real com InventoryManager, filtros, busca, cards dinâmicos)
# - Aba 2: CENTRAL DE COMPRAS (Catálogo, mercado volátil, carrinho, fornecedores, entregas)
# - Aba 3: CARDÁPIO & PREÇOS (Controle de precificação e margens de lucro)
# - Aba 4: LIVRO DE RECEITAS (Fichas técnicas e montagem livre)
# - Aba 5: FLUXO FINANCEIRO (Balanço diário, receitas por canal, contas a pagar e histórico)
# - Aba 6: FUNCIONÁRIO (Contratação de 1 funcionário, status real, tarefa atual e salários)
# - Aba 7: PEDIDOS & DELIVERY (Fluxo completo de Delivery, aceite, motoboy e histórico)
# =============================================================================

signal closed()
signal orders_viewed()

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

# Elementos da Aba Funcionário
@onready var employees_tab: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/EmployeesTab
@onready var employees_summary_label: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/EmployeesTab/TopBar/HBox/EmployeesSummaryLabel
@onready var employees_content_vbox: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/EmployeesTab/EmployeesScroll/Margin/EmployeesContentVBox

# Elementos da Aba Pedidos & Delivery
@onready var orders_tab: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab
@onready var orders_summary_label: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/TopBar/HBox/OrdersSummaryLabel
@onready var delivery_kpi_hbox: HBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/DeliveryKPICardsBar/HBox
@onready var btn_orders_all: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/FilterBar/HBox/BtnOrdersAll
@onready var btn_orders_dinein: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/FilterBar/HBox/BtnOrdersDineIn
@onready var btn_orders_drivethru: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/FilterBar/HBox/BtnOrdersDriveThru
@onready var btn_orders_delivery: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/FilterBar/HBox/BtnOrdersDelivery
@onready var orders_content_vbox: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/OrdersScroll/Margin/OrdersContentVBox

# Elementos da Aba Avaliações
@onready var reviews_tab: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/ReviewsTab
@onready var reviews_summary_label: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/ReviewsTab/TopBar/HBox/ReviewsSummaryLabel
@onready var reviews_header_container: HBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/ReviewsTab/ReputationHeaderBar/HeaderContainer
@onready var btn_reviews_all: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/ReviewsTab/FilterBar/HBox/BtnReviewsAll
@onready var btn_reviews_dinein: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/ReviewsTab/FilterBar/HBox/BtnReviewsDineIn
@onready var btn_reviews_drivethru: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/ReviewsTab/FilterBar/HBox/BtnReviewsDriveThru
@onready var btn_reviews_delivery: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/ReviewsTab/FilterBar/HBox/BtnReviewsDelivery
@onready var btn_reviews_5stars: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/ReviewsTab/FilterBar/HBox/BtnReviews5Stars
@onready var btn_reviews_complaints: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/ReviewsTab/FilterBar/HBox/BtnReviewsComplaints
@onready var reviews_content_vbox: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/ReviewsTab/ReviewsScroll/Margin/ReviewsContentVBox

# Elementos da Aba Calendário
@onready var calendar_tab: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/CalendarTab
@onready var calendar_summary_label: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/CalendarTab/TopBar/HBox/CalendarSummaryLabel
@onready var btn_prev_month: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/CalendarTab/CalendarBodyMargin/SplitHBox/MonthPanel/MonthVBox/MonthNavHBox/BtnPrevMonth
@onready var month_title_label: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/CalendarTab/CalendarBodyMargin/SplitHBox/MonthPanel/MonthVBox/MonthNavHBox/MonthTitleLabel
@onready var btn_next_month: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/CalendarTab/CalendarBodyMargin/SplitHBox/MonthPanel/MonthVBox/MonthNavHBox/BtnNextMonth
@onready var week_header_grid: GridContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/CalendarTab/CalendarBodyMargin/SplitHBox/MonthPanel/MonthVBox/WeekHeaderGrid
@onready var days_grid: GridContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/CalendarTab/CalendarBodyMargin/SplitHBox/MonthPanel/MonthVBox/DaysGrid
@onready var selected_day_title_label: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/CalendarTab/CalendarBodyMargin/SplitHBox/DayDetailPanel/DayDetailVBox/DayHeaderHBox/SelectedDayTitleLabel
@onready var btn_day_sub_summary: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/CalendarTab/CalendarBodyMargin/SplitHBox/DayDetailPanel/DayDetailVBox/DaySubNavBar/BtnDaySubSummary
@onready var btn_day_sub_orders: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/CalendarTab/CalendarBodyMargin/SplitHBox/DayDetailPanel/DayDetailVBox/DaySubNavBar/BtnDaySubOrders
@onready var btn_day_sub_reviews: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/CalendarTab/CalendarBodyMargin/SplitHBox/DayDetailPanel/DayDetailVBox/DaySubNavBar/BtnDaySubReviews
@onready var btn_day_sub_news: Button = $MainPanel/OuterWindow/VBox/Body/ContentArea/CalendarTab/CalendarBodyMargin/SplitHBox/DayDetailPanel/DayDetailVBox/DaySubNavBar/BtnDaySubNews
@onready var day_detail_content_vbox: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/CalendarTab/CalendarBodyMargin/SplitHBox/DayDetailPanel/DayDetailVBox/DayDetailScroll/DayDetailContentVBox

# Elementos da Aba Notícias / Jornal da Cidade
@onready var news_tab: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/NewsTab
@onready var news_date_label: Label = $MainPanel/OuterWindow/VBox/Body/ContentArea/NewsTab/TopBar/HBox/NewsDateLabel
@onready var news_content_vbox: VBoxContainer = $MainPanel/OuterWindow/VBox/Body/ContentArea/NewsTab/NewsScroll/Margin/NewsContentVBox

enum TabID {
	INVENTORY,
	PURCHASES,
	MENU,
	RECIPES,
	FINANCES,
	EMPLOYEES,
	ORDERS,
	REVIEWS,
	CALENDAR,
	NEWS
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

var current_orders_filter: String = "ALL" # ALL, DINE_IN, DRIVE_THRU, DELIVERY

var current_reviews_filter: String = "ALL" # ALL, DINE_IN, DRIVE_THRU, DELIVERY, 5_STARS, COMPLAINTS

var viewing_calendar_year: int = 2026
var viewing_calendar_month: int = 1
var selected_calendar_day: int = 1
var selected_calendar_subtab: String = "SUMMARY" # SUMMARY, ORDERS, REVIEWS, NEWS

# Quantidades temporárias selecionadas nos cards antes de adicionar ao carrinho
var card_selected_quantities: Dictionary = {}

var unviewed_orders_count: int = 0
var notified_orders_map: Dictionary = {}
var notification_toast_panel: PanelContainer = null
var notification_toast_label: Label = null
var notification_toast_timer: float = 0.0
var ui_notification_audio: AudioStreamPlayer = null

var nav_buttons_map: Dictionary = {}

var _employee_poll_timer: float = 0.0
var _orders_poll_timer: float = 0.0
var _reviews_poll_timer: float = 0.0

func _ready() -> void:
	visible = false
	_setup_signals()
	_setup_navigation_sidebar()
	_setup_purchases_tab()
	_setup_menu_tab()
	_setup_recipes_tab()
	_setup_finances_tab()
	_setup_employees_tab()
	_setup_orders_tab()
	_setup_reviews_tab()
	_setup_calendar_tab()
	_setup_news_tab()

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
		{"id": TabID.INVENTORY, "icon": "📦", "title": "Estoque", "active": true, "badge": ""},
		{"id": TabID.PURCHASES, "icon": "🛒", "title": "Compras", "active": true, "badge": ""},
		{"id": TabID.MENU, "icon": "🍔", "title": "Cardápio", "active": true, "badge": ""},
		{"id": TabID.RECIPES, "icon": "📖", "title": "Receitas", "active": true, "badge": ""},
		{"id": TabID.FINANCES, "icon": "💵", "title": "Finanças", "active": true, "badge": ""},
		{"id": TabID.EMPLOYEES, "icon": "👥", "title": "Funcionários", "active": true, "badge": ""},
		{"id": TabID.ORDERS, "icon": "📋", "title": "Pedidos", "active": true, "badge": ""},
		{"id": TabID.REVIEWS, "icon": "⭐", "title": "Avaliações", "active": true, "badge": ""},
		{"id": TabID.CALENDAR, "icon": "📅", "title": "Calendário", "active": true, "badge": ""},
		{"id": TabID.NEWS, "icon": "📰", "title": "Notícias / Jornal", "active": true, "badge": ""}
	]

	for t in tabs_def:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 42)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE

		var text = "%s  %s" % [t["icon"], t["title"]]
		btn.text = text

		var tab_id_val: TabID = t["id"]
		btn.pressed.connect(func(): _switch_tab(tab_id_val, t["title"]))
		nav_buttons_container.add_child(btn)
		nav_buttons_map[t["id"]] = btn

	_update_nav_button_styles()

func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var t_title = "Estoque"
	if current_tab == TabID.PURCHASES: t_title = "Compras"
	elif current_tab == TabID.MENU: t_title = "Cardápio"
	elif current_tab == TabID.RECIPES: t_title = "Receitas"
	elif current_tab == TabID.FINANCES: t_title = "Finanças"
	elif current_tab == TabID.EMPLOYEES: t_title = "Funcionários"
	elif current_tab == TabID.ORDERS: t_title = "Pedidos"
	elif current_tab == TabID.REVIEWS: t_title = "Avaliações"
	elif current_tab == TabID.CALENDAR: t_title = "Calendário"
	elif current_tab == TabID.NEWS: t_title = "Notícias / Jornal"
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
	elif current_tab == TabID.EMPLOYEES:
		_refresh_employees_tab()
	elif current_tab == TabID.ORDERS:
		_refresh_orders_tab()
	elif current_tab == TabID.REVIEWS:
		_refresh_reviews_tab()
	elif current_tab == TabID.CALENDAR:
		_refresh_calendar_tab()
	elif current_tab == TabID.NEWS:
		_refresh_news_tab()

func close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()

func _process(delta: float) -> void:
	if visible:
		_refresh_header_data()
		if current_tab == TabID.EMPLOYEES:
			_employee_poll_timer -= delta
			if _employee_poll_timer <= 0.0:
				_employee_poll_timer = 0.30
				_update_employee_live_status()
		elif current_tab == TabID.ORDERS:
			_orders_poll_timer -= delta
			if _orders_poll_timer <= 0.0:
				_orders_poll_timer = 0.80
				_refresh_orders_tab()
		elif current_tab == TabID.REVIEWS:
			_reviews_poll_timer -= delta
			if _reviews_poll_timer <= 0.0:
				_reviews_poll_timer = 1.0
				_refresh_reviews_tab()

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
	var emp_t = employees_tab if employees_tab else _get_tab_node("EmployeesTab")
	var ord_t = orders_tab if orders_tab else _get_tab_node("OrdersTab")
	var rev_t = reviews_tab if reviews_tab else _get_tab_node("ReviewsTab")
	var cal_t = calendar_tab if calendar_tab else _get_tab_node("CalendarTab")
	var news_t = news_tab if news_tab else _get_tab_node("NewsTab")

	inventory_tab = inv_t
	purchases_tab = pur_t
	menu_tab = men_t
	recipes_tab = rec_t
	finances_tab = fin_t
	employees_tab = emp_t
	orders_tab = ord_t
	reviews_tab = rev_t
	calendar_tab = cal_t
	news_tab = news_t

	if inv_t: inv_t.visible = (tab_id == TabID.INVENTORY)
	if pur_t: pur_t.visible = (tab_id == TabID.PURCHASES)
	if men_t: men_t.visible = (tab_id == TabID.MENU)
	if rec_t: rec_t.visible = (tab_id == TabID.RECIPES)
	if fin_t: fin_t.visible = (tab_id == TabID.FINANCES)
	if emp_t: emp_t.visible = (tab_id == TabID.EMPLOYEES)
	if ord_t: ord_t.visible = (tab_id == TabID.ORDERS)
	if rev_t: rev_t.visible = (tab_id == TabID.REVIEWS)
	if cal_t: cal_t.visible = (tab_id == TabID.CALENDAR)
	if news_t: news_t.visible = (tab_id == TabID.NEWS)

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
	elif tab_id == TabID.EMPLOYEES:
		_refresh_employees_tab()
	elif tab_id == TabID.ORDERS:
		_mark_orders_as_viewed()
		_refresh_orders_tab()
	elif tab_id == TabID.REVIEWS:
		_refresh_reviews_tab()
	elif tab_id == TabID.CALENDAR:
		_refresh_calendar_tab()
	elif tab_id == TabID.NEWS:
		_refresh_news_tab()

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

func _create_breakdown_card(title: String, icon: String, total_amount: float, items: Array, is_expense: bool = false) -> PanelContainer:
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
	if current_tab == TabID.EMPLOYEES:
		_refresh_employees_tab()

	var p = get_parent()
	if p and p.has_node("HUD") and p.get_node("HUD").has_method("show_temporary_feedback"):
		var icon = "💳" if res.get("success", false) else "⚠️"
		p.get_node("HUD").show_temporary_feedback("%s %s" % [icon, res.get("message", "")])

# =============================================================================
# ABA 6: GESTÃO DE FUNCIONÁRIO DO RESTAURANTE (EMPLOYEES TAB)
# =============================================================================

var _live_task_label: Label = null
var _live_status_label: Label = null
var _live_state_label: Label = null

func _setup_employees_tab() -> void:
	if not employees_tab:
		employees_tab = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/EmployeesTab")
	if not employees_summary_label:
		employees_summary_label = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/EmployeesTab/TopBar/HBox/EmployeesSummaryLabel")
	if not employees_content_vbox:
		employees_content_vbox = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/EmployeesTab/EmployeesScroll/Margin/EmployeesContentVBox")

	var emp_mgr = EmployeeManager.get_instance()
	if not emp_mgr and is_inside_tree() and get_tree() and get_tree().root:
		emp_mgr = get_tree().root.find_child("EmployeeManager", true, false)
	if emp_mgr:
		if not emp_mgr.employee_hired.is_connected(_on_employee_manager_updated):
			emp_mgr.employee_hired.connect(_on_employee_manager_updated)
		if not emp_mgr.employee_fired.is_connected(_on_employee_manager_updated):
			emp_mgr.employee_fired.connect(_on_employee_manager_updated)

func _on_employee_manager_updated(_arg = null) -> void:
	if visible and current_tab == TabID.EMPLOYEES:
		_refresh_employees_tab()

func _update_employee_live_status() -> void:
	var emp_mgr = EmployeeManager.get_instance()
	if not emp_mgr and is_inside_tree() and get_tree() and get_tree().root:
		emp_mgr = get_tree().root.find_child("EmployeeManager", true, false)
	if not emp_mgr:
		return

	var emp = emp_mgr.get_hired_employee()
	if not emp:
		if _live_task_label != null:
			_refresh_employees_tab()
		return

	var curr_task_text = emp.get_current_task_text() if emp.has_method("get_current_task_text") else "Aguardando tarefa"
	var curr_status_text = emp.get_current_status_text() if emp.has_method("get_current_status_text") else "Aguardando tarefa"
	var curr_state_text = emp.get_work_state_text() if emp.has_method("get_work_state_text") else "Aguardando"

	if _live_task_label and is_instance_valid(_live_task_label):
		_live_task_label.text = "⚡ %s" % curr_task_text
	if _live_status_label and is_instance_valid(_live_status_label):
		_live_status_label.text = "📋 Status atual: %s" % curr_status_text
	if _live_state_label and is_instance_valid(_live_state_label):
		_live_state_label.text = "Estado: %s" % curr_state_text
		if curr_state_text == "Trabalhando":
			_live_state_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.45, 1.0))
		else:
			_live_state_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))

func _refresh_employees_tab() -> void:
	_live_task_label = null
	_live_status_label = null
	_live_state_label = null

	if not employees_tab:
		employees_tab = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/EmployeesTab")
	if not employees_summary_label:
		employees_summary_label = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/EmployeesTab/TopBar/HBox/EmployeesSummaryLabel")
	if not employees_content_vbox:
		employees_content_vbox = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/EmployeesTab/EmployeesScroll/Margin/EmployeesContentVBox")

	if not employees_content_vbox:
		return

	# Limpa o container de conteúdo
	for child in employees_content_vbox.get_children():
		employees_content_vbox.remove_child(child)
		child.queue_free()

	var emp_mgr = EmployeeManager.get_instance()
	if not emp_mgr and is_inside_tree() and get_tree() and get_tree().root:
		emp_mgr = get_tree().root.find_child("EmployeeManager", true, false)

	var econ = EconomyManager.get_instance()
	if not econ and is_inside_tree() and get_tree() and get_tree().root:
		econ = get_tree().root.find_child("EconomyManager", true, false)

	var fin = FinanceManager.get_instance()
	if not fin and is_inside_tree() and get_tree() and get_tree().root:
		fin = get_tree().root.find_child("FinanceManager", true, false)

	var clock = GameClock.get_instance()

	if not emp_mgr:
		var err_lbl = Label.new()
		err_lbl.text = "⚠️ Sistema de funcionários indisponível no momento."
		err_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		employees_content_vbox.add_child(err_lbl)
		return

	if not emp_mgr.has_hired_employee():
		_render_not_hired_employee_view(emp_mgr, econ, clock)
	else:
		var emp = emp_mgr.get_hired_employee()
		_render_hired_employee_view(emp, emp_mgr, fin, econ, clock)

# -----------------------------------------------------------------------------
# TELA 1: NENHUM FUNCIONÁRIO CONTRATADO (APRESENTAÇÃO & CONTRATAÇÃO)
# -----------------------------------------------------------------------------

func _render_not_hired_employee_view(emp_mgr: EmployeeManager, econ: EconomyManager, _clock: GameClock) -> void:
	if employees_summary_label:
		employees_summary_label.text = "Nenhum funcionário contratado • 1 Vaga Disponível"

	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.14, 0.20, 0.95)
	style.border_color = Color(0.25, 0.45, 0.7, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(18)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)

	# 1. Top Header com Avatar e Apresentação
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 16)

	var avatar_box = PanelContainer.new()
	var av_style = StyleBoxFlat.new()
	av_style.bg_color = Color(0.15, 0.20, 0.30, 0.9)
	av_style.border_color = Color(0.3, 0.5, 0.8, 0.8)
	av_style.set_border_width_all(1)
	av_style.set_corner_radius_all(8)
	av_style.set_content_margin_all(12)
	avatar_box.add_theme_stylebox_override("panel", av_style)

	var avatar_lbl = Label.new()
	avatar_lbl.text = "👤"
	avatar_lbl.add_theme_font_size_override("font_size", 36)
	avatar_box.add_child(avatar_lbl)
	header_hbox.add_child(avatar_box)

	var candidate_info = VBoxContainer.new()
	candidate_info.add_theme_constant_override("separation", 4)
	candidate_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl = Label.new()
	name_lbl.text = "Carlos  •  Atendente & Auxiliar Geral"
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	candidate_info.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = "Candidato experiente e polivalente, pronto para assumir tarefas operacionais no restaurante."
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	candidate_info.add_child(desc_lbl)

	var status_badge = Label.new()
	status_badge.text = "⚪ DISPONÍVEL PARA CONTRATAÇÃO (LIMITE: 1 FUNCIONÁRIO)"
	status_badge.add_theme_font_size_override("font_size", 11)
	status_badge.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	candidate_info.add_child(status_badge)

	header_hbox.add_child(candidate_info)
	vbox.add_child(header_hbox)

	vbox.add_child(HSeparator.new())

	# 2. Termos Financeiros de Contratação e Salário
	var terms_hbox = HBoxContainer.new()
	terms_hbox.add_theme_constant_override("separation", 14)
	terms_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hiring_cost_box = _create_mini_info_box("💵 TAXA DE CONTRATAÇÃO", "R$ %.2f" % emp_mgr.hiring_cost, "Taxa única descontada do caixa ao contratar", Color(0.35, 0.9, 0.5, 1.0))
	hiring_cost_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terms_hbox.add_child(hiring_cost_box)

	var salary_box = _create_mini_info_box("👥 SALÁRIO DIÁRIO", "R$ %.2f / dia" % emp_mgr.daily_salary, "Cobrado no final do expediente via Finanças", Color(0.4, 0.8, 1.0, 1.0))
	salary_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terms_hbox.add_child(salary_box)

	vbox.add_child(terms_hbox)

	vbox.add_child(HSeparator.new())

	# 3. Principais Funções Operacionais do Funcionário
	var duties_title = Label.new()
	duties_title.text = "📋 PRINCIPAIS FUNÇÕES E ATRIBUIÇÕES AUTÔNOMAS:"
	duties_title.add_theme_font_size_override("font_size", 13)
	duties_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	vbox.add_child(duties_title)

	var duties_grid = GridContainer.new()
	duties_grid.columns = 2
	duties_grid.add_theme_constant_override("h_separation", 16)
	duties_grid.add_theme_constant_override("v_separation", 6)

	var duties = [
		"🧹 Limpar mesas do salão após refeição",
		"🧼 Limpar poças e sujeiras no chão",
		"🧽 Higienizar bancadas, chapa e fritadeira",
		"🚿 Lavar e desinfetar a bucha na pia",
		"📝 Atender clientes e anotar pedidos no salão",
		"🚗 Atender veículos na janela do Drive-Thru",
		"💵 Atender o caixa e processar pagamentos",
		"📦 Guardar mercadorias recebidas no armazém",
		"🧍 Aguardar tarefas em seu posto de prontidão"
	]

	for d in duties:
		var d_lbl = Label.new()
		d_lbl.text = d
		d_lbl.add_theme_font_size_override("font_size", 12)
		d_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95, 1.0))
		duties_grid.add_child(d_lbl)

	vbox.add_child(duties_grid)

	vbox.add_child(HSeparator.new())

	# 4. Botão de Ação / Contratação
	var bottom_action_hbox = HBoxContainer.new()
	bottom_action_hbox.add_theme_constant_override("separation", 16)

	var hint_lbl = Label.new()
	hint_lbl.text = "Ao contratar, o funcionário chegará de fora do restaurante e assumirá suas tarefas imediatamente."
	hint_lbl.add_theme_font_size_override("font_size", 11)
	hint_lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 1.0))
	hint_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom_action_hbox.add_child(hint_lbl)

	var hire_btn = Button.new()
	hire_btn.custom_minimum_size = Vector2(250, 42)
	hire_btn.text = "✍️ CONTRATAR FUNCIONÁRIO"
	hire_btn.focus_mode = Control.FOCUS_NONE
	hire_btn.add_theme_font_size_override("font_size", 13)

	var current_money = econ.get_money() if econ else 0.0
	var can_afford = current_money >= emp_mgr.hiring_cost

	var btn_style = StyleBoxFlat.new()
	if can_afford:
		btn_style.bg_color = Color(0.12, 0.55, 0.3, 1.0)
		btn_style.border_color = Color(0.25, 0.8, 0.45, 1.0)
	else:
		btn_style.bg_color = Color(0.25, 0.25, 0.3, 0.7)
		btn_style.border_color = Color(0.4, 0.4, 0.45, 0.7)
		hire_btn.tooltip_text = "Saldo insuficiente (R$ %.2f necessário)" % emp_mgr.hiring_cost

	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(6)
	hire_btn.add_theme_stylebox_override("normal", btn_style)
	hire_btn.add_theme_stylebox_override("hover", btn_style)
	hire_btn.add_theme_stylebox_override("pressed", btn_style)

	hire_btn.pressed.connect(func(): _on_hire_employee_clicked(emp_mgr))
	bottom_action_hbox.add_child(hire_btn)

	vbox.add_child(bottom_action_hbox)
	card.add_child(vbox)
	employees_content_vbox.add_child(card)

# -----------------------------------------------------------------------------
# TELA 2: FUNCIONÁRIO CONTRATADO (DASHBOARD & STATUS EM TEMPO REAL)
# -----------------------------------------------------------------------------

func _render_hired_employee_view(emp: Employee, emp_mgr: EmployeeManager, fin: FinanceManager, _econ: EconomyManager, _clock: GameClock) -> void:
	if employees_summary_label:
		employees_summary_label.text = "Funcionário Contratado • %s (%s)" % [emp.employee_name, emp.get_role_name()]

	# 1. Header Card com Identidade do Funcionário
	var id_card = PanelContainer.new()
	var id_style = StyleBoxFlat.new()
	id_style.bg_color = Color(0.10, 0.14, 0.20, 0.95)
	id_style.border_color = Color(0.25, 0.45, 0.7, 0.7)
	id_style.set_border_width_all(1)
	id_style.set_corner_radius_all(8)
	id_style.set_content_margin_all(14)
	id_card.add_theme_stylebox_override("panel", id_style)

	var id_hbox = HBoxContainer.new()
	id_hbox.add_theme_constant_override("separation", 14)

	var av_lbl = Label.new()
	av_lbl.text = "🧑‍🍳"
	av_lbl.add_theme_font_size_override("font_size", 32)
	id_hbox.add_child(av_lbl)

	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl = Label.new()
	name_lbl.text = "%s  •  %s" % [emp.employee_name, emp.get_role_name()]
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	info_vbox.add_child(name_lbl)

	var meta_lbl = Label.new()
	meta_lbl.text = "📅 Contratado no Dia %d  │  🏆 Tarefas Concluídas: %d" % [emp.hired_day, emp.tasks_completed]
	meta_lbl.add_theme_font_size_override("font_size", 11)
	meta_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	info_vbox.add_child(meta_lbl)

	id_hbox.add_child(info_vbox)

	var badge_lbl = Label.new()
	badge_lbl.text = "🟢 CONTRATADO"
	badge_lbl.add_theme_font_size_override("font_size", 12)
	badge_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.45, 1.0))
	badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	id_hbox.add_child(badge_lbl)

	id_card.add_child(id_hbox)
	employees_content_vbox.add_child(id_card)

	# 2. ÁREA DE DESTAQUE - TAREFA ATUAL & STATUS DO NPC
	var task_card = PanelContainer.new()
	var task_style = StyleBoxFlat.new()
	task_style.bg_color = Color(0.08, 0.16, 0.22, 0.95)
	task_style.border_color = Color(0.3, 0.65, 0.95, 0.9)
	task_style.border_width_left = 3
	task_style.border_width_top = 1
	task_style.border_width_right = 1
	task_style.border_width_bottom = 1
	task_style.set_corner_radius_all(8)
	task_style.set_content_margin_all(14)
	task_card.add_theme_stylebox_override("panel", task_style)

	var task_vbox = VBoxContainer.new()
	task_vbox.add_theme_constant_override("separation", 6)

	var task_header_lbl = Label.new()
	task_header_lbl.text = "⚡ TAREFA ATUAL DO FUNCIONÁRIO"
	task_header_lbl.add_theme_font_size_override("font_size", 12)
	task_header_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	task_vbox.add_child(task_header_lbl)

	var task_name = emp.get_current_task_text() if emp.has_method("get_current_task_text") else "Aguardando tarefa"
	_live_task_label = Label.new()
	_live_task_label.text = "⚡ %s" % task_name
	_live_task_label.add_theme_font_size_override("font_size", 17)
	_live_task_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	task_vbox.add_child(_live_task_label)

	var sub_row = HBoxContainer.new()
	sub_row.add_theme_constant_override("separation", 16)

	var status_name = emp.get_current_status_text() if emp.has_method("get_current_status_text") else "Aguardando tarefa"
	_live_status_label = Label.new()
	_live_status_label.text = "📋 Status atual: %s" % status_name
	_live_status_label.add_theme_font_size_override("font_size", 12)
	_live_status_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	sub_row.add_child(_live_status_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_row.add_child(spacer)

	var state_name = emp.get_work_state_text() if emp.has_method("get_work_state_text") else "Aguardando"
	_live_state_label = Label.new()
	_live_state_label.text = "Estado: %s" % state_name
	_live_state_label.add_theme_font_size_override("font_size", 12)
	if state_name == "Trabalhando":
		_live_state_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.45, 1.0))
	else:
		_live_state_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
	sub_row.add_child(_live_state_label)

	task_vbox.add_child(sub_row)
	task_card.add_child(task_vbox)
	employees_content_vbox.add_child(task_card)

	# 3. Cards Financeiros (Salário Diário e Salário Pendente)
	var fin_hbox = HBoxContainer.new()
	fin_hbox.add_theme_constant_override("separation", 12)
	fin_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Card A: Salário Diário
	var salary_daily_card = _create_mini_info_box("👥 SALÁRIO DIÁRIO", "R$ %.2f / dia" % emp.daily_salary, "Gerado no final do dia como conta a pagar", Color(0.4, 0.8, 1.0, 1.0))
	salary_daily_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fin_hbox.add_child(salary_daily_card)

	# Card B: Salário Pendente
	var pending_salary: float = 0.0
	var is_salary_paid: bool = true
	if fin:
		var bills = fin.get_active_bills()
		if bills.has("salaries"):
			var b = bills["salaries"]
			pending_salary = b.get("amount", 0.0)
			is_salary_paid = b.get("is_paid", true)

	var salary_pending_card = PanelContainer.new()
	var p_style = StyleBoxFlat.new()
	if not is_salary_paid and pending_salary > 0.0:
		p_style.bg_color = Color(0.18, 0.12, 0.08, 0.95)
		p_style.border_color = Color(0.85, 0.55, 0.2, 0.8)
	else:
		p_style.bg_color = Color(0.08, 0.16, 0.12, 0.95)
		p_style.border_color = Color(0.2, 0.6, 0.35, 0.8)

	p_style.set_border_width_all(1)
	p_style.set_corner_radius_all(8)
	p_style.set_content_margin_all(12)
	salary_pending_card.add_theme_stylebox_override("panel", p_style)
	salary_pending_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var p_vbox = VBoxContainer.new()
	p_vbox.add_theme_constant_override("separation", 4)

	var p_top_hbox = HBoxContainer.new()
	var p_title_lbl = Label.new()
	p_title_lbl.text = "📑 SALÁRIO PENDENTE"
	p_title_lbl.add_theme_font_size_override("font_size", 11)
	p_title_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	p_top_hbox.add_child(p_title_lbl)

	var p_spacer = Control.new()
	p_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_top_hbox.add_child(p_spacer)

	var p_badge = Label.new()
	if not is_salary_paid and pending_salary > 0.0:
		p_badge.text = "⚠️ PENDENTE"
		p_badge.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2, 1.0))
	else:
		p_badge.text = "✔ EM DIA"
		p_badge.add_theme_color_override("font_color", Color(0.3, 0.9, 0.45, 1.0))
	p_badge.add_theme_font_size_override("font_size", 10)
	p_top_hbox.add_child(p_badge)
	p_vbox.add_child(p_top_hbox)

	var p_val_hbox = HBoxContainer.new()
	var p_val_lbl = Label.new()
	p_val_lbl.text = "R$ %.2f" % pending_salary
	p_val_lbl.add_theme_font_size_override("font_size", 17)
	p_val_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0) if not is_salary_paid and pending_salary > 0.0 else Color(0.3, 0.9, 0.45, 1.0))
	p_val_hbox.add_child(p_val_lbl)

	var p_val_spacer = Control.new()
	p_val_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_val_hbox.add_child(p_val_spacer)

	if not is_salary_paid and pending_salary > 0.0:
		var pay_salary_btn = Button.new()
		pay_salary_btn.text = "💳 PAGAR SALÁRIO"
		pay_salary_btn.focus_mode = Control.FOCUS_NONE
		pay_salary_btn.add_theme_font_size_override("font_size", 11)
		var p_btn_style = StyleBoxFlat.new()
		p_btn_style.bg_color = Color(0.15, 0.55, 0.25, 0.95)
		p_btn_style.set_corner_radius_all(6)
		pay_salary_btn.add_theme_stylebox_override("normal", p_btn_style)
		pay_salary_btn.pressed.connect(func(): _on_pay_bill_clicked("salaries", fin))
		p_val_hbox.add_child(pay_salary_btn)

	p_vbox.add_child(p_val_hbox)
	salary_pending_card.add_child(p_vbox)
	fin_hbox.add_child(salary_pending_card)

	employees_content_vbox.add_child(fin_hbox)

	# 4. Painel de Atribuições e Status de Operação
	var duties_card = PanelContainer.new()
	var d_style = StyleBoxFlat.new()
	d_style.bg_color = Color(0.10, 0.14, 0.20, 0.95)
	d_style.border_color = Color(0.2, 0.3, 0.45, 0.7)
	d_style.set_border_width_all(1)
	d_style.set_corner_radius_all(8)
	d_style.set_content_margin_all(14)
	duties_card.add_theme_stylebox_override("panel", d_style)

	var d_vbox = VBoxContainer.new()
	d_vbox.add_theme_constant_override("separation", 8)

	var d_title = Label.new()
	d_title.text = "🛠️ FUNÇÕES ATIVAS DO FUNCIONÁRIO (AUTÔNOMO)"
	d_title.add_theme_font_size_override("font_size", 13)
	d_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	d_vbox.add_child(d_title)

	var d_grid = GridContainer.new()
	d_grid.columns = 3
	d_grid.add_theme_constant_override("h_separation", 14)
	d_grid.add_theme_constant_override("v_separation", 6)

	var active_functions = [
		"✔ Limpar mesas sujas",
		"✔ Limpar poças no chão",
		"✔ Limpar bancadas & chapa",
		"✔ Lavar bucha na pia",
		"✔ Atender mesas do salão",
		"✔ Atender Drive-Thru",
		"✔ Operar o caixa",
		"✔ Guardar mercadorias",
		"✔ Aguardar no posto"
	]

	for f in active_functions:
		var f_lbl = Label.new()
		f_lbl.text = f
		f_lbl.add_theme_font_size_override("font_size", 11)
		f_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95, 1.0))
		d_grid.add_child(f_lbl)

	d_vbox.add_child(d_grid)

	d_vbox.add_child(HSeparator.new())

	# 5. Barra Inferior de Administração (Demissão / Controle)
	var admin_hbox = HBoxContainer.new()
	admin_hbox.add_theme_constant_override("separation", 14)

	var limit_lbl = Label.new()
	limit_lbl.text = "O Burger Rush permite 1 funcionário por restaurante. Para trocar ou cancelar a folha, utilize a demissão."
	limit_lbl.add_theme_font_size_override("font_size", 11)
	limit_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 1.0))
	limit_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	limit_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	admin_hbox.add_child(limit_lbl)

	var fire_btn = Button.new()
	fire_btn.custom_minimum_size = Vector2(160, 32)
	fire_btn.text = "❌ DEMITIR FUNCIONÁRIO"
	fire_btn.focus_mode = Control.FOCUS_NONE
	fire_btn.add_theme_font_size_override("font_size", 11)
	var fire_style = StyleBoxFlat.new()
	fire_style.bg_color = Color(0.55, 0.15, 0.15, 0.9)
	fire_style.border_color = Color(0.8, 0.3, 0.3, 0.8)
	fire_style.set_border_width_all(1)
	fire_style.set_corner_radius_all(6)
	fire_btn.add_theme_stylebox_override("normal", fire_style)
	fire_btn.pressed.connect(func(): _on_fire_employee_clicked(emp.employee_id, emp_mgr))
	admin_hbox.add_child(fire_btn)

	d_vbox.add_child(admin_hbox)
	duties_card.add_child(d_vbox)
	employees_content_vbox.add_child(duties_card)

func _create_mini_info_box(title: String, value: String, details: String, value_color: Color) -> PanelContainer:
	var box = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.16, 0.22, 0.92)
	style.border_color = Color(0.25, 0.45, 0.7, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	box.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	vbox.add_child(title_lbl)

	var val_lbl = Label.new()
	val_lbl.text = value
	val_lbl.add_theme_font_size_override("font_size", 17)
	val_lbl.add_theme_color_override("font_color", value_color)
	vbox.add_child(val_lbl)

	var det_lbl = Label.new()
	det_lbl.text = details
	det_lbl.add_theme_font_size_override("font_size", 10)
	det_lbl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7, 1.0))
	vbox.add_child(det_lbl)

	box.add_child(vbox)
	return box

func _on_hire_employee_clicked(emp_mgr: EmployeeManager) -> void:
	if not emp_mgr:
		return

	var res = emp_mgr.hire_employee("Carlos", Employee.Role.GENERAL)
	_refresh_header_data()
	_refresh_employees_tab()

	var fin = FinanceManager.get_instance()
	if not fin and is_inside_tree() and get_tree() and get_tree().root:
		fin = get_tree().root.find_child("FinanceManager", true, false)
	if fin:
		fin._ensure_daily_bills()

	var p = get_parent()
	if p and p.has_node("HUD") and p.get_node("HUD").has_method("show_temporary_feedback"):
		var icon = "🧑‍🍳" if res.get("success", false) else "⚠️"
		p.get_node("HUD").show_temporary_feedback("%s %s" % [icon, res.get("message", "")])

func _on_fire_employee_clicked(emp_id: int, emp_mgr: EmployeeManager) -> void:
	if not emp_mgr:
		return

	var ok = emp_mgr.fire_employee(emp_id)
	_refresh_header_data()
	_refresh_employees_tab()

	var p = get_parent()
	if p and p.has_node("HUD") and p.get_node("HUD").has_method("show_temporary_feedback"):
		if ok:
			p.get_node("HUD").show_temporary_feedback("👋 Funcionário demitido. Vaga liberada no PC.")
		else:
			p.get_node("HUD").show_temporary_feedback("⚠️ Falha ao demitir funcionário.")

# =============================================================================
# ABA 7: GESTÃO DE PEDIDOS & DELIVERY (ORDERS TAB)
# =============================================================================

func _setup_orders_tab() -> void:
	if not orders_tab:
		orders_tab = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab")
	if not orders_summary_label:
		orders_summary_label = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/TopBar/HBox/OrdersSummaryLabel")
	if not delivery_kpi_hbox:
		delivery_kpi_hbox = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/DeliveryKPICardsBar/HBox")
	if not btn_orders_all:
		btn_orders_all = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/FilterBar/HBox/BtnOrdersAll")
	if not btn_orders_dinein:
		btn_orders_dinein = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/FilterBar/HBox/BtnOrdersDineIn")
	if not btn_orders_drivethru:
		btn_orders_drivethru = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/FilterBar/HBox/BtnOrdersDriveThru")
	if not btn_orders_delivery:
		btn_orders_delivery = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/FilterBar/HBox/BtnOrdersDelivery")
	if not orders_content_vbox:
		orders_content_vbox = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/OrdersScroll/Margin/OrdersContentVBox")

	if btn_orders_all and not btn_orders_all.pressed.is_connected(_on_orders_filter_all_pressed):
		btn_orders_all.pressed.connect(_on_orders_filter_all_pressed)
	if btn_orders_dinein and not btn_orders_dinein.pressed.is_connected(_on_orders_filter_dinein_pressed):
		btn_orders_dinein.pressed.connect(_on_orders_filter_dinein_pressed)
	if btn_orders_drivethru and not btn_orders_drivethru.pressed.is_connected(_on_orders_filter_drivethru_pressed):
		btn_orders_drivethru.pressed.connect(_on_orders_filter_drivethru_pressed)
	if btn_orders_delivery and not btn_orders_delivery.pressed.is_connected(_on_orders_filter_delivery_pressed):
		btn_orders_delivery.pressed.connect(_on_orders_filter_delivery_pressed)

	var om = OrderManager.get_instance()
	if not om and is_inside_tree() and get_tree() and get_tree().root:
		om = get_tree().root.find_child("OrderManager", true, false)

	if om:
		if not om.order_created.is_connected(_on_order_manager_updated):
			om.order_created.connect(_on_order_manager_updated)
		if not om.order_updated.is_connected(_on_order_manager_updated):
			om.order_updated.connect(_on_order_manager_updated)
		if not om.order_completed.is_connected(_on_order_manager_updated):
			om.order_completed.connect(_on_order_manager_updated)
		if not om.order_cancelled.is_connected(_on_order_manager_updated):
			om.order_cancelled.connect(_on_order_manager_updated)
		if not om.delivery_order_arrived.is_connected(_on_delivery_order_arrived):
			om.delivery_order_arrived.connect(_on_delivery_order_arrived)

func _on_orders_filter_all_pressed() -> void: _set_orders_filter("ALL")
func _on_orders_filter_dinein_pressed() -> void: _set_orders_filter("DINE_IN")
func _on_orders_filter_drivethru_pressed() -> void: _set_orders_filter("DRIVE_THRU")
func _on_orders_filter_delivery_pressed() -> void: _set_orders_filter("DELIVERY")

func _set_orders_filter(filter_type: String) -> void:
	current_orders_filter = filter_type
	_update_orders_filter_button_styles()
	_refresh_orders_tab()

func _update_orders_filter_button_styles() -> void:
	var buttons = [
		{"btn": btn_orders_all, "key": "ALL"},
		{"btn": btn_orders_dinein, "key": "DINE_IN"},
		{"btn": btn_orders_drivethru, "key": "DRIVE_THRU"},
		{"btn": btn_orders_delivery, "key": "DELIVERY"}
	]

	for b in buttons:
		var btn: Button = b["btn"]
		if not btn or not is_instance_valid(btn):
			continue
		var is_active = (current_orders_filter == b["key"])
		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(6)
		style.set_content_margin_all(6)
		if is_active:
			style.bg_color = Color(0.2, 0.4, 0.65, 1.0)
			style.border_color = Color(1.0, 0.85, 0.2, 1.0)
			style.set_border_width_all(2)
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		else:
			style.bg_color = Color(0.12, 0.16, 0.22, 0.9)
			style.border_color = Color(0.25, 0.35, 0.5, 0.5)
			style.set_border_width_all(1)
			btn.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

func _on_order_manager_updated(_order: Order = null) -> void:
	if visible and current_tab == TabID.ORDERS:
		_refresh_orders_tab()

func _on_delivery_order_arrived(_order: Order) -> void:
	if visible and current_tab == TabID.ORDERS:
		_refresh_orders_tab()

func _refresh_orders_tab() -> void:
	if not orders_tab:
		orders_tab = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab")
	if not orders_summary_label:
		orders_summary_label = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/TopBar/HBox/OrdersSummaryLabel")
	if not delivery_kpi_hbox:
		delivery_kpi_hbox = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/DeliveryKPICardsBar/HBox")
	if not orders_content_vbox:
		orders_content_vbox = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/OrdersTab/OrdersScroll/Margin/OrdersContentVBox")

	if not orders_content_vbox:
		return

	_update_orders_filter_button_styles()

	var om = OrderManager.get_instance()
	if not om and is_inside_tree() and get_tree() and get_tree().root:
		om = get_tree().root.find_child("OrderManager", true, false)

	if not om:
		return

	var active_list = om.get_active_orders()
	var delivery_count = 0
	for o in active_list:
		if o.source_type == "DELIVERY":
			delivery_count += 1

	if orders_summary_label:
		orders_summary_label.text = "%d Pedidos Ativos  │  %d Delivery em Aberto" % [active_list.size(), delivery_count]

	# 1. Renderiza os KPIs de Delivery no topo
	_render_delivery_kpis(om)

	# Limpa o container de conteúdo
	for child in orders_content_vbox.get_children():
		orders_content_vbox.remove_child(child)
		child.queue_free()

	# 2. Renderiza a Seção de Pedidos Ativos
	_render_active_orders_section(om)

	# 3. Renderiza a Seção de Histórico do Dia
	_render_orders_history_section(om)

func _render_delivery_kpis(om: OrderManager) -> void:
	if not delivery_kpi_hbox:
		return

	for child in delivery_kpi_hbox.get_children():
		delivery_kpi_hbox.remove_child(child)
		child.queue_free()

	var stats = om.get_delivery_summary_stats()

	var cards_data = [
		{"icon": "📱", "title": "NOVOS (APP)", "val": str(stats["new"]), "color": Color(1.0, 0.85, 0.2, 1.0) if stats["new"] > 0 else Color(0.7, 0.75, 0.85, 1.0)},
		{"icon": "🍳", "title": "EM PREPARO", "val": str(stats["preparing"]), "color": Color(0.4, 0.8, 1.0, 1.0)},
		{"icon": "🛵", "title": "AG. RETIRADA", "val": str(stats["waiting_courier"]), "color": Color(1.0, 0.65, 0.2, 1.0) if stats["waiting_courier"] > 0 else Color(0.7, 0.75, 0.85, 1.0)},
		{"icon": "💨", "title": "EM ENTREGA", "val": str(stats["in_delivery"]), "color": Color(0.65, 0.5, 1.0, 1.0)},
		{"icon": "✔", "title": "FINALIZADOS", "val": str(stats["completed"]), "color": Color(0.35, 0.9, 0.5, 1.0)}
	]

	for c in cards_data:
		var kpi_card = _create_kpi_mini_card(c["icon"], c["title"], c["val"], c["color"])
		kpi_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		delivery_kpi_hbox.add_child(kpi_card)

func _create_kpi_mini_card(icon: String, title: String, val: String, val_color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.14, 0.20, 0.95)
	style.border_color = Color(0.25, 0.40, 0.60, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var title_lbl = Label.new()
	title_lbl.text = "%s %s" % [icon, title]
	title_lbl.add_theme_font_size_override("font_size", 10)
	title_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	vbox.add_child(title_lbl)

	var val_lbl = Label.new()
	val_lbl.text = val
	val_lbl.add_theme_font_size_override("font_size", 16)
	val_lbl.add_theme_color_override("font_color", val_color)
	vbox.add_child(val_lbl)

	panel.add_child(vbox)
	return panel

func _render_active_orders_section(om: OrderManager) -> void:
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)

	var title_lbl = Label.new()
	title_lbl.text = "⚡ PEDIDOS ATIVOS EM ANDAMENTO"
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	header_hbox.add_child(title_lbl)
	orders_content_vbox.add_child(header_hbox)

	var filtered_orders = om.get_filtered_active_orders(current_orders_filter)

	if filtered_orders.is_empty():
		var empty_panel = PanelContainer.new()
		var e_style = StyleBoxFlat.new()
		e_style.bg_color = Color(0.10, 0.13, 0.18, 0.8)
		e_style.set_corner_radius_all(6)
		e_style.set_content_margin_all(14)
		empty_panel.add_theme_stylebox_override("panel", e_style)

		var empty_lbl = Label.new()
		empty_lbl.text = "Nenhum pedido ativo no momento nesta categoria."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 1.0))
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_panel.add_child(empty_lbl)
		orders_content_vbox.add_child(empty_panel)
		return

	# Grid de cards de pedidos ativos
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)

	for order in filtered_orders:
		var order_card = _create_active_order_card(order, om)
		order_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(order_card)

	orders_content_vbox.add_child(grid)

func _create_active_order_card(order: Order, om: OrderManager) -> PanelContainer:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()

	var is_new_delivery = (order.source_type == "DELIVERY" and order.delivery_stage == "NEW_RECEIVED")
	if is_new_delivery:
		style.bg_color = Color(0.16, 0.14, 0.08, 0.95)
		style.border_color = Color(1.0, 0.8, 0.2, 0.9)
		style.border_width_left = 3
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
	else:
		style.bg_color = Color(0.10, 0.14, 0.20, 0.95)
		style.border_color = Color(0.25, 0.45, 0.7, 0.7)
		style.set_border_width_all(1)

	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	# 1. Header do Pedido
	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 10)

	var id_lbl = Label.new()
	id_lbl.text = "PEDIDO #%03d" % order.id
	id_lbl.add_theme_font_size_override("font_size", 14)
	id_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	top_hbox.add_child(id_lbl)

	var src_lbl = Label.new()
	src_lbl.text = "[ %s ]" % order.get_source_display_name()
	src_lbl.add_theme_font_size_override("font_size", 11)
	src_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	top_hbox.add_child(src_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)

	var time_lbl = Label.new()
	time_lbl.text = "⏰ %s (⏳ %s)" % [order.created_clock_time, order.get_formatted_wait_time()]
	time_lbl.add_theme_font_size_override("font_size", 11)
	time_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	top_hbox.add_child(time_lbl)

	vbox.add_child(top_hbox)
	vbox.add_child(HSeparator.new())

	# 2. Lista de Itens do Pedido
	var items_vbox = VBoxContainer.new()
	items_vbox.add_theme_constant_override("separation", 3)

	for it in order.items:
		var it_hbox = HBoxContainer.new()
		var qty = it.get("quantity", 1)
		var name_str = it.get("product_name", "Item")
		var price = it.get("unit_price", 0.0) * qty

		var item_lbl = Label.new()
		item_lbl.text = "• %dx %s" % [qty, name_str]
		item_lbl.add_theme_font_size_override("font_size", 12)
		item_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95, 1.0))
		item_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		it_hbox.add_child(item_lbl)

		var price_lbl = Label.new()
		price_lbl.text = "R$ %.2f" % price
		price_lbl.add_theme_font_size_override("font_size", 12)
		price_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
		it_hbox.add_child(price_lbl)

		items_vbox.add_child(it_hbox)

	vbox.add_child(items_vbox)
	vbox.add_child(HSeparator.new())

	# 3. Rodapé com Status e Ações
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 10)

	var total_lbl = Label.new()
	total_lbl.text = "Total: R$ %.2f" % order.total_price
	total_lbl.add_theme_font_size_override("font_size", 13)
	total_lbl.add_theme_color_override("font_color", Color(0.35, 0.9, 0.5, 1.0))
	bottom_hbox.add_child(total_lbl)

	var b_spacer = Control.new()
	b_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(b_spacer)

	if is_new_delivery:
		var accept_btn = Button.new()
		accept_btn.text = "✍️ ACEITAR PEDIDO"
		accept_btn.focus_mode = Control.FOCUS_NONE
		accept_btn.add_theme_font_size_override("font_size", 11)
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.12, 0.55, 0.3, 1.0)
		btn_style.border_color = Color(0.25, 0.8, 0.45, 1.0)
		btn_style.set_border_width_all(1)
		btn_style.set_corner_radius_all(6)
		accept_btn.add_theme_stylebox_override("normal", btn_style)
		accept_btn.pressed.connect(func(): _on_accept_delivery_clicked(order.id, om))
		bottom_hbox.add_child(accept_btn)
	else:
		var status_badge = Label.new()
		status_badge.text = order.get_state_string()
		status_badge.add_theme_font_size_override("font_size", 11)
		if order.delivery_stage == "WAITING_COURIER":
			status_badge.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2, 1.0))
		elif order.delivery_stage == "IN_DELIVERY":
			status_badge.add_theme_color_override("font_color", Color(0.65, 0.5, 1.0, 1.0))
		else:
			status_badge.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
		bottom_hbox.add_child(status_badge)

	vbox.add_child(bottom_hbox)
	card.add_child(vbox)
	return card

func _render_orders_history_section(om: OrderManager) -> void:
	orders_content_vbox.add_child(HSeparator.new())

	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)

	var title_lbl = Label.new()
	title_lbl.text = "📑 HISTÓRICO DO DIA (TODOS OS PEDIDOS FINALIZADOS)"
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	header_hbox.add_child(title_lbl)
	orders_content_vbox.add_child(header_hbox)

	var history = om.get_order_history()

	if history.is_empty():
		var empty_panel = PanelContainer.new()
		var e_style = StyleBoxFlat.new()
		e_style.bg_color = Color(0.10, 0.13, 0.18, 0.8)
		e_style.set_corner_radius_all(6)
		e_style.set_content_margin_all(14)
		empty_panel.add_theme_stylebox_override("panel", e_style)

		var empty_lbl = Label.new()
		empty_lbl.text = "Nenhum pedido concluído ou cancelado no histórico de hoje."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 1.0))
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_panel.add_child(empty_lbl)
		orders_content_vbox.add_child(empty_panel)
		return

	# Tabela/Lista de Pedidos no Histórico
	var history_card = PanelContainer.new()
	var h_style = StyleBoxFlat.new()
	h_style.bg_color = Color(0.10, 0.14, 0.20, 0.95)
	h_style.border_color = Color(0.2, 0.3, 0.45, 0.7)
	h_style.set_border_width_all(1)
	h_style.set_corner_radius_all(8)
	h_style.set_content_margin_all(12)
	history_card.add_theme_stylebox_override("panel", h_style)

	var h_vbox = VBoxContainer.new()
	h_vbox.add_theme_constant_override("separation", 8)

	# Itera sobre o histórico em ordem cronológica reversa (mais recentes primeiro)
	for i in range(history.size() - 1, -1, -1):
		var h = history[i]
		var row_panel = _create_history_row(h)
		h_vbox.add_child(row_panel)

	history_card.add_child(h_vbox)
	orders_content_vbox.add_child(history_card)

func _create_history_row(h: Dictionary) -> PanelContainer:
	var row = PanelContainer.new()
	var style = StyleBoxFlat.new()
	var is_wrong = h.get("is_wrong", false)
	var is_paid = h.get("is_paid", false)
	var status_str = h.get("status", "Concluído")
	var is_unaccepted = ("Não aceito" in status_str or "Nao aceito" in status_str)

	if is_unaccepted:
		style.bg_color = Color(0.16, 0.12, 0.08, 0.85)
		style.border_color = Color(0.85, 0.55, 0.20, 0.70)
	elif is_wrong:
		style.bg_color = Color(0.18, 0.10, 0.10, 0.80)
		style.border_color = Color(0.80, 0.25, 0.25, 0.70)
	else:
		style.bg_color = Color(0.12, 0.16, 0.22, 0.80)
		style.border_color = Color(0.25, 0.35, 0.50, 0.60)

	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	row.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	var id_lbl = Label.new()
	id_lbl.text = "#%03d" % h.get("id", 0)
	id_lbl.add_theme_font_size_override("font_size", 12)
	id_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	hbox.add_child(id_lbl)

	var src_lbl = Label.new()
	src_lbl.text = h.get("source_name", "Origem")
	src_lbl.add_theme_font_size_override("font_size", 11)
	src_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	hbox.add_child(src_lbl)

	# Resumo compacto de itens
	var items_summary: Array[String] = []
	for it in h.get("items", []):
		items_summary.append("%dx %s" % [it.get("quantity", 1), it.get("product_name", "Item")])
	var items_lbl = Label.new()
	items_lbl.text = ", ".join(items_summary)
	items_lbl.add_theme_font_size_override("font_size", 11)
	items_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95, 1.0))
	items_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hbox.add_child(items_lbl)

	var time_lbl = Label.new()
	time_lbl.text = "%s ➔ %s" % [h.get("created_clock_time", "12:00"), h.get("completed_clock_time", "12:00")]
	time_lbl.add_theme_font_size_override("font_size", 10)
	time_lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 1.0))
	hbox.add_child(time_lbl)

	var total_lbl = Label.new()
	var amt = h.get("total_price", 0.0)
	total_lbl.text = "R$ %.2f" % amt
	total_lbl.add_theme_font_size_override("font_size", 12)
	if is_paid:
		total_lbl.add_theme_color_override("font_color", Color(0.35, 0.9, 0.5, 1.0))
	elif is_unaccepted:
		total_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.80, 1.0))
	else:
		total_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
	hbox.add_child(total_lbl)

	var status_lbl = Label.new()
	status_lbl.text = status_str
	status_lbl.add_theme_font_size_override("font_size", 11)
	if is_paid:
		status_lbl.add_theme_color_override("font_color", Color(0.35, 0.9, 0.5, 1.0))
	elif is_unaccepted:
		status_lbl.add_theme_color_override("font_color", Color(0.95, 0.65, 0.30, 1.0))
	elif is_wrong:
		status_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
	else:
		status_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	hbox.add_child(status_lbl)

	row.add_child(hbox)
	return row

func _on_accept_delivery_clicked(order_id: int, om: OrderManager) -> void:
	if not om:
		return

	var ok = om.accept_delivery_order(order_id)
	_refresh_orders_tab()

	var p = get_parent()
	if p and p.has_node("HUD") and p.get_node("HUD").has_method("show_temporary_feedback"):
		if ok:
			p.get_node("HUD").show_temporary_feedback("✍️ Pedido Delivery #%03d aceito! Inicie o preparo." % order_id)
		else:
			p.get_node("HUD").show_temporary_feedback("⚠️ Falha ao aceitar pedido.")

# =============================================================================
# SISTEMA DE NOTIFICAÇÃO DE NOVOS PEDIDOS NO PC
# =============================================================================

func _setup_order_notifications() -> void:
	if not ui_notification_audio:
		ui_notification_audio = AudioStreamPlayer.new()
		ui_notification_audio.name = "UINotificationAudio"
		ui_notification_audio.bus = "Master"
		add_child(ui_notification_audio)
		var stream = SoundSynthesizer.get_stream("pc_notification")
		if stream:
			ui_notification_audio.stream = stream

	_setup_notification_toast_ui()

	var om = OrderManager.get_instance()
	if not om and is_inside_tree() and get_tree() and get_tree().root:
		om = get_tree().root.find_child("OrderManager", true, false)
	if om:
		if not om.order_created.is_connected(_on_new_order_created):
			om.order_created.connect(_on_new_order_created)

func _setup_notification_toast_ui() -> void:
	if notification_toast_panel and is_instance_valid(notification_toast_panel):
		return

	var outer_window = get_node_or_null("MainPanel/OuterWindow")
	if not outer_window:
		outer_window = get_node_or_null("MainPanel")
	if not outer_window:
		outer_window = self

	notification_toast_panel = PanelContainer.new()
	notification_toast_panel.name = "OrderNotificationToast"
	notification_toast_panel.visible = false
	notification_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.18, 0.95)
	style.border_color = Color(1.0, 0.80, 0.20, 0.85)
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	notification_toast_panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)

	notification_toast_label = Label.new()
	notification_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notification_toast_label.text = "🔔 Novo pedido recebido"
	notification_toast_label.add_theme_font_size_override("font_size", 12)
	notification_toast_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.40, 1.0))
	hbox.add_child(notification_toast_label)

	notification_toast_panel.add_child(hbox)
	outer_window.add_child(notification_toast_panel)

	# Posiciona de forma discreta na parte superior da interface, sem bloquear cliques
	notification_toast_panel.position = Vector2(340, 16)

func _on_new_order_created(order: Order) -> void:
	if not order or notified_orders_map.has(order.id):
		return

	notified_orders_map[order.id] = true

	if current_tab != TabID.ORDERS or not visible:
		unviewed_orders_count += 1
		_update_sidebar_orders_badge()
		_show_notification_toast(order)

	_play_ui_notification_sound()

func _play_ui_notification_sound() -> void:
	if ui_notification_audio and ui_notification_audio.is_inside_tree():
		var stream = SoundSynthesizer.get_stream("pc_notification")
		if stream:
			ui_notification_audio.stream = stream
			ui_notification_audio.volume_db = -4.0
			ui_notification_audio.play()

func _show_notification_toast(order: Order) -> void:
	if not notification_toast_panel:
		_setup_notification_toast_ui()

	if notification_toast_panel and notification_toast_label:
		var src = "Delivery" if order.source_type == "DELIVERY" else ("Drive-Thru" if order.source_type == "DRIVE_THRU" else "Salão")
		notification_toast_label.text = "🔔 Novo pedido recebido (#%03d - %s)" % [order.id, src]
		notification_toast_panel.visible = true
		notification_toast_timer = 4.0

func _hide_notification_toast() -> void:
	if notification_toast_panel:
		notification_toast_panel.visible = false
	notification_toast_timer = 0.0

func _update_sidebar_orders_badge() -> void:
	if nav_buttons_map.has(TabID.ORDERS):
		var btn: Button = nav_buttons_map[TabID.ORDERS]
		if unviewed_orders_count > 0:
			btn.text = "📋  Pedidos & Delivery  [🔔 %d]" % unviewed_orders_count
		else:
			btn.text = "📋  Pedidos & Delivery"

func _mark_orders_as_viewed() -> void:
	unviewed_orders_count = 0
	_update_sidebar_orders_badge()
	_hide_notification_toast()
	orders_viewed.emit()

func notify_new_orders_arrived() -> void:
	_update_sidebar_orders_badge()
	if unviewed_orders_count > 0:
		if notification_toast_panel:
			notification_toast_panel.visible = true
			notification_toast_timer = 5.0

# =============================================================================
# ABA 8: CENTRAL DE AVALIAÇÕES E REPUTAÇÃO DO RESTAURANTE
# =============================================================================

func _setup_reviews_tab() -> void:
	if btn_reviews_all and not btn_reviews_all.pressed.is_connected(_on_reviews_filter_all_pressed):
		btn_reviews_all.pressed.connect(_on_reviews_filter_all_pressed)
	if btn_reviews_dinein and not btn_reviews_dinein.pressed.is_connected(_on_reviews_filter_dinein_pressed):
		btn_reviews_dinein.pressed.connect(_on_reviews_filter_dinein_pressed)
	if btn_reviews_drivethru and not btn_reviews_drivethru.pressed.is_connected(_on_reviews_filter_drivethru_pressed):
		btn_reviews_drivethru.pressed.connect(_on_reviews_filter_drivethru_pressed)
	if btn_reviews_delivery and not btn_reviews_delivery.pressed.is_connected(_on_reviews_filter_delivery_pressed):
		btn_reviews_delivery.pressed.connect(_on_reviews_filter_delivery_pressed)
	if btn_reviews_5stars and not btn_reviews_5stars.pressed.is_connected(_on_reviews_filter_5stars_pressed):
		btn_reviews_5stars.pressed.connect(_on_reviews_filter_5stars_pressed)
	if btn_reviews_complaints and not btn_reviews_complaints.pressed.is_connected(_on_reviews_filter_complaints_pressed):
		btn_reviews_complaints.pressed.connect(_on_reviews_filter_complaints_pressed)

	var rep = ReputationManager.get_instance()
	if not rep and is_inside_tree() and get_tree() and get_tree().root:
		rep = get_tree().root.find_child("ReputationManager", true, false)
	if rep:
		if not rep.review_added.is_connected(_on_new_review_received):
			rep.review_added.connect(_on_new_review_received)

func _on_new_review_received(_review: CustomerReview) -> void:
	if current_tab == TabID.REVIEWS and visible:
		_refresh_reviews_tab()

func _on_reviews_filter_all_pressed() -> void: _set_reviews_filter("ALL")
func _on_reviews_filter_dinein_pressed() -> void: _set_reviews_filter("DINE_IN")
func _on_reviews_filter_drivethru_pressed() -> void: _set_reviews_filter("DRIVE_THRU")
func _on_reviews_filter_delivery_pressed() -> void: _set_reviews_filter("DELIVERY")
func _on_reviews_filter_5stars_pressed() -> void: _set_reviews_filter("5_STARS")
func _on_reviews_filter_complaints_pressed() -> void: _set_reviews_filter("COMPLAINTS")

func _set_reviews_filter(filter_name: String) -> void:
	current_reviews_filter = filter_name
	_update_reviews_filter_button_styles()
	_refresh_reviews_tab()

func _update_reviews_filter_button_styles() -> void:
	var filter_btns = {
		"ALL": btn_reviews_all,
		"DINE_IN": btn_reviews_dinein,
		"DRIVE_THRU": btn_reviews_drivethru,
		"DELIVERY": btn_reviews_delivery,
		"5_STARS": btn_reviews_5stars,
		"COMPLAINTS": btn_reviews_complaints
	}

	for k in filter_btns.keys():
		var btn = filter_btns[k]
		if not btn:
			continue
		var is_sel = (k == current_reviews_filter)
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_bottom_left = 6
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 4
		style.content_margin_bottom = 4

		if is_sel:
			style.bg_color = Color(0.24, 0.32, 0.46, 1.0)
			style.border_color = Color(1.0, 0.80, 0.20, 1.0)
			style.border_width_bottom = 3
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		else:
			style.bg_color = Color(0.12, 0.15, 0.20, 1.0)
			btn.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1))

		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

func _refresh_reviews_tab() -> void:
	var rep = ReputationManager.get_instance()
	if not rep and is_inside_tree() and get_tree() and get_tree().root:
		rep = get_tree().root.find_child("ReputationManager", true, false)

	_update_reviews_filter_button_styles()

	if reviews_summary_label and rep:
		var tot = rep.get_total_reviews()
		reviews_summary_label.text = "⭐ Média %.1f/5.0 (%d avaliações)" % [rep.get_average_rating(), tot]

	# 1. Renderiza o Destaque Superior / Painel de Reputação
	_build_reputation_header(rep)

	# 2. Renderiza o Feed de Avaliações
	if not reviews_content_vbox:
		return

	for child in reviews_content_vbox.get_children():
		child.queue_free()

	if not rep:
		var empty_lbl = Label.new()
		empty_lbl.text = "Nenhuma avaliação disponível no momento."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reviews_content_vbox.add_child(empty_lbl)
		return

	var feed = rep.get_filtered_feed(current_reviews_filter)
	if feed.is_empty():
		var empty_panel = PanelContainer.new()
		var pstyle = StyleBoxFlat.new()
		pstyle.bg_color = Color(0.10, 0.13, 0.18, 0.80)
		pstyle.set_corner_radius_all(8)
		pstyle.set_content_margin_all(24)
		empty_panel.add_theme_stylebox_override("panel", pstyle)

		var elbl = Label.new()
		elbl.text = "Nenhuma avaliação encontrada nesta categoria.\nAtenda mais clientes no restaurante, drive-thru ou delivery!"
		elbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		elbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 1.0))
		empty_panel.add_child(elbl)
		reviews_content_vbox.add_child(empty_panel)
		return

	for review in feed:
		var card = _create_review_card(review)
		reviews_content_vbox.add_child(card)

func _build_reputation_header(rep: ReputationManager) -> void:
	if not reviews_header_container:
		return

	for child in reviews_header_container.get_children():
		child.queue_free()

	var avg = rep.get_average_rating() if rep else 5.0
	var total_rev = rep.get_total_reviews() if rep else 0
	var dist = rep.get_rating_distribution() if rep else {5:0, 4:0, 3:0, 2:0, 1:0}
	var pcts = rep.get_rating_percentages() if rep else {5:100.0, 4:0.0, 3:0.0, 2:0.0, 1:0.0}
	var sentiments = rep.get_sentiment_summary() if rep else {"positive": 0, "neutral": 0, "negative": 0}
	var rep_color = rep.get_reputation_color() if rep else Color(0.25, 0.85, 0.45, 1.0)
	var tier_name = rep.get_reputation_tier_name() if rep else "Excelente"

	# CARD 1: Nota Global em Destaque
	var main_card = PanelContainer.new()
	main_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_card.size_flags_stretch_ratio = 1.1
	var mstyle = StyleBoxFlat.new()
	mstyle.bg_color = Color(0.11, 0.15, 0.22, 0.95)
	mstyle.border_color = rep_color
	mstyle.border_width_left = 4
	mstyle.set_corner_radius_all(8)
	mstyle.set_content_margin_all(14)
	main_card.add_theme_stylebox_override("panel", mstyle)

	var mvbox = VBoxContainer.new()
	mvbox.add_theme_constant_override("separation", 4)

	var title_lbl = Label.new()
	title_lbl.text = "AVALIAÇÃO DO RESTAURANTE"
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	mvbox.add_child(title_lbl)

	var score_hbox = HBoxContainer.new()
	score_hbox.add_theme_constant_override("separation", 10)

	var score_lbl = Label.new()
	score_lbl.text = "%.1f" % avg
	score_lbl.add_theme_font_size_override("font_size", 34)
	score_lbl.add_theme_color_override("font_color", rep_color)
	score_hbox.add_child(score_lbl)

	var stars_vbox = VBoxContainer.new()
	stars_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var stars_lbl = Label.new()
	stars_lbl.text = rep.get_stars_string() if rep else "★★★★★"
	stars_lbl.add_theme_font_size_override("font_size", 18)
	stars_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.20, 1.0))
	stars_vbox.add_child(stars_lbl)

	var count_lbl = Label.new()
	count_lbl.text = "%d avaliações registradas • %s" % [total_rev, tier_name]
	count_lbl.add_theme_font_size_override("font_size", 11)
	count_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95, 1.0))
	stars_vbox.add_child(count_lbl)

	score_hbox.add_child(stars_vbox)
	mvbox.add_child(score_hbox)

	var rep_hint = Label.new()
	rep_hint.text = "Tolerância de Preço: %s" % ("+25% (Alta Aceitação)" if avg >= 4.5 else ("Normal (Padrão)" if avg >= 3.8 else "-20% (Preço Sensível)"))
	rep_hint.add_theme_font_size_override("font_size", 11)
	rep_hint.add_theme_color_override("font_color", Color(0.65, 0.85, 0.70, 1.0) if avg >= 4.0 else Color(0.95, 0.65, 0.40, 1.0))
	mvbox.add_child(rep_hint)

	main_card.add_child(mvbox)
	reviews_header_container.add_child(main_card)

	# CARD 2: Distribuição de Estrelas (Barras Gráficas 5★ a 1★)
	var dist_card = PanelContainer.new()
	dist_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dist_card.size_flags_stretch_ratio = 1.3
	var dstyle = StyleBoxFlat.new()
	dstyle.bg_color = Color(0.10, 0.13, 0.19, 0.95)
	dstyle.set_corner_radius_all(8)
	dstyle.set_content_margin_all(12)
	dist_card.add_theme_stylebox_override("panel", dstyle)

	var dvbox = VBoxContainer.new()
	dvbox.add_theme_constant_override("separation", 3)

	for star_idx in range(5, 0, -1):
		var star_row = _create_rating_distribution_bar(star_idx, dist.get(star_idx, 0), pcts.get(star_idx, 0.0))
		dvbox.add_child(star_row)

	dist_card.add_child(dvbox)
	reviews_header_container.add_child(dist_card)

	# CARD 3: Resumo de Sentimento & Canais
	var sent_card = PanelContainer.new()
	sent_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sent_card.size_flags_stretch_ratio = 0.9
	var sstyle = StyleBoxFlat.new()
	sstyle.bg_color = Color(0.10, 0.13, 0.19, 0.95)
	sstyle.set_corner_radius_all(8)
	sstyle.set_content_margin_all(12)
	sent_card.add_theme_stylebox_override("panel", sstyle)

	var svbox = VBoxContainer.new()
	svbox.add_theme_constant_override("separation", 6)

	var stitle = Label.new()
	stitle.text = "RESUMO DE EXPERIÊNCIA"
	stitle.add_theme_font_size_override("font_size", 11)
	stitle.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	svbox.add_child(stitle)

	var pos_lbl = Label.new()
	pos_lbl.text = "😊 Positivas: %d" % sentiments.get("positive", 0)
	pos_lbl.add_theme_font_size_override("font_size", 12)
	pos_lbl.add_theme_color_override("font_color", Color(0.35, 0.9, 0.5, 1.0))
	svbox.add_child(pos_lbl)

	var neu_lbl = Label.new()
	neu_lbl.text = "😐 Neutras: %d" % sentiments.get("neutral", 0)
	neu_lbl.add_theme_font_size_override("font_size", 12)
	neu_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.25, 1.0))
	svbox.add_child(neu_lbl)

	var neg_lbl = Label.new()
	neg_lbl.text = "😟 Reclamações: %d" % sentiments.get("negative", 0)
	neg_lbl.add_theme_font_size_override("font_size", 12)
	neg_lbl.add_theme_color_override("font_color", Color(1.0, 0.40, 0.40, 1.0))
	svbox.add_child(neg_lbl)

	sent_card.add_child(svbox)
	reviews_header_container.add_child(sent_card)

func _create_rating_distribution_bar(stars: int, count: int, pct: float) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var star_lbl = Label.new()
	star_lbl.custom_minimum_size = Vector2(48, 0)
	star_lbl.text = "%d ★" % stars
	star_lbl.add_theme_font_size_override("font_size", 11)
	star_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.30, 1.0))
	hbox.add_child(star_lbl)

	var bar_bg = ProgressBar.new()
	bar_bg.custom_minimum_size = Vector2(110, 10)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_bg.show_percentage = false
	bar_bg.max_value = 100.0
	bar_bg.value = pct

	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(1.0, 0.75, 0.15, 0.90) if stars >= 4 else (Color(0.95, 0.55, 0.20, 0.90) if stars == 3 else Color(0.95, 0.30, 0.30, 0.90))
	p_style.set_corner_radius_all(4)
	bar_bg.add_theme_stylebox_override("fill", p_style)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.18, 0.22, 0.30, 0.80)
	bg_style.set_corner_radius_all(4)
	bar_bg.add_theme_stylebox_override("background", bg_style)

	hbox.add_child(bar_bg)

	var pct_lbl = Label.new()
	pct_lbl.custom_minimum_size = Vector2(60, 0)
	pct_lbl.text = "%.0f%% (%d)" % [pct, count]
	pct_lbl.add_theme_font_size_override("font_size", 10)
	pct_lbl.add_theme_color_override("font_color", Color(0.70, 0.75, 0.85, 1.0))
	pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(pct_lbl)

	return hbox

func _create_review_card(review: CustomerReview) -> PanelContainer:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.12, 0.17, 0.95)
	var is_bad = (review.stars <= 2.0 or review.abandoned)
	var is_great = (review.stars >= 4.8)

	if is_great:
		style.border_color = Color(0.25, 0.85, 0.45, 0.70)
		style.border_width_left = 3
	elif is_bad:
		style.border_color = Color(0.95, 0.35, 0.35, 0.70)
		style.border_width_left = 3
	else:
		style.border_color = Color(0.20, 0.26, 0.36, 0.70)
		style.set_border_width_all(1)

	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	# 1. Header do Card (Avatar, Nome, Estrelas, Data/Hora e Badge de Origem)
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)

	# Avatar Inicial (ex: MS)
	var avatar_panel = PanelContainer.new()
	avatar_panel.custom_minimum_size = Vector2(36, 36)
	var a_style = StyleBoxFlat.new()
	a_style.bg_color = review.avatar_color
	a_style.set_corner_radius_all(18)
	avatar_panel.add_theme_stylebox_override("panel", a_style)

	var initials = ""
	var parts = review.customer_name.split(" ")
	for p in parts:
		if p.length() > 0:
			initials += p[0].to_upper()
		if initials.length() >= 2:
			break
	if initials == "": initials = "CL"

	var a_lbl = Label.new()
	a_lbl.text = initials
	a_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	a_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	a_lbl.add_theme_font_size_override("font_size", 13)
	a_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	avatar_panel.add_child(a_lbl)
	header_hbox.add_child(avatar_panel)

	var name_stars_vbox = VBoxContainer.new()
	name_stars_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl = Label.new()
	name_lbl.text = review.customer_name
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_stars_vbox.add_child(name_lbl)

	var stars_lbl = Label.new()
	stars_lbl.text = review.get_formatted_stars()
	stars_lbl.add_theme_font_size_override("font_size", 13)
	stars_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.20, 1.0))
	name_stars_vbox.add_child(stars_lbl)

	header_hbox.add_child(name_stars_vbox)

	# Origem Badge + Data/Hora
	var meta_vbox = VBoxContainer.new()
	meta_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var badge_panel = PanelContainer.new()
	var b_style = StyleBoxFlat.new()
	match review.channel_type:
		"DELIVERY":
			b_style.bg_color = Color(0.18, 0.40, 0.60, 0.85)
		"DRIVE_THRU":
			b_style.bg_color = Color(0.60, 0.35, 0.15, 0.85)
		_:
			b_style.bg_color = Color(0.20, 0.50, 0.30, 0.85)
	b_style.set_corner_radius_all(4)
	b_style.set_content_margin_all(4)
	badge_panel.add_theme_stylebox_override("panel", b_style)

	var badge_lbl = Label.new()
	badge_lbl.text = review.get_channel_badge_text()
	badge_lbl.add_theme_font_size_override("font_size", 11)
	badge_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	badge_panel.add_child(badge_lbl)
	meta_vbox.add_child(badge_panel)

	var time_lbl = Label.new()
	time_lbl.text = "%s — %s" % [review.date_string, review.time_string]
	time_lbl.add_theme_font_size_override("font_size", 11)
	time_lbl.add_theme_color_override("font_color", Color(0.65, 0.70, 0.80, 1.0))
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta_vbox.add_child(time_lbl)

	header_hbox.add_child(meta_vbox)
	vbox.add_child(header_hbox)

	# 2. Comentário em Destaque
	var comment_panel = PanelContainer.new()
	var c_style = StyleBoxFlat.new()
	c_style.bg_color = Color(0.06, 0.08, 0.12, 0.80)
	c_style.set_corner_radius_all(6)
	c_style.set_content_margin_all(10)
	comment_panel.add_theme_stylebox_override("panel", c_style)

	var comment_lbl = Label.new()
	comment_lbl.text = "“%s”" % review.comment
	comment_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comment_lbl.add_theme_font_size_override("font_size", 13)
	comment_lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1.0))
	comment_panel.add_child(comment_lbl)
	vbox.add_child(comment_panel)

	# 3. Tags / Detalhes do Pedido
	var footer_hbox = HBoxContainer.new()
	footer_hbox.add_theme_constant_override("separation", 6)

	if review.order_summary != "":
		var ord_tag = Label.new()
		ord_tag.text = "🍔 %s" % review.order_summary
		ord_tag.add_theme_font_size_override("font_size", 11)
		ord_tag.add_theme_color_override("font_color", Color(0.70, 0.75, 0.85, 1.0))
		ord_tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ord_tag.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		footer_hbox.add_child(ord_tag)

	for tag in review.tags:
		var tag_p = PanelContainer.new()
		var t_style = StyleBoxFlat.new()
		t_style.bg_color = Color(0.15, 0.19, 0.26, 0.90)
		t_style.set_corner_radius_all(4)
		t_style.content_margin_left = 6
		t_style.content_margin_right = 6
		t_style.content_margin_top = 2
		t_style.content_margin_bottom = 2
		tag_p.add_theme_stylebox_override("panel", t_style)

		var tag_l = Label.new()
		tag_l.text = tag
		tag_l.add_theme_font_size_override("font_size", 10)
		if tag in ["Comida Excelente", "Atendimento Rápido", "Entrega Rápida", "Ambiente Agradável", "Bom Preço"]:
			tag_l.add_theme_color_override("font_color", Color(0.35, 0.90, 0.50, 1.0))
		elif tag in ["Demora", "Pedido Incorreto", "Abandono", "Mesa Suja", "Restaurante Quente", "Preço Alto"]:
			tag_l.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 1.0))
		else:
			tag_l.add_theme_color_override("font_color", Color(0.75, 0.80, 0.90, 1.0))
		tag_p.add_child(tag_l)
		footer_hbox.add_child(tag_p)

	vbox.add_child(footer_hbox)
	card.add_child(vbox)
	return card

# =============================================================================
# ABA 9: CALENDÁRIO VIVO & HISTÓRICO DE DIAS
# =============================================================================

func _setup_calendar_tab() -> void:
	if btn_prev_month and not btn_prev_month.pressed.is_connected(_on_prev_month_pressed):
		btn_prev_month.pressed.connect(_on_prev_month_pressed)
	if btn_next_month and not btn_next_month.pressed.is_connected(_on_next_month_pressed):
		btn_next_month.pressed.connect(_on_next_month_pressed)

	if btn_day_sub_summary and not btn_day_sub_summary.pressed.is_connected(func(): _set_calendar_subtab("SUMMARY")):
		btn_day_sub_summary.pressed.connect(func(): _set_calendar_subtab("SUMMARY"))
	if btn_day_sub_orders and not btn_day_sub_orders.pressed.is_connected(func(): _set_calendar_subtab("ORDERS")):
		btn_day_sub_orders.pressed.connect(func(): _set_calendar_subtab("ORDERS"))
	if btn_day_sub_reviews and not btn_day_sub_reviews.pressed.is_connected(func(): _set_calendar_subtab("REVIEWS")):
		btn_day_sub_reviews.pressed.connect(func(): _set_calendar_subtab("REVIEWS"))
	if btn_day_sub_news and not btn_day_sub_news.pressed.is_connected(func(): _set_calendar_subtab("NEWS")):
		btn_day_sub_news.pressed.connect(func(): _set_calendar_subtab("NEWS"))

	var cal = CalendarManager.get_instance()
	if cal:
		viewing_calendar_year = cal.current_year
		viewing_calendar_month = cal.current_month
		selected_calendar_day = cal.day_number

func _on_prev_month_pressed() -> void:
	viewing_calendar_month -= 1
	if viewing_calendar_month < 1:
		viewing_calendar_month = 12
		viewing_calendar_year -= 1
	if viewing_calendar_year < 2026:
		viewing_calendar_year = 2026
		viewing_calendar_month = 1
	_refresh_calendar_tab()

func _on_next_month_pressed() -> void:
	viewing_calendar_month += 1
	if viewing_calendar_month > 12:
		viewing_calendar_month = 1
		viewing_calendar_year += 1
	_refresh_calendar_tab()

func _set_calendar_subtab(subtab_name: String) -> void:
	selected_calendar_subtab = subtab_name
	_update_calendar_subtab_button_styles()
	_refresh_calendar_day_details()

func _update_calendar_subtab_button_styles() -> void:
	var sub_btns = {
		"SUMMARY": btn_day_sub_summary,
		"ORDERS": btn_day_sub_orders,
		"REVIEWS": btn_day_sub_reviews,
		"NEWS": btn_day_sub_news
	}

	for k in sub_btns.keys():
		var btn: Button = sub_btns[k]
		if not btn:
			continue
		var is_sel = (k == selected_calendar_subtab)
		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(4)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 4
		style.content_margin_bottom = 4

		if is_sel:
			style.bg_color = Color(0.24, 0.32, 0.46, 1.0)
			style.border_color = Color(1.0, 0.80, 0.20, 1.0)
			style.border_width_bottom = 2
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		else:
			style.bg_color = Color(0.12, 0.15, 0.20, 1.0)
			btn.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1))

		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

func _select_calendar_day(day_num: int) -> void:
	selected_calendar_day = day_num
	_build_calendar_month_grid()
	_refresh_calendar_day_details()

func _refresh_calendar_tab() -> void:
	var cal = CalendarManager.get_instance()
	if calendar_summary_label and cal:
		calendar_summary_label.text = "%s — Dia %d (Hoje)" % [cal.get_formatted_date(), cal.day_number]

	if month_title_label and cal:
		var m_name = cal.MONTH_NAMES[clamp(viewing_calendar_month - 1, 0, 11)].capitalize()
		month_title_label.text = "%s %d" % [m_name, viewing_calendar_year]

	_update_calendar_subtab_button_styles()
	_build_calendar_month_grid()
	_refresh_calendar_day_details()

func _build_calendar_month_grid() -> void:
	var cal = CalendarManager.get_instance()
	if not cal or not days_grid or not week_header_grid:
		return

	# 1. Cabeçalho dos dias da semana
	if week_header_grid.get_child_count() == 0:
		var short_weekdays = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]
		for sw in short_weekdays:
			var wlbl = Label.new()
			wlbl.text = sw
			wlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			wlbl.add_theme_font_size_override("font_size", 11)
			wlbl.add_theme_color_override("font_color", Color(0.65, 0.70, 0.80, 1.0))
			wlbl.custom_minimum_size = Vector2(40, 20)
			week_header_grid.add_child(wlbl)

	# 2. Grid de Dias
	for child in days_grid.get_children():
		child.queue_free()

	var matrix = cal.get_month_matrix(viewing_calendar_year, viewing_calendar_month)

	for week in matrix:
		for day_cell in week:
			var day_val = day_cell.get("day", 0)
			var d_num = day_cell.get("day_number", 0)
			var is_cur_month = day_cell.get("is_current_month", false)
			var is_today = day_cell.get("is_today", false)
			var is_past = day_cell.get("is_past", false)
			var is_future = day_cell.get("is_future", false)

			var btn = Button.new()
			btn.custom_minimum_size = Vector2(40, 36)
			btn.focus_mode = Control.FOCUS_NONE

			if not is_cur_month or day_val == 0:
				btn.text = ""
				btn.disabled = true
				var empty_style = StyleBoxFlat.new()
				empty_style.bg_color = Color(0, 0, 0, 0)
				btn.add_theme_stylebox_override("disabled", empty_style)
			else:
				btn.text = str(day_val)
				var is_selected = (d_num == selected_calendar_day)

				var style = StyleBoxFlat.new()
				style.set_corner_radius_all(4)

				if is_selected:
					style.bg_color = Color(0.28, 0.40, 0.58, 1.0)
					style.border_color = Color(1.0, 0.85, 0.20, 1.0)
					style.set_border_width_all(2)
					btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
				elif is_today:
					style.bg_color = Color(0.20, 0.30, 0.42, 1.0)
					style.border_color = Color(1.0, 0.80, 0.20, 0.90)
					style.set_border_width_all(2)
					btn.add_theme_color_override("font_color", Color(1.0, 0.90, 0.30, 1.0))
				elif is_past:
					style.bg_color = Color(0.12, 0.16, 0.22, 0.90)
					style.border_color = Color(0.20, 0.26, 0.36, 0.60)
					style.set_border_width_all(1)
					btn.add_theme_color_override("font_color", Color(0.85, 0.90, 0.95, 1.0))
				elif is_future:
					style.bg_color = Color(0.08, 0.10, 0.14, 0.60)
					btn.add_theme_color_override("font_color", Color(0.45, 0.50, 0.60, 1.0))
					btn.disabled = true

				btn.add_theme_stylebox_override("normal", style)
				btn.add_theme_stylebox_override("hover", style)
				btn.add_theme_stylebox_override("pressed", style)
				btn.add_theme_stylebox_override("disabled", style)

				if not is_future:
					var target_d = d_num
					btn.pressed.connect(func(): _select_calendar_day(target_d))

			days_grid.add_child(btn)

func _refresh_calendar_day_details() -> void:
	var cal = CalendarManager.get_instance()
	if not day_detail_content_vbox:
		day_detail_content_vbox = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/CalendarTab/CalendarBodyMargin/SplitHBox/DayDetailPanel/DayDetailVBox/DayDetailScroll/DayDetailContentVBox")
	if not day_detail_content_vbox:
		return

	var day_num = selected_calendar_day
	var is_today = (cal and day_num == cal.day_number)
	var date_info = cal.get_date_for_day_number(day_num) if cal else {}
	var d_title = "%s — Dia %d%s" % [date_info.get("formatted_date", "01/01/2026"), day_num, " (Hoje)" if is_today else ""]

	if selected_day_title_label:
		selected_day_title_label.text = d_title

	for child in day_detail_content_vbox.get_children():
		day_detail_content_vbox.remove_child(child)
		child.queue_free()

	var day_rec = cal.get_day_record(day_num) if cal else {}

	match selected_calendar_subtab:
		"ORDERS":
			_build_day_orders_view(day_rec)
		"REVIEWS":
			_build_day_reviews_view(day_rec)
		"NEWS":
			_build_day_news_view(day_rec)
		_:
			_build_day_summary_view(day_rec)

func _build_day_summary_view(day_rec: Dictionary) -> void:
	var fin_data = day_rec.get("financial", {})
	var ord_data = day_rec.get("orders", {})
	var rep_data = day_rec.get("reputation", {})
	var evt_data = day_rec.get("event", {})
	var wea_data = day_rec.get("weather", {})

	var rev = fin_data.get("revenue", 0.0)
	var exp = fin_data.get("expenses", 0.0)
	var prof = fin_data.get("profit", 0.0)

	# 1. Painel Financeiro
	var fin_card = PanelContainer.new()
	var fstyle = StyleBoxFlat.new()
	fstyle.bg_color = Color(0.10, 0.14, 0.20, 0.95)
	fstyle.set_corner_radius_all(6)
	fstyle.set_content_margin_all(10)
	fin_card.add_theme_stylebox_override("panel", fstyle)

	var fvbox = VBoxContainer.new()
	fvbox.add_theme_constant_override("separation", 6)

	var ftitle = Label.new()
	ftitle.text = "💵 BALANÇO FINANCEIRO"
	ftitle.add_theme_font_size_override("font_size", 12)
	ftitle.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
	fvbox.add_child(ftitle)

	var fhbox = HBoxContainer.new()
	fhbox.add_theme_constant_override("separation", 14)

	var r_lbl = Label.new()
	r_lbl.text = "Receita: R$ %.2f" % rev
	r_lbl.add_theme_font_size_override("font_size", 12)
	r_lbl.add_theme_color_override("font_color", Color(0.35, 0.9, 0.5, 1))
	fhbox.add_child(r_lbl)

	var e_lbl = Label.new()
	e_lbl.text = "Despesas: R$ %.2f" % exp
	e_lbl.add_theme_font_size_override("font_size", 12)
	e_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 1))
	fhbox.add_child(e_lbl)

	var p_lbl = Label.new()
	p_lbl.text = "Lucro Líquido: R$ %.2f" % prof
	p_lbl.add_theme_font_size_override("font_size", 12)
	p_lbl.add_theme_color_override("font_color", Color(0.35, 0.9, 0.5, 1) if prof >= 0 else Color(1.0, 0.4, 0.4, 1))
	fhbox.add_child(p_lbl)

	fvbox.add_child(fhbox)
	fin_card.add_child(fvbox)
	day_detail_content_vbox.add_child(fin_card)

	# 2. Painel de Pedidos & Operação
	var ord_card = PanelContainer.new()
	var ostyle = StyleBoxFlat.new()
	ostyle.bg_color = Color(0.10, 0.14, 0.20, 0.95)
	ostyle.set_corner_radius_all(6)
	ostyle.set_content_margin_all(10)
	ord_card.add_theme_stylebox_override("panel", ostyle)

	var ovbox = VBoxContainer.new()
	ovbox.add_theme_constant_override("separation", 6)

	var otitle = Label.new()
	otitle.text = "📋 PEDIDOS & CANAIS DE VENDA"
	otitle.add_theme_font_size_override("font_size", 12)
	otitle.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
	ovbox.add_child(otitle)

	var ohbox = HBoxContainer.new()
	ohbox.add_theme_constant_override("separation", 14)

	var tot_lbl = Label.new()
	tot_lbl.text = "Total: %d" % ord_data.get("total", 0)
	tot_lbl.add_theme_font_size_override("font_size", 12)
	ohbox.add_child(tot_lbl)

	var din_lbl = Label.new()
	din_lbl.text = "🍽️ Salão: %d" % ord_data.get("dine_in", 0)
	din_lbl.add_theme_font_size_override("font_size", 12)
	ohbox.add_child(din_lbl)

	var dt_lbl = Label.new()
	dt_lbl.text = "🚗 Drive-thru: %d" % ord_data.get("drive_thru", 0)
	dt_lbl.add_theme_font_size_override("font_size", 12)
	ohbox.add_child(dt_lbl)

	var del_lbl = Label.new()
	del_lbl.text = "🛵 Delivery: %d" % ord_data.get("delivery", 0)
	del_lbl.add_theme_font_size_override("font_size", 12)
	ohbox.add_child(del_lbl)

	ovbox.add_child(ohbox)
	ord_card.add_child(ovbox)
	day_detail_content_vbox.add_child(ord_card)

	# 3. Painel de Reputação, Eventos e Clima
	var info_card = PanelContainer.new()
	var istyle = StyleBoxFlat.new()
	istyle.bg_color = Color(0.10, 0.14, 0.20, 0.95)
	istyle.set_corner_radius_all(6)
	istyle.set_content_margin_all(10)
	info_card.add_theme_stylebox_override("panel", istyle)

	var ivbox = VBoxContainer.new()
	ivbox.add_theme_constant_override("separation", 6)

	var ititle = Label.new()
	ititle.text = "⭐ SATISFAÇÃO & ACONTECIMENTOS"
	ititle.add_theme_font_size_override("font_size", 12)
	ititle.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
	ivbox.add_child(ititle)

	var ihbox = HBoxContainer.new()
	ihbox.add_theme_constant_override("separation", 14)

	var r_stars_lbl = Label.new()
	r_stars_lbl.text = "⭐ Avaliação Média: %.1f★ (%d avaliações)" % [rep_data.get("average_rating", 5.0), rep_data.get("reviews_count", 0)]
	r_stars_lbl.add_theme_font_size_override("font_size", 12)
	r_stars_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.20, 1))
	ihbox.add_child(r_stars_lbl)

	var wea_lbl = Label.new()
	wea_lbl.text = "Clima: %s %s" % [wea_data.get("icon", "☀️"), wea_data.get("name", "Ensolarado")]
	wea_lbl.add_theme_font_size_override("font_size", 12)
	ihbox.add_child(wea_lbl)

	ivbox.add_child(ihbox)

	var evt_title_lbl = Label.new()
	evt_title_lbl.text = "Evento: %s" % evt_data.get("title", "Operação Normal")
	evt_title_lbl.add_theme_font_size_override("font_size", 12)
	evt_title_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95, 1))
	ivbox.add_child(evt_title_lbl)

	info_card.add_child(ivbox)
	day_detail_content_vbox.add_child(info_card)

func _build_day_orders_view(day_rec: Dictionary) -> void:
	var ord_data = day_rec.get("orders", {})
	var history: Array = ord_data.get("history", [])

	if history.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Nenhum pedido registrado para este dia."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 1))
		day_detail_content_vbox.add_child(empty_lbl)
		return

	for ord in history:
		var row = _create_history_row(ord)
		day_detail_content_vbox.add_child(row)

func _build_day_reviews_view(day_rec: Dictionary) -> void:
	var rep_data = day_rec.get("reputation", {})
	var reviews_list: Array = rep_data.get("reviews", [])

	if reviews_list.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Nenhuma avaliação recebida neste dia."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 1))
		day_detail_content_vbox.add_child(empty_lbl)
		return

	for rev in reviews_list:
		var card = _create_review_card(rev)
		day_detail_content_vbox.add_child(card)

func _build_day_news_view(day_rec: Dictionary) -> void:
	var target_day = day_rec.get("day_number", selected_calendar_day)
	var news_list: Array = day_rec.get("news", [])

	if news_list.is_empty():
		var nm = NewsManager.get_instance()
		if not nm and is_inside_tree() and get_tree() and get_tree().root:
			nm = get_tree().root.find_child("NewsManager", true, false)
		if nm:
			news_list = nm.get_news_for_day(target_day)

	if news_list.is_empty():
		var empty_card = _create_no_news_editorial_card()
		day_detail_content_vbox.add_child(empty_card)
		return

	for art in news_list:
		if art.get("is_main", false):
			day_detail_content_vbox.add_child(_create_main_news_card(art))
		else:
			day_detail_content_vbox.add_child(_create_secondary_news_card(art))

# =============================================================================
# ABA 10: JORNAL DA CIDADE & NOTÍCIAS DIGITAIS
# =============================================================================

func _setup_news_tab() -> void:
	var nm = NewsManager.get_instance()
	if nm and not nm.news_updated.is_connected(_on_news_updated_from_manager):
		nm.news_updated.connect(_on_news_updated_from_manager)

func _on_news_updated_from_manager(_arts: Array) -> void:
	if visible and current_tab == TabID.NEWS:
		_refresh_news_tab()

func _refresh_news_tab() -> void:
	var cal = CalendarManager.get_instance()
	if news_date_label and cal:
		news_date_label.text = "%s — Dia %d" % [cal.get_full_date_string(), cal.day_number]

	if not news_content_vbox:
		news_content_vbox = get_node_or_null("MainPanel/OuterWindow/VBox/Body/ContentArea/NewsTab/NewsScroll/Margin/NewsContentVBox")
	if not news_content_vbox:
		return

	for child in news_content_vbox.get_children():
		news_content_vbox.remove_child(child)
		child.queue_free()

	var nm = NewsManager.get_instance()
	if not nm and is_inside_tree() and get_tree() and get_tree().root:
		nm = get_tree().root.find_child("NewsManager", true, false)
	if not nm:
		return

	var articles = nm.get_today_news()
	if articles.is_empty():
		var empty_card = _create_no_news_editorial_card()
		news_content_vbox.add_child(empty_card)
		return

	for art in articles:
		if art.get("is_main", false):
			var main_card = _create_main_news_card(art)
			news_content_vbox.add_child(main_card)
		else:
			var sec_card = _create_secondary_news_card(art)
			news_content_vbox.add_child(sec_card)

func _create_no_news_editorial_card() -> PanelContainer:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.14, 0.21, 0.95)
	style.border_color = Color(0.28, 0.42, 0.60, 0.85)
	style.border_width_left = 4
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)

	# 1. Header Jornalístico
	var hhbox = HBoxContainer.new()
	hhbox.add_theme_constant_override("separation", 10)

	var badge_panel = PanelContainer.new()
	var bstyle = StyleBoxFlat.new()
	bstyle.bg_color = Color(0.20, 0.35, 0.55, 0.90)
	bstyle.set_corner_radius_all(4)
	bstyle.set_content_margin_all(4)
	badge_panel.add_theme_stylebox_override("panel", bstyle)

	var badge_lbl = Label.new()
	badge_lbl.text = "📰 INFORMATIVO DIÁRIO"
	badge_lbl.add_theme_font_size_override("font_size", 10)
	badge_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	badge_panel.add_child(badge_lbl)
	hhbox.add_child(badge_panel)

	var src_lbl = Label.new()
	src_lbl.text = "Portal Central de Notícias • Edição Regular"
	src_lbl.add_theme_font_size_override("font_size", 11)
	src_lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 0.90, 1))
	hhbox.add_child(src_lbl)

	vbox.add_child(hhbox)

	# 2. Título / Manchete Integrada
	var title_lbl = Label.new()
	title_lbl.text = "📅 Dia Sem Ocorrências Relevantes"
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.40, 1.0))
	vbox.add_child(title_lbl)

	# 3. Mensagem Principal Conforme Especificação do Usuário
	var body_lbl = Label.new()
	body_lbl.text = "“Nenhuma notícia nova hoje. Não há eventos ou acontecimentos relevantes para o dia. O restaurante segue normalmente.”"
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.add_theme_font_size_override("font_size", 13)
	body_lbl.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98, 1.0))
	vbox.add_child(body_lbl)

	# 4. Box de Situação Operacional
	var imp_panel = PanelContainer.new()
	var istyle = StyleBoxFlat.new()
	istyle.bg_color = Color(0.06, 0.08, 0.12, 0.90)
	istyle.border_color = Color(0.25, 0.35, 0.50, 0.60)
	istyle.set_border_width_all(1)
	istyle.set_corner_radius_all(6)
	istyle.set_content_margin_all(10)
	imp_panel.add_theme_stylebox_override("panel", istyle)

	var imp_vbox = VBoxContainer.new()
	imp_vbox.add_theme_constant_override("separation", 4)

	var imp_title = Label.new()
	imp_title.text = "⚡ Situação Operacional:"
	imp_title.add_theme_font_size_override("font_size", 12)
	imp_title.add_theme_color_override("font_color", Color(0.40, 0.85, 1.0, 1.0))
	imp_vbox.add_child(imp_title)

	var imp1 = Label.new()
	imp1.text = "• Todos os canais de atendimento operando com normalidade (Salão, Drive-Thru e Delivery)."
	imp1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	imp1.add_theme_font_size_override("font_size", 11)
	imp1.add_theme_color_override("font_color", Color(0.85, 0.88, 0.94, 1.0))
	imp_vbox.add_child(imp1)

	var imp2 = Label.new()
	imp2.text = "• Nenhuma alteração climática brusca ou interrupção de serviços prevista."
	imp2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	imp2.add_theme_font_size_override("font_size", 11)
	imp2.add_theme_color_override("font_color", Color(0.85, 0.88, 0.94, 1.0))
	imp_vbox.add_child(imp2)

	imp_panel.add_child(imp_vbox)
	vbox.add_child(imp_panel)

	card.add_child(vbox)
	return card

func _create_main_news_card(art: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.14, 0.21, 0.95)
	style.border_color = Color(1.0, 0.80, 0.20, 0.90)
	style.border_width_left = 4
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	# 1. Header com Fonte, Categoria e Horário
	var hhbox = HBoxContainer.new()
	hhbox.add_theme_constant_override("separation", 10)

	var badge_panel = PanelContainer.new()
	var bstyle = StyleBoxFlat.new()
	bstyle.bg_color = Color(0.85, 0.25, 0.25, 0.90) if art.get("occurred", false) else Color(0.18, 0.35, 0.60, 0.90)
	bstyle.set_corner_radius_all(4)
	bstyle.set_content_margin_all(4)
	badge_panel.add_theme_stylebox_override("panel", bstyle)

	var badge_lbl = Label.new()
	badge_lbl.text = art.get("status_badge", "📢 ALERTA")
	badge_lbl.add_theme_font_size_override("font_size", 10)
	badge_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	badge_panel.add_child(badge_lbl)
	hhbox.add_child(badge_panel)

	var src_lbl = Label.new()
	src_lbl.text = "📰 %s • %s" % [art.get("source", "Portal Central"), art.get("category", "CIDADE")]
	src_lbl.add_theme_font_size_override("font_size", 11)
	src_lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 0.90, 1))
	hhbox.add_child(src_lbl)

	var time_lbl = Label.new()
	time_lbl.text = "⏰ %s" % art.get("published_time", "08:30")
	time_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_lbl.add_theme_font_size_override("font_size", 11)
	time_lbl.add_theme_color_override("font_color", Color(0.65, 0.70, 0.80, 1))
	hhbox.add_child(time_lbl)

	vbox.add_child(hhbox)

	# 2. Título da Manchete
	var title_lbl = Label.new()
	title_lbl.text = "%s %s" % [art.get("icon", "📰"), art.get("title", "Manchete do Dia")]
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.35, 1.0))
	vbox.add_child(title_lbl)

	# 3. Subtítulo / Linha fina
	if art.get("subtitle", "") != "":
		var sub_lbl = Label.new()
		sub_lbl.text = art.get("subtitle", "")
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.add_theme_font_size_override("font_size", 12)
		sub_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 0.95, 1))
		vbox.add_child(sub_lbl)

	# 4. Corpo da Notícia
	var body_lbl = Label.new()
	body_lbl.text = art.get("body", "")
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.add_theme_font_size_override("font_size", 12)
	body_lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 0.88, 1))
	vbox.add_child(body_lbl)

	# 5. Box de Influência no dia (Gameplay Impacts)
	var impacts: Array = art.get("impacts", [])
	if impacts.is_empty() and art.get("impact", "") != "":
		impacts = [art.get("impact", "")]

	if not impacts.is_empty():
		var imp_panel = PanelContainer.new()
		var istyle = StyleBoxFlat.new()
		istyle.bg_color = Color(0.06, 0.08, 0.12, 0.90)
		istyle.border_color = Color(0.95, 0.70, 0.20, 0.60)
		istyle.set_border_width_all(1)
		istyle.set_corner_radius_all(6)
		istyle.set_content_margin_all(10)
		imp_panel.add_theme_stylebox_override("panel", istyle)

		var imp_vbox = VBoxContainer.new()
		imp_vbox.add_theme_constant_override("separation", 4)

		var imp_title = Label.new()
		imp_title.text = "⚡ Impacto no restaurante:"
		imp_title.add_theme_font_size_override("font_size", 12)
		imp_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35, 1))
		imp_vbox.add_child(imp_title)

		for imp_item in impacts:
			var imp_item_lbl = Label.new()
			imp_item_lbl.text = "• %s" % imp_item
			imp_item_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			imp_item_lbl.add_theme_font_size_override("font_size", 11)
			imp_item_lbl.add_theme_color_override("font_color", Color(0.90, 0.92, 0.96, 1))
			imp_vbox.add_child(imp_item_lbl)

		imp_panel.add_child(imp_vbox)
		vbox.add_child(imp_panel)

	card.add_child(vbox)
	return card

func _create_secondary_news_card(art: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.11, 0.16, 0.90)
	style.border_color = Color(0.18, 0.24, 0.34, 0.70)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var htop = HBoxContainer.new()
	var src_lbl = Label.new()
	src_lbl.text = "%s %s • %s" % [art.get("icon", "🗞️"), art.get("source", "Diário Regional"), art.get("category", "GERAL")]
	src_lbl.add_theme_font_size_override("font_size", 10)
	src_lbl.add_theme_color_override("font_color", Color(0.65, 0.70, 0.80, 1))
	htop.add_child(src_lbl)

	var time_lbl = Label.new()
	time_lbl.text = art.get("time", "10:00")
	time_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_lbl.add_theme_font_size_override("font_size", 10)
	time_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.70, 1))
	htop.add_child(time_lbl)
	vbox.add_child(htop)

	var title_lbl = Label.new()
	title_lbl.text = art.get("title", "")
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0, 1))
	vbox.add_child(title_lbl)

	var body_lbl = Label.new()
	body_lbl.text = art.get("body", "")
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.add_theme_font_size_override("font_size", 11)
	body_lbl.add_theme_color_override("font_color", Color(0.70, 0.75, 0.85, 1))
	vbox.add_child(body_lbl)

	card.add_child(vbox)
	return card
