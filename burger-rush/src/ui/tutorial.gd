class_name TutorialController
extends CanvasLayer

# =============================================================================
# BURGER RUSH — TUTORIAL DIDÁTICO E REFINADO (15 ETAPAS COM MICROETAPAS)
#
# Ritmo calmo na explicação, rápido na execução.
# Cada etapa ensina detalhadamente: o que é o objeto, para que serve,
# onde ir, qual botão usar e como saber que terminou.
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
const BurgerAssembly = preload("res://src/recipes/burger_assembly.gd")

@onready var step_title: Label = $Control/StepPanel/Margin/VBox/StepTitle
@onready var step_instruction: Label = $Control/StepPanel/Margin/VBox/StepInstruction
@onready var step_progress: Label = $Control/StepPanel/Margin/VBox/StepProgress
@onready var congrats_panel: PanelContainer = $Control/CongratsPanel
@onready var congrats_title: Label = $Control/CongratsPanel/Margin/VBox/CongratsTitle
@onready var congrats_text: Label = $Control/CongratsPanel/Margin/VBox/CongratsText
@onready var start_day_button: Button = $Control/CongratsPanel/Margin/VBox/StartDayButton

var current_step_index: int = 0
var tutorial_completed: bool = false

# Destaques visuais 3D reutilizáveis e estáveis
var current_highlight_marker: Label3D = null
var current_highlight_light: OmniLight3D = null
var current_highlight_target: Node3D = null
var current_highlight_label_text: String = ""
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
		if not clock.state_changed.is_connected(_on_clock_state_changed):
			clock.state_changed.connect(_on_clock_state_changed)
	
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
	
	# ETAPA 1 — MOVIMENTAÇÃO E CONTROLES
	var s0 = TutorialStep.new()
	s0.title = "1. MOVIMENTAÇÃO E CONTROLES"
	s0.instruction = "Bem-vindo ao Burger Rush! Use [W, A, S, D] para andar pelo restaurante, mova o [Mouse] para olhar ao redor, pressione [Espaço] para pular e segure [Shift] para correr."
	s0.progress_text = "Mova-se, pule com [Espaço] e corra com [Shift]."
	s0.highlight_name = ""
	s0.success_msg = "Perfeito! Movimentação dominada com sucesso."
	steps.append(s0)
	
	# ETAPA 2 — QUADRO GERAL DE ENERGIA
	var s1 = TutorialStep.new()
	s1.title = "2. QUADRO GERAL DE ENERGIA"
	s1.instruction = "O quadro de energia controla todo o fornecimento elétrico do restaurante. Sem energia, máquinas e iluminação não funcionam. Vá até a parede externa na lateral e pressione [E] para ligar o disjuntor geral."
	s1.progress_text = "Vá até o quadro na parede externa e ligue a chave geral com [E]."
	s1.highlight_name = "MainPowerPanel"
	s1.success_msg = "⚡ Excelente! Rede elétrica ativada e equipamentos energizados."
	steps.append(s1)
	
	# ETAPA 3 — COMPUTADOR ADMINISTRATIVO
	var s2 = TutorialStep.new()
	s2.title = "3. COMPUTADOR ADMINISTRATIVO E GESTÃO"
	s2.instruction = "Na cozinha, localize o computador administrativo e acesse-o pressionando [E]. Ele é a central de comando do Burger Rush, onde você gerencia compras de insumos, receitas, finanças e contratação de funcionários."
	s2.progress_text = "Acesse o computador administrativo na cozinha com [E]."
	s2.highlight_name = "ComputerStation"
	s2.success_msg = "Ótimo! Computador administrativo acessado com sucesso."
	steps.append(s2)
	
	# ETAPA 4 — COMPRA E RECEBIMENTO DE MERCADORIAS
	var s3 = TutorialStep.new()
	s3.title = "4. COMPRA E RECEBIMENTO DE MERCADORIAS"
	s3.instruction = "No computador, abra a aba 'Compras' e confirme um pedido de suprimentos. O fornecedor descarregará as caixas no PALLET EXTERNO DO RESTAURANTE. Vá até a área externa, pegue a caixa no pallet pressionando [E] e transporte-a para dentro do armazém."
	s3.progress_text = "Pegue a caixa de mercadorias no pallet externo [E] e guarde no armazém."
	s3.highlight_name = "ReceivingArea"
	s3.success_msg = "Mercadorias recolhidas do pallet externo e guardadas no armazém!"
	steps.append(s3)
	
	# ETAPA 5 — INGREDIENTES E ARMAZENAMENTO
	var s4 = TutorialStep.new()
	s4.title = "5. INGREDIENTES E ARMAZENAMENTO"
	s4.instruction = "No armazém, os ingredientes ficam organizados em prateleiras e refrigeradores. Para pegar um item, use o [Clique Esquerdo]. Para devolver ao estoque, use o [Clique Direito]. Pratique pegando um item."
	s4.progress_text = "Pegue um ingrediente no armazém [Clique Esquerdo]."
	s4.highlight_name = "StorageRack"
	s4.success_msg = "Muito bem! Lógica de estoque compreendida."
	steps.append(s4)
	
	# ETAPA 6 — MÁQUINA DE REFRIGERANTES
	var s5 = TutorialStep.new()
	s5.title = "6. MÁQUINA DE REFRIGERANTES"
	s5.instruction = "1. Pegue um copo vazio na MESA DE EMBALAGENS com [Clique Esquerdo].\n2. Leve o copo até a máquina de refrigerante.\n3. Posicione o copo na máquina pressionando a tecla [E].\n4. A máquina encherá o copo automaticamente com refrigerante gelado."
	s5.progress_text = "Pegue um copo na mesa de embalagens e posicione na máquina de refrigerante com [E]."
	s5.highlight_name = "DrinkMachine"
	s5.success_msg = "Refrigerante gelado servido com sucesso!"
	steps.append(s5)
	
	# ETAPA 7 — MÁQUINA DE SUCOS NATURAIS
	var s6 = TutorialStep.new()
	s6.title = "7. MÁQUINA DE SUCOS NATURAIS"
	s6.instruction = "1. Pegue uma polpa de fruta congelada no ESTOQUE / armazém com [Clique Esquerdo].\n2. Coloque a polpa na gaveta superior da máquina de suco com [Clique Esquerdo].\n3. Pegue um copo vazio na mesa de embalagens.\n4. Posicione o copo na máquina pressionando [E] para extrair e servir o suco natural fresco."
	s6.progress_text = "Pegue a polpa no estoque, coloque na máquina, posicione o copo com [E] e sirva o suco."
	s6.highlight_name = "JuiceMachine"
	s6.success_msg = "Suco natural fresco preparado e servido com sucesso!"
	steps.append(s6)
	
	# ETAPA 8 — FRITADEIRA COMERCIAL
	var s7 = TutorialStep.new()
	s7.title = "8. FRITADEIRA COMERCIAL (BATATAS E ANÉIS DE CEBOLA)"
	s7.instruction = "A fritadeira prepara TANTO BATATAS QUANTO ANÉIS DE CEBOLA:\n1. Ligue a fritadeira interagindo com ela.\n2. Pegue a porção crua de batata ou cebola no estoque com [Clique Esquerdo].\n3. Coloque na cesta da fritadeira.\n4. Pressione [E] para abaixar a cesta no óleo aquecido.\n5. Aguarde o tempo rápido de fritura.\n6. Pressione [E] para erguer e retirar a porção pronta.\n(Dica: As embalagens vermelhas de porções prontas ficam na mesa de embalagens)."
	s7.progress_text = "Ligue a fritadeira, coloque a batata ou cebola na cesta, abaixe com [E] e retire quando dourar."
	s7.highlight_name = "Fryer"
	s7.success_msg = "Acompanhamento crocante frito com perfeição!"
	steps.append(s7)
	
	# ETAPA 9 — GRELHA INDUSTRIAL — PREPARO DO HAMBÚRGUER
	var s8 = TutorialStep.new()
	s8.title = "9. GRELHA INDUSTRIAL — PREPARO DO HAMBÚRGUER"
	s8.instruction = "Vamos preparar seu primeiro hambúrguer. Pegue um hambúrguer cru no refrigerador com [Clique Esquerdo], coloque sobre a chapa quente, equipe a Espátula [Tecla 1] e aguarde o preparo acelerado. Quando dourar, vire a carne e depois retire-a na espátula."
	s8.progress_text = "Coloque a carne na chapa, vire com a Espátula [1] e retire-a na espátula."
	s8.highlight_name = "Grill"
	s8.success_msg = "Carne assada no ponto perfeito recolhida na espátula!"
	steps.append(s8)
	
	# ETAPA 10 — MONTAGEM DO HAMBÚRGUER NA BANCADA
	var s9 = TutorialStep.new()
	s9.title = "10. MONTAGEM DO HAMBÚRGUER"
	s9.instruction = "Na bancada de montagem, coloque a Base do Pão, adicione o hambúrguer grelhado que está na sua espátula e finalize colocando a Parte Superior do Pão para fechar o lanche."
	s9.progress_text = "Monte o lanche: Base do Pão + Carne da Espátula + Parte Superior do Pão."
	s9.highlight_name = "PrepIsland"
	s9.success_msg = "Perfeito! Seu primeiro hambúrguer está montado."
	steps.append(s9)
	
	# ETAPA 11 — ESTAÇÃO DE EMBALAGEM
	var s10 = TutorialStep.new()
	s10.title = "11. ESTAÇÃO DE EMBALAGEM"
	s10.instruction = "1. Leve o hambúrguer montado até a Mesa de Embalagens.\n2. Pegue uma Caixa de Hambúrguer na bancada com [Clique Esquerdo] e embale o lanche.\n\n⚠️ DIFERENCIAÇÃO DE PEDIDOS:\n• Cliente no Salão: Use a Caixa de Hambúrguer e acomode na Bandeja de Serviço.\n• Delivery / Drive-thru (Etapa Adicional): Coloque a Caixa de Hambúrguer dentro do Saco de Delivery de papel kraft na bancada."
	s10.progress_text = "Pegue uma caixa de hambúrguer na mesa de embalagens e embale o lanche."
	s10.highlight_name = "PackagingStation"
	s10.success_msg = "Lanche embalado e protegido com sucesso!"
	steps.append(s10)
	
	# ETAPA 12 — BANDEJA DE SERVIÇO
	var s11 = TutorialStep.new()
	s11.title = "12. ATENDIMENTO NO SALÃO E BANDEJA DE SERVIÇO"
	s11.instruction = "Fluxo de atendimento para clientes que comem no restaurante:\n1. Aproxime-se do balcão de atendimento e pegue uma Bandeja de Serviço na pilha com [E] ou [Clique Esquerdo].\n2. Coloque a caixa do hambúrguer sobre a bandeja com [Clique Esquerdo].\n3. Adicione os outros itens do pedido (bebida/fritas) na mesma bandeja.\n4. Leve a bandeja completa até a mesa do cliente sentado no salão.\n5. Entregue o pedido interagindo com o cliente."
	s11.progress_text = "Pegue uma bandeja no balcão [E / Clique Esq] e coloque o lanche embalado nela."
	s11.highlight_name = "ServingTrayStack"
	s11.success_msg = "Pedido acomodado na bandeja de serviço com sucesso!"
	steps.append(s11)
	
	# ETAPA 13 — LIMPEZA DA GRELHA E HIGIENIZAÇÃO DA BUCHA
	var s12 = TutorialStep.new()
	s12.title = "13. LIMPEZA E HIGIENE DA COZINHA"
	s12.instruction = "A higiene da cozinha é fundamental. Equipe a Bucha de Limpeza com a [Tecla 2], mire na grelha e segure o [Clique Esquerdo] até limpá-la. Quando a bucha ficar suja, vá até a pia industrial e segure o [Clique Esquerdo] para lavá-la."
	s12.progress_text = "Limpe a grelha com a bucha [2] e lave a bucha na pia industrial."
	s12.highlight_name = "Grill"
	s12.success_msg = "Grelha limpa e bucha higienizada na pia!"
	steps.append(s12)
	
	# ETAPA 14 — RECEBIMENTO E CAIXA REGISTRADORA
	var s13 = TutorialStep.new()
	s13.title = "14. RECEBIMENTO E CAIXA REGISTRADORA"
	s13.instruction = "Os clientes deixam o dinheiro do pagamento no balcão de atendimento. Aproxime-se do balcão, pegue as notas com [E] ou [Clique Esquerdo], mire na Caixa Registradora e pressione [E] para abrir a gaveta e registrar o faturamento."
	s13.progress_text = "Pegue o dinheiro no balcão e guarde na Caixa Registradora [E]."
	s13.highlight_name = "CustomerMoney"
	s13.success_msg = "💵 Pagamento guardado na caixa registradora! Faturamento contabilizado com sucesso."
	steps.append(s13)
	
	# ETAPA 15 — EXPEDIENTE E PLACA DE ABERTURA
	var s14 = TutorialStep.new()
	s14.title = "15. EXPEDIENTE E PLACA DE ABERTURA"
	s14.instruction = "O expediente oficial começa às 09:00 no Período de Preparação. O restaurante abre às 10:00 e encerra às 22:00. Pressione [E] na Placa de Abertura na entrada para conhecer as regras de abertura."
	s14.progress_text = "Interaja com a Placa de Abertura [E]."
	s14.highlight_name = "OpenSign"
	s14.success_msg = "Rotina e horários de funcionamento compreendidos!"
	steps.append(s14)

func _connect_ui_signals() -> void:
	if start_day_button and not start_day_button.pressed.is_connected(_on_start_day_pressed):
		start_day_button.pressed.connect(_on_start_day_pressed)

func _process(delta: float) -> void:
	if tutorial_completed or current_step_index >= steps.size():
		return
	
	# Animação suave do destaque 3D (pulso vertical suave)
	if current_highlight_marker and is_instance_valid(current_highlight_marker):
		var time_ms = Time.get_ticks_msec()
		var offset_y = sin(time_ms * 0.0035) * 0.08
		current_highlight_marker.position.y = offset_y
		if current_highlight_light and is_instance_valid(current_highlight_light):
			current_highlight_light.light_energy = 1.0 + sin(time_ms * 0.004) * 0.25
	
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
	
	# Pausa suave de ~1.0s para leitura e observação do novo objetivo
	transition_timer = 1.0
	
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
				if gr.has_method("set_dirty"):
					gr.set_dirty(true)
				else:
					gr.add_dirt(1.0)
				_create_highlight(gr, "Grelha (Esfregar com Bucha [2])")
			var player = _get_player()
			if player:
				player.select_tool_slot(Player.ToolSlot.SPONGE, false)
		13: # Pagamento
			var cr = _get_cash_register()
			var money_scene = load("res://src/items/customer_money.tscn")
			if cr and money_scene:
				var old_money = get_tree().root.find_children("", "CustomerMoney", true, false)
				for m in old_money:
					if is_instance_valid(m) and m.get_parent():
						m.get_parent().remove_child(m)
						m.queue_free()
				
				var money = money_scene.instantiate() as CustomerMoney
				var main_scene = get_tree().current_scene if get_tree().current_scene else get_tree().root
				main_scene.add_child(money)
				money.global_position = cr.global_position + Vector3(-0.45, 0.05, 0.25)
				money.setup(35.0, null)
				_create_highlight(money, "Dinheiro do Cliente [E / Clique Esq]")
		14: # Placa de Abertura / Abertura Real do Restaurante
			var clock = _get_game_clock()
			if clock:
				clock.state = GameClock.State.PREPARATION
			var op = _get_open_sign()
			if op:
				if op.has_method("_update_sign"):
					op._update_sign()
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
			elif player:
				if player.held_item is Burger or player.held_item is Cheeseburger:
					step_ok = true
				elif player.held_item is BreadBottom:
					var bb = player.held_item as BreadBottom
					if bb.assembly != null and (bb.assembly.state == BurgerAssembly.State.CLOSED or bb.assembly.state == BurgerAssembly.State.PACKAGED):
						step_ok = true
				elif player.has_active_ingredient() and str(player.get_active_ingredient().get("item_id")).begins_with("burger"):
					step_ok = true
				else:
					# Verifica se há algum lanche fechado na bancada ou no chão
					var bottoms = get_tree().root.find_children("", "BreadBottom", true, false)
					for child in bottoms:
						if is_instance_valid(child) and child is BreadBottom:
							if child.assembly != null and (child.assembly.state == BurgerAssembly.State.CLOSED or child.assembly.state == BurgerAssembly.State.PACKAGED):
								step_ok = true
								break
					if not step_ok:
						var assemblies = get_tree().root.find_children("", "BurgerAssembly", true, false)
						for ass in assemblies:
							if is_instance_valid(ass) and (ass.state == BurgerAssembly.State.CLOSED or ass.state == BurgerAssembly.State.PACKAGED):
								step_ok = true
								break
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
			var sponge_clean = (player == null or not player.sponge_is_dirty)
			if gr and not gr.is_dirty():
				step_grill_was_cleaned = true
			if step_grill_was_cleaned and player and player.sponge_is_dirty and sink:
				_create_highlight(sink, "Lave a Bucha na Pia [Clique Esquerdo]")
			elif gr and gr.is_dirty():
				_create_highlight(gr, "Grelha (Esfregar com Bucha [2])")
			if gr and not gr.is_dirty() and sponge_clean:
				step_ok = true
		13: # Pagamento: dinheiro no caixa
			if step_payment_processed or step_money_collected:
				step_ok = true
			var player_has_money = (player and player.held_item != null and (player.held_item.get("is_customer_deposit_money") == true or str(player.held_item.get("item_id")) == "customer_money"))
			if player_has_money:
				var cr = _get_cash_register()
				if cr:
					_create_highlight(cr, "Deposite o Dinheiro na Caixa Registradora [E]")
			else:
				var money_in_world = get_tree().root.find_children("", "CustomerMoney", true, false)
				var has_world_money = false
				for m in money_in_world:
					if is_instance_valid(m) and m.location == Item.ItemLocation.WORLD and not m.is_held:
						has_world_money = true
						break
				if not has_world_money and not player_has_money and step_initialized:
					step_ok = true
		14: # Placa de Abertura / Abrir Restaurante
			var clock = _get_game_clock()
			if (clock and (clock.state == GameClock.State.OPEN or clock.is_restaurant_open())) or step_open_sign_interacted:
				step_ok = true
	
	if step_ok:
		_advance_step()

func _on_clock_state_changed(new_state: GameClock.State) -> void:
	if current_step_index == 14 and (new_state == GameClock.State.OPEN or new_state == GameClock.State.CLOSING):
		step_open_sign_interacted = true
		if not tutorial_completed:
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
		congrats_title.text = "🎓 TREINAMENTO CONCLUÍDO!"
	if congrats_text:
		congrats_text.text = "Treinamento finalizado com sucesso! Agora o restaurante é todo seu e o jogo real vai começar."
	if start_day_button:
		start_day_button.text = "COMEÇAR DIA 1"
	if step_title:
		step_title.text = "🎉 TREINAMENTO CONCLUÍDO COM SUCESSO!"
	if step_instruction:
		step_instruction.text = "Você concluiu todas as etapas e dominou os sistemas reais do Burger Rush.\nClique abaixo para iniciar seu expediente no Dia 1!"
	if step_progress:
		step_progress.text = "Etapa 15 / 15 (100% Concluído)"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_confirm_skip_pressed() -> void:
	current_step_index = steps.size()
	tutorial_completed = true
	_save_tutorial_progress()
	_on_start_day_pressed()

func _on_start_day_pressed() -> void:
	tutorial_completed = true
	
	var sm = _get_save_manager()
	if sm and sm.has_active_game:
		sm.pending_save_data["tutorial_step"] = steps.size()
		sm.pending_save_data["tutorial_completed"] = true
		sm.pending_save_data["day1_intro_shown"] = false
		sm.pending_save_data["day_number"] = 1
		sm.pending_save_data["current_day"] = 1
		sm.pending_save_data["day_of_week"] = 4
		sm.pending_save_data["week_number"] = 1
		sm.pending_save_data["clock_hour"] = 9
		sm.pending_save_data["clock_minute"] = 0
		sm.pending_save_data["clock_state"] = "PREPARATION"
		sm.save_game(sm.active_slot)
	
	var gm = get_tree().root.find_child("GameManager", true, false) if (is_inside_tree() and get_tree()) else null
	if not gm:
		var gm_class = load("res://src/core/game_manager.gd")
		if gm_class and gm_class.has_method("get_instance"):
			gm = gm_class.get_instance()
	
	if gm and gm.has_method("load_scene_with_loading"):
		gm.load_scene_with_loading("main", gm.GameState.PLAYING)
	else:
		get_tree().change_scene_to_file("res://src/ui/loading_screen.tscn")

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
	if not target or not is_instance_valid(target):
		_clear_highlight()
		return
	
	# Se o destaque já está apontando para este alvo com o mesmo texto, não recria para evitar piscar
	if current_highlight_target == target and current_highlight_label_text == label_text and current_highlight_marker and is_instance_valid(current_highlight_marker):
		return
	
	_clear_highlight()
	current_highlight_target = target
	current_highlight_label_text = label_text
	
	# Limpa quaisquer nós de highlight órfãos no alvo
	for child in target.get_children():
		if is_instance_valid(child) and child.name == "TutorialHighlight":
			child.queue_free()
	
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
	current_highlight_target = null
	current_highlight_label_text = ""

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
		var sm_class = load("res://src/core/save_manager.gd")
		if sm_class and sm_class.has_method("get_instance"):
			return sm_class.get_instance()
		return null
	var sm = get_tree().root.find_child("SaveManager", true, false)
	if not sm:
		var sm_script = load("res://src/core/save_manager.gd")
		if sm_script and "instance" in sm_script and sm_script.instance:
			sm = sm_script.instance
		elif sm_script and sm_script.has_method("get_instance"):
			sm = sm_script.get_instance()
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
