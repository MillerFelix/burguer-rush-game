class_name CommercialSink
extends StaticBody3D

@onready var status_label: Label3D = $StatusLabel

func get_interaction_prompt(player: Node = null) -> String:
	return "E — Higienizar as Mãos / Lavar Utensílios"

func interact(player: Node3D) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback("✨ Mãos e utensílios higienizados com sucesso! (Higiene 100%)")
