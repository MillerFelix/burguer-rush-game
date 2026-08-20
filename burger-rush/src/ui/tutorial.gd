class_name TutorialController
extends CanvasLayer

# =============================================================================
# BURGER RUSH — INTRODUÇÃO JOGÁVEL E REVISÃO COMPLETA DO TUTORIAL (15 ETAPAS)
#
# Estruturado, didático, focado nas ações reais dos sistemas do restaurante.
# Sem atalhos de mera proximidade. Transições com momento de leitura.
# =============================================================================

const PowerManager = preload("res://src/core/power_manager.gd")
const GameClock = preload("res://src/time/game_clock.gd")
const PurchaseManager = preload("res://src/purchasing/purchase_manager.gd")
const MainPowerPanelClass = preload("res://src/stations/main_power_panel.gd")
const ComputerStationClass = preload("res://src/stations/computer_station.gd")
const ReceivingAreaClass = preload("res://src/stations/receiving_area.gd")
const StorageRackClass = preload("res://src/stations/storage_rack.gd")
const Refrigerator = preload("res://src/stations/commercial_refrigerator.gd")
const Grill = preload("res://src/stations/grill.gd")
const PrepIsland = preload("res://src/stations/prep_island.gd")
const CommercialSinkClass = preload("res://src/stations/commercial_sink.gd")
const PackagingStationClass = preload("res://src/stations/packaging_station.gd")
const PackagedBurger = preload("res://src/items/packaged_burger.gd")
const DrinkMachineClass = preload("res://src/stations/drink_machine.gd")
const JuiceMachineClass = preload("res://src/stations/juice_machine.gd")
const FryerClass = preload("res://src/stations/fryer.gd")
const DrinkCup = preload("res://src/items/drink_cup.gd")
const DeliveryWindowStationClass = preload("res://src/stations/delivery_window_station.gd")
const ServingTray = preload("res://src/items/serving_tray.gd")
const ServingTrayStackClass = preload("res://src/stations/serving_tray_stack.gd")
const OpenSignClass = preload("res://src/stations/open_sign.gd")
const CashRegisterClass = preload("res://src/stations/cash_register.gd")
const RestaurantTableClass = preload("res://src/stations/restaurant_table.gd")
const DeliveryBox = preload("res://src/items/delivery_box.gd")
const Patty = preload("res://src/items/patty.gd")
const BreadBottom = preload("res://src/items/bread_bottom.gd")
const Burger = preload("res://src/items/burger.gd")
const Cheeseburger = preload("res://src/items/cheeseburger.gd")
const FriesPack = preload("res://src/items/fries_pack.gd")

@onready var step_title: Label = $Control/StepPanel/Margin/VBox/StepTitle
@onready var step_instruction: Label = $Control/StepPanel/Margin/VBox/StepInstruction
@onready var step_progress: Label = $Control/StepPanel/Margin/VBox/StepProgress
@onready var skip_button: Button = $Control/SkipButton
@onready var confirm_dialog: PanelContainer = $Control/ConfirmDialog
@onready var cancel_skip_button: Button = $Control/ConfirmDialog/Margin/VBox/Buttons/CancelSkipButton
@onready var confirm_skip_button: Button = $Control/ConfirmDialog/Margin/VBox/Buttons/ConfirmSkipButton
@onready var congrats_panel: PanelContainer = $Control/CongratsPanel
@onready var congrats_title: Label = $Control/CongratsPanel/Margin/VBox/CongratsTitle
@onready var congrats_text: Label = $Control/CongratsPanel/Margin/VBox/CongratsText
@onready var start_day_button: Button = $Control/CongratsPanel/Margin/VBox/StartDayButton

var current_step_index: int = 0
var tutorial_completed: bool = false

# Destaques visuais 3D reutilizáveis
var current_highlight_marker: Label3D = null
var current_highlight_light: OmniLight3D = null
var _highlight_base_y: float = 0.0

# Estado auxiliar de etapa
var step_initialized: bool = false
var step_start_pos: Vector3 = Vector3.ZERO
var step_tested_jump: bool = false
var step_tested_sprint: bool = false
var step_pc_opened: bool = false
var step_purchased_order: bool = false
var step_stored_box: bool = false
var step_ingredient_handled: bool = false
var step_juice_prepared: bool = false
var step_fryer_finished: bool = false
var step_burger_assembled: bool = false
var step_burger_packaged: bool = false
var step_grill_was_cleaned: bool = false
var step_payment_processed: bool = false
var step_money_collected: bool = false
var step_open_sign_interacted: bool = false

var transition_timer: float = 0.0
var check_timer: float = 0.0

class TutorialStep:
	var title: String
	var instruction: String
	var progress_text: String
	var highlight_name: String
	var success_msg: String

var steps: Array[TutorialStep] = []

func _ready() -> void:
	_initialize_steps()
	_connect_ui_signals()
	
	var sm = _get_save_manager()
	if sm and not sm.pending_save_data.is_empty():
		current_step_index = int(sm.pending_save_data.get("tutorial_step", 0))
		tutorial_completed = bool(sm.pending_save_data.get("tutorial_completed", false))
	
	var clock = _get_game_clock()
	if clock:
		clock.is_paused = true
	
	var rec = _get_receiving_area()
	if rec:
		rec.clear_pallet()
	
	var player = _get_player()
	if player:
		step_start_pos = player.global_position
	
	if current_step_index >= steps.size() or tutorial_completed:
		_show_congrats_panel()
	else:
		_apply_step(current_step_index)

func _initialize_steps() -> void:
	steps.clear()
	
	# ETAPA 1 — MOVIMENTAÇÃO
	var s0 = TutorialStep.new()
	s0.title = "1. MOVIMENTAÇÃO E CONTROLES"
	s0.instruction = "Use [W, A, S, D] para andar, mova o [Mouse] para olhar, pressione [Espaço] para pular e segure [Shift] para correr."
	s0.progress_text = "Mova-se, pule com [Espaço] e corra com [Shift]."
	s0.highlight_name = ""
	s0.success_msg = "Movimentação dominada com sucesso!"
	steps.append(s0)
	
	# ETAPA 2 — QUADRO DE ENERGIA
	var s1 = TutorialStep.new()
	s1.title = "2. QUADRO GERAL DE ENERGIA"
	s1.instruction = "O quadro de energia controla todo o fornecimento elétrico do restaurante. Vá até a parede externa na lateral e pressione [E] para ligar o disjuntor geral."
	s1.progress_text = "Ligue o quadro de energia geral com [E]."
	s1.highlight_name = "MainPowerPanel"
	s1.success_msg = "⚡ Rede elétrica ativada! Equipamentos energizados."
	steps.append(s1)
	
	# ETAPA 3 — PC ADMINISTRATIVO
	var s2 = TutorialStep.new()
	s2.title = "3. COMPUTADOR ADMINISTRATIVO"
	s2.instruction = "Vá até o escritório e pressione [E] para acessar o computador. É por ele que você gerencia notícias, funcionários, contas, cardápio, compras e delivery."
	s2.progress_text = "Acesse o computador com [E]."
	s2.highlight_name = "ComputerStation"
	s2.success_msg = "Computador acessado! Sistema de gestão pronto."
	steps.append(s2)
	
	# ETAPA 4 — COMPRA E RECEBIMENTO DE INGREDIENTE
	var s3 = TutorialStep.new()
	s3.title = "4. COMPRA E RECEBIMENTO DE INGREDIENTES"
	s3.instruction = "No PC, abra a aba 'Compras' e confirme um pedido. A van chegará na doca externa. Vá até o pallet externo, pegue a caixa com [E] e leve para o armazém."
	s3.progress_text = "Compre no PC, pegue a caixa no pallet [E] e leve ao armazém."
	s3.highlight_name = "ReceivingArea"
	s3.success_msg = "Mercadorias recebidas e guardadas no armazém!"
	steps.append(s3)
	
	# ETAPA 5 — INGREDIENTES E ARMAZENAMENTO
	var s4 = TutorialStep.new()
	s4.title = "5. INGREDIENTES E ARMAZENAMENTO"
	s4.instruction = "Os ingredientes ficam nas prateleiras e refrigeradores do armazém. Pegue um item com [Clique Esquerdo] e devolva com [Clique Direito]."
	s4.progress_text = "Pegue um ingrediente no armazém [Esq] e devolva [Dir]."
	s4.highlight_name = "StorageRack"
	s4.success_msg = "Lógica de estoque compreendida!"
	steps.append(s4)
	
	# ETAPA 6 — MÁQUINA DE REFRIGERANTE
	var s5 = TutorialStep.new()
	s5.title = "6. MÁQUINA DE REFRIGERANTES"
	s5.instruction = "Pegue um copo vazio no dispenser com [Clique Esquerdo], posicione sob o bico da máquina de refrigerantes e sirva a bebida com [Clique Esquerdo]."
	s5.progress_text = "Pegue um copo e sirva refrigerante na máquina."
	s5.highlight_name = "DrinkMachine"
	s5.success_msg = "Refrigerante geladinho servido com sucesso!"
	steps.append(s5)
	
	# ETAPA 7 — MÁQUINA DE SUCO
	var s6 = TutorialStep.new()
	s6.title = "7. MÁQUINA DE SUCOS NATURAIS"
	s6.instruction = "Pegue uma polpa de fruta congelada na bancada com [Clique Esquerdo], insira na máquina de suco e sirva um suco natural fresco no copo."
	s6.progress_text = "Coloque a polpa e sirva um suco natural no copo."
	s6.highlight_name = "JuiceMachine"
	s6.success_msg = "Suco natural preparado com perfeição!"
	steps.append(s6)
	
	# ETAPA 8 — FRITADEIRA
	var s7 = TutorialStep.new()
	s7.title = "8. FRITADEIRA COMERCIAL"
	s7.instruction = "Pegue batatas no armazém, coloque no cesto da fritadeira com [Clique Esquerdo], pressione [E] para abaixar no óleo e retire a porção crocante."
	s7.progress_text = "Frite uma porção de batatas e retire da fritadeira."
	s7.highlight_name = "Fryer"
	s7.success_msg = "Batatas crocantes fritas com sucesso!"
	steps.append(s7)
	
	# ETAPA 9 — GRELHA
	var s8 = TutorialStep.new()
	s8.title = "9. GRELHA INDUSTRIAL"
	s8.instruction = "Pegue um hambúrguer cru com [Clique Esquerdo], coloque na chapa da grelha, equipe a Espátula [Tecla 1], vire quando dourar e retire na espátula."
	s8.progress_text = "Coloque a carne na chapa, vire [1] e retire na espátula."
	s8.highlight_name = "Grill"
	s8.success_msg = "Carne assada no ponto perfeito recolhida na espátula!"
	steps.append(s8)
	
	# ETAPA 10 — MONTAGEM
	var s9 = TutorialStep.new()
	s9.title = "10. MONTAGEM DO HAMBÚRGUER"
	s9.instruction = "Na bancada de montagem, coloque a base do pão, adicione a carne grelhada da espátula e finalize colocando a parte superior do pão."
	s9.progress_text = "Monte o lanche: Base do pão + Carne + Topo do pão."
	s9.highlight_name = "PrepIsland"
	s9.success_msg = "Hambúrguer suculento montado com perfeição!"
	steps.append(s9)
	
	# ETAPA 11 — EMBALAGEM
	var s10 = TutorialStep.new()
	s10.title = "11. ESTAÇÃO DE EMBALAGEM"
	s10.instruction = "Leve o hambúrguer montado até a estação de embalagem. Pegue uma caixa de hambúrguer ou saco com [Clique Esquerdo] para embalar o lanche."
	s10.progress_text = "Embale o hambúrguer na estação de embalagem."
	s10.highlight_name = "PackagingStation"
	s10.success_msg = "Lanche embalado e pronto para entrega!"
	steps.append(s10)
	
	# ETAPA 12 — BANDEJA
	var s11 = TutorialStep.new()
	s11.title = "12. BANDEJA DE SERVIÇO"
	s11.instruction = "Pegue uma Bandeja de Serviço na pilha com [E] e coloque o lanche embalado nela com [Clique Esquerdo] para transportar o pedido ao cliente."
	s11.progress_text = "Pegue uma bandeja [E] e deposite o lanche embalado nela."
	s11.highlight_name = "ServingTrayStack"
	s11.success_msg = "Pedido acomodado na bandeja com sucesso!"
	steps.append(s11)
	
	# ETAPA 13 — LIMPEZA
	var s12 = TutorialStep.new()
	s12.title = "13. LIMPEZA E HIGIENE DA COZINHA"
	s12.instruction = "Equipe a Bucha de Limpeza [Tecla 2], mire na grelha e segure o [Clique Esquerdo] até limpar. Quando a bucha ficar suja, lave-a na pia industrial com [Clique Esquerdo]."
	s12.progress_text = "Limpe a grelha com a bucha [2] e lave a bucha na pia."
	s12.highlight_name = "Grill"
	s12.success_msg = "Grelha limpa e bucha higienizada na pia!"
	steps.append(s12)
	
	# ETAPA 14 — PEDIDO E PAGAMENTO
	var s13 = TutorialStep.new()
	s13.title = "14. PEDIDO E PAGAMENTO"
	s13.instruction = "Quando os clientes terminam a refeição, deixam o dinheiro no balcão ou nas mesas. Pegue as cédulas com [E] e guarde na Caixa Registradora com [E]."
	s13.progress_text = "Recolha o dinheiro e deposite na Caixa Registradora com [E]."
	s13.highlight_name = "CashRegister"
	s13.success_msg = "Dinheiro no caixa! Faturamento registrado."
	steps.append(s13)
	
	# ETAPA 15 — ABRIR E FECHAR RESTAURANTE
	var s14 = TutorialStep.new()
	s14.title = "15. EXPEDIENTE E PLACA DE ABERTURA"
	s14.instruction = "O restaurante inicia às 09:00 no Período de Preparação. Abre oficialmente às 10:00 e encerra às 22:00. Pressione [E] na Placa de Abertura na entrada."
	s14.progress_text = "Interaja com a Placa de Abertura [E]."
	s14.highlight_name = "OpenSign"
	s14.success_msg = "Rotina de funcionamento compreendida!"
	steps.append(s14)

func _connect_ui_signals() -> void:
	if skip_button and not skip_button.pressed.is_connected(_on_skip_button_pressed):
		skip_button.pressed.connect(_on_skip_button_pressed)
	if cancel_skip_button and not cancel_skip_button.pressed.is_connected(_on_cancel_skip_pressed):
		cancel_skip_button.pressed.connect(_on_cancel_skip_pressed)
	if confirm_skip_button and not confirm_skip_button.pressed.is_connected(_on_confirm_skip_pressed):
		confirm_skip_button.pressed.connect(_on_confirm_skip_pressed)
	if start_day_button and not start_day_button.pressed.is_connected(_on_start_day_pressed):
		start_day_button.pressed.connect(_on_start_day_pressed)

func _process(delta: float) -> void:
	if tutorial_completed or current_step_index >= steps.size():
		return
	
	# Animação suave do destaque 3D (pulso vertical suave)
	if current_highlight_marker and is_instance_valid(current_highlight_marker):
		var time_ms = Time.get_ticks_msec()
		var offset_y = sin(time_ms * 0.0035) * 0.08
		current_highlight_marker.position.y = _highlight_base_y + offset_y
		if current_highlight_light and is_instance_valid(current_highlight_light):
			current_highlight_light.light_energy = 1.0 + sin(time_ms * 0.004) * 0.3
	
	# Transição suave entre etapas para permitir leitura e evitar cascata
	if transition_timer > 0.0:
		transition_timer -= delta
		return
	
	# Detecção de ações de movimentação
	if Input.is_action_just_pressed("jump"):
		step_tested_jump = true
	if Input.is_action_pressed("sprint"):
		step_tested_sprint = true
	
	check_timer += delta
	if check_timer >= 0.15:
		check_timer = 0.0
		_check_step_conditions()

func _apply_step(idx: int) -> void:
	if idx >= steps.size():
		_complete_tutorial()
		return
	
	current_step_index = idx
	step_initialized = false
	step_tested_jump = false
	step_tested_sprint = false
	step_pc_opened = false
	step_purchased_order = false
	step_stored_box = false
	step_ingredient_handled = false
	step_juice_prepared = false
	step_fryer_finished = false
	step_burger_assembled = false
	step_burger_packaged = false
	step_grill_was_cleaned = false
	step_payment_processed = false
	step_money_collected = false
	step_open_sign_interacted = false
	
	transition_timer = 0.6
	
	var s = steps[idx]
	if step_title:
		step_title.text = s.title
	if step_instruction:
		step_instruction.text = s.instruction
	if step_progress:
		step_progress.text = s.progress_text
	
	var player = _get_player()
	if player:
		step_start_pos = player.global_position
	
	_clear_highlight()
	_setup_step_context(idx)
	
	step_initialized = true

func _setup_step_context(idx: int) -> void:
	match idx:
		1: # Quadro de Energia: Inicia desligado para exigir que o jogador ligue
			var pm = PowerManager.get_instance()
			if pm:
				pm.set_main_power(false)
			var panel = _get_main_power_panel()
			if panel:
				_create_highlight(panel, "Quadro Geral de Energia [E]")
		2: # PC Administrativo
			var pc = _get_computer_station()
			if pc:
				_create_highlight(pc, "PC Administrativo [E]")
		3: # Compra e Recebimento
			var rec = _get_receiving_area()
			if rec:
				_create_highlight(rec, "Pallet de Recebimento de Mercadorias")
		4: # Armazenamento / Estoque
			var rack = _get_storage_rack()
			if rack:
				_create_highlight(rack, "Prateleiras do Armazém [Esq / Dir]")
		5: # Máquina de Refrigerante
			var dm = _get_drink_machine()
			if dm:
				_create_highlight(dm, "Máquina de Refrigerantes")
		6: # Máquina de Suco
			var jm = _get_juice_machine()
			if jm:
				_create_highlight(jm, "Máquina de Sucos Naturais")
		7: # Fritadeira
			var fry = _get_fryer()
			if fry:
				_create_highlight(fry, "Fritadeira Comercial [E]")
		8: # Grelha
			var gr = _get_grill()
			if gr:
				gr.is_on = true
				gr.current_temperature = 200.0
				_create_highlight(gr, "Chapa da Grelha [1]")
		9: # Montagem
			var pi = _get_prep_island()
			if pi:
				_create_highlight(pi, "Ilha de Preparo e Montagem")
		10: # Embalagem
			var ps = _get_packaging_station()
			if ps:
				_create_highlight(ps, "Estação de Embalagem")
		11: # Bandeja
			var tr = _get_tray_stack()
			if tr:
				_create_highlight(tr, "Pilha de Bandejas [E]")
		12: # Limpeza da Grelha
			var gr = _get_grill()
			if gr:
				gr.add_dirt(0.60)
				_create_highlight(gr, "Grelha (Esfregar com Bucha [2])")
			var player = _get_player()
			if player:
				player.select_tool_slot(Player.ToolSlot.SPONGE, false)
		13: # Pagamento
			var cr = _get_cash_register()
			if cr:
				_create_highlight(cr, "Caixa Registradora [E]")
		14: # Placa de Abertura
			var op = _get_open_sign()
			if op:
				_create_highlight(op, "Placa de Abertura [E]")

func _check_step_conditions() -> void:
	if not step_initialized or current_step_index >= steps.size():
		return
	
	var player = _get_player()
	var step_ok = false
	
	match current_step_index:
		0: # Movimentação
			if player and player.global_position.distance_to(step_start_pos) > 2.0 and step_tested_jump and step_tested_sprint:
				step_ok = true
		1: # Quadro de Energia: requer que o disjuntor tenha sido ligado com [E]
			var pm = PowerManager.get_instance()
			if pm and pm.is_main_power_on:
				step_ok = true
		2: # PC Administrativo: abrir o PC
			var comp_ui = get_tree().root.find_child("ComputerUI", true, false)
			if (comp_ui and comp_ui.visible) or (player and player.is_using_computer) or step_pc_opened:
				step_ok = true
		3: # Compra e Recebimento: comprar e levar caixa ao armazém
			var rec = _get_receiving_area()
			if step_stored_box:
				step_ok = true
			elif player and player.held_item is DeliveryBox:
				var rack_pos = _get_station_pos("StorageRack")
				if player.global_position.distance_to(rack_pos) < 3.5:
					step_ok = true
			elif rec and rec.get_delivered_boxes().size() > 0:
				_create_highlight(rec, "Pegue a Caixa de Mercadorias com [E]")
		4: # Ingredientes e Armazenamento: pegar ingrediente e devolver
			if step_ingredient_handled:
				step_ok = true
			elif player and (player.has_active_ingredient() or player.held_item != null):
				step_ok = true
		5: # Máquina de Refrigerante: copo servido
			if player and player.held_item is DrinkCup:
				var cup = player.held_item as DrinkCup
				if cup.state == DrinkCup.State.FILLED and not cup.beverage_type.begins_with("juice"):
					step_ok = true
		6: # Máquina de Suco: suco natural servido no copo
			if step_juice_prepared:
				step_ok = true
			elif player and player.held_item is DrinkCup:
				var cup = player.held_item as DrinkCup
				if cup.state == DrinkCup.State.FILLED and cup.beverage_type.begins_with("juice"):
					step_ok = true
		7: # Fritadeira: porção de batatas frita e retirada
			if step_fryer_finished:
				step_ok = true
			elif player and (player.held_item is FriesPack or (player.has_active_ingredient() and player.get_active_ingredient().get("item_id") == "fries_pack")):
				step_ok = true
		8: # Grelha: carne na espátula
			if player and player.has_method("get_spatula_held_patty") and player.get_spatula_held_patty() != null:
				step_ok = true
		9: # Montagem: hambúrguer montado
			if step_burger_assembled:
				step_ok = true
			elif player and (player.held_item is Burger or player.held_item is Cheeseburger or (player.has_active_ingredient() and str(player.get_active_ingredient().get("item_id")).begins_with("burger"))):
				step_ok = true
		10: # Embalagem: hambúrguer embalado
			if step_burger_packaged:
				step_ok = true
			elif player and (player.held_item is PackagedBurger or (player.held_item != null and player.held_item.has_method("is_packaged") and player.held_item.is_packaged())):
				step_ok = true
		11: # Bandeja: lanche na bandeja
			if player and player.held_item is ServingTray:
				var tray = player.held_item as ServingTray
				if tray.carried_items.size() > 0 or (tray.has_method("has_items") and tray.has_items()):
					step_ok = true
		12: # Limpeza: grelha limpa e bucha lavada na pia
			var gr = _get_grill()
			var sink = _get_sink()
			var sponge_clean = (player and not player.sponge_is_dirty)
			if gr and not gr.is_dirty():
				step_grill_was_cleaned = true
			if step_grill_was_cleaned and player and player.sponge_is_dirty and sink:
				_create_highlight(sink, "Lave a Bucha na Pia [Clique Esquerdo]")
			if gr and not gr.is_dirty() and sponge_clean and step_grill_was_cleaned:
				step_ok = true
		13: # Pagamento: dinheiro no caixa
			if step_payment_processed or step_money_collected:
				step_ok = true
			var player_has_money = (player and player.held_item != null and (player.held_item.get("is_customer_deposit_money") == true or str(player.held_item.get("item_id")) == "customer_money"))
			if player_has_money:
				var cr = _get_cash_register()
				if cr:
					_create_highlight(cr, "Deposite o Dinheiro na Caixa Registradora [E]")
		14: # Placa de Abertura
			if step_open_sign_interacted:
				step_ok = true
	
	if step_ok:
		_advance_step()

func _advance_step() -> void:
	if current_step_index < steps.size():
		var s = steps[current_step_index]
		var player = _get_player()
		if player and player.has_node("HUD") and player.get_node("HUD").has_method("show_temporary_feedback"):
			player.get_node("HUD").show_temporary_feedback("✨ %s" % s.success_msg)
	
	current_step_index += 1
	_save_tutorial_progress()
	
	if current_step_index >= steps.size():
		_complete_tutorial()
	else:
		_apply_step(current_step_index)

func _complete_tutorial() -> void:
	tutorial_completed = true
	_clear_highlight()
	_show_congrats_panel()
	_save_tutorial_progress()
	
	var clock = _get_game_clock()
	if clock:
		clock.is_paused = false
		clock.current_hour = 9
		clock.current_minute = 0
		clock.state = GameClock.State.PREPARATION

func _show_congrats_panel() -> void:
	if congrats_panel:
		congrats_panel.visible = true
	if congrats_title:
		congrats_title.text = "🎓 TUTORIAL CONCLUÍDO!"
	if congrats_text:
		congrats_text.text = "Você já conhece o básico para administrar seu restaurante."
	if start_day_button:
		start_day_button.text = "COMEÇAR DIA 1"
	if step_title:
		step_title.text = "🎉 TUTORIAL CONCLUÍDO COM SUCESSO!"
	if step_instruction:
		step_instruction.text = "Você aprendeu todos os sistemas essenciais do Burger Rush. Agora você está pronto para assumir o restaurante no Dia 1!"
	if step_progress:
		step_progress.text = "Etapa 15 / 15 (100% Concluído)"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_skip_button_pressed() -> void:
	if confirm_dialog:
		confirm_dialog.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_cancel_skip_pressed() -> void:
	if confirm_dialog:
		confirm_dialog.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_confirm_skip_pressed() -> void:
	if confirm_dialog:
		confirm_dialog.visible = false
	current_step_index = steps.size()
	_complete_tutorial()

func _on_start_day_pressed() -> void:
	tutorial_completed = true
	_save_tutorial_progress()
	
	var clock = _get_game_clock()
	if clock:
		clock.is_paused = false
		clock.current_hour = 9
		clock.current_minute = 0
		clock.state = GameClock.State.PREPARATION
	
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("_check_and_show_day1_intro"):
		hud._check_and_show_day1_intro()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	queue_free()

func _save_tutorial_progress() -> void:
	var sm = _get_save_manager()
	if sm and sm.has_active_game:
		sm.pending_save_data["tutorial_step"] = current_step_index
		sm.pending_save_data["tutorial_completed"] = tutorial_completed
		sm.save_game(sm.active_slot)

# =============================================================================
# SISTEMA DE DESTAQUES VISUAIS 3D (ANIMAÇÃO E BRILHO)
# =============================================================================

func _create_highlight(target: Node3D, label_text: String) -> void:
	_clear_highlight()
	if not target or not is_instance_valid(target):
		return
	
	var marker_root = Node3D.new()
	marker_root.name = "TutorialHighlight"
	target.add_child(marker_root)
	
	var marker_y = 1.35
	if target is MainPowerPanelClass:
		marker_y = 1.60
	elif target is CommercialSinkClass:
		marker_y = 1.40
	elif target is OpenSignClass:
		marker_y = 1.60
	
	marker_root.position = Vector3(0, marker_y, 0)
	_highlight_base_y = marker_y
	
	var lbl = Label3D.new()
	lbl.name = "HighlightLabel"
	lbl.text = "▼\n%s" % label_text
	lbl.font_size = 24
	lbl.outline_size = 6
	lbl.modulate = Color(1.0, 0.84, 0.22, 1.0)
	lbl.outline_modulate = Color(0.1, 0.1, 0.1, 1.0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.double_sided = false
	marker_root.add_child(lbl)
	current_highlight_marker = lbl
	
	var light = OmniLight3D.new()
	light.name = "HighlightLight"
	light.light_color = Color(1.0, 0.85, 0.35, 1.0)
	light.light_energy = 1.2
	light.omni_range = 3.5
	marker_root.add_child(light)
	current_highlight_light = light

func _clear_highlight() -> void:
	if current_highlight_marker and is_instance_valid(current_highlight_marker):
		var p = current_highlight_marker.get_parent()
		if p and is_instance_valid(p):
			p.queue_free()
	current_highlight_marker = null
	current_highlight_light = null

# =============================================================================
# RESOLUÇÃO DE REFERÊNCIAS DO JOGO
# =============================================================================

func _get_player() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("Player", true, false) as Node3D

func _get_game_clock() -> GameClock:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("GameClock", true, false) as GameClock

func _get_save_manager():
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	var sm = get_tree().root.find_child("SaveManager", true, false)
	if not sm:
		var sm_script = load("res://src/core/save_manager.gd")
		if sm_script and "instance" in sm_script:
			sm = sm_script.instance
	return sm

func _get_purchase_manager() -> PurchaseManager:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("PurchaseManager", true, false) as PurchaseManager

func _get_main_power_panel() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("MainPowerPanel", true, false) as Node3D

func _get_computer_station() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("ComputerStation", true, false) as Node3D

func _get_receiving_area() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("ReceivingArea", true, false) as Node3D

func _get_storage_rack() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("StorageRack", true, false) as Node3D

func _get_refrigerator() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("CommercialRefrigerator", true, false) as Node3D

func _get_drink_machine() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("DrinkMachine", true, false) as Node3D

func _get_juice_machine() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("JuiceMachine", true, false) as Node3D

func _get_fryer() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("Fryer", true, false) as Node3D

func _get_grill() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("Grill", true, false) as Node3D

func _get_prep_island() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("PrepIsland", true, false) as Node3D

func _get_sink() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("CommercialSink", true, false) as Node3D

func _get_packaging_station() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("PackagingStation", true, false) as Node3D

func _get_restaurant_table() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("RestaurantTable", true, false) as Node3D

func _get_delivery_window() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("DeliveryWindowStation", true, false) as Node3D

func _get_tray_stack() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("ServingTrayStack", true, false) as Node3D

func _get_cash_register() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("CashRegister", true, false) as Node3D

func _get_open_sign() -> Node3D:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return null
	return get_tree().root.find_child("OpenSign", true, false) as Node3D

func _get_station_pos(st_name: String) -> Vector3:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return Vector3.ZERO
	var n = get_tree().root.find_child(st_name, true, false) as Node3D
	return n.global_position if n else Vector3.ZERO
