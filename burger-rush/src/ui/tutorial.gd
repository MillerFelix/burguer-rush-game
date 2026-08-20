class_name TutorialController
extends CanvasLayer

# =============================================================================
# BURGER RUSH — CONTROLADOR E GERENCIADOR DO TUTORIAL INICIAL (FASE 6)
#
# Coordena as etapas do tutorial, destacando objetos e validando interações
# reais através dos sistemas originais do jogo.
# =============================================================================

const PowerManager = preload("res://src/core/power_manager.gd")
const GameClock = preload("res://src/time/game_clock.gd")
const Refrigerator = preload("res://src/stations/commercial_refrigerator.gd")
const Grill = preload("res://src/stations/grill.gd")
const PrepIsland = preload("res://src/stations/prep_island.gd")
const PackagedBurger = preload("res://src/items/packaged_burger.gd")
const ServingTray = preload("res://src/items/serving_tray.gd")
const Patty = preload("res://src/items/patty.gd")
const BreadBottom = preload("res://src/items/bread_bottom.gd")
const BurgerAssembly = preload("res://src/recipes/burger_assembly.gd")

@onready var step_title: Label = $Control/StepPanel/Margin/VBox/StepTitle
@onready var step_instruction: Label = $Control/StepPanel/Margin/VBox/StepInstruction
@onready var step_progress: Label = $Control/StepPanel/Margin/VBox/StepProgress
@onready var skip_button: Button = $Control/SkipButton
@onready var confirm_dialog: PanelContainer = $Control/ConfirmDialog
@onready var cancel_skip_button: Button = $Control/ConfirmDialog/Margin/VBox/Buttons/CancelSkipButton
@onready var confirm_skip_button: Button = $Control/ConfirmDialog/Margin/VBox/Buttons/ConfirmSkipButton
@onready var congrats_panel: PanelContainer = $Control/CongratsPanel
@onready var start_day_button: Button = $Control/CongratsPanel/Margin/VBox/StartDayButton

var current_step_index: int = 0
var tutorial_completed: bool = false

# Destaques visuais
var current_highlight_marker: Label3D = null
var current_highlight_light: OmniLight3D = null

# Estado auxiliar de etapa
var step_initialized: bool = false
var step_start_pos: Vector3 = Vector3.ZERO
var check_timer: float = 0.0

# Definição das etapas
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
	
	# Restaura progresso salvo se aplicável
	var sm = _get_save_manager()
	if sm and not sm.pending_save_data.is_empty():
		var saved_step = sm.pending_save_data.get("tutorial_step", 0)
		if saved_step >= 0 and saved_step < steps.size():
			current_step_index = saved_step

	# Garante que a energia do restaurante esteja ligada para o tutorial
	var pm = PowerManager.get_instance()
	if pm:
		pm.set_main_power(true)

	# Pausa o relógio do jogo durante o tutorial
	var clock = GameClock.get_instance()
	if clock:
		clock.is_paused = true

	confirm_dialog.visible = false
	congrats_panel.visible = false
	
	_show_step(current_step_index)

func _initialize_steps() -> void:
	steps.clear()
	
	var s0 = TutorialStep.new()
	s0.title = "1. Movimentação Básica"
	s0.instruction = "Bem-vindo ao seu restaurante!\nUse as teclas W, A, S, D para se movimentar e explore a cozinha."
	s0.progress_text = "Duração: Caminhe 3 metros"
	s0.highlight_name = ""
	s0.success_msg = "Muito bem!"
	steps.append(s0)

	var s1 = TutorialStep.new()
	s1.title = "2. Computador Administrativo"
	s1.instruction = "Vá até o Computador do Escritório e acesse-o pressionando [E] para visualizar o estoque de insumos."
	s1.progress_text = "Objetivo: Acessar o PC"
	s1.highlight_name = "ComputerStation"
	s1.success_msg = "Excelente. Esse computador controla toda a gestão."
	steps.append(s1)

	var s2 = TutorialStep.new()
	s2.title = "3. Pegando Ingredientes"
	s2.instruction = "Vá até a Geladeira, abra-a clicando com o botão esquerdo e pegue 1x Carne Bovina Crua.\n(Equipe as Mãos Livres pressionando a tecla 3)."
	s2.progress_text = "Objetivo: Segurar Carne Bovina Crua"
	s2.highlight_name = "MeatRefrigerator"
	s2.success_msg = "Perfeito. Você pegou a carne."
	steps.append(s2)

	var s3 = TutorialStep.new()
	s3.title = "4. Colocando na Chapa"
	s3.instruction = "Leve a carne bovina crua até a chapa da grelha e coloque-a usando o Clique Esquerdo do mouse.\n(Se a chapa estiver desligada, ligue-a pressionando [E] nela)."
	s3.progress_text = "Objetivo: Colocar a carne na chapa"
	s3.highlight_name = "Grill"
	s3.success_msg = "Isso aí. O hambúrguer começou a grelhar."
	steps.append(s3)

	var s4 = TutorialStep.new()
	s4.title = "5. Virando a Carne"
	s4.instruction = "Aguarde a carne grelhar o primeiro lado (o prompt indicará 'VIRAR'). Equipe a Espátula [Tecla 1] e clique na carne para virá-la."
	s4.progress_text = "Objetivo: Virar a carne com a Espátula"
	s4.highlight_name = "Grill"
	s4.success_msg = "Boa! Agora o outro lado está grelhando."
	steps.append(s4)

	var s5 = TutorialStep.new()
	s5.title = "6. Retirando o Hambúrguer"
	s5.instruction = "Aguarde a carne grelhar o segundo lado até ficar no ponto (Pronta). Com a Espátula [1] equipada, clique na carne para retirá-la."
	s5.progress_text = "Objetivo: Retirar a carne pronta da grelha"
	s5.highlight_name = "Grill"
	s5.success_msg = "Perfeito, carne grelhada com sucesso."
	steps.append(s5)

	var s6 = TutorialStep.new()
	s6.title = "7. Iniciando a Montagem"
	s6.instruction = "Vá até a Bancada de Preparo (ilha central) e coloque a Base do Pão (Bread Bottom) nela com o Clique Esquerdo.\n(Use Mãos Livres [3])."
	s6.progress_text = "Objetivo: Colocar Base do Pão na bancada"
	s6.highlight_name = "PrepIsland"
	s6.success_msg = "Show. O lanche começou a ser montado."
	steps.append(s6)

	var s7 = TutorialStep.new()
	s7.title = "8. Adicionando a Carne"
	s7.instruction = "Com a Espátula segurando o hambúrguer (ou carne nos slots [4, 5, 6]), clique na Base do Pão na bancada para adicioná-la."
	s7.progress_text = "Objetivo: Adicionar carne bovina ao pão"
	s7.highlight_name = "PrepIsland"
	s7.success_msg = "Ótimo. Carne adicionada."
	steps.append(s7)

	var s8 = TutorialStep.new()
	s8.title = "9. Fechando o Lanche"
	s8.instruction = "Pegue a parte superior do pão (Bread Top) no armário de ingredientes e clique no hambúrguer na bancada para fechá-lo."
	s8.progress_text = "Objetivo: Adicionar a tampa do pão"
	s8.highlight_name = "PrepIsland"
	s8.success_msg = "Hambúrguer finalizado e pronto para embalar!"
	steps.append(s8)

	var s9 = TutorialStep.new()
	s9.title = "10. Embalando o Pedido"
	s9.instruction = "Pegue uma Caixa de Hambúrguer na bancada de embalagens e, com ela na mão, clique no lanche pronto para embalá-lo."
	s9.progress_text = "Objetivo: Embalar o lanche na caixa"
	s9.highlight_name = "PackagingStation"
	s9.success_msg = "Excelente. Lanche embalado na caixa."
	steps.append(s9)

	var s10 = TutorialStep.new()
	s10.title = "11. Preparando a Bandeja"
	s10.instruction = "Pegue uma Bandeja no stack pressionando [E]. Segurando o lanche embalado, clique com o botão DIREITO do mouse na bandeja para colocá-lo."
	s10.progress_text = "Objetivo: Colocar o lanche embalado na bandeja"
	s10.highlight_name = "ServingTrayStack"
	s10.success_msg = "Perfeito, o pedido está montado na bandeja!"
	steps.append(s10)

	var s11 = TutorialStep.new()
	s11.title = "12. Limpeza da Chapa"
	s11.instruction = "A chapa da grelha acumulou resíduos de óleo. Equipe a Bucha [Tecla 2], mire na grelha e segure o Clique Esquerdo do mouse para limpá-la."
	s11.progress_text = "Objetivo: Limpar a sujeira da chapa"
	s11.highlight_name = "Grill"
	s11.success_msg = "Espetacular! Restaurante limpo e organizado."
	steps.append(s11)

	var s12 = TutorialStep.new()
	s12.title = "13. Tudo Pronto!"
	s12.instruction = "O atendimento no BurgerRush envolve receber pedidos, preparar na grelha/fritadeira, montar na bandeja e receber o dinheiro de volta no caixa.\nAgora a gestão do restaurante é sua!"
	s12.progress_text = "Conclusão do Tutorial"
	s12.highlight_name = ""
	s12.success_msg = ""
	steps.append(s12)

func _connect_ui_signals() -> void:
	skip_button.pressed.connect(_on_skip_pressed)
	cancel_skip_button.pressed.connect(_on_cancel_skip_pressed)
	confirm_skip_button.pressed.connect(_on_confirm_skip_pressed)
	start_day_button.pressed.connect(_on_start_day_pressed)

func _show_step(step_idx: int) -> void:
	if step_idx < 0 or step_idx >= steps.size():
		return
	
	current_step_index = step_idx
	step_initialized = false
	var step = steps[step_idx]
	
	# Aplica textos
	step_title.text = step.title
	step_instruction.text = step.instruction
	step_progress.text = step.progress_text
	
	# Aplica destaque visual no objeto do mundo correspondente
	_clear_highlight()
	if step.highlight_name != "":
		var target = _find_node_by_class(step.highlight_name)
		if target:
			_update_highlight(target, step.title.split(". ")[1])
			
	# Transição visual suave (Tween)
	$Control/StepPanel.scale = Vector2(0.95, 0.95)
	var tw = create_tween()
	tw.tween_property($Control/StepPanel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Salva o progresso parcial no slot de save atual
	_save_tutorial_step(step_idx)

func _process(delta: float) -> void:
	if tutorial_completed:
		return
		
	check_timer += delta
	if check_timer >= 0.15:
		check_timer = 0.0
		_check_step_conditions()

func _check_step_conditions() -> void:
	var gm = _get_game_manager()
	var player = gm.get_player() as Player if gm else null
	if not player:
		return

	match current_step_index:
		0: # Movimentação
			if not step_initialized:
				step_start_pos = player.global_position
				step_initialized = true
			else:
				var dist = player.global_position.distance_to(step_start_pos)
				step_progress.text = "Caminhado: %.1fm / 3.0m" % dist
				if dist >= 3.0:
					_advance_step()
					
		1: # PC
			var pc = _find_node_by_class("ComputerStation") as ComputerStation
			if pc and pc.computer_ui_instance and pc.computer_ui_instance.visible:
				_advance_step()
				
		2: # Pegar Carne
			if player.has_method("has_matching_ingredient") and player.has_matching_ingredient("patty_beef"):
				_advance_step()
				
		3: # Colocar na chapa
			var grill = _find_node_by_class("Grill") as Grill
			if grill and not grill.active_items.is_empty():
				for item in grill.active_items:
					if item["type"] == "patty":
						var patty = item["item"] as Patty
						if patty and (patty.state == Patty.State.RAW or patty.state == Patty.State.COOKING_SIDE_1):
							_advance_step()
							break
							
		4: # Virar carne
			var grill = _find_node_by_class("Grill") as Grill
			if grill and not grill.active_items.is_empty():
				for item in grill.active_items:
					if item["type"] == "patty":
						var patty = item["item"] as Patty
						if patty and patty.is_flipped:
							_advance_step()
							break
							
		5: # Retirar carne
			# Verifica se o jogador retirou a carne com a espátula ou está segurando
			var holding_cooked_patty = false
			if player.has_method("get_spatula_held_patty") and player.get_spatula_held_patty() != null:
				holding_cooked_patty = true
			if not holding_cooked_patty and player.held_item and player.held_item is Patty:
				var patty = player.held_item as Patty
				if patty.is_fully_cooked():
					holding_cooked_patty = true
			if not holding_cooked_patty:
				for slot in player.quick_slots:
					if not slot.is_empty() and slot.get("item_id") == "patty_beef":
						var data = slot.get("data", {})
						if data.get("side_a_cooked", 0.0) >= 100.0 and data.get("side_b_cooked", 0.0) >= 100.0:
							holding_cooked_patty = true
							break
			if holding_cooked_patty:
				_advance_step()
				
		6: # Colocar pão inferior na bancada
			var island = _find_node_by_class("PrepIsland") as PrepIsland
			if island:
				for item in island.placed_items:
					if is_instance_valid(item) and item is BreadBottom:
						_advance_step()
						break
						
		7: # Adicionar carne bovina ao pão
			var island = _find_node_by_class("PrepIsland") as PrepIsland
			if island:
				for item in island.placed_items:
					if is_instance_valid(item) and item is BreadBottom:
						if item.has_ingredients():
							_advance_step()
							break
							
		8: # Fechar lanche (Bread Top)
			var island = _find_node_by_class("PrepIsland") as PrepIsland
			if island:
				for item in island.placed_items:
					if is_instance_valid(item) and item is BreadBottom:
						if item.assembly and item.assembly.state == BurgerAssembly.State.CLOSED:
							_advance_step()
							break
							
		9: # Embalar lanche
			var has_package = false
			if player.held_item and player.held_item is PackagedBurger:
				has_package = true
			else:
				var island = _find_node_by_class("PrepIsland") as PrepIsland
				if island:
					for item in island.placed_items:
						if is_instance_valid(item) and item is PackagedBurger:
							has_package = true
							break
			if has_package:
				_advance_step()
				
		10: # Colocar na bandeja
			if player.held_item and player.held_item is ServingTray:
				var tray = player.held_item as ServingTray
				if not tray.carried_items.is_empty():
					for item in tray.carried_items:
						if item is PackagedBurger:
							_advance_step()
							break
							
		11: # Limpar a chapa
			var grill = _find_node_by_class("Grill") as Grill
			if grill:
				step_progress.text = "Sujeira restante: %d%%" % int(grill.dirt_level * 100.0)
				if grill.dirt_level <= 0.001:
					_advance_step()
					
		12: # Etapa de conclusão
			_clear_highlight()
			$Control/StepPanel.visible = false
			skip_button.visible = false
			congrats_panel.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _advance_step() -> void:
	if current_step_index < steps.size() - 1:
		# Exibe feedback temporário na tela
		var step = steps[current_step_index]
		if step.success_msg != "" and player_has_hud():
			var gm = _get_game_manager()
			var player = gm.get_player() if gm else null
			if player:
				player.get_node("HUD").show_temporary_feedback("✅ " + step.success_msg)
		
		_show_step(current_step_index + 1)
	else:
		_clear_highlight()
		$Control/StepPanel.visible = false
		skip_button.visible = false
		congrats_panel.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# =============================================================================
# DESTAQUES VISUAIS DOS ALVOS
# =============================================================================

func _clear_highlight() -> void:
	if is_instance_valid(current_highlight_marker):
		current_highlight_marker.queue_free()
	current_highlight_marker = null
	if is_instance_valid(current_highlight_light):
		current_highlight_light.queue_free()
	current_highlight_light = null

func _update_highlight(target: Node3D, label_text: String) -> void:
	_clear_highlight()
	if not is_instance_valid(target):
		return
	
	# Cria Label3D
	var label = Label3D.new()
	label.text = "🎯 " + label_text
	label.font_size = 32
	label.outline_size = 6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.85, 0.2, 1.0)
	label.outline_modulate = Color(0.08, 0.1, 0.14, 0.95)
	
	var offset_y = 1.3
	if target.name.contains("Refrigerator") or target is Refrigerator:
		offset_y = 1.8
	elif target.name.contains("Grill") or target is Grill:
		offset_y = 1.2
	
	label.position = Vector3(0.0, offset_y, 0.0)
	target.add_child(label)
	current_highlight_marker = label
	
	# Cria OmniLight3D
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.9, 0.4)
	light.light_energy = 1.5
	light.omni_range = 3.0
	light.position = Vector3(0.0, offset_y - 0.2, 0.0)
	target.add_child(light)
	current_highlight_light = light

# =============================================================================
# PULAR TUTORIAL (SKIP FLOW)
# =============================================================================

func _on_skip_pressed() -> void:
	# Exibe diálogo de confirmação
	confirm_dialog.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var tree = _get_tree_safe()
	if tree:
		tree.paused = true

func _on_cancel_skip_pressed() -> void:
	confirm_dialog.visible = false
	var tree = _get_tree_safe()
	if tree:
		tree.paused = false
	
	# Restaura modo de mouse se necessário
	var pc = _find_node_by_class("ComputerStation") as ComputerStation
	var pc_open = pc and pc.computer_ui_instance and pc.computer_ui_instance.visible
	if not pc_open and not congrats_panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_confirm_skip_pressed() -> void:
	confirm_dialog.visible = false
	var tree = _get_tree_safe()
	if tree:
		tree.paused = false
	_complete_tutorial(true)

func _on_start_day_pressed() -> void:
	_complete_tutorial(false)

func _complete_tutorial(_skipped: bool = false) -> void:
	tutorial_completed = true
	_clear_highlight()
	
	# Salva tutorial como completo no save e limpa steps
	var sm = _get_save_manager()
	if sm:
		sm.pending_save_data["tutorial_completed"] = true
		sm.pending_save_data["tutorial_step"] = 0
		var slot_to_save = sm.active_slot if sm.active_slot > 0 else 1
		sm.save_game(slot_to_save)
	
	# Despausa o clock e restaura tempo
	var clock = GameClock.get_instance()
	if clock:
		clock.is_paused = false
		# Força o clock a ir para PREPARATION do dia 1 às 08:00
		clock.current_hour = 8
		clock.current_minute = 0
		clock.set_state(GameClock.State.PREPARATION)
		clock.time_tick.emit(8, 0)
	
	# Transita para gameplay oficial no GameManager
	var gm = _get_game_manager()
	if gm:
		gm.change_state(gm.GameState.PLAYING)
	
	# Captura o mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Remove a si mesmo da árvore de nós
	queue_free()

# =============================================================================
# PERSISTÊNCIA PARCIAL
# =============================================================================

func _save_tutorial_step(step_idx: int) -> void:
	var sm = _get_save_manager()
	if sm and sm.has_active_game:
		sm.pending_save_data["tutorial_step"] = step_idx
		sm.pending_save_data["tutorial_completed"] = false
		sm.save_game(sm.active_slot)

# =============================================================================
# HELPERS DE RESOLUÇÃO DE NÓS
# =============================================================================

func _find_node_by_class(class_name_str: String) -> Node3D:
	var tree = _get_tree_safe()
	var root = tree.current_scene if tree else null
	if not root:
		return null
	for child in root.find_children("*", "Node3D", true, false):
		if child.get_class() == class_name_str or (child.get_script() and child.get_script().resource_path.get_file().get_basename() == class_name_str.to_snake_case()):
			return child as Node3D
		if child.get_script() and child.get_script().get_global_name() == class_name_str:
			return child as Node3D
	
	var by_name = root.find_child(class_name_str, true, false)
	if by_name and by_name is Node3D:
		return by_name
	return null

func player_has_hud() -> bool:
	var gm = _get_game_manager()
	var player = gm.get_player() if gm else null
	return player != null and player.has_node("HUD")

func _get_game_manager() -> Node:
	var gm_script = load("res://src/core/game_manager.gd")
	if gm_script and "instance" in gm_script and gm_script.instance and is_instance_valid(gm_script.instance):
		return gm_script.instance
	return null

func _get_save_manager() -> Node:
	var sm_script = load("res://src/core/save_manager.gd")
	if sm_script and "instance" in sm_script and sm_script.instance and is_instance_valid(sm_script.instance):
		return sm_script.instance
	return null

func _get_tree_safe() -> SceneTree:
	return Engine.get_main_loop() as SceneTree
