
# "ao travar, destrói os blocos ao redor (e pontua como linhas parciais). A própria peça
# é consumida sem pontuar"
class_name EfeitoExplosao
extends EfeitoDePeca

## alcance da explosão, em casas, a partir de cada bloco da peça (1 = área 3x3)
@export_range(1, 5) var raio: int = 1


func ao_travar(tabuleiro: TileMapLayer, posicoes: Array[Vector2i]) -> void:
	tabuleiro.explodir_area(posicoes, raio)
