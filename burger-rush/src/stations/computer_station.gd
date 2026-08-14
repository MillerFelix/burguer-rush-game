class_name ComputerStation
extends StaticBody3D

@export var computer_ui_scene: PackedScene

var computer_ui_instance: ComputerUI = null

func _ready() -> void:
	if not computer_ui_scene:
		computer_ui_scene = load("res://src/ui/computer_ui.tscn")

	if computer_ui_scene:
		computer_ui_instance = computer_ui_scene.instantiate() as ComputerUI
		add_child(computer_ui_instance)

func get_interaction_prompt(player: Node = null) -> String:
	return "E — Usar Computador"

func interact(player: Node3D) -> void:
	if computer_ui_instance:
		computer_ui_instance.open()
