extends Control

# =============================================================================
# BURGER RUSH — HISTÓRIA DE INTRODUÇÃO E CRIAÇÃO DO CHEFE (FASE 5)
#
# Apresenta a narrativa oficial de passagem de bastão do pai ao jogador em 2026,
# seguida pelo input de nome do chefe e criação da nova carreira.
# =============================================================================

signal story_completed(chef_name: String)

@onready var background_rect: ColorRect = $Background
@onready var story_panel: PanelContainer = $ContentBox/StoryPanel
@onready var step_label: Label = $ContentBox/StoryPanel/Margin/VBox/HeaderBox/StepLabel
@onready var title_label: Label = $ContentBox/StoryPanel/Margin/VBox/TitleLabel
@onready var body_label: Label = $ContentBox/StoryPanel/Margin/VBox/BodyLabel
@onready var skip_button: Button = $ContentBox/StoryPanel/Margin/VBox/FooterBox/SkipButton
@onready var next_button: Button = $ContentBox/StoryPanel/Margin/VBox/FooterBox/NextButton

@onready var name_modal: PanelContainer = $ContentBox/NameModal
@onready var name_input: LineEdit = $ContentBox/NameModal/Margin/VBox/NameInput
@onready var confirm_button: Button = $ContentBox/NameModal/Margin/VBox/ConfirmButton
@onready var error_label: Label = $ContentBox/NameModal/Margin/VBox/ErrorLabel

var current_panel_index: int = 0
var target_slot: int = 1

const PANELS: Array[Dictionary] = [
	{
		"step": "1 / 5",
		"title": "2026 — O Início de uma Nova Era",
		"body": "Depois de anos trabalhando na cozinha e aprendendo os segredos do ofício, chegou o momento decisivo da sua trajetória profissional."
	},
	{
		"step": "2 / 5",
		"title": "O Legado da Família",
		"body": "Seu pai dedicou décadas da sua vida como um chef respeitado na cidade. Ele construiu seu nome com muita disciplina, paixão e transmitiu a você tudo o que sabia."
	},
	{
		"step": "3 / 5",
		"title": "A Passagem do Bastão",
		"body": "Agora, ao se aposentar, ele decidiu entregar em suas mãos a oportunidade mais valiosa da sua vida: o restaurante BurgerRush é oficialmente seu."
	},
	{
		"step": "4 / 5",
		"title": "Da Chapa à Gestão",
		"body": "Você domina os hambúrgueres e o ritmo da chapa. Mas a partir de hoje, você também comandará as finanças, o estoque e as decisões do negócio através do computador do restaurante."
	},
	{
		"step": "5 / 5",
		"title": "Seu Primeiro Dia Começa Agora",
		"body": "Ingredientes frescos, clientes famintos, contas a pagar e uma reputação a conquistar. O futuro do BurgerRush está sob o seu comando."
	}
]

func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title("Burger Rush")
		if is_inside_tree() and get_tree() and get_tree().root:
			get_tree().root.title = "Burger Rush"

	var gm = _get_game_manager()
	if gm and gm.has_method("change_state"):
		gm.change_state(gm.GameState.STORY)

	var sm = _get_save_manager()
	if sm and target_slot <= 1 and sm.get_active_slot() > 1:
		target_slot = sm.get_active_slot()

	story_panel.visible = true
	name_modal.visible = false
	error_label.text = ""

	_show_panel(0)

	skip_button.pressed.connect(_on_skip_pressed)
	next_button.pressed.connect(_on_next_pressed)
	confirm_button.pressed.connect(_on_confirm_name_pressed)
	name_input.text_submitted.connect(func(_text): _on_confirm_name_pressed())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # ESC
		if story_panel.visible:
			_open_name_modal()
	elif event.is_action_pressed("ui_accept"): # ENTER / ESPAÇO
		if story_panel.visible:
			_on_next_pressed()

func _show_panel(index: int) -> void:
	if index < 0 or index >= PANELS.size():
		_open_name_modal()
		return

	current_panel_index = index
	var p = PANELS[index]
	step_label.text = p["step"]
	title_label.text = p["title"]
	body_label.text = p["body"]

	if index == PANELS.size() - 1:
		next_button.text = "CRIAR MEU CHEFE →"
	else:
		next_button.text = "AVANÇAR [ ENTER ] →"

	# Animação sutil de fade
	body_label.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(body_label, "modulate:a", 1.0, 0.25)

func _on_next_pressed() -> void:
	if current_panel_index < PANELS.size() - 1:
		_show_panel(current_panel_index + 1)
	else:
		_open_name_modal()

func _on_skip_pressed() -> void:
	_open_name_modal()

func _open_name_modal() -> void:
	story_panel.visible = false
	name_modal.visible = true
	error_label.text = ""
	if is_inside_tree() and name_input.is_inside_tree():
		name_input.grab_focus()

func _on_confirm_name_pressed() -> void:
	if not name_input:
		name_input = get_node_or_null("ContentBox/NameModal/Margin/VBox/NameInput")
	if not confirm_button:
		confirm_button = get_node_or_null("ContentBox/NameModal/Margin/VBox/ConfirmButton")
	if not error_label:
		error_label = get_node_or_null("ContentBox/NameModal/Margin/VBox/ErrorLabel")

	var chef_name = name_input.text.strip_edges() if name_input else ""

	if chef_name.is_empty():
		error_label.text = "Por favor, digite um nome válido para o chefe."
		return

	if chef_name.length() > 24:
		error_label.text = "O nome deve ter no máximo 24 caracteres."
		return

	confirm_button.disabled = true
	name_input.editable = false

	# 1. Cria a carreira e persiste no SaveManager no slot escolhido
	var sm = _get_save_manager()
	if sm and sm.has_method("create_new_career"):
		sm.create_new_career(target_slot, chef_name)

	story_completed.emit(chef_name)

	# 2. Transita via GameManager para a preparação do tutorial / jogo
	var gm = _get_game_manager()
	if gm and gm.has_method("finish_new_game_creation"):
		gm.finish_new_game_creation(target_slot)
	elif gm and gm.has_method("load_scene_with_loading"):
		gm.load_scene_with_loading("main", gm.GameState.TUTORIAL)
	else:
		get_tree().change_scene_to_file("res://src/main.tscn")

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
	return null

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
	return null
