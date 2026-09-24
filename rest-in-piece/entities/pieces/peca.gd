
class_name Peca

extends Resource

## Utilizado pra definir o visual dessa peça
@export var coords_no_atlas: Vector2i

@export_category("Tabela SRS")
@export_enum("PADRAO", "I", "O") var tipo_srs: String = "PADRAO"

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
		# pra acessar o dict: angulos["0"]
