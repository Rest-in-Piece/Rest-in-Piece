
# "o bloco quebra IMEDIATAMENTE quando existe, acima dele na mesma coluna, um bloco que não
# é vidro (a pilha acima precisa estar encostada). Vidro sobre vidro passa o peso adiante"
class_name EfeitoVidro
extends EfeitoDePeca

## frames da animação de quebra, em ordem: o primeiro é o bloco inteiro e os seguintes são
## as rachaduras. Vazio = o bloco só some, sem rachar
@export var atlas_por_estagio_de_dano: Array[Vector2i] = []


# REGRAS: roda depois de as linhas serem limpas. Todos os blocos são avaliados ANTES de
# qualquer um ser removido, pra que a remoção de um não mude o resultado dos outros
func ao_resolver_tabuleiro(tabuleiro: TileMapLayer) -> bool:
	var quebrados: Array[Vector2i] = []
	for posicao in tabuleiro.posicoes_com_efeito(self):
		if _tem_peso_acima(tabuleiro, posicao):
			quebrados.append(posicao)
	
	for posicao in quebrados:
		# lidos ANTES de apagar a célula
		var id_fonte: int = tabuleiro.get_cell_source_id(posicao)
		var atlas_atual: Vector2i = tabuleiro.get_cell_atlas_coords(posicao)
		tabuleiro.remover_bloco(posicao)
		EfeitoQuebraVidro.tocar(tabuleiro, id_fonte, posicao, atlas_por_estagio_de_dano, atlas_atual)
	
	if not quebrados.is_empty():
		tabuleiro.blocos_quebrados.emit(quebrados.size())
	return not quebrados.is_empty()


# a linha 1 é o topo, então "acima" significa y menor. Sobe a coluna e PARA na primeira
# casa vazia: só conta peso encostado no vidro (direto, ou por uma pilha contínua)
func _tem_peso_acima(tabuleiro: TileMapLayer, posicao: Vector2i) -> bool:
	var y: int = posicao.y - 1
	while y >= 1:
		var posicao_acima := Vector2i(posicao.x, y)
		
		if tabuleiro.celula_vazia(posicao_acima):
			return false
		
		# tile sem dados é tratado como bloco sólido
		var outro: BlocoFixado = tabuleiro.blocos_fixados.get(posicao_acima)
		if outro == null or not outro.tem_efeito_do_mesmo_tipo(self):
			return true
		
		y -= 1
	
	return false
