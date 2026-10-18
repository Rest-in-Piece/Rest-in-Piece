class_name Peca

extends Resource

# Resource só de DADOS. Comportamentos especiais (areia, bomba, vidro, fantasma...) ficam
# em "efeitos" (EfeitoDePeca); a Peca apenas combina as respostas dos efeitos.

@export var nome: String = ""

## Utilizado pra definir o visual dessa peça. Pode olhar no TileSet a coord da cor que quer usar.
@export var coords_no_atlas: Vector2i
@export var id_fonte_tiles: int = 0

@export_category("Pontuação")
@export var pontos_por_bloco: int = 10
@export var multiplicador_por_bloco: float = 1.0

@export_category("Efeitos")
## comportamentos especiais da peça, aplicados em ordem. Os efeitos são compartilhados e
## SEM estado: reutilize os .tres de res://entities/pecas/efeitos/
@export var efeitos: Array[EfeitoDePeca] = []

@export_category("Tabela SRS")
@export_enum("T", "S", "Z", "J", "L", "I", "O", "BOMBA") var tipo_peca: String
## AUTO escolhe pelo tipo (I -> "I", O -> "O", o resto -> "PADRAO")
@export_enum("AUTO", "PADRAO", "I", "O") var tabela_srs: String = "AUTO"

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
	if tabela_srs != "AUTO":
		return tabela_srs
	if tipo_peca == "I":
		return "I"
	if tipo_peca == "O":
		return "O"
	return "PADRAO"

func obter_pontos_por_bloco() -> int:
	return pontos_por_bloco + pontos_extras

func obter_multiplicador_por_bloco() -> float:
	return multiplicador_por_bloco + multiplicador_extra


# ---------- consultas aos efeitos ----------

# ex: peca.tem_efeito(EfeitoAreia)
func tem_efeito(tipo_de_efeito: Script) -> bool:
	for efeito in efeitos:
		if efeito != null and is_instance_of(efeito, tipo_de_efeito):
			return true
	return false

func atravessa_blocos() -> bool:
	for efeito in efeitos:
		if efeito != null and efeito.atravessa_blocos():
			return true
	return false

func fixa_ao_apoiar() -> bool:
	for efeito in efeitos:
		if efeito != null and efeito.fixa_ao_apoiar():
			return true
	return false

func permite_fixar_manualmente() -> bool:
	for efeito in efeitos:
		if efeito != null and efeito.permite_fixar_manualmente():
			return true
	return false

# todos os efeitos precisam permitir
func permite_descer(tabuleiro: TileMapLayer, forma: Array, posicao: Vector2i) -> bool:
	for efeito in efeitos:
		if efeito != null and not efeito.permite_descer(tabuleiro, forma, posicao):
			return false
	return true

func obter_cor_visual() -> Color:
	var cor: Color = Color.WHITE
	for efeito in efeitos:
		if efeito != null:
			cor *= efeito.cor_visual()
	return cor


# ---------- hooks (repassados aos efeitos, na ordem da lista) ----------

func filtrar_posicoes_para_registro(tabuleiro: TileMapLayer, posicoes: Array[Vector2i]) -> Array[Vector2i]:
	var resultado: Array[Vector2i] = posicoes
	for efeito in efeitos:
		if efeito != null:
			resultado = efeito.filtrar_posicoes_para_registro(tabuleiro, resultado)
	return resultado

func ao_travar(tabuleiro: TileMapLayer, posicoes: Array[Vector2i]) -> void:
	for efeito in efeitos:
		if efeito != null:
			efeito.ao_travar(tabuleiro, posicoes)

func projetar_posicoes(tabuleiro: TileMapLayer, posicoes: Array[Vector2i], ignoradas: Array[Vector2i]) -> Array[Vector2i]:
	var resultado: Array[Vector2i] = posicoes
	for efeito in efeitos:
		if efeito != null:
			resultado = efeito.ao_projetar(tabuleiro, resultado, ignoradas)
	return resultado


# cópia independente da peça, mantendo os buffs permanentes (o duplicate() sozinho não
# copia variáveis sem @export). Os efeitos são compartilhados (não têm estado), mas a
# lista é nova, pra que mexer nela não afete o original
func criar_copia() -> Peca:
	var copia := duplicate() as Peca
	copia.pontos_extras = pontos_extras
	copia.multiplicador_extra = multiplicador_extra
	var efeitos_copiados: Array[EfeitoDePeca] = []
	efeitos_copiados.assign(efeitos)
	copia.efeitos = efeitos_copiados
	return copia
