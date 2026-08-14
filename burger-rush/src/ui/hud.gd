class_name HUD
extends CanvasLayer

@onready var interaction_label: Label = $InteractionLabel
@onready var crosshair: ColorRect = $Crosshair

func _ready() -> void:
	hide_prompt()

func show_prompt(text: String) -> void:
	interaction_label.text = text
	interaction_label.visible = true

func hide_prompt() -> void:
	interaction_label.text = ""
	interaction_label.visible = false
