class_name Peca

extends Resource

@export var nome: String = ""

## tiles do atlas, do inteiro ao mais rachado. Vazio = o bloco não muda de visual
@export var atlas_por_estagio_de_dano: Array[Vector2i] = []

## Utilizado pra definir o visual dessa peça. Pode olhar no TileSet a coord da cor que quer usar.
@export var coords_no_atlas: Vector2i
@export var id_fonte_tiles: int = 0

@export_category("Pontuação")
@export var pontos_por_bloco: int = 10
@export var multiplicador_por_bloco: float = 1.0

## quantos blocos NÃO-vidro empilhados acima o bloco aguenta antes de quebrar (0 = não é frágil)
@export var resistencia_ao_peso_por_bloco: int = 0

@export_category("Efeito ao travar")
@export var explode_ao_travar: bool = false
@export var atravessa_blocos: bool = false
@export var cai_em_blocos_ao_travar: bool = false

@export_category("Tabela SRS")
@export_enum("T", "S", "Z", "J", "L", "I", "O", "BOMBA") var tipo_peca: String

## cada ângulo define os blocos da peça (a bomba tem apenas um)
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
	elif tipo_peca in ["O", "BOMBA"]:
		return "O"
	else:
		return "PADRAO"

func obter_pontos_por_bloco() -> int:
	return pontos_por_bloco + pontos_extras

func obter_multiplicador_por_bloco() -> float:
	return multiplicador_por_bloco + multiplicador_extra


func obter_cor_visual() -> Color:
	return Color(0.6, 0.95, 1.0, 0.6) if atravessa_blocos else Color.WHITE


# cópia independente da peça, mantendo os buffs permanentes (o duplicate() sozinho não
# copia variáveis sem @export)
func criar_copia() -> Peca:
	var copia := duplicate() as Peca
	copia.pontos_extras = pontos_extras
	copia.multiplicador_extra = multiplicador_extra
	return copia
