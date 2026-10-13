

# dados de UM quadradinho já fixado no tabuleiro. O tetris.gd guarda um por posição.
# Os valores são capturados quando a peça trava: buffs dados depois à peça não alteram
# quadradinhos que já estão no grid.

class_name BlocoFixado
extends RefCounted

var tipo_peca: String = ""
var pontos: int = 10
var multiplicador: float = 1.0
var eh_fragil: bool = false  # vidro: quebra assim que há um bloco não frágil acima
var atlas_da_quebra: Array[Vector2i] = []  # frames da animação de quebra


static func criar_a_partir_da_peca(peca_origem: Peca, travamento: TravamentoDePeca) -> BlocoFixado:
	var bloco_fixado := BlocoFixado.new()
	bloco_fixado.tipo_peca = peca_origem.tipo_peca
	bloco_fixado.pontos = peca_origem.obter_pontos_por_bloco() + travamento.pontos_extras_por_bloco
	bloco_fixado.multiplicador = peca_origem.obter_multiplicador_por_bloco() + travamento.multiplicador_extra_por_bloco
	bloco_fixado.eh_fragil = peca_origem.eh_fragil
	bloco_fixado.atlas_da_quebra = peca_origem.atlas_por_estagio_de_dano
	return bloco_fixado
