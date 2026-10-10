class_name Peca

extends Resource

@export var nome: String = ""

## Utilizado pra definir o visual dessa peça. Pode olhar no TileSet a coord da cor que quer usar.
@export var coords_no_atlas: Vector2i

@export_category("Pontuação")
@export var pontos_por_bloco: int = 10
@export var multiplicador_por_bloco: float = 1.0

@export_category("Tabela SRS")
@export_enum("T", "S", "Z", "J", "L", "I", "O") var tipo_peca: String

## cada ângulo deve definir quatro coordenadas
@export_category("Coordenadas para cada ângulo")
@export var angulo_0: Array[Vector2i]
@export var angulo_90: Array[Vector2i]
@export var angulo_180: Array[Vector2i]
@export var angulo_270: Array[Vector2i]

# buffs permanentes dessa cópia da peça
var pontos_extras: int = 0
var multiplicador_extra: float = 0.0

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

func obter_pontos_por_bloco() -> int:
	return pontos_por_bloco + pontos_extras

func obter_multiplicador_por_bloco() -> float:
	return multiplicador_por_bloco + multiplicador_extra
