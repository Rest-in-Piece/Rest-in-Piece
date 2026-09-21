class_name Peca

extends Resource

## cada ângulo deve definir quatro coordenadas
@export_category("Coordenadas para cada ângulo")
@export var angulo_0: Array[Vector2i]
@export var angulo_90: Array[Vector2i]
@export var angulo_180: Array[Vector2i]
@export var angulo_270: Array[Vector2i]

var angulos: Dictionary:
	get:
		return {
			"0": angulo_0,
			"90": angulo_90,
			"180": angulo_180,
			"270": angulo_270
		}
