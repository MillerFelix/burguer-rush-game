class_name HUD
extends CanvasLayer

@onready var interaction_label: Label = $InteractionLabel
@onready var crosshair: ColorRect = $Crosshair
@onready var money_label: Label = $TopRight/MoneyLabel
@onready var orders_label: Label = $TopLeft/OrdersLabel
@onready var day_time_label: Label = $TopCenter/DayTimeLabel
@onready var feedback_label: Label = $FeedbackLabel
@onready var feedback_timer: Timer = $FeedbackTimer

@onready var report_modal: PanelContainer = $DayReportModal
@onready var report_title: Label = $DayReportModal/VBox/TitleLabel
@onready var report_revenue: Label = $DayReportModal/VBox/RevenueLabel
@onready var report_completed: Label = $DayReportModal/VBox/CompletedLabel
@onready var report_cancelled: Label = $DayReportModal/VBox/CancelledLabel
@onready var report_avg_time: Label = $DayReportModal/VBox/AvgTimeLabel
@onready var report_balance: Label = $DayReportModal/VBox/BalanceLabel
@onready var next_day_button: Button = $DayReportModal/VBox/NextDayButton

func _ready() -> void:
	hide_prompt()
	if report_modal:
		report_modal.visible = false

	_update_money_display(100.0)
	_update_orders_display()
	_update_day_time_display(1, 8, 0, GameClock.State.PREPARATION)

	var economy = EconomyManager.get_instance()
	if economy:
		economy.money_changed.connect(_on_money_changed)
		_update_money_display(economy.get_money())

	var order_mgr = OrderManager.get_instance()
	if order_mgr:
		order_mgr.order_created.connect(_on_order_event)
		order_mgr.order_updated.connect(_on_order_event)
		order_mgr.order_completed.connect(_on_order_event)
		order_mgr.order_cancelled.connect(_on_order_event)

	var clock = GameClock.get_instance()
	if clock:
		clock.time_tick.connect(_on_time_tick)
		clock.state_changed.connect(_on_clock_state_changed)
		clock.day_started.connect(_on_day_started)
		clock.day_ended.connect(_on_day_ended)
		_update_day_time_display(clock.day_number, clock.current_hour, clock.current_minute, clock.state)

	if next_day_button:
		next_day_button.pressed.connect(_on_next_day_button_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if report_modal and report_modal.visible:
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			_on_next_day_button_pressed()

func show_prompt(text: String) -> void:
	if interaction_label:
		interaction_label.text = text
		interaction_label.visible = true

@onready var slot1_label: Label = get_node_or_null("ToolHotbar/HBox/Slot1Label")
@onready var slot2_label: Label = get_node_or_null("ToolHotbar/HBox/Slot2Label")
@onready var slot3_label: Label = get_node_or_null("ToolHotbar/HBox/Slot3Label")

func update_active_tool(slot_number: int) -> void:
	if not slot1_label or not slot2_label or not slot3_label:
		slot1_label = get_node_or_null("ToolHotbar/HBox/Slot1Label")
		slot2_label = get_node_or_null("ToolHotbar/HBox/Slot2Label")
		slot3_label = get_node_or_null("ToolHotbar/HBox/Slot3Label")

	var col_active = Color(1.0, 0.9, 0.35, 1.0)
	var col_dimmed = Color(0.65, 0.68, 0.75, 0.45)

	if slot1_label:
		slot1_label.modulate = col_active if slot_number == 1 else col_dimmed
	if slot2_label:
		slot2_label.modulate = col_active if slot_number == 2 else col_dimmed
	if slot3_label:
		slot3_label.modulate = col_active if slot_number == 3 else col_dimmed

func hide_prompt() -> void:
	if interaction_label:
		interaction_label.text = ""
		interaction_label.visible = false

func show_temporary_feedback(message: String, duration: float = 3.0) -> void:
	if not feedback_label:
		return
	feedback_label.text = message
	feedback_label.visible = true

	if feedback_timer:
		feedback_timer.stop()
		feedback_timer.wait_time = duration
		feedback_timer.start()

func _on_feedback_timer_timeout() -> void:
	if feedback_label:
		feedback_label.text = ""
		feedback_label.visible = false

func _on_money_changed(new_amount: float, _delta: float) -> void:
	_update_money_display(new_amount)

func _update_money_display(amount: float) -> void:
	if money_label:
		money_label.text = "💰 Caixa: $%.2f" % amount

func _on_order_event(_order: Order) -> void:
	_update_orders_display()

func _update_orders_display() -> void:
	if not orders_label:
		return

	var order_mgr = OrderManager.get_instance()
	if not order_mgr:
		orders_label.text = "📋 PEDIDOS ATIVOS (0)\nNenhum pedido no momento."
		return

	var active = order_mgr.get_active_orders()
	if active.is_empty():
		orders_label.text = "📋 PEDIDOS ATIVOS (0)\nNenhum pedido no momento."
		return

	var text = "📋 PEDIDOS ATIVOS (%d):\n" % active.size()
	for o in active:
		var prod_info = ""
		var item_list: Array[String] = []
		for item in o.items:
			item_list.append("%dx %s" % [item.get("quantity", 1), item.get("product_name", "Item")])
		prod_info = ", ".join(item_list)

		var group_tag = " (%dp)" % o.group_size if o.group_size > 1 else ""
		var table_tag = "[Mesa #%d%s] " % [o.table_id, group_tag] if o.table_id > 0 else "[Balcão] "
		text += "#%03d %s: %s — $%.2f [%s]\n" % [o.id, table_tag, prod_info, o.total_price, o.get_state_string()]

	orders_label.text = text

func _on_time_tick(hours: int, minutes: int) -> void:
	var clock = GameClock.get_instance()
	var day = clock.day_number if clock else 1
	var st = clock.state if clock else GameClock.State.PREPARATION
	_update_day_time_display(day, hours, minutes, st)

func _on_clock_state_changed(new_state: GameClock.State) -> void:
	var clock = GameClock.get_instance()
	var day = clock.day_number if clock else 1
	var h = clock.current_hour if clock else 8
	var m = clock.current_minute if clock else 0
	_update_day_time_display(day, h, m, new_state)

func _update_day_time_display(day: int, hours: int, minutes: int, st: GameClock.State) -> void:
	if not day_time_label:
		return

	var state_str = ""
	var state_color = Color.WHITE

	match st:
		GameClock.State.PREPARATION:
			state_str = "PREPARAÇÃO"
			state_color = Color(1.0, 0.85, 0.2, 1)
		GameClock.State.OPEN:
			state_str = "ABERTO"
			state_color = Color(0.3, 1.0, 0.4, 1)
		GameClock.State.CLOSING:
			state_str = "ENCERRANDO"
			state_color = Color(1.0, 0.5, 0.2, 1)
		GameClock.State.CLOSED:
			state_str = "FECHADO"
			state_color = Color(1.0, 0.3, 0.3, 1)

	day_time_label.text = "DIA %d  |  %02d:%02d  |  %s" % [day, hours, minutes, state_str]
	day_time_label.add_theme_color_override("font_color", state_color)

func _on_day_ended(summary: DaySummary) -> void:
	if not report_modal:
		return

	report_title.text = "📋 RELATÓRIO DO DIA %d" % summary.day_number
	report_revenue.text = "💵 Vendas do Dia: +$%.2f" % summary.revenue
	report_completed.text = "🛒 Gastos em Compras: -$%.2f" % summary.purchases
	report_cancelled.text = "📈 Lucro Líquido: $%.2f" % summary.net_profit
	report_avg_time.text = "✅ Pedidos Concluídos: %d  |  ⏱️ Tempo Médio: %.1fs" % [summary.orders_completed, summary.avg_wait_time]
	report_balance.text = "💰 Saldo Final no Caixa: $%.2f" % summary.ending_balance

	report_modal.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_day_started(_day_number: int) -> void:
	if report_modal:
		report_modal.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_orders_display()

func _on_next_day_button_pressed() -> void:
	var clock = GameClock.get_instance()
	if clock:
		clock.start_next_day()
