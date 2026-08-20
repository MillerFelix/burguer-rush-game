class_name HUD
extends CanvasLayer

@onready var interaction_label: Label = $InteractionLabel
@onready var crosshair: ColorRect = $Crosshair
@onready var money_label: Label = $TopRight/MoneyLabel
@onready var orders_label: Label = $TopLeft/OrdersLabel
@onready var day_time_label: Label = $TopCenter/DayTimeLabel
@onready var feedback_label: Label = $FeedbackLabel
@onready var feedback_timer: Timer = $FeedbackTimer

@onready var report_modal: PanelContainer = get_node_or_null("DayReportModal")
@onready var report_title: Label = get_node_or_null("DayReportModal/MarginContainer/VBox/TitleLabel")
@onready var report_date: Label = get_node_or_null("DayReportModal/MarginContainer/VBox/DateLabel")
@onready var report_starting_balance: Label = get_node_or_null("DayReportModal/MarginContainer/VBox/Grid/StartingBalanceLabel")
@onready var report_revenue: Label = get_node_or_null("DayReportModal/MarginContainer/VBox/Grid/RevenueLabel")
@onready var report_purchases: Label = get_node_or_null("DayReportModal/MarginContainer/VBox/Grid/PurchasesLabel")
@onready var report_net_profit: Label = get_node_or_null("DayReportModal/MarginContainer/VBox/Grid/NetProfitLabel")
@onready var report_completed: Label = get_node_or_null("DayReportModal/MarginContainer/VBox/Grid/CompletedLabel")
@onready var report_reputation: Label = get_node_or_null("DayReportModal/MarginContainer/VBox/Grid/ReputationLabel")
@onready var report_balance: Label = get_node_or_null("DayReportModal/MarginContainer/VBox/Grid/BalanceLabel")
@onready var next_day_button: Button = get_node_or_null("DayReportModal/MarginContainer/VBox/NextDayButton")

@onready var daily_notice_modal: PanelContainer = get_node_or_null("DailyNoticeModal")
@onready var notice_title_label: Label = get_node_or_null("DailyNoticeModal/VBox/NoticeTitle")
@onready var notice_headline_label: Label = get_node_or_null("DailyNoticeModal/VBox/NoticeHeadline")
@onready var notice_body_label: Label = get_node_or_null("DailyNoticeModal/VBox/NoticeBody")
@onready var date_tag_label: Label = get_node_or_null("DailyNoticeModal/VBox/DateTagLabel")
@onready var dismiss_notice_button: Button = get_node_or_null("DailyNoticeModal/VBox/DismissNoticeButton")

@onready var day1_welcome_modal: PanelContainer = get_node_or_null("Day1WelcomeModal")
@onready var day1_title_label: Label = get_node_or_null("Day1WelcomeModal/MarginContainer/VBox/TitleLabel")
@onready var day1_body_label: Label = get_node_or_null("Day1WelcomeModal/MarginContainer/VBox/BodyLabel")
@onready var day1_start_button: Button = get_node_or_null("Day1WelcomeModal/MarginContainer/VBox/StartButton")

const CalendarManager = preload("res://src/core/calendar_manager.gd")
const DailyEventManager = preload("res://src/core/daily_event_manager.gd")
const SaveManager = preload("res://src/core/save_manager.gd")
const GameClock = preload("res://src/time/game_clock.gd")
const EconomyManager = preload("res://src/economy/economy_manager.gd")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_prompt()
	if report_modal:
		report_modal.process_mode = Node.PROCESS_MODE_ALWAYS
		report_modal.visible = false
	if daily_notice_modal:
		daily_notice_modal.process_mode = Node.PROCESS_MODE_ALWAYS
		daily_notice_modal.visible = false
	if day1_welcome_modal:
		day1_welcome_modal.process_mode = Node.PROCESS_MODE_ALWAYS
		day1_welcome_modal.visible = false

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
	if not dem and is_inside_tree() and get_tree() and get_tree().root:
		dem = get_tree().root.find_child("DailyEventManager", true, false)
	if dem and not dem.event_started.is_connected(_on_daily_event_started):
		dem.event_started.connect(_on_daily_event_started)

	if next_day_button:
		next_day_button.pressed.connect(_on_next_day_button_pressed)
	if dismiss_notice_button:
		dismiss_notice_button.pressed.connect(_on_dismiss_notice_button_pressed)
	if day1_start_button:
		day1_start_button.pressed.connect(_on_day1_start_button_pressed)

	_check_and_show_day1_intro()
	_check_and_show_daily_notice()
	call_deferred("_check_and_show_day1_intro")
	call_deferred("_check_and_show_daily_notice")

func _unhandled_input(event: InputEvent) -> void:
	if day1_welcome_modal and day1_welcome_modal.visible:
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			_on_day1_start_button_pressed()
			get_viewport().set_input_as_handled()
			return

	if daily_notice_modal and daily_notice_modal.visible:
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			_on_dismiss_notice_button_pressed()
			get_viewport().set_input_as_handled()
			return

	# Bloqueio estrito: Enquanto a tela de Dia Encerrado estiver visível, NENHUMA tecla ou ação de gameplay é disparada
	if report_modal and report_modal.visible:
		get_viewport().set_input_as_handled()
		return

func _check_and_show_day1_intro() -> void:
	var sm = _get_save_manager()
	if not sm:
		return

	if not sm.has_active_game or sm.pending_save_data.is_empty():
		if sm.has_method("load_game"):
			sm.load_game(sm.active_slot)

	if not sm.has_active_game:
		return

	# 1. Se o tutorial NÃO foi concluído, NUNCA exibe a introdução do Dia 1
	var tut_completed = bool(sm.pending_save_data.get("tutorial_completed", false))
	if not tut_completed:
		return

	# 2. Se houver qualquer nó de tutorial ativo na árvore de nós, não exibe
	if is_inside_tree() and get_tree() and get_tree().root:
		var tut = get_tree().root.find_child("Tutorial", true, false)
		if tut and is_instance_valid(tut) and not tut.get("tutorial_completed"):
			return
		var tut_intro = get_tree().root.find_child("TutorialIntroUI", true, false)
		if tut_intro and is_instance_valid(tut_intro):
			return

	# 3. Se o GameManager estiver em estado de tutorial, não exibe
	var gm = _get_game_manager()
	if gm and "GameState" in gm and "current_state" in gm:
		if gm.current_state == gm.GameState.TUTORIAL:
			return

	# 4. Só exibe se for o Dia 1 e a mensagem ainda não tiver sido apresentada
	var current_day = sm.pending_save_data.get("current_day", sm.pending_save_data.get("day_number", 1))
	var shown = sm.pending_save_data.get("day1_intro_shown", false)
	if current_day == 1 and not shown:
		var raw_name = str(sm.pending_save_data.get("chef_name", sm.pending_save_data.get("player_name", "Chefe")))
		var player_name = raw_name.strip_edges()
		if player_name.begins_with("Chef ") or player_name.begins_with("Chefe "):
			player_name = player_name.substr(player_name.find(" ") + 1).strip_edges()
		if player_name.is_empty():
			player_name = "Chefe"
		if day1_title_label:
			day1_title_label.text = "SEU PRIMEIRO DIA"
		if day1_body_label:
			day1_body_label.text = "Chefe %s, agora é pra valer.\n\nO treinamento terminou e o restaurante está oficialmente sob sua responsabilidade.\n\nAgora é sua vez de colocar tudo o que aprendeu em prática, atender seus clientes, administrar o restaurante e fazer seu negócio crescer.\n\nBoa sorte. O seu primeiro dia começa agora!" % player_name
		if day1_start_button:
			day1_start_button.text = "COMEÇAR DIA 1"
		if day1_welcome_modal:
			day1_welcome_modal.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_day1_start_button_pressed() -> void:
	if day1_welcome_modal:
		day1_welcome_modal.visible = false
	var sm = _get_save_manager()
	if sm and sm.has_active_game:
		sm.pending_save_data["day1_intro_shown"] = true
		sm.save_game(sm.active_slot)

	var gm = _get_game_manager()
	if gm and "GameState" in gm and gm.has_method("change_state"):
		gm.change_state(gm.GameState.PLAYING)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _get_save_manager() -> Node:
	if is_inside_tree() and get_tree() != null and get_tree().root:
		if get_tree().root.has_node("SaveManager"):
			return get_tree().root.get_node("SaveManager")
		for child in get_tree().root.get_children():
			if child.name == "SaveManager" or child.get_script() == load("res://src/core/save_manager.gd"):
				return child
	var sm_script = load("res://src/core/save_manager.gd")
	if sm_script and "instance" in sm_script and sm_script.instance and is_instance_valid(sm_script.instance):
		return sm_script.instance
	if sm_script and sm_script.has_method("get_instance"):
		return sm_script.get_instance()
	return null

func _get_game_manager() -> Node:
	if is_inside_tree() and get_tree() != null and get_tree().root:
		if get_tree().root.has_node("GameManager"):
			return get_tree().root.get_node("GameManager")
		for child in get_tree().root.get_children():
			if child.name == "GameManager" or child.get_script() == load("res://src/core/game_manager.gd"):
				return child
	var gm_script = load("res://src/core/game_manager.gd")
	if gm_script and "instance" in gm_script and gm_script.instance and is_instance_valid(gm_script.instance):
		return gm_script.instance
	if gm_script and gm_script.has_method("get_instance"):
		return gm_script.get_instance()
	return null

func show_prompt(text: String) -> void:
	if interaction_label:
		if interaction_label.text != text:
			interaction_label.text = text
		if not interaction_label.visible:
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
			if active_item_info.get("is_large_item", false):
				active_lbl.text = "Mão: %s %s" % [
					active_item_info.get("icon", "📦"),
					active_item_info.get("name", "")
				]
			else:
				var slot_num = active_item_info.get("slot", 0) + 4
				active_lbl.text = "Ativo [%d]: %s %s" % [
					slot_num,
					active_item_info.get("icon", "📦"),
					active_item_info.get("name", "")
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

		var is_active = (i == active_slot_idx)
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
	if interaction_label and interaction_label.visible:
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

func _check_and_show_daily_notice() -> void:
	if day1_welcome_modal and day1_welcome_modal.visible:
		return
	var dem = DailyEventManager.get_instance()
	if not dem and is_inside_tree() and get_tree() and get_tree().root:
		dem = get_tree().root.find_child("DailyEventManager", true, false)
	if dem:
		var edata = dem.get_current_event_data()
		_on_daily_event_started(dem.current_event, edata)

func _on_daily_event_started(_event_type: int, event_data: Dictionary) -> void:
	if not daily_notice_modal:
		daily_notice_modal = get_node_or_null("DailyNoticeModal")
	if not daily_notice_modal:
		return

	# Se for o Dia 1 e a introdução de boas-vindas estiver ativa, prioriza a introdução
	if day1_welcome_modal and day1_welcome_modal.visible:
		daily_notice_modal.visible = false
		return

	if not event_data.get("has_event", false) or _event_type == DailyEventManager.EventType.NONE:
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
		report_modal = get_node_or_null("DayReportModal")
		if not report_modal:
			return

	# 1. Salva imediatamente o progresso final do dia no slot ativo
	var sm = _get_save_manager()
	if sm and sm.has_active_game:
		sm.pending_save_data["current_day"] = summary.day_number
		sm.pending_save_data["money"] = summary.ending_balance
		sm.save_game(sm.active_slot)

	# 2. Notifica o GameManager do estado DAY_END
	var gm = _get_game_manager()
	if gm and gm.has_method("change_state"):
		gm.change_state(gm.get("GameState").DAY_END if "GameState" in gm else 6)

	var cal = CalendarManager.get_instance()
	var date_str = cal.get_full_date_string() if cal else "Dia %d" % summary.day_number

	if report_title:
		report_title.text = "🎉 DIA %d ENCERRADO!" % summary.day_number
	if report_date:
		report_date.text = "📅 %s" % date_str
	if report_starting_balance:
		report_starting_balance.text = "💵 Dinheiro Inicial: R$ %.2f" % summary.starting_balance
	if report_revenue:
		report_revenue.text = "🛒 Vendas do Dia: +R$ %.2f" % summary.revenue
	if report_purchases:
		report_purchases.text = "📦 Despesas e Compras: -R$ %.2f" % summary.purchases
	if report_net_profit:
		var sign_char = "+" if summary.net_profit >= 0 else ""
		report_net_profit.text = "📈 Lucro Líquido: %sR$ %.2f" % [sign_char, summary.net_profit]
		report_net_profit.modulate = Color(0.4, 0.95, 0.55, 1.0) if summary.net_profit >= 0 else Color(1.0, 0.4, 0.4, 1.0)
	if report_completed:
		var abandon_count = summary.customers_abandoned if "customers_abandoned" in summary else 0
		report_completed.text = "🍔 Pedidos Atendidos: %d concluídos | 🚶 Abandono: %d clientes" % [summary.orders_completed, abandon_count]
	if report_reputation:
		var rep_val = summary.reputation if "reputation" in summary else 5.0
		report_reputation.text = "⭐ Reputação do Restaurante: %.1f / 5.0 estrelas" % rep_val
	if report_balance:
		report_balance.text = "💰 Dinheiro Final: R$ %.2f" % summary.ending_balance

	report_modal.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if next_day_button and is_inside_tree():
		next_day_button.grab_focus()

	# Toca o som de resultado/fechamento
	var audio_stream = SoundSynthesizer.get_stream("cash_register_open")
	if audio_stream:
		var p = AudioStreamPlayer.new()
		p.stream = audio_stream
		p.bus = "SFX"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		p.play()
		p.finished.connect(p.queue_free)

func _on_day_started(_day_number: int) -> void:
	if report_modal:
		report_modal.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_orders_display()
	_check_and_show_daily_notice()

func _on_next_day_button_pressed() -> void:
	get_tree().paused = false
	if report_modal:
		report_modal.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# 1. Inicia o próximo dia no mesmo mundo sem recarregar a cena (preserva itens e estado do restaurante)
	var clock = GameClock.get_instance()
	if clock:
		clock.start_next_day()

	# 2. Atualiza e salva o estado do jogo no disco
	var sm = _get_save_manager()
	if sm and sm.has_active_game:
		var cal_mgr = CalendarManager.get_instance()
		var current_d = cal_mgr.day_number if cal_mgr else (clock.day_number if clock else 2)
		sm.pending_save_data["current_day"] = current_d
		sm.pending_save_data["day"] = current_d
		sm.pending_save_data["day_number"] = current_d
		sm.pending_save_data["calendar_day"] = current_d
		sm.pending_save_data["day_of_week"] = cal_mgr.day_of_week if cal_mgr else 1
		sm.pending_save_data["week_number"] = int((current_d - 1) / 7) + 1
		var econ = EconomyManager.get_instance()
		if econ:
			sm.pending_save_data["money"] = econ.get_money()
		sm.pending_save_data["clock_hour"] = 9
		sm.pending_save_data["clock_minute"] = 0
		sm.pending_save_data["clock_state"] = "PREPARATION"
		sm.pending_save_data["day1_intro_shown"] = true
		sm.save_game(sm.active_slot)

	# 3. Notifica o GameManager do retorno ao estado PLAYING
	var gm = _get_game_manager()
	if gm and gm.has_method("change_state"):
		gm.change_state(gm.GameState.PLAYING if "GameState" in gm else 1)

	# 4. Restaura controle do jogador e câmera
	var player = get_tree().get_first_node_in_group("player") as Node3D if (is_inside_tree() and get_tree()) else null
	if player:
		if "can_move" in player:
			player.can_move = true
		if "is_paused" in player:
			player.is_paused = false
		if player.has_method("_notify_hud_quick_slots"):
			player._notify_hud_quick_slots()

	_update_orders_display()
	_check_and_show_daily_notice()
