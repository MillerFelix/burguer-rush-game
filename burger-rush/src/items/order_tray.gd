class_name OrderTray
extends ServingTray

# Mantém compatibilidade com OrderTray existente herdando ServingTray diretamente
func _ready() -> void:
	super._ready()
	item_id = "serving_tray"
	display_name = "Bandeja"
