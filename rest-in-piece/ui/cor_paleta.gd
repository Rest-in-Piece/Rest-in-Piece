@tool
extends ColorRect

@export var cor_da_paleta: StringName = &"destaque"


func _ready() -> void:
	theme_changed.connect(_aplicar_cor)
	_aplicar_cor()


func _aplicar_cor() -> void:
	if has_theme_color(cor_da_paleta, &"Paleta"):
		color = get_theme_color(cor_da_paleta, &"Paleta")
