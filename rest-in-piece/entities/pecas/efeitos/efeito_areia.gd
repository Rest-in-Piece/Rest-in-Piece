
# "cada bloco cai sozinho até encostar em algo, ao travar E durante o resto da partida:
# sempre que o tabuleiro muda (linha limpa, explosão, vidro quebrado), os grãos de areia
# que ficaram sem apoio caem de novo"
class_name EfeitoAreia
extends EfeitoDePeca


# FÍSICA: roda em toda estabilização do tabuleiro, para TODOS os grãos que carregam o efeito
func ao_assentar_tabuleiro(tabuleiro: TileMapLayer) -> bool:
	var origens: Array[Vector2i] = tabuleiro.posicoes_com_efeito(self)
	var plano: Dictionary[Vector2i, Vector2i] = calcular_assentamento(tabuleiro, origens)
	var mudou: bool = false
	
	# de baixo pra cima: o destino de cada grão já foi liberado pelos de baixo
	var ordenadas: Array[Vector2i] = origens.duplicate()
	ordenadas.sort_custom(func(a: Vector2i, b: Vector2i): return a.y > b.y)
	for origem in ordenadas:
		var destino: Vector2i = plano[origem]
		if destino != origem:
			tabuleiro.mover_bloco(origem, destino)
			mudou = true
	return mudou


# a projeção usa o MESMO cálculo da queda real, então as duas nunca divergem
func ao_projetar(tabuleiro: TileMapLayer, posicoes: Array[Vector2i], ignoradas: Array[Vector2i]) -> Array[Vector2i]:
	var destinos: Array[Vector2i] = []
	for destino in calcular_assentamento(tabuleiro, posicoes, ignoradas).values():
		destinos.append(destino)
	return destinos


# simula (sem alterar nada) a queda de cada grão e devolve origem -> destino. Os grãos de
# baixo caem primeiro, liberando espaço para os de cima na mesma coluna.
# "ignoradas" são células que contam como vazias (a própria peça ainda em jogo)
func calcular_assentamento(tabuleiro: TileMapLayer, origens: Array[Vector2i], ignoradas: Array[Vector2i] = []) -> Dictionary[Vector2i, Vector2i]:
	var ordenadas: Array[Vector2i] = origens.duplicate()
	ordenadas.sort_custom(func(a: Vector2i, b: Vector2i): return a.y > b.y)
	
	var ocupadas_no_fim: Dictionary = {}
	var plano: Dictionary[Vector2i, Vector2i] = {}
	
	for origem in ordenadas:
		var destino: Vector2i = origem
		while _pode_cair_para(tabuleiro, destino + Vector2i.DOWN, origens, ignoradas, ocupadas_no_fim):
			destino += Vector2i.DOWN
		ocupadas_no_fim[destino] = true
		plano[origem] = destino
	
	return plano


# uma célula serve de destino se está no tabuleiro, nenhum grão já parou nela e está vazia
# (ou é a casa de origem de um grão que já saiu dali, ou é da própria peça em jogo)
func _pode_cair_para(tabuleiro: TileMapLayer, posicao: Vector2i, origens: Array[Vector2i], ignoradas: Array[Vector2i], ocupadas_no_fim: Dictionary) -> bool:
	if not tabuleiro.posicao_esta_no_tabuleiro(posicao):
		return false
	if ocupadas_no_fim.has(posicao):
		return false
	return tabuleiro.celula_vazia(posicao) or origens.has(posicao) or ignoradas.has(posicao)
