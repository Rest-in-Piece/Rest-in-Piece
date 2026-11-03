

# "a peça atravessa os blocos enquanto houver espaço vazio abaixo, nas colunas dela. Quando
# não houver mais, ela espera o tempo de fixação normal e então fixa. O hard drop desce a
# peça INTEIRA até a posição vazia mais profunda dessas colunas. Só as células livres
# recebem bloco; o resto é descartado"
class_name EfeitoFantasma
extends EfeitoDePeca

@export var cor: Color = Color(0.6, 0.95, 1.0, 0.6)


func atravessa_blocos() -> bool:
	return true

# false: a fantasma respeita o tempo de fixação (etapas e resets) das outras peças
func fixa_ao_apoiar() -> bool:
	return false

func permite_fixar_manualmente() -> bool:
	return true

# a peça só pode descer se PELO MENOS UMA coluna dela ainda tiver, a partir do bloco MAIS
# BAIXO dela naquela coluna, uma célula vazia nessa linha ou abaixo. Só o bloco de baixo
# de cada coluna conta (os de cima ficariam mais "folgados" e fariam a peça descer demais)
func permite_descer(tabuleiro: TileMapLayer, forma: Array, posicao: Vector2i) -> bool:
	var mais_baixo_por_coluna: Dictionary = {}
	for deslocamento in forma:
		var celula: Vector2i = posicao + deslocamento
		if not mais_baixo_por_coluna.has(celula.x) or celula.y > mais_baixo_por_coluna[celula.x]:
			mais_baixo_por_coluna[celula.x] = celula.y
	
	for coluna in mais_baixo_por_coluna:
		var linha_mais_funda: int = tabuleiro.linha_livre_mais_profunda(coluna)
		if linha_mais_funda >= mais_baixo_por_coluna[coluna]:
			return true
	return false

func cor_visual() -> Color:
	return cor

# só as células vazias do tabuleiro recebem bloco
func filtrar_posicoes_para_registro(tabuleiro: TileMapLayer, posicoes: Array[Vector2i]) -> Array[Vector2i]:
	var livres: Array[Vector2i] = []
	for posicao in posicoes:
		if tabuleiro.celula_vazia(posicao):
			livres.append(posicao)
	return livres
