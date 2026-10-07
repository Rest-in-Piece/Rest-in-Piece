class_name Peca

extends Resource

@export var nome: String = ""

## Utilizado pra definir o visual dessa peça. Pode olhar no TileSet a coord da cor que quer usar.
@export var coords_no_atlas: Vector2i

@export_category("Tabela SRS")
@export_enum("T", "S", "Z", "J", "L", "I", "O") var tipo_peca: String

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

func obter_tipo_tabela_srs() -> String:
	if tipo_peca == "I":
		return "I"
	elif tipo_peca == "O":
		return "O"
	else:
		return "PADRAO"
