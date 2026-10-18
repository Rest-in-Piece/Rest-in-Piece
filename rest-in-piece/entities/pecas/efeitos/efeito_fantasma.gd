
# "a peça atravessa os blocos enquanto houver espaço vazio abaixo, nas colunas dela. Quando
# não houver mais, fixa sozinha. O hard drop desce a peça INTEIRA até a posição vazia mais
# profunda dessas colunas. Só as células livres recebem bloco; o resto é descartado"
class_name EfeitoFantasma
extends EfeitoDePeca

@export var cor: Color = Color(0.6, 0.95, 1.0, 0.6)


func atravessa_blocos() -> bool:
	return true

func fixa_ao_apoiar() -> bool:
	return true

func permite_fixar_manualmente() -> bool:
	return true

# a peça só pode descer se PELO MENOS UM bloco dela ainda tiver, na própria coluna, uma
# célula vazia nessa linha ou abaixo dela. Como a peça desce inteira, o limite é o bloco
# que alcança a célula vazia mais profunda
func permite_descer(tabuleiro: TileMapLayer, forma: Array, posicao: Vector2i) -> bool:
	for deslocamento in forma:
		var celula: Vector2i = posicao + deslocamento
		var linha_mais_funda: int = tabuleiro.linha_livre_mais_profunda(celula.x)
		if linha_mais_funda >= celula.y:
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
