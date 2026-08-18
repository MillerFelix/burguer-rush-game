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

@onready var daily_notice_modal: PanelContainer = get_node_or_null("DailyNoticeModal")
@onready var notice_title_label: Label = get_node_or_null("DailyNoticeModal/VBox/NoticeTitle")
@onready var notice_headline_label: Label = get_node_or_null("DailyNoticeModal/VBox/NoticeHeadline")
@onready var notice_body_label: Label = get_node_or_null("DailyNoticeModal/VBox/NoticeBody")
@onready var date_tag_label: Label = get_node_or_null("DailyNoticeModal/VBox/DateTagLabel")
@onready var dismiss_notice_button: Button = get_node_or_null("DailyNoticeModal/VBox/DismissNoticeButton")

const CalendarManager = preload("res://src/core/calendar_manager.gd")
const DailyEventManager = preload("res://src/core/daily_event_manager.gd")

func _ready() -> void:
	hide_prompt()
	if report_modal:
		report_modal.visible = false
	if daily_notice_modal:
		daily_notice_modal.visible = false

	_update_money_display(100.0)
	_update_orders_display()
	_update_day_time_display(1, 9, 0, GameClock.State.PREPARATION)

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

	var dem = DailyEventManager.get_instance()
	if dem:
		dem.event_started.connect(_on_daily_event_started)

	if next_day_button:
		next_day_button.pressed.connect(_on_next_day_button_pressed)
	if dismiss_notice_button:
		dismiss_notice_button.pressed.connect(_on_dismiss_notice_button_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if daily_notice_modal and daily_notice_modal.visible:
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			_on_dismiss_notice_button_pressed()
			get_viewport().set_input_as_handled()
			return

	if report_modal and report_modal.visible:
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			_on_next_day_button_pressed()
			get_viewport().set_input_as_handled()

func show_prompt(text: String) -> void:
	if interaction_label:
		interaction_label.text = text
		interaction_label.visible = true

@onready var slot1_label: Label = get_node_or_null("BottomInventoryBar/TopRowHBox/ToolHotbar/HBox/Slot1Label")
@onready var slot2_label: Label = get_node_or_null("BottomInventoryBar/TopRowHBox/ToolHotbar/HBox/Slot2Label")
@onready var slot3_label: Label = get_node_or_null("BottomInventoryBar/TopRowHBox/ToolHotbar/HBox/Slot3Label")

func update_active_tool(slot_number: int) -> void:
	if not slot1_label or not slot2_label or not slot3_label:
		slot1_label = get_node_or_null("BottomInventoryBar/TopRowHBox/ToolHotbar/HBox/Slot1Label")
		slot2_label = get_node_or_null("BottomInventoryBar/TopRowHBox/ToolHotbar/HBox/Slot2Label")
		slot3_label = get_node_or_null("BottomInventoryBar/TopRowHBox/ToolHotbar/HBox/Slot3Label")

	var col_active = Color(1.0, 0.9, 0.35, 1.0)
	var col_dimmed = Color(0.65, 0.68, 0.75, 0.45)

	if slot1_label:
		slot1_label.modulate = col_active if slot_number == 1 else col_dimmed
	if slot2_label:
		slot2_label.modulate = col_active if slot_number == 2 else col_dimmed
	if slot3_label:
		slot3_label.modulate = col_active if slot_number == 3 else col_dimmed

func update_quick_slots_display(slots_info: Array, active_slot_idx: int, active_item_info: Dictionary, tool_slot: int = 3) -> void:
	update_active_tool(tool_slot)

	# 1. Atualiza o badge do item ativo
	var active_badge = get_node_or_null("BottomInventoryBar/TopRowHBox/ActiveItemBadge") as PanelContainer
	var active_lbl = get_node_or_null("BottomInventoryBar/TopRowHBox/ActiveItemBadge/ActiveItemLabel") as Label

	if active_badge and active_lbl:
		if not active_item_info.is_empty() and active_item_info.get("name", "") != "":
			active_badge.visible = true
			var count_txt = " (x%d)" % active_item_info.get("count", 1) if active_item_info.get("count", 1) > 1 else ""
			active_lbl.text = "Ativo: %s %s%s" % [
				active_item_info.get("icon", "📦"),
				active_item_info.get("name", ""),
				count_txt
			]
		else:
			active_badge.visible = false

	# 2. Atualiza os 3 slots rápidos (4, 5, 6)
	var slot_nodes = [
		{"panel": get_node_or_null("BottomInventoryBar/QuickSlotsHBox/QuickSlot4"), "label": get_node_or_null("BottomInventoryBar/QuickSlotsHBox/QuickSlot4/Label4"), "key": "4"},
		{"panel": get_node_or_null("BottomInventoryBar/QuickSlotsHBox/QuickSlot5"), "label": get_node_or_null("BottomInventoryBar/QuickSlotsHBox/QuickSlot5/Label5"), "key": "5"},
		{"panel": get_node_or_null("BottomInventoryBar/QuickSlotsHBox/QuickSlot6"), "label": get_node_or_null("BottomInventoryBar/QuickSlotsHBox/QuickSlot6/Label6"), "key": "6"}
	]

	for i in range(slot_nodes.size()):
		var sn = slot_nodes[i]
		var panel = sn["panel"] as PanelContainer
		var label = sn["label"] as Label
		var key_num = sn["key"]

		if not panel or not label:
			continue

		var is_active = (i == active_slot_idx and tool_slot == 3)
		var s_data = slots_info[i] if (i < slots_info.size()) else {}

		if s_data.is_empty():
			label.text = "[%s] (Vazio)" % key_num
			label.modulate = Color(0.55, 0.60, 0.70, 0.40)
		else:
			var icon = s_data.get("icon", "📦")
			var d_name = s_data.get("display_name", "")
			var count = s_data.get("count", 1)
			label.text = "[%s] %s %s x%d" % [key_num, icon, d_name, count]
			label.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_active else Color(0.85, 0.88, 0.95, 0.75)

		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(6)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 3
		style.content_margin_bottom = 3

		if is_active:
			style.bg_color = Color(0.16, 0.22, 0.32, 0.95)
			style.border_color = Color(1.0, 0.85, 0.20, 1.0)
			style.set_border_width_all(2)
		else:
			style.bg_color = Color(0.06, 0.08, 0.12, 0.65)
			style.border_color = Color(0.20, 0.26, 0.36, 0.50)
			style.set_border_width_all(1)

		panel.add_theme_stylebox_override("panel", style)

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
		feedback_label.visible = false

func _on_money_changed(new_amount: float, _delta: float = 0.0) -> void:
	_update_money_display(new_amount)

func _update_money_display(amount: float) -> void:
	if money_label:
		money_label.text = "💰 Caixa: $%.2f" % amount

func _on_order_event(_order: Order = null) -> void:
	_update_orders_display()

func _update_orders_display() -> void:
	if not orders_label:
		return

	var order_mgr = OrderManager.get_instance()
	if not order_mgr:
		orders_label.text = "📋 PEDIDOS ATIVOS (0)\nNenhum pedido no momento."
		return

	var active_orders = order_mgr.get_active_orders()
	if active_orders.is_empty():
		orders_label.text = "📋 PEDIDOS ATIVOS (0)\nNenhum pedido no momento."
		return

	var text = "📋 PEDIDOS ATIVOS (%d):\n" % active_orders.size()
	for o in active_orders:
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
	var h = clock.current_hour if clock else 9
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

	var cal = CalendarManager.get_instance()
	var date_str = cal.get_formatted_date() if cal else "01/01/2026"
	var weekday_short = cal.get_weekday_name().substr(0, 3) if cal else "Qui"

	day_time_label.text = "DIA %d (%s, %s)  |  %02d:%02d  |  %s" % [day, weekday_short, date_str, hours, minutes, state_str]
	day_time_label.add_theme_color_override("font_color", state_color)

func _on_daily_event_started(_event_type: int, event_data: Dictionary) -> void:
	if not daily_notice_modal:
		return

	if not event_data.get("has_event", false):
		daily_notice_modal.visible = false
		return

	if notice_title_label:
		notice_title_label.text = event_data.get("title", "AVISO DO DIA")
	if notice_headline_label:
		notice_headline_label.text = event_data.get("headline", "")
	if notice_body_label:
		notice_body_label.text = event_data.get("body", "")
	if date_tag_label:
		var cal = CalendarManager.get_instance()
		date_tag_label.text = "📰 NOTÍCIAS — %s" % (cal.get_full_date_string() if cal else "")

	daily_notice_modal.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_dismiss_notice_button_pressed() -> void:
	if daily_notice_modal:
		daily_notice_modal.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
