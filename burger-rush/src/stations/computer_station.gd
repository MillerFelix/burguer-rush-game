class_name ComputerStation
extends StaticBody3D

const PowerManager = preload("res://src/core/power_manager.gd")

@export var computer_ui_scene: PackedScene

var computer_ui_instance: ComputerUI = null

func _ready() -> void:
	if not computer_ui_scene:
		computer_ui_scene = load("res://src/ui/computer_ui.tscn")

	if computer_ui_scene:
		computer_ui_instance = computer_ui_scene.instantiate() as ComputerUI
		add_child(computer_ui_instance)

	var pm = PowerManager.get_instance()
	if pm:
		pm.register_appliance(self, "computer", "Terminal / PC do Escritório", 0.35, true)

func _exit_tree() -> void:
	var pm = PowerManager.get_instance()
	if pm:
		pm.unregister_appliance(self)

func get_interaction_prompt(player: Node = null) -> String:
	var pm = PowerManager.get_instance()
	var has_power = pm.is_main_power_on if pm else false
	if has_power:
		return "💻 [E] Acessar Computador / Pedidos de Insumos"
	else:
		return "Computador sem energia (Ligue o Quadro Geral)"

func interact(player: Node3D) -> void:
	var pm = PowerManager.get_instance()
	var has_power = pm.is_main_power_on if pm else false
	if not has_power:
		if player and player.has_node("HUD"):
			var hud = player.get_node("HUD")
			if hud and hud.has_method("show_temporary_feedback"):
				hud.show_temporary_feedback("⚠️ Computador desligado! Ligue a chave geral no quadro de energia.")
		return

	if computer_ui_instance:
		computer_ui_instance.open()

